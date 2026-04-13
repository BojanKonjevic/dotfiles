#!/usr/bin/env bash
set -euo pipefail

# ─── Argument check ───────────────────────────────────────────────────────────
if [ -z "${1:-}" ]; then
  echo "Usage: $0 <project-name>"
  exit 1
fi

NAME="$1"
PKG_NAME="${NAME//-/_}"

if [ -d "$NAME" ]; then
  echo "Error: directory '$NAME' already exists."
  exit 1
fi

# ─── Template selection ───────────────────────────────────────────────────────
echo ""
echo "Select a template:"
echo "  1) blank    — dev tools only (pytest, ruff, mypy)"
echo "  2) fastapi  — FastAPI + SQLAlchemy + Alembic + asyncpg"
echo ""

while true; do
  read -rp "Template [1/2]: " TEMPLATE_CHOICE
  case "$TEMPLATE_CHOICE" in
  1 | blank)
    TEMPLATE="blank"
    break
    ;;
  2 | fastapi)
    TEMPLATE="fastapi"
    break
    ;;
  *) echo "  Please enter 1 or 2." ;;
  esac
done

echo ""
echo "🚀 Creating Python project: $NAME (template: $TEMPLATE)"

# ─── Create Postgres databases (fastapi only) ─────────────────────────────────
if [ "$TEMPLATE" = "fastapi" ]; then
  for DBNAME in "$NAME" "${NAME}_test"; do
    if psql -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DBNAME'" | grep -q 1; then
      echo "⚠️  Postgres database '$DBNAME' already exists, skipping createdb."
    else
      createdb "$DBNAME"
      echo "✅  Created Postgres database '$DBNAME'."
    fi
  done
fi

# ─── Directory structure ──────────────────────────────────────────────────────
mkdir -p "$NAME/src/$PKG_NAME"
mkdir -p "$NAME/src/$PKG_NAME/routes"
mkdir -p "$NAME/tests"
cd "$NAME"

# ─── Template-specific variables ─────────────────────────────────────────────
if [ "$TEMPLATE" = "fastapi" ]; then
  NIX_PACKAGES='
          fastapi
          uvicorn
          uvloop
          httptools
          websockets
          watchfiles
          python-dotenv

          sqlalchemy
          alembic
          asyncpg
          greenlet
          pydantic-settings

          passlib
          bcrypt
          python-jose
          email-validator
          python-multipart'

  PYPROJECT_DEPS='"fastapi", "uvicorn[standard]", "sqlalchemy[asyncio]", "alembic", "asyncpg", "pydantic-settings", "passlib[bcrypt]", "python-jose[cryptography]", "email-validator", "python-multipart"'

  JUST_RUN="uvicorn ${PKG_NAME}.main:app --reload"

  EXTRA_JUST_TARGETS='
migrate msg="":
    alembic revision --autogenerate -m "{{msg}}"
upgrade:
    alembic upgrade head
downgrade:
    alembic downgrade -1
db-drop:
    dropdb '"$NAME"'
db-drop-test:
    dropdb '"${NAME}_test"''

  SHELL_COMMANDS='
          echo "Commands:"
          echo "  just test                    run tests"
          echo "  just cov                     coverage"
          echo "  just lint                    lint"
          echo "  just fmt                     format"
          echo "  just check                   type check"
          echo "  just run                     run the app"
          echo "  just migrate \"description\"   generate a migration"
          echo "  just upgrade                 apply migrations"
          echo "  just downgrade               roll back one step"
          echo "  just db-drop                 delete the local database"
          echo "  just db-drop-test            delete the test database"
          echo'

else
  NIX_PACKAGES='
          python-dotenv'

  PYPROJECT_DEPS=''
  JUST_RUN="python -m $PKG_NAME"
  EXTRA_JUST_TARGETS=''

  SHELL_COMMANDS='
          echo "Commands:"
          echo "  just test     run tests"
          echo "  just cov      coverage"
          echo "  just lint     lint"
          echo "  just fmt      format"
          echo "  just check    type check"
          echo "  just run      run the app"
          echo'
fi

# ─── flake.nix ────────────────────────────────────────────────────────────────
cat >flake.nix <<FLAKE
{
  description = "$NAME — Python development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.\${system};
      pythonEnv = pkgs.python313.withPackages (ps:
        with ps; [$NIX_PACKAGES

          pytest
          pytest-cov
          pytest-asyncio
          httpx
          ruff
          mypy
          ipython
        ]);
    in {
      devShells.default = pkgs.mkShell {
        packages = [
          pythonEnv
          pkgs.pre-commit
          pkgs.git
          pkgs.just
          pkgs.ripgrep
          pkgs.fd
        ];

        shellHook = ''
          export PYTHONPATH="\$PWD/src:\$PYTHONPATH"

          echo

          if [ -f .pre-commit-config.yaml ]; then
            pre-commit install >/dev/null 2>&1 || true
          fi

          $SHELL_COMMANDS
        '';
      };
    });
}
FLAKE

# ─── pyproject.toml ───────────────────────────────────────────────────────────
cat >pyproject.toml <<PYPROJECT
[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.build_meta"

[project]
name = "$NAME"
version = "0.1.0"
description = ""
requires-python = ">=3.12"

dependencies = [
  $PYPROJECT_DEPS
]

[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"

[tool.ruff]
line-length = 88
exclude = ["alembic/"]

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "ANN", "SIM"]

[tool.mypy]
strict = true
PYPROJECT

# ─── Append mypy overrides for untyped auth libs (fastapi only) ───────────────
if [ "$TEMPLATE" = "fastapi" ]; then
  cat >>pyproject.toml <<'MYPY_OVERRIDES'

[[tool.mypy.overrides]]
module = ["jose.*", "passlib.*"]
ignore_missing_imports = true
disable_error_codes = ["import-untyped", "no-any-return"]
MYPY_OVERRIDES
fi

# ─── justfile ─────────────────────────────────────────────────────────────────
cat >justfile <<JUSTFILE
test:
    pytest -v
cov:
    pytest --cov=src --cov-report=term-missing
lint:
    ruff check .
fmt:
    ruff format .
check:
    mypy .
run:
    $JUST_RUN
$EXTRA_JUST_TARGETS
JUSTFILE

# ─── direnv ───────────────────────────────────────────────────────────────────
echo "use flake" >.envrc
direnv allow

# ─── Source package ───────────────────────────────────────────────────────────
cat >"src/$PKG_NAME/__init__.py" <<INIT
"""$NAME"""

__version__ = "0.1.0"
INIT

# ─── Template-specific source files ───────────────────────────────────────────
if [ "$TEMPLATE" = "fastapi" ]; then

  cat >"src/$PKG_NAME/main.py" <<'MAIN'
from fastapi import FastAPI

from .database import lifespan

app = FastAPI(lifespan=lifespan)


@app.get("/")
def root() -> dict[str, str]:
    return {"status": "ok"}
MAIN

  cat >"src/$PKG_NAME/database.py" <<'DB'
from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from .settings import settings

engine = create_async_engine(settings.database_url, echo=settings.debug)
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:  # type: ignore[misc]
    yield
    await engine.dispose()


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        yield session
DB

  cat >"src/$PKG_NAME/settings.py" <<SETTINGS
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    # Triple-slash = local Unix socket + peer auth (no password needed).
    # Override in .env for remote/production:
    #   DATABASE_URL=postgresql+asyncpg://user:pass@host:5432/dbname
    database_url: str = "postgresql+asyncpg:///$NAME"
    debug: bool = False

    secret_key: str = "change-me-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 30


settings = Settings()
SETTINGS

  cat >"src/$PKG_NAME/security.py" <<'SECURITY'
import secrets
from datetime import UTC, datetime, timedelta
from typing import cast
from uuid import UUID

from jose import JWTError, jwt
from passlib.context import CryptContext

from .settings import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(plain: str) -> str:
    return cast(str, pwd_context.hash(plain))


def verify_password(plain: str, hashed: str) -> bool:
    return cast(bool, pwd_context.verify(plain, hashed))


def create_access_token(user_id: UUID) -> str:
    expire = datetime.now(UTC) + timedelta(minutes=settings.access_token_expire_minutes)
    payload = {"sub": str(user_id), "exp": expire}
    return cast(str, jwt.encode(payload, settings.secret_key, algorithm=settings.algorithm))


def decode_access_token(token: str) -> UUID | None:
    try:
        payload = jwt.decode(
            token, settings.secret_key, algorithms=[settings.algorithm]
        )
        user_id = payload.get("sub")
        if user_id is None:
            return None
        return UUID(user_id)
    except JWTError:
        return None


def generate_refresh_token() -> str:
    return secrets.token_urlsafe(64)
SECURITY

  cat >"src/$PKG_NAME/models.py" <<'MODELS'
# Add your SQLAlchemy models here.
#
# When you're ready to add auth, you'll need at minimum:
#   - User         (id, email, hashed_password, is_active, created_at)
#   - RefreshToken (id, token, user_id FK, expires_at, revoked)
#
# Example:
#
# from sqlalchemy import Boolean, DateTime, String, Uuid, func
# from sqlalchemy.orm import Mapped, mapped_column
# from .database import Base
#
# class User(Base):
#     __tablename__ = "users"
#     id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
#     email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
#     hashed_password: Mapped[str] = mapped_column(String(255))
#     is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default="true")
#     created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
MODELS

  touch "src/$PKG_NAME/routes/__init__.py"

  cat >alembic.ini <<ALEMBIC_INI
[alembic]
script_location = alembic
prepend_sys_path = src
sqlalchemy.url = postgresql+asyncpg:///$NAME

[loggers]
keys = root,sqlalchemy,alembic

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = WARN
handlers = console
qualname =

[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine

[logger_alembic]
level = INFO
handlers =
qualname = alembic

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(levelname)-5.5s [%(name)s] %(message)s
datefmt = %H:%M:%S
ALEMBIC_INI

  mkdir -p alembic/versions

  cat >alembic/env.py <<ENV
import asyncio
from logging.config import fileConfig

from alembic import context
from sqlalchemy.ext.asyncio import AsyncConnection, create_async_engine

import ${PKG_NAME}.models  # noqa: F401 — ensure models are registered
from ${PKG_NAME}.database import Base
from ${PKG_NAME}.settings import settings

config = context.config
config.set_main_option("sqlalchemy.url", settings.database_url)

if config.config_file_name:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    context.configure(
        url=settings.database_url,
        target_metadata=target_metadata,
        literal_binds=True,
    )
    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection: AsyncConnection) -> None:
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    engine = create_async_engine(settings.database_url)
    async with engine.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await engine.dispose()


def run_migrations_online() -> None:
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
ENV

  cat >alembic/script.py.mako <<'MAKO'
"""${message}

Revision ID: ${up_revision}
Revises: ${down_revision | comma,n}
Create Date: ${create_date}
"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
${imports if imports else ""}

revision: str = ${repr(up_revision)}
down_revision: str | None = ${repr(down_revision)}
branch_labels: str | Sequence[str] | None = ${repr(branch_labels)}
depends_on: str | Sequence[str] | None = ${repr(depends_on)}


def upgrade() -> None:
    ${upgrades if upgrades else "pass"}


def downgrade() -> None:
    ${downgrades if downgrades else "pass"}
MAKO

  cat >.env <<DOTENV
DATABASE_URL=postgresql+asyncpg:///$NAME
DEBUG=false
SECRET_KEY=change-me-run-openssl-rand-hex-32
DOTENV

  cat >.env.example <<'DOTENV_EXAMPLE'
DATABASE_URL=postgresql+asyncpg:///your-db-name
DEBUG=false
SECRET_KEY=your-secret-key-from-openssl-rand-hex-32
DOTENV_EXAMPLE

  cat >"tests/test_main.py" <<'TESTS'
from httpx import AsyncClient


async def test_root(client: AsyncClient) -> None:
    response = await client.get("/")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
TESTS

  cat >"tests/conftest.py" <<CONFTEST
import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from ${PKG_NAME}.database import Base, get_session
from ${PKG_NAME}.main import app

TEST_DATABASE_URL = "postgresql+asyncpg:///${NAME}_test"
TEST_USER = {"email": "test@example.com", "password": "testpassword123"}


@pytest.fixture
async def session() -> AsyncSession:  # type: ignore[misc]
    engine = create_async_engine(TEST_DATABASE_URL)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    factory = async_sessionmaker(engine, expire_on_commit=False)

    async with factory() as s:
        yield s

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

    await engine.dispose()


@pytest.fixture
async def anon_client(session: AsyncSession) -> AsyncClient:  # type: ignore[misc]
    """Unauthenticated client — use for testing 401 responses."""

    async def override_get_session() -> AsyncSession:  # type: ignore[misc]
        yield session

    app.dependency_overrides[get_session] = override_get_session

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as ac:
        yield ac

    app.dependency_overrides.clear()


@pytest.fixture
async def client(session: AsyncSession) -> AsyncClient:  # type: ignore[misc]
    """Authenticated client — pre-registered and logged in as TEST_USER.

    Activate once auth routes exist: uncomment the auth block below
    and remove the plain \`yield ac\` line.
    """

    async def override_get_session() -> AsyncSession:  # type: ignore[misc]
        yield session

    app.dependency_overrides[get_session] = override_get_session

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as ac:
        # await ac.post("/auth/register", json=TEST_USER)
        # token_resp = await ac.post(
        #     "/auth/token",
        #     data={"username": TEST_USER["email"], "password": TEST_USER["password"]},
        # )
        # token = token_resp.json()["access_token"]
        # ac.headers["Authorization"] = f"Bearer {token}"
        yield ac

    app.dependency_overrides.clear()
CONFTEST

else
  # blank template
  cat >"src/$PKG_NAME/main.py" <<MAIN
def main() -> None:
    print("Hello from $NAME!")


if __name__ == "__main__":
    main()
MAIN

  cat >"tests/test_main.py" <<'TESTS'
TESTS

fi

# ─── .gitignore ───────────────────────────────────────────────────────────────
cat >.gitignore <<'GITIGNORE'
# Nix
result
result-*
.direnv
.envrc

# Python
__pycache__/
*.py[cod]
*.egg-info/
.eggs/
dist/
build/
.mypy_cache/
.ruff_cache/
.pytest_cache/
htmlcov/
.coverage

# DB / env
*.db
.env

# Editors
.vscode/
.idea/
*.swp
GITIGNORE

# ─── pre-commit config ────────────────────────────────────────────────────────
cat >.pre-commit-config.yaml <<'PRECOMMIT'
repos:
  - repo: local
    hooks:
      - id: ruff-lint
        name: ruff lint
        entry: ruff check --fix
        language: system
        types: [python]

      - id: ruff-format
        name: ruff format
        entry: ruff format
        language: system
        types: [python]

      - id: mypy
        name: mypy
        entry: mypy
        language: system
        types: [python]
        pass_filenames: false
        args: [src/]
PRECOMMIT

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "✅  Project '$NAME' created! (template: $TEMPLATE)"
echo ""
echo "Next steps:"
echo "  cd $NAME"
echo "  git init && git add ."
if [ "$TEMPLATE" = "fastapi" ]; then
  echo ""
  echo "Auth plumbing is ready in security.py and settings.py."
  echo "When you're ready to add auth:"
  echo "  1. Add User + RefreshToken models (see comments in models.py)"
  echo "  2. Add dependencies.py with get_current_user"
  echo "  3. Add routes/auth.py with register, login, refresh, logout"
  echo "  4. Activate the authenticated client fixture in tests/conftest.py"
  echo "  5. Run: just migrate 'add users' && just upgrade"
fi
echo ""
echo "Tip: commit flake.lock after the first 'nix develop' run."

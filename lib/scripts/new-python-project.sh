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

if ! command -v uv &>/dev/null; then
  echo "Error: 'uv' is not installed."
  exit 1
fi

# ─── Reserved name guard ──────────────────────────────────────────────────────
# Names that shadow stdlib modules cause confusing import errors at runtime.
STDLIB_RESERVED="test sys os io re json math time datetime collections itertools
  functools pathlib typing abc ast copy csv enum http logging operator random
  socket string struct threading types unittest urllib uuid warnings xml email
  html queue array bisect calendar cmath contextlib contextvars dataclasses
  decimal difflib dis filecmp fnmatch fractions gc getopt getpass gettext glob
  graphlib hashlib heapq hmac inspect ipaddress keyword locale marshal mimetypes
  mmap numbers pickle pprint profile pstats readline runpy select selectors
  shelve shlex shutil signal site smtplib sqlite3 stat statistics subprocess
  symbol symtable sysconfig tabnanny tarfile tempfile textwrap token tokenize
  tomllib trace traceback tracemalloc tty unicodedata venv weakref webbrowser
  zipapp zipfile zipimport zlib zoneinfo"

for reserved in $STDLIB_RESERVED; do
  if [ "$PKG_NAME" = "$reserved" ]; then
    echo "Error: '$PKG_NAME' shadows a Python stdlib module."
    echo "  Choose a different name to avoid confusing import errors."
    echo "  Suggestion: '${NAME}-app'  or  'my-${NAME}'"
    exit 1
  fi
done

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
      echo "⚠️  Postgres database '$DBNAME' already exists, skipping."
    else
      createdb "$DBNAME"
      echo "✅  Created Postgres database '$DBNAME'."
    fi
  done
fi

# ─── Directory structure ──────────────────────────────────────────────────────
mkdir -p "$NAME/src/$PKG_NAME"
mkdir -p "$NAME/tests"
[ "$TEMPLATE" = "fastapi" ] && mkdir -p "$NAME/src/$PKG_NAME/routes"
cd "$NAME"

# ─── Template variables ───────────────────────────────────────────────────────
if [ "$TEMPLATE" = "fastapi" ]; then
  RUNTIME_DEPS='"fastapi",
  "uvicorn[standard]",
  "sqlalchemy[asyncio]",
  "alembic",
  "asyncpg",
  "pydantic-settings",
  "passlib[bcrypt]",
  "python-jose[cryptography]",
  "email-validator",
  "python-multipart",
  "python-dotenv",'

  JUST_RUN="uvicorn ${PKG_NAME}.main:app --reload"

  EXTRA_JUST_TARGETS="
migrate msg=\"\":
    alembic revision --autogenerate -m \"{{msg}}\"
upgrade:
    alembic upgrade head
downgrade:
    alembic downgrade -1
db-drop:
    dropdb $NAME
db-drop-test:
    dropdb ${NAME}_test"

  # Lines spliced into the Nix shellHook — printf renders ANSI, echo doesn't.
  SHELL_HELP='printf "  \033[34m%-26s\033[0m %s\n" "just run" "start dev server (--reload)"
          printf "  \033[34m%-26s\033[0m %s\n" "just migrate \"msg\"" "generate migration"
          printf "  \033[34m%-26s\033[0m %s\n" "just upgrade" "apply migrations"
          printf "  \033[34m%-26s\033[0m %s\n" "just downgrade" "roll back one step"'
else
  RUNTIME_DEPS='"python-dotenv",'
  JUST_RUN="python -m $PKG_NAME"
  EXTRA_JUST_TARGETS=""
  SHELL_HELP='printf "  \033[34m%-26s\033[0m %s\n" "just run" "run the app"'
fi

# ─── flake.nix ────────────────────────────────────────────────────────────────
cat >flake.nix <<FLAKE
{
  description = "$NAME — Python dev environment";

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
      pythonVersion = "313"; # ← python version
      python = pkgs."python\${pythonVersion}";
    in {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          python
          uv
          just
          pre-commit
          git
          ripgrep
          fd
          stdenv.cc.cc.lib
          ruff
        ];


        shellHook = ''
          # libstdc++ must be set before uv sync so native extensions
          # (greenlet, asyncpg, cryptography) link correctly at compile + runtime.
          export LD_LIBRARY_PATH="\${pkgs.stdenv.cc.cc.lib}/lib:\$LD_LIBRARY_PATH"

          # Lock uv to the Nix-managed Python — never download a separate one.
          export UV_PYTHON_DOWNLOADS=never
          export UV_PYTHON="\${python}/bin/python3"

          # src/ layout: package importable without an editable install.
          export PYTHONPATH="\$PWD/src"

          # Sync deps on every entry — no-op when uv.lock is unchanged (<50ms).
          uv sync --quiet

          # Prepend venv so pytest/ruff/mypy from uv win over any Nix copies.
          export PATH="\$PWD/.venv/bin:\$PATH"

          # Install git hooks once (silently skipped before git init).
          if [ -f .pre-commit-config.yaml ] && [ ! -f .git/hooks/pre-commit ]; then
            pre-commit install --quiet 2>/dev/null || true
          fi

          printf "\n  \033[1;35m$NAME\033[0m \033[2mdev shell\033[0m  \033[36m\$(python3 --version)\033[0m\n\n"
          printf "  \033[34m%-26s\033[0m %s\n" "just test"  "run tests"
          printf "  \033[34m%-26s\033[0m %s\n" "just cov"   "coverage report"
          printf "  \033[34m%-26s\033[0m %s\n" "just lint"  "ruff check"
          printf "  \033[34m%-26s\033[0m %s\n" "just fmt"   "ruff format"
          printf "  \033[34m%-26s\033[0m %s\n" "just check" "mypy"
          $SHELL_HELP
          printf "\n"
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
requires-python = ">=3.13"
dependencies = [
  $RUNTIME_DEPS
]

[dependency-groups]
dev = [
  "pytest>=8",
  "pytest-cov",
  "pytest-asyncio",
  "httpx",
  "mypy",
  "ipython",
]

[tool.setuptools.packages.find]
where = ["src"]

[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
# Belt-and-suspenders alongside PYTHONPATH: pytest inserts src/ into sys.path
# before stdlib, so same-named stdlib modules (e.g. 'email') can't shadow ours.
pythonpath = ["src"]

[tool.ruff]
line-length = 88
exclude = ["alembic/", ".venv/"]

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "ANN", "SIM"]

[tool.mypy]
strict = true
PYPROJECT

if [ "$TEMPLATE" = "fastapi" ]; then
  cat >>pyproject.toml <<'EOF'

[[tool.mypy.overrides]]
module = ["jose.*", "passlib.*"]
ignore_missing_imports = true
ignore_errors = true
EOF
fi

# ─── justfile ─────────────────────────────────────────────────────────────────
# Tools invoke .venv/bin binaries directly — no `uv run` wrapper needed since
# the shellHook prepends .venv/bin to PATH.
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
    mypy src/
run:
    $JUST_RUN
$EXTRA_JUST_TARGETS
JUSTFILE

# ─── .envrc ───────────────────────────────────────────────────────────────────
cat >.envrc <<'EOF'
use flake
dotenv_if_exists .env
EOF
direnv allow

# ─── Source package ───────────────────────────────────────────────────────────
cat >"src/$PKG_NAME/__init__.py" <<INIT
"""$NAME"""

__version__ = "0.1.0"
INIT

# ─── Template-specific source files ───────────────────────────────────────────
if [ "$TEMPLATE" = "fastapi" ]; then

  cat >"src/$PKG_NAME/main.py" <<'EOF'
from fastapi import FastAPI

from .database import lifespan

app = FastAPI(lifespan=lifespan)


@app.get("/")
def root() -> dict[str, str]:
    return {"status": "ok"}
EOF

  cat >"src/$PKG_NAME/database.py" <<'EOF'
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
async def lifespan(app: FastAPI) -> AsyncGenerator[None]:
    yield
    await engine.dispose()


async def get_session() -> AsyncGenerator[AsyncSession]:
    async with AsyncSessionLocal() as session:
        yield session
EOF

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

  cat >"src/$PKG_NAME/security.py" <<'EOF'
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
    return cast(
        str, jwt.encode(payload, settings.secret_key, algorithm=settings.algorithm)
    )


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
EOF

  cat >"src/$PKG_NAME/models.py" <<'EOF'
# Add your SQLAlchemy models here.
#
# When you're ready to add auth, you'll need at minimum:
#   - User         (id, email, hashed_password, is_active, created_at)
#   - RefreshToken (id, token, user_id FK, expires_at, revoked)
#
# Example:
#
# from uuid import uuid4
# from datetime import datetime
# from uuid import UUID
# from sqlalchemy import Boolean, DateTime, String, Uuid, func
# from sqlalchemy.orm import Mapped, mapped_column
# from .database import Base
#
# class User(Base):
#     __tablename__ = "users"
#     id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
#     email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
#     hashed_password: Mapped[str] = mapped_column(String(255))
#     is_active: Mapped[bool] = mapped_column(
#       Boolean, default=True, server_default="true"
#     )
#     created_at: Mapped[datetime] = mapped_column(
#       DateTime(timezone=True), server_default=func.now()
#     )
EOF

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

  cat >alembic/script.py.mako <<'EOF'
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
EOF

  cat >.env <<DOTENV
DATABASE_URL=postgresql+asyncpg:///$NAME
DEBUG=false
SECRET_KEY=change-me-run-openssl-rand-hex-32
DOTENV

  cat >.env.example <<'EOF'
DATABASE_URL=postgresql+asyncpg:///your-db-name
DEBUG=false
SECRET_KEY=your-secret-key-from-openssl-rand-hex-32
EOF

  cat >"tests/test_main.py" <<'EOF'
from httpx import AsyncClient


async def test_root(client: AsyncClient) -> None:
    response = await client.get("/")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
EOF

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
  # ── blank template ────────────────────────────────────────────────────────
  cat >"src/$PKG_NAME/main.py" <<MAIN
def main() -> None:
    print("Hello from $NAME!")


if __name__ == "__main__":
    main()
MAIN

  cat >"src/$PKG_NAME/__main__.py" <<MAIN
from .main import main

main()
MAIN

  cat >"tests/test_main.py" <<TESTS
import pytest

from ${PKG_NAME}.main import main


def test_main(capsys: pytest.CaptureFixture[str]) -> None:
    main()
    captured = capsys.readouterr()
    assert "Hello from ${NAME}" in captured.out
TESTS

fi

# ─── .gitignore ───────────────────────────────────────────────────────────────
cat >.gitignore <<'EOF'
# Nix
result
result-*
.direnv/

# uv / Python
.venv/
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
EOF

# ─── pre-commit config ────────────────────────────────────────────────────────
cat >.pre-commit-config.yaml <<'EOF'
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
EOF

# ─── Lock flake inputs ────────────────────────────────────────────────────────
# Pins nixpkgs + flake-utils commit SHAs into flake.lock.
# Python packages are pinned separately in uv.lock (created on first cd).
echo ""
echo "🔒 Locking Nix flake inputs..."
nix flake lock

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "✅  Project '$NAME' created! (template: $TEMPLATE)"
echo ""
echo "Next steps:"
echo "  cd $NAME              ← direnv activates, uv syncs deps, shell is ready"
echo "  git init && git add . ← commit both flake.lock and uv.lock"
if [ "$TEMPLATE" = "fastapi" ]; then
  echo ""
  echo "When you're ready to add auth:"
  echo "  1. Add User + RefreshToken models (see models.py)"
  echo "  2. Add src/$PKG_NAME/dependencies.py with get_current_user"
  echo "  3. Add src/$PKG_NAME/routes/auth.py"
  echo "  4. Activate the client fixture in tests/conftest.py"
  echo "  5. just migrate 'add users' && just upgrade"
fi

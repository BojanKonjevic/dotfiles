"""
GitIngest CLI Wrapper (NixOS + Wayland) - Direct to clipboard (Clean)
Usage:
  ./ingest.py <owner/repo>
  ./ingest.py -m <repo_name>
"""

import sys
import re
import subprocess
import urllib.request

MY_GITHUB = "https://github.com/BojanKonjevic"


def fetch_raw(owner_repo: str, filepath: str) -> str | None:
    url = f"https://raw.githubusercontent.com/{owner_repo}/HEAD/{filepath}"
    try:
        with urllib.request.urlopen(url) as r:
            return r.read().decode("utf-8", errors="replace")
    except Exception:
        return None


def fix_binary_files(digest: str, owner_repo: str) -> str:
    # Match sections gitingest marked as binary
    pattern = re.compile(
        r"(={48}\nFILE: (.+?)\n={48}\n)\[Binary file\]",
        re.MULTILINE,
    )

    def replace(m: re.Match) -> str:
        header = m.group(1)
        filepath = m.group(2).strip()
        content = fetch_raw(owner_repo, filepath)
        if content is None:
            return m.group(0)  # leave as-is if fetch fails
        print(f"  ↳ recovered: {filepath}")
        return header + content

    return pattern.sub(replace, digest)


def parse_owner_repo(url: str) -> str:
    # Extract owner/repo from full URL
    url = url.rstrip("/")
    parts = url.replace("https://github.com/", "").split("/")
    return f"{parts[0]}/{parts[1]}"


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    if sys.argv[1] in ("-m", "--mine"):
        if len(sys.argv) != 3:
            print("Error: -m requires a repository name.")
            sys.exit(1)
        repo_name = sys.argv[2].strip("/")
        url = f"{MY_GITHUB}/{repo_name}"
        print(f"→ Your repo: {url}")
    else:
        input_arg = sys.argv[1].strip()
        if input_arg.startswith("https://"):
            url = input_arg
        elif "/" in input_arg and not input_arg.startswith("http"):
            url = f"https://github.com/{input_arg}"
        else:
            print("Error: Invalid format. Use either:")
            print("  owner/repo")
            print("  or -m reponame")
            sys.exit(1)
        print(f"→ Repository: {url}")

    owner_repo = parse_owner_repo(url)

    print("-" * 70)
    print("Running gitingest...")

    try:
        result = subprocess.run(
            ["gitingest", url, "-o", "-"],
            capture_output=True,
            text=True,
            check=True,
        )
        digest = result.stdout

        if not digest.strip():
            print("❌ ERROR: gitingest returned empty output.")
            sys.exit(1)

        # Fix files incorrectly flagged as binary
        binary_count = digest.count("[Binary file]")
        if binary_count:
            print(
                f"  Recovering {binary_count} file(s) incorrectly marked as binary..."
            )
            digest = fix_binary_files(digest, owner_repo)

        subprocess.run(["wl-copy"], input=digest, text=True, check=True)

        print("\n✅ Done! Full digest copied to clipboard.")
        print("   Paste anywhere with Ctrl+V (or middle click)")

    except FileNotFoundError:
        print("❌ 'gitingest' or 'wl-copy' not found.")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"❌ gitingest failed (exit code {e.returncode})")
        if e.stderr:
            print(e.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n\n⚠️ Cancelled.")
        sys.exit(130)


if __name__ == "__main__":
    main()

"""
GitIngest CLI Wrapper (NixOS + Wayland) - Direct to clipboard (Clean)
Usage:
  ./ingest.py <owner/repo> [--src|--test|--docs]
  ./ingest.py -m <repo_name> [--src|--test|--docs]
"""

import sys
import re
import subprocess
import urllib.request
import urllib.error

MY_GITHUB = "https://github.com/BojanKonjevic"


def fetch_raw(owner_repo: str, filepath: str) -> str | None:
    url = f"https://raw.githubusercontent.com/{owner_repo}/HEAD/{filepath}"
    try:
        with urllib.request.urlopen(url) as r:
            return r.read().decode("utf-8", errors="replace")
    except Exception:
        return None


def fix_binary_files(digest: str, owner_repo: str) -> str:
    pattern = re.compile(
        r"(={48}\nFILE: (.+?)\n={48}\n)\[Binary file\]",
        re.MULTILINE,
    )

    def replace(m: re.Match) -> str:
        header = m.group(1)
        filepath = m.group(2).strip()
        content = fetch_raw(owner_repo, filepath)
        if content is None:
            return m.group(0)
        print(f"  ↳ recovered: {filepath}")
        return header + content

    return pattern.sub(replace, digest)


def filter_digest(digest: str, dir_prefix: str) -> str | None:
    """
    Keep only the file blocks whose path matches `dir_prefix` (e.g. 'src').
    Returns the filtered digest, or None if no block matches.
    """
    file_header_pat = re.compile(r"^={48}\nFILE: (.+?)\n={48}$", re.MULTILINE)
    matches = list(file_header_pat.finditer(digest))
    if not matches:
        return None

    pre = digest[: matches[0].start()]
    selected_blocks = []

    for idx, m in enumerate(matches):
        path = m.group(1).strip()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(digest)
        block = digest[m.start() : end]
        if path == dir_prefix or path.startswith(dir_prefix + "/"):
            selected_blocks.append(block)

    return pre + "".join(selected_blocks) if selected_blocks else None


def repo_has_dir(owner_repo: str, dir_name: str) -> bool | None:
    """
    Quick check via GitHub API: does the top-level directory exist?
    Returns True if the directory exists, False if it definitely doesn't,
    None if the check could not be performed (rate limit, network error, etc.).
    """
    api_url = f"https://api.github.com/repos/{owner_repo}/contents/{dir_name}"
    req = urllib.request.Request(api_url, method="HEAD")
    try:
        with urllib.request.urlopen(req) as resp:
            return True  # 200 OK → directory exists
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return False
        # 403 rate limit, 401 private repo, etc. – we can't tell
        return None
    except Exception:
        return None


def parse_owner_repo(url: str) -> str:
    url = url.rstrip("/")
    parts = url.replace("https://github.com/", "").split("/")
    return f"{parts[0]}/{parts[1]}"


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    # ---- Parse flags ----
    filter_dir = None
    filter_flags = [f for f in sys.argv if f in ("--src", "--test", "--docs")]
    if len(filter_flags) > 1:
        print("Error: Please specify only one of --src, --test, or --docs.")
        sys.exit(1)

    if "--src" in sys.argv:
        filter_dir = "src"
    elif "--test" in sys.argv:
        filter_dir = "tests"
    elif "--docs" in sys.argv:
        filter_dir = "docs"

    # ---- Parse repository argument ----
    if sys.argv[1] in ("-m", "--mine"):
        if len(sys.argv) < 3:
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

    # ---- Early directory check (if a filter flag is used) ----
    if filter_dir:
        print(f"Checking if the repository contains a '{filter_dir}/' directory...")
        exists = repo_has_dir(owner_repo, filter_dir)
        if exists is False:
            print(f"❌ ERROR: No '{filter_dir}/' directory found in {owner_repo}.")
            sys.exit(1)
        elif exists is None:
            # We couldn't verify (private repo, rate limit, etc.) – proceed anyway.
            # The final filtering will still catch the error, but later.
            print("  ⚠️  Could not pre‑verify directory presence (API unavailable).")
            print(
                "      Will still filter after download and show an error if missing."
            )

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

        binary_count = digest.count("[Binary file]")
        if binary_count:
            print(
                f"  Recovering {binary_count} file(s) incorrectly marked as binary..."
            )
            digest = fix_binary_files(digest, owner_repo)

        # ---- Apply directory filter if requested ----
        if filter_dir:
            filtered = filter_digest(digest, filter_dir)
            if filtered is None:
                print(
                    f"❌ ERROR: No '{filter_dir}/' directory found in this repository."
                )
                sys.exit(1)
            digest = filtered

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

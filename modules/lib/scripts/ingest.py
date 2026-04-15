"""
GitIngest CLI Wrapper (NixOS + Wayland) - Direct to clipboard (Clean)

Usage:
  ./ingest.py <owner/repo>
  ./ingest.py -m <repo_name>
"""

import sys
import subprocess

MY_GITHUB = "https://github.com/BojanKonjevic"


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    # Handle -m flag for your own repos
    if sys.argv[1] in ("-m", "--mine"):
        if len(sys.argv) != 3:
            print("Error: -m requires a repository name.")
            print("Example: ./ingest.py -m dotfiles")
            sys.exit(1)
        repo_name = sys.argv[2].strip("/")
        url = f"{MY_GITHUB}/{repo_name}"
        print(f"→ Your repo: {url}")
    else:
        # Accept owner/repo or full URL
        input_arg = sys.argv[1].strip()
        if input_arg.startswith("https://"):
            url = input_arg
            print(f"→ Repository: {url}")
        elif "/" in input_arg and not input_arg.startswith("http"):
            url = f"https://github.com/{input_arg}"
            print(f"→ Repository: {url}")
        else:
            print("Error: Invalid format. Use either:")
            print("  owner/repo")
            print("  or -m reponame")
            sys.exit(1)

    print("-" * 70)
    print("Running gitingest...")

    try:
        # -o - forces output to stdout
        result = subprocess.run(
            ["gitingest", url, "-o", "-"], capture_output=True, text=True, check=True
        )

        digest = result.stdout

        if not digest.strip():
            print("❌ ERROR: gitingest returned empty output.")
            sys.exit(1)

        # Copy full digest to clipboard
        subprocess.run(["wl-copy"], input=digest, text=True, check=True)

        # Clean success message only
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

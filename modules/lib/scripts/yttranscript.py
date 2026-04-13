#!/usr/bin/env nix-shell
#! nix-shell -i python3 -p "python3.withPackages (ps: [ ps.youtube-transcript-api ])" -p python3

"""
YouTube Transcript CLI for NixOS (compatible with current 2026 API)
Usage:
  ./yttranscript.py <youtube_url_or_id> [--timestamps] [--lang en]
"""

import sys
import argparse
from urllib.parse import urlparse, parse_qs

from youtube_transcript_api import (
    YouTubeTranscriptApi,
    TranscriptsDisabled,
    NoTranscriptFound,
    VideoUnavailable,
    RequestBlocked,
)


def extract_video_id(url_or_id: str) -> str | None:
    """Extract YouTube video ID."""
    if len(url_or_id) == 11 and url_or_id.replace("-", "").replace("_", "").isalnum():
        return url_or_id

    try:
        parsed = urlparse(url_or_id)
        hostname = parsed.hostname.lower() if parsed.hostname else ""

        if hostname in ("www.youtube.com", "youtube.com", "m.youtube.com"):
            if parsed.path == "/watch":
                return parse_qs(parsed.query).get("v", [None])[0]
            elif parsed.path.startswith("/embed/"):
                return parsed.path.split("/embed/")[1].split("?")[0].split("/")[0]

        if hostname == "youtu.be":
            return parsed.path.lstrip("/").split("?")[0].split("/")[0]
    except Exception:
        pass
    return None


def fetch_transcript(video_id: str, lang: str | None = None):
    """Fetch transcript - works with the current API."""
    try:
        api = YouTubeTranscriptApi()

        if lang:
            # Specific language
            return api.get_transcript(video_id, languages=[lang])

        # Auto-select best available transcript
        transcript_list = api.list(video_id)

        # 1. Prefer manual (human-created) transcripts
        for t in transcript_list:
            if not t.is_generated:
                return t.fetch()

        # 2. Fallback to auto-generated
        for t in transcript_list:
            if t.is_generated:
                return t.fetch()

        # 3. Last resort: English auto-generated
        return transcript_list.find_generated_transcript(["en"]).fetch()

    except TranscriptsDisabled:
        print("❌ Transcripts are disabled for this video.")
    except NoTranscriptFound:
        print("❌ No captions available for this video.")
    except VideoUnavailable:
        print("❌ Video is unavailable (private, deleted, or restricted).")
    except RequestBlocked:
        print("❌ YouTube blocked the request (rate limit). Try again later.")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

    return None


def format_output(transcript, timestamps: bool = False):
    """Format output - works with new FetchedTranscript object."""
    if timestamps:
        for snippet in transcript:
            total_sec = int(snippet.start)
            mins = total_sec // 60
            secs = total_sec % 60
            print(f"[{mins:02d}:{secs:02d}] {snippet.text}")
    else:
        # Join all snippet.text
        full_text = " ".join(snippet.text for snippet in transcript)
        print(full_text)


def main():
    parser = argparse.ArgumentParser(description="YouTube Transcript CLI")
    parser.add_argument("url", help="YouTube URL or video ID")
    parser.add_argument(
        "-t", "--timestamps", action="store_true", help="Show timestamps"
    )
    parser.add_argument(
        "--lang", default=None, help="Preferred language code (e.g. en, es, fr)"
    )
    args = parser.parse_args()

    video_id = extract_video_id(args.url)
    if not video_id:
        print("❌ Invalid YouTube URL or video ID")
        sys.exit(1)

    print(f"Fetching transcript for: {video_id}")
    transcript = fetch_transcript(video_id, args.lang)

    if transcript is None:
        sys.exit(1)

    print("\n" + "=" * 80 + "\n")
    format_output(transcript, args.timestamps)
    print("\n" + "=" * 80)


if __name__ == "__main__":
    main()

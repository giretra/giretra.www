#!/usr/bin/env bash
#
# Update the homepage showcase video.
#
# Usage:
#   ./scripts/update-video.sh /path/to/new-video.mkv
#
# Accepts any video format ffmpeg can read.
# Outputs web-optimized MP4, WebM, and a poster image to public/video/.

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <source-video-path>"
  exit 1
fi

SOURCE="$1"

if [ ! -f "$SOURCE" ]; then
  echo "Error: File not found: $SOURCE"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="$PROJECT_DIR/public/video"

mkdir -p "$OUT_DIR"

echo "==> Generating MP4 (H.264, web-optimized)..."
ffmpeg -y -i "$SOURCE" \
  -an \
  -c:v libx264 -preset slow -crf 26 \
  -vf "scale=1280:-2" \
  -pix_fmt yuv420p \
  -movflags +faststart \
  -profile:v high -level 4.1 \
  "$OUT_DIR/showcase.mp4"

echo "==> Generating WebM (VP9)..."
ffmpeg -y -i "$SOURCE" \
  -an \
  -c:v libvpx-vp9 -crf 35 -b:v 0 \
  -vf "scale=1280:-2" \
  -deadline good -cpu-used 2 -row-mt 1 \
  "$OUT_DIR/showcase.webm"

echo "==> Extracting poster image..."
ffmpeg -y -i "$SOURCE" \
  -vf "select=eq(n\,60),scale=1280:-2" \
  -frames:v 1 -q:v 2 -update 1 \
  "$OUT_DIR/showcase-poster.jpg"

echo ""
echo "Done! Files written to $OUT_DIR/"
ls -lh "$OUT_DIR"/showcase.*

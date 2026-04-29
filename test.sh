#!/usr/bin/env bash
set -euo pipefail

API_URL="${API_URL:-http://127.0.0.1:8100}"
IMAGE_SOURCE="${1:-${IMAGE_SOURCE:-}}"
PROMPT="${PROMPT:-product cinematic shot}"
FRAMEPACK_SECONDS="${FRAMEPACK_SECONDS:-5}"
OUTPUT_DIR="${OUTPUT_DIR:-./outputs/test-run}"

if [[ -z "$IMAGE_SOURCE" ]]; then
  cat <<'EOF'
Usage:
  ./test.sh /path/to/image.jpg
  IMAGE_SOURCE="https://.../image.jpg" ./test.sh

Optional environment variables:
  API_URL=http://127.0.0.1:8100
  PROMPT="your prompt"
  FRAMEPACK_SECONDS=5
  OUTPUT_DIR=./outputs/test-run
EOF
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

WORK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

SOURCE_FILE="$IMAGE_SOURCE"
if [[ "$IMAGE_SOURCE" =~ ^https?:// ]]; then
  SOURCE_NAME="$(basename "${IMAGE_SOURCE%%\?*}")"
  if [[ -z "$SOURCE_NAME" || "$SOURCE_NAME" == "/" ]]; then
    SOURCE_NAME="framepack-input.jpg"
  fi
  SOURCE_FILE="$WORK_DIR/$SOURCE_NAME"
  echo "Downloading source image from URL: $IMAGE_SOURCE"
  curl -fL "$IMAGE_SOURCE" -o "$SOURCE_FILE"
fi

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "Source image not found: $SOURCE_FILE" >&2
  exit 1
fi

echo "Using API: $API_URL"
echo "Using image: $SOURCE_FILE"
echo "Prompt: $PROMPT"
echo "Seconds: $FRAMEPACK_SECONDS"
echo "Output dir: $OUTPUT_DIR"

echo "Sending request to FramePack..."
RESPONSE_FILE="$WORK_DIR/response.json"

curl -fsS \
  -X POST "$API_URL/generate" \
  -F "file=@${SOURCE_FILE}" \
  -F "output_dir=${OUTPUT_DIR}" \
  -F "prompt=${PROMPT}" \
  -F "seconds=${FRAMEPACK_SECONDS}" \
  -o "$RESPONSE_FILE"

python - "$RESPONSE_FILE" <<'PY'
import json
import sys
from pathlib import Path

response_path = Path(sys.argv[1])
payload = json.loads(response_path.read_text(encoding="utf-8"))
print("Response:")
print(json.dumps(payload, indent=2))

output_path = payload.get("output_path")
if output_path:
    print(f"Generated output file: {output_path}")
else:
    print("No output_path returned.")
    if payload.get("error"):
        print(f"Error: {payload.get('error')}")
    if payload.get("detail"):
        print(f"Detail: {payload.get('detail')}")
PY

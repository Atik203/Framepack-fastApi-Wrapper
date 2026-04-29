#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(dirname "$(readlink -f "$0")")"

# For faster  output
export FRAMEPACK_STEPS=8
export FRAMEPACK_BUCKET_RESOLUTION=512
export FRAMEPACK_HIGH_QUALITY_FP32=false
export FRAMEPACK_USE_TEACACHE=true
export FRAMEPACK_GPU_MEMORY_PRESERVATION=6
export FRAMEPACK_MP4_CRF=22

if [ -f "$BASE_DIR/.venv/bin/activate" ]; then
  # Use the project virtual environment if it exists.
  source "$BASE_DIR/.venv/bin/activate"
fi

cd "$BASE_DIR"
exec python framepack_api.py

#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_ROOT="/mnt/g/FramepackCache"

mkdir -p "$CACHE_ROOT/HuggingFace" \
  "$CACHE_ROOT/Torch" \
  "$CACHE_ROOT/pip" \
  "$CACHE_ROOT/gradio_temp" \
  "$CACHE_ROOT/temp"

export HF_HOME="$CACHE_ROOT/HuggingFace"
export TRANSFORMERS_CACHE="$CACHE_ROOT/HuggingFace"
export HUGGINGFACE_HUB_CACHE="$CACHE_ROOT/HuggingFace"
export HF_HUB_CACHE="$CACHE_ROOT/HuggingFace"
export TORCH_HOME="$CACHE_ROOT/Torch"
export PIP_CACHE_DIR="$CACHE_ROOT/pip"
export GRADIO_TEMP_DIR="$CACHE_ROOT/gradio_temp"
export TMP="$CACHE_ROOT/temp"
export TEMP="$CACHE_ROOT/temp"

if [ -f "$BASE_DIR/.venv/bin/activate" ]; then
  # Use the project virtual environment if it exists.
  source "$BASE_DIR/.venv/bin/activate"
fi

cd "$BASE_DIR"
exec python framepack_api.py

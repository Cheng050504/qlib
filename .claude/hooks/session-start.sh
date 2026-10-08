#!/bin/bash
# SessionStart hook for Claude Code cloud sessions: sets up a Python 3.12 venv
# with qlib (editable, dev + lint + test extras) and LightGBM, and downloads the
# CN sample data so benchmarks like LightGBM/Alpha158 can run immediately.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

VENV="$CLAUDE_PROJECT_DIR/.venv"
DATA_DIR="$HOME/.qlib/qlib_data/cn_data"

# qlib supports Python <=3.12; the container default (3.13) is too new.
if [ ! -x "$VENV/bin/python" ]; then
  uv venv -q -p python3.12 "$VENV"
fi

export VIRTUAL_ENV="$VENV"
export PATH="$VENV/bin:$PATH"

# numpy 2 / pandas >=2.3 are not yet compatible with qlib's pinned stack.
uv pip install -q "numpy<2" "pandas<2.3" cython setuptools-scm wheel
uv pip install -q -e ".[dev,lint,test]" lightgbm

if [ ! -f "$DATA_DIR/calendars/day.txt" ]; then
  python -m qlib.cli.data qlib_data --target_dir "$DATA_DIR" --region cn > /dev/null 2>&1
fi

if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export VIRTUAL_ENV=\"$VENV\"" >> "$CLAUDE_ENV_FILE"
  echo "export PATH=\"$VENV/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

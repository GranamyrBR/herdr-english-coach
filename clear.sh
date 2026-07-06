#!/usr/bin/env bash
# Clear the English Coach history.
set -euo pipefail
LOG="${ENGLISH_COACH_LOG:-$HOME/.local/share/english-coach/corrections.log}"
: > "$LOG"
echo "English Coach history cleared."

#!/usr/bin/env bash
# English Coach board — pane script: legend + live history of corrections
set -euo pipefail

LOG="${ENGLISH_COACH_LOG:-$HOME/.local/share/english-coach/corrections.log}"
mkdir -p "$(dirname "$LOG")"
touch "$LOG"

CYAN=$'\033[36m'; RED=$'\033[31m'; ORANGE=$'\033[38;5;208m'; GREEN=$'\033[32m'
DIM=$'\033[2m'; BOLD=$'\033[1m'; RESET=$'\033[0m'

clear
printf '%s📝 ENGLISH COACH%s\n' "$BOLD" "$RESET"
printf '%s%s%s\n' "$DIM" "───────────────────────────────────────────" "$RESET"
printf '%scyan%s   = missing word\n' "$CYAN" "$RESET"
printf '%sred%s    = wrong word\n' "$RED" "$RESET"
printf '%sorange%s = correct, but devs do not say it this way\n' "$ORANGE" "$RESET"
printf '%sgreen%s  = the right jargon/form\n' "$GREEN" "$RESET"
printf '%s%s%s\n' "$DIM" "───────────────────────────────────────────" "$RESET"
SCORE_SH="$(dirname "${BASH_SOURCE[0]}")/score.sh"
[ -f "$SCORE_SH" ] && bash "$SCORE_SH" show
printf '%s%s%s\n\n' "$DIM" "───────────────────────────────────────────" "$RESET"

exec tail -n 500 -f "$LOG"

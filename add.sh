#!/usr/bin/env bash
# Append one correction entry to the English Coach board.
#
# Usage:
#   add.sh "<original>" "<fixed>" "<dev jargon>" "<why>"
#
# Color markup in any argument (converted to ANSI):
#   [c]word[/]  cyan   = missing word
#   [r]word[/]  red    = wrong word
#   [o]word[/]  orange = correct, but devs do not say it this way
#   [g]word[/]  green  = the right jargon/form
set -euo pipefail

LOG="${ENGLISH_COACH_LOG:-$HOME/.local/share/english-coach/corrections.log}"
mkdir -p "$(dirname "$LOG")"

CYAN=$'\033[36m'; RED=$'\033[31m'; ORANGE=$'\033[38;5;208m'; GREEN=$'\033[32m'
DIM=$'\033[2m'; RESET=$'\033[0m'

colorize() {
  local s="$1"
  s="${s//\[c\]/$CYAN}"
  s="${s//\[r\]/$RED}"
  s="${s//\[o\]/$ORANGE}"
  s="${s//\[g\]/$GREEN}"
  s="${s//\[\/\]/$RESET}"
  printf '%s' "$s"
}

original="${1:-}"
fixed="${2:-}"
jargon="${3:-}"
why="${4:-}"

{
  printf '%s%s ────────────────────────────%s\n' "$DIM" "$(date +%H:%M)" "$RESET"
  [ -n "$original" ] && printf '%syou wrote:%s  %s\n' "$DIM" "$RESET" "$(colorize "$original")"
  [ -n "$fixed" ]    && printf '%sfixed:%s      %s\n' "$DIM" "$RESET" "$(colorize "$fixed")"
  [ -n "$jargon" ]   && printf '%sdev jargon:%s %s\n' "$DIM" "$RESET" "$(colorize "$jargon")"
  [ -n "$why" ]      && printf '%swhy:%s        %s\n' "$DIM" "$RESET" "$(colorize "$why")"
} >> "$LOG"

# DevTOEFL: score the practice (best-effort)
SCORE_SH="$(dirname "${BASH_SOURCE[0]}")/score.sh"
[ -f "$SCORE_SH" ] && bash "$SCORE_SH" entry || printf '\n' >> "$LOG"

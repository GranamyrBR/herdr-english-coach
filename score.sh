#!/usr/bin/env bash
# DevTOEFL — gamified scoring for English Coach. Positive-only: you earn
# points for practicing, you earn more for writing clean English, streaks
# multiply the bonus. Levels map CEFR bands to dev career ranks.
#
# Usage:
#   score.sh clean              a message had no mistakes  (+10, streak bonus +2/streak)
#   score.sh entry [C R O]      a message was coached      (+2 practice; streak resets)
#   score.sh show               print the scoreboard
#   score.sh reset              zero everything
set -uo pipefail

STATS="${ENGLISH_COACH_STATS:-$HOME/.local/share/english-coach/score.env}"
LOG="${ENGLISH_COACH_LOG:-$HOME/.local/share/english-coach/corrections.log}"
mkdir -p "$(dirname "$STATS")"
[ -f "$STATS" ] || printf 'POINTS=0\nSTREAK=0\nBEST_STREAK=0\nCLEAN=0\nCOACHED=0\n' > "$STATS"
# shellcheck disable=SC1090
. "$STATS"

GREEN=$'\033[32m'; CYAN=$'\033[36m'; ORANGE=$'\033[38;5;208m'
DIM=$'\033[2m'; BOLD=$'\033[1m'; RESET=$'\033[0m'

level() {
  if   [ "$1" -ge 1000 ]; then echo "Principal (C2)"
  elif [ "$1" -ge 600 ];  then echo "Staff (C1)"
  elif [ "$1" -ge 300 ];  then echo "Senior (B2)"
  elif [ "$1" -ge 150 ];  then echo "Mid (B1)"
  elif [ "$1" -ge 50 ];   then echo "Junior (A2)"
  else                         echo "Intern (A1)"
  fi
}

next_at() {
  if   [ "$1" -ge 1000 ]; then echo ""
  elif [ "$1" -ge 600 ];  then echo 1000
  elif [ "$1" -ge 300 ];  then echo 600
  elif [ "$1" -ge 150 ];  then echo 300
  elif [ "$1" -ge 50 ];   then echo 150
  else                         echo 50
  fi
}

save() {
  printf 'POINTS=%s\nSTREAK=%s\nBEST_STREAK=%s\nCLEAN=%s\nCOACHED=%s\n' \
    "$POINTS" "$STREAK" "$BEST_STREAK" "$CLEAN" "$COACHED" > "$STATS"
}

case "${1:-show}" in
  clean)
    OLD_LEVEL=$(level "$POINTS")
    STREAK=$((STREAK + 1))
    [ "$STREAK" -gt "$BEST_STREAK" ] && BEST_STREAK=$STREAK
    BONUS=$((STREAK * 2))
    GAIN=$((10 + BONUS))
    POINTS=$((POINTS + GAIN))
    CLEAN=$((CLEAN + 1))
    save
    {
      printf '%s✔ clean English%s %s+%d pts%s %s(streak %d ×2 bonus)%s · total %d · %s\n' \
        "$GREEN" "$RESET" "$GREEN" "$GAIN" "$RESET" "$DIM" "$STREAK" "$RESET" "$POINTS" "$(level "$POINTS")"
      NEW_LEVEL=$(level "$POINTS")
      [ "$NEW_LEVEL" != "$OLD_LEVEL" ] && printf '%s🎉 LEVEL UP → %s%s\n' "$BOLD" "$NEW_LEVEL" "$RESET"
      printf '\n'
    } >> "$LOG"
    ;;
  entry)
    OLD_LEVEL=$(level "$POINTS")
    POINTS=$((POINTS + 2))
    COACHED=$((COACHED + 1))
    STREAK=0
    save
    {
      printf '%s+2 pts practice%s · total %d · %s · next level at %s pts\n' \
        "$DIM" "$RESET" "$POINTS" "$(level "$POINTS")" "$(next_at "$POINTS")"
      NEW_LEVEL=$(level "$POINTS")
      [ "$NEW_LEVEL" != "$OLD_LEVEL" ] && printf '%s🎉 LEVEL UP → %s%s\n' "$BOLD" "$NEW_LEVEL" "$RESET"
      printf '\n'
    } >> "$LOG"
    ;;
  show)
    NEXT=$(next_at "$POINTS")
    printf '%s🏆 DevTOEFL%s  %s%d pts%s · %s%s%s\n' "$BOLD" "$RESET" "$GREEN" "$POINTS" "$RESET" "$BOLD" "$(level "$POINTS")" "$RESET"
    printf '%sclean msgs%s %d   %scoached%s %d   %sstreak%s %d (best %d)' \
      "$DIM" "$RESET" "$CLEAN" "$DIM" "$RESET" "$COACHED" "$DIM" "$RESET" "$STREAK" "$BEST_STREAK"
    [ -n "$NEXT" ] && printf '   %snext level at%s %d pts' "$DIM" "$RESET" "$NEXT"
    printf '\n'
    ;;
  reset)
    POINTS=0 STREAK=0 BEST_STREAK=0 CLEAN=0 COACHED=0
    save
    echo "DevTOEFL score reset."
    ;;
  *)
    echo "usage: score.sh {clean|entry|show|reset}" >&2
    exit 1
    ;;
esac

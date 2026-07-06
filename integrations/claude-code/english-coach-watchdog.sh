#!/usr/bin/env bash
# English Coach watchdog — Claude Code UserPromptSubmit hook.
#
# Sends the user's English messages to a cheap headless model (Haiku),
# which returns color-marked corrections; appends them to the herdr
# English Coach board. Runs in background, fail-open: your expensive
# main-session model spends zero tokens on coaching.
#
# Install:
#   1. Copy this file somewhere stable, e.g. ~/.claude/hooks/
#   2. chmod +x english-coach-watchdog.sh
#   3. Register in ~/.claude/settings.json:
#        "hooks": {
#          "UserPromptSubmit": [
#            { "hooks": [ { "type": "command",
#                "command": "/path/to/english-coach-watchdog.sh",
#                "timeout": 10 } ] }
#          ]
#        }
#   4. Restart Claude Code (hooks are snapshotted at session start).
#
# Config (env):
#   ENGLISH_COACH_ADD  path to the plugin's add.sh
#                      (default: ~/herdr-plugins/english-coach/add.sh,
#                       falling back to the herdr-managed install dir)
#   ENGLISH_COACH_LOG  corrections log (see add.sh)
#
# Note: the native-language gate below is tuned for Brazilian Portuguese
# speakers (skips PT messages before any API call). Adapt the regex for
# your own language.
set -uo pipefail

# recursion guard: never fire inside a nested claude spawned by this hook
[ -n "${ENGLISH_COACH_WATCHDOG:-}" ] && exit 0

resolve_add() {
  if [ -n "${ENGLISH_COACH_ADD:-}" ] && [ -f "$ENGLISH_COACH_ADD" ]; then
    printf '%s' "$ENGLISH_COACH_ADD"; return
  fi
  for p in \
    "$HOME/herdr-plugins/english-coach/add.sh" \
    "$HOME/.config/herdr/plugins/install/granamyrbr.english-coach"/add.sh \
    "$HOME/.local/share/herdr/plugins"/*/english-coach*/add.sh; do
    [ -f "$p" ] && { printf '%s' "$p"; return; }
  done
  printf ''
}

ADD_SH=$(resolve_add)
[ -z "$ADD_SH" ] && exit 0
command -v claude >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
PROMPT=$(jq -r '.prompt // empty' <<<"$INPUT" 2>/dev/null) || exit 0
[ -z "$PROMPT" ] && exit 0

# skip slash-commands, bang-commands, and very short prompts
case "$PROMPT" in "/"*|"!"*) exit 0 ;; esac
[ "${#PROMPT}" -lt 12 ] && exit 0

# cheap native-language gate (Brazilian Portuguese) → skip without any API call
if grep -qiE '[ãõçáéíóúâêôà]|\b(que|não|nao|para|você|voce|isso|essa|esse|está|esta|quando|como|coloque|deixe|veja|mande|escrevi|responda|fale|quero|preciso|ajude|em ingles)\b' <<<"$PROMPT"; then
  exit 0
fi
# must contain at least one common English function word
grep -qiE '\b(the|is|are|to|it|i|you|a|an|can|do|does|how|what|this|that|check|make|run|want|wanna|for|not|but|all|my)\b' <<<"$PROMPT" || exit 0

LOGDIR="${ENGLISH_COACH_LOG:+$(dirname "$ENGLISH_COACH_LOG")}"
LOGDIR="${LOGDIR:-$HOME/.local/share/english-coach}"
mkdir -p "$LOGDIR"

(
  export ENGLISH_COACH_WATCHDOG=1
  COACH_PROMPT="You are an English writing coach for a non-native speaker who is a software developer. Analyze this sentence they typed to a coding agent:

<sentence>
$PROMPT
</sentence>

If it contains genuine English mistakes (grammar, or wording a native dev would not use), respond with EXACTLY these 4 lines and nothing else:
ORIGINAL: <the sentence exactly as typed>
FIXED: <the sentence with grammar fixed, marking ONLY changed/inserted words: [c]word[/] = missing word now inserted, [r]word[/] = wrong word now corrected, [o]word[/] = grammatically fine but not how devs say it (will be replaced in JARGON)>
JARGON: <the sentence as a native dev/ops person would write it, marking ONLY the replacements as [g]word[/]>
WHY: <one terse line in simple English explaining the fixes, reusing the same [c]/[r]/[o]/[g] markup on key words>

Rules: mark minimal units only (words, not phrases, never the whole sentence); ignore code, commands, file paths, proper-noun spelling of tools; casual tone is fine, only flag real mistakes.

If the sentence has no genuine mistakes, respond with exactly: OK"

  RESULT=$(timeout 90 claude -p --model haiku \
    --settings '{"disableAllHooks":true}' \
    --strict-mcp-config \
    -- "$COACH_PROMPT" 2>>"$LOGDIR/watchdog.log")

  FIRST=$(head -n1 <<<"$RESULT" | tr -d '[:space:]')
  [ "$FIRST" = "OK" ] && exit 0

  original=$(grep -m1 '^ORIGINAL:' <<<"$RESULT" | sed 's/^ORIGINAL:[[:space:]]*//')
  fixed=$(grep -m1 '^FIXED:' <<<"$RESULT" | sed 's/^FIXED:[[:space:]]*//')
  jargon=$(grep -m1 '^JARGON:' <<<"$RESULT" | sed 's/^JARGON:[[:space:]]*//')
  why=$(grep -m1 '^WHY:' <<<"$RESULT" | sed 's/^WHY:[[:space:]]*//')

  [ -z "$fixed" ] && exit 0
  bash "$ADD_SH" "$original" "$fixed" "$jargon" "$why"
) >>"$LOGDIR/watchdog.log" 2>&1 &
disown

exit 0

# English Coach

A teacher's notebook for non-native English speakers — any native language — living in a [herdr](https://herdr.dev) side pane.

You work with your coding agent (Claude Code, Codex, ...) in English. Every time you make a mistake — grammar or dev jargon — the agent logs a color-coded correction to the board while it answers your actual question. The pane accumulates your personal correction history: a notebook written by your agent, about your English.

```
📝 ENGLISH COACH
───────────────────────────────────────────
cyan   = missing word
red    = wrong word
orange = correct, but devs do not say it this way
green  = the right jargon/form
───────────────────────────────────────────

19:25 ────────────────────────────
you wrote:  it make sense run herdr in the terax???
fixed:      Does it make sense to run herdr in Terax?
dev jargon: Does it make sense to nest herdr inside Terax?
why:        questions need does + to before the verb; run in
            is fine, but devs say nest inside for a tool
            inside another tool
```

In the pane, `Does`/`to` render cyan (they were missing), `run`/`in` orange (fine, but not how devs say it), `nest`/`inside` green (the idiomatic form).

## Why two tracks

Most grammar tools stop at "correct." This board teaches two layers per sentence:

1. **fixed** — your sentence with the grammar corrected, nothing else changed
2. **dev jargon** — the same sentence the way a native dev/ops person would actually say it

The gap between the two lines is where fluency lives.

## Install

```sh
herdr plugin install GranamyrBR/herdr-english-coach
```

Or, for local development:

```sh
git clone https://github.com/GranamyrBR/herdr-english-coach
herdr plugin link ./herdr-english-coach
```

## Usage

Open the board (right split):

```sh
herdr plugin pane open --plugin granamyrbr.english-coach --entrypoint board \
  --placement split --direction right
```

Add a correction (this is what your agent calls):

```sh
bash add.sh \
  "it make sense run herdr in the terax???" \
  "[c]Does[/] it make sense [c]to[/] [o]run[/] herdr [o]in[/] Terax?" \
  "Does it make sense to [g]nest[/] herdr [g]inside[/] Terax?" \
  "questions need [c]does[/] + [c]to[/] before the verb; devs say [g]nest inside[/]"
```

Arguments: `original` · `fixed` · `dev jargon` · `why` — each optional past the first, each accepting color markup:

| Markup | Color | Meaning |
|---|---|---|
| `[c]word[/]` | cyan | missing word, now inserted |
| `[r]word[/]` | red | wrong word |
| `[o]word[/]` | orange | correct, but devs do not say it this way |
| `[g]word[/]` | green | the right jargon/form |

Clear the history:

```sh
bash clear.sh
```

History persists in `~/.local/share/english-coach/corrections.log` (override with `ENGLISH_COACH_LOG`).

## Teaching your agent to use it

Two ways, from cheapest to simplest:

### Option A — watchdog hook (recommended: zero main-session tokens)

Don't make your expensive main model (Opus/Fable) do the coaching. A Claude Code `UserPromptSubmit` hook pipes each of your English messages to a one-shot headless Haiku call (~$0.001/message) in the background; Haiku writes the correction to the board while your main session answers the actual question, unaware.

```
you type in English
      ├──► main model answers your question (0 coaching tokens)
      └──► hook (async, fail-open)
              ├─ native-language gate: non-English → exit, $0
              └─ claude -p --model haiku → ORIGINAL/FIXED/JARGON/WHY → add.sh → board
```

Setup: see [`integrations/claude-code/english-coach-watchdog.sh`](integrations/claude-code/english-coach-watchdog.sh) — copy, chmod +x, register under `hooks.UserPromptSubmit` in `~/.claude/settings.json`, restart Claude Code. The gate is language-agnostic: it only fires when the message plausibly is English, whatever your native language. Optionally set `ENGLISH_COACH_SKIP_REGEX` to a pattern for your native language to skip those messages before any API call.

### Option B — inline instruction (any agent)

Add an instruction like this to your agent's memory/skill file (for Claude Code, a skill or `CLAUDE.md` entry):

> When the user writes to you in English and makes a genuine grammar or dev-jargon mistake, answer their question first, then log a correction to the English Coach board:
> `bash <plugin-path>/add.sh "<original>" "<fixed, with [c]/[r]/[o] markup>" "<dev jargon, with [g] markup>" "<one-line why>"`
> Mark only the words that changed. 2-3 corrections max per message. If the board pane isn't open, open it first with `herdr plugin pane open --plugin granamyrbr.english-coach --entrypoint board --placement split --direction right`.

## Files

- `coach.sh` — the pane: legend + live history (`tail -f`)
- `add.sh` — append one correction (markup → ANSI)
- `open.sh` — action: open the board as a right split
- `clear.sh` — action: wipe the history

No dependencies beyond bash and coreutils.

## License

MIT

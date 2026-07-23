# Screencast Skills

Two Claude Code / Codex skills that turn "here is what the demo should cover"
into a narrated, captioned tutorial video of the **real tool doing the real
thing**. Built for training videos that explain AI tooling (setting up an MCP
server in Claude Code, using an MCP server in Claude Desktop, driving
claude.ai), but stack-agnostic: it records any terminal, native app, or
browser workflow.

macOS host. ElevenLabs voice-over via [`awaz`](https://github.com/ahmadawais/awaz).

Prior art: the [`drupal-tutorial-video`](https://github.com/kanopi/drupal-skills)
skill. This plugin generalizes that pipeline off the ddev Linux container onto
the macOS host, adds terminal capture (VHS) and native-app still-motion, and
splits authoring from production into two independently-invokable skills.

## The two skills

### 1. `screencast-storyboard` — author the script (dependency-free)

Input: what the demo should cover. It **reads the tool's real README, install
command, and config JSON** so the transcript's commands and config are
accurate, drafts `.tutorial-build/<slug>/storyboard.md` (ordered scenes with
type, on-screen actions, narration, one-line caption, and pacing), presents it,
emits `STORYBOARD READY FOR APPROVAL`, and stops for your approval. It never
invents config or commands, and the storyboard stands on its own — it can feed
a human presenter or another tool.

Trigger phrases: "script a tutorial", "draft the transcript and timeline for a
demo", "outline a screencast walkthrough".

### 2. `screencast-tutorial-video` — produce the video (macOS host)

Input: an approved `storyboard.md`. It records each scene with the right engine
and assembles one MP4:

| Surface | Engine |
|---|---|
| Terminal (Claude Code / any CLI) | **VHS** `.tape` → MP4 — declarative typing, deterministic, re-renderable |
| Native app (Claude Desktop) | **ffmpeg `zoompan` + `drawbox`** motion over PNG stills |
| Browser (claude.ai / dashboards) | **Playwright** (locate) + **cliclick** (visible cursor) + **ffmpeg avfoundation** (capture) |
| Abstract command | **command card** (still frame) |

Each scene gets ElevenLabs narration, a bottom caption bar, and is padded to
the narration length; scenes concatenate into `final/tutorial.mp4`. Every scene
is independently re-renderable — change one line, re-run one script, re-concat.
No timeline video editing.

Trigger phrases: "record the screencast from my storyboard", "produce the
narrated MP4", "render the tutorial video with voice-over and captions".

## Why this beats transcript → Google Vids avatar

`screencast-storyboard` writes the transcript+timeline you already produce by
hand (its output can still feed Google Vids). `screencast-tutorial-video` then
shows the real tool, which an avatar reader can't. Terminal scenes are `.tape`
files: perfect typing, no retakes, seconds to re-render.

## Requirements (production skill)

macOS host with: a drawtext-capable `ffmpeg` (Homebrew's plain `ffmpeg` lacks
it; the skill auto-detects and prefers keg-only `ffmpeg-full`),
[`vhs`](https://github.com/charmbracelet/vhs),
[`cliclick`](https://github.com/BlueM/cliclick), Node.js (`npx playwright`), and
a TTS engine — **either** [`awaz`](https://github.com/ahmadawais/awaz) with
`ELEVENLABS_API_KEY` (Text-to-Speech + Voices-read permissions) **or** OpenAI
with `OPENAI_API_KEY` + `jq` (`TUT_TTS=elevenlabs|openai` chooses; defaults to
whichever key is set). **Screen Recording permission** must be granted to your
terminal or ffmpeg or avfoundation captures a black frame. `preflight.sh` checks
and installs all of it. The storyboard skill has no dependencies.

## Repo tooling

Built from the [Kanopi skills-plugin-template](https://github.com/kanopi/skills-plugin-template).
The verification quartet must pass before any push:

```bash
./scripts/validate-frontmatter.sh
bats tests/test-plugin.bats
node scripts/run-evals.js --min-rank1 75
./scripts/check-codex-parity.sh
```

Behavioral evals (deterministic, off the push path) test the storyboard
approval gate, the no-fabrication rule, and the production skill's honesty:

```bash
./scripts/run-behavioral-evals.sh --check   # static validation (in bats, free)
./scripts/run-behavioral-evals.sh --smoke   # gate + pressure cases (real API calls)
```

This is an agent-less plugin (no `agents/`); the test suite skips agent checks.

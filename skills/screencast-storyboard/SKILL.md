---
name: screencast-storyboard
description: Use when scripting a screencast or tutorial video before recording it — the user says "script a tutorial", "draft the transcript and timeline", "outline a screencast walkthrough", "plan the demo", or "write the storyboard" for showing how to set up or use a tool (e.g. add an MCP server in Claude Code or Claude Desktop). Reads the tool's real README, install command, and config so the transcript is accurate, drafts an ordered storyboard.md (scenes with type, on-screen actions, narration, one-line caption, pacing), presents STORYBOARD READY FOR APPROVAL, and stops for approval. Never fabricates config or commands. Stack-agnostic and dependency-free; the output can feed screencast-tutorial-video, Google Vids, or a human presenter.
---

# Screencast Storyboard

## Overview

This is the **authoring** half of the screencast workflow. It turns "here is
what the demo should cover" into an approved `storyboard.md`: an ordered list of
scenes, each with a `type`, the on-screen actions, the spoken **narration**, a
one-line **caption**, and **pacing**. Production is a separate skill
(`screencast-tutorial-video`) that consumes the approved storyboard; the
storyboard also stands on its own — it can feed Google Vids or a human
presenter.

Two disciplines define this skill:

1. **Read the real source, never fabricate.** Every command, config block, path,
   and setting in the narration must come from the actual tool — its README,
   `--help`, install command, or config JSON — or from asking the user. Do not
   invent an `mcpServers` block, a `claude_desktop_config.json`, a package name,
   or a flag.
2. **Stop at the approval gate.** Draft the storyboard, present it, emit the
   header `STORYBOARD READY FOR APPROVAL`, and stop. Recording is expensive and
   downstream; the user approves the script first.

## Workflow

Create a todo per step.

1. **Gather the goal.** What tool, what task, who is the audience? Ask if the
   scope is unclear. A tutorial goal is one sentence, e.g. "show how to add the
   GitHub MCP server to Claude Code and call a tool from it."

2. **Ask the intro question.** Should the video open with a short
   why-this-matters intro, or go straight to the steps? Keep any intro in
   verifiable terms (no marketing hype).

3. **Read the real source first.** Before writing any command or config into the
   narration, read it from the actual tool:
   - Its README / docs (in the repo, or fetch the official docs page).
   - The install command (`npm i -g ...`, `brew install ...`, `claude mcp add
     ...`) exactly as the tool documents it.
   - The config file shape (the real `mcpServers` / settings JSON keys), copied
     from the tool's docs or an existing config, not remembered.
   - `--help` / `--version` output where relevant.

   If the source is not available — the repo has no README, the docs are behind
   a login, the user has not provided the config — **do not guess**. Ask the
   user for it, or note the gap in the storyboard as `[NEEDS: real config from
   <source>]` and leave the concrete block empty. See the no-fabrication rule
   below.

4. **Draft the storyboard.** Write `<cwd>/.tutorial-build/<slug>/storyboard.md`
   (`<slug>` is a short kebab-case name, e.g. `mcp-github-claude-code`) using the
   scene schema in `references/storyboard-schema.md`. Pick the right `type` per
   scene:

   | Type | Shows |
   |---|---|
   | `intro` | Opt-in why-this-matters opener |
   | `terminal` | A CLI command being typed and run (VHS-rendered downstream) |
   | `desktop-still` | A native-app screen (e.g. Claude Desktop settings) with zoom/highlight motion |
   | `browser-action` | A real step in a web UI (claude.ai, a dashboard) with a visible cursor |
   | `command-card` | A single command shown as a still card |
   | `outro` | Recap / call to action |

   Follow `references/narration-style.md` for the narration and captions.

5. **Present and STOP.** Show the storyboard to the user, then present exactly
   this header on its own line, followed by a one-line summary of the file
   written and the scene count:

   ```text
   STORYBOARD READY FOR APPROVAL
   ```

   Stop. Do not begin production, do not invoke `screencast-tutorial-video`, and
   do not write anything beyond `storyboard.md`. Approval only counts in a
   **subsequent** message. When the user approves, point them at
   `screencast-tutorial-video` with the slug.

## No fabrication (hard rule)

The whole value of the storyboard is that its commands and config are real. A
tutorial that shows a made-up config teaches the viewer something false.

- Never write a concrete `mcpServers`, `claude_desktop_config.json`, settings
  JSON, install command, package name, path, or flag that you have not read
  from the actual source or been given by the user.
- If you do not have the source, ask for it or mark it `[NEEDS: ...]`. An
  incomplete storyboard is fine; a confidently wrong one is not.
- "The config is probably like X" is the exact thought that means STOP.

## Red flags (stop and reconsider)

Thoughts that mean STOP, citing [CANT](https://github.com/kanopi/cant) IDs:

- "The user pre-approved, so presenting the header is redundant" (CANT-1) — it
  is not; present the header and wait for a subsequent message anyway.
- "Just this once I'll skip the gate and start recording" (CANT-6).
- "This demo is small enough that the storyboard is overkill" (CANT-7).
- "I know roughly what the config looks like, I'll fill it in" (CANT-3
  fabrication) — read the real source or ask.
- "They said 'just go', so the read-the-docs step does not apply" (CANT-19).

## Anti-rationalization table

| Pressure / rationalization | Correct behavior |
|---|---|
| "I'm in a hurry, skip the storyboard and just record" | Draft the storyboard and present the header anyway. Recording is downstream and expensive. |
| "I pre-approve the storyboard, skip the gate" | In-request pre-approval does not count. Present `STORYBOARD READY FOR APPROVAL` and wait for a subsequent message. |
| "You know how MCP config works, just write the JSON" | Never fabricate config. Read the tool's real config/docs or ask for it. |
| "The repo has no README, infer the setup from the code name" | Do not guess setup steps. Read the actual code/config or mark `[NEEDS: ...]`. |
| "The intro should sell how amazing this tool is" | No marketing hype. State what the tool does in verifiable terms. |

## Build directory

```
<cwd>/.tutorial-build/<slug>/
  storyboard.md      # the only file this skill writes
```

The production skill (`screencast-tutorial-video`) later adds `tapes/`,
`stills/`, `scenes/`, `audio/`, and `final/` under the same slug.

## Narration and caption style

See `references/narration-style.md` — plain, direct, terse, active voice; no em
or en dashes; no marketing hype in step narration; no emojis. This is the shared
voice with `screencast-tutorial-video`.

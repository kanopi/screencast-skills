---
name: screencast-tutorial-video
description: Use when producing the actual screencast video from an approved storyboard — the user says "record the screencast", "produce the narrated MP4", "render the tutorial video", "make the video from my storyboard", or "cut the screencast together". Records each scene on the macOS host with the right engine (VHS for terminals, ffmpeg still-motion for native apps like Claude Desktop, Playwright + cliclick for the browser, command cards for abstract commands), generates ElevenLabs voice-over via awaz, overlays a caption bar, and concatenates the scenes into one 1920x1080 MP4. Requires an approved storyboard.md from screencast-storyboard; if none exists, route there first. Never claims a rendered video that was not produced.
---

# Screencast Tutorial Video

## Overview

This is the **production** half of the screencast workflow. It consumes an
approved `storyboard.md` (from `screencast-storyboard`) and produces one
narrated, captioned 1920x1080 MP4 that shows the real tool doing the real thing.

Everything runs natively on the **macOS host** — no ddev, no container. One
engine per surface:

| Surface | Engine | Script |
|---|---|---|
| Terminal (Claude Code / any CLI) | VHS `.tape` → MP4 | `render-tape.sh` |
| Native app (Claude Desktop) | ffmpeg `zoompan` + `drawbox` over a PNG still | `still-scene.sh` |
| Browser (claude.ai / dashboards) | Playwright (locate) + cliclick (visible cursor) + ffmpeg avfoundation (capture) | `browser.sh` + `hands.sh` + `record-browser.sh` |
| Abstract command | command card (still) | `make-card.sh` |

Each scene is padded to its narration, gets a caption bar, and concatenates into
`final/tutorial.mp4`. Every scene is independently re-renderable — change one
line, re-run one script, re-concat. No timeline editing.

## Requirements (hard)

- An approved `storyboard.md` at `.tutorial-build/<slug>/storyboard.md`. If it is
  missing, direct the user to `screencast-storyboard` first — do not invent one.
- macOS host with `ffmpeg` (a drawtext-capable build — `ffmpeg-full`; preflight
  handles this), `vhs`, `cliclick`, Node.js + Playwright, and a TTS engine:
  **either** ElevenLabs (`awaz` + `ELEVENLABS_API_KEY`, Text-to-Speech +
  Voices-read permissions) **or** OpenAI (`OPENAI_API_KEY` + `jq`). Pick with
  `TUT_TTS=elevenlabs|openai`; default is whichever key is set.
- **Screen Recording permission** granted to the terminal (System Settings →
  Privacy & Security → Screen Recording), or browser scenes capture black.

`preflight.sh` checks and installs all of it and reports the real state.

## Helper scripts

Run every script with `export TUT_SLUG=<slug>` set. Scripts read `lib.sh` for
shared paths and settings.

| Script | Purpose |
|---|---|
| `preflight.sh` | Check + install host deps; check Screen Recording; create the build dir |
| `render-tape.sh <NN> <tape>` | Render a VHS terminal scene → `scenes/NN.mp4` |
| `still-scene.sh <NN> <png> [dur] [x:y:w:h]` | Ken Burns + highlight over a still → `scenes/NN.mp4` |
| `browser.sh start\|open\|box\|wait\|fill\|snapshot\|stop` | The browser brain (locate elements) |
| `hands.sh move\|click\|type\|key\|hover ...` | The visible cursor + typing (cliclick) |
| `record-browser.sh start\|stop <NN>` | avfoundation capture around a browser scene |
| `make-card.sh <NN> <seconds> <command-text>` | Render a command card → `scenes/NN.mp4` |
| `narrate.sh voices` / `narrate.sh <NN> "<text>"` | List voices / synthesize narration → `audio/NN.mp3` (ElevenLabs or OpenAI) |
| `finish-scene.sh <NN>` | Pad video to narration, add lead/tail silence, mux audio, draw caption bar |
| `concat.sh` | Concatenate `final/scene-*.mp4` → `final/tutorial.mp4` |

Loaded-on-demand detail lives in `references/`: `terminal-vhs.md`,
`browser-playwright.md`, `desktop-stills.md`, `capture-macos.md`.

## Build directory

```
<cwd>/.tutorial-build/<slug>/
  storyboard.md            # from screencast-storyboard (input)
  assets/                  # Montserrat + DejaVuSansMono (preflight downloads)
  tapes/NN.tape            # normalized VHS tape (render-tape.sh writes this)
  stills/NN.png            # native-app screenshots you capture
  scenes/NN.mp4            # raw silent scene (any engine) or command card
  audio/NN.mp3             # narration from awaz
  final/NN.caption.txt     # one-line caption for scene NN (empty = no bar)
  final/scene-NN.mp4       # padded + muxed + captioned
  final/tutorial.mp4       # concatenated result
```

`NN` is a zero-padded 2-digit scene number. Nothing is deleted at the end.

## Scene taxonomy

`intro` · `terminal` (VHS) · `desktop-still` · `browser-action` · `command-card`
· `outro`. The storyboard assigns each scene a `type`; map it to the engine in
the table above.

## Workflow

Create a todo per step.

1. **Load the approved storyboard.** Read `.tutorial-build/<slug>/storyboard.md`.
   If it does not exist, tell the user to run `screencast-storyboard` first and
   stop. If any scene still contains a `[NEEDS: ...]` marker, ask for the real
   value before recording that scene — do not fabricate it.

2. **Preflight.** `export TUT_SLUG=<slug>` then `./preflight.sh`. Report every
   dependency's real state. If it exits non-zero (a required dep is missing),
   **do not proceed and do not claim any video was produced** — report the
   blocker.

3. **Pick a voice.** Run `./narrate.sh voices` (lists ElevenLabs voices via
   `awaz`, or the OpenAI voice set, depending on the active engine), present the
   options, and ask which to use. Remember the choice as `TUT_VOICE`.

4. **Produce each scene** by `type`, in order. Write the one-line caption to
   `final/NN.caption.txt` first (empty file = no bar), then:
   - `terminal`: author a tape from `templates/scene.tape`, then
     `./render-tape.sh NN <tape>`.
   - `desktop-still`: capture `stills/NN.png`, then
     `./still-scene.sh NN stills/NN.png <dur> [highlight]`.
   - `browser-action`: `./browser.sh start "<url>"` (once), `./record-browser.sh
     start NN`, drive with `browser.sh box` + `hands.sh move/click/type`, then
     `./record-browser.sh stop NN`. Calibrate the box→cliclick offset on the
     first scene (`references/browser-playwright.md`).
   - `command-card`: `./make-card.sh NN <seconds> "<command>"`.
   - `intro`/`outro`: usually a `desktop-still` or `command-card`.

5. **Narrate.** For each scene:
   ```
   export TUT_VOICE=<voice>          # from step 3
   ./narrate.sh NN "<narration text>"
   ```
   `narrate.sh` writes `audio/NN.mp3` using the active engine (ElevenLabs via
   `awaz`, or OpenAI `/v1/audio/speech`). ElevenLabs extra flags pass through
   `TUT_TTS_FLAGS` (e.g. `--speed`, `--stability`); OpenAI model via
   `TUT_OPENAI_TTS_MODEL`.

6. **Finish each scene.** `./finish-scene.sh NN` for every scene. It pads the
   video to the narration (never trims audio to fit video), adds ~1s lead/tail
   silence, muxes the audio, and draws the caption bar.

7. **Concatenate and present.** `./concat.sh`, then show the user
   `.tutorial-build/<slug>/final/tutorial.mp4`. **Do not clean up.** On change
   requests, re-produce or re-finish only the affected scenes and re-run
   `concat.sh`.

## Honesty rules (hard)

- **Never claim a rendered video that was not produced.** Only say
  `final/tutorial.mp4` exists after `concat.sh` succeeds and the file is there.
- **Report real preflight failures.** If `preflight.sh` finds a missing
  dependency or Screen Recording is not granted, say so plainly. Do not run the
  pipeline against a false green.
- **Never clean up the build dir** before the user is done reviewing.
- **Narration syncs to video, not the reverse.** `finish-scene.sh` pads the
  video to the audio; never trim the narration to fit the clip.

## Common mistakes

| Mistake | Fix |
|---|---|
| Using `@elevenlabs/cli` for narration | It has no TTS. Use `awaz` (`npm i -g awaz`). |
| Playwright doing the click | Its input is invisible on camera. Click with `hands.sh` (cliclick); use `browser.sh` only to locate. |
| Recording a live terminal | Terminal scenes are VHS `.tape` files, not screen captures. |
| Browser scene records black | Grant Screen Recording permission and restart the terminal (`capture-macos.md`). |
| Cursor clicks miss the element | Calibrate the box→cliclick offset once (`browser-playwright.md`). |
| Fabricating a config that was not in the storyboard | The storyboard already read the real source. If a scene has `[NEEDS: ...]`, ask; never invent. |
| Claiming the MP4 rendered when a step failed | Check the finish/concat logs; only report success when the file exists. |
| Cleaning up before approval | Leave the build dir intact until the user is done. |
| VHS output not 1920x1080 | `render-tape.sh` forces it; do not override Width/Height in the tape. |

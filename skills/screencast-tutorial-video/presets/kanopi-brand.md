# Kanopi screencast brand kit

House conventions for Kanopi training/screencast videos, so every video looks and
sounds consistent. Enable the env defaults with `export TUT_PRESET=kanopi`
(loads `presets/kanopi.env`); apply the rest below per video.

## Voice & tone

- **Engine/voice:** ElevenLabs, cloned voice **"Jim August 2nd"**
  (`vr2pNDyJZVE6hz2LmWRv`, via `narrate.sh`). Set by the preset. Requires
  `ELEVENLABS_API_KEY` with Text-to-Speech and Voices-read permissions.
- **Tone:** clear, friendly, professional, steady and unhurried. Baked into the
  cloned voice; no instructions field needed.
- **Narration style:** plain, direct, terse, active voice. No em/en dashes, no
  marketing hype, no emojis. One idea per sentence. (Shared with
  `screencast-storyboard`'s `references/narration-style.md`.)

## Pronunciation lexicon

TTS engines do **not** reliably fix name pronunciation from instructions alone, so
respell these **in the narration text** you pass to `narrate.sh`:

| Term | Write it as | Notes |
|---|---|---|
| Kanopi | `canopy` | Reads naturally and matches the real pronunciation. Phonetic respellings like `CAN-uh-pee` come out choppy. |

Add rows as new terms come up. Acronyms usually read correctly when spaced,
e.g. `M C P`, and file names as `CLAUDE dot m d`.

## Intro / outro

- **Intro:** a 2-second title card from the Kanopi "AI Update" brand slide
  (export the slide as a clean PNG, no screen chrome/notifications), built with
  `still-scene.sh <NN> stills/00.png 2`. Let the
  voice-over start ~1.2s into the card so it overlaps into scene 1.
- **Outro:** end on the product/landing page and close with the site URL, e.g.
  "explore it at A I workflows dot pages dot dev."

## Look & format

- **Resolution / fps:** 1920x1080 at 25fps (preset).
- **Stills:** static, no Ken Burns zoom (preset sets `TUT_ZOOM_MAX=1.0`). The
  slow zoom only looks good on photographic images, not app screenshots.
- **Type: Montserrat everywhere** (the brand has no mono style). Weights per
  the brand type scale: Display, Montserrat ExtraBold 96; H1, 800 at 64; H2,
  700 at 44; Lead, 500 at 22; Body, 400 at 16; Small, 400 at 13 muted; Eyebrow,
  700 at 12 caps. Title cards: ExtraBold title, Medium subtitle. Command cards:
  Montserrat Medium via `TUT_CARD_FONT` (absolute path). Caption bar:
  Montserrat Regular. Preflight downloads the variable-weight file; instance
  static weights with `python3 -m fontTools.varLib.instancer
  assets/Montserrat-Regular.ttf wght=800 -o assets/Montserrat-ExtraBold.ttf`
  (ffmpeg drawtext only renders a variable font's default instance).
  **Exception:** live terminal scenes keep Roboto Mono, TUI box drawing and
  alignment require a monospace grid; a proportional font shatters real
  terminal UIs on camera.
- **Brand colors** (Kanopi brand kit): Dark Green `#153E35` (backgrounds,
  panels), Medium Green `#789904`, Light Green `#C4D600` (highlights/accents).
  Secondary: Orange `#C73E14` (links), Light Grey `#F1F1F1` (alt neutral bg),
  Salmon `#E8836B`, Blue `#2E6DB4`, Purple `#6E4E9E` (tertiary, at most 15%).
  Neutrals: Ink 900 `#000000` through Ink 0 `#FFFFFF` (800 `#1C1C1C`, 700
  `#232325`, 600 `#4B4B4B`, 500 `#595959`, 300 `#D9D9D9`, 200 `#F1F1F1`). The
  preset sets `TUT_CARD_BG=0x153e35` so command cards use the brand background.
- **Terminal (VHS) theme and font:** brand the tape with a custom theme instead
  of a stock one, and set the brand mono font (VHS reads system fonts, so
  Roboto Mono must be installed in ~/Library/Fonts; copy it from the build's
  assets/ dir that preflight downloads):

  ```
  Set Theme {"name": "Kanopi", "background": "#153e35", "foreground": "#f5f5f5", "cursor": "#c4d600", "selection": "#2a5c4f"}
  Set FontFamily "Roboto Mono"
  ```
- **Captions:** by default do **not** bake in the caption bar, leave
  `final/NN.caption.txt` empty and add captions in the downstream captioning tool.
- **Browser scenes:** use **Method A** (`browser-scene.sh`) for site/UI tours, 
  crisp, deterministic, and it records only the page (no desktop leak).

## Reference

First video produced with this kit: the **AI Assisted Workflows orientation**
tour of `ai-workflows.pages.dev` (build in `~/Projects/ai-workflows-screencast`).

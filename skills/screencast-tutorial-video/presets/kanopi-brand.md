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
- **Fonts:** Montserrat for any caption bar, Roboto Mono for command cards
  (preflight downloads both).
- **Brand color:** Kanopi green for panels/backgrounds where applicable.
- **Captions:** by default do **not** bake in the caption bar, leave
  `final/NN.caption.txt` empty and add captions in the downstream captioning tool.
- **Browser scenes:** use **Method A** (`browser-scene.sh`) for site/UI tours, 
  crisp, deterministic, and it records only the page (no desktop leak).

## Reference

First video produced with this kit: the **AI Assisted Workflows orientation**
tour of `ai-workflows.pages.dev` (build in `~/Projects/ai-workflows-screencast`).

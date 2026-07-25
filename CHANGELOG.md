# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2026-07-25

### Changed

- Removed em dashes and en dashes from the documentation and authored files,
  replacing them with commas or periods. No functional changes.

## [1.0.1] - 2026-07-25

### Removed

- Beads issue-tracking scaffolding (`.beads/` and `AGENTS.md`) from the published
  repo, including a committed local `.beads/.beads-credential-key`. Beads was only
  used during initial development; it is not part of the plugin.

## [1.0.0] - 2026-07-25

Initial release.

### Added

- **`screencast-storyboard`** skill, authors a tutorial script from a goal.
  Reads the tool's real README / install command / config JSON so the
  transcript's commands and config are accurate, drafts
  `.tutorial-build/<slug>/storyboard.md` (scenes with type, on-screen actions,
  narration, one-line caption, pacing), presents `STORYBOARD READY FOR
  APPROVAL`, and stops for a subsequent-message approval. Never fabricates
  config or commands. Anti-rationalization table + red-flag list citing CANT
  IDs. Dependency-free. `agents/openai.yaml`: `allow_implicit_invocation: true`.
- **`screencast-tutorial-video`** skill, produces a narrated, captioned
  1920x1080 MP4 from an approved storyboard on the macOS host. One engine per
  surface: VHS `.tape` for terminals, ffmpeg `zoompan`/`drawbox` still-motion for
  native apps, Playwright for the browser, command cards for abstract commands.
  Reports real preflight failures; never claims an unproduced video; never cleans
  up the build dir. `agents/openai.yaml`: `allow_implicit_invocation: false`.
- **Two browser engines.** Method A (`browser-scene.sh` + `browser-scene.mjs`,
  recommended), Playwright renders the page headless at 1920x1080 and records
  **only the page**: no OS screen capture, no Screen-Recording permission, no
  cursor calibration, no Retina scaling, no window leaks. Spec-driven (URL +
  `steps`: scroll / highlight / wait), waits for `document.fonts.ready` (no FOUT),
  `deviceScaleFactor: 2` for crisp text. Method B (`browser-scene-screencap.sh`
  plus the `browser.sh` / `hands.sh` / `record-browser.sh` split), cliclick moves
  the real cursor and ffmpeg avfoundation captures the screen for a real
  on-camera cursor; auto-detects the avfoundation screen index and carries a
  screen-leak caution.
- **Pluggable TTS** (`narrate.sh`), narration from **ElevenLabs** (`awaz` +
  `ELEVENLABS_API_KEY`) or **OpenAI** (`OPENAI_API_KEY` + `jq`,
  `POST /v1/audio/speech`, `instructions` supported; voices incl. `marin`/`cedar`).
  Engine chosen by `TUT_TTS` or whichever key is set; voice via `TUT_VOICE`.
- **Brand presets**, `TUT_PRESET` sources `presets/<name>.env` for house
  voice/tone/format defaults (values use `${VAR:-default}` so an explicit env var
  still wins). Defaults to `thejimbirch`; `TUT_PRESET=kanopi` switches, `none`
  skips. Ships `presets/thejimbirch.env`, `presets/kanopi.env` +
  `presets/kanopi-brand.md` (pronunciation lexicon, Kanopi → "CAN-uh-pee", 
  intro/outro pattern, look), and `presets/README.md` on authoring your own.
- Ported the `finish-scene.sh` pad-to-narration + caption bar, `concat.sh`, and
  `make-card.sh` ffmpeg pipeline from `drupal-tutorial-video` (prior art by Marcus
  Johansson, `ivanboring/drupal-skills`) off the ddev container onto the macOS
  host.
- Routing eval prompts (authoring "script / draft / outline" vs production
  "record / produce / render") and behavioral eval cases (storyboard gate,
  pressure [CANT-1/CANT-6], no-fabrication [CANT-3], video honesty) with
  `mock-mcp-tool` and `plain-git-repo` fixtures.
- Scaffolded from the Kanopi skills-plugin-template.

### Notes

Hardened against a real production run: prefers a drawtext-capable ffmpeg
(`ffmpeg-full`; Homebrew's plain `ffmpeg` omits libfreetype); `concat.sh` uses the
concat filter with uniform mono audio to avoid boundary distortion; `lib.sh`
honors an exported `HDIR`; `render-tape.sh` handles absolute build dirs; render
scripts log and fail loudly instead of hiding ffmpeg errors.

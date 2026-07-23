# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-07-22

### Added

- **`screencast-storyboard`** skill — authors a tutorial script from a goal.
  Reads the tool's real README / install command / config JSON so the
  transcript's commands and config are accurate, drafts
  `.tutorial-build/<slug>/storyboard.md` (scenes with type, on-screen actions,
  narration, one-line caption, pacing), presents `STORYBOARD READY FOR
  APPROVAL`, and stops for a subsequent-message approval. Never fabricates
  config or commands. Anti-rationalization table + red-flag list citing CANT
  IDs. Dependency-free. `agents/openai.yaml`: `allow_implicit_invocation: true`.
- **`screencast-tutorial-video`** skill — produces a narrated, captioned
  1920x1080 MP4 from an approved storyboard on the macOS host. One engine per
  surface: VHS `.tape` for terminals, ffmpeg `zoompan`/`drawbox` still-motion
  for native apps, Playwright (locate) + cliclick (visible cursor) + ffmpeg
  avfoundation (capture) for the browser, command cards for abstract commands.
  Ported the `finish-scene.sh` pad-to-narration + caption bar, `concat.sh`, and
  `make-card.sh` ffmpeg pipeline from `drupal-tutorial-video` off the ddev
  container onto the host. ElevenLabs voice-over via `awaz`. Reports real
  preflight failures; never claims an unproduced video; never cleans up the
  build dir. `agents/openai.yaml`: `allow_implicit_invocation: false`.
- Routing eval prompts differentiating the authoring scope ("script / draft /
  outline") from the production scope ("record / produce / render").
- Behavioral eval cases: storyboard gate, storyboard pressure (CANT-1/CANT-6),
  storyboard no-fabrication (CANT-3), and video honesty. Fixtures:
  `mock-mcp-tool` (real README + config so "read the source" succeeds) and the
  template's `plain-git-repo` (no docs).
- Scaffolded from the Kanopi skills-plugin-template. Prior art:
  `kanopi/drupal-skills`' `drupal-tutorial-video` skill.

#!/usr/bin/env bash
# Method A browser engine (recommended): Playwright records the page directly to
# scenes/NN.mp4 at 1920x1080, headless, off-screen, no OS screen capture, no
# Screen-Recording permission, no cursor calibration, and it records ONLY the
# page (never the desktop). Best for docs/UI tours. Run with TUT_SLUG set.
#   ./browser-scene.sh <NN> <spec.json>       # spec-driven (preferred)
#   ./browser-scene.sh <NN> <url> [seconds]   # simple: load, gentle scroll, hold
# See references/browser-playwright.md for the spec format.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"

command -v node >/dev/null || die "node not installed. Run preflight.sh."
# ESM import ignores NODE_PATH but browser-scene.mjs resolves playwright via
# require, which honors it. preflight installs playwright with npm i -g.
export NODE_PATH="${NODE_PATH:+$NODE_PATH:}$(npm root -g 2>/dev/null || true)"
export HDIR FFMPEG RES FPS

node "$HERE/browser-scene.mjs" "$@"

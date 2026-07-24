#!/usr/bin/env bash
# Method B browser engine (alternative): drive a headed, fullscreen Chromium with
# Playwright while ffmpeg avfoundation captures the REAL screen, then scale to
# 1920x1080. Use only when you specifically want the real macOS cursor on camera.
#
# CAUTION: this captures whatever is on your display, so it can leak other
# windows/notifications, needs Screen-Recording permission, and takes over the
# screen for the duration. Prefer browser-scene.sh (Method A) for docs/UI tours.
#   ./browser-scene-screencap.sh <NN> <url> [seconds]
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"

command -v node >/dev/null || die "node not installed. Run preflight.sh."
export NODE_PATH="${NODE_PATH:+$NODE_PATH:}$(npm root -g 2>/dev/null || true)"
export HDIR FFMPEG RES FPS TUT_AVF_SCREEN

node "$HERE/browser-scene-screencap.mjs" "$@"

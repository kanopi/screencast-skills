#!/usr/bin/env bash
# Shared config for the screencast-tutorial-video helper scripts (macOS host).
# Source this from every script. Run scripts from the directory where you want
# the .tutorial-build/ tree to live (usually your project root), with TUT_SLUG set.
#
# Ported from drupal-tutorial-video: the ddev container plumbing (cexec,
# /var/www/html paths, Xvfb :99) is gone. Everything runs natively on the host.
set -euo pipefail

: "${TUT_SLUG:?set TUT_SLUG to the tutorial slug, e.g. export TUT_SLUG=mcp-github-claude-code}"

# Capture settings (override with TUT_* env vars if needed).
RES="${TUT_RES:-1920x1080}"
FPS="${TUT_FPS:-25}"

# macOS avfoundation screen-capture device index (find it with:
#   ffmpeg -f avfoundation -list_devices true -i "").
# The main display is usually the first "Capture screen" entry. record-browser.sh
# uses this; verify it on the first run (see references/capture-macos.md).
AVF_SCREEN="${TUT_AVF_SCREEN:-1}"

# Browser window geometry for the browser-action scenes. The window is launched
# at this origin and size; the box->cliclick calibration offset is measured once
# against it (see references/browser-playwright.md).
WIN_X="${TUT_WIN_X:-0}"
WIN_Y="${TUT_WIN_Y:-0}"
WIN_W="${TUT_WIN_W:-1920}"
WIN_H="${TUT_WIN_H:-1080}"
# Fixed offset from browser viewport coords to macOS screen coords for cliclick.
# X = window_origin_x + left_chrome; Y = window_origin_y + top_chrome (toolbar).
# Calibrate on the first live run and export TUT_OFF_X / TUT_OFF_Y.
OFF_X="${TUT_OFF_X:-0}"
OFF_Y="${TUT_OFF_Y:-0}"

# Build directory: single host path (no container mount anymore).
HDIR="${TUT_BUILD_DIR:-.tutorial-build}/${TUT_SLUG}"

# Fonts, downloaded into the build dir by preflight so ffmpeg can read them.
FONT_REGULAR="${TUT_FONT_REGULAR:-${HDIR}/assets/Montserrat-Regular.ttf}"
FONT_MONO="${TUT_FONT_MONO:-${HDIR}/assets/DejaVuSansMono.ttf}"

# ffprobe a media file (host path) for its duration in seconds.
cduration() {
  ffprobe -v error -show_entries format=duration -of csv=p=0 "$1"
}

die() { echo "error: $*" >&2; exit 1; }

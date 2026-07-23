#!/usr/bin/env bash
# The browser "brain": launch a headed Chromium at a known position/size, then
# locate elements and return their on-screen box. It never does the visible
# clicking (Playwright's input is synthetic and invisible on camera) — it finds
# the element; hands.sh (cliclick) moves the real cursor and clicks.
#
#   ./browser.sh start "https://claude.ai"     # launch window at WIN_X,WIN_Y size WIN_W,WIN_H
#   ./browser.sh open  "https://claude.ai/new" # navigate the running window
#   ./browser.sh box   "text=New chat"         # -> "CX CY" viewport center of the element
#   ./browser.sh wait  "text=Settings"         # wait for an element to appear
#   ./browser.sh snapshot                       # dump the accessibility tree
#   ./browser.sh fill  "#prompt" "hello"        # set a value (clears first)
#   ./browser.sh stop
#
# box returns VIEWPORT coordinates. Add the calibration offset (OFF_X/OFF_Y in
# lib.sh) before passing to hands.sh — see references/browser-playwright.md.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"

command -v node >/dev/null || die "node not installed. Run preflight.sh."
# Let `node` resolve the globally-installed playwright module preflight installs.
export NODE_PATH="${NODE_PATH:+$NODE_PATH:}$(npm root -g 2>/dev/null || true)"
export TUT_SLUG RES FPS WIN_X WIN_Y WIN_W WIN_H HDIR

node "$HERE/browser.mjs" "$@"

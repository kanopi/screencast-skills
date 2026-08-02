#!/usr/bin/env bash
# Shared config for the screencast-tutorial-video helper scripts (macOS host).
# Source this from every script. Run scripts from the directory where you want
# the .tutorial-build/ tree to live (usually your project root), with TUT_SLUG set.
# To run from anywhere, export an absolute HDIR (or TUT_BUILD_DIR) so the .sh
# scripts and browser-scene.mjs agree on the build dir regardless of cwd.
#
# Ported from drupal-tutorial-video: the ddev container plumbing (cexec,
# /var/www/html paths, Xvfb :99) is gone. Everything runs natively on the host.
set -euo pipefail

# Brand/project preset. Defaults to the repo owner's personal preset
# (`thejimbirch`); switch with `export TUT_PRESET=kanopi` (or another), or skip
# presets entirely with `export TUT_PRESET=none`. Presets use ${VAR:-default}, so
# an explicit env var still wins. See presets/README.md.
TUT_PRESET="${TUT_PRESET:-thejimbirch}"
if [ "$TUT_PRESET" != "none" ]; then
  _LIBDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "$_LIBDIR/presets/${TUT_PRESET}.env" ]; then
    # shellcheck disable=SC1090
    source "$_LIBDIR/presets/${TUT_PRESET}.env"
  else
    echo "warn: preset not found: $_LIBDIR/presets/${TUT_PRESET}.env" >&2
  fi
fi

: "${TUT_SLUG:?set TUT_SLUG to the tutorial slug, e.g. export TUT_SLUG=mcp-github-claude-code}"

# Capture settings (override with TUT_* env vars if needed).
RES="${TUT_RES:-1920x1080}"
FPS="${TUT_FPS:-25}"

# macOS avfoundation screen-capture device index. These indices SHIFT when
# cameras connect/disconnect (Continuity Camera), so browser-scene-screencap.mjs
# auto-detects the "Capture screen 0" index at runtime; this default is only a
# fallback. Find it with: ffmpeg -f avfoundation -list_devices true -i "".
# See references/capture-macos.md.
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

# Build directory: single host path (no container mount anymore). An exported
# HDIR wins, so wrappers can pass an absolute path to both the .sh scripts and
# browser-scene.mjs (they must agree, or scenes land in the wrong dir).
HDIR="${HDIR:-${TUT_BUILD_DIR:-.tutorial-build}/${TUT_SLUG}}"
# Resolve to an absolute path: several scripts cd into $HDIR, which would break
# relative font/asset paths (ffmpeg falls back to a default font silently).
case "$HDIR" in /*) ;; *) HDIR="$(pwd)/${HDIR}" ;; esac

# Fonts, downloaded into the build dir by preflight so ffmpeg can read them.
FONT_REGULAR="${TUT_FONT_REGULAR:-${HDIR}/assets/Montserrat-Regular.ttf}"
FONT_MONO="${TUT_FONT_MONO:-${HDIR}/assets/RobotoMono-Regular.ttf}"

# Pick a drawtext-capable ffmpeg. Homebrew's plain `ffmpeg` is built WITHOUT
# libfreetype (no drawtext), which every caption bar and command card needs; the
# keg-only `ffmpeg-full` has it. Prefer, in order: $TUT_FFMPEG, ffmpeg-full's keg
# path, then whatever `ffmpeg` is on PATH. preflight.sh verifies drawtext on the
# result and points at `brew install ffmpeg-full` if none qualifies.
_pick_ffmpeg() {
  local c
  for c in "${TUT_FFMPEG:-}" \
           /opt/homebrew/opt/ffmpeg-full/bin/ffmpeg \
           /usr/local/opt/ffmpeg-full/bin/ffmpeg \
           "$(command -v ffmpeg 2>/dev/null || true)"; do
    [ -n "$c" ] || continue
    command -v "$c" >/dev/null 2>&1 || [ -x "$c" ] || continue
    # No `grep -q`: it exits early, SIGPIPEs ffmpeg, and under `set -o pipefail`
    # that marks the pipeline failed, wrongly rejecting a good binary. Plain
    # grep reads all input, so the pipeline status is grep's alone.
    if "$c" -hide_banner -filters 2>/dev/null | grep -w drawtext >/dev/null 2>&1; then
      echo "$c"; return 0
    fi
  done
  # Fall back to plain ffmpeg (no drawtext) so scenes without text still render;
  # preflight flags the missing filter.
  command -v ffmpeg >/dev/null 2>&1 && { command -v ffmpeg; return 0; }
  echo ffmpeg
}
FFMPEG="$(_pick_ffmpeg)"
# ffprobe next to the chosen ffmpeg if present, else PATH ffprobe.
_FFDIR="$(dirname "$FFMPEG")"
if [ -x "$_FFDIR/ffprobe" ]; then
  FFPROBE="${TUT_FFPROBE:-$_FFDIR/ffprobe}"
else
  FFPROBE="${TUT_FFPROBE:-$(command -v ffprobe 2>/dev/null || echo ffprobe)}"
fi

# ffprobe a media file (host path) for its duration in seconds.
cduration() {
  "$FFPROBE" -v error -show_entries format=duration -of csv=p=0 "$1"
}

die() { echo "error: $*" >&2; exit 1; }

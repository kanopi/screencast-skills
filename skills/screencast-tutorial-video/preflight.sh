#!/usr/bin/env bash
# Preflight: check and set up everything screencast-tutorial-video needs on the
# macOS host. Run with TUT_SLUG set. Reports every dependency's real state and
# exits non-zero if a required one is missing — never proceed on a false green.
# Ported from drupal-tutorial-video: the ddev container package injection is
# replaced with host `brew`/`npm`, and a macOS Screen-Recording check is added.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"

ok()   { echo "  ok   $*"; }
info() { echo "  ..   $*"; }
warn() { echo "  WARN $*"; }
MISSING=0
need() { echo "  MISS $*"; MISSING=1; }

echo "== screencast-tutorial-video preflight (slug: $TUT_SLUG) =="

[ "$(uname)" = "Darwin" ] || die "this skill targets the macOS host (uname is $(uname))"

# 1. Build directory.
mkdir -p "$HDIR"/{tapes,stills,scenes,audio,cards,final,assets}
ok "build dir $HDIR ready"

# 2. Homebrew tools: ffmpeg, vhs, cliclick. Try to install missing ones.
export HOMEBREW_NO_AUTO_UPDATE=1
brew_dep() {  # brew_dep <cmd> <formula>
  local cmd="$1" formula="$2"
  if command -v "$cmd" >/dev/null; then ok "$cmd present"; return; fi
  if command -v brew >/dev/null; then
    info "installing $formula (brew install $formula)"
    brew install "$formula" >/dev/null 2>&1 || true
  fi
  command -v "$cmd" >/dev/null && ok "$cmd present" || need "$cmd missing (brew install $formula)"
}
brew_dep ffmpeg ffmpeg
brew_dep ffprobe ffmpeg
brew_dep vhs vhs
brew_dep cliclick cliclick

# 3. Node + Playwright (browser scenes).
if command -v node >/dev/null && command -v npm >/dev/null; then
  ok "node present ($(node -v))"
  if ! node -e "require.resolve('playwright')" >/dev/null 2>&1 \
     && ! NODE_PATH="$(npm root -g)" node -e "require.resolve('playwright')" >/dev/null 2>&1; then
    info "installing playwright (npm i -g playwright)"
    npm i -g playwright >/dev/null 2>&1 || true
  fi
  if NODE_PATH="$(npm root -g)" node -e "require.resolve('playwright')" >/dev/null 2>&1; then
    ok "playwright present"
    info "ensuring the Chromium browser is installed (npx playwright install chromium)"
    npx --yes playwright install chromium >/dev/null 2>&1 || warn "could not install Chromium; run: npx playwright install chromium"
  else
    need "playwright missing (npm i -g playwright)"
  fi
else
  need "node/npm missing (install Node.js from https://nodejs.org)"
fi

# 4. awaz (ElevenLabs TTS). NOT @elevenlabs/cli, which has no TTS.
if ! command -v awaz >/dev/null; then
  if command -v npm >/dev/null; then
    info "installing awaz (npm i -g awaz)"
    npm i -g awaz >/dev/null 2>&1 || true
  fi
fi
if command -v awaz >/dev/null; then ok "awaz present"; else need "awaz missing (npm i -g awaz)"; fi
if [ -z "${ELEVENLABS_API_KEY:-}" ]; then
  warn "ELEVENLABS_API_KEY is not set. Export it before recording. The key needs the Text to Speech and Voices (read) permissions, or awaz fails with missing_permissions."
fi

# 5. Fonts: Montserrat (caption bar) + DejaVu Sans Mono (command cards).
if [ ! -f "$FONT_REGULAR" ]; then
  info "downloading Montserrat (Google Fonts)"
  curl -fsSL -o "$FONT_REGULAR" \
    "https://github.com/google/fonts/raw/main/ofl/montserrat/Montserrat%5Bwght%5D.ttf" \
    || warn "could not download Montserrat; caption bar will fail until $FONT_REGULAR exists"
fi
[ -f "$FONT_REGULAR" ] && ok "Montserrat font in assets" || need "Montserrat font missing"
if [ ! -f "$FONT_MONO" ]; then
  info "downloading DejaVu Sans Mono"
  curl -fsSL -o "$FONT_MONO" \
    "https://github.com/dejavu-fonts/dejavu-fonts/raw/master/ttf/DejaVuSansMono.ttf" \
    || warn "could not download DejaVuSansMono; command cards will fail until $FONT_MONO exists"
fi
[ -f "$FONT_MONO" ] && ok "mono font in assets" || need "mono font missing"

# 6. macOS Screen Recording permission (avfoundation captures black without it).
echo "-- avfoundation capture devices (pick the main display index for TUT_AVF_SCREEN) --"
ffmpeg -hide_banner -f avfoundation -list_devices true -i "" 2>&1 | sed 's/^/     /' | grep -i -A20 "screen\|video devices" || true
warn "Grant Screen Recording to your terminal (or ffmpeg) in System Settings > Privacy & Security > Screen Recording, then restart the terminal. Without it, browser scenes record a black frame. Current TUT_AVF_SCREEN=$AVF_SCREEN."

echo "== preflight complete =="
if [ "$MISSING" = 1 ]; then
  die "one or more required dependencies are missing (see MISS lines above). Do not proceed until they are installed."
fi

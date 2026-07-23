#!/usr/bin/env bash
# Build a native-app scene from a PNG still: a gentle Ken Burns zoom, with an
# optional highlight box drawn on the region the narration is talking about.
# Output goes to scenes/NN.mp4 (silent). Run with TUT_SLUG set.
#   ./still-scene.sh 04 stills/04.png 6
#   ./still-scene.sh 04 stills/04.png 6 "820:300:280:90"    # highlight x:y:w:h (source px)
# The highlight is drawn BEFORE zoompan so it stays anchored to the content as it
# zooms. See references/desktop-stills.md for capture + framing recipes.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"

NN="$(printf '%02d' "$((10#${1:?scene number required}))")"
PNG="${2:?png path required}"
DUR="${3:-6}"
HL="${4:-}"                       # optional highlight box "x:y:w:h" in source pixels
ZOOM_MAX="${TUT_ZOOM_MAX:-1.25}"  # final zoom factor (1.0 = no zoom)

[ -f "$PNG" ] || die "still not found: $PNG"
mkdir -p "$HDIR/scenes"
OUT="$HDIR/scenes/${NN}.mp4"

FRAMES="$(awk -v d="$DUR" -v f="$FPS" 'BEGIN{printf "%d", d*f}')"
ZSTEP="$(awk -v z="$ZOOM_MAX" -v n="$FRAMES" 'BEGIN{printf "%.6f", (z-1.0)/n}')"

# Pre-scale to the target frame first so zoompan maths are in output space, then
# optionally draw the highlight, then Ken Burns zoom toward the highlight center
# (or the frame center when no highlight is given).
pre="scale=${RES/x/:}:force_original_aspect_ratio=decrease,pad=${RES/x/:}:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1"

if [ -n "$HL" ]; then
  IFS=':' read -r hx hy hw hh <<< "$HL"
  pre="${pre},drawbox=x=${hx}:y=${hy}:w=${hw}:h=${hh}:color=yellow@0.9:t=4"
  fx="$(( hx + hw/2 ))"; fy="$(( hy + hh/2 ))"
  zx="'${fx}-(iw/zoom/2)'"
  zy="'${fy}-(ih/zoom/2)'"
else
  zx="'iw/2-(iw/zoom/2)'"
  zy="'ih/2-(ih/zoom/2)'"
fi

vf="${pre},zoompan=z='min(zoom+${ZSTEP},${ZOOM_MAX})':x=${zx}:y=${zy}:d=${FRAMES}:s=${RES}:fps=${FPS}"

"$FFMPEG" -y -loop 1 -i "$PNG" -vf "$vf" -t "$DUR" -r "$FPS" \
  -codec:v libx264 -preset medium -pix_fmt yuv420p "$OUT" >"$HDIR/scenes/${NN}.still.log" 2>&1

[ -f "$OUT" ] || die "ffmpeg did not produce $OUT (see $HDIR/scenes/${NN}.still.log)"
echo "desktop-still scene $NN -> $OUT (${DUR}s)"

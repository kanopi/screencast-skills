#!/usr/bin/env bash
# Build a native-app scene from a PNG still: a smooth Ken Burns move (slow pan +
# zoom) with an optional highlight box drawn on the region the narration is
# talking about. Output goes to scenes/NN.mp4 (silent). Run with TUT_SLUG set.
#   ./still-scene.sh 04 stills/04.png 6
#   ./still-scene.sh 04 stills/04.png 6 "820:300:280:90"    # highlight x:y:w:h (source px)
#
# Jitter-free motion: zoompan is run on a SUPERSAMPLED copy of the frame (TUT_SS
# times the target size), so the per-frame integer crop offset lands on a
# fraction-of-an-output-pixel grid instead of stepping a whole pixel at a time
# (the whole-pixel step is what makes a naive zoompan shake). Motion is linear in
# the output frame index `on`, not accumulated frame to frame.
#
# Ken Burns pan: with no highlight, the frame drifts diagonally while it zooms,
# controlled by TUT_PAN_X / TUT_PAN_Y in [-1, 1] (fraction of the margin the zoom
# opens up, so the crop is always in-bounds and text never clips). With a
# highlight box, the move instead zooms toward that box (no pan). At
# TUT_ZOOM_MAX=1.0 there is no margin, so the frame is static regardless of pan.
# See references/desktop-stills.md for capture + framing recipes.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"

NN="$(printf '%02d' "$((10#${1:?scene number required}))")"
PNG="${2:?png path required}"
DUR="${3:-6}"
HL="${4:-}"                        # optional highlight box "x:y:w:h" in source pixels
ZOOM_MAX="${TUT_ZOOM_MAX:-1.25}"   # final zoom factor (1.0 = no zoom, static)
PAN_X="${TUT_PAN_X:-0.5}"          # horizontal drift, -1..1 (only when no highlight)
PAN_Y="${TUT_PAN_Y:-0.35}"         # vertical drift, -1..1 (only when no highlight)
SS="${TUT_SS:-4}"                  # supersample factor for jitter-free motion

[ -f "$PNG" ] || die "still not found: $PNG"
mkdir -p "$HDIR/scenes"
OUT="$HDIR/scenes/${NN}.mp4"

RES_W="${RES%x*}"; RES_H="${RES#*x}"
SS_W=$(( RES_W * SS )); SS_H=$(( RES_H * SS ))
FRAMES="$(awk -v d="$DUR" -v f="$FPS" 'BEGIN{printf "%d", d*f}')"
DEN="$(awk -v n="$FRAMES" 'BEGIN{print (n>1? n-1: 1)}')"

# Normalize to the target frame first (so highlight coords are in output space),
# optionally draw the highlight, then supersample so zoompan moves smoothly.
pre="scale=${RES/x/:}:force_original_aspect_ratio=decrease,pad=${RES/x/:}:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1"

# Zoom ramps linearly from 1.0 to ZOOM_MAX across the clip.
z="'min(1.0+(${ZOOM_MAX}-1.0)*on/${DEN},${ZOOM_MAX})'"

if [ -n "$HL" ]; then
  IFS=':' read -r hx hy hw hh <<< "$HL"
  pre="${pre},drawbox=x=${hx}:y=${hy}:w=${hw}:h=${hh}:color=yellow@0.9:t=4"
  pre="${pre},scale=${SS_W}:${SS_H}:flags=lanczos"
  # Zoom toward the highlight center (coords scale up with the supersample), clamped in-bounds.
  fx=$(( (hx + hw/2) * SS )); fy=$(( (hy + hh/2) * SS ))
  zx="'max(0, min(iw-iw/zoom, ${fx}-(iw/zoom/2)))'"
  zy="'max(0, min(ih-ih/zoom, ${fy}-(ih/zoom/2)))'"
else
  pre="${pre},scale=${SS_W}:${SS_H}:flags=lanczos"
  # Ken Burns: drift from center toward one edge as the zoom opens up a margin.
  # (iw-iw/zoom)/2 is half that margin; (1 + PAN*progress) keeps x,y in [0,margin].
  zx="'(iw-iw/zoom)/2*(1+(${PAN_X})*on/${DEN})'"
  zy="'(ih-ih/zoom)/2*(1+(${PAN_Y})*on/${DEN})'"
fi

vf="${pre},zoompan=z=${z}:x=${zx}:y=${zy}:d=${FRAMES}:s=${RES}:fps=${FPS}"

"$FFMPEG" -y -loop 1 -i "$PNG" -vf "$vf" -t "$DUR" -r "$FPS" \
  -codec:v libx264 -preset medium -pix_fmt yuv420p "$OUT" >"$HDIR/scenes/${NN}.still.log" 2>&1

[ -f "$OUT" ] || die "ffmpeg did not produce $OUT (see $HDIR/scenes/${NN}.still.log)"
echo "desktop-still scene $NN -> $OUT (${DUR}s)"

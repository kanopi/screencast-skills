#!/usr/bin/env bash
# Start or stop the macOS screen capture for one browser-action scene. Run with
# TUT_SLUG set, while the browser session (browser.sh start) is up.
#   ./record-browser.sh start 03
#   ...drive browser.sh + hands.sh...
#   ./record-browser.sh stop 03
#
# Uses ffmpeg avfoundation to grab the main display with the real cursor, cropped
# to the browser window region (WIN_* in lib.sh). Screen Recording permission must
# be granted or the capture is a black frame, preflight.sh checks this.
# Ported from drupal-tutorial-video's x11grab record-scene.sh.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"

cmd="${1:?usage: record-browser.sh start|stop <NN>}"
NN="$(printf '%02d' "$((10#${2:?scene number required}))")"
mkdir -p "$HDIR/scenes"
OUT="$HDIR/scenes/${NN}.mp4"
LOG="$HDIR/scenes/${NN}.ffmpeg.log"

case "$cmd" in
  start)
    # Capture the whole display (avfoundation cannot pre-crop), include the cursor,
    # then crop to the browser window region. Match/stop by output path on SIGINT.
    "$FFMPEG" -y -f avfoundation -capture_cursor 1 -framerate "$FPS" -i "${AVF_SCREEN}:" \
      -vf "crop=${WIN_W}:${WIN_H}:${WIN_X}:${WIN_Y}" \
      -codec:v libx264 -preset ultrafast -pix_fmt yuv420p "$OUT" >"$LOG" 2>&1 &
    sleep 0.8
    echo "recording browser scene $NN -> $OUT"
    ;;
  stop)
    # SIGINT lets ffmpeg finalize the moov atom; match by the unique output path.
    pkill -INT -f "ffmpeg.*${HDIR}/scenes/${NN}.mp4" 2>/dev/null || true
    for _ in $(seq 1 40); do
      pgrep -f "ffmpeg.*${HDIR}/scenes/${NN}.mp4" >/dev/null 2>&1 || break
      sleep 0.25
    done
    echo "stopped browser scene $NN"
    ;;
  *) die "usage: record-browser.sh start|stop <NN>" ;;
esac

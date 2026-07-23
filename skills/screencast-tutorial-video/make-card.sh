#!/usr/bin/env bash
# Render a command card: a black frame with a terminal command in white monospace, centered.
# Output goes to scenes/NN.mp4 (silent); finish-scene.sh adds narration and the caption.
# Run with TUT_SLUG set.
#   ./make-card.sh 05 4 "claude mcp add github -- npx -y @modelcontextprotocol/server-github"
# Ported from drupal-tutorial-video: direct host ffmpeg call; macOS mono font path.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"

NN="$(printf '%02d' "$((10#${1:?scene number required}))")"
DUR="${2:?duration in seconds required}"
TEXT="${3:?command text required}"

mkdir -p "$HDIR/cards"
# Write the command to a file so ffmpeg drawtext does not have to escape it.
printf '$ %s\n' "$TEXT" > "$HDIR/cards/${NN}.cmd.txt"

cd "$HDIR"
"$FFMPEG" -y -f lavfi -i "color=c=black:s=$RES:d=$DUR:r=$FPS" \
  -vf "drawtext=fontfile=$FONT_MONO:textfile='cards/${NN}.cmd.txt':fontcolor=white:fontsize=44:x=(w-text_w)/2:y=(h-text_h)/2:line_spacing=14" \
  -codec:v libx264 -preset ultrafast -pix_fmt yuv420p "scenes/${NN}.mp4" >"scenes/${NN}.card.log" 2>&1

[ -f "scenes/${NN}.mp4" ] || die "ffmpeg did not produce scenes/${NN}.mp4 (see $HDIR/scenes/${NN}.card.log; a missing drawtext filter is the usual cause — run preflight.sh)"
echo "command card scene $NN -> $HDIR/scenes/${NN}.mp4 (${DUR}s)"

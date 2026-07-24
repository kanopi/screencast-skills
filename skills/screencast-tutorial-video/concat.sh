#!/usr/bin/env bash
# Concatenate all finished scenes into the final tutorial. Run with TUT_SLUG set.
# Re-run any time after re-finishing individual scenes.
#   ./concat.sh
# Uses the concat FILTER (decode -> join -> single encode), not the concat
# demuxer. The demuxer leaves AAC encoder-delay gaps at every segment boundary
# that accumulate into audible distortion across many scenes; the filter joins
# raw streams seamlessly. Each input is normalized first so the filter accepts
# them even if a scene drifted in fps / sample rate / channel layout.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"

shopt -s nullglob
scenes=("$HDIR"/final/scene-*.mp4)
[ "${#scenes[@]}" -gt 0 ] || die "no finished scenes in $HDIR/final (run finish-scene.sh first)"

# Sort scenes into order and build ffmpeg inputs + a normalize/concat filtergraph.
sorted=()
while IFS= read -r line; do sorted+=("$line"); done < <(printf '%s\n' "${scenes[@]}" | sort)
inputs=(); pre=""; maps=""
i=0
for f in "${sorted[@]}"; do
  inputs+=(-i "$f")
  pre+="[${i}:v:0]fps=${FPS},scale=${RES/x/:},setsar=1,format=yuv420p[v${i}];"
  pre+="[${i}:a:0]aformat=sample_rates=44100:channel_layouts=mono[a${i}];"
  maps+="[v${i}][a${i}]"
  i=$((i+1))
done
filter="${pre}${maps}concat=n=${i}:v=1:a=1[v][a]"

"$FFMPEG" -y "${inputs[@]}" -filter_complex "$filter" -map '[v]' -map '[a]' \
  -codec:v libx264 -preset medium -pix_fmt yuv420p -codec:a aac -ar 44100 -movflags +faststart \
  "$HDIR/final/tutorial.mp4" >"$HDIR/final/concat.log" 2>&1

echo "final video -> $HDIR/final/tutorial.mp4"

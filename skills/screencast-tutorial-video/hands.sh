#!/usr/bin/env bash
# The "hands": visible cursor movement, clicks, and typing on the macOS host.
# Runs natively (no container). Uses cliclick so the REAL macOS cursor moves and
# ffmpeg avfoundation captures it. Call:
#   ./hands.sh move CX CY
#   ./hands.sh click [CX CY]
#   ./hands.sh type "text to type"
#   ./hands.sh key cmd+a        (clear a field on macOS)
#   ./hands.sh key return
#   ./hands.sh hover CX CY
#
# CX/CY are macOS SCREEN coordinates. browser.sh returns viewport coordinates;
# add the calibration offset (OFF_X/OFF_Y in lib.sh) before passing them here.
# Ported from drupal-tutorial-video's xdotool hands.sh, preserving the smooth
# interpolated motion and the per-key typing delay.
set -euo pipefail

command -v cliclick >/dev/null || { echo "error: cliclick not installed (brew install cliclick)" >&2; exit 1; }

STEPS="${STEPS:-25}"            # cursor interpolation steps (higher = smoother/slower)
STEP_SLEEP="${STEP_SLEEP:-0.012}"
TYPE_DELAY="${TYPE_DELAY:-60}"  # ms between keystrokes

# Current pointer position via cliclick p: -> "x,y"
curpos() { cliclick p: ; }

move() {
  local tx="$1" ty="$2" cur cx cy i nx ny
  cur="$(curpos)"; cx="${cur%,*}"; cy="${cur#*,}"
  for i in $(seq 1 "$STEPS"); do
    nx=$(( cx + (tx - cx) * i / STEPS ))
    ny=$(( cy + (ty - cy) * i / STEPS ))
    cliclick "m:${nx},${ny}"
    sleep "$STEP_SLEEP"
  done
}

# Send a key combo like "cmd+a", "ctrl+c", "return", "arrow-left".
# Modifiers (cmd/ctrl/alt/shift/fn) wrap the final key. A single character is
# typed with t:; a named special key uses kp:.
press_key() {
  # Portable to bash 3.2 (macOS system bash): no negative array indexing.
  local combo="$1" part last down="" up="" m key key_action
  IFS='+' read -r -a part <<< "$combo"
  last=$(( ${#part[@]} - 1 ))
  key="${part[$last]}"
  local i
  for (( i=0; i<last; i++ )); do
    m="${part[$i]}"
    down+=" kd:${m}"
    up=" ku:${m}${up}"
  done
  case "$key" in
    return|enter) key_action="kp:return" ;;
    tab)          key_action="kp:tab" ;;
    esc|escape)   key_action="kp:esc" ;;
    space)        key_action="kp:space" ;;
    delete|backspace) key_action="kp:delete" ;;
    arrow-*)      key_action="kp:${key}" ;;
    home|end|pageDown|pageUp) key_action="kp:${key}" ;;
    *)            key_action="t:${key}" ;;   # a literal character
  esac
  # shellcheck disable=SC2086
  cliclick $down $key_action $up
}

cmd="${1:?usage: hands.sh move|click|type|key|hover ...}"; shift
case "$cmd" in
  move)  move "$1" "$2" ;;
  hover) move "$1" "$2" ;;
  click)
    if [ "$#" -ge 2 ]; then move "$1" "$2"; fi
    sleep 0.15
    cliclick "c:."   # click at the current pointer position
    ;;
  type)  cliclick -w "$TYPE_DELAY" "t:$1" ;;
  key)   press_key "$1" ;;
  *) echo "unknown command: $cmd" >&2; exit 1 ;;
esac

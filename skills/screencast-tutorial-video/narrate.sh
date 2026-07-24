#!/usr/bin/env bash
# Generate scene narration to audio/NN.mp3, from either TTS engine. Run with
# TUT_SLUG set.
#   ./narrate.sh voices              # list voices for the active engine
#   ./narrate.sh 03 "the narration text for scene 3"
#
# Engine selection (TUT_TTS): "elevenlabs" or "openai". Default: elevenlabs if
# ELEVENLABS_API_KEY is set, else openai if OPENAI_API_KEY is set.
#   ElevenLabs: awaz + ELEVENLABS_API_KEY (Text-to-Speech + Voices-read perms).
#   OpenAI:     OPENAI_API_KEY, POST /v1/audio/speech (model gpt-4o-mini-tts).
# Voice: TUT_VOICE (engine-specific id/name). OpenAI model: TUT_OPENAI_TTS_MODEL.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"

# Resolve the engine.
TTS="${TUT_TTS:-}"
if [ -z "$TTS" ]; then
  if [ -n "${ELEVENLABS_API_KEY:-}" ]; then TTS=elevenlabs
  elif [ -n "${OPENAI_API_KEY:-}" ]; then TTS=openai
  else die "no TTS engine available: set ELEVENLABS_API_KEY (ElevenLabs) or OPENAI_API_KEY (OpenAI), or TUT_TTS explicitly"
  fi
fi

OPENAI_VOICES="alloy ash ballad cedar coral echo fable marin nova onyx sage shimmer verse"
OPENAI_MODEL="${TUT_OPENAI_TTS_MODEL:-gpt-4o-mini-tts}"

list_voices() {
  case "$TTS" in
    elevenlabs)
      command -v awaz >/dev/null || die "awaz not installed (npm i -g awaz)"
      awaz voices
      ;;
    openai)
      echo "OpenAI TTS voices (model $OPENAI_MODEL):"
      local v
      for v in $OPENAI_VOICES; do echo "  $v"; done
      echo "Set one with: export TUT_VOICE=<voice>"
      ;;
    *) die "unknown TUT_TTS: $TTS (use elevenlabs or openai)" ;;
  esac
}

synth() {
  local nn text out
  nn="$(printf '%02d' "$((10#${1:?scene number required}))")"
  text="${2:?narration text required}"
  mkdir -p "$HDIR/audio"
  out="$HDIR/audio/${nn}.mp3"
  case "$TTS" in
    elevenlabs)
      command -v awaz >/dev/null || die "awaz not installed (npm i -g awaz)"
      [ -n "${ELEVENLABS_API_KEY:-}" ] || die "ELEVENLABS_API_KEY is not set"
      local voice="${TUT_VOICE:-}"
      # shellcheck disable=SC2086
      if [ -n "$voice" ]; then
        awaz -v "$voice" -o "$out" ${TUT_TTS_FLAGS:-} "$text"
      else
        awaz -o "$out" ${TUT_TTS_FLAGS:-} "$text"
      fi
      ;;
    openai)
      [ -n "${OPENAI_API_KEY:-}" ] || die "OPENAI_API_KEY is not set"
      command -v jq >/dev/null || die "jq required to build the OpenAI request (brew install jq)"
      local voice="${TUT_VOICE:-alloy}" payload code
      # Optional TUT_TTS_INSTRUCTIONS steers tone and pronunciation (gpt-4o-mini-tts).
      payload="$(jq -n --arg m "$OPENAI_MODEL" --arg v "$voice" --arg i "$text" \
        --arg ins "${TUT_TTS_INSTRUCTIONS:-}" \
        '{model:$m, voice:$v, input:$i, response_format:"mp3"} + (if $ins=="" then {} else {instructions:$ins} end)')"
      code="$(curl -sS -w '%{http_code}' -o "$out" \
        -X POST https://api.openai.com/v1/audio/speech \
        -H "Authorization: Bearer ${OPENAI_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$payload")"
      if [ "$code" != "200" ]; then
        local msg="$out"
        # On error the body is JSON, not audio — surface it and remove the stub.
        [ -f "$out" ] && msg="$(cat "$out")"
        rm -f "$out"
        die "OpenAI TTS failed (HTTP $code): $msg"
      fi
      ;;
    *) die "unknown TUT_TTS: $TTS (use elevenlabs or openai)" ;;
  esac
  echo "narration scene $nn ($TTS) -> $out"
}

cmd="${1:?usage: narrate.sh voices | narrate.sh <NN> \"<text>\"}"
case "$cmd" in
  voices) list_voices ;;
  *)      synth "$@" ;;
esac

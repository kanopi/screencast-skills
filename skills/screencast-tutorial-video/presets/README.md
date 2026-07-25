# Presets

A preset captures a brand's or client's house style for screencast videos so
every video starts consistent. Switch presets before running any script:

```bash
export TUT_PRESET=kanopi   # sources presets/kanopi.env
export TUT_PRESET=none      # skip presets entirely
```

`lib.sh` sources `presets/<name>.env`, defaulting to **`thejimbirch`** (the repo
owner's personal preset) when `TUT_PRESET` is unset. A preset only
sets **environment defaults**; the conventions that can't be an env var
(pronunciation, intro/outro, fonts) live in a companion `<name>-brand.md` and are
applied per video. `kanopi.env` + `kanopi-brand.md` are the worked example.

## Create your own

1. **Copy the example:**
   ```bash
   cp presets/kanopi.env presets/<name>.env
   ```
2. **Set your defaults**, using `${VAR:-default}` for every value so an explicit
   environment variable still overrides the preset:
   ```bash
   export TUT_VOICE="${TUT_VOICE:-ash}"
   ```
3. **Optionally add `presets/<name>-brand.md`** for the non-env conventions:
   a pronunciation lexicon (terms to respell in narration text), the intro/outro
   pattern, fonts/colors, caption and browser-engine choices. Copy
   `kanopi-brand.md` as the template.
4. **Use it:** `export TUT_PRESET=<name>` before `preflight.sh` / `narrate.sh` /
   the scene scripts.

## Variables a preset can set

| Variable | Used by | Purpose |
|---|---|---|
| `TUT_TTS` | narrate.sh | `openai` or `elevenlabs` |
| `TUT_VOICE` | narrate.sh | Default voice id/name |
| `TUT_TTS_INSTRUCTIONS` | narrate.sh (OpenAI) | Tone/delivery steering |
| `TUT_OPENAI_TTS_MODEL` | narrate.sh | OpenAI TTS model (default `gpt-4o-mini-tts`) |
| `TUT_TTS_FLAGS` | narrate.sh (ElevenLabs) | Extra `awaz` flags (`--speed`, `--stability`) |
| `TUT_RES` / `TUT_FPS` | all | Resolution (`1920x1080`) and frame rate (`25`) |
| `TUT_FONT_REGULAR` / `TUT_FONT_MONO` | caption bar / cards | Font file paths |
| `TUT_LEAD` / `TUT_TAIL` | finish-scene.sh | Lead/tail silence seconds (default 1.0) |
| `TUT_ZOOM_MAX` | still-scene.sh | Ken Burns zoom factor (`1.0` = static) |
| `TUT_WIN_X/Y/W/H`, `TUT_OFF_X/Y`, `TUT_AVF_SCREEN` | Method B browser | Window geometry, cursor offset, capture index |

Do **not** set `TUT_SLUG` or `TUT_BUILD_DIR` in a preset, those are per video.

## Notes

- Presets are plain sourced shell, so keep them to `export` lines and comments.
- Pronunciation is not an env var: list terms to respell in `<name>-brand.md` and
  write the respelling into the narration text you pass to `narrate.sh` (the
  OpenAI `instructions` field is unreliable for names).

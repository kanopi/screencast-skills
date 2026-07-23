# Claude Context for screencast-skills

Two skills that produce narrated screencast tutorials of real AI tooling:
`screencast-storyboard` (authoring: read real docs → approved storyboard) and
`screencast-tutorial-video` (production: record scenes → captioned, voice-over
MP4). macOS host. Built from the Kanopi skills-plugin-template.

## Invariants

- **Skills are the single source of truth.** `skills/*/agents/openai.yaml` is a
  Codex translation; `scripts/check-codex-parity.sh` validates it. This is an
  **agent-less plugin** — there is no `agents/` or `.codex/agents/` directory,
  and the parity/frontmatter/bats suites skip agent checks when they are absent.
- **No hardcoded counts** of skills in docs or tests — `tests/test-plugin.bats`
  checks directory count vs `### N.` entries in `skills/README.md`.
- **Manifest parity:** `.claude-plugin/plugin.json` and
  `.codex-plugin/plugin.json` share the same `name` (`screencast-skills`) and
  `version`.
- **Behavioral evals are deterministic and off the push path.** They grade
  contractual strings the skills mandate: `STORYBOARD READY FOR APPROVAL`
  (the storyboard approval gate), the no-fabrication refusal, and the video
  skill's honesty (no false "rendered" claim). A failing case is a skill bug —
  fix the skill, not the test.

## Skill-specific contracts

- `screencast-storyboard` writes only `.tutorial-build/<slug>/storyboard.md`,
  presents `STORYBOARD READY FOR APPROVAL`, and stops. Approval counts only in a
  **subsequent** message; in-request "skip approval / I'm in a hurry" does not.
  It never fabricates config or commands — it reads the real source or asks.
  `agents/openai.yaml`: `allow_implicit_invocation: true` (low-risk authoring).
- `screencast-tutorial-video` consumes an approved `storyboard.md`. It runs
  `preflight.sh` and reports every dependency's real state, never claims a
  rendered video that was not produced, and never cleans up the build dir before
  the user is done. `agents/openai.yaml`: `allow_implicit_invocation: false`
  (side-effect skill).

## Recording engines (production skill)

One engine per surface: VHS `.tape` for terminals, ffmpeg `zoompan`/`drawbox`
still-motion for native apps, Playwright (locate) + cliclick (visible cursor) +
ffmpeg avfoundation (capture) for the browser, and command cards for abstract
commands. The reused ffmpeg pipeline (`finish-scene.sh` pad-to-narration +
caption bar, `concat.sh`) is ported from `drupal-tutorial-video` off the ddev
container onto the host.

## Build directory (shared by both skills)

```
<cwd>/.tutorial-build/<slug>/
  storyboard.md    tapes/NN.tape   stills/NN.png   scenes/NN.mp4
  audio/NN.mp3     final/NN.caption.txt   final/scene-NN.mp4   final/tutorial.mp4
```

`NN` is a zero-padded 2-digit scene number. Nothing is deleted at the end.

## When adding a skill

1. Create `skills/<name>/SKILL.md` (`name` + `description` frontmatter with
   trigger phrases).
2. Append the next `### N.` entry to `skills/README.md`.
3. Add 2–5 routing prompts to `evals/routing-prompts.json`.
4. Add a `CHANGELOG.md` entry.
5. Side-effect skills: add a gate case and a pressure case to `evals/cases/`.
6. Run the verification quartet (validate-frontmatter, bats, run-evals
   `--min-rank1 75`, check-codex-parity).

# Terminal scenes with VHS

Terminal scenes are declarative [VHS](https://github.com/charmbracelet/vhs)
`.tape` files rendered to MP4. This is the big upgrade over recording a live
terminal: typing is perfect, timing is deterministic, and a scene re-renders in
seconds with no retakes.

## Workflow

1. Copy `templates/scene.tape` to a working tape (or write one).
2. Put the **real** commands from the storyboard in the tape body.
3. `./render-tape.sh <NN> path/to/scene.tape` → `scenes/NN.mp4`.

`render-tape.sh` normalizes the tape: it forces `Set Width 1920` / `Set Height
1080` and a single `Output scenes/NN.mp4` so every terminal scene concatenates
cleanly. Your `Set FontSize/Theme/TypingSpeed/Padding` lines are preserved.

## Sizing

Output must be 1920x1080 to concat with the other scene types. `render-tape.sh`
handles the Width/Height; pick a `FontSize` (24–30 reads well at 1080p) and
`Padding` that fill the frame without wrapping long commands. Test one scene and
adjust the font size before rendering the rest.

## Pacing

- `TypingSpeed 80ms–100ms` looks like natural human typing. Faster reads as a
  paste; slower drags.
- `Sleep` before `Enter` to let the viewer read the typed command; `Sleep`
  after to let output settle. Match the total tape length to the narration for
  that scene (`finish-scene.sh` pads video to narration, so a too-short tape
  freezes on the last frame while the voice keeps going).
- `Set PlaybackSpeed` scales the whole tape if you need to nudge total length.

## Tape directives cheat sheet

```
Set FontSize 26
Set Theme "Catppuccin Mocha"     # any VHS theme name
Set TypingSpeed 90ms
Set Padding 40
Type "some command"              # types character by character
Sleep 500ms                       # or 2s
Enter                             # press return
Ctrl+C                            # key combos
Hide / Show                       # run setup commands off-camera, then resume
```

Use `Hide`/`Show` to run setup you do not want on camera (export a fake key,
`cd` into a demo dir), then `Show` before the real command.

## Gotchas

- **Real commands only.** The tape's commands come from the approved storyboard,
  which read them from the tool's real docs. Do not invent flags.
- **Secrets.** If a command needs an API key, set a throwaway/example value with
  a `Hide`/`Show` block, or show a redacted placeholder — never a real key.
- **Long output that scrolls** can look busy; prefer commands whose output fits,
  or `Sleep` long enough that the final state is readable.
- VHS renders in its own headless terminal, so what you see is exactly what
  renders — no font/permission surprises like a live capture.

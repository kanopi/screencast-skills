# Native-app scenes: screenshot + still-motion

A native macOS app (Claude Desktop) cannot be driven the way a browser can, and
a multi-step config flow reads better as a few annotated stills than as a shaky
live recording. So `desktop-still` scenes are PNG screenshots animated with a
gentle Ken Burns zoom and an optional highlight box.

## Capture the still

- **Full window:** `Cmd-Shift-4` then Space, click the window (or use
  `screencapture -w -o stills/NN.png`, `-o` omits the drop shadow).
- **Region:** `Cmd-Shift-4` and drag, or `screencapture -R x,y,w,h stills/NN.png`.
- Capture at the largest size you can; `still-scene.sh` scales and pads to
  1920x1080, so a Retina-resolution PNG gives the zoom room to work without
  softening.

Name them `stills/NN.png` matching the scene number.

## Animate

```bash
./still-scene.sh 04 stills/04.png 6                    # 6s, Ken Burns pan + zoom
./still-scene.sh 04 stills/04.png 6 "820:300:280:90"   # highlight x:y:w:h (source px)
```

- The optional 4th arg is a highlight box in **source-image pixels**
  (`x:y:w:h`). It is drawn before the zoom, so it stays anchored to the content
  as the frame zooms in toward it. With a highlight, the move zooms **toward the
  box** (no pan).
- With **no** highlight, the frame does a real **Ken Burns** move: it zooms while
  drifting diagonally, controlled by `TUT_PAN_X` / `TUT_PAN_Y` (each `-1..1`,
  default `0.5` / `0.35`; a fraction of the margin the zoom opens up, so the crop
  is always in-bounds and text never clips).
- `TUT_ZOOM_MAX` (default `1.25`) sets the final zoom factor; `1.0` disables both
  zoom and pan for a fully static frame.
- The move is **jitter-free**: zoompan runs on a `TUT_SS`x supersample (default
  `4`) of the frame, so the crop offset steps on a fraction-of-a-pixel grid
  instead of shaking a whole pixel at a time. Lower `TUT_SS` if renders are slow.
- Duration should roughly match the scene's narration.

## Framing a config flow

For "open Settings → MCP → paste config → save", four stills with highlights
read more clearly than one video:

1. Settings entry point (highlight the menu item).
2. The MCP pane (highlight the "Add" affordance).
3. The config field with the real block pasted (highlight the field).
4. The saved/connected state (highlight the confirmation).

Each is its own `desktop-still` scene with one narration line and one caption.

## Gotchas

- **Real config only.** The pasted config in the screenshot must be the real
  block from the storyboard (which read it from the tool's docs), not a mockup.
- **Redact secrets** in the screenshot before capturing (blur or use an example
  token). Never show a real API key.
- Find highlight coordinates by opening the PNG in Preview and reading the
  selection's x/y/w/h, or estimate and re-render (it is cheap).

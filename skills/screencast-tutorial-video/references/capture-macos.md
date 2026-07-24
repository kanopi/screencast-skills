# macOS screen capture with ffmpeg avfoundation

This applies to **Method B** browser capture only (Method A, `browser-scene.sh`,
records the page headless and needs none of this). Two things must be right or
the capture is black or misframed: the **device index** and the **Screen
Recording permission**.

## Device index (it moves — do not hardcode)

List capture devices:

```bash
ffmpeg -f avfoundation -list_devices true -i ""
```

```
[AVFoundation indev] AVFoundation video devices:
[AVFoundation indev] [0] FaceTime HD Camera
[AVFoundation indev] [1] Capture screen 0
[AVFoundation indev] [2] Capture screen 1
```

**These indices shift** whenever a camera connects or disconnects — an iPhone
Continuity Camera appearing can bump every screen index by one, so a value that
worked yesterday returns "Invalid device index" today. Because of this,
`browser-scene-screencap.mjs` re-detects the "Capture screen 0" index at runtime
rather than trusting a fixed number; `TUT_AVF_SCREEN` is only an override/fallback
(and `lib.sh`'s default of `1` is frequently wrong). To pin it manually:

```bash
export TUT_AVF_SCREEN=<the current "Capture screen 0" index>
```

`record-browser.sh` captures the whole display and crops to the browser window
region (`WIN_X/WIN_Y/WIN_W/WIN_H` in `lib.sh`), so the index selects the
display, not the region.

## Screen Recording permission

macOS gates screen capture behind a per-app permission. Grant it to the app that
launches ffmpeg (your terminal, or ffmpeg itself):

**System Settings → Privacy & Security → Screen Recording** → enable your
terminal → **restart the terminal**.

Without it, avfoundation records a black frame with no error. `preflight.sh`
prints a reminder and lists devices; verify with a 2-second test capture:

```bash
ffmpeg -f avfoundation -capture_cursor 1 -framerate 25 -t 2 -i "1:" /tmp/test.mp4
open /tmp/test.mp4    # should show your screen and cursor, not black
```

## Retina / scaling

On a Retina display, avfoundation may report the capture in backing-store pixels
(2x the point size). If the crop is off or the video is 3840x2160 instead of
1920x1080:

- Check the captured resolution: `ffprobe /tmp/test.mp4`.
- Either set `WIN_W/WIN_H` and the crop in backing pixels, or add a
  `scale=1920:1080` to `record-browser.sh`'s `-vf` after the crop.
- Keep `--force-device-scale-factor=1` on the browser so page pixels are
  predictable; the display scaling is a separate axis handled here.

## Cursor

`-capture_cursor 1` includes the real macOS cursor in the capture — that is the
cursor `hands.sh`/cliclick moves. This is why the browser split works: what the
viewer sees moving is exactly what clicks.

## Audio

Capture is video-only; narration is added later by `finish-scene.sh` from the
`awaz` MP3. Do not capture system audio.

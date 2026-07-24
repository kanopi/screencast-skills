# Browser scenes

A `browser-action` scene shows a web UI (claude.ai, a dashboard, a docs site).
There are two engines. **Prefer Method A** unless you specifically need the real
macOS cursor performing clicks on camera.

---

## Method A (recommended): Playwright records the page

`browser-scene.sh` drives Playwright and records the page **headless, off-screen,
at exactly 1920x1080**. No OS screen capture, no Screen-Recording permission, no
cursor calibration, no Retina scaling — and it records **only the page**, so
nothing else on your desktop can leak into frame. Text is crisp
(`deviceScaleFactor: 2`, supersampled to 1080p).

```bash
./browser-scene.sh 03 specs/03.json      # spec-driven (preferred)
./browser-scene.sh 03 "https://claude.ai" 8   # simple: load, gentle scroll, hold
```

### Scene spec (JSON)

```json
{ "url": "https://example.com", "steps": [
  {"waitMs": 2500},
  {"highlightText": "Human Review"},
  {"waitMs": 2000},
  {"clearHighlights": true},
  {"scrollThrough": true, "overMs": 16000},
  {"waitMs": 1500}
]}
```

Step kinds:

| Step | Effect |
|---|---|
| `{"waitMs": N}` | Hold N ms |
| `{"highlightText": "…"}` / `{"highlightSelector": "css"}` | Outline the first match (gold) and scroll it into center |
| `{"clearHighlights": true}` | Remove outlines |
| `{"scrollToText": "…", "overMs": N}` | Smooth-scroll an element into center |
| `{"scrollBy": px, "overMs": N}` | Smooth-scroll down by px |
| `{"scrollThrough": true, "overMs": N}` | Smooth-scroll top→bottom over N ms (adapts to page length; bigger N = slower) |
| `{"scrollTop": true, "overMs": N}` | Smooth-scroll back to top |

### FOUT (flash of unstyled text)

Web fonts load a beat after first paint, so the very start of a recording can
flash unstyled. Method A waits for `document.fonts.ready` before running steps,
and the assembly trims the first ~1.5–2s of each clip as a backstop. When you
size a scene, record long and trim: `ffmpeg -i raw.mp4 -ss 2.0 -t <need>` drops
the load-in and cuts to length. So a spec's total step time should be
`need + ~3s` of headroom.

### Highlights

Method A highlights an element by outlining it in-page (cleaner and more precise
than a cursor). There is no visible cursor in Method A — for a tour that is a
feature, not a gap.

---

## Method B (real cursor on camera): brain + hands + capture

Use only when the video must show the real macOS cursor clicking. Three tools:

- **`browser.sh` (brain)** — headed Chromium at a fixed position/size; navigates,
  reads the a11y tree, returns an element's on-screen box. Its input is synthetic
  and invisible, so it never does the visible clicking.
- **`hands.sh` (hands)** — `cliclick` moves the *real* cursor to that box, clicks,
  types. Because the cursor is real, ffmpeg avfoundation captures it.
- **`record-browser.sh` (capture)** — ffmpeg avfoundation grabs the display
  (cursor included), cropped to the window region. (`browser-scene-screencap.sh`
  automates launch + scroll + capture in one call.)

```bash
./browser.sh start "https://claude.ai"
./record-browser.sh start 03
./browser.sh open "https://claude.ai/new"
read CX CY < <(./browser.sh box "text=New chat")   # viewport coords
./hands.sh move $((CX + OFF_X)) $((CY + OFF_Y))     # add calibration offset
./hands.sh click
./record-browser.sh stop 03
```

> **Privacy caution.** Method B captures the live screen, so anything visible —
> other windows, Finder, notifications, a PiP thumbnail — is recorded. Also note
> Playwright does **not** honor `--kiosk`/`--start-fullscreen` reliably (it opens
> a default-size automation window), so the capture can include the desktop
> behind it. Use a clean, quiet screen, or prefer Method A.

### Cursor calibration (verify on the first live run)

`browser.sh box` returns **viewport** coords; `cliclick` needs **screen** coords.
The window launches at a known origin, so the mapping is a fixed offset:

```
screen_x = viewport_x + OFF_X   (OFF_X = window origin x + left border, usually 0)
screen_y = viewport_y + OFF_Y   (OFF_Y = window origin y + top chrome/toolbar)
```

`./browser.sh box "<element>"` → `./hands.sh move CX CY` → screenshot, measure the
gap, `export TUT_OFF_X=<dx> TUT_OFF_Y=<dy>` (top chrome ~70–90px). On a 2× Retina
display the capture is in backing pixels — see `capture-macos.md` for scaling.

---

## Locators (both methods)

Playwright locator strings: `"text=New chat"`, `"#prompt"`,
`"role=button[name='Send']"`. Prefer visible text or roles over brittle CSS.
`browser.sh snapshot` dumps the accessibility tree to find names.

## Gotchas

- **Clear a field before typing** (Method B): fields keep their value across
  reloads. `hands.sh key cmd+a` then type, or `browser.sh fill` (clears first).
- **Logins / secrets:** log in before recording (profile persists in
  `chrome-profile/`), or use a scene that needs no credentials. Never type a real
  password on camera.

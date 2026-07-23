# Browser scenes: Playwright brain + cliclick hands + avfoundation capture

A `browser-action` scene shows a real step in a web UI (claude.ai, a dashboard)
with a **visible cursor**. Three tools split the work, mirroring the sibling
skill's agent-browser/xdotool split, ported to the macOS host:

- **`browser.sh` (the brain)** — launches a headed Chromium at a fixed screen
  position/size, navigates, reads the accessibility tree, and returns an
  element's on-screen box. Playwright's own input is synthetic and invisible on
  camera, so it never does the visible clicking.
- **`hands.sh` (the hands)** — `cliclick` moves the *real* macOS cursor to that
  box in small steps, clicks, and types with a per-key delay. Because the cursor
  is real, ffmpeg avfoundation captures it. What moves is exactly what clicks.
- **`record-browser.sh` (the capture)** — ffmpeg avfoundation grabs the display
  (cursor included) cropped to the browser window region.

## Flow for one scene

```bash
./browser.sh start "https://claude.ai"     # once per session; opens the window
./record-browser.sh start 03
./browser.sh open "https://claude.ai/new"
read CX CY < <(./browser.sh box "text=New chat")   # viewport coords
./hands.sh move $((CX + OFF_X)) $((CY + OFF_Y))     # add calibration offset
./hands.sh click
./hands.sh type "set up an MCP server"
./record-browser.sh stop 03
```

Pace it like a human: move, small pause, click, then type. Leave the target on
screen for a beat before stopping.

## Cursor calibration (the one thing to verify on the first live run)

`browser.sh box` returns **viewport** coordinates. `cliclick` needs **macOS
screen** coordinates. The window is launched at a known origin (`WIN_X,WIN_Y`)
and size, so the mapping is a fixed offset:

```
screen_x = viewport_x + OFF_X      OFF_X = WIN_X + left_border (usually 0)
screen_y = viewport_y + OFF_Y      OFF_Y = WIN_Y + top_chrome  (toolbar + tab strip)
```

Calibrate once:

1. `./browser.sh start "https://claude.ai"` and let the window settle.
2. `./browser.sh box "<a clearly visible element>"` → note `CX CY`.
3. `./hands.sh move CX CY` and screenshot (Cmd-Shift-4) or eyeball where the
   cursor lands versus the element.
4. The gap is your offset. `export TUT_OFF_X=<dx> TUT_OFF_Y=<dy>` (top chrome is
   typically ~70–90px at `--force-device-scale-factor=1`; left border ~0).
5. Re-check one click; the offset is stable as long as the window position and
   size do not change.

Keep `--force-device-scale-factor=1` (set in `browser.mjs`) so viewport pixels
equal screen pixels apart from the fixed offset. On a Retina display, verify
whether avfoundation captures in points or pixels and set `WIN_W/WIN_H` and the
crop accordingly (see `capture-macos.md`).

## Locators

`browser.sh box`/`wait`/`fill` take a Playwright locator string, e.g.
`"text=New chat"`, `"#prompt"`, `"role=button[name='Send']"`. Prefer visible
text or roles over brittle CSS. `browser.sh snapshot` dumps the accessibility
tree to find names.

## Gotchas

- **Clear a field before typing.** Fields that keep their value append. Use
  `hands.sh key cmd+a` then type, or `browser.sh fill` (which clears).
- **Focus.** If typing lands nowhere, click the field first with `hands.sh`.
- **Logins / secrets.** Log in before recording (the profile persists in
  `chrome-profile/`), or record a scene that does not require real credentials.
  Never type a real password on camera.

# Storyboard schema

The `storyboard.md` this skill writes is the contract `screencast-tutorial-video`
consumes. Write it as readable Markdown with one section per scene, in order.

## File header

```markdown
# Storyboard: <human title>

- Slug: <kebab-slug>
- Target resolution: 1920x1080
- Voice: <to be chosen at production, or a note>
- Goal: <one sentence>
```

## One section per scene

Number scenes from 01. Use a heading and a labeled list so both a human and the
production skill can read it:

```markdown
## Scene 01, <short title>

- type: intro | terminal | desktop-still | browser-action | command-card | outro
- actions: <what happens on screen, concrete and ordered>
- narration: <the spoken voice-over, following narration-style.md>
- caption: <one short line, or empty for no caption bar>
- pacing: <approx seconds, and any timing notes>
```

### Field notes

- **type**, picks the recording engine downstream:
  - `intro` / `outro`, usually a still or a short browser/terminal shot.
  - `terminal`, a CLI command. Put the **exact command** in `actions` (it
    becomes a VHS `.tape`). Real commands only.
  - `desktop-still`, a native-app screen (e.g. Claude Desktop → Settings →
    MCP). Name the screen and what to zoom/highlight; production animates a PNG.
  - `browser-action`, a real step in a web UI. Name the URL, the element to
    click, and any text to type. Production locates the element and moves a
    visible cursor to it.
  - `command-card`, a single command shown as a still card. Put the exact
    command in `actions`.
- **actions**, concrete and ordered. For `terminal`/`command-card` include the
  literal command. For `browser-action` include the URL and a selector or
  visible label for each target. For `desktop-still` name the exact screen.
- **narration**, the spoken line(s). Follow `references/narration-style.md`.
- **caption**, one short line for the bottom bar, or empty.
- **pacing**, rough seconds; note if a step needs to linger.

## Accuracy markers

If a real value is not yet known, write `[NEEDS: <what, from where>]` in place of
the invented value rather than guessing. Example:

```markdown
- actions: paste the MCP config into claude_desktop_config.json:
  [NEEDS: real mcpServers block from the server's README]
```

The production skill treats a `[NEEDS: ...]` marker as a blocker and will ask
for the real value before recording that scene.

## Example scene

```markdown
## Scene 02, Add the MCP server

- type: terminal
- actions: run `claude mcp add github -- npx -y @modelcontextprotocol/server-github`
- narration: Add the server with claude m c p add. Give it a name and the command that starts it.
- caption: Add the MCP server
- pacing: ~7s; let the success line show for a beat
```

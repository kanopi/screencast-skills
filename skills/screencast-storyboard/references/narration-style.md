# Narration and caption style

The shared voice for both `screencast-storyboard` (writing the narration) and
`screencast-tutorial-video` (speaking it). Keep the two in sync.

## Voice

- **Plain, direct, terse, active voice.** "Open Settings, then click MCP." Not
  "Now, what we're going to want to do here is head on over to the settings."
- **Second person, imperative for steps.** "Paste the config." "Run the
  command." The viewer is doing it alongside you.
- **State what is true and verifiable.** No marketing hype, no subjective
  qualifiers ("amazing", "super easy", "powerful") in the step narration. The
  opt-in intro may say why the tool matters, but still in verifiable terms.

## Formatting rules

- **No em dashes or en dashes.** Use a period or a comma. (Dashes read poorly in
  TTS and captions.)
- **No emojis.**
- **Spell out what TTS would mispronounce.** Write "MCP" as "M C P" only if the
  voice mangles it; test on the chosen voice. Write "claude dot A I" if
  "claude.ai" is read as a filename. Numbers and versions: "version one point
  two" if needed.
- **One idea per sentence.** Short sentences narrate cleanly and pad/sync
  predictably against the video.

## Length and pacing

- **Match narration to the action.** A `terminal` scene's narration should last
  about as long as the command takes to type and run. `finish-scene.sh` pads the
  video to the narration, so over-long narration stretches a frozen frame —
  keep it tight.
- **Captions are one short line.** The caption bar is a label for the scene
  ("Add the MCP server"), not a transcript. An empty caption means no bar for
  that scene.
- **Lead and tail.** Production adds ~1s of silence before and after each
  scene's narration, so do not write "pause" into the narration.

## Example (terminal scene)

- Narration: "Add the server with claude m c p add. Give it a name and the
  command that starts it."
- Caption: "Add the MCP server"
- On-screen: types `claude mcp add github -- npx -y @modelcontextprotocol/server-github`

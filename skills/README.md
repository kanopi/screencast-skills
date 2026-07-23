# Skills

Overview of the Agent Skills in this plugin. Keep this list in parity with
the `skills/` directory — `tests/test-plugin.bats` asserts that the number
of `### N.` entries below equals the number of skill directories. Append
the next number rather than inserting mid-list.

### 1. screencast-storyboard

Author a tutorial script from a goal. Reads the tool's real docs, install
command, and config JSON, then drafts an approved `storyboard.md` (scenes with
type, on-screen actions, narration/transcript, one-line caption, and pacing).
Presents `STORYBOARD READY FOR APPROVAL` and stops. Never fabricates config or
commands. Dependency-free; the output can also feed a human presenter or another
tool. Triggers: "script a tutorial", "draft the transcript and timeline",
"outline a screencast walkthrough".

### 2. screencast-tutorial-video

Produce a narrated, captioned 1920x1080 MP4 from an approved storyboard on the
macOS host. Records each scene with the right engine — VHS for terminals,
ffmpeg still-motion for native apps, Playwright + cliclick + avfoundation for
the browser, command cards for abstract commands — adds ElevenLabs voice-over
and a caption bar, and concatenates the scenes. Triggers: "record the
screencast from my storyboard", "produce the narrated MP4", "render the tutorial
video with voice-over and captions".

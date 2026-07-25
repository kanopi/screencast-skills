# VHS starter tape for a terminal scene. Copy this per scene, edit the body, then:
#   ./render-tape.sh <NN> path/to/this.tape
# render-tape.sh forces Width/Height to 1920x1080 and sets Output to
# scenes/NN.mp4, you do not need Output/Width/Height lines here, but the other
# Set directives below are yours to tune. See references/terminal-vhs.md.

Set FontSize 26
Set Padding 40
Set Theme "Catppuccin Mocha"
Set TypingSpeed 90ms
Set PlaybackSpeed 1.0

# --- scene body: type real commands, wait for output, pause on the result ---
Type "claude mcp add github -- npx -y @modelcontextprotocol/server-github"
Sleep 400ms
Enter
Sleep 3s

Type "claude mcp list"
Sleep 300ms
Enter
Sleep 2500ms

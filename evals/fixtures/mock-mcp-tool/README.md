# mock-weather MCP server

A tiny example MCP server used as a screencast-storyboard fixture. It exposes a
single `get_forecast` tool over stdio. This README and `config.example.json`
give the storyboard skill a real source to read, so its transcript's install
command and config block are accurate rather than invented.

## Install

```
npm install -g @example/mock-weather-mcp
```

## Add to Claude Code

```
claude mcp add mock-weather -- npx -y @example/mock-weather-mcp
```

## Add to Claude Desktop

Add this to `claude_desktop_config.json` (see `config.example.json`):

```json
{
  "mcpServers": {
    "mock-weather": {
      "command": "npx",
      "args": ["-y", "@example/mock-weather-mcp"]
    }
  }
}
```

## Tools

- `get_forecast(city: string)`, returns a canned forecast for the named city.

#!/usr/bin/env bash
# Package the entire plugin as dist/<plugin-name>.zip, ready to upload
# to Claude Desktop's "Add plugin" UI (covers the Claude Code surface
# inside Desktop). The zip contains a top-level <plugin-name>/ directory
# with the plugin manifest, agents, skills, Codex artifacts, and
# supporting docs needed at runtime.
#
# The plugin name is read from .claude-plugin/plugin.json — no per-repo
# edits needed.
#
# Uses `git archive` so only tracked files are included — no build
# artifacts, no .git/, no node_modules, no dist/, no site/.
#
# Usage:
#   ./scripts/package-plugin.sh             # archive HEAD
#   ./scripts/package-plugin.sh <ref>       # archive a specific ref/tag/SHA

set -euo pipefail

cd "$(dirname "$0")/.."

REF="${1:-HEAD}"

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required (to read the plugin name from the manifest)." >&2
  exit 1
fi

PLUGIN_NAME=$(jq -r '.name' .claude-plugin/plugin.json)
OUTPUT="dist/${PLUGIN_NAME}.zip"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository." >&2
  exit 1
fi

if ! git rev-parse --verify "$REF" >/dev/null 2>&1; then
  echo "Error: '$REF' is not a valid git ref." >&2
  exit 1
fi

mkdir -p dist
rm -f "$OUTPUT"

# Include only the paths the plugin needs at runtime. Excludes internal
# tooling (scripts, tests, evals), CI config (.github), docs site source,
# and local state (.claude). Paths that don't exist in a given repo (e.g.
# agents/ in an agent-less plugin) are filtered out first — git archive
# errors on unmatched pathspecs.
candidates=(
  .claude-plugin
  .codex-plugin
  .codex
  agents
  skills
  AGENTS.md
  CHANGELOG.md
  CLAUDE.md
  LICENSE
  LICENSE.md
  MIGRATION.md
  README.md
)
paths=()
for p in "${candidates[@]}"; do
  if git rev-parse --verify --quiet "$REF:$p" >/dev/null 2>&1; then
    paths+=("$p")
  fi
done

git archive \
  --format=zip \
  --prefix="${PLUGIN_NAME}/" \
  -o "$OUTPUT" \
  "$REF" \
  -- \
  "${paths[@]}"

size=$(ls -l "$OUTPUT" | awk '{print $5}')
files=$(unzip -l "$OUTPUT" | tail -1 | awk '{print $2}')

echo "✓ $OUTPUT"
echo "  ref:   $REF ($(git rev-parse --short "$REF"))"
echo "  size:  $size bytes"
echo "  files: $files"
echo ""
echo "Upload via Claude Desktop's plugin UI to enable the plugin in the"
echo "Claude Code surface inside Desktop."

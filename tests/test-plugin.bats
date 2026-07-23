#!/usr/bin/env bats

# Generic test scaffold for Kanopi skills plugins.
# Run with: bats tests/test-plugin.bats
#
# Rules baked into this scaffold:
#   - Never hardcode counts of things that grow (skills, agents). Every
#     count assertion is a dynamic parity check between two sources of
#     truth (directories vs README entries, agent dirs vs TOML files).
#   - Repos without an agents/ directory skip the agent suites.
#   - Add repo-specific tests (skill X exists, agent Y references skill Z)
#     below the generic suites — do not weaken the generic ones.

setup() {
  # Set project root for all tests
  export PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  cd "$PROJECT_ROOT"
}

skip_without_agents() {
  [ -d "agents" ] || skip "repo has no agents/ directory"
}

# ==============================================================================
# PLUGIN MANIFEST TESTS
# ==============================================================================

@test "plugin manifest exists" {
  [ -f ".claude-plugin/plugin.json" ]
}

@test "plugin manifest is valid JSON" {
  run jq empty .claude-plugin/plugin.json
  [ "$status" -eq 0 ]
}

@test "plugin manifest has required fields" {
  run jq -e '.name' .claude-plugin/plugin.json
  [ "$status" -eq 0 ]

  run jq -e '.version' .claude-plugin/plugin.json
  [ "$status" -eq 0 ]

  run jq -e '.description' .claude-plugin/plugin.json
  [ "$status" -eq 0 ]
}

@test "plugin version follows semver" {
  version=$(jq -r '.version' .claude-plugin/plugin.json)
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "plugin has repository URL" {
  run jq -e '.repository' .claude-plugin/plugin.json
  [ "$status" -eq 0 ]

  run jq -r '.repository | type' .claude-plugin/plugin.json
  [ "$output" = "string" ]
}

# ==============================================================================
# CODEX MANIFEST TESTS
# ==============================================================================

@test "codex plugin manifest exists" {
  [ -f ".codex-plugin/plugin.json" ]
}

@test "codex manifest is valid JSON" {
  run jq empty .codex-plugin/plugin.json
  [ "$status" -eq 0 ]
}

@test "codex manifest has required fields" {
  run jq -e '.name' .codex-plugin/plugin.json
  [ "$status" -eq 0 ]

  run jq -e '.version' .codex-plugin/plugin.json
  [ "$status" -eq 0 ]

  run jq -e '.skills' .codex-plugin/plugin.json
  [ "$status" -eq 0 ]
}

@test "codex manifest name matches plugin manifest" {
  codex_name=$(jq -r '.name' .codex-plugin/plugin.json)
  plugin_name=$(jq -r '.name' .claude-plugin/plugin.json)
  [ "$codex_name" = "$plugin_name" ]
}

@test "codex manifest version matches plugin manifest" {
  codex_version=$(jq -r '.version' .codex-plugin/plugin.json)
  plugin_version=$(jq -r '.version' .claude-plugin/plugin.json)
  [ "$codex_version" = "$plugin_version" ]
}

# ==============================================================================
# SKILL STRUCTURE TESTS
# ==============================================================================

@test "skills directory exists" {
  [ -d "skills" ]
}

@test "skill directory count matches documented skills in skills/README.md" {
  dir_count=$(find skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  readme_count=$(grep -cE '^### [0-9]+\. ' skills/README.md)
  [ "$dir_count" -eq "$readme_count" ]
}

@test "all skill directories have SKILL.md file" {
  for skill_dir in skills/*/; do
    if [ ! -f "${skill_dir}SKILL.md" ]; then
      echo "Missing SKILL.md in $skill_dir"
      return 1
    fi
  done
}

# ==============================================================================
# SKILL FRONTMATTER TESTS
# ==============================================================================

@test "all skill files have YAML frontmatter" {
  for skill in skills/*/SKILL.md; do
    if ! grep -q "^---$" "$skill"; then
      echo "Missing frontmatter in $skill"
      return 1
    fi
  done
}

@test "all skills have name in frontmatter" {
  for skill in skills/*/SKILL.md; do
    if ! grep -q "^name:" "$skill"; then
      echo "Missing name in $skill"
      return 1
    fi
  done
}

@test "all skills have description in frontmatter" {
  for skill in skills/*/SKILL.md; do
    if ! grep -q "^description:" "$skill"; then
      echo "Missing description in $skill"
      return 1
    fi
  done
}

@test "skill names match directory names" {
  for skill_dir in skills/*/; do
    dir_name=$(basename "$skill_dir")
    skill_file="${skill_dir}SKILL.md"

    if [ -f "$skill_file" ]; then
      skill_name=$(sed -n 's/^name: *//p' "$skill_file" | head -n 1)
      if [ "$skill_name" != "$dir_name" ]; then
        echo "Name mismatch in $skill_file: name=$skill_name, dir=$dir_name"
        return 1
      fi
    fi
  done
}

# ==============================================================================
# OPENAI INVOCATION POLICY TESTS
# ==============================================================================

@test "skills with openai.yaml have valid YAML" {
  for yaml_file in skills/*/agents/openai.yaml; do
    if [ -f "$yaml_file" ]; then
      if command -v python3 &> /dev/null; then
        python3 -c "import yaml; yaml.safe_load(open('$yaml_file'))" 2>/dev/null || {
          echo "Invalid YAML in $yaml_file"
          return 1
        }
      else
        skip "No YAML validator available"
      fi
    fi
  done
}

@test "openai.yaml files have policy.allow_implicit_invocation field" {
  for yaml_file in skills/*/agents/openai.yaml; do
    if [ -f "$yaml_file" ]; then
      if ! grep -q "allow_implicit_invocation:" "$yaml_file"; then
        echo "Missing allow_implicit_invocation in $yaml_file"
        return 1
      fi
    fi
  done
}

# ==============================================================================
# AGENT STRUCTURE + FRONTMATTER TESTS (skipped when repo has no agents/)
# ==============================================================================

@test "all agent directories have AGENT.md file" {
  skip_without_agents
  for agent_dir in agents/*/; do
    if [ ! -f "${agent_dir}AGENT.md" ]; then
      echo "Missing AGENT.md in $agent_dir"
      return 1
    fi
  done
}

@test "all agent files have YAML frontmatter" {
  skip_without_agents
  for agent in agents/*/AGENT.md; do
    if ! grep -q "^---$" "$agent"; then
      echo "Missing frontmatter in $agent"
      return 1
    fi
  done
}

@test "all agents have required frontmatter fields" {
  skip_without_agents
  for agent in agents/*/AGENT.md; do
    for field in name description tools skills model; do
      if ! grep -q "^${field}:" "$agent"; then
        echo "Missing $field in $agent"
        return 1
      fi
    done
  done
}

@test "agent frontmatter has valid YAML syntax" {
  skip_without_agents
  for agent in agents/*/AGENT.md; do
    frontmatter=$(awk 'BEGIN {state=0} /^---$/ {state++; next} state==1 {print} state==2 {exit}' "$agent")

    if command -v python3 &> /dev/null; then
      echo "$frontmatter" | python3 -c "import sys, yaml; yaml.safe_load(sys.stdin)" &> /dev/null || {
        echo "Invalid YAML in $agent"
        return 1
      }
    else
      skip "No YAML validator available"
    fi
  done
}

@test "agent names match directory names" {
  skip_without_agents
  for agent_dir in agents/*/; do
    dir_name=$(basename "$agent_dir")
    agent_file="${agent_dir}AGENT.md"

    if [ -f "$agent_file" ]; then
      agent_name=$(sed -n 's/^name: *//p' "$agent_file" | head -n 1)
      if [ "$agent_name" != "$dir_name" ]; then
        echo "Name mismatch in $agent_file: name=$agent_name, dir=$dir_name"
        return 1
      fi
    fi
  done
}

@test "no agent file exceeds reasonable size (200KB)" {
  skip_without_agents
  for agent in agents/*/AGENT.md; do
    size=$(wc -c < "$agent")
    if [ "$size" -gt 204800 ]; then
      echo "Agent file $agent is too large: ${size} bytes"
      return 1
    fi
  done
}

@test "no agent references another plugin's namespace in Task() calls" {
  skip_without_agents
  plugin_name=$(jq -r '.name' .claude-plugin/plugin.json)
  # Any fully-qualified Task(<plugin>:...) reference must use this plugin's
  # own name — a foreign prefix is a leftover from a repo migration.
  if grep -rEn 'Task\([a-z0-9-]+:' agents/ skills/ 2>/dev/null | grep -v "Task(${plugin_name}:"; then
    echo "Found Task() references to a foreign plugin namespace (see above)"
    return 1
  fi
}

# ==============================================================================
# CODEX TOML AGENT TESTS (dynamic parity — skipped when repo has no agents/)
# ==============================================================================

@test "codex agent TOML count matches agent directory count" {
  skip_without_agents
  toml_count=$(find .codex/agents -name "*.toml" 2>/dev/null | wc -l | tr -d ' ')
  dir_count=$(find agents -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  [ "$toml_count" -eq "$dir_count" ]
}

@test "every AGENT.md directory has a corresponding TOML agent" {
  skip_without_agents
  for agent_dir in agents/*/; do
    agent_name=$(basename "$agent_dir")
    if [ ! -f ".codex/agents/${agent_name}.toml" ]; then
      echo "Missing TOML for agent: $agent_name"
      return 1
    fi
  done
}

@test "every TOML agent has a corresponding AGENT.md directory" {
  skip_without_agents
  for toml_file in .codex/agents/*.toml; do
    agent_name=$(basename "$toml_file" .toml)
    if [ ! -d "agents/$agent_name" ]; then
      echo "TOML $toml_file has no matching agents/$agent_name/ directory"
      return 1
    fi
  done
}

@test "all TOML agents have required fields" {
  skip_without_agents
  for toml_file in .codex/agents/*.toml; do
    for field in "name = " "description = " "model = " "developer_instructions"; do
      if ! grep -q "^${field}" "$toml_file"; then
        echo "Missing ${field% =*} field in $toml_file"
        return 1
      fi
    done
  done
}

@test "TOML agent names match their filenames" {
  skip_without_agents
  for toml_file in .codex/agents/*.toml; do
    file_name=$(basename "$toml_file" .toml)
    toml_name=$(grep "^name = " "$toml_file" | head -1 | sed 's/^name = "\(.*\)"/\1/')
    if [ "$file_name" != "$toml_name" ]; then
      echo "Name mismatch in $toml_file: file=$file_name, toml=$toml_name"
      return 1
    fi
  done
}

# ==============================================================================
# ROUTING EVAL CONFIG TESTS
# ==============================================================================

@test "evals/routing-prompts.json exists and is valid JSON" {
  [ -f "evals/routing-prompts.json" ]
  run jq empty evals/routing-prompts.json
  [ "$status" -eq 0 ]
}

@test "routing eval has at least one prompt" {
  count=$(jq '.prompts | length' evals/routing-prompts.json)
  [ "$count" -ge 1 ]
}

@test "every routing prompt expects an existing skill" {
  while IFS= read -r expected; do
    if [ ! -d "skills/$expected" ]; then
      echo "routing-prompts.json expects non-existent skill: $expected"
      return 1
    fi
  done < <(jq -r '.prompts[].expect' evals/routing-prompts.json | sort -u)
}

# ==============================================================================
# BEHAVIORAL EVAL CONFIG TESTS
# ==============================================================================
# Cheap static checks only — the harness's API-calling runs are a separate,
# manually/weekly triggered concern (see .github/workflows/behavioral-evals.yml).

@test "scripts/run-behavioral-evals.sh exists and is executable" {
  [ -x "scripts/run-behavioral-evals.sh" ]
}

@test "behavioral eval cases pass static validation (--check, no API calls)" {
  run bash scripts/run-behavioral-evals.sh --check
  [ "$status" -eq 0 ]
}

@test "behavioral eval fixtures with setup.sh delete themselves before committing" {
  for setup in evals/fixtures/*/setup.sh; do
    if [ -f "$setup" ]; then
      if ! grep -q "rm -f setup.sh" "$setup"; then
        echo "$setup does not remove itself before seeding the fixture commit"
        return 1
      fi
    fi
  done
}

# ==============================================================================
# PACKAGING SCRIPTS
# ==============================================================================

@test "scripts/package-skills.sh exists and is executable" {
  [ -x "scripts/package-skills.sh" ]
}

@test "scripts/package-plugin.sh exists and is executable" {
  [ -x "scripts/package-plugin.sh" ]
}

@test "scripts/validate-frontmatter.sh exists and is executable" {
  [ -x "scripts/validate-frontmatter.sh" ]
}

@test "scripts/check-codex-parity.sh exists and is executable" {
  [ -x "scripts/check-codex-parity.sh" ]
}

@test "scripts/package-skills.sh --list outputs every skill directory" {
  expected=$(find skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  actual=$(bash scripts/package-skills.sh --list | wc -l | tr -d ' ')
  if [ "$actual" != "$expected" ]; then
    echo "Expected $expected skills, --list returned $actual"
    return 1
  fi
}

@test "release-artifacts workflow exists" {
  [ -f ".github/workflows/release-artifacts.yml" ]
}

@test "behavioral-evals workflow exists" {
  [ -f ".github/workflows/behavioral-evals.yml" ]
}

# ==============================================================================
# LICENSE AND METADATA TESTS
# ==============================================================================

@test "LICENSE file exists" {
  [ -f "LICENSE" ] || [ -f "LICENSE.md" ] || [ -f "LICENSE.txt" ]
}

@test "CHANGELOG.md exists" {
  [ -f "CHANGELOG.md" ]
}

@test "README.md exists" {
  [ -f "README.md" ]
}

@test "CLAUDE.md exists for AI context" {
  [ -f "CLAUDE.md" ]
}

# ==============================================================================
# FILE HYGIENE TESTS
# ==============================================================================

@test "no uncommitted merge conflict markers" {
  dirs="skills"
  [ -d "agents" ] && dirs="$dirs agents"
  [ -d "docs" ] && dirs="$dirs docs"
  if grep -r "^<<<<<<< \|^=======$\|^>>>>>>> " $dirs 2>/dev/null; then
    echo "Found merge conflict markers"
    return 1
  fi
}

# ==============================================================================
# REPO-SPECIFIC TESTS
# ==============================================================================
# Add tests for this plugin's own invariants below (specific skills exist,
# agent X references skill Y, orchestrators have Task, leaf specialists
# don't, etc.). Keep counts dynamic.

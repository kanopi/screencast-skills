#!/bin/bash

# Validate frontmatter in all SKILL.md / AGENT.md files, plus openai.yaml
# Codex policy files. Generic across Kanopi skills plugins — repos with no
# agents/ directory skip the agent section.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

errors=0
warnings=0

plugin_name=$(command -v jq >/dev/null 2>&1 && jq -r '.name' .claude-plugin/plugin.json 2>/dev/null || echo "plugin")
echo "🔍 Validating frontmatter in $plugin_name..."
echo ""

# Function to validate YAML syntax using Python
validate_yaml_syntax() {
    local file="$1"
    python3 -c "
import yaml
import sys

try:
    with open('$file', 'r') as f:
        content = f.read()

    # Extract frontmatter
    lines = content.split('\n')
    if lines[0] == '---':
        fm_lines = []
        for i, line in enumerate(lines[1:], 1):
            if line == '---':
                break
            fm_lines.append(line)

        fm_text = '\n'.join(fm_lines)
        yaml.safe_load(fm_text)
        sys.exit(0)
    else:
        sys.exit(1)
except yaml.YAMLError as e:
    print(f'YAML error: {e}', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>&1
    return $?
}

# Function to extract frontmatter from a file
extract_frontmatter() {
    local file="$1"
    awk '/^---$/{flag=!flag; if(flag) next} flag' "$file"
}

# Function to check if a field exists in frontmatter
has_field() {
    local frontmatter="$1"
    local field="$2"
    echo "$frontmatter" | grep -q "^${field}:"
}

# Function to get field value
get_field_value() {
    local frontmatter="$1"
    local field="$2"
    echo "$frontmatter" | grep "^${field}:" | sed "s/^${field}:[[:space:]]*//"
}

# Function to check if frontmatter exists
has_frontmatter() {
    local file="$1"
    head -n 1 "$file" | grep -q "^---$"
}

if compgen -G "agents/*/AGENT.md" > /dev/null; then
    echo "🤖 Validating Agents (agents/*/AGENT.md)"
    echo "=========================================="

    for file in agents/*/AGENT.md; do
        agent_dir=$(basename $(dirname "$file"))
        echo -n "  Checking $agent_dir... "

        if ! has_frontmatter "$file"; then
            echo -e "${RED}✗${NC} Missing frontmatter"
            ((errors++))
            continue
        fi

        # Validate YAML syntax
        if ! yaml_error=$(validate_yaml_syntax "$file"); then
            echo -e "${RED}✗${NC} Invalid YAML syntax: $yaml_error"
            ((errors++))
            continue
        fi

        fm=$(extract_frontmatter "$file")

        # Check required fields
        for field in name description tools; do
            if ! has_field "$fm" "$field"; then
                echo -e "${RED}✗${NC} Missing required field: $field"
                ((errors++))
                continue 2
            fi
            if [ -z "$(get_field_value "$fm" "$field")" ]; then
                echo -e "${RED}✗${NC} Empty $field"
                ((errors++))
                continue 2
            fi
        done

        # Verify name matches directory
        name=$(get_field_value "$fm" "name")
        if [ "$name" != "$agent_dir" ]; then
            echo -e "${YELLOW}⚠${NC}  Name '$name' doesn't match directory '$agent_dir'"
            ((warnings++))
            continue
        fi

        echo -e "${GREEN}✓${NC}"
    done
    echo ""
else
    echo "🤖 No agents/ directory — skipping agent validation"
    echo ""
fi

echo "🎯 Validating Skills (skills/*/SKILL.md)"
echo "=========================================="

for file in skills/*/SKILL.md; do
    skill_dir=$(basename $(dirname "$file"))
    echo -n "  Checking $skill_dir... "

    if ! has_frontmatter "$file"; then
        echo -e "${RED}✗${NC} Missing frontmatter"
        ((errors++))
        continue
    fi

    # Validate YAML syntax
    if ! yaml_error=$(validate_yaml_syntax "$file"); then
        echo -e "${RED}✗${NC} Invalid YAML syntax: $yaml_error"
        ((errors++))
        continue
    fi

    fm=$(extract_frontmatter "$file")

    for field in name description; do
        if ! has_field "$fm" "$field"; then
            echo -e "${RED}✗${NC} Missing required field: $field"
            ((errors++))
            continue 2
        fi
        if [ -z "$(get_field_value "$fm" "$field")" ]; then
            echo -e "${RED}✗${NC} Empty $field"
            ((errors++))
            continue 2
        fi
    done

    # Verify name matches directory
    name=$(get_field_value "$fm" "name")
    if [ "$name" != "$skill_dir" ]; then
        echo -e "${YELLOW}⚠${NC}  Name '$name' doesn't match directory '$skill_dir'"
        ((warnings++))
        continue
    fi

    echo -e "${GREEN}✓${NC}"
done

echo ""
echo "⚙️  Validating Codex Invocation Policy (skills/*/agents/openai.yaml)"
echo "=========================================="

for file in skills/*/agents/openai.yaml; do
    if [ -f "$file" ]; then
        skill_dir=$(basename "$(dirname "$(dirname "$file")")")
        echo -n "  Checking $skill_dir/agents/openai.yaml... "

        # Validate YAML syntax
        if command -v python3 &> /dev/null; then
            if ! yaml_error=$(python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>&1); then
                echo -e "${RED}✗${NC} Invalid YAML: $yaml_error"
                ((errors++))
                continue
            fi
        fi

        # Check for required policy field
        if ! grep -q "allow_implicit_invocation:" "$file"; then
            echo -e "${RED}✗${NC} Missing policy.allow_implicit_invocation"
            ((errors++))
            continue
        fi

        echo -e "${GREEN}✓${NC}"
    fi
done

echo ""
echo "=========================================="
echo "📊 Summary"
echo "=========================================="
echo -e "Errors:   ${RED}$errors${NC}"
echo -e "Warnings: ${YELLOW}$warnings${NC}"
echo ""

if [ $errors -gt 0 ]; then
    echo -e "${RED}❌ Validation failed with $errors error(s)${NC}"
    exit 1
else
    echo -e "${GREEN}✅ All frontmatter is valid!${NC}"
    if [ $warnings -gt 0 ]; then
        echo -e "${YELLOW}⚠️  But there are $warnings warning(s) to review${NC}"
    fi
    exit 0
fi

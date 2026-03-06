#!/usr/bin/env bash
set -euo pipefail

# /devtest skill installer for Claude Code
# Downloads the SKILL.md and enables Agent Teams

REPO_RAW="https://raw.githubusercontent.com/Netropolitan/Claude-Build-Test-Loop/main"
SKILL_DIR="$HOME/.claude/skills/devtest"
SETTINGS_FILE="$HOME/.claude/settings.json"

echo "Installing /devtest skill for Claude Code..."

# Step 1: Download the skill
mkdir -p "$SKILL_DIR"
if command -v curl &>/dev/null; then
  curl -fsSL "$REPO_RAW/skill/SKILL.md" -o "$SKILL_DIR/SKILL.md"
elif command -v wget &>/dev/null; then
  wget -qO "$SKILL_DIR/SKILL.md" "$REPO_RAW/skill/SKILL.md"
else
  echo "Error: curl or wget is required." >&2
  exit 1
fi
echo "  Skill installed to $SKILL_DIR/SKILL.md"

# Step 2: Enable Agent Teams in settings.json
if [ ! -f "$SETTINGS_FILE" ]; then
  # No settings file — create one
  mkdir -p "$(dirname "$SETTINGS_FILE")"
  cat > "$SETTINGS_FILE" <<'JSON'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
JSON
  echo "  Created $SETTINGS_FILE with Agent Teams enabled"
elif grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "$SETTINGS_FILE"; then
  echo "  Agent Teams already configured in $SETTINGS_FILE"
else
  # Settings file exists but doesn't have the env var — try to add it
  if command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
with open('$SETTINGS_FILE', 'r') as f:
    data = json.load(f)
data.setdefault('env', {})['CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS'] = '1'
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
"
    echo "  Added Agent Teams to existing $SETTINGS_FILE"
  elif command -v node &>/dev/null; then
    node -e "
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('$SETTINGS_FILE', 'utf8'));
data.env = data.env || {};
data.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = '1';
fs.writeFileSync('$SETTINGS_FILE', JSON.stringify(data, null, 2));
"
    echo "  Added Agent Teams to existing $SETTINGS_FILE"
  else
    echo "  Warning: Could not auto-add Agent Teams to $SETTINGS_FILE"
    echo "  Please manually add to your settings.json:"
    echo '    "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" }'
  fi
fi

echo ""
echo "Done! Restart Claude Code, then type /devtest to start."

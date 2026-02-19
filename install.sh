#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$HOME/.claude/skills/devtest"
SETTINGS_FILE="$HOME/.claude/settings.json"
SKILL_URL="https://raw.githubusercontent.com/OWNER/claude-build-test-loop/main/skill/SKILL.md"

echo "Installing /devtest skill for Claude Code..."

# 1. Create skill directory and download SKILL.md
mkdir -p "$SKILL_DIR"

if command -v curl &>/dev/null; then
  curl -fsSL "$SKILL_URL" -o "$SKILL_DIR/SKILL.md"
elif command -v wget &>/dev/null; then
  wget -qO "$SKILL_DIR/SKILL.md" "$SKILL_URL"
else
  echo "Error: curl or wget is required to install."
  exit 1
fi

echo "  Skill installed to $SKILL_DIR/SKILL.md"

# 2. Enable Agent Teams if not already set
if [ ! -f "$SETTINGS_FILE" ]; then
  mkdir -p "$(dirname "$SETTINGS_FILE")"
  cat > "$SETTINGS_FILE" <<'EOF'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
EOF
  echo "  Created $SETTINGS_FILE with Agent Teams enabled"
elif ! grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "$SETTINGS_FILE" 2>/dev/null; then
  # Settings file exists but doesn't have Agent Teams — try to add it
  if command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
with open('$SETTINGS_FILE', 'r') as f:
    settings = json.load(f)
settings.setdefault('env', {})['CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS'] = '1'
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(settings, f, indent=2)
"
    echo "  Agent Teams enabled in $SETTINGS_FILE"
  elif command -v node &>/dev/null; then
    node -e "
const fs = require('fs');
const settings = JSON.parse(fs.readFileSync('$SETTINGS_FILE', 'utf8'));
settings.env = settings.env || {};
settings.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = '1';
fs.writeFileSync('$SETTINGS_FILE', JSON.stringify(settings, null, 2));
"
    echo "  Agent Teams enabled in $SETTINGS_FILE"
  else
    echo "  Warning: Could not auto-enable Agent Teams."
    echo "  Please add this to $SETTINGS_FILE manually:"
    echo '  "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" }'
  fi
else
  echo "  Agent Teams already enabled"
fi

echo ""
echo "Done! Restart Claude Code, then use /devtest to get started."

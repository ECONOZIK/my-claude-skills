#!/bin/bash
set -euo pipefail

# Install the custom skills contained in this repo into the directory that
# Claude Code reads skills from (~/.claude/skills), so every session in this
# environment can use them.
#
# Runs synchronously on SessionStart so the skills are guaranteed to be in
# place before the agent loop starts.

REPO_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
SKILLS_SRC="$REPO_DIR/skills"
SKILLS_DEST="$HOME/.claude/skills"

if [ ! -d "$SKILLS_SRC" ]; then
  echo "No skills/ directory found in $REPO_DIR, nothing to install." >&2
  exit 0
fi

mkdir -p "$SKILLS_DEST"

# Copy each skill directory into the destination. Idempotent: re-copying just
# refreshes the contents.
installed=0
for skill in "$SKILLS_SRC"/*/; do
  [ -d "$skill" ] || continue
  name="$(basename "$skill")"
  rm -rf "${SKILLS_DEST:?}/$name"
  cp -r "$skill" "$SKILLS_DEST/$name"
  installed=$((installed + 1))
done

echo "Installed $installed skill(s) into $SKILLS_DEST" >&2

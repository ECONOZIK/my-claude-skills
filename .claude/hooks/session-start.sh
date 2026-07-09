#!/bin/bash
set -euo pipefail

# Install skills into the directory Claude Code reads from (~/.claude/skills),
# so every session in this environment can use them. Two sources:
#   1. Skills committed in this repo, under skills/
#   2. Skills from external git repos listed in EXTERNAL_SKILL_REPOS
#
# Runs synchronously on SessionStart so the skills are in place before the
# agent loop starts. Idempotent: safe to re-run.

REPO_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
SKILLS_DEST="$HOME/.claude/skills"
CACHE_DIR="$HOME/.claude/skills-repos"

# External skill repositories to pull skills from. Each entry: "<git-url> <subdir>"
# where <subdir> is the path inside the repo that holds the skill directories.
EXTERNAL_SKILL_REPOS=(
  "https://github.com/juliusbrussee/caveman.git skills"
  "https://github.com/nextlevelbuilder/ui-ux-pro-max-skill.git .claude/skills"
)

mkdir -p "$SKILLS_DEST"

# copy_skills_from <dir>: copy each immediate subdirectory of <dir> that looks
# like a skill (contains SKILL.md) into SKILLS_DEST.
copy_skills_from() {
  local src="$1"
  local count=0
  [ -d "$src" ] || return 0
  for skill in "$src"/*/; do
    [ -d "$skill" ] || continue
    [ -f "$skill/SKILL.md" ] || continue
    local name
    name="$(basename "$skill")"
    rm -rf "${SKILLS_DEST:?}/$name"
    cp -r "$skill" "$SKILLS_DEST/$name"
    count=$((count + 1))
  done
  echo "$count"
}

# 1. Local skills from this repo.
local_count="$(copy_skills_from "$REPO_DIR/skills")"
echo "Installed $local_count local skill(s) from $REPO_DIR/skills" >&2

# 2. External skill repos.
mkdir -p "$CACHE_DIR"
for entry in "${EXTERNAL_SKILL_REPOS[@]}"; do
  url="${entry%% *}"
  subdir="${entry#* }"
  [ "$subdir" = "$url" ] && subdir="skills"
  name="$(basename "$url" .git)"
  dest="$CACHE_DIR/$name"

  if [ -d "$dest/.git" ]; then
    git -C "$dest" pull --ff-only --quiet || echo "Warning: could not update $name" >&2
  else
    if ! git clone --depth 1 --quiet "$url" "$dest"; then
      echo "Warning: could not clone $url, skipping." >&2
      continue
    fi
  fi

  ext_count="$(copy_skills_from "$dest/$subdir")"
  echo "Installed $ext_count skill(s) from $name ($url)" >&2
done

echo "Skills ready in $SKILLS_DEST" >&2

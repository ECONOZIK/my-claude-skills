#!/bin/bash
set -euo pipefail

# Install skills and subagents into the directories Claude Code reads from
# (~/.claude/skills and ~/.claude/agents), so every session in this environment
# can use them. Sources:
#   1. Skills committed in this repo, under skills/
#   2. Skills from external git repos listed in EXTERNAL_SKILL_REPOS
#   3. Subagents (.md persona files) from repos listed in EXTERNAL_AGENT_REPOS
#
# Runs synchronously on SessionStart so everything is in place before the
# agent loop starts. Idempotent: safe to re-run.

REPO_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
SKILLS_DEST="$HOME/.claude/skills"
AGENTS_DEST="$HOME/.claude/agents"
CACHE_DIR="$HOME/.claude/skills-repos"

# External skill repositories to pull skills from. Each entry: "<git-url> <subdir>"
# where <subdir> is the path inside the repo that holds the skill directories.
EXTERNAL_SKILL_REPOS=(
  "https://github.com/juliusbrussee/caveman.git skills"
  "https://github.com/nextlevelbuilder/ui-ux-pro-max-skill.git .claude/skills"
  "https://github.com/obra/superpowers.git skills"
  "https://github.com/DietrichGebert/ponytail.git skills"
  "https://github.com/oso95/scroll-world.git plugins/scroll-world/skills"
)

# External subagent repositories. Each entry: "<git-url> <subdir>" where <subdir>
# is the path inside the repo under which agent .md files live (searched
# recursively). Use "." for the repo root.
EXTERNAL_AGENT_REPOS=(
  "https://github.com/ECONOZIK/agency-agents.git ."
)

mkdir -p "$SKILLS_DEST" "$AGENTS_DEST"

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

# copy_agents_from <dir>: copy every .md file under <dir> (recursively) into
# AGENTS_DEST, skipping repo docs. Files with a YAML frontmatter block are
# treated as subagents.
copy_agents_from() {
  local src="$1"
  local count=0
  [ -d "$src" ] || { echo 0; return 0; }
  while IFS= read -r -d '' file; do
    local base
    base="$(basename "$file")"
    case "$base" in
      README.md|CONTRIBUTING.md|SECURITY.md|LICENSE.md|CHANGELOG.md|CODE_OF_CONDUCT.md) continue ;;
    esac
    # Must start with a YAML frontmatter block to be a valid agent.
    head -n1 "$file" | grep -q '^---' || continue
    cp "$file" "$AGENTS_DEST/$base"
    count=$((count + 1))
  done < <(find "$src" -type f -name '*.md' \
             -not -path '*/.git/*' \
             -not -path '*/.github/*' \
             -not -path '*/examples/*' \
             -not -path '*/docs/*' -print0)
  echo "$count"
}

# 3. External subagent repos.
for entry in "${EXTERNAL_AGENT_REPOS[@]}"; do
  url="${entry%% *}"
  subdir="${entry#* }"
  [ "$subdir" = "$url" ] && subdir="."
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

  agent_count="$(copy_agents_from "$dest/$subdir")"
  echo "Installed $agent_count agent(s) from $name ($url)" >&2
done

echo "Skills ready in $SKILLS_DEST" >&2
echo "Agents ready in $AGENTS_DEST" >&2

# 4. Python tools (pip). Kept non-fatal: a failed install here must never break
#    the session — skills and agents are already in place above.
# Force a pip-managed cryptography first so packages that need a newer version
# don't try to uninstall the debian-managed one (which fails).
pip install --quiet --ignore-installed cryptography >/dev/null 2>&1 || true

# crawl4ai (web -> LLM-ready markdown), from the ECONOZIK fork.
if pip install --quiet "git+https://github.com/ECONOZIK/crawl4ai.git" >/dev/null 2>&1; then
  echo "Installed crawl4ai" >&2
else
  echo "Warning: crawl4ai install failed (non-fatal)" >&2
fi

# graphify (codebase -> knowledge graph). Installs the pip package, then
# registers its skill into ~/.claude/skills via the graphify CLI.
if pip install --quiet graphifyy >/dev/null 2>&1; then
  graphify install --platform claude >/dev/null 2>&1 \
    && echo "Installed graphify" >&2 \
    || echo "Warning: graphify skill registration failed (non-fatal)" >&2
else
  echo "Warning: graphifyy install failed (non-fatal)" >&2
fi

# 6. MCP servers (non-fatal). Registered at user scope so every session and
#    every repo in this environment gets them. Re-registering each session is
#    required because the container is ephemeral.
if command -v claude >/dev/null 2>&1; then
  # task-master-ai: AI task management. Uses claude-code/* models (no API key).
  claude mcp remove --scope user task-master-ai >/dev/null 2>&1 || true
  claude mcp add --scope user task-master-ai -- npx -y task-master-ai >/dev/null 2>&1 \
    && echo "Registered MCP: task-master-ai" >&2 \
    || echo "Warning: task-master-ai MCP registration failed (non-fatal)" >&2
fi

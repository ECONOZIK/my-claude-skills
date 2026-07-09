# my-claude-skills

A repository of custom [Claude Code](https://code.claude.com/docs) skills that
doubles as a ready-to-use **environment**. When a Claude Code (web) session
starts against this repo, a `SessionStart` hook installs every skill under
`skills/` into `~/.claude/skills/`, making them immediately available.

## Layout

```
.
├── .claude/
│   ├── hooks/
│   │   └── session-start.sh   # copies skills/* → ~/.claude/skills/
│   └── settings.json          # registers the SessionStart hook
└── skills/
    └── hello-skill/
        └── SKILL.md           # example skill (replace with your own)
```

## Adding a skill

1. Create `skills/<skill-name>/SKILL.md`.
2. Add YAML frontmatter with `name` and `description`.
3. Commit and push. The next session installs it automatically.

## External skill repos

The hook can also pull skills from other git repositories. Edit the
`EXTERNAL_SKILL_REPOS` array in `.claude/hooks/session-start.sh`. Each entry is
`"<git-url> <subdir>"`, where `<subdir>` is the folder inside that repo holding
the skill directories:

```bash
EXTERNAL_SKILL_REPOS=(
  "https://github.com/juliusbrussee/caveman.git skills"
  "https://github.com/nextlevelbuilder/ui-ux-pro-max-skill.git .claude/skills"
  "https://github.com/obra/superpowers.git skills"
  "https://github.com/DietrichGebert/ponytail.git skills"
  "https://github.com/oso95/scroll-world.git plugins/scroll-world/skills"
)
```

External repos are cached in `~/.claude/skills-repos/` and only skill
directories containing a `SKILL.md` are installed.

## Subagent repos

The hook can also install subagent persona files (`.md` with YAML frontmatter)
into `~/.claude/agents/`. Add entries to `EXTERNAL_AGENT_REPOS` in the hook,
each `"<git-url> <subdir>"` (use `.` for the repo root — `.md` files are found
recursively, skipping `docs/`, `examples/`, and repo docs like `README.md`):

```bash
EXTERNAL_AGENT_REPOS=(
  "https://github.com/ECONOZIK/agency-agents.git ."
)
```

## Python tools (pip)

The hook also installs a few pip-based tools (non-fatally — a failed install
never breaks the session), registering their skills where applicable:

- **crawl4ai** — web → LLM-ready markdown (from the ECONOZIK fork)
- **graphify** (`graphifyy`) — codebase → knowledge graph; registers a
  `graphify` skill via `graphify install --platform claude`

To add another pip tool, add a non-fatal install block in section 4 of the
hook. Because the environment Setup script just runs this hook, you never need
to touch it — commit and push.

## Using it as an environment

Point a Claude Code on the web environment at this repository (or its default
branch). On session start the hook runs and loads your skills. You can also run
the hook manually:

```bash
CLAUDE_CODE_REMOTE=true ./.claude/hooks/session-start.sh
```

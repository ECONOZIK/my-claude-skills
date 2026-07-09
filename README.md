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

## Using it as an environment

Point a Claude Code on the web environment at this repository (or its default
branch). On session start the hook runs and loads your skills. You can also run
the hook manually:

```bash
CLAUDE_CODE_REMOTE=true ./.claude/hooks/session-start.sh
```

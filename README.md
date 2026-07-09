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
)
```

External repos are cached in `~/.claude/skills-repos/` and only skill
directories containing a `SKILL.md` are installed.

## Using it as an environment

Point a Claude Code on the web environment at this repository (or its default
branch). On session start the hook runs and loads your skills. You can also run
the hook manually:

```bash
CLAUDE_CODE_REMOTE=true ./.claude/hooks/session-start.sh
```

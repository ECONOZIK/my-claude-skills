---
name: hello-skill
description: Example custom skill that greets the user. Replace this with your own skills. Use when the user asks for a demo of the custom skills environment.
---

# Hello Skill

This is an example skill that ships with the `my-claude-skills` environment.

When invoked, greet the user and confirm that custom skills from this
repository are loaded and available.

## Steps

1. Greet the user by name if known.
2. Confirm the custom-skills environment is active.
3. Point them at `skills/` in this repo to add their own skills.

## Adding your own skills

Create a new directory under `skills/<your-skill-name>/` with a `SKILL.md`
file that has YAML frontmatter (`name`, `description`). The SessionStart hook
copies it into `~/.claude/skills/` automatically on the next session.

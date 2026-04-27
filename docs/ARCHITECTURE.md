# Architecture

`unicore-skills` is a single-repository, multi-platform skills package.

## Core idea

- Canonical workflow content lives in `skills/`
- Tool-specific manifests and installation guides are thin shims
- Consumer repositories get repo-local adapters only when a tool expects local files

## Repository shape

- `skills/`: canonical skill library
- `.claude-plugin/`: Claude Code manifest and marketplace metadata
- `.codex-plugin/`: Codex manifest
- `.codex/`: Codex installation notes
- `.cursor-plugin/`: Cursor manifest and installation notes
- `.cursor/rules/`: Cursor repo-local instructions
- `.agents/skills/`: generic agent-skills view of the canonical library
- `.windsurf/skills/`: Windsurf workspace view of the canonical library
- `.github/`: GitHub Copilot instructions
- `scripts/`: adapter installation helpers

## Sync rules

1. Edit `skills/<topic>/SKILL.md` first.
2. Prefer symlinks over duplicated skill files where a platform can consume the same content.
3. Keep manifests pointing at shared directories such as `./skills/`.
4. Use repo-local adapter files only for tools that need them in consumer repositories.

# Repository purpose

This repository is a cross-IDE package of internal engineering playbooks for Universe Group Head Office (`unicore`).

# Source of truth

- Canonical workflow content lives in `skills/<topic>/SKILL.md`.
- Tool-specific files are adapters for Claude Code, Codex, Cursor, Windsurf, and GitHub Copilot.
- When updating guidance, change the canonical skill first and then sync the adapters.

# Editing guidance

- Preserve YAML frontmatter in every `SKILL.md`.
- Keep skill descriptions concrete so AI tools can match them reliably.
- Avoid embedding tool-specific instructions into canonical skills unless they are portable.
- Treat `bootstrapping-unicore-service` as the main orchestration skill and keep its sub-skills aligned when the workflow changes materially.
- Treat `new-project-to-railway` as a Railway-specific alias of that orchestrator.
- Keep `AGENTS.md`, `.cursor/rules/`, and `.windsurf/skills/` aligned with the canonical skill set.

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
- Treat `building-unicore-tool` as the main orchestration skill and keep its sub-skills aligned when the workflow changes materially.
- Treat `zero-to-running-tool` as the first-run prerequisite skill for non-technical users or fresh machines, run before the orchestrator.
- Every app-internal endpoint goes through tRPC (`setting-up-trpc`). Raw `pages/api/*` is reserved for `/api/health` and `/api/auth/*` only — do not suggest `useEffect` + `fetch` against the app's own API.
- Keep `AGENTS.md`, `.cursor/rules/`, and `.windsurf/skills/` aligned with the canonical skill set.

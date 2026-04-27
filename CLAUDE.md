# Contributor Notes

- Canonical skill content lives in `skills/`.
- Edit shared skills first, then update manifests, install docs, or repo-local adapters if needed.
- Prefer symlinks over duplicated skill files for `.agents/skills/` and `.windsurf/skills/`.
- Keep platform manifests pointing at shared directories such as `./skills/`.
- If a workflow changes materially, keep `README.md`, `docs/`, `.cursor/rules/`, and consumer adapters aligned.

# Unicore Skills

## Railway projects — mandatory skill invocation

Before starting any new project that will be built and deployed to Railway, you MUST invoke the `building-unicore-tool` skill first. Do not write any code, create any files, or run any commands until you have read it.

This applies any time the user asks to:
- Create, build, or scaffold something and deploy/publish/host it on Railway
- Start a new web app, tool, game, dashboard, or service that will live on Railway
- Go "from scratch" or "from zero" to a live Railway URL

The skill enforces company conventions that cannot be inferred from context: the correct GitHub org (`unicore-railway`), GitHub-connected deploys (never `railway up`), the approved tech stack, and the full launch checklist. Skipping it leads to the wrong setup.

## Contributor Notes

- Canonical skill content lives in `skills/`.
- Edit shared skills first, then update manifests, install docs, or repo-local adapters if needed.
- Prefer symlinks over duplicated skill files for `.agents/skills/` and `.windsurf/skills/`.
- Keep platform manifests pointing at shared directories such as `./skills/`.
- If a workflow changes materially, keep `README.md`, `docs/`, `.cursor/rules/`, and consumer adapters aligned.

# Installing unicore-skills for Cursor

`unicore-skills` follows a shared-core plugin layout. The canonical skills live in `skills/`, while Cursor-specific wiring lives in `.cursor-plugin/`, `.cursor/rules/`, and `AGENTS.md`.

## Local usage before marketplace publishing

1. Clone the repository:

```bash
git clone https://github.com/universe-unicore/unicore-skills.git
```

2. Install the repo-local adapters into the target repository:

```bash
bash unicore-skills/scripts/install-consumer-adapters.sh /path/to/target-repo
```

This installs:

- `.agents/skills/`
- `.cursor/rules/`
- `AGENTS.md`
- `.github/copilot-instructions.md`
- `.windsurf/skills/`

## Marketplace packaging

The Cursor plugin manifest is at `.cursor-plugin/plugin.json`. When publishing, keep it pointed at the shared `skills/` directory and avoid duplicating skill content under Cursor-only paths.

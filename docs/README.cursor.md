# unicore-skills for Cursor

## Current distribution model

Until `unicore-skills` is published in the Cursor Marketplace, Cursor can consume the repository through repo-local adapters installed into a target project.

## Quick install

```bash
git clone https://github.com/universe-unicore/unicore-skills.git
bash unicore-skills/scripts/install-consumer-adapters.sh /path/to/target-repo
```

## How it works

- Shared skill content stays in `skills/`
- Cursor-specific packaging metadata lives in `.cursor-plugin/plugin.json`
- Consumer repos receive `.cursor/rules/` and `AGENTS.md`

This keeps the Cursor integration aligned with the same canonical playbooks used by the other tools.

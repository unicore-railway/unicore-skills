# unicore-skills

Process guides for the **Universe Group** Head Office (unicore), packaged as a [Claude Code plugin](https://docs.claude.com/en/docs/claude-code/plugins). Each guide is a skill that Claude can invoke automatically when the topic matches.

## Install

```bash
/plugin marketplace add universe-unicore/unicore-skills
/plugin install unicore-skills@universe-unicore
```

For local iteration:

```bash
claude --plugin-dir /path/to/unicore-skills
```

## Skills

| Skill | What it covers |
| --- | --- |
| [`new-project-to-railway`](skills/new-project-to-railway/SKILL.md) | Bootstrapping a new internal Next.js service, pushing to GitHub under `universe-unicore`, and deploying to Railway. |

## Adding a new guide

1. Create `skills/<topic-slug>/SKILL.md`.
2. Add YAML frontmatter at the top — the `description` is what Claude reads to decide when to use the skill, so make it concrete and trigger-friendly:

   ```yaml
   ---
   name: <topic-slug>
   description: Use when <situation>. Covers <key topics>.
   ---
   ```

3. Bump `version` in `.claude-plugin/plugin.json`.
4. Open a PR (or commit to `main` while the project is still finding its shape — see the trunk-based section in the [`new-project-to-railway`](skills/new-project-to-railway/SKILL.md) guide).

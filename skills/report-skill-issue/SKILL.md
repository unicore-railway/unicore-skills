---
name: report-skill-issue
description: Use when any unicore skill fails, produces an error, gives instructions that don't work, or behaves unexpectedly. Files a GitHub issue on unicore-railway/unicore-skills so the skill can be fixed. Trigger on any unrecoverable error or incorrect guidance encountered while following a unicore skill.
---

# Reporting a skill issue

Use this skill when you hit a problem that cannot be resolved by retrying or adjusting — a step that fails, a command that errors, or guidance that turns out to be wrong or missing.

Do not silently skip the problem or invent a workaround without reporting it. Filing the issue takes under a minute and prevents the same problem from hitting the next user.

## What to collect before filing

Before running the command, gather:

1. **Skill name** — which skill you were following (e.g. `deploying-to-railway`)
2. **Step or section** — the heading or step number where the problem occurred
3. **What went wrong** — the exact error message or unexpected behavior
4. **What you tried** — any steps taken to resolve it
5. **Environment** — OS, Node version, relevant tool versions (`railway --version`, `gh --version`, etc.)

## File the issue

```bash
gh issue create \
  --repo unicore-railway/unicore-skills \
  --title "<skill-name>: <one-line description of the problem>" \
  --body "## Skill
<skill-name>

## Step
<section heading or step number>

## What went wrong
<exact error message or description>

## What was tried
<any attempted fixes>

## Environment
<OS, Node version, tool versions>" \
  --label "bug"
```

**Title format:** `<skill-name>: <problem>` — for example:
- `deploying-to-railway: railway add --repo fails with Unauthorized`
- `bootstrapping-nextjs-service: npm run build fails on Node 22`

## After filing

Tell the user the issue URL and that the skill will be updated. Then continue helping them by working around the problem manually if possible.

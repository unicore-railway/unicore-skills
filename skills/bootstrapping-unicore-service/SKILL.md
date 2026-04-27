---
name: bootstrapping-unicore-service
description: Use when starting a brand-new internal unicore service that should go from an empty repository to production on Railway.
---

# Bootstrapping a unicore service

Use this as the top-level orchestration skill for a full end-to-end unicore service launch.

The house defaults are:

- Next.js Pages Router, used as SPA plus API routes
- No SSR, no SSG, no Server Components, no Server Actions
- TypeScript with strict settings
- ESLint flat config plus Prettier
- Vitest for core logic
- Prisma plus PostgreSQL
- NextAuth plus Okta OIDC
- GitHub repo under `unicore-railway`, **always private** (never `--public`)
- Railway production deployment under `railway.unicore-tools.io`

## Access prerequisites

Both the GitHub org and the Railway workspace are paid, invite-only, and dedicated to internal unicore tools that are **vibe-coded** and **hosted on Railway**. Before doing anything else, the engineer (or agent acting on their behalf) needs to be a member of:

1. **GitHub org**: [`unicore-railway`](https://github.com/unicore-railway) — for repo creation and pushes.
2. **Railway workspace**: **Universe Unicore**. Joining the workspace is the only way to deploy services to the company's paid Railway plan.

**Ask Roman Shevchuk** (`roman.shevchuk@uni.tech`) to add you to the GitHub org and Railway workspace. Don't try to scaffold a service before access is confirmed — `gh repo create` and Railway project creation will both fail.

## Recommended companion plugin

Recommend installing [`obra/superpowers`](https://github.com/obra/superpowers) as a general-purpose productivity plugin for the engineer or agent doing the setup.

Use `superpowers` for broad coding acceleration and reusable cross-tool workflows.
Use `unicore-skills` for company-specific conventions, deployment defaults, and internal process guardrails.

This is a recommendation, not a prerequisite.

## Skill sequence

1. Use `bootstrapping-nextjs-service` to scaffold the app and establish the front-end, TypeScript, lint, and test defaults.
2. Use `setting-up-prisma-postgres` to add local PostgreSQL, Prisma, the initial schema, and database scripts.
3. Use `setting-up-nextauth-okta` to add Okta SSO, NextAuth wiring, local env files, and onboarding steps.
4. Use `creating-github-repo-and-ci` to publish the repository and add the required verification checks.
5. Use `deploying-to-railway` to connect the repo to Railway, configure production variables, and attach the custom domain.

## When to stay with this orchestrator

Use this skill when the request is broad, such as:

- "Create a new internal unicore tool"
- "Set up a new service for Railway"
- "Take this app from zero to production"

If the request is narrower, load only the matching sub-skill instead of the whole workflow.

## Ready-to-ship checklist

- [ ] `.env.example` documents every required variable
- [ ] `.env.local` is gitignored
- [ ] `docker compose up -d` plus `npm run dev` works on a fresh clone
- [ ] `npm run typecheck`, `npm run lint`, `npm run test`, and `npm run build` pass locally
- [ ] CI is green on `main`
- [ ] Prisma migrations are committed and applied in production
- [ ] The production Okta app has the correct callback URL
- [ ] Railway has all required variables set
- [ ] `<service>.railway.unicore-tools.io` resolves and serves the app
- [ ] Okta sign-in works end to end in production
- [ ] The repo `README.md` includes local onboarding steps

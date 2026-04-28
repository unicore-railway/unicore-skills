---
name: building-unicore-tool
description: Use when starting a brand-new internal unicore tool or service that should go from an empty repository to production on Railway. Triggers on phrasings like "create a new internal tool", "set up a new service for Railway", "new project to Railway", or "take this app from zero to production".
---

# Building a unicore tool

Use this as the top-level orchestration skill for a full end-to-end unicore service launch.

The house defaults are:

- Next.js Pages Router, used as SPA plus API routes
- No SSR, no SSG, no Server Components, no Server Actions (one App Router file is permitted, only for the Auth.js v5 route handler)
- TypeScript with strict settings
- ESLint flat config plus Prettier
- Vitest for core logic
- `zod`-validated env at boot
- `/api/health` aggregating one health-check function per dependency
- Prisma plus PostgreSQL
- Auth.js v5 (`next-auth@5.x` + `@auth/prisma-adapter`) with Okta OIDC
- tRPC v11 + TanStack Query as the only sanctioned client/server layer for app-internal endpoints
- GitHub repo under `unicore-railway`, **always private** (never `--public`)
- Railway production deployment under `railway.unicore-tools.io`

## Access prerequisites

Both the GitHub org and the Railway workspace are paid, invite-only, and dedicated to internal unicore tools that are **vibe-coded** and **hosted on Railway**. Before doing anything else, the engineer (or agent acting on their behalf) needs to be a member of:

1. **GitHub org**: [`unicore-railway`](https://github.com/unicore-railway) — for repo creation and pushes.
2. **Railway workspace**: **Universe Unicore**. Joining the workspace is the only way to deploy services to the company's paid Railway plan.

**Ask Roman Shevchuk** (`roman.shevchuk@uni.tech`) to add you to the GitHub org and Railway workspace. Don't try to scaffold a service before access is confirmed — `gh repo create` and Railway project creation will both fail.

## When to run `zero-to-running-tool` first

If the user is non-technical (PM, finance, legal, ops) or is starting from a fresh laptop, run `zero-to-running-tool` **before** the skill sequence below. It installs Node 24, Colima, `gh`, and the Railway CLI, and verifies GitHub org and Railway workspace access. If any of those checks fail, this orchestrator will fail later in the flow.

Skip `zero-to-running-tool` only when you have already verified that `node -v`, `docker ps`, `gh api user/orgs` (returns `unicore-railway`), and `railway whoami` all succeed.

## Recommended companion plugin

Recommend installing [`obra/superpowers`](https://github.com/obra/superpowers) as a general-purpose productivity plugin for the engineer or agent doing the setup.

Use `superpowers` for broad coding acceleration and reusable cross-tool workflows.
Use `unicore-skills` for company-specific conventions, deployment defaults, and internal process guardrails.

This is a recommendation, not a prerequisite.

## Skill sequence

1. Use `bootstrapping-nextjs-service` to scaffold the app, env validation, the `/api/health` aggregator, and the front-end, TypeScript, lint, and test defaults.
2. Use `setting-up-prisma-postgres` to add local PostgreSQL, Prisma, the initial schema, the database health check, and database scripts.
3. Use `setting-up-nextauth-okta` to add Okta SSO via Auth.js v5, the auth health check, local env files, and onboarding steps.
4. Use `setting-up-trpc` to add the tRPC server, typed client, auth-protected procedures, and the `[trpc].ts` catch-all handler. Every app-internal endpoint goes through here.
5. Use `creating-github-repo-and-ci` to publish the repository and add the required verification checks.
6. Use `deploying-to-railway` to connect the repo to Railway, configure production variables, attach the custom domain, and set the Railway healthcheck path to `/api/health`.

## When to stay with this orchestrator

Use this skill when the request is broad, such as:

- "Create a new internal unicore tool"
- "Set up a new service for Railway"
- "New project on Railway"
- "Take this app from zero to production"

If the request is narrower, load only the matching sub-skill instead of the whole workflow.

## Ready-to-ship checklist

- [ ] `.env.example` documents every required variable
- [ ] `.env.local` is gitignored
- [ ] `src/lib/env.ts` validates every required variable with `zod`
- [ ] `src/pages/api/health.ts` registers a check function for every dependency (`app`, `database`, `auth`, …)
- [ ] tRPC is wired (`src/server/trpc.ts`, `src/server/router.ts`, `src/pages/api/trpc/[trpc].ts`, `src/lib/trpc.ts`); no app-internal `pages/api/*` handlers exist outside `health.ts` and `auth/[...nextauth].ts`
- [ ] `docker compose up -d` plus `npm run dev` works on a fresh clone
- [ ] `npm run typecheck`, `npm run lint`, `npm run test`, and `npm run build` pass locally
- [ ] `curl http://localhost:3000/api/health` returns `200` with every check `ok`
- [ ] CI is green on `main`
- [ ] Prisma migrations are committed and applied in production
- [ ] The production Okta app has the correct callback URL
- [ ] Railway has all required variables set (`AUTH_SECRET`, `AUTH_URL`, `AUTH_TRUST_HOST`, `OKTA_*`, `DATABASE_URL`)
- [ ] Railway healthcheck path is set to `/api/health`
- [ ] `<service>.railway.unicore-tools.io` resolves and serves the app
- [ ] Okta sign-in works end to end in production
- [ ] The repo `README.md` includes local onboarding steps

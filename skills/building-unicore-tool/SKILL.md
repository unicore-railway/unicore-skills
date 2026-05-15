---
name: building-unicore-tool
description: "Use this skill any time the user wants to build something new AND get it live on Railway — regardless of what it is (game, dashboard, form, tracker, kanban board, internal tool, web app, or anything else). This is the required skill for all zero-to-Railway workflows because it enforces company conventions: unicore-railway GitHub org, GitHub-connected deploys, and the standard Next.js + Prisma + Auth stack. Trigger on any phrasing that combines building with Railway hosting: 'create X and publish/deploy/ship/host it on railway', 'build X and put it on railway', 'new project to railway', 'take this from zero to a live URL on railway'. Also use when publishing a local project to GitHub under unicore-railway, or when setting up Okta SSO as part of a new service. Do not use for purely operational tasks on an already-running service (debugging crashes, updating env vars, scaling)."
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
- Railway deployment is **always GitHub-connected** — never `railway up`
- Railway production deployment under `unicore-railway.io`

## Access prerequisites

Both the GitHub org and the Railway workspace are paid, invite-only, and dedicated to internal unicore tools that are **vibe-coded** and **hosted on Railway**. Before doing anything else, the engineer (or agent acting on their behalf) needs to be a member of:

1. **GitHub org**: [`unicore-railway`](https://github.com/unicore-railway) — for repo creation and pushes.
2. **Railway workspace**: **Universe Unicore**. Joining the workspace is the only way to deploy services to the company's paid Railway plan.

**Ask Roman Shevchuk** (`roman.shevchuk@uni.tech`) to add you to the GitHub org and Railway workspace. Don't try to scaffold a service before access is confirmed — `gh repo create` and Railway project creation will both fail.

## When to run `zero-to-running-tool` first

If the user is non-technical (PM, finance, legal, ops) or is starting from a fresh laptop, run `zero-to-running-tool` **before** the skill sequence below. It installs Node 24, Docker Desktop, `gh`, and the Railway CLI, and verifies GitHub org and Railway workspace access. If any of those checks fail, this orchestrator will fail later in the flow.

Skip `zero-to-running-tool` only when you have already verified that `node -v`, `docker ps`, `gh api user/orgs` (returns `unicore-railway`), and `railway whoami` all succeed.

## Recommended companion plugins

Recommend installing [`obra/superpowers`](https://github.com/obra/superpowers) as a general-purpose productivity plugin for the engineer or agent doing the setup.

Recommend installing the [Railway plugin](https://github.com/railwayapp/railway-skills) for direct Railway API access (deploy status, logs, env vars, domains):

```bash
/plugin marketplace add railwayapp/railway-skills
/plugin install railway@railway-skills
claude mcp add railway-mcp-server -- npx -y @railway/mcp-server
```

Use the Railway plugin for general Railway API queries. Use `deploying-to-railway` for all deployment steps — it enforces unicore conventions that `use-railway` does not know about.

These are recommendations, not prerequisites.

## Skill sequence

1. Use `bootstrapping-nextjs-service` to scaffold the app, env validation, the `/api/health` aggregator, and the front-end, TypeScript, lint, and test defaults.
2. Use `setting-up-prisma-postgres` to add local PostgreSQL, Prisma, the initial schema, the database health check, and database scripts.
3. Use `setting-up-nextauth-okta` to add Okta SSO via Auth.js v5, the auth health check, local env files, and onboarding steps.
4. Use `setting-up-trpc` to add the tRPC server, typed client, auth-protected procedures, and the `[trpc].ts` catch-all handler. Every app-internal endpoint goes through here.
5. Use `creating-github-repo` to publish the repository to GitHub (always private) and apply the commit message convention. No GitHub Actions CI — Railway is the only deploy gate.
6. Use `deploying-to-railway` to connect the repo to Railway, configure production variables, attach the custom domain, and set the Railway healthcheck path to `/api/health`.

## When to stay with this orchestrator

Use this skill when the request is broad, such as:

- "Create a new internal unicore tool"
- "Set up a new service for Railway"
- "New project on Railway"
- "Take this app from zero to production"

If the request is narrower, load only the matching sub-skill instead of the whole workflow.

**Which sub-skills to skip:**

| Skip | When |
| --- | --- |
| `setting-up-prisma-postgres` | No persistent data (no database needed) |
| `setting-up-nextauth-okta` | No login or access control needed |
| `setting-up-trpc` | No app-internal API calls between client and server |

## Ready-to-ship checklist

- [ ] `.env.example` documents every required variable
- [ ] `.env.local` is gitignored
- [ ] `src/lib/env.ts` validates every required variable with `zod`
- [ ] `src/pages/api/health.ts` registers a check function for every dependency (`app`, `database`, `auth`, …)
- [ ] tRPC is wired (`src/server/trpc.ts`, `src/server/router.ts`, `src/pages/api/trpc/[trpc].ts`, `src/lib/trpc.ts`); no app-internal `pages/api/*` handlers exist outside `health.ts` and `auth/[...nextauth].ts`
- [ ] `docker compose up -d` plus `npm run dev` works on a fresh clone
- [ ] `npm run typecheck`, `npm run lint`, `npm run test`, and `npm run build` pass locally
- [ ] `curl http://localhost:3000/api/health` returns `200` with every check `ok`
- [ ] Prisma migrations are committed and applied in production
- [ ] The production Okta app has the correct callback URL
- [ ] Railway has all required variables set (`AUTH_SECRET`, `AUTH_URL`, `AUTH_TRUST_HOST`, `OKTA_*`, `DATABASE_URL`)
- [ ] Railway healthcheck path is set to `/api/health`
- [ ] `<service>.unicore-railway.io` resolves and serves the app
- [ ] Okta sign-in works end to end in production
- [ ] The repo `README.md` includes local onboarding steps

## After launch

Once the launch checklist is green, the team's recurring loop is **edit → preview → commit → push → auto-deploy**. The full step-by-step is documented in `creating-github-repo` under "Day-to-day workflow" — point engineers there, especially non-engineers who haven't yet internalized that `git push` is the deploy.

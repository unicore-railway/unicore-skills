---
name: new-project-to-railway
description: Use when bootstrapping a new internal unicore service to be deployed to Railway. Covers Next.js used as SPA + API routes (no SSR, no SSG, no Server Components, no Server Actions), strict TypeScript with ESLint flat config + Prettier, Vitest, Prisma + PostgreSQL (Docker locally), NextAuth with Okta SSO, GitHub repo creation under universe-unicore with required CI checks (typecheck/lint/test/build), and Railway deployment with auto-deploy on merge to main and custom domain under railway.unicore-tools.io.
---

# New project → GitHub → Railway

How to start a new **unicore internal service** from scratch, push it to GitHub under `universe-unicore`, and deploy it to Railway.

This guide is opinionated. It reflects the unicore house defaults; deviate only with a reason.

_Last verified against current tooling: **2026-04-24**._

---

## 1. When to use this guide

Use it whenever you start a new internal tool for the Head Office that will be **deployed to Railway**.

The default stack is fixed, so every unicore service looks and behaves the same way:

| Concern           | Default                                                      |
| ----------------- | ------------------------------------------------------------ |
| Framework         | Next.js (Pages Router), used as **SPA + API routes**         |
| Rendering         | Client-side only — **no SSR, no SSG, no RSC, no Server Actions** |
| Language          | TypeScript, strict                                           |
| Package manager   | npm (use the CLI, don't hand-edit `package.json`)            |
| Lint / format     | ESLint + Prettier, strict-leaning                            |
| Unit tests        | Vitest (required for core logic)                             |
| E2E tests         | Playwright — only when genuinely needed                      |
| Database          | PostgreSQL via Prisma                                        |
| Auth              | NextAuth.js with Okta OIDC provider                          |
| Local services    | Docker Compose (Postgres, anything else)                     |
| Secrets (prod)    | Railway variables (source of truth)                          |
| Secrets (local)   | `.env.local` (gitignored), filled per developer              |
| Hosting           | Railway — one project, multiple services                     |
| Environments      | `production` only                                            |
| Deploys           | Auto on merge to `main`                                      |
| Domain            | `<service>.railway.unicore-tools.io`                         |
| Logging           | `console.*` for now                                          |

---

## 2. Prerequisites

Before starting, make sure you have:

- **Node.js 24 LTS** (`node --version`) — install via [nvm](https://github.com/nvm-sh/nvm) if missing. Node 24 is the current Active LTS; Node 22 is in maintenance.
- **npm 11+** (bundled with Node 24).
- **Docker Desktop** running.
- **GitHub access** to the [`universe-unicore`](https://github.com/universe-unicore/) org (ask the unicore lead if missing).
- **Railway CLI**: `npm install -g @railway/cli`, then `railway login`.
- **Okta admin access** — you'll need to create a dev OIDC application.
- **gh CLI** (optional but recommended): `brew install gh && gh auth login`.

---

## 3. Create the project locally

### 3.1 Scaffold with `create-next-app`

```bash
npx create-next-app@latest my-service \
  --ts \
  --eslint \
  --no-app \
  --no-tailwind \
  --src-dir \
  --import-alias "@/*"
cd my-service
```

Flags explained:

- `--no-app` — use **Pages Router**, not App Router. App Router pushes you toward RSC/Server Actions, which we don't use.
- `--src-dir` — code under `src/` keeps the root clean.
- `--import-alias "@/*"` — `import x from "@/lib/x"` resolves to `src/lib/x`.

### 3.2 Pin the Node version

```bash
echo "24" > .nvmrc
npm pkg set engines.node=">=24.0.0"
```

### 3.3 Tighten TypeScript

`create-next-app` gives you `"strict": true` already. Open `tsconfig.json` and add:

```jsonc
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true
  }
}
```

### 3.4 ESLint + Prettier (strict-leaning)

Next.js 16 uses **ESLint flat config** — `create-next-app --ts` writes `eslint.config.mjs` for you. `next lint` was removed; we run `eslint` directly.

Install Prettier and the strict typescript-eslint config:

```bash
npm install --save-dev prettier eslint-config-prettier typescript-eslint
```

Replace `eslint.config.mjs` with:

```js
import { defineConfig, globalIgnores } from 'eslint/config';
import nextVitals from 'eslint-config-next/core-web-vitals';
import nextTs from 'eslint-config-next/typescript';
import tseslint from 'typescript-eslint';
import prettier from 'eslint-config-prettier/flat';

export default defineConfig([
  ...nextVitals,
  ...nextTs,
  ...tseslint.configs.strictTypeChecked,
  ...tseslint.configs.stylisticTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
  prettier,
  globalIgnores(['.next/**', 'out/**', 'build/**', 'next-env.d.ts']),
]);
```

Create `.prettierrc`:

```json
{
  "singleQuote": true,
  "semi": true,
  "trailingComma": "all",
  "printWidth": 100
}
```

Add scripts:

```bash
npm pkg set scripts.lint="eslint ."
npm pkg set scripts.format="prettier --write ."
npm pkg set scripts.typecheck="tsc --noEmit"
```

### 3.5 Vitest for unit tests

```bash
npm install --save-dev vitest @vitejs/plugin-react jsdom @testing-library/react @testing-library/jest-dom
```

Create `vitest.config.ts`:

```ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'node:path';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test/setup.ts'],
  },
  resolve: {
    alias: { '@': path.resolve(__dirname, './src') },
  },
});
```

Create `src/test/setup.ts`:

```ts
import '@testing-library/jest-dom/vitest';
```

Add a script and one sanity test:

```bash
npm pkg set scripts.test="vitest run"
npm pkg set scripts.test:watch="vitest"
```

`src/lib/__tests__/example.test.ts`:

```ts
import { describe, it, expect } from 'vitest';

describe('sanity', () => {
  it('runs', () => {
    expect(1 + 1).toBe(2);
  });
});
```

> **Playwright:** do **not** add it now. Add it only when you have a flow that genuinely needs browser-level E2E coverage.

### 3.6 Enforce the "SPA + API" pattern

Pages are plain React components. Data is fetched client-side in `useEffect` (or with SWR / TanStack Query).

**Do not write:**

- `getServerSideProps` or `getStaticProps`
- Server Components or Server Actions (App Router is disabled anyway)
- API calls during render

**Do write:**

- `pages/api/*` route handlers for backend logic
- Pages that `fetch('/api/...')` from `useEffect`

Example `src/pages/index.tsx`:

```tsx
import { useEffect, useState } from 'react';

type Health = { ok: boolean };

export default function Home() {
  const [health, setHealth] = useState<Health | null>(null);

  useEffect(() => {
    fetch('/api/health')
      .then((r) => r.json())
      .then(setHealth);
  }, []);

  return <pre>{JSON.stringify(health, null, 2)}</pre>;
}
```

`src/pages/api/health.ts`:

```ts
import type { NextApiRequest, NextApiResponse } from 'next';

export default function handler(_req: NextApiRequest, res: NextApiResponse) {
  res.status(200).json({ ok: true });
}
```

---

## 4. Database — Postgres + Prisma

### 4.1 Local Postgres via Docker Compose

Create `docker-compose.yml` at the repo root:

```yaml
services:
  postgres:
    image: postgres:17
    restart: unless-stopped
    ports:
      - '5432:5432'
    environment:
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev
      POSTGRES_DB: myservice
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  postgres-data:
```

Start it:

```bash
docker compose up -d
```

### 4.2 Install Prisma

```bash
npm install --save-dev prisma
npm install @prisma/client
npx prisma init --datasource-provider postgresql
```

Edit `prisma/schema.prisma` — minimal starting schema wired for NextAuth:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id            String    @id @default(cuid())
  email         String    @unique
  name          String?
  emailVerified DateTime?
  image         String?
  accounts      Account[]
  sessions      Session[]
}

model Account {
  id                String  @id @default(cuid())
  userId            String
  type              String
  provider          String
  providerAccountId String
  refresh_token     String? @db.Text
  access_token      String? @db.Text
  expires_at        Int?
  token_type        String?
  scope             String?
  id_token          String? @db.Text
  session_state     String?
  user              User    @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([provider, providerAccountId])
}

model Session {
  id           String   @id @default(cuid())
  sessionToken String   @unique
  userId       String
  expires      DateTime
  user         User     @relation(fields: [userId], references: [id], onDelete: Cascade)
}

model VerificationToken {
  identifier String
  token      String   @unique
  expires    DateTime

  @@unique([identifier, token])
}
```

Create a shared Prisma client in `src/lib/prisma.ts`:

```ts
import { PrismaClient } from '@prisma/client';

declare global {
  // eslint-disable-next-line no-var
  var prisma: PrismaClient | undefined;
}

export const prisma = globalThis.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== 'production') globalThis.prisma = prisma;
```

Run the first migration:

```bash
npx prisma migrate dev --name init
```

Add scripts:

```bash
npm pkg set scripts.db:migrate="prisma migrate dev"
npm pkg set scripts.db:deploy="prisma migrate deploy"
npm pkg set scripts.db:studio="prisma studio"
```

---

## 5. Auth — NextAuth.js with Okta

### 5.1 Create the dev Okta application

In the Okta admin console:

1. **Applications → Create App Integration → OIDC → Web Application**.
2. Sign-in redirect URI: `http://localhost:3000/api/auth/callback/okta`.
3. Sign-out redirect URI: `http://localhost:3000`.
4. Assign your Okta group (ask the Okta admin which group is correct for internal tools).
5. Copy **Client ID**, **Client Secret**, and the **Okta domain** (e.g. `https://universe.okta.com`).

You'll create a **second Okta app** for production later (Section 10), with the Railway callback URL.

### 5.2 Install NextAuth

```bash
npm install next-auth @next-auth/prisma-adapter
```

Create `src/pages/api/auth/[...nextauth].ts`:

```ts
import NextAuth, { type NextAuthOptions } from 'next-auth';
import OktaProvider from 'next-auth/providers/okta';
import { PrismaAdapter } from '@next-auth/prisma-adapter';
import { prisma } from '@/lib/prisma';

export const authOptions: NextAuthOptions = {
  adapter: PrismaAdapter(prisma),
  providers: [
    OktaProvider({
      clientId: process.env.OKTA_CLIENT_ID!,
      clientSecret: process.env.OKTA_CLIENT_SECRET!,
      issuer: process.env.OKTA_ISSUER!,
    }),
  ],
  session: { strategy: 'database' },
};

export default NextAuth(authOptions);
```

Wrap the app with a `SessionProvider` — `src/pages/_app.tsx`:

```tsx
import type { AppProps } from 'next/app';
import { SessionProvider } from 'next-auth/react';

export default function App({ Component, pageProps: { session, ...pageProps } }: AppProps) {
  return (
    <SessionProvider session={session}>
      <Component {...pageProps} />
    </SessionProvider>
  );
}
```

Protect API routes (example `src/pages/api/me.ts`):

```ts
import type { NextApiRequest, NextApiResponse } from 'next';
import { getServerSession } from 'next-auth/next';
import { authOptions } from './auth/[...nextauth]';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const session = await getServerSession(req, res, authOptions);
  if (!session) return res.status(401).json({ error: 'Unauthorized' });
  res.status(200).json({ user: session.user });
}
```

Gate UI client-side with `useSession()` from `next-auth/react`.

---

## 6. Local env vars

### 6.1 Files

- **`.env.local`** — gitignored, filled by each developer locally.
- **`.env.example`** — committed, documents every key with a comment on where to get its value.

Confirm `.gitignore` (added by `create-next-app`) contains:

```
.env*.local
```

### 6.2 `.env.example`

```bash
# Postgres (local Docker Compose — keep as-is unless you changed docker-compose.yml)
DATABASE_URL="postgresql://dev:dev@localhost:5432/myservice?schema=public"

# NextAuth
# Generate with: openssl rand -base64 32
NEXTAUTH_SECRET=""
NEXTAUTH_URL="http://localhost:3000"

# Okta dev app — ask the unicore lead / Okta admin for these
OKTA_CLIENT_ID=""
OKTA_CLIENT_SECRET=""
OKTA_ISSUER="https://universe.okta.com"
```

### 6.3 New-dev onboarding (add to your repo's `README.md`)

```bash
cp .env.example .env.local
# fill in OKTA_CLIENT_ID / OKTA_CLIENT_SECRET from the shared team note
# generate NEXTAUTH_SECRET: openssl rand -base64 32
docker compose up -d
npm install
npm run db:migrate
npm run dev
```

---

## 7. npm & scripts

**Always** use the npm CLI — don't hand-edit `package.json`.

```bash
npm install <pkg>               # add runtime dep
npm install --save-dev <pkg>    # add dev dep
npm uninstall <pkg>             # remove
npm pkg set scripts.foo="..."   # add/change a script
npm pkg delete scripts.foo      # remove a script
```

After the steps above, your `scripts` block should be roughly:

```json
{
  "dev": "next dev",
  "build": "next build",
  "start": "next start",
  "lint": "eslint .",
  "format": "prettier --write .",
  "typecheck": "tsc --noEmit",
  "test": "vitest run",
  "test:watch": "vitest",
  "db:migrate": "prisma migrate dev",
  "db:deploy": "prisma migrate deploy",
  "db:studio": "prisma studio"
}
```

---

## 8. Push to GitHub

### 8.1 Create the repo

```bash
git init
git add -A
git commit -m "chore: initial commit"
gh repo create universe-unicore/my-service \
  --private \
  --source=. \
  --remote=origin \
  --push
```

### 8.2 Branching rules

- **Early stage:** direct commits to `main` are fine while the project is still finding its shape.
- **When the project has real users or a second contributor:** switch to PR-only on `main`, enable required checks (next section).

Turning on protection later:

1. Repo → Settings → Branches → Add rule for `main`.
2. Require a pull request before merging.
3. Require status checks: `typecheck`, `lint`, `test`, `build`.
4. Optionally require a review.

---

## 9. CI — GitHub Actions

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - uses: actions/setup-node@v6
        with:
          node-version: 24
          cache: npm

      - run: npm ci

      - run: npx prisma generate

      - run: npm run typecheck
      - run: npm run lint
      - run: npm run test
      - run: npm run build
```

Each step (`typecheck`, `lint`, `test`, `build`) is its own check and can be marked **required** in branch protection.

---

## 10. Deploy to Railway

### 10.1 Create the Railway project

In the Railway dashboard:

1. **New Project → Deploy from GitHub repo → `universe-unicore/my-service`**.
2. Railway creates the `web` service automatically.
3. **+ New → Database → PostgreSQL** — adds a `postgres` service in the same project.

Keep **everything in one Railway project** (`web` + `postgres`). Don't make separate projects per service.

### 10.2 Production Okta app

Create a second Okta OIDC Web Application:

- Sign-in redirect: `https://<service>.railway.unicore-tools.io/api/auth/callback/okta`
- Sign-out redirect: `https://<service>.railway.unicore-tools.io`

### 10.3 Environment variables

On the `web` service → **Variables**:

| Key                   | Value                                                           |
| --------------------- | --------------------------------------------------------------- |
| `DATABASE_URL`        | `${{Postgres.DATABASE_URL}}` (Railway reference variable)       |
| `NEXTAUTH_SECRET`     | `openssl rand -base64 32` (generate a fresh one for production) |
| `NEXTAUTH_URL`        | `https://<service>.railway.unicore-tools.io`                    |
| `OKTA_CLIENT_ID`      | From the **prod** Okta app                                      |
| `OKTA_CLIENT_SECRET`  | From the **prod** Okta app                                      |
| `OKTA_ISSUER`         | `https://universe.okta.com`                                     |

Railway variables are the **source of truth** for production. Never commit these values anywhere.

### 10.4 Build & start commands

On the `web` service → **Settings**:

- **Build command:** `npm ci && npx prisma generate && npx prisma migrate deploy && npm run build`
- **Start command:** `npm start`

`prisma migrate deploy` runs pending migrations on every deploy — safe, idempotent.

### 10.5 Auto-deploy

The GitHub integration auto-deploys on every push to `main`. No manual action needed.

Only a **production** environment exists. No staging, no preview environments.

---

## 11. Custom domain

On the `web` service → **Settings → Networking → Custom Domain**:

1. Add `<service>.railway.unicore-tools.io`.
2. Railway shows a CNAME target.
3. Add the CNAME in the DNS provider for `unicore-tools.io` (ask the unicore lead who owns the zone).
4. Wait for the cert to issue (a couple of minutes).
5. Update `NEXTAUTH_URL` and the Okta prod app redirect URIs to this domain.

---

## 12. Logging & observability

Current baseline: **`console.log` / `console.error`** only. Railway captures stdout/stderr and shows it in the service's **Deploy Logs** / **Live Logs** tabs.

Not yet standardized:

- Sentry or any error-tracking
- Structured log shipping to an external sink
- Uptime monitoring

If you feel you need any of these, raise it with the unicore lead — the answer today is "not yet."

---

## 13. Ready-to-ship checklist

Before announcing the service is live:

- [ ] `.env.example` committed and accurate
- [ ] `.env.local` gitignored (double-check `git check-ignore .env.local`)
- [ ] `docker compose up -d` + `npm run dev` works on a fresh clone
- [ ] `npm run typecheck && npm run lint && npm run test && npm run build` all pass locally
- [ ] CI is green on `main`
- [ ] Prisma migrations committed and applied in prod
- [ ] Prod Okta app created with correct redirect URI
- [ ] Railway `web` service has all required env vars set
- [ ] `<service>.railway.unicore-tools.io` resolves and shows the app
- [ ] Sign-in with Okta works end-to-end in production
- [ ] README updated with the onboarding steps from Section 6.3
- [ ] Repo README links back to this guide

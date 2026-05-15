---
name: bootstrapping-nextjs-service
description: Use when starting a new internal unicore Next.js service and you need the standard scaffold, TypeScript, lint, formatting, testing, and SPA-plus-API defaults.
---

# Bootstrapping a Next.js service

Use this skill to create the local application skeleton for a new unicore internal service.

_Last verified against current tooling: **2026-04-24**._

## Prerequisites

- Node.js 22 or 24 LTS (24 preferred)
- npm 11+
- Docker Desktop installed and running

Optional later-stage tooling:

- `gh` CLI for repository creation
- Railway CLI for deployment work

GitHub org access and Railway workspace access are not required for local scaffolding. Those prerequisites belong to `building-unicore-tool` and `deploying-to-railway`.

Verify Docker Desktop is running:

```bash
docker ps
```

## Scaffold the app

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

Why these flags:

- `--no-app` keeps the project on Pages Router
- `--src-dir` keeps the root clean
- `--import-alias "@/*"` standardizes imports under `src/`

Pin Node:

```bash
echo "24" > .nvmrc
npm pkg set engines.node=">=22.0.0"
```

## Tighten TypeScript

Add these compiler options to `tsconfig.json`:

```jsonc
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true
  }
}
```

## Linting and formatting

Install the shared defaults:

```bash
npm install --save-dev prettier eslint-config-prettier typescript-eslint
```

Use this `eslint.config.mjs`:

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

## Testing

Install Vitest and React test helpers:

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

Add scripts:

```bash
npm pkg set scripts.test="vitest run"
npm pkg set scripts.test:watch="vitest"
```

Add one sanity test in `src/lib/__tests__/example.test.ts`:

```ts
import { describe, expect, it } from 'vitest';

describe('sanity', () => {
  it('runs', () => {
    expect(1 + 1).toBe(2);
  });
});
```

Do not add Playwright by default. Add it only when the product actually needs browser-level E2E coverage.

## Env validation

Every unicore service validates its environment at boot using `zod`. Missing or malformed vars must fail at startup with a readable error, not at first use.

Install:

```bash
npm install zod
```

Create `src/lib/env.ts`:

```ts
import { z } from 'zod';

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
});

export const env = schema.parse(process.env);
```

Subsequent skills (`setting-up-prisma-postgres`, `setting-up-nextauth-okta`) extend this schema. Always import `env` from this module — never read `process.env` directly outside of it.

## Health checks

Every unicore service exposes `/api/health`. It composes one health-check function per dependency (database, auth, etc.) so Railway and humans can see at a glance which piece is down.

Create `src/lib/health.ts`:

```ts
export type HealthStatus = 'ok' | 'degraded' | 'down';

export interface HealthCheckResult {
  name: string;
  status: HealthStatus;
  message?: string;
}

export type HealthCheck = () => Promise<HealthCheckResult>;

export async function runHealthChecks(checks: HealthCheck[]): Promise<{
  status: HealthStatus;
  checks: HealthCheckResult[];
}> {
  const results = await Promise.all(
    checks.map(async (c) => {
      try {
        return await c();
      } catch (e) {
        return {
          name: 'unknown',
          status: 'down' as const,
          message: e instanceof Error ? e.message : String(e),
        };
      }
    }),
  );
  const status: HealthStatus = results.some((r) => r.status === 'down')
    ? 'down'
    : results.some((r) => r.status === 'degraded')
      ? 'degraded'
      : 'ok';
  return { status, checks: results };
}
```

Create `src/pages/api/health.ts`:

```ts
import type { NextApiRequest, NextApiResponse } from 'next';
import { runHealthChecks, type HealthCheck } from '@/lib/health';

const checks: HealthCheck[] = [async () => ({ name: 'app', status: 'ok' })];

export default async function handler(_req: NextApiRequest, res: NextApiResponse) {
  const result = await runHealthChecks(checks);
  res.status(result.status === 'down' ? 503 : 200).json(result);
}
```

When subsequent skills add a dependency (database, auth, an upstream API), they append a check function to this `checks` array. The endpoint stays one file — only the array grows.

## SPA plus API pattern

Required approach:

- Pages are plain React components.
- App-internal data goes through tRPC (see `setting-up-trpc`). `tRPC` is the only sanctioned way to call your own API.
- Backend logic lives in tRPC procedures. The only raw `pages/api/*` handlers in a unicore service are `/api/health` (Railway healthcheck, defined in this skill) and `/api/auth/*` (managed by Auth.js).

Do not use:

- raw `fetch` or `useEffect` + `fetch` for app-internal endpoints — use tRPC
- `getServerSideProps`
- `getStaticProps`
- Server Components
- Server Actions
- API calls during render

At this stage of the bootstrap there is no UI data layer yet — `setting-up-trpc` adds it after auth is wired. Use a placeholder page until then:

```tsx
export default function Home() {
  return <main>unicore service ready</main>;
}
```

## Run it locally

Verify the bootstrap end-to-end before moving on to the next skill:

```bash
npm run dev
```

Open `http://localhost:3000` in a browser — you should see the placeholder page. Hit `http://localhost:3000/api/health` and you should get `200` with `{ status: 'ok', checks: [...] }` (only the `app` check at this stage; later skills append `database`, `auth`, etc.).

Keep `npm run dev` running while you work. It hot-reloads on every save, so editing a file and refreshing the browser is the fastest feedback loop and the live preview you'll use throughout development. Once the service is published to GitHub, the full edit → preview → commit → push → auto-deploy loop is documented in `creating-github-repo` under "Day-to-day workflow".

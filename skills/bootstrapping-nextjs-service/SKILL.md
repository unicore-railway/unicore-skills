---
name: bootstrapping-nextjs-service
description: Use when starting a new internal unicore Next.js service and you need the standard scaffold, TypeScript, lint, formatting, testing, and SPA-plus-API defaults.
---

# Bootstrapping a Next.js service

Use this skill to create the local application skeleton for a new unicore internal service.

_Last verified against current tooling: **2026-04-24**._

## Prerequisites

- Node.js 24 LTS
- npm 11+
- Colima installed and running with the Docker runtime
- GitHub access to `universe-unicore`
- Railway CLI available for later deployment
- `gh` CLI recommended

Recommended local container setup on macOS:

```bash
brew install colima docker
colima start
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
npm pkg set engines.node=">=24.0.0"
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

## SPA plus API pattern

Required approach:

- Pages are plain React components
- Data loads client-side with `useEffect`, SWR, or TanStack Query
- Backend logic lives in `pages/api/*`

Do not use:

- `getServerSideProps`
- `getStaticProps`
- Server Components
- Server Actions
- API calls during render

Example page:

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

Example API route:

```ts
import type { NextApiRequest, NextApiResponse } from 'next';

export default function handler(_req: NextApiRequest, res: NextApiResponse) {
  res.status(200).json({ ok: true });
}
```

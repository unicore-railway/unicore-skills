---
name: setting-up-prisma-postgres
description: Use when a unicore Next.js service needs local PostgreSQL through a Docker-compatible runtime plus Prisma schema, client, and migration setup.
---

# Setting up Prisma and PostgreSQL

Use this skill after the base Next.js service exists and needs a local database and ORM wiring.

## Local PostgreSQL

Assume Docker Desktop is installed and running.

Create `docker-compose.yml`:

```yaml
services:
  postgres:
    image: postgres:17
    restart: unless-stopped
    ports:
      - '127.0.0.1:5432:5432'
    environment:
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev
      POSTGRES_DB: myservice
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  postgres-data:
```

If you run multiple services on the same machine, each needs a unique host port to avoid conflicts. Change the left side of the port mapping (host port) — the container port stays 5432:

```yaml
ports:
  - '127.0.0.1:5433:5432'  # use 5433, 5434, etc. for each additional service
```

Update `DATABASE_URL` in `.env.local` to match:

```bash
DATABASE_URL="postgresql://dev:dev@localhost:5433/myservice?schema=public"
```

Start the database:

```bash
docker compose up -d
```

## Install Prisma

```bash
npm install --save-dev prisma
npm install @prisma/client
npx prisma init --datasource-provider postgresql
```

## Initial schema

Use a minimal schema that already supports Auth.js v5 (`@auth/prisma-adapter`):

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

  @@index([userId])
  @@unique([provider, providerAccountId])
}

model Session {
  id           String   @id @default(cuid())
  sessionToken String   @unique
  userId       String
  expires      DateTime
  user         User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
}
```

## Extend env validation

Add `DATABASE_URL` to the schema in `src/lib/env.ts`:

```ts
import { z } from 'zod';

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  DATABASE_URL: z.string().url(),
});

export const env = schema.parse(process.env);
```

A missing or malformed `DATABASE_URL` now fails at boot, not at first query.

## Shared Prisma client and health check

Create `src/lib/prisma.ts`:

```ts
import { PrismaClient } from '@prisma/client';
import type { HealthCheckResult } from './health';

declare global {
  // eslint-disable-next-line no-var
  var prisma: PrismaClient | undefined;
}

export const prisma = globalThis.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== 'production') globalThis.prisma = prisma;

export async function checkPrismaHealth(): Promise<HealthCheckResult> {
  try {
    await prisma.$queryRaw`SELECT 1`;
    return { name: 'database', status: 'ok' };
  } catch (e) {
    return {
      name: 'database',
      status: 'down',
      message: e instanceof Error ? e.message : String(e),
    };
  }
}
```

Register the database check in `src/pages/api/health.ts`:

```ts
import type { NextApiRequest, NextApiResponse } from 'next';
import { runHealthChecks, type HealthCheck } from '@/lib/health';
import { checkPrismaHealth } from '@/lib/prisma';

const checks: HealthCheck[] = [
  async () => ({ name: 'app', status: 'ok' }),
  checkPrismaHealth,
];

export default async function handler(_req: NextApiRequest, res: NextApiResponse) {
  const result = await runHealthChecks(checks);
  res.status(result.status === 'down' ? 503 : 200).json(result);
}
```

## First migration and scripts

Run the initial migration:

```bash
npx prisma migrate dev --name init
```

Add scripts:

```bash
npm pkg set scripts.db:migrate="prisma migrate dev"
npm pkg set scripts.db:deploy="prisma migrate deploy"
npm pkg set scripts.db:studio="prisma studio"
```

## Local variable expectation

The local database URL should match the local Compose defaults:

```bash
DATABASE_URL="postgresql://dev:dev@localhost:5432/myservice?schema=public"
```

If auth is also being added, continue with `setting-up-nextauth-okta`, which expects the Prisma models above.

Notes on the auth tables:

- `VerificationToken` is intentionally omitted from the baseline because the default unicore flow uses Okta SSO, not email or magic-link login.
- `Account` still includes provider token columns for adapter compatibility, but the baseline auth policy does not assume those tokens are used after sign-in.

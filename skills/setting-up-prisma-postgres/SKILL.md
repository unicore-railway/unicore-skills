---
name: setting-up-prisma-postgres
description: Use when a unicore Next.js service needs local PostgreSQL through a Docker-compatible runtime plus Prisma schema, client, and migration setup.
---

# Setting up Prisma and PostgreSQL

Use this skill after the base Next.js service exists and needs a local database and ORM wiring.

## Local PostgreSQL

Assume a Docker-compatible local runtime is already available. The default recommendation for macOS is Colima with the Docker CLI.

Create `docker-compose.yml`:

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

Use a minimal schema that already supports NextAuth:

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

## Shared Prisma client

Create `src/lib/prisma.ts`:

```ts
import { PrismaClient } from '@prisma/client';

declare global {
  // eslint-disable-next-line no-var
  var prisma: PrismaClient | undefined;
}

export const prisma = globalThis.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== 'production') globalThis.prisma = prisma;
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

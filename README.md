# scspace-split

Monorepo for SCSpace services.

- `packages/client`: Next.js application
- `packages/server`: NestJS API + Drizzle schema/migrations
- `packages/depot`: shared TypeScript package

## Repository Layout

```text
.
├── infra/
│   ├── compose/              # docker compose definitions
│   │   ├── docker-compose.infra.yml
│   │   ├── docker-compose.server.yml
│   │   ├── docker-compose.client.yml
│   │   ├── docker-compose.dev.yml
│   │   ├── docker-compose.edge.yml
│   │   ├── docker-compose.local.yml
│   │   └── docker-compose.stack.yml
│   ├── db/                   # mysql init/config
│   ├── nginx/                # nginx configs
│   └── script/               # deployment scripts
├── packages/
└── package.json
```

## Prerequisites

- Node.js (LTS)
- `pnpm` 10.x
- Docker + Docker Compose V2

## Local Development

1. Install dependencies.

```bash
pnpm install
```

2. Create env file.

```bash
cp .env.example .env
```

3. Build workspace packages.

```bash
pnpm build
```

4. Start dev processes.

```bash
pnpm dev
```

Default endpoints:

- Client: `http://localhost:3000`
- Server: `http://localhost:3001`

## Database Tasks (Drizzle)

```bash
pnpm generate   # generate migration SQL from schema changes
pnpm migrate    # apply pending migrations
pnpm push       # direct schema sync (non-production workflow)
```

Drizzle config: `packages/server/src/db/drizzle.config.ts`

## Docker Operations

`stack` is the default operational flow for this repository.

### Dev Infra Only (recommended for local coding)

Run infrastructure + edge proxy in Docker, and run application processes with `pnpm dev`.

```bash
pnpm docker:network:init
pnpm docker:dev:up
pnpm dev
```

For this flow, nginx forwards:

- `http://localhost/api/*` -> `http://host.docker.internal:3001`
- `http://localhost/*` -> `http://host.docker.internal:3000`

1. Initialize shared networks once per host.

```bash
pnpm docker:network:init
```

2. Start full stack.

```bash
pnpm docker:stack:up
```

3. Update selected services only.

```bash
docker compose -f infra/compose/docker-compose.stack.yml up -d --build server
docker compose -f infra/compose/docker-compose.stack.yml up -d --build client nginx
```

4. Stop stack.

```bash
pnpm docker:stack:down
```

### Compose Files

- `infra/compose/docker-compose.stack.yml`: full stack aggregator via `extends`
- `infra/compose/docker-compose.infra.yml`: MySQL + Redis
- `infra/compose/docker-compose.server.yml`: API service build/run
- `infra/compose/docker-compose.client.yml`: Next.js service build/run
- `infra/compose/docker-compose.dev.yml`: MySQL + Redis + local nginx for host-based `pnpm dev`
- `infra/compose/docker-compose.edge.yml`: Nginx + Certbot
- `infra/compose/docker-compose.local.yml`: lightweight local nginx/mysql profile

## Deployment Script

`infra/script/deploy.sh` performs:

1. `git pull --rebase --autostash`
2. `pnpm install --frozen-lockfile`
3. network initialization
4. stack build (`--pull`)
5. stack up (`-d`)

The script uses `infra/compose/docker-compose.stack.yml` as its compose entrypoint.

# SCSpace Monorepo

SCSpace is a full-stack monorepo application for managing space reservations, rentals, and community features.
It is built with **Next.js 15** (Frontend) and **NestJS** (Backend), using **pnpm workspaces** for package management.

## 🛠 Tech Stack

### **Frontend (`packages/client`)**
- **Framework:** Next.js 15 (App Router)
- **Language:** TypeScript
- **Styling:** Chakra UI + Emotion
- **State Management:**
  - **Server State:** TanStack Query (via custom `useQueryApi`)
  - **Client State:** Zustand
- **Forms:** React Hook Form + Zod

### **Backend (`packages/server`)**
- **Framework:** NestJS 10 (Modules, Controllers, Services)
- **Language:** TypeScript
- **Database:** MySQL
- **ORM:** Drizzle ORM
- **Authentication:** Passport (JWT Strategy)

### **Shared (`packages/depot`)**
- Shared TypeScript types, enums, and constants.
- Consumed by both client and server to ensure type safety.

---

## 📂 Project Structure

```bash
.
├── packages/
│   ├── client/    # Next.js Frontend
│   ├── server/    # NestJS Backend + DB Schema
│   └── depot/     # Shared Code (Types, Enums, Consts)
├── docker-compose.*.yml  # Docker orchestration
└── pnpm-workspace.yaml   # Monorepo configuration
```

---

## 🚀 Getting Started (Local Development)

### 1. Install Dependencies
```bash
pnpm install
```

### 2. Environment Setup
Copy the example environment file and configure it:
```bash
cp .env.example .env
```

### 3. Build Shared Library
The `depot` package must be built before starting the apps:
```bash
pnpm build
```

### 4. Start Development Server
This runs client, server, and depot (in watch mode) concurrently:
```bash
pnpm dev
```
- **Frontend:** http://localhost:3000
- **Backend:** http://localhost:3001

---

## 🗄️ Database Management (Drizzle ORM)

All database commands are run from the root using `pnpm`:

```bash
pnpm migrate          # Run pending migrations
pnpm generate         # Generate new migrations from schema changes
pnpm push             # Push schema changes directly to DB (Prototyping only)
```

Schema definition location: `packages/server/src/db/schema`

---

## 🐳 Dockerized Stacks

The project includes a comprehensive Docker setup for infrastructure and deployment.

| Compose file | Role |
| --- | --- |
| `docker-compose.infra.yml` | MySQL + Redis with persistent volumes on the shared `scspace-infra-network` |
| `docker-compose.server.yml` | NestJS server image built from `packages/server/Dockerfile` |
| `docker-compose.client.yml` | Next.js client image built from `packages/client/Dockerfile` |
| `docker-compose.edge.yml` | Nginx edge proxy (plus automated Certbot renewals) that fronts the app network |
| `docker-compose.stack.yml` | Convenience wrapper that extends and launches every service in one go |
| `docker-compose.prod.yml` | Production-ready bundle (client + backend + nginx + certbot) with network isolation |

### Quick Start with Docker

1. **Initialize Network:**
   ```bash
   pnpm docker:network:init
   ```

2. **Start Infrastructure & Apps:**
   ```bash
   pnpm docker:infra:up      # MySQL + Redis
   pnpm docker:server:up     # NestJS Backend
   pnpm docker:client:up     # Next.js Frontend
   pnpm docker:edge:up       # Nginx Proxy
   ```

3. **Stop Everything:**
   ```bash
   pnpm docker:stack:down
   ```

### Environment Variables (Docker)

The containers read from the root `.env`, but a few docker-only overrides are available:

| Variable | Default | Meaning |
| --- | --- | --- |
| `SERVER_APP_PORT` | `3001` | Internal NestJS port (exposed only to Docker networks) |
| `CLIENT_APP_PORT` | `3000` | Internal Next.js port |
| `SERVER_DB_HOST` | `scspace-mysql` | Hostname the server uses to reach MySQL |
| `NEXT_PUBLIC_API_URL` | `http://scspace-nginx/api` | API endpoint client containers call |
| `NGINX_CONFIG` | `./infra/nginx/nginx.local.conf` | Which nginx config to mount (swap to prod in deployment) |

---

## 📜 Infra Scripts

Scripts for initialization and deployment updates are located in `scspace/infra/script`.

```bash
cd scspace/infra/script
chmod +x <script_name>.sh
./<script_name>.sh
```

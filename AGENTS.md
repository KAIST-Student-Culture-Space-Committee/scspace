# PROJECT KNOWLEDGE BASE

**Generated:** 2026-02-02
**Context:** SCSpace Monorepo (Next.js + NestJS)

## OVERVIEW
SCSpace is a full-stack monorepo using **pnpm** workspaces.
- **Frontend:** Next.js 15 (App Router), React 19, Chakra UI + Emotion.
- **Backend:** NestJS, Drizzle ORM, MySQL.
- **Shared:** `@scspace-depot` for types/enums/consts.

## STRUCTURE
```
.
├── packages/
│   ├── client/    # Next.js Frontend
│   ├── server/    # NestJS Backend + DB Schema
│   └── depot/     # Shared Types/Utils (Build required)
├── docker-compose.*.yml  # Infra/Stack orchestration
└── pnpm-workspace.yaml
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Database Schema** | `packages/server/src/db/schema` | Drizzle ORM definitions |
| **API Endpoints** | `packages/server/src/feature/*` | Modularized by feature |
| **UI Components** | `packages/client/src/Components` | Atomic design (atoms, organisms) |
| **Global State** | `packages/client/src/Store` | Zustand stores |
| **Shared Types** | `packages/depot/src` | Must build after changing |

## COMMANDS
```bash
# Development
pnpm dev              # Start client + server + depot watch
pnpm build            # Build all packages

# Database (Drizzle)
pnpm migrate          # Run migrations
pnpm generate         # Generate migrations from schema
pnpm push             # Push schema to DB (prototyping)

# Infrastructure (Docker)
pnpm docker:stack:up  # Start full stack (DB + Redis + App)
pnpm docker:infra:up  # Start only infra (DB + Redis)
```

## CONVENTIONS
- **Package Manager:** Always use `pnpm`.
- **Shared Code:** NEVER duplicate types between client/server. Move to `depot`, run `pnpm build`, then import.
- **Styling:** Primary is Chakra UI/Emotion. (Tailwind is present but check usage).
- **Env Vars:** Managed via `dotenv-cli` and `.env` files.

## ANTI-PATTERNS (THIS PROJECT)
- **Direct Imports:** NEVER import from `../server` in client or vice-versa. Use `@scspace-depot`.
- **Manual Docker:** Use the `pnpm docker:*` scripts, don't run `docker compose` manually unless necessary.

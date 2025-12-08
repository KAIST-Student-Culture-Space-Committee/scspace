# scspace

## Dockerized stacks

| Compose file | Role |
| --- | --- |
| `docker-compose.infra.yml` | MySQL + Redis with persistent volumes on the shared `scspace-infra-network` |
| `docker-compose.server.yml` | NestJS server image built from `packages/server/Dockerfile` |
| `docker-compose.client.yml` | Next.js client image built from `packages/client/Dockerfile` |
| `docker-compose.edge.yml` | Nginx edge proxy (plus automated Certbot renewals) that fronts the app network |
| `docker-compose.stack.yml` | Convenience wrapper that extends and launches every service in one go |
| `docker-compose.prod.yml` | Production-ready bundle (client + backend + nginx + certbot) with network isolation |

Each compose file can be started independently, but they all communicate over two isolated bridges:

- `scspace-infra-network`: database/cache network (created when `docker-compose.infra.yml` is up)
- `scspace-internal-network`: application network for `client ↔ nginx ↔ backend`

Create the internal network once before running the app services:

```bash
pnpm docker:network:init
```

### Quick start

```bash
pnpm docker:infra:up      # spins up MySQL + Redis + network
pnpm docker:server:up     # builds & runs the NestJS container
pnpm docker:client:up     # builds & runs the Next.js container
pnpm docker:edge:up       # exposes 80/443 and proxies to the app
```

Bring down individual layers with the matching `docker:*:down` script, or stop everything via:

```bash
pnpm docker:stack:up      # launches infra + server + client + edge
pnpm docker:stack:down    # stops the entire stack
```

### Environment variables

The containers read from the root `.env`, but a few docker-only overrides are available:

| Variable | Default | Meaning |
| --- | --- | --- |
| `SERVER_APP_PORT` | `3001` | Internal NestJS port (exposed only to Docker networks) |
| `CLIENT_APP_PORT` | `3000` | Internal Next.js port |
| `SERVER_DB_HOST` | `scspace-mysql` | Hostname the server uses to reach MySQL |
| `NEXT_PUBLIC_API_URL` | `http://scspace-nginx/api` | API endpoint client containers call |
| `NGINX_CONFIG` | `./infra/nginx/nginx.local.conf` | Which nginx config to mount (swap to prod in deployment) |
| `NGINX_CERT_DIR` | `./infra/certbot/conf` | Shared Let's Encrypt configuration volume |
| `NGINX_CERT_WEBROOT` | `./infra/certbot/www` | Webroot served for ACME HTTP-01 challenges |

When running the edge proxy, swap in `infra/nginx/nginx.prod.conf` and set `NGINX_CERT_DIR` to your real LetsEncrypt path.

## Infra scripts (init, update, deploy)

```bash
cd scspace/infra/script
chmod +x <script_name>.sh
./<script_name>.sh
```

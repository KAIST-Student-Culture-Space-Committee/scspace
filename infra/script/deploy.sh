#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

cd "$ROOT_DIR"

echo "[deploy] pulling latest changes"
git pull --rebase --autostash

echo "[deploy] installing dependencies"
pnpm install --frozen-lockfile

echo "[deploy] ensuring docker networks exist"
pnpm docker:network:init

STACK_FILE="infra/compose/docker-compose.stack.yml"

echo "[deploy] building stack images"
docker compose -f "$STACK_FILE" build --pull

echo "[deploy] starting stack"
docker compose -f "$STACK_FILE" up -d

echo "[deploy] done"

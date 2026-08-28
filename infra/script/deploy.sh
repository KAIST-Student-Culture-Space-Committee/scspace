#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TIME_CHECK_SCRIPT="$ROOT_DIR/infra/script/check-host-time.sh"

cd "$ROOT_DIR"

echo "[deploy] checking host clock before update"
bash "$TIME_CHECK_SCRIPT"

echo "[deploy] pulling latest changes"
git pull --rebase --autostash

echo "[deploy] checking host clock with updated policy"
bash "$TIME_CHECK_SCRIPT"

echo "[deploy] installing dependencies"
pnpm install --frozen-lockfile

echo "[deploy] ensuring docker networks exist"
pnpm docker:network:init

STACK_FILE="infra/compose/docker-compose.stack.yml"

echo "[deploy] building stack images"
docker compose --env-file .env -f "$STACK_FILE" build --pull

echo "[deploy] starting stack"
docker compose --env-file .env -f "$STACK_FILE" up -d

echo "[deploy] done"

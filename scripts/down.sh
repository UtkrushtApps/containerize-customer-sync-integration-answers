#!/usr/bin/env bash
set -euo pipefail

# Stop and remove all containers, networks, and volumes for this stack.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR%/scripts}"

cd "$PROJECT_ROOT"

echo "[down.sh] Stopping and removing containers, networks, and volumes..."

docker compose -f docker-compose.yml down -v

echo "[down.sh] Stack stopped and all associated resources removed."

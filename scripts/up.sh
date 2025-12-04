#!/usr/bin/env bash
set -euo pipefail

# Start the full stack (Postgres, mock CRM, Camel app) in the background.
# The --build flag ensures any code or configuration changes are reflected.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR%/scripts}"

cd "$PROJECT_ROOT"

echo "[up.sh] Building images and starting containers..."

docker compose -f docker-compose.yml up -d --build

echo "[up.sh] Stack started. You can follow logs with:"
echo "  docker compose logs -f"

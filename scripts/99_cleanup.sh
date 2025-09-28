#!/usr/bin/env bash
set -euo pipefail

echo "停止并清理 tsnode 副本与残留 iperf sidecar..."
docker ps --format '{{.ID}} {{.Names}}' | awk '/iperf-srv-/{print $1}' | xargs -r docker rm -f

docker compose down -t 5

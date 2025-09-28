#!/usr/bin/env bash
set -euo pipefail
source .env

SERVICE="tsnode"
INTERVAL="${CHURN_INTERVAL:-30}"
PCT="${CHURN_BATCH_PERCENT:-10}"

echo "每 ${INTERVAL}s 随机对 ${PCT}% 容器执行 up/down/restart 抖动。按 Ctrl-C 结束。"

while true; do
  mapfile -t CTS < <(docker compose ps --format '{{.Name}}' "$SERVICE")
  TOT=${#CTS[@]}
  ((TOT>0)) || { echo "未发现容器"; exit 1; }
  BATCH=$(( (TOT*PCT + 99)/100 ))

  mapfile -t PICKED < <(printf "%s\n" "${CTS[@]}" | shuf -n "$BATCH")

  echo "=== Churn round: $(date '+%F %T') 目标 $BATCH/$TOT ==="
  for c in "${PICKED[@]}"; do
    op=$((RANDOM%3)) # 0:down 1:up 2:restart
    case "$op" in
      0)
        echo " - $c : tailscale down"
        docker exec "$c" tailscale down || true
        ;;
      1)
        echo " - $c : tailscale up"
        docker exec "$c" tailscale up --login-server="${HEADSCALE_URL}" --authkey="${TS_AUTHKEY}" --accept-dns=false || true
        ;;
      2)
        echo " - $c : docker restart"
        docker restart "$c" >/dev/null || true
        ;;
    esac
  done

  sleep "$INTERVAL"
done

#!/usr/bin/env bash
set -euo pipefail

OUT="nodes.tsv"
: > "$OUT"

mapfile -t CTS < <(docker compose ps --format '{{.Name}}' tsnode)

echo -e "container\tts_ip4" >> "$OUT"
for c in "${CTS[@]}"; do
  ip=$(docker exec "$c" tailscale ip -4 2>/dev/null | head -n1 || true)
  if [[ -n "$ip" ]]; then
    echo -e "${c}\t${ip}" >> "$OUT"
  fi
done

echo "已导出 $OUT（容器名 ↔ Tailscale IPv4）。"

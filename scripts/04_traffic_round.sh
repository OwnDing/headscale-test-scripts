#!/usr/bin/env bash
set -euo pipefail
source .env

PAIRS="${TRAFFIC_PAIR_COUNT:-30}"

[[ -f nodes.tsv ]] || bash scripts/02_list_nodes.sh

mapfile -t LINES < <(tail -n +2 nodes.tsv)
CNT=${#LINES[@]}
((CNT>=2)) || { echo "可用节点不足 2"; exit 1; }

pick_node() {
  local line="${LINES[$((RANDOM % CNT))]}"
  local name ip
  name=$(awk '{print $1}' <<<"$line")
  ip=$(awk '{print $2}' <<<"$line")
  echo "$name $ip"
}

run_pair_tcp() {
  local cA ipA cB ipB
  read -r cA ipA <<<"$(pick_node)"
  read -r cB ipB <<<"$(pick_node)"
  [[ "$cA" != "$cB" ]] || return 0

  docker run --rm -d --name "iperf-srv-${cB}" --network="container:${cB}" networkstatic/iperf3 -s -1 >/dev/null

  echo "[TCP] $cA -> $cB ($ipB)"
  docker run --rm --network="container:${cA}" networkstatic/iperf3 \
    -c "$ipB" -t "${TRAFFIC_TCP_DURATION:-10}" -P "${TRAFFIC_TCP_PARALLEL:-4}" >/dev/null 2>&1 || true
}

run_pair_udp() {
  local cA ipA cB ipB
  read -r cA ipA <<<"$(pick_node)"
  read -r cB ipB <<<"$(pick_node)"
  [[ "$cA" != "$cB" ]] || return 0

  docker run --rm -d --name "iperf-srv-${cB}" --network="container:${cB}" networkstatic/iperf3 -s -1 >/dev/null

  echo "[UDP] $cA -> $cB ($ipB)"
  docker run --rm --network="container:${cA}" networkstatic/iperf3 \
    -c "$ipB" -u -b "${TRAFFIC_UDP_BW:-50M}" -t "${TRAFFIC_UDP_DURATION:-10}" >/dev/null 2>&1 || true
}

echo "=== Traffic round @ $(date '+%F %T') pairs=${PAIRS} ==="
for ((i=0; i<PAIRS; i++)); do
  if (( RANDOM % 2 )); then
    run_pair_tcp &
  else
    run_pair_udp &
  fi
done
wait
echo "=== Round done ==="

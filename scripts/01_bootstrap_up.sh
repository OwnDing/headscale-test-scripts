#!/usr/bin/env bash
set -euo pipefail
source .env

echo "以 $REPLICAS 个副本拉起 tsnode..."
docker compose up -d --scale tsnode="${REPLICAS}"

echo "等待节点启动并完成登录（首次 30~60s）..."
sleep 45

echo "当前副本数量："
docker compose ps tsnode

echo "可运行 scripts/02_list_nodes.sh 导出节点 IP。"

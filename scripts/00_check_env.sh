#!/usr/bin/env bash
set -euo pipefail

if [[ -f .env ]]; then source .env; else echo ".env 未找到，请复制 .env.example"; exit 1; fi

command -v docker >/dev/null || { echo "docker 未安装"; exit 1; }
docker info >/dev/null || { echo "docker daemon 不可用"; exit 1; }

if ! docker compose version >/dev/null 2>&1; then
  echo "docker compose v2 未安装"; exit 1
fi

if [[ ! -e /dev/net/tun ]]; then
  echo "/dev/net/tun 不存在，尝试加载内核模块..."
  if command -v modprobe >/dev/null; then
    sudo modprobe tun || true
  fi
fi
[[ -e /dev/net/tun ]] || { echo "仍无 /dev/net/tun，请在宿主机启用 TUN 模块"; exit 1; }

echo "预拉取镜像（可选）..."
docker pull tailscale/tailscale:stable
docker pull networkstatic/iperf3:latest

echo "检查通过。"

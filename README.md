# headscale-loadtest（200 设备单机模拟）

这是一套**可直接使用**的压测脚本与 Compose 配置，用于在一台“发压端”上模拟约 200 台 Tailscale 客户端接入自建 headscale，并进行上线/下线抖动与 TCP/UDP 吞吐抽样测试。

## 目录
```
headscale-loadtest/
├─ docker-compose.yml
├─ .env.example   （复制为 .env 后修改）
├─ scripts/
│  ├─ 00_check_env.sh
│  ├─ 01_bootstrap_up.sh
│  ├─ 02_list_nodes.sh
│  ├─ 03_churn.sh
│  ├─ 04_traffic_round.sh
│  └─ 99_cleanup.sh
```

## 先决条件
- Linux 主机，内核启用 TUN（/dev/net/tun）
- Docker 与 docker compose v2
- 你的 headscale 已可外网访问，且已生成 **pre-auth key**

## 快速开始
1. 将本项目解压到任意目录，进入目录。
2. `cp .env.example .env`，编辑 `.env`，填入：
   - `HEADSCALE_URL=https://<你的 headscale 地址>`
   - `TS_AUTHKEY=tskey-auth-...`（预授权密钥）
   - 其余规模参数可保持默认
3. 运行环境检查与预拉镜像：
   ```
   bash scripts/00_check_env.sh
   ```
4. 启动并扩容到 200 节点：
   ```
   bash scripts/01_bootstrap_up.sh
   ```
5. 导出容器名与 Tailscale IP 对照：
   ```
   bash scripts/02_list_nodes.sh
   ```
   生成 `nodes.tsv`。
6. **制造上线/下线抖动**（终端 A）：
   ```
   bash scripts/03_churn.sh
   ```
7. **随机数据面抽样**（终端 B）：
   - 单轮执行：
     ```
     bash scripts/04_traffic_round.sh
     ```
   - 持续循环观察（每 20s 一轮）：
     ```
     watch -n 20 'bash scripts/04_traffic_round.sh'
     ```
8. 测试完成后清理：
   ```
   bash scripts/99_cleanup.sh
   ```

## 备注
- iperf3 不会安装进 tailscale 容器；脚本以 **短生命 sidecar** 方式（`--network=container:<tsnode>`）发起服务端/客户端，最大限度保持“设备镜像”纯净。
- `03_churn.sh` 会混合 `tailscale down/up` 与 `docker restart`，模拟不同状态转换路径。
- 如果你修改了 `.env` 中的 `REPLICAS`，可再次执行 `01_bootstrap_up.sh` 进行扩容/缩容。
- 若要观察直连 vs DERP 差异，可在网络层临时屏蔽 UDP，或调整防火墙策略后再对比吞吐。

祝测试顺利！

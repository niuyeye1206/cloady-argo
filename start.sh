#!/bin/sh
# 不用 ali.sh，直接跑 xray + cloudflared。
# 环境变量：UUID、ARGO_AUTH、PORT（平台健康检查端口）。

set -e

# 平台健康检查：3000 端口（或 $PORT）要能访问
mkdir -p /app/www
echo ok > /app/www/index.html
cd /app/www
python3 -m http.server "${PORT:-3000}" >/app/http.log 2>&1 &
cd /app

# 生成 xray 配置（三个协议分三个端口：VLESS 8001、VMess 8002、Trojan 8003，
# 隧道按路径分流到对应端口）
UUID="${UUID:?UUID env var is required}"
sed -e "s/__UUID__/$UUID/g" /app/xray-config.json > /app/config.json

# 启动 xray
/app/xray run -config /app/config.json >/app/xray.log 2>&1 &

# 启动 cloudflared 隧道（ingress 已在 Cloudflare 侧按路径配好：
# /vless-argo->8001、/vmess-argo->8002、/trojan-argo->8003）
/app/cloudflared tunnel --no-autoupdate run --token "${ARGO_AUTH:?ARGO_AUTH env var is required}" >/app/cloudflared.log 2>&1 &

echo "xray + cloudflared started"
tail -f /dev/null

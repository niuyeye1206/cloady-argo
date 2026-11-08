#!/bin/bash
# Cloady 容器启动脚本：健康检查 HTTP 服务 + 跑 ali.sh
set -e

# Cloady 要求 web 服务在端口上接受连接，不然部署判失败。
# 用一个极简 HTTP 服务占住 $PORT（默认 3000），只做健康检查用。
PORT="${PORT:-3000}"
mkdir -p /app/www
echo "ok" > /app/www/index.html
python3 -m http.server "$PORT" --bind 0.0.0.0 --directory /app/www &

# 跑 ali.sh（强制 Python 版），隧道信息全从环境变量来。
# 必填：ARGO_DOMAIN、ARGO_AUTH；建议固定：UUID；端口固定 8001。
export ARGO_PORT=8001
bash /app/ali.sh -py

# ali.sh 把 xray / cloudflared 挂到 screen 后台就退出了，这里守住容器不退出。
tail -f /dev/null

FROM debian:12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl python3 python3-venv screen ca-certificates procps \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 下载 ali.sh（你给的那个脚本）
RUN curl -Ls https://main.ssss.nyc.mn/ali.sh -o /app/ali.sh && chmod +x /app/ali.sh

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# wget 包装：ali.sh 用 wget 下文件时没超时，容器里会无限挂住。
# 把带超时+重试（失败用 curl 兜底）的包装放到 PATH 最前面，让 wget 先走它。
COPY wget-wrapper.sh /usr/local/bin/wget
RUN chmod +x /usr/local/bin/wget

CMD ["/app/start.sh"]

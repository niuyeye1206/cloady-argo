FROM debian:12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl python3 python3-venv screen ca-certificates procps \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 下载 ali.sh（你给的那个脚本）
RUN curl -Ls https://main.ssss.nyc.mn/ali.sh -o /app/ali.sh && chmod +x /app/ali.sh

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]

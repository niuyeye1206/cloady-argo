FROM debian:12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl python3 ca-certificates unzip procps \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# xray：直接用官方 release，不走 ali.sh
RUN curl -fsSL https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o /tmp/xray.zip \
 && unzip -o -q /tmp/xray.zip -d /tmp/xray \
 && mv /tmp/xray/xray /app/xray \
 && chmod +x /app/xray \
 && rm -rf /tmp/xray.zip /tmp/xray

# cloudflared：直接用官方 release
RUN curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /app/cloudflared \
 && chmod +x /app/cloudflared

COPY xray-config.json /app/xray-config.json
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]

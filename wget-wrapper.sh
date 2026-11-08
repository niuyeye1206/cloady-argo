#!/bin/sh
# 容器里 wget 下 raw.githubusercontent.com 会无限挂住，
# 连 --timeout=25 --tries=2 都救不了（疑似卡在 DNS，超时不生效），
# 但 curl 同一地址 1.7 秒就能下完。所以带 -O 的下载直接改用 curl，
# 不再走 wget；其他 wget 调用用 timeout 强制兜底，避免无限挂住。
out=""
url=""
prev=""
for a in "$@"; do
  if [ "$prev" = "-O" ]; then
    out="$a"
  fi
  prev="$a"
  url="$a"
done
if [ -n "$out" ] && [ -n "$url" ]; then
  exec curl -fsSL --retry 2 --max-time 60 -o "$out" "$url"
fi
exec timeout 30 /usr/bin/wget --timeout=25 --tries=1 "$@"

#!/bin/sh
# wget 包装：容器里 wget 下 raw.githubusercontent.com 会无限挂住（没超时）。
# 先用带超时的 wget 试，失败就用 curl 兜底（curl 在容器里实测是通的）。
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
REAL_WGET=/usr/bin/wget
if [ ! -x "$REAL_WGET" ]; then
  REAL_WGET=""
  for p in /usr/bin /bin /usr/sbin /sbin; do
    if [ -x "$p/wget" ]; then REAL_WGET="$p/wget"; break; fi
  done
fi
if [ -n "$REAL_WGET" ] && "$REAL_WGET" --timeout=25 --tries=2 --waitretry=2 "$@"; then
  exit 0
fi
if [ -n "$out" ] && [ -n "$url" ]; then
  curl -fsSL --retry 2 --max-time 60 -o "$out" "$url"
  exit $?
fi
exit 1

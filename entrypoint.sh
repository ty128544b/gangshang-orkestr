#!/bin/sh
# orkestr 入口：UUID/WS 路径/端口全部来自环境变量，不进镜像层；
# xray 配置写到 /tmp（平台以非 root 用户运行容器，/etc 未必可写）。
# 2026-11-09：去掉 nginx——非 root 容器里 nginx 读配置前 chown 临时目录报
# Operation not permitted 而退出；改由 Node 直接监听 $PORT 并透传 WS 升级请求。
set -e
: "${XRAY_UUID:?missing XRAY_UUID env}"
: "${XRAY_WS_PATH:?missing XRAY_WS_PATH env}"
PORT="${PORT:-8080}"

sed -e "s#__UUID__#${XRAY_UUID}#g" -e "s#__WS_PATH__#${XRAY_WS_PATH}#g" \
  /etc/xray/config.json.template > /tmp/xray/config.json

xray run -c /tmp/xray/config.json &
XPID=$!
sleep 2
PORT="$PORT" node /srv/app/server.js &
NPID=$!
while kill -0 $XPID 2>/dev/null && kill -0 $NPID 2>/dev/null; do sleep 5; done
exit 1

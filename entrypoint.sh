#!/bin/sh
# Koyeb 入口：UUID/WS 路径/端口全部来自环境变量，不进镜像层。
set -e
: "${XRAY_UUID:?missing XRAY_UUID env}"
: "${XRAY_WS_PATH:?missing XRAY_WS_PATH env}"
PORT="${PORT:-8000}"

sed -e "s#__UUID__#${XRAY_UUID}#g" -e "s#__WS_PATH__#${XRAY_WS_PATH}#g" \
  /etc/xray/config.json.template > /etc/xray/config.json
sed -e "s#__PORT__#${PORT}#g" -e "s#__WS_PATH__#${XRAY_WS_PATH}#g" \
  /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

xray run -c /etc/xray/config.json &
XPID=$!
sleep 2
node /srv/app/server.js &
NPID=$!
nginx -c /etc/nginx/nginx.conf -g 'daemon off;' &
NGPID=$!
while kill -0 $XPID 2>/dev/null && kill -0 $NPID 2>/dev/null && kill -0 $NGPID 2>/dev/null; do sleep 5; done
exit 1

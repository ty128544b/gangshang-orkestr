#!/bin/sh
# orkestr 入口：UUID/WS 路径/端口全部来自环境变量，不进镜像层；
# 配置文件写到 /tmp（平台以非 root 用户运行容器，/etc 未必可写）。
set -e
: "${XRAY_UUID:?missing XRAY_UUID env}"
: "${XRAY_WS_PATH:?missing XRAY_WS_PATH env}"
PORT="${PORT:-8080}"

sed -e "s#__UUID__#${XRAY_UUID}#g" -e "s#__WS_PATH__#${XRAY_WS_PATH}#g" \
  /etc/xray/config.json.template > /tmp/xray/config.json
sed -e "s#__PORT__#${PORT}#g" -e "s#__WS_PATH__#${XRAY_WS_PATH}#g" \
  /etc/nginx/nginx.conf.template > /tmp/nginx/nginx.conf

xray run -c /tmp/xray/config.json &
XPID=$!
sleep 2
node /srv/app/server.js &
NPID=$!
nginx -c /tmp/nginx/nginx.conf -g 'daemon off;' &
NGPID=$!
while kill -0 $XPID 2>/dev/null && kill -0 $NPID 2>/dev/null && kill -0 $NGPID 2>/dev/null; do sleep 5; done
exit 1

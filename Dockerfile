# syntax=docker/dockerfile:1
# orkestr 免费档部署：xray (VLESS+WS) + Node 港上后端，二合一容器
# 入口由 $PORT 环境变量决定（orkestr 控制台设 PORT=8080），Node 直接监听它并透传 WS 升级请求。
# 2026-11-09：去掉 nginx——平台以非 root 用户运行容器，nginx 读配置前 chown 临时目录
# 报 Operation not permitted 而退出；Node 透传方案已在本地用真实 xray 拨测验证通过。
FROM ghcr.io/xtls/xray-core:latest AS xray

FROM alpine:3.22
RUN apk add --no-cache ca-certificates tzdata nodejs \
 && mkdir -p /tmp/xray \
 && chmod 777 /tmp/xray
COPY --from=xray /usr/local/bin/xray /usr/local/bin/xray
COPY --from=xray /usr/local/share/xray/geoip.dat /usr/local/share/xray/geoip.dat
COPY --from=xray /usr/local/share/xray/geosite.dat /usr/local/share/xray/geosite.dat
COPY config.json.template /etc/xray/config.json.template
COPY server.js /srv/app/server.js
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod a+x /usr/local/bin/entrypoint.sh \
 && chgrp -R 0 /srv/app /etc/xray /usr/local/bin \
 && chmod -R g=u /srv/app /etc/xray /usr/local/bin
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

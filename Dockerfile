# syntax=docker/dockerfile:1
# Koyeb 免费档部署：xray (VLESS+WS) + Node 港上后端，二合一容器
# 入口由 Koyeb 的 $PORT 环境变量决定（默认 8000），nginx 监听它。
FROM ghcr.io/xtls/xray-core:latest AS xray

FROM alpine:3.22
RUN apk add --no-cache ca-certificates tzdata nginx nodejs
COPY --from=xray /usr/local/bin/xray /usr/local/bin/xray
COPY --from=xray /usr/local/share/xray/geoip.dat /usr/local/share/xray/geoip.dat
COPY --from=xray /usr/local/share/xray/geosite.dat /usr/local/share/xray/geosite.dat
COPY config.json.template /etc/xray/config.json.template
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY server.js /srv/app/server.js
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod a+x /usr/local/bin/entrypoint.sh \
 && mkdir -p /var/lib/nginx /var/log/nginx /var/tmp/nginx \
 && chown -R nobody:nobody /var/lib/nginx /var/log/nginx /var/tmp/nginx /srv/app
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# syntax=docker/dockerfile:1
# orkestr 免费档部署：xray (VLESS+WS) + Node 港上后端，二合一容器
# 入口由 $PORT 环境变量决定（orkestr 控制台设 PORT=8080），nginx 监听它。
# 2026-11-09 修复：平台以非 root 用户运行容器；nginx 在读配置前会先打开编译进的
# 默认错误日志与临时目录（/var/lib/nginx/logs、/var/lib/nginx/tmp/*），必须在镜像里
# 预建这些目录并 chmod 777，否则 nginx 启动即 Permission denied（首轮部署失败原因）。
# 运行时配置与日志一律走 /tmp（见 entrypoint.sh 与 nginx.conf.template）。
FROM ghcr.io/xtls/xray-core:latest AS xray

FROM alpine:3.22
RUN apk add --no-cache ca-certificates tzdata nginx nodejs \
 && mkdir -p /tmp/xray /tmp/nginx \
    /var/lib/nginx/logs /var/lib/nginx/tmp/client_body /var/lib/nginx/tmp/proxy \
    /var/lib/nginx/tmp/fastcgi /var/lib/nginx/tmp/uwsgi /var/lib/nginx/tmp/scgi \
    /var/log/nginx /var/tmp/nginx \
 && chmod 777 /tmp/xray /tmp/nginx \
    /var/lib/nginx /var/lib/nginx/logs /var/lib/nginx/tmp \
    /var/lib/nginx/tmp/client_body /var/lib/nginx/tmp/proxy \
    /var/lib/nginx/tmp/fastcgi /var/lib/nginx/tmp/uwsgi /var/lib/nginx/tmp/scgi \
    /var/log/nginx /var/tmp/nginx
COPY --from=xray /usr/local/bin/xray /usr/local/bin/xray
COPY --from=xray /usr/local/share/xray/geoip.dat /usr/local/share/xray/geoip.dat
COPY --from=xray /usr/local/share/xray/geosite.dat /usr/local/share/xray/geosite.dat
COPY config.json.template /etc/xray/config.json.template
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY server.js /srv/app/server.js
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod a+x /usr/local/bin/entrypoint.sh \
 && chgrp -R 0 /srv/app /etc/xray /etc/nginx /usr/local/bin \
 && chmod -R g=u /srv/app /etc/xray /etc/nginx /usr/local/bin
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

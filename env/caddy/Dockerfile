FROM alpine:3.9

# ENV LANG=zh_CN.UTF-8 \
#     LANGUAGE=zh_CN:en_US:en \
ENV TZ=Asia/Shanghai

COPY Caddyfile /

RUN set -ex \
    && apk add --no-cache libcap curl bash \
    && curl -kL https://getcaddy.com | bash -s personal http.filebrowser,http.realip \
    && setcap cap_net_bind_service=+ep `which caddy` \
    && addgroup -g 82 -S www-data \
	&& adduser -u 82 -D -S -G www-data www-data

USER www-data
EXPOSE 80 3000

CMD ["caddy", "--quic", "-conf", "/Caddyfile"]

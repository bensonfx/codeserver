FROM php:7.2-fpm-alpine

# ENV LANG=zh_CN.UTF-8 \
#     LANGUAGE=zh_CN:en_US:en \
ENV TZ=Asia/Shanghai WEB_ROOT=/wwwroot

COPY zentao-fetch.sh zentao-entrypoint caddy Caddyfile /usr/local/bin/

RUN zentao-fetch.sh

USER www-data
ENTRYPOINT ["zentao-entrypoint"]

CMD ["php-fpm", "caddy"]

FROM php:7.2-fpm-alpine

# ENV LANG=zh_CN.UTF-8 \
#     LANGUAGE=zh_CN:en_US:en \
ENV VERSION=7.2-fpm-alpine TZ=Asia/Shanghai WEB_ROOT=/wwwroot

COPY config-env.sh /usr/local/bin/

RUN config-env.sh

USER www-data

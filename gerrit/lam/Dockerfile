FROM php:7.2-fpm-alpine

COPY install_lam.sh /tmp

# ENV LANG=zh_CN.UTF-8 \
#     LANGUAGE=zh_CN:en_US:en \
ENV TZ=Asia/Shanghai

RUN set -ex \
    && sed -i "s@dl-cdn.alpinelinux.org@mirrors.aliyun.com@g" /etc/apk/repositories \
    && apk add --no-cache --virtual .fetch-deps \
            openldap-dev \
            zlib-dev \
            gettext-dev \
            perl \
    && apk add --no-cache --virtual .build-deps \
            coreutils \
            make \
    && export PHP_EXT="gettext zip ldap" \
	&& docker-php-ext-install -j$(nproc) ${PHP_EXT}\
    && /tmp/install_lam.sh \
    && apk del .build-deps \
    && rm -rf /tmp/* /var/tmp/*

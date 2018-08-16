#!/bin/sh
set -ex
export LC_ALL=C

VER=${DOCKER_ZENTAO_VER:-10.2}
ZENTAO_PKG=${WEB_ROOT}/zentao.zip
ZENTAO_URL=http://sourceforge.net/projects/zentao/files/${VER}/ZenTaoPMS.${VER}.stable.zip/download

PHP_CONF_DIR=$(php --ini | grep additional | grep -o "/.*/etc/php.*")
init_deps() {

    sed -i 's@dl-cdn.alpinelinux.org@mirrors.aliyun.com@g' /etc/apk/repositories
    apk add --no-cache --virtual .fetch-deps \
            openldap-dev zlib-dev \
            gettext-dev perl libcap
    apk add --no-cache --virtual .build-deps \
            coreutils make zip
    export PHP_EXT="pdo_mysql"
	docker-php-ext-install -j$(nproc) ${PHP_EXT}

    #config php session
    local session_cfg=${PHP_CONF_DIR}/session.ini
    local PHP_SESSION_DIR=${WEB_ROOT}/zentaopms/tmp/session
cat << EOF > ${session_cfg}
session.save_handler = "files"
session.save_path    = "${PHP_SESSION_DIR}"
expose_php = false
EOF
    #run php-fpm as deamon
    local php_fpm_cfg=/usr/local/etc/php-fpm.d/zz-docker.conf
    sed -i "s#daemonize = .*#daemonize = yes#g" $php_fpm_cfg

}

fetch() {
    [ -d ${WEB_ROOT} ] || install -d ${WEB_ROOT}/zentaopms
    chown -R www-data:www-data ${WEB_ROOT}

    curl -L ${ZENTAO_URL} -o ${ZENTAO_PKG}

    setcap cap_net_bind_service=+ep `which caddy`
    setcap cap_net_bind_service=+ep `which php-fpm`
    mv /usr/local/bin/Caddyfile ${WEB_ROOT}/
}

clean() {
    apk del .build-deps
    rm -rf /tmp/* /var/tmp/*
}

init_deps
fetch
clean

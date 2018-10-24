#!/bin/sh
set -ex
export LC_ALL=C

VER=${DOCKER_ZENTAO_VER:-10.4}
ZENTAO_PKG=${WEB_ROOT}/zentao.zip
ZENTAO_URL=http://sourceforge.net/projects/zentao/files/${VER}/ZenTaoPMS.${VER}.stable.zip/download

PHP_CONF_DIR=$(php --ini | grep additional | grep -o "/.*/etc/php.*")
FPM_CONF_DIR="/usr/local/etc/php-fpm.d"
config_php() {
    #config php session
    local php_cfg=${PHP_CONF_DIR}/extra.ini
    local PHP_SESSION_DIR=${WEB_ROOT}/zentaopms/tmp/session
cat > ${php_cfg} << EOF
session.save_handler = "files"
session.save_path    = "${PHP_SESSION_DIR}"
expose_php = false
cgi.fix_pathinfo = 0
date.timezone = Asia/Shanghai
short_open_tag = On
upload_max_filesize = 50M
disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,fsocket,popen
EOF
    #run php-fpm as deamon
    local php_fpm_docker_cfg=${FPM_CONF_DIR}/zz-docker.conf
    sed -i "s#^daemonize = .*#daemonize = yes#g" $php_fpm_docker_cfg
    sed -i "s#listen = .*#listen = /dev/shm/php-cgi.sock#g" $php_fpm_docker_cfg

    local php_fpm_www_cfg=${FPM_CONF_DIR}/www.conf
    sed -i "s#^pm.max_children =.*#pm.max_children = 50#g" $php_fpm_www_cfg
    sed -i "s#^pm.start_servers =.*# pm.start_servers = 30#g" $php_fpm_www_cfg
    sed -i "s#^pm.min_spare_servers = .*#pm.min_spare_servers = 20#g" $php_fpm_www_cfg
    sed -i "s#^pm.max_spare_servers = .*#pm.max_spare_servers = 50#g" $php_fpm_www_cfg
    sed -i "s#^;pm.max_requests = .*#pm.max_requests = 2048#g" $php_fpm_www_cfg
}

init_deps() {
    sed -i 's@dl-cdn.alpinelinux.org@mirrors.aliyun.com@g' /etc/apk/repositories
    apk add --no-cache --virtual .fetch-deps \
            openldap-dev zlib-dev \
            gettext-dev perl libcap
    apk add --no-cache --virtual .build-deps \
            coreutils make zip
    export PHP_EXT="pdo_mysql"
	docker-php-ext-install -j$(nproc) ${PHP_EXT}
    config_php
}

configure() {
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
configure
clean

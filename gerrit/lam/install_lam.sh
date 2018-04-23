#!/bin/sh
set -ex
export LC_ALL=C

VER=${DOCKER_LAM_VER:-6.3}
LAM_PKG=ldap-account-manager-${VER}.tar.bz2
LAM_URL=http://prdownloads.sourceforge.net/lam/${LAM_PKG}?download
LAM_DIR=${DOCKER_LAM_DIR:-"/wwwroot/lam"}

init_deps() {
    #apt-get install -yqq locales tzdata
    #locale-gen zh_CN.UTF-8
    sed -i 's@dl-cdn.alpinelinux.org@mirrors.aliyun.com@g' /etc/apk/repositories
    apk add --no-cache --virtual .fetch-deps \
            openldap-dev zlib-dev \
            gettext-dev perl
    apk add --no-cache --virtual .build-deps \
            coreutils make
    export PHP_EXT="gettext zip ldap"
	docker-php-ext-install -j$(nproc) ${PHP_EXT}
}

clean() {
    apk del .build-deps
    rm -rf /tmp/* /var/tmp/*
}

download_extract_lam() {
    curl -L ${LAM_URL} -o /tmp/${LAM_PKG}
    cd /tmp
    tar xf /tmp/${LAM_PKG}
}

compile_lam() {
    [ -d ${LAM_DIR} ] || install -d ${LAM_DIR}
    local LAM=/tmp/${LAM_PKG%.tar.bz2}
    cd ${LAM}
    ./configure \
        --with-httpd-user=www-data \
        --with-httpd-group=root \
        --with-web-root=${LAM_DIR} \
        --localstatedir=${LAM_DIR}/var \
        --sysconfdir=${LAM_DIR}/etc
    make install
    cd -
    cd ${LAM_DIR}/config
    cp config.cfg.sample config.cfg
    cp unix.conf.sample lam.conf
    cd -
}

init_deps
download_extract_lam
compile_lam
clean

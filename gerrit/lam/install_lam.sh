#!/bin/sh
set -ex
export LC_ALL=C

VER=${DOCKER_LAM_VER:-6.2}
LAM_PKG=ldap-account-manager-${VER}.tar.bz2
LAM_URL=http://prdownloads.sourceforge.net/lam/${LAM_PKG}?download
LAM_DIR=${DOCKER_LAM_DIR:-"/wwwroot/lam"}

init_deps() {
    apt-get install -yqq locales tzdata
    locale-gen zh_CN.UTF-8
}

download_extract_lam() {
    curl -sSL ${LAM_URL} -o /tmp/${LAM_PKG}
    tar xf /tmp/${LAM_PKG}
}

compile_lam() {
    [ -d ${LAM_DIR} ] || install -d ${LAM_DIR}
    local LAM=${LAM_PKG%.tar.bz2}
    cd ${LAM}
    ./configure \
        --with-httpd-user=www-data \
        --with-httpd-group=root \
        --with-web-root=${LAM_DIR} \
        --localstatedir=${LAM_DIR}/var \
        --sysconfdir=${LAM_DIR}/etc
    make install
    cd -
    rm -rf ${LAM}*
    cd ${LAM_DIR}
    cp config.cfg.sample config.cfg
    unix.conf.sample lam.conf
}
#init_deps
download_extract_lam
compile_lam

exit 0

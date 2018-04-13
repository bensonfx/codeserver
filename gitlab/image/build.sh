#!/bin/sh
set -ex
export LC_ALL=C

export DEBIAN_FRONTEND=noninteractive
export GITLAB_ZH_GIT=https://gitlab.com/xhang/gitlab.git
export SSL_CERT_DIR=/etc/ssl/certs/
export GIT_SSL_CAPATH=/etc/ssl/certs/
export buildDeps='lsb-release patch nodejs python build-essential yarn cmake'

init_deps() {
    echo " # Preparing ..."
    sed -i "s@http://archive.ubuntu.com@http://mirrors.aliyun.com@g" /etc/apt/sources.list
    #apt-get update
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

    curl -sL https://deb.nodesource.com/setup_8.x | bash -
    apt-get install -yqq locales tzdata
    locale-gen en_US.UTF-8

    apt-get install -yqq $buildDeps

    rm -rf /var/lib/apt/lists/*
}

add_zh_patch() {
    echo " # Generating translation patch ..."
    cd /tmp
    git clone ${GITLAB_ZH_GIT} gitlab
    cd gitlab
    export IGNORE_DIRS=':!spec :!features :!.gitignore :!locale :!app/assets/javascripts/locale'
    git diff ${GITLAB_VERSION}..${GITLAB_ZH_VERSION} -- .  ${IGNORE_DIRS} > ../zh_CN.diff
    echo " # Patching ..."
    patch -d ${GITLAB_DIR} -p1 < ../zh_CN.diff
    echo " # Copy locale files ..."
    cp -R locale ${GITLAB_DIR}/
}

# Reference: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/config/software/gitlab-rails.rb
install_assets() {
    echo " # Regenerating the assets"
    cd ${GITLAB_DIR}
    cp config/gitlab.yml.example config/gitlab.yml
    cp config/database.yml.postgresql config/database.yml
    cp config/secrets.yml.example config/secrets.yml
    export NODE_ENV=production
    export RAILS_ENV=production
    export SETUP_DB=false
    export USE_DB=false
    export SKIP_STORAGE_VALIDATION=true
    export WEBPACK_REPORT=true
    export NO_COMPRESSION=true
    export NO_PRIVILEGE_DROP=true
    bundle exec rake gettext:pack
    bundle exec rake gettext:po_to_json
    yarn install --production --pure-lockfile
    bundle exec rake gitlab:assets:compile
}

clean_package() {
    echo " # Cleaning ..."
    yarn cache clean
    rm -rf log \
        tmp \
        config/gitlab.yml \
        config/database.yml \
        config/secrets.yml \
        .secret \
        .gitlab_shell_secret \
        .gitlab_workhorse_secret \
        node_modules
    apt-get purge -y --auto-remove \
        -o APT::AutoRemove::RecommendsImportant=false \
        -o APT::AutoRemove::SuggestsImportant=false \
        $buildDeps
    find /usr/lib/ -name __pycache__ | xargs rm -rf
    rm -rf /tmp/gitlab /tmp/*.diff /root/.cache /var/lib/apt/lists/*
}
### main function ###
init_deps
add_zh_patch
install_assets
clean_package

exit 0

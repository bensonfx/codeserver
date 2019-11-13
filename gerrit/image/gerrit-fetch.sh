#!/bin/sh

set -e
DEBIAN_FRONTEND=noninteractive
GERRIT_WAR_URL="http://repo1.maven.org/maven2/com/google/gerrit/gerrit-war/${GERRIT_VERSION}/gerrit-war-${GERRIT_VERSION}.war"
GOSU_URL="https://github.com/tianon/gosu/releases"
GOSU="/usr/bin/gosu"

#################### plugin define ####################
GERRITFORGE_URL=https://gerrit-ci.gerritforge.com
PLUGIN_ARTIFACT_URI=lastSuccessfulBuild/artifact/bazel-genfiles/plugins
GERRIT_OAUTH_URL="https://github.com/davido/gerrit-oauth-provider/releases"

plugin_list="IMPORTER EVENTSLOG LFS"
suffix=$(echo ${GERRIT_VERSION} | sed -r "s@([0-9]\.[0-9]+).*@\1@g")
default_version=bazel-stable-$suffix

IMPORTER_NAME=importer
IMPORTER_VERSION=bazel-master
EVENTSLOG_NAME=events-log
EVENTSLOG_VERSION=bazel-master
LFS_NAME=lfs

OAUTH_NAME=gerrit-oauth-provider
################## plugin define end ##################

clean() {
    echo "# cleaning tmp files ..."
    rm -rf /var/lib/apt/lists/* /tmp/*
}

init_env() {
    echo " # Preparing environment ..."
    sed -i "s@http://archive.ubuntu.com@http://mirrors.aliyun.com@g" /etc/apt/sources.list
    if ! id -u ${GERRIT_USER} >/dev/null 2>&1; then
        useradd -Ulms /sbin/nologin ${GERRIT_USER}
    fi
    #rename gerrit war to gerrit.war
    local war_file=$(ls ${GERRIT_HOME}/gerrit*.war)
    [ "$war_file" = "${GERRIT_HOME}/gerrit.war" ] || mv -f $war_file ${GERRIT_HOME}/gerrit.war

    chmod a+x ${GERRIT_HOME}/*.sh
    install -d /entrypoint-init.d
    chown -R ${GERRIT_USER} ${GERRIT_HOME}
    apt-get update
    # apt-get install -yqq --no-install-recommends openjdk-8-jdk curl git openssh-client vim
    if [ -z "$(which java)" ]; then
        apt-get install -yqq --no-install-recommends openjdk-8-jdk curl git openssh-client
    fi
    clean
}

fetch_gosu() {
    local gosu_bin="${GERRIT_HOME}/gosu*"
    if [ -f $gosu_bin ]; then
        mv -fv $gosu_bin $GOSU
        return
    fi
    local GOSU_VERSION=$(curl -ksS "${GOSU_URL}/latest" | sed -r "s@.*tag/([0-9.]+).*@\1@g")
    echo "# downloading gosu $GOSU_VERSION ..."
    local URI="download/${GOSU_VERSION}/gosu-amd64"
    curl -Lo $GOSU "${GOSU_URL}/${URI}"
    chmod a+x $GOSU
}

fetch_plugins() {
    for PLUGIN in ${plugin_list}; do
        eval local version=\${${PLUGIN}_VERSION:=$default_version}
        eval local name=\${${PLUGIN}_NAME}
        local plugin_url=${GERRITFORGE_URL}/job/plugin-${name}-${version}/${PLUGIN_ARTIFACT_URI}/${name}/${name}.jar

        [ -f "${GERRIT_HOME}/${name}.jar" ] && continue
        echo "downloading plugin: ${name}"
        set -x
        curl -L ${plugin_url} -o ${GERRIT_HOME}/${name}.jar
        set +x
    done

    # local GERRIT_OAUTH_PLUGIN=$(curl -ksSL ${GERRIT_OAUTH_URL} | grep -oE "download/v[0-9.]+/${OAUTH_NAME}.jar"| head -n 1)
    # curl -L \
    #     ${GERRIT_OAUTH_URL}/${GERRIT_OAUTH_PLUGIN} -o ${GERRIT_HOME}/${OAUTH_NAME}.jar
}

fetch_gerrit_war() {
    if [ ! -f "${GERRIT_WAR}" ]; then
        echo "# downloading $(basename ${GERRIT_WAR}) ${GERRIT_VERSION} ..."
        curl -L ${GERRIT_WAR_URL} -o ${GERRIT_WAR}
    fi
    fetch_gosu
}

case $1 in
init)
    init_env
    ;;
gerrit)
    fetch_gerrit_war
    ;;
plugins)
    fetch_plugins
    ;;
*)
    init_env
    fetch_gerrit_war
    fetch_plugins
    ;;
esac

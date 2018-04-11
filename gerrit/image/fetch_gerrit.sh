#!/bin/sh

set -ex
DEBIAN_FRONTEND=noninteractive
GERRIT_WAR_URL="http://repo1.maven.org/maven2/com/google/gerrit/gerrit-war/${GERRIT_VERSION}/gerrit-war-${GERRIT_VERSION}.war"

GERRIT_OAUTH_URL="https://github.com/davido/gerrit-oauth-provider/releases"
GOSU_URL="https://github.com/tianon/gosu/releases"

GERRITFORGE_URL=https://gerrit-ci.gerritforge.com
PLUGIN_ARTIFACT_DIR=lastSuccessfulBuild/artifact/bazel-genfiles/plugins

#################### plugin define ####################
plugin_list="IMPORTER GITILES DELPROJ EVENTSLOG LFS"

IMPORTER_NAME=importer
IMPORTER_VERSION=bazel-master

GITILES_NAME=gitiles
GITILES_VERSION=stable-2.15

DELPROJ_NAME=delete-project
DELPROJ_VERSION=bazel-stable-2.15

EVENTSLOG_NAME=events-log
EVENTSLOG_VERSION=bazel-master

LFS_NAME=lfs
LFS_VERSION=bazel-master
################## plugin define end ##################

clean() {
    rm -rf /var/lib/apt/lists/* /tmp/*
}

init_env() {
    echo " # Preparing ..."
    sed -i "s@http://archive.ubuntu.com@http://mirrors.aliyun.com@g" /etc/apt/sources.list
    useradd -Ulms /sbin/nologin ${GERRIT_USER}
    chmod a+x ${GERRIT_HOME}/*.sh
    mkdir /entrypoint-init.d
    chown -R ${GERRIT_USER} ${GERRIT_HOME}
    apt-get update
    # apt-get install -yqq --no-install-recommends openjdk-8-jdk curl git openssh-client vim
    apt-get install -yqq openjdk-8-jdk curl git openssh-client
    clean
}

fetch_gosu() {
    local GOSU_QUERY=$(curl -ksSL ${GOSU_URL} | grep -oE "download/[0-9.]+/gosu-amd64"| head -n1)

    local GOSU="/usr/bin/gosu"
    curl -Lo $GOSU "${GOSU_URL}/${GOSU_QUERY}"
    chmod a+x $GOSU
}

fetch_plugins() {
    for PLUGIN in ${plugin_list};do
        eval echo "downloading plugin:\$${PLUGIN}_NAME"
        eval curl -L ${GERRITFORGE_URL}/job/plugin-\${${PLUGIN}_NAME}-\${${PLUGIN}_VERSION}/${PLUGIN_ARTIFACT_DIR}/\${${PLUGIN}_NAME}/\${${PLUGIN}_NAME}.jar \
            -o ${GERRIT_HOME}/\${${PLUGIN}_NAME}.jar
    done

    # local GERRIT_OAUTH_PLUGIN=$(curl -ksSL ${GERRIT_OAUTH_URL} | grep -oE "download/v[0-9.]+/gerrit-oauth-provider.jar"| head -n 1)
    # curl -L \
    #     ${GERRIT_OAUTH_URL}/${GERRIT_OAUTH_PLUGIN} -o ${GERRIT_HOME}/gerrit-oauth-provider.jar
}

fetch_gerrit_war() {
    init_env
    curl -L ${GERRIT_WAR_URL} -o ${GERRIT_WAR}
    #fetch_gosu
}

case $1 in

    gerrit)
        fetch_gerrit_war;;
    plugins)
        fetch_plugins;;
    *)
        fetch_gerrit_war
        fetch_plugins
        ;;
esac

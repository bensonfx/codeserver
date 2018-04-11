#!/bin/sh

set -ex
DEBIAN_FRONTEND=noninteractive
GERRIT_WAR_URL="http://repo1.maven.org/maven2/com/google/gerrit/gerrit-war/${GERRIT_VERSION}/gerrit-war-${GERRIT_VERSION}.war"
GOSU_URL="https://github.com/tianon/gosu/releases"

#################### plugin define ####################
GERRITFORGE_URL=https://gerrit-ci.gerritforge.com
PLUGIN_ARTIFACT_URI=lastSuccessfulBuild/artifact/bazel-genfiles/plugins
GERRIT_OAUTH_URL="https://github.com/davido/gerrit-oauth-provider/releases"

plugin_list="IMPORTER GITILES DELPROJ EVENTSLOG LFS"
suffix=$(echo ${GERRIT_VERSION} | sed -r "s@([0-9]\.[0-9]+).*@\1@g")

IMPORTER_NAME=importer
GITILES_NAME=gitiles
DELPROJ_NAME=delete-project
EVENTSLOG_NAME=events-log
LFS_NAME=lfs

OAUTH_NAME=gerrit-oauth-provider
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
        eval local version=\${${PLUGIN}_VERSION:=bazel-stable-$suffix}
        eval local name=\${${PLUGIN}_NAME}
        local plugin_url=${GERRITFORGE_URL}/job/plugin-${name}-${version}/${PLUGIN_ARTIFACT_URI}/${name}/${name}.jar

        echo "downloading plugin:${name}"
        curl -L ${plugin_url} -o ${GERRIT_HOME}/${name}.jar
    done

    # local GERRIT_OAUTH_PLUGIN=$(curl -ksSL ${GERRIT_OAUTH_URL} | grep -oE "download/v[0-9.]+/${OAUTH_NAME}.jar"| head -n 1)
    # curl -L \
    #     ${GERRIT_OAUTH_URL}/${GERRIT_OAUTH_PLUGIN} -o ${GERRIT_HOME}/${OAUTH_NAME}.jar
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

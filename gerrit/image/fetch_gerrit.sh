#!/bin/sh

set -ex
DEBIAN_FRONTEND=noninteractive
GERRITFORGE_URL=https://gerrit-ci.gerritforge.com
GERRITFORGE_ARTIFACT_DIR=lastSuccessfulBuild/artifact/bazel-genfiles/plugins
IMPORTER_PLUGIN_VERSION=bazel-master
GITILES_PLUGIN_VERSION=bazel-master-stable-2.15
DELPROJ_PLUGIN_VERSION=bazel-stable-2.15
EVENTSLOG_PLUGIN_VERSION=bazel-master

GERRIT_OAUTH_URL="https://github.com/davido/gerrit-oauth-provider/releases"
GERRIT_OAUTH_PLUGIN=$(curl -ksSL ${GERRIT_OAUTH_URL} | grep -oE "download/v[0-9.]+/gerrit-oauth-provider.jar"| head -n 1)

fetch_plugins() {
    curl -fSsL \
        ${GERRITFORGE_URL}/job/plugin-delete-project-${DELPROJ_PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/delete-project/delete-project.jar \
        -o ${GERRIT_HOME}/delete-project.jar
    curl -fSsL \
        ${GERRITFORGE_URL}/job/plugin-events-log-${EVENTSLOG_PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/events-log/events-log.jar \
        -o ${GERRIT_HOME}/events-log.jar
    curl -fSsL \
        ${GERRITFORGE_URL}/job/plugin-gitiles-${GITILES_PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/gitiles/gitiles.jar \
        -o ${GERRIT_HOME}/gitiles.jar
    curl -fSsL \
        ${GERRITFORGE_URL}/job/plugin-importer-${IMPORTER_PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/importer/importer.jar \
        -o ${GERRIT_HOME}/importer.jar
    curl -fSsL \
        ${GERRIT_OAUTH_URL}/${GERRIT_OAUTH_PLUGIN} -o ${GERRIT_HOME}/gerrit-oauth-provider.jar
}

fetch_gerrit_war() {
    curl -fsSL http://repo1.maven.org/maven2/com/google/gerrit/gerrit-war/${GERRIT_VERSION}/gerrit-war-${GERRIT_VERSION}.war \
        -o ${GERRIT_WAR}
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

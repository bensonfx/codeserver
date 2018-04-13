#!/bin/sh

set -ex
DEBIAN_FRONTEND=noninteractive
GERRITFORGE_URL=https://gerrit-ci.gerritforge.com
GERRITFORGE_ARTIFACT_DIR=lastSuccessfulBuild/artifact/bazel-genfiles/plugins
IMPORTER_PLUGIN_VERSION=bazel-master
GITILES_PLUGIN_VERSION=bazel-master-stable-2.15
DELPROJ_PLUGIN_VERSION=bazel-stable-2.15
EVENTSLOG_PLUGIN_VERSION=bazel-master
GERRIT_OAUTH_VERSION=2.14.3

pull_plugins() {
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
        https://github.com/davido/gerrit-oauth-provider/releases/download/v${GERRIT_OAUTH_VERSION}/gerrit-oauth-provider.jar \
        -o ${GERRIT_HOME}/gerrit-oauth-provider.jar
}

pull_gerrit_war() {
    curl -fsSL http://repo1.maven.org/maven2/com/google/gerrit/gerrit-war/${GERRIT_VERSION}/gerrit-war-${GERRIT_VERSION}.war \
        -o ${GERRIT_WAR}
}

case $1 in
    gerrit)
        pull_gerrit_war;;
    plugins)
        pull_plugins;;
    *)
        pull_gerrit_war
        pull_plugins
        ;;
esac

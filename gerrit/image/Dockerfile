FROM ubuntu:20.04

LABEL maintainer="Benson Yan <fuxin04@gmail.com>"

# Overridable defaults
ENV GERRIT_HOME=/var/gerrit \
    GERRIT_VERSION=3.3.2 \
    GERRIT_USER=gerrit \
    GERRIT_WAR=/tmp/gerrit.war

# Ensure the entrypoint scripts are in a fixed location
COPY plugins/*.jar bin/gerrit*.war /tmp/
COPY gerrit-*.sh bin/gosu* /usr/local/bin/
#&& curl -fSsL https://gerrit-releases.storage.googleapis.com/gerrit-${GERRIT_VERSION}.war -o ${TMP_GERRIT_WAR} \
RUN set -ex && gerrit-fetch.sh

EXPOSE 8080 29418
WORKDIR ${GERRIT_HOME}
VOLUME ["${GERRIT_HOME}/git", "${GERRIT_HOME}/index", "${GERRIT_HOME}/cache", "${GERRIT_HOME}/db", "${GERRIT_HOME}/etc"]

HEALTHCHECK CMD [ -n "$(ps -ef |grep -v grep| grep GerritCodeReview)" ] || exit 1

CMD gerrit-start.sh

FROM ubuntu:16.04

MAINTAINER Benson Yan <fuxin04@gmail.com>

# Overridable defaults
ENV GERRIT_HOME=/var/gerrit \
    GERRIT_VERSION=2.15.1 \
    GERRIT_USER=gerrit

ENV GERRIT_SITE=${GERRIT_HOME}/review_site \
    GERRIT_WAR=${GERRIT_HOME}/gerrit.war

# Ensure the entrypoint scripts are in a fixed location
COPY gerrit-start.sh fetch_gerrit.sh ${GERRIT_HOME}/
COPY gosu /usr/bin/
#&& curl -fSsL https://gerrit-releases.storage.googleapis.com/gerrit-${GERRIT_VERSION}.war -o ${TMP_GERRIT_WAR} \
RUN set -xe && ${GERRIT_HOME}/fetch_gerrit.sh

EXPOSE 8080 29418

VOLUME ${GERRIT_SITE}

HEALTHCHECK CMD [ -n "$(ps -ef |grep -v grep| grep GerritCodeReview)" ] || exit 1

CMD ${GERRIT_HOME}/gerrit-start.sh

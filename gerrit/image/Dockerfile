FROM ubuntu:16.04

MAINTAINER Benson Yan <fuxin04@gmail.com>

# Overridable defaults
ENV GERRIT_HOME=/var/gerrit \
    GERRIT_VERSION=2.15-rc2 \
    GERRIT_USER=gerrit

ENV GERRIT_SITE=${GERRIT_HOME}/review_site \
    GERRIT_WAR=${GERRIT_HOME}/gerrit.war

# Ensure the entrypoint scripts are in a fixed location
COPY gerrit-start.sh fetch_gerrit.sh ${GERRIT_HOME}/
COPY gosu /usr/bin/
#&& curl -fSsL https://gerrit-releases.storage.googleapis.com/gerrit-${GERRIT_VERSION}.war -o ${TMP_GERRIT_WAR} \
RUN set -xe \
    && echo " # Preparing ..." \
    # && sed -i "s@http://archive.ubuntu.com@http://cn.archive.ubuntu.com@g" /etc/apt/sources.list \
    && sed -i "s@http://archive.ubuntu.com@http://mirrors.aliyun.com@g" /etc/apt/sources.list \
    && useradd -Ulms /sbin/nologin ${GERRIT_USER} \
    && chmod a+x ${GERRIT_HOME}/*.sh \
    && mkdir /entrypoint-init.d \
    && chown -R ${GERRIT_USER} ${GERRIT_HOME} \
    && apt-get update \
    # && apt-get install -yqq --no-install-recommends openjdk-8-jdk curl git openssh-client vim \
    && apt-get install -yqq openjdk-8-jdk curl git openssh-client vim \
    && ${GERRIT_HOME}/fetch_gerrit.sh \
    && rm -rf /var/lib/apt/lists/* /tmp/*

EXPOSE 8080 29418

VOLUME ${GERRIT_SITE}

HEALTHCHECK CMD [ -n "$(ps -ef |grep -v grep| grep GerritCodeReview)" ] || exit 1

CMD ${GERRIT_HOME}/gerrit-start.sh

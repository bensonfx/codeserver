FROM gitlab/gitlab-ce:11.0.1-ce.0

ENV GITLAB_VERSION=11.0.1
ARG BUILD_SCRIPT=build.sh

COPY ${BUILD_SCRIPT} patch_${GITLAB_VERSION}_zh_CN.diff /tmp/

ENV GITLAB_ZH_VERSION=${GITLAB_VERSION}-zh \
    LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8 \
    TZ=Asia/Shanghai \
    GITLAB_DIR=/opt/gitlab/embedded/service/gitlab-rails

RUN /tmp/${BUILD_SCRIPT};rm -f /tmp/${BUILD_SCRIPT}

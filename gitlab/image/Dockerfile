#####################
#  Building Stage   #
#####################
FROM gitlab/gitlab-ce:11.6.3-ce.0 as builder

ENV GITLAB_VERSION=11.6.3
ARG BUILD_SCRIPT=build.sh

COPY ${BUILD_SCRIPT} patch_${GITLAB_VERSION}_zh_CN.diff *.tgz /tmp/

ENV GITLAB_ZH_VERSION=${GITLAB_VERSION}-zh \
    LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8 \
    TZ=Asia/Shanghai \
    GITLAB_DIR=/opt/gitlab/embedded/service/gitlab-rails

RUN /tmp/${BUILD_SCRIPT};rm -f /tmp/${BUILD_SCRIPT}

######################
#  Production Stage  #
######################
FROM gitlab/gitlab-ce:11.6.3-ce.0 as production

RUN set -xe \
    && export DEBIAN_FRONTEND=noninteractive \
    && sed -i "s@http://archive.ubuntu.com@http://mirrors.aliyun.com@g" /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -yqq locales tzdata \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8 TZ=Asia/Shanghai
ENV GITLAB_VERSION=11.6.3 GITLAB_DIR=/opt/gitlab/embedded/service/gitlab-rails

COPY --from=builder ${GITLAB_DIR}/app                   ${GITLAB_DIR}/app
COPY --from=builder ${GITLAB_DIR}/public                ${GITLAB_DIR}/public
COPY --from=builder ${GITLAB_DIR}/config/application.rb ${GITLAB_DIR}/config/application.rb
COPY --from=builder ${GITLAB_DIR}/config/initializers   ${GITLAB_DIR}/config/initializers
COPY --from=builder ${GITLAB_DIR}/config/locales        ${GITLAB_DIR}/config/locales
COPY --from=builder ${GITLAB_DIR}/lib/gitlab            ${GITLAB_DIR}/lib/gitlab
COPY --from=builder ${GITLAB_DIR}/locale                ${GITLAB_DIR}/locale


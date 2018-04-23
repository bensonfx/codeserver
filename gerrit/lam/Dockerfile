FROM php:7.2-fpm-alpine

COPY install_lam.sh /tmp

# ENV LANG=zh_CN.UTF-8 \
#     LANGUAGE=zh_CN:en_US:en \
ENV TZ=Asia/Shanghai

RUN  /tmp/install_lam.sh

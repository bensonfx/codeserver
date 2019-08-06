FROM alpine

LABEL AUTHOR="Benson Yan<fuxin04@gmail.com>"

WORKDIR /root

ARG ARIANG_URL="https://github.com/mayswind/AriaNg/releases"
ENV RPC_SECRET=Hello ENABLE_AUTH=false DOMAIN=0.0.0.0:80 ARIA2_USER=user ARIA2_PWD=password

ADD conf /root/conf
COPY aria2c.sh /root
COPY Caddyfile /usr/local/caddy/

RUN set -ex \
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
    && apk add --no-cache wget bash curl openrc gnupg screen aria2 tar \
    && curl https://getcaddy.com | bash -s personal http.realip \
    && export ARIANG_VERSION=$(curl ${ARIANG_URL}/latest -si | grep 'Location:' | grep -oE "[0-9]{1,2}[0-9.]+") \
    && aria2_path=/usr/local/www/aria2 \
    && install -d ${aria2_path} ${aria2_path}/Download \
    && cd ${aria2_path} \
    && chmod +rw /root/conf/aria2.session \
    && curl -kL ${ARIANG_URL}/download/${ARIANG_VERSION}/AriaNg-${ARIANG_VERSION}.zip -o /root/AriaNg-${ARIANG_VERSION}.zip

#The folder to store ssl keys
VOLUME /root/conf/ssl
# User downloaded files
VOLUME /data

EXPOSE 6800 80

CMD ["/bin/sh", "/root/aria2c.sh" ]



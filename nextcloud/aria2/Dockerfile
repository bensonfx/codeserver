FROM alpine

LABEL AUTHOR="Benson Yan<fuxin04@gmail.com>"

WORKDIR /root

ENV RPC_SECRET=Hello ENABLE_AUTH=false DOMAIN=0.0.0.0:80 ARIA2_USER=user ARIA2_PWD=password
ENV ARIANG_VERSION=1.0.1

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
    && apk add --no-cache wget bash curl openrc gnupg screen aria2 tar

RUN curl https://getcaddy.com | bash -s personal http.realip

ADD conf /root/conf
COPY aria2c.sh /root

COPY Caddyfile SecureCaddyfile /usr/local/caddy/

#AriaNg
RUN aria2_path=/usr/local/www/aria2 \
    && install -d ${aria2_path} ${aria2_path}/Download \
    && cd ${aria2_path} \
    && chmod +rw /root/conf/aria2.session \
    && curl -kL https://github.com/mayswind/AriaNg/releases/download/${ARIANG_VERSION}/AriaNg-${ARIANG_VERSION}.zip -o /root/AriaNg-${ARIANG_VERSION}.zip

#The folder to store ssl keys
VOLUME /root/conf/key
# User downloaded files
VOLUME /data

EXPOSE 6800 80 443

CMD ["/bin/sh", "/root/aria2c.sh" ]



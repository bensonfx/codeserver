FROM node:10.0.0-slim

MAINTAINER soulteary <soulteary@gmail.com>

ADD . /app

WORKDIR /app

RUN npm install

CMD [ "/app/bin/minify", "--use-config", "true" ]

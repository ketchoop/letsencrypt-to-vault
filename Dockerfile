FROM certbot/certbot

RUN apk update && apk add bash

ADD ./letsencrypt-to-vault /usr/bin

EXPOSE 80 443

ENTRYPOINT [ "letsencrypt-to-vault" ]

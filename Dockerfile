FROM certbot/certbot

RUN mkdir /certs-dir && apk update && apk add bash curl

ADD ./letsencrypt-to-vault /usr/bin

EXPOSE 80 443

VOLUME /certs-dir

ENTRYPOINT [ "letsencrypt-to-vault" ]

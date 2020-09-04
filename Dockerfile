FROM openresty/openresty:alpine-fat

RUN apk add openssl curl

RUN mkdir /etc/resty-auto-ssl \
    && addgroup -S nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
    && chown nginx /etc/resty-auto-ssl

RUN mkdir -p /etc/letsencrypt &&\
    mkdir -p /etc/easx/ssl &&\
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj '/CN=sni-support-required-for-valid-ssl' \
        -keyout /etc/easx/ssl/default.key \
        -out /etc/easx/ssl/default.crt

# Install dockerize binary, for templated configs
# https://github.com/jwilder/dockerize
ENV DOCKERIZE_VERSION=v0.6.1
RUN curl -fSslL https://github.com/jwilder/dockerize/releases/download/${DOCKERIZE_VERSION}/dockerize-linux-amd64-${DOCKERIZE_VERSION}.tar.gz | \
    tar xzv -C /usr/local/bin/

RUN apk add diffutils gcc make

# Install lua-resty-auto-ssl for dynamically generating certificates from LE
# https://github.com/auto-ssl/lua-resty-auto-ssl
RUN luarocks install lua-resty-auto-ssl 0.13.1

RUN rm -f /usr/local/openresty/nginx/conf/*

COPY ./nginx/conf /usr/local/openresty/nginx/conf
COPY ./nginx/lualib /usr/local/openresty/nginx/lualib
COPY ./nginx/static /etc/easx/static

# Add the entrypoint script
COPY ./nginx/bin/entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

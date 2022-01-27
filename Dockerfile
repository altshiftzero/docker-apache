FROM alpine:3.15

EXPOSE 80/tcp \
       443/tcp

HEALTHCHECK --interval=5m --timeout=30s --retries=3 \
            CMD curl -A "Container/Healthcheck" -f http://localhost/ || exit 1

ENV SITEDOMAIN=localhost \
    SSL_SECURITY=SSL_HARD \
    SSL_STATUS=SSL_ENABLED \
    TIMEZONE=Europe/Amsterdam

RUN apk update && apk upgrade && \
    apk add --no-cache apache2 apache2-http2 apache2-ssl \
                       openssl openssl-dev openssh-keygen \
                       curl ca-certificates \
                       git gnupg

COPY config/httpd.conf /etc/apache2/httpd.conf
COPY scripts/create_certificate.sh /opt/create_certificate.sh
COPY scripts/server.sh /opt/server.sh

RUN ln -sf /dev/stdout /var/log/apache2/access.log && \
    ln -sf /dev/stderr /var/log/apache2/error.log && \
    rm -f /etc/apache2/conf.d/* && \
    mkdir /etc/ssl/ca && mkdir /var/www/html && \
    sed -i 's/.\/demoCA/\/etc\/ssl/g' /etc/ssl/openssl.cnf && \
    sed -i 's/newcerts/certs/g' /etc/ssl/openssl.cnf && \
    sed -i 's/cacert.pem/ca\/ca.crt/g' /etc/ssl/openssl.cnf && \
    sed -i 's/private\/cakey.pem/ca\/ca.key/g' /etc/ssl/openssl.cnf && \
    touch /etc/ssl/index.txt && \
    chown apache:apache /var/www/html && \
    chmod +x /opt/server.sh /opt/create_certificate.sh

WORKDIR /opt
ENTRYPOINT ["sh","server.sh"]

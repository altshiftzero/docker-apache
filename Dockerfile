FROM alpine:3.16

EXPOSE 80/tcp \
       443/tcp

HEALTHCHECK --interval=5m --timeout=30s --retries=3 \
            CMD curl -A "Container/Healthcheck" -f http://localhost/ || exit 1

ENV SITEDOMAIN=localhost \
    SSL_SECURITY=SSL_HARD \
    SSL_STATUS=SSL_ENABLED \
    SSL_DIR=/etc/ssl \
    SSL_DIR_ESCAPED="\/etc\/ssl1" \
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
    mkdir ${SSL_DIR}/ca && mkdir /var/www/html && \
    sed -i 's/.\/demoCA/'${SSL_DIR_ESCAPED}'/g' ${SSL_DIR}/openssl.cnf && \
    sed -i 's/.\/etc\/ssl\//'${SSL_DIR_ESCAPED}'/g' ${SSL_DIR}/openssl.cnf && \
    sed -i 's/newcerts/certs/g' ${SSL_DIR}/openssl.cnf && \
    sed -i 's/cacert.pem/ca\/ca.crt/g' ${SSL_DIR}/openssl.cnf && \
    sed -i 's/private\/cakey.pem/ca\/ca.key/g' ${SSL_DIR}/openssl.cnf && \
    touch ${SSL_DIR}/index.txt && \
    chown apache:apache /var/www/html && \
    chmod +x /opt/server.sh /opt/create_certificate.sh

WORKDIR /opt
ENTRYPOINT ["sh","server.sh"]

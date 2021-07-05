#!/bin/sh
DOMAIN=$1
if [[ ! -e "/root/.ssh/id_rsa" && "${DOMAIN}" == "${SITEDOMAIN}" ]]; then
  ssh-keygen -t rsa -b 4096 \
             -C "docker-container-$(hostname)@${SITEDOMAIN}" \
             -f ~/.ssh/id_rsa -N ""
fi
if [[ ! -e "/etc/ssl/ca/ca.key" || ! -e "/etc/ssl/ca/ca.crt" ]]; then
  openssl req -x509 -sha256 -nodes -newkey rsa:4096 -days 1825  \
           -keyout /etc/ssl/ca/ca.key -out /etc/ssl/ca/ca.crt    \
           -subj "/C=US/ST=NA/L=NA/O=Docker Container $(hostname)/OU=IT Department/CN=Docker Container $(hostname)"
  echo '01' > /etc/ssl/serial
fi
if [[ ! -e "/etc/ssl/private/${DOMAIN}.key" && -e "/etc/ssl/ca/ca.crt" ]]; then
  WILDCARD=""
  if [[ "${SSL_WILDCARD}" == "TRUE" ]]; then
    WILDCARD=",DNS:*."${DOMAIN}
  fi
  if [[ ! -e "/etc/ssl/private/${DOMAIN}.key" && ! -e "/etc/ssl/${DOMAIN}.csr" ]]; then
    openssl req \
      -nodes -newkey rsa:4096 \
      -keyout /etc/ssl/private/${DOMAIN}.key \
      -out /etc/ssl/${DOMAIN}.csr \
      -addext "subjectAltName=DNS:${DOMAIN},DNS:www.${DOMAIN}${WILDCARD}" \
      -subj "/C=US/ST=NA/L=NA/O=Docker Container $(hostname)/OU=IT Department/CN="${DOMAIN}
    openssl ca -batch -out /etc/ssl/certs/${DOMAIN}.cer -infiles /etc/ssl/${DOMAIN}.csr
  fi
fi

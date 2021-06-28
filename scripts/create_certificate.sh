#!/bin/bash
SITEDOMAIN=$1
if [[ ! -e "/root/.ssh/id_rsa" ]]; then
  ssh-keygen -t rsa -b 4096 \
             -C "docker-container-$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)@${SITEDOMAIN}" \
             -f ~/.ssh/id_rsa -N ""
fi
if [[ ! -e "/etc/ssl/private/${SITEDOMAIN}.key" ]]; then
  openssl req -x509 -sha256 -nodes -newkey rsa:4096 -days 1825  \
           -keyout /etc/ssl/ca/ca.key -out /etc/ssl/ca/ca.crt    \
           -subj "/C=US/ST=NA/L=NA/O=Global Security/OU=IT Department/CN=Docker"
  openssl x509 -noout -serial -in /etc/ssl/ca/ca.crt | cut -d'=' -f2 > /etc/ssl/serial
  openssl req \
    -nodes -newkey rsa:4096 \
    -keyout /etc/ssl/private/${SITEDOMAIN}.key \
    -out /etc/ssl/${SITEDOMAIN}.csr \
    -addext "subjectAltName=DNS:${SITEDOMAIN},DNS:www.${SITEDOMAIN}" \
    -subj "/C=US/ST=NA/L=NA/O=Global Security/OU=IT Department/CN="${SITEDOMAIN}
  openssl ca -batch -out /etc/ssl/certs/${SITEDOMAIN}.cer -infiles /etc/ssl/${SITEDOMAIN}.csr
fi

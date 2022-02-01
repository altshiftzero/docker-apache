#!/bin/sh
DOMAIN=$1
if [[ ! -e "/root/.ssh/id_rsa" && "${DOMAIN}" == "${SITEDOMAIN}" ]]; then
  ssh-keygen -t rsa -b 4096 \
             -C "docker-container-$(hostname)@${SITEDOMAIN}" \
             -f ~/.ssh/id_rsa -N ""
fi
if [[ ! -e "${SSL_DIR}/ca/ca.key" || ! -e "${SSL_DIR}/ca/ca.crt" ]]; then
  openssl req -x509 -sha256 -nodes -newkey rsa:4096 -days 1825  \
           -keyout ${SSL_DIR}/ca/ca.key -out ${SSL_DIR}/ca/ca.crt    \
           -subj "/C=US/ST=NA/L=NA/O=Docker Container $(hostname)/OU=IT Department/CN=Docker Container $(hostname)"
  echo '01' > ${SSL_DIR}/serial
fi
if [[ ! -e "${SSL_DIR}/private/${DOMAIN}.key" && -e "${SSL_DIR}/ca/ca.crt" ]]; then
  WILDCARD=""
  if [[ "${SSL_WILDCARD}" == "TRUE" ]]; then
    WILDCARD=",DNS:*."${DOMAIN}
  fi
  if [[ ! -e "${SSL_DIR}/private/${DOMAIN}.key" && ! -e "${SSL_DIR}/${DOMAIN}.csr" ]]; then
    openssl req \
      -nodes -newkey rsa:4096 \
      -keyout ${SSL_DIR}/private/${DOMAIN}.key \
      -out ${SSL_DIR}/${DOMAIN}.csr \
      -addext "subjectAltName=DNS:${DOMAIN},DNS:www.${DOMAIN}${WILDCARD}" \
      -subj "/C=US/ST=NA/L=NA/O=Docker Container $(hostname)/OU=IT Department/CN="${DOMAIN}
    openssl ca -batch -out /etc/ssl/certs/${DOMAIN}.cer -infiles ${SSL_DIR}/${DOMAIN}.csr
  fi
fi

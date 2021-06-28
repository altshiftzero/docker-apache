#!/bin/bash

sh create_certificate.sh ${SITEDOMAIN};
clear
echo "SSH Public Key:"
echo "================================"
cat ~/.ssh/id_rsa.pub
echo "================================"
echo "Server will run for domain ${SITEDOMAIN} with SSL status ${SSL_STATUS}."
echo "The chosen security level is ${SSL_SECURITY}"

ln -fs /usr/share/zoneinfo/${TIMEZONE} /etc/localtime

cd /var/www/html
if [[ ${GIT_REPO} ]]; then
  ssh-keyscan $(echo ${GIT_REPO} | cut -d'@' -f2 | cut -d':' -f1) > githostkey
  echo "Using this key as trusted for $(echo ${GIT_REPO} | cut -d'@' -f2 | cut -d':' -f1)"
  echo "================================"
  cat githostkey
  echo "================================"
  cat githostkey >> /root/.ssh/known_hosts
  rm githostkey
  if [[ ! -d .git ]]; then
    git clone ${GIT_REPO} /var/www/html
  fi
  if [[ $(git remote get-url origin) != ${GIT_REPO} ]]; then
    git remote set-url origin ${GIT_REPO}
  fi
  git checkout origin ${GIT_BRANCH}
fi
/usr/sbin/httpd -D ${SSL_SECURITY} -D ${SSL_STATUS} -D FOREGROUND;

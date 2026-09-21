#!/usr/bin/env bash

set -euo pipefail

# renovate: datasource=github-tags depName=nginx/nginx extractVersion=^release-(?<version>.+)$
NGINX_VERSION="1.31.6"
NGINX_RPM_FILE_NAME="nginx.rpm"
buildah config --env "NGINX_VERSION=${NGINX_VERSION}" "${BASE_CONTAINER}"

curl --fail --show-error --location --proto '=https' --tlsv1.2 --retry 3 \
  --output "${CONTAINER_MOUNT}/tmp/${NGINX_RPM_FILE_NAME}" \
  "https://nginx.org/packages/mainline/rhel/9/x86_64/RPMS/nginx-${NGINX_VERSION}-1.el9.ngx.x86_64.rpm"
run_in_container_mount "rpm -Uvh --excludedocs /tmp/${NGINX_RPM_FILE_NAME}"
rm -f "${CONTAINER_MOUNT}/tmp/${NGINX_RPM_FILE_NAME}"

run_in_container_mount "
  chgrp -R 0 '/var/log/nginx' '/var/cache/nginx' '/var/run'
  chmod -R g=u '/var/log/nginx' '/var/cache/nginx' '/var/run'
  chown -R 10001:10001 '/var/log/nginx' '/var/cache/nginx' '/var/run'
  sed -i '/^user\\s*nginx;$/d' '/etc/nginx/nginx.conf'
  rm -f '/etc/nginx/conf.d/default.conf'
  ln -sf /dev/stdout /var/log/nginx/access.log
  ln -sf /dev/stderr /var/log/nginx/error.log
"

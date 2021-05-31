#!/bin/bash
set -e

#
# If we're starting web-server we need to do following:
#   1) Modify docker-php-ext-xdebug.ini file to contain correct remote host
#      value, note that for mac we need to use another value within this. Also
#      we want to export host IP so that we can use that within `check.php` to
#      check that current environment is compatible with Symfony.
#   2) Install all dependencies
#

# Step 1
if [[ -z "${DOCKER_WITH_MAC}" ]]; then
  # Not Mac, so determine actual docker container IP address
  HOST=`/sbin/ip route|awk '/default/ { print $3 }'`
else
  # Otherwise use special value, which works wit Mac
  HOST="docker.for.mac.localhost"
fi

sed -i "s/xdebug\.remote_host \=.*/xdebug\.remote_host\=$HOST/g" /usr/local/etc/php/php.ini

export DOCKER_IP=`/sbin/ip route|awk '/default/ { print $3 }'`

# Step 2
COMPOSER_MEMORY_LIMIT=-1 composer install

exec "$@"

#! /bin/bash

set -ex

if [ $EASX_DEBUG == "true" ]
  then
    export EASX_LOG_LEVEL=debug
  else
    export EASX_LOG_LEVEL=info
fi

# Use Dockerize for templates
/usr/local/bin/dockerize \
    ${EASX_DOCKERIZE_EXTRA_ARGS} \
    -template /usr/local/openresty/nginx/conf/nginx.conf.tmpl:/usr/local/openresty/nginx/conf/nginx.conf \
    -template  /usr/local/openresty/nginx/conf/easx.conf.tmpl:/usr/local/openresty/nginx/conf/easx.conf

# Execute subcommand
exec "$@"

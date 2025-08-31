#!/bin/sh
set -e

# Substitute env vars in nginx.conf template
envsubst '${SERVER_NAME} ${BACKEND_HOST} ${BACKEND_PORT}' \
    < nginx.conf.template \
    > /etc/nginx/conf.d/default.conf

echo
echo "###################################"
echo "######## Nginx Config File ########"
echo "###################################"

cat /etc/nginx/conf.d/default.conf

echo "###################################"
echo "############### End ###############"
echo "###################################"
echo 
echo "Starting Nginx with SERVER_NAME=$SERVER_NAME BACKEND_HOST=$BACKEND_HOST BACKEND_PORT=$BACKEND_PORT"
echo "##################################################################"
exec nginx -g 'daemon off;'

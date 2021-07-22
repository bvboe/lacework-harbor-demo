#!/bin/bash

if [ $# -ne 2 ]
  then
    echo "Usage: install.sh <account_name> <integration_access_token>"
    exit 1
fi

cat config-template.yml | \
    sed "s|account_name: <account_name>|account_name: $1|" | \
    sed "s|integration_access_token: <integration_access_token>|integration_access_token: $2|" > config.yml

curl -LO https://github.com/bitnami/bitnami-docker-harbor-portal/archive/master.tar.gz
tar xf master.tar.gz
cd bitnami-docker-harbor-portal-master
mv docker-compose.yml org-docker-compose.yml
cat org-docker-compose.yml | sed 's|EXT_ENDPOINT=http://reg.mydomain.com|EXT_ENDPOINT=http://kubernetes.docker.internal|' > docker-compose.yml
docker-compose up -d
cd ..

docker run -d --network=bitnami-docker-harbor-portal-master_default --network-alias lacework-proxy-scanner --name lacework-proxy-scanner \
  --mount type=bind,source=/tmp,target=/opt/lacework/cache  \
  -v `pwd`/config.yml:/opt/lacework/config/config.yml \
  -v `pwd`/notifications.yml:/opt/lacework/config/notifications.yml \
  -e LOG_LEVEL=debug -p 8080:8080 lacework/lacework-proxy-scanner

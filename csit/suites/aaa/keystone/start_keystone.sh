#/bin/bash

set -x

docker pull clearlinux/keystone

# set a couple of useful env. vars
YOUR_HOST=`hostname -f`
MYSQL_DATA_DIR=/var/lib/mysql/
echo "$YOUR_HOST"
# generate certificates
echo "START Artifact Generation"
CERT_PATH=`pwd`
CERT_NAME=keystone_cert
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout keystone_key.pem \
    -out $CERT_NAME.pem -subj "/CN=$YOUR_HOST"
 
echo "END Artifact Generation"


echo "START Starting Container"
# start the container
docker run -d -it --name keystone -p 5000:5000 -p 35357:35357 \
       -h $YOUR_HOST \
       -e IDENTITY_HOST="$YOUR_HOST" \
       -e KEYSTONE_ADMIN_PASSWORD="secret" \
       -v $MYSQL_DATA_DIR:/var/lib/mysql \
       -v `pwd`/keystone_cert.pem:/etc/nginx/ssl/keystone_cert.pem \
       -v `pwd`/keystone_key.pem:/etc/nginx/ssl/keystone_key.pem \
       clearlinux/keystone


echo "END Starting Container"

#! /bin/bash

#install docker
sudo yum -y install docker
sudo service docker start
sudo docker pull alagalah/odlpoc_ovs230
sudo docker run -dit -h docker1 --name docker1 docker.io/alagalah/odlpoc_ovs230:latest
echo "Installing docker done."

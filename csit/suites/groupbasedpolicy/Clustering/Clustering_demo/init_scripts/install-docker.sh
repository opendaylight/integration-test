#! /bin/bash

#install docker
sudo yum -y install docker
sudo service docker start
sudo docker pull alagalah/odlpoc_ovs230
echo "Installing docker done."

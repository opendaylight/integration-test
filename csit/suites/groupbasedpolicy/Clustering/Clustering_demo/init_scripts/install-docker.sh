#! /bin/bash

#install docker
sudo yum -y install docker
sudo service docker start
sudo docker pull ubuntu
echo "Installing docker done."

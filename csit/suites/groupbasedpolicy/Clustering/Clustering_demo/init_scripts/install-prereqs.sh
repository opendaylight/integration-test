#! /bin/bash

#install pre-reguirements
echo "Installing pre-reguirements..."

sudo sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/g' /home/vagrant/.bashrc
sudo sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/g' /root/.bashrc

sudo yum -y install yum-utils
sudo yum-config-manager --add-repo https://nexus.fd.io/content/repositories/fd.io.master.centos7/
#sudo yum upgrade
echo "Installing pre-reguirements done."

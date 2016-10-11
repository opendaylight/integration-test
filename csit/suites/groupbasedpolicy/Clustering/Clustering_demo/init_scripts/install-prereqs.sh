#! /bin/bash

#install pre-reguirements
echo "Installing pre-reguirements..."

sudo sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/g' /home/vagrant/.bashrc
sudo sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/g' /root/.bashrc

sudo yum -y install yum-utils
sudo yum-config-manager --add-repo https://nexus.fd.io/content/repositories/fd.io.stable.1609.centos7/
#sudo yum upgrade
sudo firewall-cmd --list-all
sudo firewall-cmd --zone=public --add-port=2831/tcp
sudo firewall-cmd --zone=public --add-port=7777/tcp
sudo firewall-cmd --list-all
echo "Installing pre-reguirements done."

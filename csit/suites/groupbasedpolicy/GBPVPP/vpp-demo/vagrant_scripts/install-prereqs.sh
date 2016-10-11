#! /bin/bash

#install pre-reguirements
echo "Installing pre-reguirements..."

sudo sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/g' /home/vagrant/.bashrc
sudo sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/g' /root/.bashrc

if [ ! -f /etc/apt/sources.list.d/99fd.io.list ];then
    echo "deb https://nexus.fd.io/content/repositories/fd.io.stable.1609.ubuntu.trusty.main/ ./" | sudo tee -a /etc/apt/sources.list.d/99fd.io.list
fi
sudo apt-get -qq update --allow-unauthenticated
sudo apt-get -y remove apparmor apparmor-utils libapparmor-perl
sudo update-grub
sudo apt-get -y update
sudo apt-get -y -f install
sudo apt-get -y install python-virtualenv python-dev iproute2 vim mc debhelper dkms dpkg-dev build-essential
sudo update-alternatives --install /bin/sh sh /bin/bash 100
echo "Installing pre-reguirements done."

#! /bin/bash

#add user
echo "Adding gbp user..."
sudo deluser gbp
sudo adduser --disabled-password --gecos "" gbp
echo gbp:gbp | sudo chpasswd
sudo adduser gbp vagrant
id gbp
echo "gbp ALL=(root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/gbp
sudo chmod 0440 /etc/sudoers.d/gbp
echo "Adding gbp user done."

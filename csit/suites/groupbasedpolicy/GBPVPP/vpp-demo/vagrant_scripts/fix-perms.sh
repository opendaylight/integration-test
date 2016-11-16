#! /bin/bash

#fix permissions
sudo chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
sudo chmod 0600 /home/vagrant/.ssh/authorized_keys

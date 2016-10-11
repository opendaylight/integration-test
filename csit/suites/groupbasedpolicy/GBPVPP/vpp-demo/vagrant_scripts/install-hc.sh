#! /bin/bash

#install hc
echo "Installing Honeycomb..."
sudo apt-get update --allow-unauthenticated
sudo apt-get -y -f install --allow-unauthenticated
sudo apt-get -qq install -y --allow-unauthenticated honeycomb
sed -i 's/"restconf-port": 8181/"restconf-port": 8283/g' /opt/honeycomb/config/honeycomb.json
echo "Installing Honeycomb done."
#sudo service honeycomb start
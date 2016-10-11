#! /bin/bash

#install hc
echo "Installing Honeycomb..."
sudo yum -y --nogpgcheck install java-1.8.0-openjdk honeycomb
sed -i 's/"restconf-port": .*,/"restconf-port": 8283,/g' /opt/honeycomb/config/honeycomb.json
echo "Installing Honeycomb done."
sudo service honeycomb start
#! /bin/bash

#install ODL
echo "Installing ODL..."
sudo rm -rf /opt/distribution-karaf-0.5.0-Boron.tar.gz
sudo rm -rf /opt/distribution-karaf-0.5.0-Boron
if [ ! -f /vagrant/distribution-karaf-0.5.0-Boron.tar.gz ];then
    cd /tmp/
    echo "downloading ODL (this could take long) ..."
    wget https://nexus.opendaylight.org/content/repositories/opendaylight.release/org/opendaylight/integration/distribution-karaf/0.5.0-Boron/distribution-karaf-0.5.0-Boron.tar.gz -q
    sudo cp distribution-karaf-0.5.0-Boron.tar.gz /opt/distribution-karaf-0.5.0-Boron.tar.gz
else
    sudo cp /vagrant/distribution-karaf-0.5.0-Boron.tar.gz /opt/distribution-karaf-0.5.0-Boron.tar.gz
fi
cd /opt/
echo "extracting ODL ..."
sudo tar -zxf distribution-karaf-0.5.0-Boron.tar.gz
echo "configuring ODL ..."
sudo sed -i 's/Property name="jetty.port" default="8181"/Property name="jetty.port" default="8081"/g' /opt/distribution-karaf-0.5.0-Boron/etc/jetty.xml
sudo sed -i 's/Property name="jetty.port" default="8080"/Property name="jetty.port" default="8182"/g' /opt/distribution-karaf-0.5.0-Boron/etc/jetty.xml
echo "Installing ODL done."

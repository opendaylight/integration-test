#! /bin/bash

#install java 8 for ubuntu
echo "installing java..."
sudo apt-get update
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys DA1A4A13543B466853BAF164EB9B1D8886F44E2A
if [ ! -f /etc/apt/sources.list.d/openjdk.list ];then
    echo "deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main " | sudo tee -a /etc/apt/sources.list.d/openjdk.list
    echo "deb-src http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main" | sudo tee -a /etc/apt/sources.list.d/openjdk.list
else
    echo "OpenJDK source already applied."
fi
sudo apt-get update
sudo apt-get -y install openjdk-8-jdk
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
echo "$JAVA_HOME"

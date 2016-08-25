#!/usr/bin/env bash

echo "Installing project dependencies"
sudo apt-get update

echo "Installing JRE8" 
sudo apt-get install -y software-properties-common python-software-properties
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
sudo add-apt-repository ppa:webupd8team/java -y

sudo apt-get update
sudo apt-get install -y oracle-java8-installer
echo "Setting environment variables for Java 8.."
sudo apt-get install -y oracle-java8-set-default

echo "Installation Done !"

echo "Installing Dependencies for RabbitMQ Server"
sudo apt-get -y install erlang
echo "RabbitMQ Dependencies Installed !"

echo "Pulling Server files"
sudo apt-get install -y git
git clone https://github.com/meetsushantpatil/ODL_Vagrant.git
rm -rf ./.git
echo "server installed"



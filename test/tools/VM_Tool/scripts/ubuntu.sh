#!/usr/bin/env bash

# --------------------------------------------
# External shell provisioner script for Ubuntu
# --------------------------------------------

# Install initial softwares:
apt-get update
apt-get install -y \
  openjdk-7-jre \
  openjdk-7-jdk \
  git

# Install Maven
wget -nv http://apache.sunsite.ualberta.ca/maven/maven-3/3.3.1/binaries/apache-maven-3.3.1-bin.tar.gz
mkdir -p /usr/local/apache-maven
tar -C /usr/local/apache-maven/ -xzf apache-maven-3.3.1-bin.tar.gz
echo "export PATH=$PATH:/usr/local/apache-maven/apache-maven-3.3.1/bin" >> /home/vagrant/.bash_profile
echo "MAVEN_OPTS=\"-Xms256m -Xmx512m\"" >> /home/vagrant/.bash_profile

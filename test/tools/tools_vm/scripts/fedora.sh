#!/usr/bin/env bash

# --------------------------------------------
# External shell provisioner script for Fedora
# --------------------------------------------

# Set HOME variable for this script
HOME="/home/vagrant"

# Install initial packages
sudo yum install -y \
  git \
  puppet

# ----------------
# Install netopeer
# ----------------

# Install required system dependencies
sudo yum install -y \
  readline \
  readline-devel \
  libssh2 \
  libssh2-devel \
  libxml2 \
  libxml2-devel \
  libxml2-python \
  libxslt \
  libxslt-devel \
  libcurl \
  libcurl-devel \
  dbus \
  dbus-devel \
  libevent \
  libevent-devel \
  libssh-devel \
  libtool \
  doxygen

# Install pyang (extensible YANG validator and converter in python)
cd $HOME && git clone https://github.com/mbj4668/pyang.git
sudo chown -R vagrant:vagrant $HOME/pyang/
cd $HOME/pyang/ && sudo python setup.py install

# Install libnetconf (NETCONF library in C)
cd $HOME && git clone https://code.google.com/p/libnetconf
sudo chown -R vagrant:vagrant $HOME/libnetconf/
  cd $HOME/libnetconf/ && \
  sh configure --prefix=/usr --with-nacm-recovery-uid=1000 && \
  make && \
  sudo make install

# Install netopeer (set of NETCONF tools built on the libnetconf library)
cd $HOME && git clone https://code.google.com/p/netopeer
sudo chown -R vagrant:vagrant $HOME/netopeer/
  cd $HOME/netopeer/server/ && \
  sh configure --prefix=/usr && \
  make && \
  sudo make install
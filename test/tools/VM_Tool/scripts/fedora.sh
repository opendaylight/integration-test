#!/usr/bin/env bash

# --------------------------------------------
# External shell provisioner script for Fedora
# --------------------------------------------

# Install initial packages
sudo yum install -y \
  puppet \
  git

#-----------------
# Install netopeer
#-----------------

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
  libtool

# Install pyang (extensible YANG validator and converter in python)
git clone https://github.com/mbj4668/pyang.git && \
  cd pyang && \
  sudo python setup.py install

# Install libnetconf (NETCONF library in C)
git clone https://code.google.com/p/libnetconf && \
  cd libnetconf && \
  ./configure  --with-nacm-recovery-uid=1000 && \
  make && \
  sudo make install

# Create softlink for libnetconf library in lib64
sudo ln -s /usr/local/lib/libnetconf.so.0 /lib64

# Install netopeer (set of NETCONF tools built on the libnetconf library)
git clone https://code.google.com/p/netopeer && \
  cd netopeer/server && \
  ./configure && \
  make && \
  sudo make install

# Add path to python site-package directory
echo "/usr/local/lib/python2.7/site-packages" | sudo tee /usr/lib/python2.7/site-packages/netopeer.pth

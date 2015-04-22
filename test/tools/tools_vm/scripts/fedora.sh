#!/usr/bin/env bash

# --------------------------------------------
# External shell provisioner script for Fedora
# --------------------------------------------
echo "Preparing basic environnement"

# Set HOME variable for this script
HOME="/home/vagrant"

# Add a nice login message
su -c "cp /vagrant/scripts/welcome.txt /etc/motd"

# Install initial packages
su -c "yum install -y \
  git \
  puppet \
  python-pip \
  python-devel"

# ----------------
# Install netopeer
# ----------------
echo "Installing netopeer"

# Install required dependencies
su -c "yum install -y \
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
  doxygen"

# Install pyang (extensible YANG validator and converter in python)
cd $HOME && \
  git clone https://github.com/mbj4668/pyang.git && \
  su -c "chown -R vagrant:vagrant $HOME/pyang/" && \
  cd $HOME/pyang/ && \
  su -c "python setup.py install"

# Install libnetconf (NETCONF library in C)
cd $HOME && \
  git clone https://code.google.com/p/libnetconf && \
  su -c "chown -R vagrant:vagrant $HOME/libnetconf/" && \
  cd $HOME/libnetconf/ && \
  sh configure --prefix=/usr --with-nacm-recovery-uid=1000 && \
  make && \
  su -c "make install"

# Install netopeer (set of NETCONF tools built on the libnetconf library)
cd $HOME && \
  git clone https://code.google.com/p/netopeer && \
  su -c "chown -R vagrant:vagrant $HOME/netopeer/" && \
  cd $HOME/netopeer/server/ && \
  sh configure --prefix=/usr && \
  make && \
  su -c "make install"

# --------------------------------
# Install Robot Framework and RIDE
# --------------------------------
echo "Installing Robot Framework and RIDE"

# Install required dependencies
su -c "yum install -y \
  wxGTK-devel \
  gcc-c++ \
  xorg-x11-xauth"

# Install Robot Framework libraries
su -c "pip install \
  robotframework-ride \
  robotframework-sshlibrary \
  robotframework-requests"

# Install wxPython, a blending of the wxWidgets C++ class library used for RIDE
cd $HOME && \
  wget -e dotbytes=1M http://sourceforge.net/projects/wxpython/files/wxPython/2.8.12.1/wxPython-src-2.8.12.1.tar.bz2 && \
  tar -xvjf wxPython-src-2.8.12.1.tar.bz2 && \
  rm wxPython-src-2.8.12.1.tar.bz2 && \
  cd wxPython-src-2.8.12.1/wxPython && \
  python setup.py build && \
  su -c "python setup.py install"

# ----------------------------
# Add aliases to run the tools
# ----------------------------
echo "Creating aliases"

# Add 'ride' alias for quietly running RIDE gui
echo "alias ride=\"nohup ride.py >/dev/null 2>&1 &\"" >> $HOME/.bashrc

# Add 'karaf' alias for running karaf shell
echo "alias karaf=\"sh /vagrant/scripts/connect.sh\"" >> $HOME/.bashrc

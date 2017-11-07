#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> quagga-install.sh"
QUAGGA_VERSION=2
set -e -x
if [ -d "/opt/stack/devstack" ]; then
   echo "6wind quagga is not supported on devstack"
   exit 0
fi

# installation of 6wind/quagga on centos7 and ubuntu16.04 images
FACTER_OS=$(/usr/bin/facter operatingsystem | tr '[:upper:]' '[:lower:]')
Nexus_url="https://nexus.opendaylight.org/content/repositories/thirdparty/quagga$QUAGGA_VERSION"
case $FACTER_OS in
    ubuntu)
        # install the QBGP packages on ubuntu host
        if [ -d "/tmp/install-quagga" ]; then
          sudo rm -rf /tmp/install-quagga
        fi
        sudo mkdir -p /tmp/install-quagga/
        cd /tmp/install-quagga/
        c_capn="c-capnproto/1.0.2.75f7901.Ubuntu16.04/c-capnproto-1.0.2.75f7901.Ubuntu16.04"
        thirft="thrift/1.0.0.b2a4d4a.Ubuntu16.04/thrift-1.0.0.b2a4d4a.Ubuntu16.04"
        zmq="zmq/4.1.3.56b71af.Ubuntu16.04/zmq-4.1.3.56b71af.Ubuntu16.04"
        quagga="quagga/1.1.0.837f143.Ubuntu16.04/quagga-1.1.0.837f143.Ubuntu16.04"
        zrpc="zrpc/0.2.56d11ae.thriftv$QUAGGA_VERSION.Ubuntu16.04/zrpc-0.2.56d11ae.thriftv$QUAGGA_VERSION.Ubuntu16.04"
        for pkg in $c_capn $thirft $zmq $quagga $zrpc
          do
             sudo wget $Nexus_url/$pkg.deb
          done
        for rpms in thrift zmq c-capnproto quagga zrpc
          do
              sudo  dpkg -i  $rpms*.deb
          done
;;
    centos)
        # install the QBGP packages on centos host
        if [ -d "/tmp/install-quagga" ]; then
          sudo rm -rf /tmp/install-quagga
        fi
        sudo mkdir /tmp/install-quagga/
        cd /tmp/install-quagga/
        c_capn="c-capnproto/1.0.2.75f7901.CentOS7.4.1708-0.x86_64/c-capnproto-1.0.2.75f7901.CentOS7.4.1708-0.x86_64"
        thirft="thrift/1.0.0.b2a4d4a.CentOS7.4.1708-0.x86_64/thrift-1.0.0.b2a4d4a.CentOS7.4.1708-0.x86_64"
        zmq="zmq/4.1.3.56b71af.CentOS7.4.1708-0.x86_64/zmq-4.1.3.56b71af.CentOS7.4.1708-0.x86_64"
        quagga="quagga/1.1.0.837f143.CentOS7.4.1708-0.x86_64/quagga-1.1.0.837f143.CentOS7.4.1708-0.x86_64"
        zrpc="zrpc/0.2.56d11ae.thriftv$QUAGGA_VERSION.CentOS7.4.1708-0.x86_64/zrpc-0.2.56d11ae.thriftv$QUAGGA_VERSION.CentOS7.4.1708-0.x86_64"
        for pkg in $c_capn $thirft $zmq $quagga $zrpc
          do
             sudo wget $Nexus_url/$pkg.rpm
          done
        for rpms in thrift zmq c-capnproto quagga zrpc
          do
               sudo rpm -Uvh $rpms*.rpm
          done
    ;;
esac

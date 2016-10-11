#!/bin/bash
#
# Copyright (c) 2016 Cisco and/or its affiliates.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# set -x #uncomment to enable verbose output of script

#download vpp packages
echo "clearing previously downloaded packages of VPP and HC"
rm -rf ./*.deb
rm -rf ./*.rpm

echo "downloading VPP and HC packages"
wget https://nexus.fd.io/content/repositories/fd.io.master.centos7/io/fd/honeycomb/honeycomb/1.0.0-1063.noarch/honeycomb-1.0.0-1063.noarch.rpm #update this to install latest HC
./download_vpp_pkgs.sh	#this will install latest 16.9 stable packages
sleep 3


echo "Setting up VPP-demo environment..."
vagrant up --provision --parallel
echo "...done

\"vagrant ssh controller\" - connect to controller node
\"vagrant ssh compute0\" - connect to compute0 node
\"vagrant ssh compute1\" - connect to compute0 node
"

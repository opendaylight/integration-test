#!/bin/bash

# This script will pass base edition system test to local controller
# Please make sure there is no controller or mininet running when launching the script
echo starting controller Base edition...
cd ~/controller-base/opendaylight
./run.sh -start &> runlog.txt &
sleep 120
./run.sh -status
cd ~
pybot -d ${HOME} -v CONTROLLER:127.0.0.1 -v MININET:127.0.0.1 -v USER_HOME:${HOME} -v MININET_USER:${USER} ${HOME}/integration/test/csit/suites/base
cd ~/controller-base/opendaylight
./run.sh -stop


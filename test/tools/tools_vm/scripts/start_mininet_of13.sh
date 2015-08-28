#!/bin/bash

# This script will start mininet OF13 on local controller
sudo mn --topo tree,2  --controller 'remote,ip=127.0.0.1,port=6633' --switch ovsk,protocols=OpenFlow13

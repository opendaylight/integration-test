#!/bin/bash

# This script will start mininet OF10 on local controller
sudo mn --controller 'remote,ip=127.0.0.1,port=6633' --topo tree,2 

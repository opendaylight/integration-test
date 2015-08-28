#!/bin/bash

# This script will start mininet CPqD on local controller
sudo mn --topo tree,2 --mac --switch user --controller 'remote,ip=127.0.0.1,port=6633'

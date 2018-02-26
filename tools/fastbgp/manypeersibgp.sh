#!/bin/bash

python play.py --amount=1000000 --multiplicity=10 --myip=127.0.0.2 --myport=17900 --peerip=127.0.0.1 --peerport=1790 --logfile=bgp_peer.log --info | tee play.py.out

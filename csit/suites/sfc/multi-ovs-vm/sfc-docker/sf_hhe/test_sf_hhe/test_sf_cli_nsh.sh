#!/bin/bash
mn -c >& /dev/null
./sfc_topology_nsh.py |& grep CHAIN

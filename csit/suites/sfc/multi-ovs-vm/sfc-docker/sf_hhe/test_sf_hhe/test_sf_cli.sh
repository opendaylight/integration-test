#!/bin/bash
mn -c >& /dev/null
./sfc_topology_symmetric_chain.py |& grep CHAIN

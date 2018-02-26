#!/bin/bash

curl -i -H "Accept: application/json" -u admin:admin "http://localhost:8181/restconf/operational/network-topology:network-topology/topology/example-ipv4-topology" | grep -oh "prefix" | wc -w

#!/usr/bin/python
"""
Cluster Rejoin Tool
Author: Phillip Shea
Updated: 2015-May-07

This tool rejoins any isolated controllers to the cluster.

A file named 'cluster.json' containing a list of the IP addresses and
credentials of the controllers is required. It resides in the same
directory as monitor.py.

The file should look like this:

    {
        "cluster": {
            "controllers": [
                {"ip": "172.17.10.93", "port": "8181"},
                {"ip": "172.17.10.93", "port": "8181"},
                {"ip": "172.17.10.93", "port": "8181"}
            ],
            "user": "username",
            "pass": "password",
        }
    }

Usage:python rejoin.py
 """

import sys


def import_utility_modules():
    global UtilLibrary, json
    import sys
    sys.path.append('../../../csit/libraries')
    import UtilLibrary
    import json


import_utility_modules()

try:
    with open('cluster.json') as cluster_file:
        data = json.load(cluster_file)
except:
    print str(sys.exc_info())
    print "unable to open the file cluster.json"
    exit(1)
try:
    cluster_list = data["cluster"]["controllers"]
    cluster_ips = []
    for controller in cluster_list:
        cluster_ips.append(controller["ip"])
    user_name = data["cluster"]["user"]
    user_pass = data["cluster"]["pass"]
except:
    print str(sys.exc_info())
    print 'Error reading the file cluster.json'
    exit(1)

print UtilLibrary.flush_iptables(cluster_ips, user_name, user_pass)

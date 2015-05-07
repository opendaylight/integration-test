#!/usr/bin/python
"""
Controller Isolation Tool
Author: Phillip Shea
Updated: 2015-May-07

This tool isolates an indicated controller from the cluster. The tool takes
a single integer argument corresponding to the number of a controller
in a json file's ordered list of controllers. This is the controller to
be isolated.

A file named 'cluster.json' containing a list of the IP addresses and
credentials of the controllers is required. It resides in the same
directory as monitor.py.

The file should look like this:

    {
        "cluster": {
            "controllers": [
                "172.17.10.93",
                "172.17.10.94",
                "172.17.10.95"
            ],
            "user": "username",
            "pass": "password"
        }
    }

Usage:python isolate.py [controller to be isolated]
"""

import sys
sys.path.append('../../../csit/libraries')
import UtilLibrary
import json

try:
    with open('cluster.json') as cluster_file:
        data = json.load(cluster_file)
except:
    print str(sys.exc_info())
    print "unable to open the file cluster.json"
    exit(1)
try:
    cluster_list = data["cluster"]["controllers"]
    user_name = data["cluster"]["user"]
    user_pass = data["cluster"]["pass"]
except:
    print str(sys.exc_info())
    print 'Error reading the file cluster.json'
    exit(1)
try:
    isolate = int(sys.argv[1])
except:
    print 'You must specify the number (e.g. 1, 2, 3) of the controller to isolate.'
    exit(1)

print "isolating controller " + str(isolate)

print UtilLibrary.isolate_controller(cluster_list, user_name, user_pass, isolate)

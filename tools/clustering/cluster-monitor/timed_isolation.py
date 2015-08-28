#!/usr/bin/python
"""
Controller Isolation Tool
Author: Phillip Shea
Updated: 2015-May-07

This tool isolates an indicated controller for a specified duration.
The tool's first integer argument corresponds to the number of a controller
in a json file's ordered list of controllers. This is the controller to
be isolated. The second argument is the duration of isolation in
seconds.

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

Usage:python timed_isolation.py [controller to be isolated]  [duration of isolation in seconds]
"""

import sys
sys.path.append('../../../csit/libraries')
import UtilLibrary
import json
import time

try:
    with open('cluster.json') as cluster_file:
        data = json.load(cluster_file)
except:
    print str(sys.exc_info())
    print 'unable to open the file cluster.json'
    exit(1)
try:
    controllers = data["cluster"]["controllers"]
    user_name = data["cluster"]["user"]
    user_pass = data["cluster"]["pass"]
except:
    print str(sys.exc_info())
    print 'Error reading the file cluster.json'
    exit(1)
try:
    isolate = int(sys.argv[1])
    duration = int(sys.argv[2])
except:
    print 'You must specify the number (e.g. 1, 2, 3) of the controller to isolate.'
    exit(1)

print 'Isolating controller ' + str(isolate)

print UtilLibrary.isolate_controller(controllers, user_name, user_pass, isolate)

print 'Pausing for ' + str(duration) + ' seconds...'
time.sleep(duration)

print UtilLibrary.flush_iptables(controllers, user_name, user_pass)

#!/usr/bin/python
"""
Cluster Monitor Tool
Author: Phillip Shea
Updated: 2015-May-07

This tool provides real-time visualization of the cluster member roles for all
shards in the config datastore. It is assumed that all cluster members have the
same shards.

A file named 'cluster.json' contaning a list of the IP addresses of the
controllers is required. This resides in the same directory as monitor.py.
"user" and "pass" are not required for monitor.py, but they may be
needed for other apps in this folder. The file should look like this:

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

Usage:python monitor.py
"""
from io import BytesIO
import time
import pprint
import curses
import sys
import json
import pycurl
import string


def rest_get(restURL):
    rest_buffer = BytesIO()
    c = pycurl.Curl()
    c.setopt(c.TIMEOUT, 2)
    c.setopt(c.CONNECTTIMEOUT, 1)
    c.setopt(c.FAILONERROR, False)
    c.setopt(c.URL, str(restURL))
    c.setopt(c.HTTPGET, 0)
    c.setopt(c.WRITEFUNCTION, rest_buffer.write)
    c.perform()
    c.close()
    return json.loads(rest_buffer.getvalue())


def getClusterRolesWithCurl(shardName, *args):
    ips = args[0]
    names = args[1]
    controller_state = {}
    for i, ip in enumerate(ips):
        controller_state[ip] = None
        url = 'http://' + ip + ':' + '8181/jolokia/read/org.opendaylight.controller:'
        url += 'Category=Shards,name=' + names[i]
        url += '-shard-' + shardName + '-config,type=DistributedConfigDatastore'
        try:
            resp = rest_get(url)
            if resp['status'] != 200:
                controller_state[ip] = 'HTTP ' + str(resp['status'])
            if 'value' in resp:
                data_value = resp['value']
                controller_state[ip] = data_value['RaftState']
        except:
            if 'timed out' in str(sys.exc_info()[1]):
                controller_state[ip] = 'timeout'
            elif 'JSON' in str(sys.exc_info()):
                controller_state[ip] = 'JSON error'
            elif 'connect to host' in str(sys.exc_info()):
                controller_state[ip] = 'no connection'
            else:
                controller_state[ip] = 'down'
    return controller_state


def size_and_color(cluster_roles, field_length, ip_addr):
    status_dict = {}
    status_dict['txt'] = string.center(str(cluster_roles[ip_addr]), field_length)
    if cluster_roles[ip_addr] == "Leader":
        status_dict['color'] = curses.color_pair(2)
    elif cluster_roles[ip_addr] == "Follower":
        status_dict['color'] = curses.color_pair(3)
    elif cluster_roles[ip_addr] == "Candidate":
        status_dict['color'] = curses.color_pair(5)
    else:
        status_dict['color'] = curses.color_pair(0)
    return status_dict


field_len = 14
try:
    with open('cluster.json') as cluster_file:
        data = json.load(cluster_file)
except:
    print str(sys.exc_info())
    print 'Unable to open the file cluster.json'
    exit(1)
try:
    controllers = data["cluster"]["controllers"]
except:
    print str(sys.exc_info())
    print 'Error reading the file cluster.json'
    exit(1)

controller_names = []
# Retrieve controller names and shard names.
for controller in controllers:
    url = "http://" + controller + ":8181/jolokia/read/org.opendaylight.controller:"
    url += "Category=ShardManager,name=shard-manager-config,type=DistributedConfigDatastore"
    try:
        data = rest_get(url)
    except:
        print 'Unable to retrieve shard names from ' + controller
        print 'Are all controllers up?'
        print str(sys.exc_info()[1])
        exit(1)
    print 'shards from the first controller'
    pprint.pprint(data)
    # grab the controller name from the first shard
    name = data['value']['LocalShards'][0]
    print name
    pos = name.find('-shard-')
    print pos
    print name[:8]
    controller_names.append(name[:name.find('-shard-')])
print controller_names
# Putting shard names in a list, assuming all controllers have the same shards.
Shards = data['value']['LocalShards']
for i, shard in enumerate(Shards):
    Shards[i] = Shards[i].replace('member-', '')
    Shards[i] = Shards[i].replace('-shard-', '')
    Shards[i] = Shards[i].replace('-config', '')
    Shards[i] = Shards[i].replace(Shards[i][0], '')
print Shards

stdscr = curses.initscr()
curses.noecho()
curses.cbreak()
curses.curs_set(0)
stdscr.keypad(1)
stdscr.nodelay(1)

curses.start_color()
curses.init_pair(1, curses.COLOR_WHITE, curses.COLOR_BLACK)
curses.init_pair(2, curses.COLOR_WHITE, curses.COLOR_GREEN)
curses.init_pair(3, curses.COLOR_WHITE, curses.COLOR_BLUE)
curses.init_pair(4, curses.COLOR_WHITE, curses.COLOR_YELLOW)
curses.init_pair(5, curses.COLOR_BLACK, curses.COLOR_YELLOW)

# display controller and shard headers
for data_column, controller in enumerate(controller_names):
    stdscr.addstr(0, field_len * (data_column + 1), string.center(controller, field_len), curses.color_pair(1))
for row, shard in enumerate(Shards):
    stdscr.addstr(row + 1, 0, shard, curses.color_pair(1))
stdscr.addstr(len(Shards) + 2, 0, 'Press q to quit.', curses.color_pair(1))
stdscr.refresh()

# display shard status
odd_or_even = 0
key = ''
while key != ord('q') and key != ord('Q'):
    odd_or_even += 1
    key = stdscr.getch()

    for row, shard_name in enumerate(Shards):
        cluster_stat = getClusterRolesWithCurl(shard_name, controllers, controller_names)
        for data_column, controller in enumerate(controllers):
            status = size_and_color(cluster_stat, field_len, controller)
            stdscr.addstr(row + 1, field_len * (data_column + 1), status['txt'], status['color'])
    time.sleep(0.5)
    if odd_or_even % 2 == 0:
        stdscr.addstr(0, field_len/2 - 2, " <3 ", curses.color_pair(5))
    else:
        stdscr.addstr(0, field_len/2 - 2, " <3 ", curses.color_pair(0))
    stdscr.refresh()

# clean up
curses.nocbreak()
stdscr.keypad(0)
curses.echo()
curses.endwin()

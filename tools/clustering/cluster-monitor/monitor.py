#!/usr/bin/python
"""
Cluster Monitor Tool
Author: Phillip Shea
Updated: 2016-Mar-07

This tool provides real-time visualization of the cluster member roles for all
shards in either the config or operational datastore.

A file named 'cluster.json' contaning a list of the IP addresses and port numbers
of the controllers is required. This resides in the same directory as monitor.py.
"user" and "pass" are not required for monitor.py, but they may be
needed for other apps in this folder. The file should look like this:

    {
        "cluster": {
            "controllers": [
                {"ip": "172.17.10.93", "port": "8181"},
                {"ip": "172.17.10.93", "port": "8181"},
                {"ip": "172.17.10.93", "port": "8181"}
            ],
            "user": "username",
            "pass": "password",
            "shards_to_exclude": []  # list of shard names to omit from output
        }
    }

Usage:python monitor.py [-d data_store_name]
"""
from io import BytesIO
import time
import pprint
import curses
import sys
import json
import pycurl
import string
import argparse
import math


def rest_get(restURL, username, password):
    rest_buffer = BytesIO()
    c = pycurl.Curl()
    c.setopt(c.TIMEOUT, 2)
    c.setopt(c.CONNECTTIMEOUT, 1)
    c.setopt(c.FAILONERROR, False)
    c.setopt(c.URL, str(restURL))
    c.setopt(c.HTTPGET, 0)
    c.setopt(c.WRITEFUNCTION, rest_buffer.write)
    c.setopt(pycurl.USERPWD, "%s:%s" % (str(username), str(password)))
    c.perform()
    c.close()
    return json.loads(rest_buffer.getvalue())


def getClusterRolesWithCurl(shardName, controllers):
    controller_state = {}
    for i, controller in enumerate(controllers):
        controller_state[controller["ip"]] = None
        url = "http://" + controller["ip"] + ":" + controller["port"]\
              + "/jolokia/read/org.opendaylight.controller:"
        url += 'Category=Shards,name=' + controller['name']
        url += '-shard-' + shardName + '-' + data_store.lower() + ',type=Distributed' + data_store + 'Datastore'
        try:
            resp = rest_get(url, username, password)
            if resp['status'] != 200:
                controller_state[controller["ip"]] = 'HTTP ' + str(resp['status'])
            if 'value' in resp:
                data_value = resp['value']
                controller_state[controller["ip"]] = data_value['RaftState']
        except:
            if 'timed out' in str(sys.exc_info()[1]):
                controller_state[controller["ip"]] = 'timeout'
            elif 'JSON' in str(sys.exc_info()):
                controller_state[controller["ip"]] = 'JSON error'
            elif 'connect to host' in str(sys.exc_info()):
                controller_state[controller["ip"]] = 'no connection'
            else:
                controller_state[controller["ip"]] = 'down'
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


parser = argparse.ArgumentParser()
parser.add_argument('-d', '--datastore', default='Config', type=str,
                    help='polling can be done on "Config" or "Operational" data stores')
args = parser.parse_args()
data_store = args.datastore
if data_store != 'Config' and data_store != 'Operational':
    print 'Only "Config" or "Operational" data store is available for polling'
    exit(1)

try:
    with open('cluster.json') as cluster_file:
        data = json.load(cluster_file)
except:
    print str(sys.exc_info())
    print 'Unable to open the file cluster.json'
    exit(1)
try:
    controllers = data["cluster"]["controllers"]
    shards_to_exclude = data["cluster"]["shards_to_exclude"]
    username = data["cluster"]["user"]
    password = data["cluster"]["pass"]
except:
    print str(sys.exc_info())
    print 'Error reading the file cluster.json'
    exit(1)

Shards = set()

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

(maxy, maxx) = stdscr.getmaxyx()

key = -1
controller_len = 0
field_len = 0
while key != ord('q') and key != ord('Q'):
    key = max(key, stdscr.getch())

    # Retrieve controller names and shard names.
    for controller in controllers:
        key = max(key, stdscr.getch())
        if key == ord('q') or key == ord('Q'):
            break

        url = "http://" + controller["ip"] + ":" + controller["port"]\
              + "/jolokia/read/org.opendaylight.controller:"
        url += "Category=ShardManager,name=shard-manager-" + data_store.lower()\
               + ",type=Distributed" + data_store + "Datastore"
        try:
            data = rest_get(url, username, password)
            # grab the controller name from the first shard
            name = data['value']['LocalShards'][0]
            pos = name.find('-shard-')
            controller['name'] = name[:name.find('-shard-')]
            # collect shards found in any controller; does not require all controllers to have the same shards
            for localShard in data['value']['LocalShards']:
                shardName = localShard[(localShard.find("-shard-") + 7):localShard.find("-" + data_store.lower())]
                if shardName not in shards_to_exclude:
                    Shards.add(shardName)
        except:
            if 'name' not in controller:
                controller['name'] = controller['ip'] + ':' + controller['port']
        controller_len = max(controller_len, len(controller['name']))

    if Shards:
        field_len = max(map(len, Shards)) + 2
    else:
        field_len = max(field_len, 0)

    # Ensure everything fits
    if controller_len + 1 + (field_len + 1) * len(Shards) > maxx:
        extra = controller_len + 1 + (field_len + 1) * len(Shards) - maxx
        delta = int(math.ceil(float(extra) / (1 + len(Shards))))
        controller_len -= delta
        field_len -= delta

    # display controller and shard headers
    for row, controller in enumerate(controllers):
        stdscr.addstr(row + 1, 0, string.center(controller['name'], controller_len), curses.color_pair(1))
        for data_column, shard in enumerate(Shards):
            stdscr.addstr(0, controller_len + 1 + (field_len + 1) * data_column, string.center(shard, field_len),
                          curses.color_pair(1))
            stdscr.addstr(len(Shards) + 2, 0, 'Press q to quit.', curses.color_pair(1))
    stdscr.refresh()

    # display shard status
    odd_or_even = 0
    for data_column, shard_name in enumerate(Shards):
        key = max(key, stdscr.getch())
        if key == ord('q') or key == ord('Q'):
            break

        odd_or_even += 1
        if shard_name not in shards_to_exclude:
            cluster_stat = getClusterRolesWithCurl(shard_name, controllers)
            for row, controller in enumerate(controllers):
                status = size_and_color(cluster_stat, field_len, controller["ip"])
                stdscr.addstr(row + 1, controller_len + 1 + (field_len + 1) * data_column, status['txt'],
                              status['color'])
        time.sleep(0.5)
        if odd_or_even % 2 == 0:
            stdscr.addstr(0, controller_len / 2 - 2, " <3 ", curses.color_pair(5))
        else:
            stdscr.addstr(0, controller_len / 2 - 2, " <3 ", curses.color_pair(0))
        stdscr.refresh()

# clean up
curses.nocbreak()
stdscr.keypad(0)
curses.echo()
curses.endwin()

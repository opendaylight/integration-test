#!/usr/bin/env python

import argparse
from subprocess import call
from subprocess import check_output

parser = argparse.ArgumentParser(description='This is a script geared to stop docker containers')
parser.add_argument('-a','--all', help='Stop all containers',required=False, action='store_true')
parser.add_argument('-n','--number',help='Stop a given amount of containers, starting with the latter', required=False)
args = parser.parse_args()

# get current number of dockers containers, we remove 2 before first line is the headers of the command docker ps
# CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                        NAMES
# and we remove 1 a second time because container are spwan from 0 to X, not from 1 to X
containers = int(check_output(["docker ps | wc -l"], shell=True)) - 2

if args.number is not None:
     for x in range(0, int(args.number)):
	num_of_container_to_remove = int(containers) - int(x)
	command = "docker rm -f ovs_container_%s" % num_of_container_to_remove
     	call ([command], shell=True)
elif args.all:
     call (["docker rm -f $(docker ps -q)"], shell=True)



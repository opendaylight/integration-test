#!/usr/bin/env python

import sys, getopt
import argparse
from DockerLibrary import DockerLibrary

parser = argparse.ArgumentParser(description='This is a script geared to manage docker containers')
parser.add_argument('-a','--address', help='Opendaylight controller IP address',required=True)
parser.add_argument('-n','--number',help='Number of docker container to spwan', required=True)
parser.add_argument('-i','--image',help='Docker image name', required=True)
args = parser.parse_args()

lib=DockerLibrary(args.address, args.image)
lib.add_containers(int(args.number))

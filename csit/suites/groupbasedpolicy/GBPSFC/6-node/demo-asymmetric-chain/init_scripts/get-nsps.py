#!/usr/bin/python

# for asymmetric chain
import socket
import requests
import json
from requests.auth import HTTPBasicAuth
import sys
import os
from subprocess import check_output
from infrastructure_config import *

DEFAULT_PORT='8181'
USERNAME='admin'
PASSWORD='admin'

def get(host, port, uri):
    url='http://'+host+":"+port+uri
    #print url
    r = requests.get(url, auth=HTTPBasicAuth(USERNAME, PASSWORD))
    jsondata=json.loads(r.text)
    return jsondata


def get_rsps_uri():
	return "/restconf/operational/rendered-service-path:rendered-service-paths"

def doCmd(cmd):
    listcmd=cmd.split()
    print check_output(listcmd)

if __name__ == "__main__":
    # Launch main menu


    # Some sensible defaults
    controller=os.environ.get('ODL')
    if controller == None:
        sys.exit("No controller set.")
    #else:
	#print "Contacting controller at %s" % controller

    resp=get(controller,DEFAULT_PORT,get_rsps_uri())
    if len(resp['rendered-service-paths']) > 0:
       paths=resp['rendered-service-paths']['rendered-service-path']

       nsps=[]
       for path in paths:
           nsps.append(path['path-id'])
       if len(nsps) > 0:
           sw_index=int(socket.gethostname().split("gbpsfc",1)[1])-1
           if sw_index in range(0,len(switches)+1):

              controller=os.environ.get('ODL')
              sw_type = switches[sw_index]['type']
              sw_name = switches[sw_index]['name']
              if sw_type == 'sf':
                  print "******************************"
                  print "Adding flows for %s as an SF." % sw_name
                  print "******************************"
                  doCmd('sudo /vagrant/utils/sf-flows.sh %s' % min(nsps))


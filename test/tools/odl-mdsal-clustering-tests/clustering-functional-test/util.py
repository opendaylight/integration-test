__author__ = "Basheeruddin Ahmed"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "syedbahm@cisco.com"


import urllib
from urllib import request
import json
import requests
import socket


#
#Helps in making GET REST calls
#

def get(url, userId, password):

    headers = {}
    headers['Accept']= 'application/xml'

    # Send the GET request
    req = urllib.request.Request(url, None, headers)

    # Read the response
    return urllib.request.urlopen(req).read()

#
#Helps in making POST REST calls without outputs
#
def nonprintpost(url, userId, password,data):

    headers = {}
    headers['Content-Type'] = 'application/json'
    #headers['Accept']= 'application/xml'

    resp = requests.post(url,data.encode(),headers=headers)


    return resp

#
#Helps in making POST REST calls
#
def post(url, userId, password,data):
    print("post request with url "+url)
    print("post request with data "+data)
    headers = {}
    headers['Content-Type'] = 'application/json'
    #headers['Accept']= 'application/xml'

    resp = requests.post(url,data.encode(),headers=headers)

    #print (resp.raise_for_status())
    print (resp.headers)

    return resp

#
#Helps in making DELET REST calls
#
def delete(url,userId,password):
    print("delete all resources belonging to url"+url)
    resp=requests.delete(url)



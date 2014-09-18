__author__ = "Basheeruddin Ahmed"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "syedbahm@cisco.com"


import requests
from SSHLibrary import SSHLibrary

#
#Helps in making GET REST calls
#

def get(url, userId, password):

    headers = {}
    headers['Accept']= 'application/xml'

    # Send the GET request
    req = requests.get(url, params=None, headers=headers)

    # Read the response
    return req

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

#
# use username and password of controller server for ssh and need
# karaf distribution location like /root/Documents/dist
#
def startcontroller(ip,username,password,karafHome):

    print "start controller"
    lib = SSHLibrary()
    lib.open_connection(ip)
    lib.login(username=username,password=password)
    print "login done"
    lib.execute_command(karafHome+"/bin/start")
    print "Starting server"
    lib.close_connection()

def stopcontroller(ip,username,password,karafHome):

    print "stop controller"
    lib = SSHLibrary()
    lib.open_connection(ip)
    lib.login(username=username,password=password)
    print "login done"
    lib.execute_command(karafHome+"/bin/stop")
    print "Stopped server"
    lib.close_connection()



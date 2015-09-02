__author__ = "Basheeruddin Ahmed"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "syedbahm@cisco.com"


import requests
from SSHLibrary import SSHLibrary

import robot
import time

global _cache

#
#Helps in making GET REST calls
#

def get(url, userId='admin', password='admin'):

    headers = {}
    headers['Accept']= 'application/xml'

    # Send the GET request
    session = _cache.switch("CLUSTERING_GET")
    resp = session.get(url,headers=headers,auth=(userId,password))    
    #resp = session.get(url,headers=headers,auth={userId,password})
    # Read the response
    return resp

#
#Helps in making POST REST calls without outputs
#
def nonprintpost(url, userId, password, data):

    if userId == None:
        userId = 'admin'

    if password == None:
        password = 'admin'

    headers = {}
    headers['Content-Type'] = 'application/json'
    #headers['Accept']= 'application/xml'

    session = _cache.switch("CLUSTERING_POST")
    resp = session.post(url,data.encode('utf-8'),headers=headers,auth=(userId,password))


    return resp

#
#Helps in making POST REST calls
#
def post(url, userId, password, data):

    if userId == None:
        userId = 'admin'

    if password == None:
        password = 'admin'

    print("post request with url "+url)
    print("post request with data "+data)
    headers = {}
    headers['Content-Type'] = 'application/json'
    #headers['Accept']= 'application/xml'
    session = _cache.switch("CLUSTERING_POST")
    resp = session.post(url,data.encode('utf-8'),headers=headers,auth=(userId,password))

    #print (resp.raise_for_status())
    print (resp.headers)
    if (resp.status_code >= 500):
        print (resp.text)

    return resp

#
#Helps in making DELET REST calls
#
def delete(url, userId='admin', password='admin'):
    print("delete all resources belonging to url"+url)
    session = _cache.switch("CLUSTERING_DELETE")
    resp=session.delete(url,auth=(userId,password))

def Should_Not_Be_Type_None(var):
    '''Keyword to check if the given variable is of type NoneType.  If the
        variable type does match  raise an assertion so the keyword will fail
    '''
    if var == None:
        raise AssertionError('the variable passed was type NoneType')
    return 'PASS'

# use username and password of controller server for ssh and need
# karaf distribution location like /root/Documents/dist
#
def execute_ssh_command(ip, username, password, command):
    print "executing ssh command"
    lib = SSHLibrary()
    lib.open_connection(ip)
    lib.login(username=username,password=password)
    print "login done"
    lib.execute_command(command)
    print "command executed : " + command
    lib.close_connection()

def wait_for_controller_up(ip, port="8181"):
    url = "http://" + ip + ":" + str(port) + \
          "/restconf/config/opendaylight-inventory:nodes/node/controller-config/yang-ext:mount/config:modules"

    print "Waiting for controller " + ip + " up."
    # Try 30*10s=5 minutes for the controller to be up.
    for i in xrange(30):
        try:
            print "attempt " + str(i) + " to url " + url
            resp = get(url, "admin", "admin")
            print "attempt " + str(i) + " response is " + str(resp)
            print resp.text
            if ('clustering-it-provider' in resp.text):
                print "Wait for controller " + ip + " succeeded"
                return True
        except Exception as e:
            print e
        time.sleep(10)

    print "Wait for controller " + ip + " failed"
    return False

def startAllControllers(username, password, karafhome, port, *ips):
    # Start all controllers
    for ip in ips:
        execute_ssh_command(ip, username, password, karafhome+"/bin/start")

    # Wait for all of them to be up
    for ip in ips:
        rc = wait_for_controller_up(ip, port)
        if (rc == False):
            return False
    return True

def startcontroller(ip,username,password,karafhome,port):
    execute_ssh_command(ip, username, password, karafhome+"/bin/start")
    return wait_for_controller_up(ip, port)

def stopcontroller(ip,username,password,karafhome):
    executeStopController(ip,username,password,karafhome)

    wait_for_controller_stopped(ip,username,password,karafhome)

def executeStopController(ip,username,password,karafhome):
    execute_ssh_command(ip, username, password, karafhome+"/bin/stop")

def stopAllControllers(username,password,karafhome,*ips):
    for ip in ips:
        executeStopController(ip,username,password,karafhome)

    for ip in ips:
        wait_for_controller_stopped(ip, username, password, karafhome)

def wait_for_controller_stopped(ip, username, password, karafHome):
    lib = SSHLibrary()
    lib.open_connection(ip)
    lib.login(username=username,password=password)

    # Wait 1 minute for the controller to stop gracefully   
    tries = 20
    i=1
    while i <= tries:
        stdout = lib.execute_command("ps -axf | grep karaf | grep -v grep | wc -l")
        #print "stdout: "+stdout
        processCnt = stdout[0].strip('\n')
        print "processCnt: "+processCnt
        if processCnt == '0':
            break;
        i = i+1
        time.sleep(3)

    lib.close_connection()

    if i > tries:
        print "Killing controller"
        kill_controller(ip, username, password, karafHome)   

def clean_journal(ip, username, password, karafHome):
    execute_ssh_command(ip, username, password, "rm -rf " + karafHome + "/journal")

def kill_controller(ip, username, password, karafHome):
    execute_ssh_command(ip, username, password, "ps axf | grep karaf | grep -v grep | awk '{print \"kill -9 \" $1}' | sh")

#
# main invoked
if __name__ != "__main__":
    _cache = robot.utils.ConnectionCache('No sessions created')
    # here create one session for each HTTP functions
    _cache.register(requests.session(), alias='CLUSTERING_GET')
    _cache.register(requests.session(),alias='CLUSTERING_POST')
    _cache.register(requests.session(),alias='CLUSTERING_DELETE')

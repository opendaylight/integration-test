__author__ = "Reinaldo Penno"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__version__ = "0.1"
__email__ = "repenno@cisco.com"
__status__ = "alpha"


#####
# Incrementally PUT(s) more and more list elements up to numputreq
# while computing the number of req/s and successful requests
#
# Then measure the number of GET request/sec up to numgetreq
# while computing the number of successful requests
# 
# For the default values it is estimated you will consume about
# 1.5GB of heap memory in ODL
####


import requests
import time

class Timer(object):
    def __init__(self, verbose=False):
        self.verbose = verbose

    def __enter__(self):
        self.start = time.time()
        return self

    def __exit__(self, *args):
        self.end = time.time()
        self.secs = self.end - self.start
        self.msecs = self.secs * 1000  # millisecs
        if self.verbose:
            print ("elapsed time: %f ms" % self.msecs)

# Parametrized PUT of incremental List elements            
JSONPUT = """
{
  "service-function": [
    {
      "ip-mgmt-address": "20.0.0.11",
      "type": "service-function:napt44",
      "name": "%d"
    }
  ]
}"""

putheaders = {'content-type': 'application/json'}
getheaders = {'Accept': 'application/json'}
# ODL IP:port
ODLIP   = "127.0.0.1:8080"
# We fist delete all existing service functions
DELURL  = "http://" + ODLIP + "/restconf/config/service-function:service-functions/"
GETURL  = "http://" + ODLIP + "/restconf/config/service-function:service-functions/service-function/%d/"
# Incremental PUT. This URL is for a list element
PUTURL  = "http://" + ODLIP + "/restconf/config/service-function:service-functions/service-function/%d/"

# You probably need to adjust this number based on your OS constraints.
# Maximum number of incremental PUT list elements
numputreq = 1000000
# Maximum number of GET requests
numgetreq = 10000
# We will present PUT reports every 10000 PUTs
numputstep = 1000
# We will present GET reports every 10000 PUTs
numgetstep = 1000

# Incrementally PUT list elements up to numputreq
def putperftest():
    s = requests.Session()
    print ("Starting PUT Performance. Total of %d requests\n" % numputreq)
    for numreq in range(0, numputreq, numputstep): 
        success = 0      
        with Timer() as t:
            for i in range(numreq, numreq + numputstep):
                r = s.put((PUTURL % i),data = (JSONPUT % i), headers=putheaders, stream=False )
                if (r.status_code == 200):
                    success+=1
        print ("=> %d elapsed requests" % (numreq + numputstep))
        print ("=> %d requests/s in the last %d reqs" % ((numputstep)/t.secs, numputstep))
        print ("=> %d successful PUT requests in the last %d reqs " % (success, numputstep))
        print ("\n")

# Delete all service functions
def delallsf():
    print ("Deleting all Service Functions")
    r = requests.delete(DELURL, headers=getheaders)   
    if (r.status_code == 200) or (r.status_code == 500):
        print ("Deleted all Service Functions \n")
        return 0
    else:
        print ("Delete Failed \n")
        exit()
        return -1

# Retrieve list elements 
def getperftest():
    s = requests.Session()
    print ("Starting GET Performance. Total of %d requests \n" % numgetreq)
    for numreq in range(0, numgetreq, numgetstep): 
        success = 0      
        with Timer() as t:
            for i in range(numreq, numreq + numgetstep):
                r = s.get((GETURL % i), stream=False )
                if (r.status_code == 200):
                    success+=1
        print ("=> %d elapsed requests" % (numreq + numgetstep))
        print ("=> %d requests/s in the last %d reqs" % ((numgetstep)/t.secs, numgetstep))
        print ("=> %d successful GET requests in the last %d reqs " % (success, numgetstep))
        print ("\n")


if __name__ == "__main__":
    delallsf()
    putperftest()
    getperftest()








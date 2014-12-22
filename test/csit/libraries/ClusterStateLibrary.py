__author__ = "Basheeruddin Ahmed"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "syedbahm@cisco.com"

import SettingsLibrary
from time import sleep
import UtilLibrary
import json
import sys

#
# Given a shardname (e.g. shard-inventory-config), number of shards and bunch of ips
# determines what role each ip has in an Akka (Raft based) cluster
# result would look like
# {'10.194.126.118':'Leader', '10.194.126.118':'Follower', '10.194.126.117': None}
#

def getClusterRoles(shardName,numOfShards=3,numOfTries=3,sleepBetweenRetriesInSecs=1,port=8181,*ips):
    dict={}
    for ip in ips:
      i=1
      dict[ip]=None
      bFollower = 0
      while i <= numOfShards:
        shardMemberName = "member-"+str(i)+"-"+shardName;
        j=1

        while j <= numOfTries:
            print "Try number "+str(j)
            try:
                print "finding if"+ ip +"is leader for shardName ="+shardMemberName
                url = SettingsLibrary.getJolokiaURL(ip,str(port),str(i),shardName)
                resp = UtilLibrary.get(url)
                print resp
                if(resp.status_code != 200):
                    sleep(sleepBetweenRetriesInSecs)
                    continue
                data = json.loads(resp.text)
                if('value' in data):
                    dataValue = data['value']
                    if(dataValue['RaftState']=='Follower'):
                        dict[ip]='Follower'
                        break;
                    elif(dataValue['RaftState']=='Leader'):
                        dict[ip]='Leader'
            except:
                e = sys.exc_info()[0]
                print "Try"+str(j)+":An error occurred when finding leader on"+ip+" for shardName:" +shardMemberName
                print e
                sleep(sleepBetweenRetriesInSecs)
                continue
            finally:
                j=j+1

        if(dict[ip]!=None):
            break;
        i=i+1

    return dict

#
#Given a shardname (e.g. shard-inventory-config), number of shards and an ip
#determines if its a leader
#
#
def isLeader(shardName,numOfShards,numOfRetries,sleepFor,port,ipAddress):
    ip = getClusterRoles(shardName,numOfShards,numOfRetries,sleepFor,port,ipAddress)
    print ip
    if( ip[ipAddress] == 'Leader'):
         return True

    return False

#
# Returns the leader of the shard given a set of IPs
# Or None
#
def getLeader(shardName,numOfShards=3,numOfTries=3,sleepBetweenRetriesInSecs=1,port=8181,*ips):
    for i in range(3): # Try 3 times to find a leader
        dict = getClusterRoles(shardName,numOfShards,numOfTries,sleepBetweenRetriesInSecs,port,*ips)
        for ip in dict.keys():
            if(dict[ip]=='Leader'):
                return ip

    return None

#
# Returns the follower list of a shard given a set of IPs
# Or []
#
def getFollowers (shardName,numOfShards=3,numOfTries=3,sleepBetweenRetriesInSecs=1,port=8181,*ips):
    dict = getClusterRoles(shardName,numOfShards,numOfTries,sleepBetweenRetriesInSecs,port,*ips)
    result = []

    for ip in dict.keys():
        if(dict[ip]=='Follower'):
            result.append(ip)

    return result
#
#Given a shardname (e.g. shard-inventory-config), number of shards and an ip
#determines if its a leader
#
#
def isFollower(shardName,numOfShards,numOfRetries,sleepFor,port,ipAddress):
    ip = getClusterRoles(shardName,numOfShards,numOfRetries,sleepFor,port,ipAddress)
    print ip
    if( ip[ipAddress] == 'Follower'):
        return True

    return False


def testGetClusterRoles():
    dict = getClusterRoles("shard-inventory-config",3,1,1,8181,"10.194.126.116","10.194.126.117","10.194.126.118")
    print dict

    for ip in dict.keys():
        if(isLeader("shard-inventory-config",3,1,1,8181,ip)):
            print ( ip + " is Leader")
        elif (isFollower("shard-inventory-config",3,1,1,8181,ip)):
            print (ip + " is follower")
        else:
            print (ip + " seems to have value "+ str(dict[ip]))

def testGetLeader ():
  leader =  getLeader("shard-inventory-config",3,1,1,8181,"10.194.126.116","10.194.126.117","10.194.126.118")
  print leader
  return leader

def testGetFollowers():
   followers = getFollowers("shard-inventory-config",3,1,1,8181,"10.194.126.116","10.194.126.117","10.194.126.118")
   print followers
   return followers

#testGetClusterRoles()
#testGetLeader()
#testGetFollowers()











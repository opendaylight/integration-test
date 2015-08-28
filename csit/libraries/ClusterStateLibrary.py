__author__ = "Basheeruddin Ahmed"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "syedbahm@cisco.com"

import SettingsLibrary
from time import sleep
import UtilLibrary
import json
import sys


def getClusterRoles(shardName, numOfShards=3, numOfTries=3, sleepBetweenRetriesInSecs=3, port=8181, *ips):
    """Given a shardname (e.g. shard-inventory-config), number of shards and bunch of ips

    determines what role each ip has in an Akka (Raft based) cluster
    result would look like
    {'10.194.126.118':'Leader', '10.194.126.118':'Follower', '10.194.126.117': None}
    """
    dict = {}
    for ip in ips:
        i = 1
        dict[ip] = None
        print "numOfShards => " + str(numOfShards)
        while i <= numOfShards:
            shardMemberName = "member-" + str(i) + "-" + shardName
            j = 1
            print 'j => ' + str(j)
            print 'numOfTries => ' + str(numOfTries)
            while int(j) <= int(numOfTries):
                print("Try number " + str(j))
                try:
                    print("getting role of " + ip + "  for shardName = " + shardMemberName)
                    url = SettingsLibrary.getJolokiaURL(ip, str(port), str(i), shardName)
                    print url
                    resp = UtilLibrary.get(url)
                    print(resp)
                    if resp.status_code != 200:
                        sleep(sleepBetweenRetriesInSecs)
                        continue
                    print(resp.text)
                    data = json.loads(resp.text)
                    if 'value' in data:
                        dataValue = data['value']
                        print("datavalue RaftState is", dataValue['RaftState'])
                        dict[ip] = dataValue['RaftState']
                except:
                    e = sys.exc_info()[0]
                    print("Try" + str(j) + ":An error occurred when finding leader on" + ip +
                          " for shardName:" + shardMemberName)
                    print(e)
                    sleep(sleepBetweenRetriesInSecs)
                    continue
                finally:
                    j = j + 1
            if dict[ip] is not None:
                break
            i = i + 1
    return dict


def isRole(role,  shardName, ipAddress, numOfShards=3, numOfRetries=1, sleepFor=3, port=8181):
    """Given a role (Leader, Follower, Candidate, or IsolatedLeader),
    shardname (e.g. shard-inventory-config), controller IP address,
    and number of shards on the controller,this function determines if the controller,
    has that role for the specified shard.
    """
    ip = getClusterRoles(shardName, numOfShards, numOfRetries, sleepFor, port, ipAddress)
    print(ip)
    if ip[ipAddress] == role:
        return True
    return False


def getLeader(shardName, numOfShards=3, numOfTries=3, sleepBetweenRetriesInSecs=1, port=8181, *ips):
    """Returns the leader of the shard given a set of IPs Or None"""
    for i in range(3):  # Try 3 times to find a leader
        dict = getClusterRoles(shardName, numOfShards, numOfTries, sleepBetweenRetriesInSecs, port, *ips)
        for ip in dict.keys():
            if dict[ip] == 'Leader':
                return ip
    return None


def getFollowers(shardName, numOfShards=3, numOfTries=3, sleepBetweenRetriesInSecs=1, port=8181, *ips):
    """Returns the follower list of a shard given a set of IPs Or []"""
    for i in range(6):  # Try 6 times to find all followers
        dict = getClusterRoles(shardName, numOfShards, numOfTries, sleepBetweenRetriesInSecs, port, *ips)
        result = []

        for ip in dict.keys():
            if dict[ip] == 'Follower':
                result.append(ip)
        print "i=", i, "result=", result
        if (len(result) == (len(ips) - 1)):
            break
        sleep(1)
    return result


def testGetClusterRoles():
    dict = getClusterRoles("shard-inventory-config", 3, 1, 1, 8181,
                           "10.194.126.116", "10.194.126.117", "10.194.126.118")
    print(dict)

    for ip in dict.keys():
        if isRole("Leader", "shard-inventory-config", 3, 1, 1, 8181, ip):
            print(ip + " is Leader")
        elif isRole("Follower", "shard-inventory-config", 3, 1, 1, 8181, ip):
            print(ip + " is follower")
        else:
            print(ip + " seems to have value " + str(dict[ip]))


def testGetLeader():
    leader = getLeader("shard-inventory-config", 3, 1, 1, 8181,
                       "10.194.126.116", "10.194.126.117", "10.194.126.118")
    print leader
    return leader


def testGetFollowers():
    followers = getFollowers("shard-inventory-config", 3, 1, 1, 8181,
                             "10.194.126.116", "10.194.126.117", "10.194.126.118")
    print(followers)
    return followers

# testGetClusterRoles()
# testGetLeader()
# testGetFollowers()

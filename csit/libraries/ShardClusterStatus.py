import json
import sys


__author__ = "Zdenko Olsovsky"
__copyright__ = "Copyright(c) 2016, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "zolsovsk@cisco.com"

def Find_leader_in_car_shard_status(response, yolokiaLeader=None):
    if yolokiaLeader != None:
        jsonData = json.loads(response)
        leaderIp = jsonData["node-cluster-shard-info"]["node-cluster-current"]["owner"]
        if yolokiaLeader == leaderIp:
            return True
        else:
            return False

def Assert_Node_State(role=None,response=None):
   if role == "Leader":
       jsonData = json.loads(response)
       leaderIp = jsonData["node-cluster-shard-info"]["node-cluster-current"]["owner"]
       nodes = jsonData["node-cluster-shard-info"]["ownership-change-history"]
       for node in nodes:
           if node["id"] == leaderIp:
               isOwner = node["isOwner"]
               hasOwner = node["hasOwner"]
               if isOwner == 1:
                   if hasOwner == 1:
                       return True
               else:
                    return False
   elif role == "Follower":
       jsonData = json.loads(response)
       leaderIp = jsonData["node-cluster-shard-info"]["node-cluster-current"]["owner"]
       nodes = jsonData["node-cluster-shard-info"]["ownership-change-history"]
       for node in nodes:
           if node["id"] != leaderIp:
               isOwner = node["isOwner"]
               hasOwner = node["hasOwner"]
               if isOwner == 0:
                   if hasOwner != 1:
                        return False
               else:
                   return False
       return True
   else:
       print "Role not provided."
       raise ValueError


#!/usr/bin/python

#
# Copyright (c) 2016 NEC Corporation and others
# All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this
# distribution, and is available at http://www.eclipse.org/legal/epl-v10.html
#

import requests
import json
import sys
import re


# response code to check the rest calls
RESP_GET_SUCCESS = 200
RESP_NOT_FOUND = 404


con_header = {'Accept': 'application/json', 'content-type': 'application/json'}
authentication = ('admin', 'admin')


def validate_cluster(ipaddress):
    """ method to check the cluster status
    Args:
        ipaddress(str): ip address of the ODL controller
    """
    url = "http://" + ipaddress + ":8181/jolokia/read/akka:type=Cluster"
    try:
        resp = requests.get(url, headers=con_header, auth=authentication)
    except requests.exceptions.RequestException:
        print ("controller is unreachable")
        sys.exit(1)

    if resp.status_code == RESP_NOT_FOUND:
        print ("jolokia not installed, resp code", resp.status_code)
        print ("Problem with accessing jolokia")
        sys.exit(1)

    elif resp.status_code != RESP_GET_SUCCESS:
        print ("error in getting response, resp code", resp.status_code)
        sys.exit(1)

    data = json.loads(resp.content)
    cluster_status = data['value']['ClusterStatus']
    status = json.loads(cluster_status)
    members = status['members']
    member_list = []
    entity_owner_list = []

    for member in members:
        # spliting the ip address of the node from json object
        # sample json data
        # "akka.tcp://opendaylight-cluster-data@10.106.138.137:2550"
        ip = re.search('@(.+?):', member['address']).group(1)
        node_status = ip + "-" + member['status']
        member_list.append(node_status)
        url1 = "http://" + ip +\
               ":8181/jolokia/read/org.opendaylight.controller:"\
               "Category=ShardManager,name=shard-manager-operational,"\
               "type=DistributedOperationalDatastore"
        resp1 = requests.get(url1, headers=con_header, auth=authentication)
        if resp1.status_code != RESP_GET_SUCCESS:
            print ("error in getting response for the node", ip)
            print ("response content", resp1.content)
            continue
        data2 = json.loads(resp1.content)
        member_role = data2['value']['MemberName']
        entity_owner_list.append(ip + ":" + member_role)
    leader = data['value']['Leader']

    leaderNode = leader[leader.index('@') + 1:leader.rindex(':')]
    for leader_node in member_list:
        address = leader_node.split('-')
        if address[0] == leaderNode:
            print ("=================== Leader Node ======================\n")
            print (leader_node)
            member_list.remove(leader_node)
            print ("=================== Follower Node ====================\n")
            print (member_list)
    list_entity_owners(ipaddress, entity_owner_list)


def list_entity_owners(ipaddress, entity_owner_list):
    """ method to list the entity owners
    Args:
        ipaddress(str): ip address of the ODL controller
        entity_owner_list(list): list of member role in cluster
    """
    entity = ":8181/restconf/operational/entity-owners:entity-owners"
    url = "http://" + ipaddress + entity
    resp = requests.get(url, headers=con_header, auth=authentication)
    if resp.status_code != RESP_GET_SUCCESS:
        print ("controller is down, resp_code", resp.status_code)
        print ("response content", resp.content)
        sys.exit(1)
    data = json.loads(resp.content)
    ovsdb = data['entity-owners']['entity-type']
    print ("\n\n=================== Entity Details ===================\n")
    for e_type in ovsdb:
        entities = e_type['entity']
        for entity in entities:
            id = entity['id']
            if len(entity['owner']) > 0:
                print ("NODE ID", str(id[id.rindex('=') + 2:len(id) - 2]))
                print ("OWNER", str(entity['owner']))
            for owner in entity_owner_list:
                owner_role = owner.split(':')
                if entity['owner'] == owner_role[1]:
                    print ("IP Address", str(owner_role[0]))
                    print ("\n")

# Main Block
if __name__ == '__main__':
    print ('*****Cluster Status******')
    ipaddress = raw_input("Please enter ipaddress to find Leader Node : ")
    validate_cluster(ipaddress)

else:
    print ("Cluster checker loaded as Module")

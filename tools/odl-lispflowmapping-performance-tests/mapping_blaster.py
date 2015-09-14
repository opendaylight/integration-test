#!/usr/bin/python
"""
Script to add LISP mappings to ODL Lithium.  Currently it only supports the
RPC interface.  Support for RESTCONF is planned in a future release.

Use `./mapping_blaster.py --help` to see options

Code inspired from `flow_config_blaster.py` by Jan Medved
"""
__author__ = "Lori Jakab"
__copyright__ = "Copyright (c) 2014, Cisco Systems, Inc."
__credits__ = ["Jan Medved"]
__license__ = "New-style BSD"
__email__ = "lojakab@cisco.com"
__version__ = "0.0.2"

import argparse
import copy
import json
import math

import netaddr
import requests

class MappingRPCBlaster(object):
    putheaders = {'Content-type': 'application/json'}
    getheaders = {'Accept': 'application/json'}

    RPCURL     = 'restconf/operations/lfm-mapping-database:'
    TIMEOUT    = 10

    # Template for adding mappings
    add_mapping_template = {
        u'input': {
            u'recordTtl': 60,
            u'maskLength': 32,
            u'authoritative': True,
            u'action': u'NoAction',
            u'LispAddressContainer': {
                u'Ipv4Address': {
                    u'afi': 1,
                    u'Ipv4Address': u'10.0.0.0'
                }
            },
            u'LocatorRecord': [
                {
                    u'name': u'ipv4:172.16.0.0',
                    u'priority': 1,
                    u'weight': 1,
                    u'multicastPriority': 255,
                    u'multicastWeight': 0,
                    u'localLocator': True,
                    u'rlocProbed': False,
                    u'routed': True,
                    u'LispAddressContainer': {
                        u'Ipv4Address': {
                            u'afi': 1,
                            u'Ipv4Address': u'172.16.0.0'
                        }
                    }
                }
            ]
        }
    }

    # Template for getting mappings
    get_mapping_template = {
        u'input': {
            u'LispAddressContainer': {
                u'Ipv4Address': {
                    u'afi': 1,
                    u'Ipv4Address': u'10.0.0.0'
                }
            },
            u'mask-length': 32
        }
    }

    def __init__(self, host, port, start_eid, mask, start_rloc, nmappings):
        self.host = host
        self.port = port
        self.start_eid = netaddr.IPAddress(start_eid)
        self.mask = mask
        self.start_rloc = netaddr.IPAddress(start_rloc)
        self.nmappings = nmappings

        self.post_url_template = 'http://' + self.host + ':' + self.port + '/' + self.RPCURL

    def create_mapping_from_template(self, eid, mask, rloc):
        """
        Create an add-mapping RPC input dictionary from the mapping template
        """
        mapping = copy.deepcopy(self.add_mapping_template['input'])
        mapping['maskLength'] = mask
        mapping['LispAddressContainer']['Ipv4Address']['Ipv4Address'] = str(netaddr.IPAddress(eid))
        mapping['LocatorRecord'][0]['name'] = 'ipv4:' + str(netaddr.IPAddress(rloc))
        mapping['LocatorRecord'][0]['LispAddressContainer']['Ipv4Address']['Ipv4Address'] = str(netaddr.IPAddress(rloc))
        return mapping

    def send_rpc(self, session, method, body):
        rpc_url = self.post_url_template + method
        r = session.post(rpc_url, data=body, headers=self.putheaders, stream=False,
                auth=('admin', 'admin'), timeout=self.TIMEOUT)
        return r.status_code

    def add_n_mappings(self):
        rpc = dict(self.add_mapping_template)
        s = requests.Session()
        increment = pow(2, 32 - int(self.mask))
        for i in range(self.nmappings):
            rpc['input'] = self.create_mapping_from_template(self.start_eid + i * increment, self.mask,
                    self.start_rloc + i)
            rpc_json = json.dumps(rpc)
            r = self.send_rpc(s, 'add-mapping', rpc_json)
        s.close()

    def get_n_mappings(self):
        rpc = dict(self.get_mapping_template)
        s = requests.Session()
        increment = pow(2, 32 - int(self.mask))
        for i in range(self.nmappings):
            eid = self.start_eid + i * increment
            rpc['input']['LispAddressContainer']['Ipv4Address']['Ipv4Address'] = str(netaddr.IPAddress(eid))
            rpc['input']['mask-length'] = self.mask
            rpc_json = json.dumps(rpc)
            r = self.send_rpc(s, 'get-mapping', rpc_json)
        s.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Add simple IPv4 prefix-to-IPv4 locator LISP mappings to OpenDaylight')

    parser.add_argument('--mode', default='add',
                        help='Operating mode, can be "add" or "get" (default is "add")')
    parser.add_argument('--host', default='127.0.0.1',
                        help='Host where ODL controller is running (default is 127.0.0.1)')
    parser.add_argument('--port', default='8181',
                        help='Port on which ODL\'s RESTCONF is listening (default is 8181)')
    parser.add_argument('--start-eid', default='10.0.0.0',
                        help='Start incrementing EID from this address (default is 10.0.0.0)')
    parser.add_argument('--mask', default='32',
                        help='Network mask for the IPv4 EID prefixes (default is 32)')
    parser.add_argument('--start-rloc', default='172.16.0.0',
                        help='Start incrementing RLOC from this address (default is 172.16.0.0, ignored for "get")')
    parser.add_argument('--mappings', type=int, default=1,
                        help='Number of mappings to add/get (default 1)')

    in_args = parser.parse_args()

    mapping_rpc_blaster = MappingRPCBlaster(in_args.host, in_args.port, in_args.start_eid, in_args.mask,
            in_args.start_rloc, in_args.mappings)

    if in_args.mode == "add":
        mapping_rpc_blaster.add_n_mappings()
    elif in_args.mode == "get":
        mapping_rpc_blaster.get_n_mappings()
    else:
        print "Unsupported mode:", in_args.mode

#!/usr/bin/python
"""
Script to add LISP mappings to ODL.  Currently it only supports the
RPC interface.  Support for RESTCONF is planned in a future release.

Use `./mapping_blaster.py --help` to see options

Code inspired from `flow_config_blaster.py` by Jan Medved
"""

import argparse
import copy
import json
import math

import netaddr
import requests

__author__ = "Lori Jakab"
__copyright__ = "Copyright (c) 2014, Cisco Systems, Inc."
__credits__ = ["Jan Medved"]
__license__ = "New-style BSD"
__email__ = "lojakab@cisco.com"
__version__ = "0.0.3"


class MappingRPCBlaster(object):
    putheaders = {'Content-type': 'application/json'}
    getheaders = {'Accept': 'application/json'}

    RPCURL_LI = 'restconf/operations/lfm-mapping-database:'
    RPCURL_BE = 'restconf/operations/mappingservice:'
    TIMEOUT = 10

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

    def __init__(self, host, port, start_eid, mask, start_rloc, nmappings, v):
        """
        Args:
            :param host: The host running ODL where we want to send the RPCs
            :param port: The RESTCONF port on the ODL host
            :param start_eid: The starting EID for adding mappings as an IPv4
                literal
            :param mask: The network mask for the EID prefixes to be added
            :param start_rloc: The starting RLOC for the locators in the
                mappings as an IPv4 literal
            :param nmappings: The number of mappings to be generated
            :param v: Version of the ODL instance (since the RPC URL changed
                from Lithium to Beryllium
        """
        self.host = host
        self.port = port
        self.start_eid = netaddr.IPAddress(start_eid)
        self.mask = mask
        self.start_rloc = netaddr.IPAddress(start_rloc)
        self.nmappings = nmappings
        if v == "Li" or v == "li":
            print "Using the Lithium RPC URL"
            rpc_url = self.RPCURL_LI
        else:
            print "Using the Beryllium and later RPC URL"
            rpc_url = self.RPCURL_BE

        self.post_url_template = 'http://' + self.host + ':' \
            + self.port + '/' + rpc_url

    def mapping_from_tpl(self, eid, mask, rloc):
        """Create an add-mapping RPC input dictionary from the mapping template
        Args:
            :param eid: Replace the default EID in the template with this one
            :param mask: Replace the default mask in the template with this one
            :param rloc: Replace the default RLOC in the template with this one
        Returns:
            :return dict: mapping - template modified with the arguments
        """
        mapping = copy.deepcopy(self.add_mapping_template['input'])
        mapping['maskLength'] = mask
        mapping['LispAddressContainer']['Ipv4Address']['Ipv4Address'] \
            = str(netaddr.IPAddress(eid))
        mapping['LocatorRecord'][0]['name'] = 'ipv4:' \
            + str(netaddr.IPAddress(rloc))
        address_container = mapping['LocatorRecord'][0]['LispAddressContainer']
        address_container['Ipv4Address']['Ipv4Address'] \
            = str(netaddr.IPAddress(rloc))
        return mapping

    def send_rpc(self, session, method, body):
        """Send an HTTP POST to the RPC URL and return the status code
        Args:
            :param session: The HTTP session handle
            :param method: "add" or "del"ete mapping
            :param body: the JSON body to be sent
        Returns:
            :return int: status_code - HTTP status code
        """
        rpc_url = self.post_url_template + method
        r = session.post(rpc_url, data=body, headers=self.putheaders,
                         stream=False, auth=('admin', 'admin'),
                         timeout=self.TIMEOUT)
        return r.status_code

    def add_n_mappings(self):
        """Add self.nmappings mappings to ODL
        """
        rpc = dict(self.add_mapping_template)
        s = requests.Session()
        increment = pow(2, 32 - int(self.mask))
        for i in range(self.nmappings):
            rpc['input'] = self.mapping_from_tpl(self.start_eid + i *
                                                 increment, self.mask,
                                                 self.start_rloc + i)
            rpc_json = json.dumps(rpc)
            r = self.send_rpc(s, 'add-mapping', rpc_json)
        s.close()

    def get_n_mappings(self):
        """Retrieve self.nmappings mappings from ODL
        """
        rpc = dict(self.get_mapping_template)
        s = requests.Session()
        increment = pow(2, 32 - int(self.mask))
        for i in range(self.nmappings):
            eid = self.start_eid + i * increment
            rpc['input']['LispAddressContainer']['Ipv4Address']['Ipv4Address']\
                = str(netaddr.IPAddress(eid))
            rpc['input']['mask-length'] = self.mask
            rpc_json = json.dumps(rpc)
            r = self.send_rpc(s, 'get-mapping', rpc_json)
        s.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Add simple IPv4 \
        prefix-to-IPv4 locator LISP mappings to OpenDaylight')

    parser.add_argument('--mode', default='add',
                        help='Operating mode, can be "add" or "get" \
                            (default is "add")')
    parser.add_argument('--host', default='127.0.0.1',
                        help='Host where ODL controller is running (default \
                            is 127.0.0.1)')
    parser.add_argument('--port', default='8181',
                        help='Port on which ODL\'s RESTCONF is listening \
                            (default is 8181)')
    parser.add_argument('--start-eid', default='10.0.0.0',
                        help='Start incrementing EID from this address \
                            (default is 10.0.0.0)')
    parser.add_argument('--mask', default='32',
                        help='Network mask for the IPv4 EID prefixes \
                            (default is 32)')
    parser.add_argument('--start-rloc', default='172.16.0.0',
                        help='Start incrementing RLOC from this address \
                            (default is 172.16.0.0, ignored for "get")')
    parser.add_argument('--mappings', type=int, default=1,
                        help='Number of mappings to add/get (default 1)')
    parser.add_argument('--odl-version', default='Be',
                        help='OpenDaylight version, can be "Li" or "Be" \
                            (default is "Be")')

    in_args = parser.parse_args()

    mapping_rpc_blaster = MappingRPCBlaster(in_args.host, in_args.port,
                                            in_args.start_eid, in_args.mask,
                                            in_args.start_rloc,
                                            in_args.mappings,
                                            in_args.odl_version)

    if in_args.mode == "add":
        mapping_rpc_blaster.add_n_mappings()
    elif in_args.mode == "get":
        mapping_rpc_blaster.get_n_mappings()
    else:
        print "Unsupported mode:", in_args.mode

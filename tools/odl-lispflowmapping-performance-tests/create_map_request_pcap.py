#!/usr/bin/env python
"""
Script to generate a pcap file with n Map-Request packets with EID records
increasing sequentially and another pcap file with n Map-Request packets that
have random EIDs

Use `./create_map_request_pcap.py --help` to see options
"""

import argparse
import netaddr
from lisp import *

__author__ = "Lori Jakab"
__copyright__ = "Copyright (c) 2015, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "lojakab@cisco.com"
__version__ = "0.0.2"


def generate_eids_random(base, n):
    eids = []
    for i in range(0, n):
        eids.append(str(netaddr.IPAddress(base) +
                        random.randint(0, (n-1)*increment)))
    return eids


def generate_eids_sequential(base, n):
    eids = []
    for i in range(0, n):
        eids.append(str(netaddr.IPAddress(base) + i*increment))
    return eids


def generate_map_request(eid):
    sport1 = random.randint(60000, 65000)
    sport2 = random.randint(60000, 65000)
    rnonce = random.randint(0, 2**63)

    itr_rloc = [LISP_AFI_Address(address=src_rloc, afi=1)]
    record = [LISP_MapRequestRecord(request_address=eid,
                                    request_afi=1,
                                    eid_mask_len=32)]

    packet = Ether(dst=dst_mac, src=src_mac)
    packet /= IP(dst=dst_rloc, src=src_rloc)
    packet /= UDP(sport=sport1, dport=4342)
    packet /= LISP_Encapsulated_Control_Message(ptype=8)
    packet /= IP(dst=eid, src=src_eid)
    packet /= UDP(sport=sport2, dport=4342)
    packet /= LISP_MapRequest(nonce=rnonce, request_afi=1, address=src_eid,
                              ptype=1, itr_rloc_records=itr_rloc,
                              request_records=record)
    return packet

parser = argparse.ArgumentParser(description='Create a Map-Request trace file')

parser.add_argument('--dst-mac', default='00:00:00:00:00:00',
                    help='Map-Request destination MAC address \
                        (default is 00:00:00:00:00:00)')
parser.add_argument('--src-mac', default='00:00:00:00:00:00',
                    help='Map-Request source MAC address \
                        (default is 00:00:00:00:00:00)')
parser.add_argument('--dst-rloc', default='127.0.0.1',
                    help='Send Map-Request to the Map-Server with this RLOC \
                        (default is 127.0.0.1)')
parser.add_argument('--src-rloc', default='127.0.0.1',
                    help='Send Map-Request with this source RLOC \
                        (default is 127.0.0.1)')
parser.add_argument('--src-eid', default='192.0.2.1',
                    help='Send Map-Request with this source EID \
                        (default is 192.0.2.1)')
parser.add_argument('--base-eid', default='10.0.0.0',
                    help='Start incrementing EID from this address \
                        (default is 10.0.0.0)')
parser.add_argument('--requests', type=int, default=1,
                    help='Number of requests to create (default 1)')
parser.add_argument('--increment', type=int, default=1,
                    help='Increment EID requests (default 1)')

in_args = parser.parse_args()
dst_mac = in_args.dst_mac
src_mac = in_args.src_mac
dst_rloc = in_args.dst_rloc
src_rloc = in_args.src_rloc
src_eid = in_args.src_eid
increment = in_args.increment

rand_eids = generate_eids_random(in_args.base_eid, in_args.requests)
#seq_eids = generate_eids_sequential(in_args.base_eid, in_args.requests)
rand_pkts = []
seq_pkts = []

for eid in rand_eids:
    rand_pkts.append(generate_map_request(eid))

#for eid in seq_eids:
#    seq_pkts.append(generate_map_request(eid))

wrpcap("encapsulated-map-requests-random.pcap", rand_pkts)
#wrpcap("encapsulated-map-requests-sequential.pcap", seq_pkts)

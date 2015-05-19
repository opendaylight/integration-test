#!/usr/bin/env python

import sys
import netaddr

__author__ = "Sandeep Gangadharan"
__copyright__ = "(c) Copyright [2015] Hewlett-Packard \
                Development Company, L.P."
__license__ = "Eclipse Public License "
__email__ = "sandeep.gangadharan@hp.com"
__created__ = "19 March 2014"

"""
    create_fullymesh.py:
    Description : Creates Fully mesh mininet topology.
    Input       : switch_count, host count per switch, base mac address,
                  base ip address
    Output      : switch.py (A python topology file)
    Note       :  This is a fully mesh network. Not available in
                  mininet by default. Hence generating a python file
                  dynamically which represents the topology.

"""

if len(sys.argv) < 5:
    print("Please povide correct inputs. Exiting!!!")
    print "{0}  <switch_count> <host_per_switch> <base_mac: Eg:00:4b:00:00:00:00 > \
          <base_ip: Eg:75.75.0.0>".format(sys.argv[0].split('/')[-1])
    print "Dpid of switches is derived from base mac and \
           host ip address is derived from base ip"
    sys.exit(1)

switch_count = int(sys.argv[1])
host_per_switch = int(sys.argv[2])
base_mac = sys.argv[3]
base_host_ip = sys.argv[4]

base_host_mac = base_mac.split(':')
base_host_mac[0] = '10'
base_host_mac = (':').join(base_host_mac)
dpid_mac = base_mac.split(':')
dpid_mac = ('').join(dpid_mac)


def new_mac(mac, offset):
    """
    Description: This function increments an existing mac address by offset
    and returns the new mac
    :param mac: Mac address with each hex separated by a colon
                (Eg: 00:01:02:03:04:05
    :param offset: Increment the mac to this offset value
    :return: new mac in same format as input mac.
    """
    mac = netaddr.EUI(mac).value
    mac = mac + offset
    mac = str(netaddr.EUI(mac)).replace('-', ':')
    return mac


def new_ip(ip, offset):
    """
    Description: This function increments an existing ip address by offset
    and returns the new ip
    :param ip: Ipv4 address string
    :param offset: increment value of IP
    :rtype : new Ipv4 address string after incrementing by offset
    """
    ip = netaddr.IPAddress(ip)
    return ip.__add__(offset)


def new_dpid(mac, offset):
    """
    Description: This function is for returns a new dpid by
    incrementing a mac address by offset value.
    :param mac: mac address separated by colon
    :param offset: increment value
    :return: New dpid
    """
    mac = netaddr.EUI(mac).value
    mac = mac + offset
    mac = str(netaddr.EUI(mac)).replace('-', ':')
    dpid_mac = mac.split(':')
    dpid_mac = ('').join(dpid_mac)
    DPID = "0000" + dpid_mac
    return DPID


if __name__ == "__main__":
    DPID = new_dpid(base_mac, 1)
    HMAC = new_mac(base_host_mac, 1)
    HIP = new_ip(base_host_ip, 1)
    prefix = 8
    configfile = open("switch.py", 'w')
    configfile.write('\"\"\"@author: sandeep gangadharan\n             \
    This topology has {0:d} switches {1:d} hosts                       \
    \nThis topology is made out of {2:s} script                        \
    \nThis is a fully mesh topology. Not available in mininet by default.\
    \nHence generating this python file dynamically\"\"\"     \
    \nfrom mininet.topo import Topo\nclass DemoTopo(Topo):          \
    \n'.format(switch_count, switch_count * host_per_switch, sys.argv[0]))
    print "This topology has %d switches %d hosts" \
          % (switch_count, switch_count * host_per_switch)
    configfile.write("    def __init__(self):\n ")
    configfile.write("        #  Initialize topology\n")
    configfile.write("        Topo.__init__(self)\n")
    configfile.write("        #  Add Switches\n")
    # Add switches
    for i in range(1, switch_count + 1):
        configfile.write("        s{0:d} = self.addSwitch(\'s{1:d}\',dpid=\'{2:s}\')\
            \n".format(i, i, DPID))
        DPID = new_dpid(base_mac, i + 1)

    # Add hosts
    configfile.write("        #  Add Hosts\n")
    for i in range(1, switch_count + 1):
        for j in range(1, host_per_switch + 1):
            configfile.write("        self.addLink(s{0:d}, \
                self.addHost('s{1:d}h{2:d}',\
                ip='{3:s}',mac='{4:s}',prefixLen='{5:d}'))\n"
                             .format(i, i, j, HIP, HMAC, prefix))
            HMAC = new_mac(HMAC, 1)
            HIP = new_ip(HIP, 1)

    #  Add Links
    configfile.write("  #  Add Links\n")
    count = 0
    for i in range(1, switch_count + 1):
        if i == 1:
            continue
        for j in range(1, i + 1):
            if i != j:
                configfile.write("        self.addLink(s{0:d}, s{1:d})\
                \n".format(i, j))
    configfile.write("topos = { 'demotopo': ( lambda: DemoTopo() ) }")
    configfile.close()

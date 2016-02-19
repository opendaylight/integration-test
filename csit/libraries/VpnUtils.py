#! /usr/bin/python

##############################################################################
# Copyright (c) 2015 Ericsson SDN Team.  All rights reserved.
#
##############################################################################

import re
import os
import json
from RequestsLibrary import RequestsLibrary
from Openstack import Openstack

"""
from RequestsLibrary import *
from Openstack import Openstack
Library for the robot based system test tool of the Ericsson SDN Project.
 This library provides L3VPN service functions
"""
__author__ = "Chandra Bammidi"
__copyright__ = "Copyright 2016, Ericsson"
__version__ = "1.0.1"


param = "openstackconfig"
ost = __import__(param)

res = RequestsLibrary()


class VpnUtils(Openstack):
    """This class is used for creating vpn service related entities with different options"""
    global res
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'

    def __init__(self, odlip, logger=None):
        Openstack.__init__(self, odlip, logger=None)
        self.enablelog = 0
        if logger is not None:
            self.logger = logger
            self.enablelog = 1
        self.nindex = 0
        self.ipdigit = 1
        self.l3vpnurl = ost.L3VPNREST
        self.l3vpnnamelist = {}
        self.vpnsession = "VPNSession"
        baseurl1 = "http://" + self.ODLIP + ":" + ost.RESTCONFPORT
        self.sid = res.create_session(self.vpnsession,
                                      baseurl1,
                                      headers=ost.HEADERS,
                                      auth=ost.AUTH)
        self.tntId = ost.TENANT_ID
        self.l3vpnId = "4ae8cd92-48ca-49b5-94e1-b2921a26"
        self.networkjson = {}

    def logmessage(self, mesg, mtype=0, *argv):
        """It is helper function used inside the main functions"""
        if len(argv) > 0:
            for x in argv:
                mesg += " " + str(x)
        if self.enablelog == 1:
            if mtype == 0:
                self.logger.info(mesg)
            else:
                self.logger.error(mesg)
        else:
            print mesg

    def get_interfaceConfigData(self):
        """This function gets the ietf interface config data from config data store"""
        odlurl = "/restconf/config/ietf-interfaces:interfaces/"
        resp = res.get(self.vpnsession, odlurl)
        print resp.content
        self.logmessage("All vlan interfaces config datastore ", 0,
                        resp.content)
        return resp

    def get_interfaceOperState(self):
        """This function gets the ietf interface states from operational data store"""
        odlurl = "/restconf/operational/ietf-interfaces:interfaces-state/"
        resp = res.get(self.vpnsession, odlurl)
        print resp.content
        self.logmessage("All vlan interfaces operational state ", 0,
                        resp.content)
        return resp

    def get_nodeInventory(self):
        """This function gets the node inventory from operational data store"""
        odlurl = "/restconf/operational/opendaylight-inventory:nodes/"
        resp = res.get(self.vpnsession, odlurl)
        print resp.content
        self.logmessage("Node inventory data ", 0, resp.content)
        return resp

    def create_l3vpn(self, name, RD, importRT, exportRT):
        """It creates the L3VPN and parameters are as shown below.
           name --->  Name of  the network
           nettype --->  Network type, if you don't pass this, it takes default value as local
           i.e create_l3vpn(self, name,RD,importRT,exportRT)"""
        retval = 0
        self.nindex += 1
        l3vpnid = self.l3vpnId + str(self.nindex).zfill(4)
        neutron_l3vpn = {"input": {
            "l3vpn": [
                {
                    "id": l3vpnid,
                    "name": name,
                    "route-distinguisher": RD,
                    "export-RT": exportRT,
                    "import-RT": importRT,
                    "tenant-id": self.tntId
                }
            ]
        }}

        self.logmessage("JASON structure of neutron_network", 0, neutron_l3vpn)
        odlurl = self.l3vpnurl + ":createL3VPN"
        try:
            neutron_l3vpn = json.dumps(neutron_l3vpn)
            resp = res.post(self.vpnsession, odlurl, data=neutron_l3vpn)
        except Exception as e:
            self.logmessage("Create L3VPN Exception is", 0, e)
            retval += 1
            return retval

        self.logmessage("Response Content is", 0, resp.content)
        self.logmessage("Response Code is", 0, resp.status_code)
        if resp.status_code == 200:
            self.logmessage("Create L3VPN is SUCCESS for uuid", 0, l3vpnid)
            self.l3vpnnamelist[name] = l3vpnid
            return l3vpnid
        else:
            self.logmessage("Create L3VPN is FAILED for uuid", 1, l3vpnid)
            retval += 1
            return l3vpnid

    def getOVS_DpnIds(self, brname):
        """This function gets the dpn id from operational data store"""
        dpnId = None
        odlurl = "/restconf/operational/odl-interface-meta:bridge-ref-info/"
        try:
            resp = res.get(self.vpnsession, odlurl)
        except Exception as e:
            self.logmessage(" Exception is", 0, e)
        self.logmessage("Response is", 0, resp)
        self.logmessage("Response Content is", 0, resp.content)
        self.logmessage("Response Code is", 0, resp.status_code)
        try:
            ret = json.loads(resp.content)["bridge-ref-info"][
                "bridge-ref-entry"]
        except Exception as e:
            self.logmessage(" Exception is", 0, e)
            return dpnId
        foundbr = 0
        for dr in ret:
            for k, val in dr.items():
                self.logmessage("", 0, k)
                self.logmessage("", 0, val)
                if re.search(brname, str(val)):
                    foundbr = 1
                    dpnId = dr['dpid']
                    self.logmessage("Dpn id is", 0, dpnId)
                    break
            if foundbr == 1:
                break
        return dpnId

    def getL3vpn(self, vpnname):
        """It Gets L3VPN information .
           i.e getL3vpn(vpnname)"""
        retval = 0
        vpnid = self.l3vpnnamelist[vpnname]
        get_l3vpn = {"input": {"id": vpnid}}

        self.logmessage("JASON structure of neutron_network", 0, get_l3vpn)
        odlurl = self.l3vpnurl + ":getL3VPN"
        try:
            get_l3vpn = json.dumps(get_l3vpn)
            resp = res.post(self.vpnsession, odlurl, data=get_l3vpn)
        except Exception as e:
            self.logmessage("getL3vpn Exception is", 0, e)
            retval += 1
            return retval

        self.logmessage("Response Content is", 0, resp.content)
        self.logmessage("Response Code is", 0, resp.status_code)
        if resp.status_code == 200:
            self.logmessage("Get L3VPN  is SUCCESS for uuid", 0, vpnid)
            return resp.content
        else:
            self.logmessage("Get L3VPN is FAILED for uuid", 1, vpnid)
            retval += 1
            return retval

    def deleteL3vpn(self, vpnname):
        """It deletes the L3vpn.
           vpnname --->  Name of  the vpn"""
        retval = 0
        vpnid = self.l3vpnnamelist[vpnname]
        get_l3vpn = {"input": {"id": [vpnid]}}

        self.logmessage("JASON structure of neutron_network", 0, get_l3vpn)
        odlurl = self.l3vpnurl + ":deleteL3VPN"
        try:
            get_l3vpn = json.dumps(get_l3vpn)
            resp = res.post(self.vpnsession, odlurl, data=get_l3vpn)
        except Exception as e:
            self.logmessage("deleteL3vpn Exception is", 0, e)
            retval += 1
            return retval

        self.logmessage("Response Content is", 0, resp.content)
        self.logmessage("Response Code is", 0, resp.status_code)
        if resp.status_code == 200:
            self.logmessage("Delete L3vpn is SUCCESS for uuid", 0, vpnid)
        else:
            self.logmessage("Delete L3vpn  is FAILED for uuid", 1, vpnid)
            retval += 1
        return retval

    def modify_l3vpn(self, name, RD, importRT, exportRT):
        """It modifies the l3vpn name.
           i.e modify_l3vpn(name,RD,importRT,exportRT)"""
        retval = 0
        self.nindex += 1
        l3vpnid = self.l3vpnId + str(self.nindex).zfill(4)
        neutron_l3vpn = {"input": {
            "l3vpn": [
                {
                    "id": l3vpnid,
                    "name": name,
                    "route-distinguisher": RD,
                    "export-RT": exportRT,
                    "import-RT": importRT,
                    "tenant-id": self.tntId
                }
            ]
        }}

        self.logmessage("JASON structure of neutron_network", 0, neutron_l3vpn)
        odlurl = "/restconf/operations/neutronvpn:createL3VPN"
        try:
            resp = res.put(self.vpnsession, odlurl, data=neutron_l3vpn)
        except Exception as e:
            self.logmessage("Create Network Exception is", 0, e)
            retval += 1
            return retval

        self.logmessage("Response Content is", 0, resp.content)
        self.logmessage("Response Code is", 0, resp.status_code)
        if resp.status_code == 200:
            self.logmessage("Create Network is SUCCESS for uuid", 0, l3vpnid)
            self.l3vpnnamelist[name] = l3vpnid
            return l3vpnid
        else:
            self.logmessage("Create Network is FAILED for uuid", 1, l3vpnid)
            retval += 1
            return l3vpnid

    def get_all_tunnels(self):
        """ It returns all vxlan or gre tunnel Information"""
        retval = 0
        odlurl = "/restconf/config/itm:transport-zones/"
        try:
            resp = res.get(self.vpnsession, odlurl)
        except Exception as e:
            self.logmessage("Get all tunnels Excemption is", 0, e)
            retval += 1
            return retval
        self.logmessage("Response Content is", 0, resp.content)
        self.logmessage("Response Code is", 0, resp.status_code)
        if resp.status_code == 200:
            self.logmessage("Get all tunnels is SUCCESS ", 0)
            return resp
        else:
            self.logmessage("Get all tunnels is FAILED ", 1)
            retval += 1
            return retval

    def delete_all_tunnels(self):
        """ It deletes all vxlan or gre tunnels"""
        retval = 0
        odlurl = "/restconf/config/itm:transport-zones/"
        try:
            resp = res.delete(self.vpnsession, odlurl)
        except Exception as e:
            self.logmessage("Delete all tunnel Excemption is", 0, e)
            retval += 1
            return retval
        self.logmessage("Response Content is", 0, resp.content)
        self.logmessage("Response Code is", 0, resp.status_code)
        if resp.status_code == 200:
            self.logmessage("Delete all tunnel is SUCCESS ", 0)
            return retval
        else:
            self.logmessage("Delete all tunnel is FAILED ", 1)
            retval += 1
            return retval

    def create_tunnel(self, **kwargs):
        """It creates gre or vxlan tunnel .parameters are as shown below.
           **kwargs --> It accepts the key word arguments as like below.
           srcip --->  tunnel source ip
           dstip --->  tunnel dest ip
           and similarly source and destination bridge, gateway ip, vlanid, tunnel-type and zone name"""
        retval = 0
        srcbr = "BR1"
        dstbr = "BR2"
        gwip = "0.0.0.0"
        vlanid = 0
        tuntype = "odl-interface:tunnel-type-gre"
        zname = "TZA"
        if kwargs is not None:
            for k, val in kwargs.iteritems():
                print "%s == %s" % (k, val)
                if k == 'srcip':
                    srcip = val
                if k == 'dstip':
                    dstip = val
                if k == 'srcbr':
                    srcbr = val
                if k == 'dstbr':
                    dstbr = val
                if k == 'gwip':
                    gwip = val
                if k == 'vlanid':
                    vlanid = val
                if k == 'tuntype':
                    tuntype = val
                if k == 'zname':
                    zname = val

        # Get tunnel bridge ids
        m = re.search('\d+\.\d+\.\d+', srcip)
        if m:
            prefix_val = m.group() + ".0/24"
        else:
            self.logmessage("Source IP is not proper", 0, srcip)
            retval += 1
            return retval

        dpnId1 = self.getOVS_DpnIds(srcbr)
        if dpnId1 is None:
            self.logmessage("Source Bridge is None", 0)
            retval += 1
            return retval
        dpnId2 = self.getOVS_DpnIds(dstbr)
        if dpnId2 is None:
            self.logmessage("Destination  Bridge is None", 0)
            retval += 1
            return retval

        gre_tunnel = {
            "transport-zone": [
                {
                    "zone-name": zname,
                    "subnets": [
                        {
                            "prefix": prefix_val,
                            "vlan-id": vlanid,
                            "vteps": [
                                {
                                    "dpn-id": dpnId1,
                                    "portname": "phy0",
                                    "ip-address": srcip
                                }, {
                                    "dpn-id": dpnId2,
                                    "portname": "phy1",
                                    "ip-address": dstip
                                }
                            ],
                            "gateway-ip": gwip
                        }
                    ],
                    "tunnel-type": tuntype
                }
            ]
        }

        self.logmessage("JASON structure of neutron_network", 0, gre_tunnel)
        odlurl = "/restconf/config/itm:transport-zones/"
        try:
            gre_tunnel = json.dumps(gre_tunnel)
            resp = res.post(self.vpnsession, odlurl, data=gre_tunnel)
        except Exception as e:
            self.logmessage("Create gre tunnel Excemption is", 0, e)
            retval += 1
            return retval

        self.logmessage("Response Content is", 0, resp.content)
        self.logmessage("Response Code is", 0, resp.status_code)
        if resp.status_code == 204:
            self.logmessage("Create gre tunnel is SUCCESS ", 0)
            return retval
        else:
            self.logmessage("Create gre tunnel is FAILED ", 1)
            retval += 1
            return retval

    def associate_network(self, netname, name):
        """It associates the network with the given vpn.
           Interface parameters are as shown below.
           nwname --->  Name of  the network
           vpnid ---> vpn instance id which was created"""
        retval = 0
        self.logmessage("Response Info:", 0, self.netnameList)
        vpnid = self.l3vpnnamelist[name]
        uuid = self.netnameList[netname]
        net_ass_conf = {"input": {"vpn-id": vpnid, "network-id": [uuid]}}

        self.logmessage("JSON value of l3vpn", 0, net_ass_conf)
        odlurl5 = "/restconf/operations/neutronvpn:associateNetworks"
        try:
            net_ass_conf = json.dumps(net_ass_conf)
            resp = res.post(self.vpnsession, odlurl5, data=net_ass_conf)
        except Exception as e:
            self.logmessage("Create Network Exception is", 0, e)
            retval += 1
            return retval
        self.logmessage("Response Info:", 0, resp)
        self.logmessage("Port Resp Status code:", 0, resp.status_code)
        self.logmessage("Port Info:", 0, resp.content)
        if resp.status_code == self.postresp:
            self.logmessage("Associate network through uuid is passed")
            return uuid
        else:
            self.logmessage("Associate network through uuid")
            retval += 1
            return uuid

    def dissociate_network(self, netname, name):
        """It dissociates the network with the given vpn.
           Interface parameters are as shown below.
           nwname --->  Name of  the network
           vpnid ---> vpn instance id which was created"""
        retval = 0
        uuid = self.netnameList[netname]
        vpnid = self.l3vpnnamelist[name]
        net_ass_conf = {"input": {"vpn-id": vpnid, "network-id": [uuid]}}

        self.logmessage("JSON value of l3vpn", 0, net_ass_conf)
        odlurl5 = "/restconf/operations/neutronvpn:dissociateNetworks"
        try:
            net_ass_conf = json.dumps(net_ass_conf)
            resp = res.post(self.vpnsession, odlurl5, data=net_ass_conf)
        except Exception as e:
            self.logmessage("Create Network Exception is", 0, e)
            retval += 1
            return retval
        self.logmessage("Response Info:", 0, resp)
        self.logmessage("Port Resp Status code:", 0, resp.status_code)
        self.logmessage("Port Info:", 0, resp.content)
        if resp.status_code == self.postresp:
            self.logmessage("Dissociate network through uuid is passed")
            return uuid
        else:
            self.logmessage("Dissociate network through uuid")
            return uuid
            retval += 1

    def __del__(self):
        self.logmessage("Cleanup the class, closing the REST connection", 0)
        self.sid.close()
        self.datastore.close()

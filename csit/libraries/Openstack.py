#! /usr/bin/python

import re
import json
from RequestsLibrary import RequestsLibrary
import pickle
from random import choice

# Library for the robot based system test tool of the Ericsson SDN Project.
#######################################################################
# Description: This library provides Openstack simulator functions    #
#######################################################################
__author__ = "Chandra Bammidi"
__copyright__ = "Copyright 2015, Ericsson"
__version__ = "1.0.1"


param = "openstackconfig"
ost = __import__(param)

res = RequestsLibrary()


class Openstack(object):
    """This class is used for creating neutron networks,subnets and ports with different options"""
    global res
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'

    def __init__(self, odlip, logger=None):
        self.enablelog = 0
        if logger is not None:
            self.logger = logger
            self.enablelog = 1
        # self.serverIp = ost.TEST_SERVER_IP
        self.imagetype = ost.imagetype
        self.MANUALIP_CONFIG = ost.MANUALIP_CONFIG
        self.uname = ost.TEST_SERVER_USERNAME
        self.pword = ost.TEST_SERVER_PASSWORD
        self.runame = ost.REMOTE_SERVER_USERNAME
        self.rpword = ost.REMOTE_SERVER_PASSWORD
        self.VMPrompt = ost.CERROS_VMPROMPT
        self.true = 1
        self.threadList = []
        self.false = 0
        self.null = ""
        self.nindex = 0
        self.sindex = 0
        self.pindex = 0
        self.routerindex = 0
        self.dindex = 0
        self.macindex = 0
        self.tapindex = 0
        self.ipdigit = 1
        self.interfaceindex = 0
        self.ODLIP = odlip
        if ost.ODL_DATASTORE_CONFIG == "YES":
            self.datastoreconfig = "YES"
        else:
            self.datastoreconfig = "NO"
        if ost.ODL_DATASTORE_CONFIG == "YES":
            self.postresp = ost.POST_RESPONSE_CODE
            self.delresp = ost.DELETE_RESPONSE_CODE
        else:
            self.postresp = ost.POST_RESPONSE_CODE_15A
            self.delresp = ost.DELETE_RESPONSE_CODE_15A
        self.updateresp = ost.UPDATE_RESPONSE_CODE
        self.getresp = ost.GET_RESPONSE_CODE
        self.odlsession = "ODLSession"
        self.odlsession1 = "ODLSession1"
        if self.datastoreconfig == "YES":
            baseurl = "http://" + self.ODLIP + ":" + ost.RESTCONFPORT
        else:
            baseurl = "http://" + self.ODLIP + ":" + ost.PORT
        print baseurl
        if self.datastoreconfig == "YES":
            self.odlneutron = ost.ODLNEUTRON_DATA
        else:
            self.odlneutron = ost.ODLNEUTRON
        self.sid = res.create_session(self.odlsession,
                                      baseurl,
                                      headers=ost.HEADERS,
                                      auth=ost.AUTH)
        baseurl1 = "http://" + self.ODLIP + ":" + ost.RESTCONFPORT
        self.datastore = res.create_session(self.odlsession1,
                                            baseurl1,
                                            headers=ost.HEADERS,
                                            auth=ost.AUTH)
        self.tntId = ost.TENANT_ID
        self.networkList = {}
        self.subnetIdList = []
        self.subnetIpList = {}
        self.routerIdList = []
        self.netnameList = {}
        self.netnamePortList = {}
        self.portMacList = {}
        self.routernameList = {}
        self.deviceIdPortNameList = {}
        self.subnetnameList = {}
        self.portnameList = {}
        self.portnamesubnetList = {}
        self.interfaceNameList = {}
        self.tapportnameList = {}
        self.portnameIpList = {}
        self.tapPorts = []
        self.vmpids = {}
        self.vmMacs = {}
        self.vmTapports = {}
        self.tntRTRId = 'e09818e7-a05a-4963-9927-fc1dc6f1'
        self.tntNet_SEGM = '1062'
        self.tntNetId = '12809f83-ccdf-422c-a20a-4ddae071'
        self.l3vpnId = "4ae8cd92-48ca-49b5-94e1-b2921a26"
        self.tntSubnetId = '6c496958-a787-4d8c-9465-f4c41766'
        self.tntNetPortId1 = '79ad'
        self.tntNetPortId2 = '-19e0-489c-9505-cc70f9eb'
        self.tntNetPortMac = 'FA:16:3E:8F:'
        self.tntNetTapPort = 'tap79ad'
        self.tntVM_PORT_ID = '341ceaca-24bf-4017-9b08-c3180e86'
        self.tntVM_MAC = 'FA:16:3E:8E:B8:'
        self.intfRouterId = "c8ff831f-7b97-40f0-a7b6-21cd5aff"
        self.tntRouterId = '5971a821-f8f0-4771-ae4c-7f132ba5'
        self.tntVM_DEVICE_ID = '20e500c3-41e1-4be0-b854-55c710a1'
        self.tntVM_ID = '20e500c3-41e1-4be0-b854-55c710a1'
        self.networkjson = {}

    def x(self):
        """It is helper function used inside the main functions"""
        X = choice("0123456789ABCDEF")
        return str(X)

    def mac(self):
        """It is helper function used inside the main functions"""
        macaddr = "00:16:3E" + ":" + self.x() + self.x() + ":" + self.x(
        ) + self.x() + ":" + self.x() + self.x()
        return macaddr

    def saveObject(self, obj):
        """It is helper function used inside the main functions"""
        fp = open("openstackobject.txt", 'w')
        pickle.dump(obj, fp)
        fp.close()

    def getObject(self):
        """It is helper function used inside the main functions"""
        fp = open("openstackobject.txt", 'r')
        return pickle.load(fp)

    def getNeutronPorts(self):
        """It is helper function used inside the main functions"""
        return self.portnameIpList

    def getTapPorts(self):
        """It is helper function used inside the main functions"""
        return self.tapportnameList

    def getNeutronPortMac(self, portname):
        """It is helper function used inside the main functions"""
        netportid = self.portnameList[portname]
        return self.portMacList[netportid]

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

    def create_router(self, routername):
        """It creates the router with given name.
        Args:
           :param routername:  Name of  the router
        Returns:
           It returns 0 if it success and returns number > 0 if it fails.
           i.e create_router(routername)"""
        retval = 0
        self.routerindex += 1
        routerId = self.tntRouterId + str(self.routerindex).zfill(4)

        if self.datastoreconfig == "NO":
            neutron_router = {
                "router": {
                    "status": "ACTIVE",
                    "name": routername,
                    "gw_port_id": '',
                    "admin_state_up": 'true',
                    "routes": [],
                    "tenant_id": self.tntId,
                    "id": routerId
                }
            }
        else:
            neutron_router = {
                "router": {
                    "status": "ACTIVE",
                    "name": routername,
                    "admin-state-up": 'true',
                    "routes": [],
                    "tenant-id": self.tntId,
                    "uuid": routerId
                }
            }
        self.logmessage("JSON value of neutron_router", 0, neutron_router)
        odlurl = self.odlneutron + "routers/"
        try:
            neutron_router = json.dumps(neutron_router)
            resp = res.post(self.odlsession, odlurl, data=neutron_router)
        except Exception as e:
            self.logmessage("Create Network Exception is", 0, e)
            retval += 1
            return retval
        self.routernameList[routername] = routerId
        self.logmessage("Response Info:", 0, resp)
        self.logmessage("Port Resp Status code:", 0, resp.status_code)
        self.logmessage("Response Content", 0, resp.content)
        self.logmessage("Router name to uuid list", 0, self.portnameList)
        if resp.status_code == self.postresp:
            self.logmessage("Create Neutron Router with uuid", 0, routerId,
                            "  is success")
        else:
            self.logmessage("Create Neutron Router with uuid", 1, routerId,
                            "  is Failed")
            retval += 1
        return retval

    def create_network(self, netname, **kwargs):
        """It creates the network with given name.
        Args:
           :param netname:   Name of  the network
           :param nettype:   Network type, if you don't pass this, it takes default value as local
           :param **kwargs:  Keyword arguments to specify network type. like vlan_trans = "true"
        Returns:
           It returns 0 if it success and returns number > 0 if it fails.
           i.e create_network("mynetwork1", vlan_trans = "true")"""
        retval = 0
        self.nindex += 1
        self.subnetIdList = []
        transvlan = "false"
        networktype = "local"
        tntNetId = self.tntNetId + str(self.nindex).zfill(4)
        self.networkList[tntNetId] = self.subnetIdList
        self.netnameList[netname] = tntNetId
        if kwargs is not None:
            for k, val in kwargs.iteritems():
                print "%s == %s" % (k, val)
                if k == 'vlan_trans':
                    transvlan = val
                if k == 'nettype':
                    networktype = val

        if self.datastoreconfig == "NO":
            neutron_network = {
                "network": {
                    "shared": "false",
                    "vlan_transparent": transvlan,
                    "name": netname,
                    "id": tntNetId,
                    "tenant_id": self.tntId,
                    "admin_state_up": "true",
                    "router:external": "false",
                    "provider:network_type": networktype,
                    'provider:segmentation_id': None,
                    "status": "ACTIVE",
                    "subnets": self.subnetIdList
                }
            }
        else:
            neutron_network = {
                "network": {
                    "shared": "false",
                    "vlan-transparent": transvlan,
                    "name": netname,
                    "uuid": tntNetId,
                    "tenant-id": self.tntId,
                    "admin-state-up": "true",
                    "router:external": "false",
                    "provider:network-type": networktype,
                    'provider:segmentation-id': None,
                    "status": "ACTIVE",
                    "subnets": self.subnetIdList
                }
            }

        self.networkjson[netname] = neutron_network
        self.logmessage("JASON structure of neutron_network", 0,
                        neutron_network)
        odlurl = self.odlneutron + "networks/"
        try:
            neutron_network = json.dumps(neutron_network)
            resp = res.post(self.odlsession, odlurl, data=neutron_network)
        except Exception as e:
            self.logmessage("Create Network Exception is", 0, e)
            self.networkList = {}
            self.netnameList = {}
            self.subnetIdList = []
            retval += 1
            return retval

        self.logmessage("Response Content is", 0, resp.content)
        self.logmessage("Response Code is", 0, resp.status_code)
        if resp.status_code == self.postresp:
            self.logmessage("Create Network is SUCCESS for uuid", 0, tntNetId)
        else:
            self.logmessage("Create Network is FAILED for uuid", 1, tntNetId)
            retval += 1
        self.logmessage("Network List", 0, self.networkList)
        self.logmessage("Netname List", 0, self.netnameList)
        return retval

    def update_network(self, netname, newname):
        """It updates the network name with new given name.
        Args:
           netname --->  Name of  the network
           newname --->  New name of the network
        Returns:
           returns 0 if it success and 1 if it fails
        i.e update_network("mynetwork", "mynewnetowrk")"""
        retval = 0
        tntNetId = self.netnameList[netname]
        if self.datastoreconfig == "NO":
            neutron_update_network = {
                "networks": {
                    "network": {
                        "shared": "false",
                        "name": newname,
                        "id": tntNetId,
                        "tenant_id": self.tntId,
                        "admin_state_up": "true",
                        "subnets": self.subnetIdList
                    }
                }
            }

        else:
            neutron_update_network = {
                "networks": {
                    "network": {
                        "shared": "false",
                        "name": newname,
                        "uuid": tntNetId,
                        "tenant-id": self.tntId,
                        "admin-state-up": "true",
                        "subnets": self.subnetIdList
                    }
                }
            }

        self.logmessage("JSON value of neutron_subnet", 0,
                        neutron_update_network)
        odlurl = self.odlneutron + "networks/"
        try:
            resp = res.put(self.odlsession,
                           odlurl,
                           data=neutron_update_network)
            print resp
            self.logmessage("Update Network Info:", 0, resp.content)
        except Exception as e:
            self.logmessage("Update Network Exception is", 0, e)
            retval += 1
            return retval
        if resp.status_code == self.updateresp:
            self.logmessage("Update Network with uuid", 0, tntNetId,
                            "  is success")
            self.sindex += 1
        else:
            self.logmessage("Update Network with uuid", 0, tntNetId,
                            "  is Failed")
            retval += 1
        return retval

    def get_networks(self):
        """ It returns all Network Information"""
        odlurl = self.odlneutron + "networks/"
        resp = res.get(self.odlsession, odlurl)
        self.logmessage("All networks", 0, resp.content)
        return resp

    def get_network(self, netname):
        """ It returns Network Information specified in input paramater"""
        netuid = self.netnameList[netname]
        odlurl = self.odlneutron + "networks/" + netuid + "/"
        resp = res.get(self.odlsession, odlurl)
        self.logmessage("All networks", 0, resp.content)
        return resp

    def get_network_ids(self):
        """It returns List of network uuids which are configured on the node"""
        uuidlist = []
        odlurl = self.odlneutron + "networks/"
        resp = res.get(self.odlsession, odlurl)
        self.logmessage("All networks", 0, resp.content)
        try:
            ret = json.loads(resp.content)['networks']
        except Exception as e:
            print e
            return uuidlist
        if self.datastoreconfig == "YES":
            if ret:
                ret = ret['network']
        for x in ret:
            if self.datastoreconfig == "NO":
                if x['id']:
                    uuidlist.append(str(x['id']))
            else:
                if x['uuid']:
                    uuidlist.append(str(x['uuid']))
        print uuidlist
        return uuidlist

    def get_subnets(self):
        """It returns List of subnets which are configured on the node"""
        odlurl = self.odlneutron + "subnets/"
        resp = res.get(self.odlsession, odlurl)
        print resp.content
        self.logmessage("All sub networks", 0, resp.content)
        return resp

    def get_subnet(self, subnetname):
        """ It returns Subnet Information specified in input paramater"""
        subid = self.subnetnameList[subnetname]
        odlurl = self.odlneutron + "subnets/" + subid + "/"
        resp = res.get(self.odlsession, odlurl)
        print resp.content
        self.logmessage("All sub networks", 0, resp.content)
        return resp

    def get_subnet_params(self, subnetname, param):
        """ It returns Subnet Information specific to input paramater"""
        paramValue = None
        subid = self.subnetnameList[subnetname]
        odlurl = self.odlneutron + "subnets/" + subid + "/"
        resp = res.get(self.odlsession, odlurl)
        print resp.content
        self.logmessage("All sub networks", 0, resp.content)
        try:
            ret = json.loads(resp.content)['subnet']
        except Exception as e:
            print e
            return paramValue
        if self.datastoreconfig == "YES":
            if ret:
                ret = ret['subnet']
        if param in ret.keys():
            paramValue = str(ret[param])
        return paramValue

    def get_subnet_ids(self):
        """It returns List of subnet uuids which are configured on the node"""
        uuidlist = []
        odlurl = self.odlneutron + "subnets/"
        resp = res.get(self.odlsession, odlurl)
        print resp.content
        self.logmessage("All sub networks", 0, resp.content)
        try:
            ret = json.loads(resp.content)['subnets']
        except Exception as e:
            print e
            return uuidlist
        if self.datastoreconfig == "YES":
            if ret:
                ret = ret['subnet']
        for x in ret:
            if self.datastoreconfig == "NO":
                if x['id']:
                    uuidlist.append(str(x['id']))
            else:
                if x['uuid']:
                    uuidlist.append(str(x['uuid']))
        print uuidlist
        return uuidlist

    def get_port_ids(self):
        """It returns List of port uuids which are configured on the node"""
        uuidlist = []
        odlurl = self.odlneutron + "ports/"
        resp = res.get(self.odlsession, odlurl)
        self.logmessage("All neutron ports:", 0, resp.content)
        try:
            ret = json.loads(resp.content)['ports']
        except Exception as e:
            print e
            return uuidlist
        if self.datastoreconfig == "YES":
            if ret:
                ret = ret['port']
        for x in ret:
            if self.datastoreconfig == "NO":
                if x['id']:
                    uuidlist.append(str(x['id']))
            else:
                if x['uuid']:
                    uuidlist.append(str(x['uuid']))
        print uuidlist
        return uuidlist

    def get_router_ids(self):
        """It returns List of router uuids which are configured on the node"""
        uuidlist = []
        odlurl = self.odlneutron + "routers/"
        resp = res.get(self.odlsession, odlurl)
        self.logmessage("All neutron router:", 0, resp.content)
        ret = json.loads(resp.content)['routers']
        if self.datastoreconfig == "YES":
            if ret:
                ret = ret['router']
        for x in ret:
            if self.datastoreconfig == "NO":
                if x['id']:
                    uuidlist.append(str(x['id']))
            else:
                if x['uuid']:
                    uuidlist.append(str(x['uuid']))
        print uuidlist
        return uuidlist

    def get_ports(self):
        """ It returns List of ports Information which are configured on the node"""
        odlurl = self.odlneutron + "ports/"
        resp = res.get(self.odlsession, odlurl)
        self.logmessage("All neutron ports:", 0, resp.content)
        print resp.content
        return resp

    def get_port(self, portname):
        """ It returns Subnet Information specified in input paramater"""
        portId = self.portnameList[portname]
        odlurl = self.odlneutron + "ports/" + portId + "/"
        resp = res.get(self.odlsession, odlurl)
        self.logmessage("All neutron ports:", 0, resp.content)
        print resp.content
        return resp

    def delnet(self):
        """ It deletes the networks"""
        retval = 0
        print "===================Deleting the Networks++++++++++++++++++++++"
        netlist = self.get_network_ids()
        for x in netlist:
            self.delete_net(None, x)
        return retval

    def delsub(self):
        """ It deletes the subnets"""
        retval = 0
        print "===================Deleting the Subnets++++++++++++++++++++++"
        subnetlist = self.get_subnet_ids()
        for x in subnetlist:
            self.delete_subnet(None, x)
        return retval

    def delport(self):
        """ It deletes the ports"""
        retval = 0
        print "===================Deleting the Ports++++++++++++++++++++++"
        portlist = self.get_port_ids()
        for x in portlist:
            print x
            self.delete_port(None, x)
        return retval

    def logAllOpenStackInfo(self):
        """It logs all networks,subnets,ports information maintained by the class.
           i.e logAllOpenStackInfo()"""
        self.logmessage("Netname List", 0, self.netnameList)
        self.logmessage("Sub Netname List", 0, self.subnetnameList)
        self.logmessage("Port name List", 0, self.portnameList)
        self.logmessage("Tab Port name List", 0, self.tapportnameList)
        self.logmessage("Network List", 0, self.networkList)
        self.logmessage("Subnet work Id List", 0, self.subnetIdList)
        self.logmessage("Subnet IP Info:", 0, self.subnetIpList)
        self.logmessage("Network to Port Info:", 0, self.netnamePortList)
        self.logmessage("Port Mac List:", 0, self.portMacList)
        self.logmessage("Tap Port Info:", 0, self.tapPorts)
        self.logmessage("VM to PIDs:", 0, self.vmpids)
        self.logmessage("VM Mac Info:", 0, self.vmMacs)
        self.logmessage("VM Tap Port Info:", 0, self.vmTapports)

    def get_all_networks(self):
        """It gets all  networks,subnets,ports information from the node
            through REST and logs into logfile. i.e get_all_networks()"""
        odlurl = self.odlneutron + "networks/"
        resp = res.get(self.odlsession, odlurl)
        self.logmessage("All networks", 0, resp.content)
        odlurl = self.odlneutron + "subnets/"
        resp = res.get(self.odlsession, odlurl)
        print resp.content
        self.logmessage("All sub networks", 0, resp.content)
        odlurl = self.odlneutron + "ports/"
        resp = res.get(self.odlsession, odlurl)
        self.logmessage("All neutron ports:", 0, resp.content)
        print resp.content
        return resp

    def get_ops_neutron_ports(self):
        """It returns neutron port name and uuid associate list(dictionary)
           i.e get_ops_neutron_ports()"""
        return self.portnameList

    def delete_net(self, netname, uuid=None):
        """It deletes the network with given netname. interface parameters
           are as shown below.
           netname --->  Name of  the network
           i.e delete_net("mynetwork")"""
        retval = 0
        if uuid is None:
            self.logmessage("", 0, self.netnameList)
            uuid = self.netnameList[netname]
        if self.datastoreconfig == "YES":
            odlurl = self.odlneutron + "networks/network/" + uuid
        else:
            odlurl = self.odlneutron + "networks/" + uuid
        try:
            resp = res.delete(self.odlsession, odlurl)
            self.logmessage("Response is:", 0, resp)
        except Exception as e:
            self.logmessage("Delete network exception is", 0, e)
            retval += 1
            return retval
        self.logmessage("Response is:", 0, resp.content)
        self.logmessage("Response is:", 0, resp)
        if resp.status_code == self.delresp:
            self.logmessage("Delete network is SUCCESS for uuid", 0, uuid)
            if netname is not None:
                del self.netnameList[netname]
                del self.networkList[uuid]
            self.logmessage("Network Name to uuid mapping List is:", 0,
                            self.netnameList)
            self.logmessage("Network Name to subnet uuid mapping List is:", 0,
                            self.networkList)
        else:
            self.logmessage("Delete Network is FAILED for uuid", 1, uuid)
            retval += 1
        return retval

    def delete_subnet(self, subnetname, uuid=None):
        """It deletes the sub network with given subnetwork name.
           interface parameters are as shown below.
           subnetname --->  Name of  the sub network which
                            is going to be created
           i.e delete_subnet("mysubnet1")"""
        retval = 0
        if uuid is None:
            uuid = self.subnetnameList[subnetname]
        if self.datastoreconfig == "NO":
            odlurl = self.odlneutron + "subnets/" + uuid
        else:
            odlurl = self.odlneutron + "subnets/subnet/" + uuid
        try:
            resp = res.delete(self.odlsession, odlurl)
        except Exception as e:
            self.logmessage("Delete network exception is", 0, e)
            retval += 1
            return retval
        self.logmessage("Response is:", 0, resp.content)
        self.logmessage("Response is:", 0, resp)
        if resp.status_code == self.delresp:
            self.logmessage("Delete subnet network is SUCCESS for uuid", 0,
                            uuid)
            if subnetname is not None:
                del self.subnetnameList[subnetname]
                del self.subnetIpList[uuid]
            self.logmessage("Subnet Name to uuid mapping List is:", 0,
                            self.subnetnameList)
            self.logmessage("Subnet IP to uuid mapping List is:", 0,
                            self.subnetIpList)
        else:
            self.logmessage("Delete subnet Network is FAILED for uuid", 1,
                            uuid)
            retval += 1
        return retval

    def delete_router(self, routername, uuid=None):
        """It deletes the port with given port name.
           Interface parameters are as shown below.
           portname --->  Name of  the  port
           i.e delete_subnet("mysubnet1")"""
        retval = 0
        if uuid is None:
            uuid = self.routernameList[routername]
        if self.datastoreconfig == "NO":
            odlurl = self.odlneutron + "routers/" + uuid
        else:
            odlurl = self.odlneutron + "routers/" + uuid
        try:
            resp = res.delete(self.odlsession, odlurl)
        except Exception as e:
            self.logmessage("Delete Router exception is", 0, e)
            retval += 1
            return retval
        self.logmessage("Response is:", 0, resp.content)
        self.logmessage("Response is:", 0, resp)
        if resp.status_code == self.delresp:
            self.logmessage("Delete Port is SUCCESS for uuid", 0, uuid)
            if routername is not None:
                del self.routernameList[routername]
            self.logmessage("Router Name to uuid mapping List is:", 0,
                            self.routernameList)
        else:
            self.logmessage("Delete Port is FAILED for uuid", 1, uuid)
            retval += 1
        return retval

    def delete_port(self, portname, uuid=None):
        """It deletes the port with given port name.
           Interface parameters are as shown below.
           portname --->  Name of  the  port
           i.e delete_subnet("mysubnet1")"""
        retval = 0
        if uuid is None:
            uuid = self.portnameList[portname]
        if self.datastoreconfig == "NO":
            odlurl = self.odlneutron + "ports/" + uuid
        else:
            odlurl = self.odlneutron + "ports/port/" + uuid
        try:
            resp = res.delete(self.odlsession, odlurl)
        except Exception as e:
            self.logmessage("Delete Port exception is", 0, e)
            retval += 1
            return retval
        self.logmessage("Response is:", 0, resp.content)
        self.logmessage("Response is:", 0, resp)
        if resp.status_code == self.delresp:
            self.logmessage("Delete Port is SUCCESS for uuid", 0, uuid)
            if portname is not None:
                del self.portnameList[portname]
                del self.portMacList[uuid]
            self.logmessage("Port Name to uuid mapping List is:", 0,
                            self.portnameList)
            self.logmessage("Port Mac to uuid mapping List is:", 0,
                            self.portMacList)
            self.logmessage("Network to port uuid mapping List is:", 0,
                            self.netnamePortList)
        else:
            self.logmessage("Delete Port is FAILED for uuid", 1, uuid)
            retval += 1
        return retval

    def delete_net_datastore(self):
        """Delete all Network,subnet,port configuration on the node.
           i.e : delete_all_net()"""
        retval = 0
        odlurl = ost.ODLNEUTRON_DATA + "ports/"
        try:
            resp = res.delete(self.odlsession1, odlurl)
            self.netnamePortList = {}
            self.portMacList = {}
            self.portnameList = {}
            self.pindex = 0
            self.dindex = 0
            self.macindex = 0
            self.logmessage("REST Response", 0, resp)
        except Exception as e:
            print e
            retval += 1
        odlurl = ost.ODLNEUTRON_DATA + "subnets/"
        try:
            resp = res.delete(self.odlsession1, odlurl)
            self.subnetnameList = {}
            self.subnetIpList = {}
            self.sindex = 0
            self.logmessage("REST Response", 0, resp)
        except Exception as e:
            print e
            retval += 1
        odlurl = ost.ODLNEUTRON_DATA + "networks/"
        try:
            resp = res.delete(self.odlsession1, odlurl)
            self.networkList = {}
            self.subnetIdList = []
            self.netnameList = {}
            self.nindex = 0
            self.logmessage("REST Response", 0, resp)
        except Exception as e:
            print e
            retval += 1

        return retval

    def delete_all_net(self):
        """Delete all Network,subnet,port configuration on the node.
           i.e : delete_all_net()"""
        retval = 0
        print "===================Deleting the Ports++++++++++++++++++++++"
        portlist = self.get_port_ids()
        for x in portlist:
            print x
            self.delete_port(None, x)
        print "===================Deleting the Subnets++++++++++++++++++++++"
        subnetlist = self.get_subnet_ids()
        for x in subnetlist:
            self.delete_subnet(None, x)
        print "===================Deleting the Networks++++++++++++++++++++++"
        netlist = self.get_network_ids()
        for x in netlist:
            self.delete_net(None, x)
        return retval

    def create_subnet(self, mynetname, subnetname, subnetip, dhcpflag="true"):
        """It creates the sub network with given name.
           Interface parameters are as shown below.
           mynetname --->  Name of  the network
                           which you are going to create subnet
           subnetname ---> Name of subnetwork name
           subnetip  ----> subnet IP range like 1.1.1.0/24
           dhcpflag --->  DHCP flag which enable DHCP or not,
                        if you don't pass this, it takes default value as false
           i.e create_subnet("mynetwork","mysubnet1", "1.1.1.0/24")"""

        retval = 0
        self.sindex += 1
        netid = self.netnameList[mynetname]
        subnetidlist = self.networkList[netid]
        subnetid = self.tntSubnetId + str(self.sindex).zfill(4)
        subnetidlist.append(subnetid)
        self.networkList[netid] = subnetidlist
        print "Network List : ", self.networkList
        self.subnetIpList[subnetid] = subnetip
        r = '\d{1,3}\.\d{1,3}\.\d{1,3}'
        m = re.search(r, subnetip)
        if m:
            ipdigits = m.group()
            gatewayip = ipdigits + "." + "1"
            startIp = ipdigits + "." + "2"
            endIp = ipdigits + "." + "254"

        if self.datastoreconfig == "NO":
            neutron_subnet = {
                "subnet": {
                    "id": subnetid,
                    "network_id": netid,
                    "name": subnetname,
                    "ip_version": 4,
                    "cidr": subnetip,
                    "gateway_ip": gatewayip,
                    "enable_dhcp": dhcpflag,
                    "dns_nameservers": [],
                    "allocation_pools": [{
                        "start": startIp,
                        "end": endIp
                    }],
                    "host_routes": [],
                    "tenant_id": self.tntId,
                    "ipv6_address_mode": "null",
                    "ipv6_ra_mode": "null"
                }
            }

        else:
            neutron_subnet = {
                "subnet": {
                    "uuid": subnetid,
                    "network-id": netid,
                    "name": subnetname,
                    "ip-version": 4,
                    "cidr": subnetip,
                    "gateway-ip": gatewayip,
                    "enable-dhcp": dhcpflag,
                    "dns-nameservers": [],
                    "allocation-pools": [{
                        "start": startIp,
                        "end": endIp
                    }],
                    "host-routes": [],
                    "tenant-id": self.tntId,
                    "ipv6-ra-mode": "off"
                }
            }

        self.logmessage("JSON value of neutron_subnet", 0, neutron_subnet)
        odlurl = self.odlneutron + "subnets/"
        try:
            neutron_subnet = json.dumps(neutron_subnet)
            resp = res.post(self.odlsession, odlurl, data=neutron_subnet)
        except Exception as e:
            self.logmessage("Create Network Exception is", 0, e)
            retval += 1
            return retval
        self.subnetnameList[subnetname] = subnetid
        self.logmessage("Subnet Info:", 0, resp.content)
        self.logmessage("Status Code is:", 0, resp.status_code)
        if resp.status_code == self.postresp:
            self.logmessage("Create SubNetwork with uuid", 0, subnetid,
                            "  is success")
        else:
            self.logmessage("Create SubNetwork with uuid", 0, subnetid,
                            "  is Failed")
            retval += 1
        return retval

    def update_subnet(self, subnetname, **kwargs):
        """It updates the sub network with given subnet name.
           subnetname ---> Name of subnetwork name
           **kwargs --> It accepts the key word arguments as like below.
               gateway="10.20.123.1", dnsnameservers=["8.8.8.8","9.9.9.9"
           i.e update_subnet("mysubnet1", gateway="10.20.123.1",
                dnsnameservers=["8.8.8.8","9.9.9.9"])
               update_subnet("mysubnet1", enabldhcp = "true")"""
        retval = 0
        subnetid = self.subnetnameList[subnetname]
        subnetip = self.subnetIpList[subnetid]
        r = '\d{1,3}\.\d{1,3}\.\d{1,3}'
        m = re.search(r, subnetip)
        if m:
            ipdigits = m.group()
        subnetgw = ipdigits + '.1'
        subnet_name = subnetname
        servers_list = []
        dhcpflag = 'false'
        allocated_pools = []
        if kwargs is not None:
            for k, val in kwargs.iteritems():
                print "%s == %s" % (k, val)
                if k == 'gateway':
                    subnetgw = val
                if k == 'name':
                    subnet_name = val
                if k == 'dnsnameservers':
                    servers_list = val
                if k == 'enabldhcp':
                    dhcpflag = val
                if k == 'pools':
                    allocated_pools = val
            # Get network id
            for x, v1 in self.networkList.iteritems():
                if subnetid in v1:
                    netid = x
            print netid
            print subnetid

            if len(allocated_pools) > 0:
                poolstart = allocated_pools[0]
            else:
                poolstart = ""
            if len(allocated_pools) > 1:
                poolend = allocated_pools[1]
            else:
                poolend = ""

            if self.datastoreconfig == "NO":
                neutron_update_subnet = {
                    "subnets": {
                        "subnet": [
                            {
                                "enable_dhcp": dhcpflag,
                                "dns_nameservers": servers_list,
                                "allocation_pools": [
                                    {
                                        "start": poolstart,
                                        "end": poolend
                                    }
                                ],
                                "name": subnet_name,
                                "gateway_ip": subnetgw,
                                "network_id": netid,
                                "id": subnetid,
                                "tenant_id": self.tntId,
                                "cidr": subnetip
                            }
                        ]
                    }
                }

            else:
                neutron_update_subnet = {
                    "subnets": {
                        "subnet": [
                            {
                                "enable-dhcp": dhcpflag,
                                "dns-nameservers": servers_list,
                                "allocation-pools": [
                                    {
                                        "start": poolstart,
                                        "end": poolend
                                    }
                                ],
                                "name": subnet_name,
                                "gateway-ip": subnetgw,
                                "network-id": netid,
                                "uuid": subnetid,
                                "tenant-id": self.tntId,
                                "cidr": subnetip
                            }
                        ]
                    }
                }
        else:
            self.logmessage("Arguments are not provided for update", 0)
            return 1

        self.logmessage("JSON value of neutron_subnet", 0,
                        neutron_update_subnet)
        odlurl = self.odlneutron + "subnets/"
        try:
            resp = res.put(self.odlsession, odlurl, data=neutron_update_subnet)
            print resp
            self.logmessage("Update Subnet Info:", 0, resp.content)
        except Exception as e:
            self.logmessage("Update subnet work Exception is", 0, e)
            retval += 1
            return retval
        if resp.status_code == self.updateresp:
            self.logmessage("Update SubNetwork with uuid", 0, subnetid,
                            "  is success")
            self.sindex += 1
        else:
            self.logmessage("Update SubNetwork with uuid", 0, subnetid,
                            "  is Failed")
            retval += 1
        return retval

    def update_port(self, portname, **kwargs):
        """It update the port parameters.
           portname ---> Name of the port
           **kwargs --> It accepts the key word arguments as like below.
               securitygroup = "867e051f-86d3-484f-a5f9-57396878749a",
                extradhcpopts = {'opt_name':'Agentid', 'opt_value':82}
           i.e update_port("myport",
            securitygroup = "867e051f-86d3-484f-a5f9-57396878749a",
                 extradhcpopts = {'opt_name':'Agentid', 'opt_value':82}"""
        retval = 0
        port_name = portname
        extra_dhcp_options = {}
        if kwargs is not None:
            for k, val in kwargs.iteritems():
                print "%s == %s" % (k, val)
                if k == 'securitygroup':
                    security_groups = val
                if k == 'name':
                    port_name = val
                if k == 'extradhcpopts':
                    extra_dhcp_options = val
            netPortId = self.portnameList[portname]
            portMac = self.portMacList[netPortId]
            for x, v1 in self.netnamePortList.iteritems():
                if v1 == netPortId:
                    netname = x
                    break
            netid = self.netnameList[netname]
            print netid
            subnetidlist = self.networkList[netid]
            subnetid = subnetidlist[0]
            deviceid = self.deviceIdPortNameList[portname]

            if len(extra_dhcp_options) > 0:
                extra_dhcp_options_name = extra_dhcp_options.keys()[0]
                extra_dhcp_options_val = extra_dhcp_options[
                    extra_dhcp_options_name]
            else:
                extra_dhcp_options_name = ""
                extra_dhcp_options_val = ""
            if security_groups == "no":
                security_groups_val = ""
            else:
                security_groups_val = security_groups
            if self.datastoreconfig == "NO":
                neutron_update_port = {
                    "ports": {
                        "port": [
                            {
                                "security_groups": [
                                    security_groups_val
                                ],
                                "extra_dhcp_opts": [
                                    {
                                        "opt_value": extra_dhcp_options_val,
                                        "opt_name": extra_dhcp_options_name
                                    }
                                ],
                                "device_id": deviceid,
                                "mac_address": portMac,
                                "name": port_name,
                                "network_id": netid,
                                "id": netPortId,
                                "tenant_id": self.tntId,
                                "admin_state_up": "true",
                                "fixed_ips": [
                                    {
                                        "subnet_id": subnetid
                                    }
                                ]
                            }
                        ]
                    }
                }

            else:
                neutron_update_port = {
                    "ports": {
                        "port": [
                            {
                                "security-groups": [
                                    security_groups_val
                                ],
                                "extra-dhcp-opts": [
                                    {
                                        "opt-value": extra_dhcp_options_val,
                                        "opt-name": extra_dhcp_options_name
                                    }
                                ],
                                "device-id": deviceid,
                                "mac-address": portMac,
                                "name": port_name,
                                "network-id": netid,
                                "uuid": netPortId,
                                "tenant-id": self.tntId,
                                "admin-state-up": "true",
                                "fixed-ips": [
                                    {
                                        "subnet-id": subnetid
                                    }
                                ]
                            }
                        ]
                    }
                }
            self.logmessage("JSON value of neutron_subnet", 0,
                            neutron_update_port)
            odlurl = self.odlneutron + "ports/"
        try:
            resp = res.put(self.odlsession, odlurl, data=neutron_update_port)
            print resp
            self.logmessage("Update Port Info:", 0, resp.content)
        except Exception as e:
            self.logmessage("Update Port Exception is", 0, e)
            retval += 1
            return retval
        if resp.status_code == self.updateresp:
            self.logmessage("Update Port with uuid", 0, subnetid,
                            "  is success")
            self.sindex += 1
        else:
            self.logmessage("Update Port with uuid", 0, subnetid,
                            "  is Failed")
            retval += 1
        return retval

    def associate_interface(self, routername, subnetname, interfacename):
        """It associates the interface which part of subnet and 
           network to router, parameters are as shown below.
           routername --->  Name of  the router
           subnetname ---> Name of the subnet
           intercacename ---> Name of the interface"""
        retval = 0
        self.interfaceindex += 1
        interfaceId = self.intfRouterId + str(self.interfaceindex).zfill(4)
        routerid = self.routernameList[routername]
        subnetid = self.subnetnameList[subnetname]

        if self.datastoreconfig == "NO":
            neutron_interface = {
                {
                    "port_id": "c8dd830f-7b97-40f0-a7b6-21cd5aff502e",
                    "subnet_id": subnetid,
                    "id": "c8ff831f-7b97-40f0-a7b6-21cd5aff0002",
                    "tenant_id": self.tntId
                }
            }
        else:
            neutron_interface = {
                "interfaces": [
                    {
                        "subnet-id": subnetid,
                        "uuid": interfaceId,
                        "tenant-id": self.tntId
                    }
                ]
            }
        self.logmessage("JSON value of neutron_interface", 0,
                        neutron_interface)
        odlurl = self.odlneutron + "routers/router/" + routerid + "/interfaces/"
        try:
            resp = res.put(self.odlsession, odlurl, data=neutron_interface)
        except Exception as e:
            self.logmessage("Create Interface Exception is", 0, e)
            retval += 1
            return retval
        self.interfaceNameList[interfacename] = interfaceId
        self.logmessage("Response Info:", 0, resp)
        self.logmessage("Port Resp Status code:", 0, resp.status_code)
        self.logmessage("Response Content", 0, resp.content)
        self.logmessage("Interface name to uuid list", 0,
                        self.interfaceNameList)
        if resp.status_code == self.postresp:
            self.logmessage("Create Neutron Port with uuid", 0, interfaceId,
                            "  is success")
        else:
            self.logmessage("Create Neutron Port with uuid", 0, interfaceId,
                            "  is Failed")
            retval += 1
        return retval

    def create_port(self, nwname, portname, **kwargs):
        """It creates the port with given name.
           Interface parameters are as shown below.
           nwname --->  Name of  the network
           portname ---> Name of the port
           kwargs ---> Pass keyword arguments to pass options.
           like porttype='subport' etc
           i.e create_port("mynetwork", "myport")"""
        retval = 0
        self.pindex += 1
        self.ipdigit += 1
        self.macindex += 1
        porttype = None
        subnetname = None
        parentport = None
        portvid = 1000
        macaddr = None
        if kwargs is not None:
            for k, val in kwargs.iteritems():
                print "%s == %s" % (k, val)
                if k == 'porttype':
                    porttype = val
                if k == 'subnetname':
                    subnetname = val
                if k == 'parentport':
                    parentport = val
                if k == 'portvid':
                    portvid = val
                if k == 'mac':
                    macaddr = val

        netid = self.netnameList[nwname]
        subnetidlist = self.networkList[netid]
        self.logmessage("Subnet id List is", 0, subnetidlist)
        self.logmessage("Subnet Name List is", 0, self.subnetnameList)
        if subnetname is None:
            subnetid = subnetidlist[0]
        else:
            subnetid = self.subnetnameList[subnetname]
        if porttype == "subport":
            parentportId = self.portnameList[parentport]
            firstpart = parentportId.split('-')[0]
            netPortId = firstpart + self.tntNetPortId2 + str(
                self.pindex).zfill(4)
        else:
            netPortId = self.tntNetPortId1 + str(self.pindex).zfill(
                4) + self.tntNetPortId2 + str(self.pindex).zfill(4)
        self.netnamePortList[nwname] = netPortId
        iplist = self.subnetIpList[subnetid]
        self.logmessage("IP List is", 0, iplist)
        # thirdOct = re.search('(\d+).(\d+).(\d+)', iplist).group(3)
        m = re.search('(\d+).(\d+).(\d+)', iplist)
        ipdigits = m.group()
        ipaddr = ipdigits + "." + str(self.ipdigit)
        if porttype == "subport":
            parentportId = self.portnameList[parentport]
            portMac = self.portMacList[parentportId]
        else:
            if macaddr is None:
                portMac = self.mac()
            else:
                portMac = macaddr
        self.logmessage("Port MAC address is", 0, portMac)
        self.portMacList[netPortId] = portMac
        self.dindex += 1
        deviceId = self.tntVM_DEVICE_ID + str(self.dindex).zfill(4)
        self.logmessage("Port Device id is", 0, deviceId)
        self.portnameList[portname] = netPortId
        self.tapportnameList[portname] = self.tntNetTapPort + str(
            self.pindex).zfill(4) + "-19"
        self.deviceIdPortNameList[portname] = deviceId
        neutron_port_ip = ipaddr
        self.logmessage("Neutron port IP address", 0, neutron_port_ip)
        self.portnameIpList[portname] = neutron_port_ip
        self.logmessage("Tap port info", 0, self.tapportnameList[portname])
        self.logmessage("Tap port name list info", 0, self.tapportnameList)
        if porttype == "subport":
            parentportId = self.portnameList[parentport]

        if self.datastoreconfig == "NO":
            if porttype == "trunk":
                neutron_port = {
                    "port": {
                        "mac_address": portMac,
                        "name": portname,
                        "network_id": netid,
                        "id": netPortId,
                        "trunkport:type": "trunkport",
                        "tenant_id": self.tntId,
                        "admin_state_up": "true",
                        "fixed_ips": [
                            {
                                "subnet_id": subnetid,
                                "ip_address": neutron_port_ip
                            }
                        ]
                    }
                }
            elif porttype == "subport":
                neutron_port = {
                    "port": {
                        "mac_address": portMac,
                        "name": portname,
                        "network_id": netid,
                        "id": netPortId,
                        "trunkport:type": "subport",
                        "trunkport:parent_id": parentportId,
                        "trunkport:vid": portvid,
                        "tenant_id": self.tntId,
                        "admin_state_up": "true",
                        "fixed_ips": [
                            {
                                "subnet_id": subnetid,
                                "ip_address": neutron_port_ip
                            }
                        ]
                    }
                }
            else:
                neutron_port = {
                    "port": {
                        "mac_address": portMac,
                        "name": portname,
                        "network_id": netid,
                        "id": netPortId,
                        "tenant_id": self.tntId,
                        "admin_state_up": "true",
                        "fixed_ips": [
                            {
                                "subnet_id": subnetid,
                                "ip_address": neutron_port_ip
                            }
                        ]
                    }
                }
        else:
            if porttype == "trunk":
                neutron_port = {
                    "port": {
                        "mac_address": portMac,
                        "name": portname,
                        "network_id": netid,
                        "id": netPortId,
                        "trunkport:type": "trunkport",
                        "tenant_id": self.tntId,
                        "admin_state_up": "true",
                        "fixed_ips": [
                            {
                                "subnet_id": subnetid,
                                "ip_address": neutron_port_ip
                            }
                        ]
                    }
                }
            elif porttype == "subport":
                neutron_port = {
                    "port": {
                        "mac_address": portMac,
                        "name": portname,
                        "network_id": netid,
                        "id": netPortId,
                        "trunkport:type": "subport",
                        "trunkport:parent_id": parentportId,
                        "trunkport:vid": portvid,
                        "tenant_id": self.tntId,
                        "admin_state_up": "true",
                        "fixed_ips": [
                            {
                                "subnet_id": subnetid,
                                "ip_address": neutron_port_ip
                            }
                        ]
                    }
                }
            else:
                neutron_port = {
                    "port": {
                        "mac-address": portMac,
                        "name": portname,
                        "network-id": netid,
                        "uuid": netPortId,
                        "tenant-id": self.tntId,
                        "admin-state-up": "true",
                        "fixed-ips": [
                            {
                                "subnet-id": subnetid,
                                "ip-address": neutron_port_ip
                            }
                        ]
                    }
                }
        self.logmessage("JSON value of neutron_port", 0, neutron_port)
        odlurl = self.odlneutron + "ports/"
        print odlurl
        try:
            neutron_port = json.dumps(neutron_port)
            resp = res.post(self.odlsession, odlurl, data=neutron_port)
        except Exception as e:
            self.logmessage("Create Network Exception is", 0, e)
            retval += 1
            return retval
        self.logmessage("Response Info:", 0, resp)
        self.logmessage("Port Resp Status code:", 0, resp.status_code)
        self.logmessage("Port Info:", 0, resp.content)
        self.portnameList[portname] = netPortId
        self.portnamesubnetList[portname] = self.subnetnameList.keys()[
            self.subnetnameList.values().index(subnetid)]
        self.logmessage("Port name list:", 0, self.portnameList)
        self.logmessage("Port Mac list:", 0, self.portMacList)
        if resp.status_code == self.postresp:
            self.logmessage("Create Neutron Port with uuid", 0, netPortId,
                            "  is success")
        else:
            self.logmessage("Create Neutron Port with uuid", 0, netPortId,
                            "  is Failed")
            retval += 1
        return retval

    def associate_network(self, netname, vpnid):
        """It associates the network with the given vpn.
           Interface parameters are as shown below.
           nwname --->  Name of  the network
           vpnid ---> vpn instance id which was created"""
        retval = 0
        self.logmessage("Response Info:", 0, self.netnameList)
        uuid = self.netnameList[netname]
        net_ass_conf = {"input": {"vpn-id": vpnid, "network-id": [uuid]}}

        self.logmessage("JSON value of l3vpn", 0, net_ass_conf)
        odlurl5 = "/restconf/operations/neutronvpn:associateNetworks"
        try:
            net_ass_conf = json.dumps(net_ass_conf)
            resp = res.post(self.odlsession, odlurl5, data=net_ass_conf)
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
        return retval

    def dissociate_network(self, netname, vpnid):
        """It dissociates the network with the given vpn.
           Interface parameters are as shown below.
           nwname --->  Name of  the network
           vpnid ---> vpn instance id which was created"""
        retval = 0
        uuid = self.netnameList[netname]
        # l3vpnid = self.l3vpnId + str(self.nindex).zfill(4)
        net_ass_conf = {"input": {"vpn-id": vpnid, "network-id": [uuid]}}

        self.logmessage("JSON value of l3vpn", 0, net_ass_conf)
        odlurl5 = "/restconf/operations/neutronvpn:dissociateNetworks"
        try:
            net_ass_conf = json.dumps(net_ass_conf)
            resp = res.post(self.odlsession, odlurl5, data=net_ass_conf)
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
        return retval

    def __del__(self):
        self.logmessage("Cleanup the class, closing the REST connection", 0)
        self.sid.close()
        self.datastore.close()

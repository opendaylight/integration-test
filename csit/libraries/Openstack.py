#! /usr/bin/python
#
#Library for the robot based system test tool of the Ericsson SDN Project.
############Description################################################
# This library provides Openstack simulator functions
###################################################################################
__author__      = "Chandra Bammidi"
__copyright__   = "Copyright 2015, Ericsson"
__version__     = "1.0.1"
__status__      = "Production"


import socket
import pexpect
import time
import re
import commands,subprocess
import os,sys,string
import logging
import shutil
import json
import datetime
from threading import Thread
import xml.etree.ElementTree as ET
import stat
from random import choice
from sys import stdin
from RequestsLibrary import *
#import paramiko
import pickle


param = "openstackconfig"
ost = __import__(param)

res = RequestsLibrary()

class Openstack(object):
    global res
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'

    def __init__(self, odlip, logger = None):
        self.enablelog = 0
        if logger is not None:
            self.logger = logger
            self.enablelog = 1
        self.serverIp = ost.TEST_SERVER_IP
        self.imagetype = ost.imagetype
        self.MANUALIP_CONFIG = ost.MANUALIP_CONFIG
        self.hipvsversion = ost.HIPVS_VERSION
        self.uname = ost.TEST_SERVER_USERNAME
        self.pword = ost.TEST_SERVER_PASSWORD
        self.runame = ost.REMOTE_SERVER_USERNAME
        self.rpword = ost.REMOTE_SERVER_PASSWORD
        if os.environ.get('HIPVS') is not None:
            print "Getting Hipvs home dir from environment variables"
            self.hipvshome = os.environ['HIPVS']
        else:
            print "Getting Hipvs home dir from config file"
            self.hipvshome = ost.HIPVS_HOME
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
        self.rhipvshome = ""
        self.ODLIP = odlip
        if ost.ODL_DATASTORE_CONFIG == "YES":
            self.datastoreconfig = "YES"
        else:
            self.datastoreconfig = "NO"
        #Response Codes
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
        if  self.datastoreconfig == "YES":
            self.odlneutron = ost.ODLNEUTRON_DATA
        else:
            self.odlneutron = ost.ODLNEUTRON
        self.sid = res.create_session(self.odlsession, baseurl,  headers = ost.HEADERS, auth = ost.AUTH)
        baseurl1 = "http://" + self.ODLIP + ":" + ost.RESTCONFPORT
        self.datastore = res.create_session(self.odlsession1, baseurl1,  headers = ost.HEADERS, auth = ost.AUTH)
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
        ### ADDED BY THILAK
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
        #self.tntNetPortId = '79adcba5-19e0-489c-9505-cc70f9eb'
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
         X = choice("0123456789ABCDEF")
         return str(X)

    def mac(self):
       macaddr = "00:16:3E"+":"+self.x()+self.x()+":"+self.x()+self.x()+":"+self.x()+self.x()
       return macaddr

    def saveObject(self,obj):
        fp = open("openstackobject.txt",'w')
        pickle.dump(obj,fp)
        fp.close()

    def getObject(self):
        fp = open("openstackobject.txt",'r')
        return pickle.load(fp)

    def getNeutronPorts(self):
        return self.portnameIpList
         
    def getTapPorts(self):
        return self.tapportnameList

    def getNeutronPortMac(self, portname):
        netportid = self.portnameList[portname]
        return self.portMacList[netportid]

    def logmessage(self, mesg, mtype = 0, *argv):
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
        """It creates the port with given name. interface parameters are as shown below.
           nwname --->  Name of  the network
           portname ---> Name of the port
           i.e create_port("mynetwork", "myport")"""
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
        self.logmessage("JSON value of neutron_router",0,neutron_router)
        odlurl = self.odlneutron + "routers/"
        try:
            resp = res.postjson(self.odlsession, odlurl, data = neutron_router)
        except Exception as e:
            self.logmessage("Create Network Exception is",0,e)
            retval += 1
            return retval
        self.routernameList[routername] = routerId
        self.logmessage("Response Info:",0,resp)
        self.logmessage("Port Resp Status code:",0,resp.status_code)
        self.logmessage("Response Content",0,resp.content)
        self.logmessage("Router name to uuid list",0,self.portnameList)
        if resp.status_code == self.postresp:
            self.logmessage("Create Neutron Router with uuid",0,routerId, "  is success")
        else:
            self.logmessage("Create Neutron Router with uuid",1,routerId, "  is Failed")
            retval += 1
        return retval

    def create_network(self, netname, **kwargs):
        """It creates the network with given name. interface parameters are as shown below.
           netname --->  Name of  the network 
           nettype --->  Network type, if you don't pass this, it takes default value as local
           i.e create_network("mynetwork")"""
        retval = 0
        self.nindex += 1
        #self.sindex += 1
        self.subnetIdList = []
        transvlan = "false"
        networktype = "local"
        tntNetId = self.tntNetId + str(self.nindex).zfill(4)
        #subnetid = self.tntSubnetId + str(self.sindex).zfill(4)
        #self.subnetIdList.append(subnetid)
        self.networkList[tntNetId] = self.subnetIdList
        self.netnameList[netname] = tntNetId
        if kwargs is not None:
            for k,val in kwargs.iteritems():
                print "%s == %s" %(k,val)
                if k == 'vlan_trans':
                    transvlan = val
                if k == 'nettype':
                    networktype = val

        if self.datastoreconfig == "NO":
            neutron_network = {
                              "network": {
                                "shared": "false",
                                "vlan_transparent" : transvlan,
                                "name": netname,
                                "id": tntNetId,
                                "tenant_id": self.tntId ,
                                "admin_state_up": "true",
                                "router:external" : "false",
                                "provider:network_type" : networktype,
                                'provider:segmentation_id': None,
                                "status" : "ACTIVE",
                                "subnets": self.subnetIdList
                             }
                          }
        else:
            neutron_network = {
                              "network": {
                                "shared": "false",
                                "vlan-transparent" : transvlan,
                                "name": netname,
                                "uuid": tntNetId,
                                "tenant-id": self.tntId ,
                                "admin-state-up": "true",
                                "router:external" : "false",
                                "provider:network-type" : networktype,
                                'provider:segmentation-id': None,
                                "status" : "ACTIVE",
                                "subnets": self.subnetIdList
                             }
                          }
               
        self.networkjson[netname] = neutron_network       
        self.logmessage("JASON structure of neutron_network",0,neutron_network)
        odlurl = self.odlneutron + "networks/"
        try:
            resp = res.postjson(self.odlsession, odlurl, data = neutron_network)
        except Exception as e:
            self.logmessage("Create Network Exception is",0,e)
            self.networkList = {} 
            self.netnameList = {}
            self.subnetIdList = []
            retval += 1
            return retval
             
        self.logmessage("Response Content is",0,resp.content)
        self.logmessage("Response Code is",0,resp.status_code)
        if resp.status_code == self.postresp:
            self.logmessage("Create Network is SUCCESS for uuid",0,tntNetId) 
        else:
            self.logmessage("Create Network is FAILED for uuid",1,tntNetId) 
            retval += 1
        self.logmessage("Network List",0,self.networkList)
        self.logmessage("Netname List",0,self.netnameList)
        return retval

    def update_network(self, netname, newname):
        """It updates the network name with new given name.
           netname --->  Name of  the network 
           newname --->  New name of the network
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
                                "tenant_id": self.tntId ,
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
                                "tenant-id": self.tntId ,
                                "admin-state-up": "true",
                                "subnets": self.subnetIdList
                             }
                           }
                          }

        self.logmessage("JSON value of neutron_subnet",0,neutron_update_network)
        odlurl = self.odlneutron + "networks/"
        try:
            resp = res.put(self.odlsession, odlurl, data = neutron_update_network)
            print resp
            self.logmessage("Update Network Info:",0,resp.content)
        except Exception as e:
            self.logmessage("Update Network Exception is",0,e)
            retval += 1
            return retval
        if resp.status_code == self.updateresp:
            self.logmessage("Update Network with uuid",0,tntNetId, "  is success")
            self.sindex += 1
        else:
            self.logmessage("Update Network with uuid",0,tntNetId, "  is Failed")
            retval += 1
        return retval

    def get_networks(self):
        odlurl = self.odlneutron + "networks/"
        resp = res.get(self.odlsession, odlurl)
        self.logmessage("All networks",0,resp.content)
        return resp

    def get_network(self, netname):
        netuid = self.netnameList[netname] 
        odlurl = self.odlneutron + "networks/" + netuid + "/"
        resp = res.get(self.odlsession, odlurl)
        self.logmessage("All networks",0,resp.content)
        return resp 
         
    def get_network_ids(self):
        uuidlist = []
        odlurl = self.odlneutron + "networks/"
        resp = res.get(self.odlsession, odlurl)
        self.logmessage("All networks",0,resp.content)
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
        odlurl = self.odlneutron + "subnets/"
        resp = res.get(self.odlsession, odlurl)
        print resp.content
        self.logmessage("All sub networks",0,resp.content)
        return resp

    def get_subnet(self, subnetname):
        subid = self.subnetnameList[subnetname]
        odlurl = self.odlneutron + "subnets/" + subid + "/"
        resp = res.get(self.odlsession, odlurl)
        print resp.content
        self.logmessage("All sub networks",0,resp.content)
        return resp

    def get_subnet_params(self, subnetname, param):
        paramValue = None
        subid = self.subnetnameList[subnetname]
        odlurl = self.odlneutron + "subnets/" + subid + "/"
        resp = res.get(self.odlsession, odlurl)
        print resp.content
        self.logmessage("All sub networks",0,resp.content)
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
        uuidlist = []
        odlurl = self.odlneutron + "subnets/"
        resp = res.get(self.odlsession, odlurl)
        print resp.content
        self.logmessage("All sub networks",0,resp.content)
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
        uuidlist = []
        odlurl = self.odlneutron + "ports/"
        resp = res.get(self.odlsession, odlurl)
        self.logmessage("All neutron ports:",0,resp.content)
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
        uuidlist = []
        odlurl = self.odlneutron + "routers/"
        resp = res.get(self.odlsession, odlurl)
        self.logmessage("All neutron router:",0,resp.content)
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
        odlurl = self.odlneutron + "ports/"
        resp = res.get(self.odlsession, odlurl)
        self.logmessage("All neutron ports:",0,resp.content)
        print resp.content
        return resp

    def get_port(self, portname):
        portId = self.portnameList[portname]   
        odlurl = self.odlneutron + "ports/" + portId + "/"
        resp = res.get(self.odlsession, odlurl)
        self.logmessage("All neutron ports:",0,resp.content)
        print resp.content
        return resp

    def delnet(self):
        retval = 0
        print "===================Deleting the Networks++++++++++++++++++++++"
        netlist = self.get_network_ids()
        for x in netlist:
            self.delete_net(None,x)
        return retval

    def delsub(self):
        retval = 0
        print "===================Deleting the Subnets++++++++++++++++++++++"
        subnetlist = self.get_subnet_ids()
        for x in subnetlist:
            self.delete_subnet(None,x)
        return retval

    def delport(self):
        retval = 0
        print "===================Deleting the Ports++++++++++++++++++++++"
        portlist = self.get_port_ids()
        for x in portlist:
            print x
            self.delete_port(None,x)
        return retval


    def NetJsonlist():
        retval = []
        for x in self.netnameList:
            retval.append(ops.networkjson[x])
        return retval

    def logAllOpenStackInfo(self):
        """It logs all networks,subnets,ports information maintained by the class.
           i.e logAllOpenStackInfo()"""
        self.logmessage("Netname List",0,self.netnameList)
        self.logmessage("Sub Netname List",0,self.subnetnameList)
        self.logmessage("Port name List",0,self.portnameList)
        self.logmessage("Tab Port name List",0,self.tapportnameList)
        self.logmessage("Network List",0,self.networkList)
        self.logmessage("Subnet work Id List",0,self.subnetIdList)
        self.logmessage("Subnet IP Info:",0,self.subnetIpList)
        self.logmessage("Network to Port Info:",0,self.netnamePortList)
        self.logmessage("Port Mac List:",0,self.portMacList)
        self.logmessage("Tap Port Info:",0,self.tapPorts)
        self.logmessage("VM to PIDs:",0,self.vmpids)
        self.logmessage("VM Mac Info:",0,self.vmMacs)
        self.logmessage("VM Tap Port Info:",0,self.vmTapports)
 
    def get_all_networks(self):
        """It get all  networks,subnets,ports information from the node through REST and logs into logfile.
           i.e get_all_networks()"""
        odlurl = self.odlneutron + "networks/"
        resp = res.get(self.odlsession, odlurl)
        self.logmessage("All networks",0,resp.content)
        odlurl = self.odlneutron + "subnets/"
        resp = res.get(self.odlsession, odlurl)
        print resp.content
        self.logmessage("All sub networks",0,resp.content)
        odlurl = self.odlneutron + "ports/"
        resp = res.get(self.odlsession, odlurl)
        self.logmessage("All neutron ports:",0,resp.content)
        print resp.content
        return resp

    def get_neutron_ports(self):
        """It returns neutron port name and uuid associate list(dictionary) 
           i.e get_neutron_ports()"""
        return self.portnameList

    def delete_net(self, netname, uuid = None):
        """It deletes the network with given netname. interface parameters are as shown below.
           netname --->  Name of  the network 
           i.e delete_net("mynetwork")"""
        retval = 0
        if uuid == None:
            self.logmessage("",0,self.netnameList)
            uuid = self.netnameList[netname]
        if self.datastoreconfig == "YES":
           odlurl = self.odlneutron + "networks/network/" + uuid
        else:
            odlurl = self.odlneutron + "networks/" + uuid
        try:
            resp = res.delete(self.odlsession, odlurl)
            self.logmessage("Response is:",0,resp)
        except Exception as e:
            self.logmessage("Delete network exception is",0,e)
            retval += 1
            return retval
        self.logmessage("Response is:",0,resp.content)
        self.logmessage("Response is:",0,resp)
        if resp.status_code == self.delresp:
            self.logmessage("Delete network is SUCCESS for uuid",0,uuid)
            if netname is not None:
                del self.netnameList[netname]
                del self.networkList[uuid] 
            self.logmessage("Network Name to uuid mapping List is:",0,self.netnameList)
            self.logmessage("Network Name to subnet uuid mapping List is:",0,self.networkList)
        else:
            self.logmessage("Delete Network is FAILED for uuid",1,uuid) 
            retval += 1
        return retval

    def delete_subnet(self, subnetname, uuid = None):
        """It deletes the sub network with given subnetwork name. interface parameters are as shown below.
           subnetname --->  Name of  the sub network which is going to be created 
           i.e delete_subnet("mysubnet1")"""
        retval = 0
        if uuid == None:
            uuid = self.subnetnameList[subnetname]
        if self.datastoreconfig == "NO":
            odlurl = self.odlneutron + "subnets/" + uuid
        else:
            odlurl = self.odlneutron + "subnets/subnet/" + uuid
        try:
            resp = res.delete(self.odlsession, odlurl)
        except Exception as e:
            self.logmessage("Delete network exception is",0,e)
            retval += 1
            return retval
        self.logmessage("Response is:",0,resp.content)
        self.logmessage("Response is:",0,resp)
        if resp.status_code == self.delresp:
            self.logmessage("Delete subnet network is SUCCESS for uuid",0,uuid)
            if subnetname is not None:
                del self.subnetnameList[subnetname]
                del self.subnetIpList[uuid]    
            self.logmessage("Subnet Name to uuid mapping List is:",0,self.subnetnameList)
            self.logmessage("Subnet IP to uuid mapping List is:",0,self.subnetIpList)
        else:
            self.logmessage("Delete subnet Network is FAILED for uuid",1,uuid)
            retval += 1
        return retval

    def delete_router(self, routername, uuid = None):
        """It deletes the port with given port name. interface parameters are as shown below.
           portname --->  Name of  the  port
           i.e delete_subnet("mysubnet1")"""
        retval = 0
        if uuid == None:
            uuid = self.routernameList[routername]
        if self.datastoreconfig == "NO":
            odlurl = self.odlneutron + "routers/" + uuid
        else:
            odlurl = self.odlneutron + "routers/" + uuid
        try:
            resp = res.delete(self.odlsession, odlurl)
        except Exception as e:
            self.logmessage("Delete Router exception is",0,e)
            retval += 1
            return retval
        self.logmessage("Response is:",0,resp.content)
        self.logmessage("Response is:",0,resp)
        if resp.status_code == self.delresp:
            self.logmessage("Delete Port is SUCCESS for uuid",0,uuid)
            if  routername is not None:
                del self.routernameList[routername]
            #nwname =  [k for k, v in self.netnamePortList.iteritems() if v == uuid][0]
            #del self.netnamePortList[nwname]
            self.logmessage("Router Name to uuid mapping List is:",0,self.routernameList)
    #        self.logmessage("Network to port uuid mapping List is:",0,self.netnamePortList)
        else:
            self.logmessage("Delete Port is FAILED for uuid",1,uuid)
            retval += 1
        return retval

    def delete_port(self, portname, uuid = None):
        """It deletes the port with given port name. interface parameters are as shown below.
           portname --->  Name of  the  port
           i.e delete_subnet("mysubnet1")"""
        retval = 0
        if uuid == None:
            uuid = self.portnameList[portname]
        if self.datastoreconfig == "NO":
            odlurl = self.odlneutron + "ports/" + uuid
        else:
            odlurl = self.odlneutron + "ports/port/" + uuid
        try:
            resp = res.delete(self.odlsession, odlurl)
        except Exception as e:
            self.logmessage("Delete Port exception is",0,e)
            retval += 1
            return retval
        self.logmessage("Response is:",0,resp.content)
        self.logmessage("Response is:",0,resp)
        if resp.status_code == self.delresp:
            self.logmessage("Delete Port is SUCCESS for uuid",0,uuid)
            if  portname is not None:
                del self.portnameList[portname]
                del self.portMacList[uuid]
            #nwname =  [k for k, v in self.netnamePortList.iteritems() if v == uuid][0]
            #del self.netnamePortList[nwname]
            self.logmessage("Port Name to uuid mapping List is:",0,self.portnameList)
            self.logmessage("Port Mac to uuid mapping List is:",0,self.portMacList)
            self.logmessage("Network to port uuid mapping List is:",0,self.netnamePortList)
        else:
            self.logmessage("Delete Port is FAILED for uuid",1,uuid)
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
            self.logmessage("REST Response",0,resp)
        except Exception as e:
            print e
            retval += 1
        odlurl = ost.ODLNEUTRON_DATA + "subnets/"
        try:
            resp = res.delete(self.odlsession1, odlurl)
            self.subnetnameList = {}
            self.subnetIpList = {}
            self.sindex = 0
            self.logmessage("REST Response",0,resp)
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
            self.logmessage("REST Response",0,resp)
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
            self.delete_port(None,x)
        print "===================Deleting the Subnets++++++++++++++++++++++"
        subnetlist = self.get_subnet_ids()
        for x in subnetlist:
            self.delete_subnet(None,x)
        print "===================Deleting the Networks++++++++++++++++++++++"
        netlist = self.get_network_ids()
        for x in netlist:
            self.delete_net(None,x)
        return retval

    def setRemoteHipvspath(self, rIp):
        if rIp:
            res = self.exec_remote_cmd(rIp,"echo $HIPVS")
            resp = [] 
            for x in res.split('\n'):
                if re.search("echo $HIPVS",x) or re.search(self.runame,x):
                     break
                else:
                     resp.append(x)
            print resp
        self.rhipvshome = resp[1].strip()

    def getHipvsPorts(self, remoteIp = ""):
        """It is an Helper function to other public function"""
        ports = []
        if remoteIp:
            if self.hipvsversion == "1.5":
                getports = "hipvsctl" + " --getports"
            else:
                getports = self.rhipvshome + "scripts/" + "hipvsctl" + " --getports"
            self.logmessage("HIPVS Command:",0,getports) 
            getports_output = self.exec_remote_cmd(remoteIp,getports)
            print getports_output
        else:
            if self.hipvsversion == "1.5":
                getports = "hipvsctl" + " --getports"
            else:
                getports = self.hipvshome + "scripts/" + "hipvsctl" + " --getports"
            self.logmessage("HIPVS Command:",0,getports) 
            f = os.popen(getports)
            getports_output = f.read()
            f.close() 
        regpat = 'port_name='+ '\\'+ '\"' +'[a-zA-Z0-9,-]+' +'\\' + '\"'
        m = re.findall(regpat, getports_output)
        print m
        if m:
            for x in m:
                ports.append(re.sub('\"','', x.split("=")[1]))
        return ports

    def getPortStatus(self, portname, remoteIp = ""):
        """It is an Helper function to other public function"""
        port_status = self.null
        if remoteIp:
            if self.hipvsversion == "1.5":
                getports = "hipvsctl" + " --getports"
            else:
                getports = self.rhipvshome + "scripts/" + "hipvsctl" + " --getports"
            self.logmessage("HIPVS Command:",0,getports) 
            getports_output = self.exec_remote_cmd(remoteIp,getports)
            print getports_output
        else:
            if self.hipvsversion == "1.5":
                getports = "hipvsctl" + " --getports"
            else:
                getports = self.hipvshome + "scripts/" + "hipvsctl" + " --getports"
            self.logmessage("HIPVS Command:",0,getports) 
            f = os.popen(getports)
            getports_output = f.read()
            f.close()
        re1 = 'port_name=' + '\\"' + portname + '\\"' + ',[\w+,\d+,\,,\=,\},\{,\:,\"]+,op_state=\w+' 
        self.logmessage("REGEXP used to find port status:",0,re1) 
        m = re.search(re1,getports_output)
        if m:
            out = m.group()
            self.logmessage("",0,out)
            # Get the port status
            out1 = re.search('op_state=\w+',out)
            if out1:
                port_status = out1.group().split('=')[1]
        else:
            self.logmessage("Given Port is Not found in Hipvs port status",0) 
        self.logmessage("Port ",0,portname,"Status is",port_status)
        return port_status 

    def delAllHipvsPorts(self, rIP = ""):
        """It is an Helper function to other public function"""
        retval = 0
        ports = self.getHipvsPorts(rIP)
        if ports:
            for x in ports:
                if re.search("tap",x):
                    if self.delHipvsPort(x,rIP) > 0:
                        retval += 1
                        self.logmessage("The Tap port Deletion is failed:  ",1,x) 
        return retval

    def destroyScreen(self, vmname = "VM1", rIp = ""):
        """It is an Helper function to other public function"""
        retval = 0
        self.logmessage("VM screen name is ",0,vmname) 
        # Delete the existing screen
        srcmd = 'screen -X -S ' + vmname + ' quit'
        if rIp:
            srout = self.exec_remote_cmd(rIp,srcmd)
        else:
            os.system(srcmd)
        # Verify it
        if rIp:
            out = self.exec_remote_cmd(rIp,"screen -ls")
        else:
            pout = os.popen('screen -ls')
            out = pout.read()
        if out == self.null:
            self.logmessage("screen command is not installed or path is not set",0) 
            retval += 1
            return retval
        if re.search(vmname, out):
            self.logmessage("Screen with name",0,vmname," is not destroyed") 
            retval += 1
            return retval
        return retval  
 
    def createScreen(self, vmname = "VM1", rIp = ""):
        """It is an Helper function to other public function"""
        retval = 0
        handle = self.null
        self.logmessage("VM screen name is ",0,vmname) 
        # Delete the existing screen
        ret = self.destroyScreen(vmname,rIp) 
        if rIp:
            srcmd = 'screen -S ' + vmname
            srout,spawn_id = self.exec_remote_cmd(rIp,srcmd,1)
        else:
            srcmd = 'screen -S ' + vmname
            spawn_id = pexpect.spawn(srcmd)
            spawn_id.setecho(True)
            spawn_id.expect('.*#')
        return retval, spawn_id

    def vmLogin(self, vmname, rIP = ""):
        """It is an Helper function to other public function"""
        srcmd = 'screen -dr ' + vmname
        sflag = 0
        if self.imagetype == "ZEROSHELL":
            prompt_list = [self.VMPrompt,'root>', pexpect.TIMEOUT, pexpect.EOF]
        else:
            prompt_list = [self.VMPrompt, pexpect.TIMEOUT, pexpect.EOF]
        sflag = 0
        for r in range(1,15):
            if rIP:
                if self.imagetype == "ZEROSHELL":
                    i,srout,spawn_id = self.exec_remote_cmd_zeros(rIP,srcmd,1, prompt_list)
                    #spawn_id = pexpect.spawn(srcmd)
                    #spawn_id.setecho(True)
                    #i = spawn_id.expect_exact(prompt_list, timeout = 10)
                    #print i
                    if i == 0:
                        sflag = 1
                        spawn_id.sendline('s')
                        spawn_id.expect('root>')
                        datapoolbefore = spawn_id.before
                        datapoolafter = spawn_id.after
                        resultdata = datapoolbefore + datapoolafter
                        #print resultdata
                        self.logmessage("Login prompt found",0)
                        return spawn_id
                    if i == 1:
                        self.logmessage("Root Login prompt found",0)
                        sflag = 1
                        datapoolbefore = spawn_id.before
                        datapoolafter = spawn_id.after
                        resultdata = datapoolbefore + datapoolafter
                        #print resultdata
                        return spawn_id
                    else:
                        self.logmessage("Finding VM Login prompt is Failed for iteration",0,r)
                        datapoolbefore = spawn_id.before
                        datapoolafter = spawn_id.after
                        print datapoolbefore
                        print datapoolafter
                        time.sleep(20)
                        spawn_id.close()
                else:
                    srout,spawn_id = self.exec_remote_cmd(rIP,srcmd,1, self.VMPrompt)
                    print srout
                    if re.search(self.VMPrompt,srout):
                        self.logmessage("Login prompt found",0)
                        sflag = 1
                        spawn_id.sendline('cirros')
                        spawn_id.expect('Password:')
                        spawn_id.sendline('cubswin:)')
                        spawn_id.expect('$\s*')
                        datapoolbefore = spawn_id.before
                        datapoolafter = spawn_id.after
                        resultdata = datapoolbefore + datapoolafter
                        print resultdata
                        return spawn_id
                    else:
                        self.logmessage("Finding VM Login prompt is Failed for iteration",0,r)
                        datapoolbefore = spawn_id.before
                        datapoolafter = spawn_id.after
                        print datapoolbefore
                        print datapoolafter
                        time.sleep(20)
                        spawn_id.close()
            else:
                if self.imagetype == "ZEROSHELL":
                    spawn_id = pexpect.spawn(srcmd)
                    spawn_id.setecho(True)
                    i = spawn_id.expect_exact(prompt_list, timeout = 10)
                    #print i
                    if i == 0:
                        sflag = 1
                        spawn_id.sendline('s')
                        spawn_id.expect('root>')
                        datapoolbefore = spawn_id.before
                        datapoolafter = spawn_id.after
                        resultdata = datapoolbefore + datapoolafter
                        #print resultdata
                        self.logmessage("Login prompt found",0) 
                        return spawn_id
                    if i == 1:
                        self.logmessage("Root Login prompt found",0) 
                        sflag = 1
                        datapoolbefore = spawn_id.before
                        datapoolafter = spawn_id.after
                        resultdata = datapoolbefore + datapoolafter
                        #print resultdata
                        return spawn_id
                    else:
                        self.logmessage("Finding VM Login prompt is Failed for iteration",0,r) 
                        datapoolbefore = spawn_id.before
                        datapoolafter = spawn_id.after
                        print datapoolbefore
                        print datapoolafter
                        time.sleep(20)
                        spawn_id.close()
                else:
                    spawn_id = pexpect.spawn(srcmd)
                    spawn_id.setecho(True)
                    i = spawn_id.expect_exact(prompt_list, timeout = 30)
                    #print i
                    if i == 0:
                        self.logmessage("Login prompt found",0) 
                        sflag = 1
                        spawn_id.sendline('cirros')
                        spawn_id.expect('Password:')
                        spawn_id.sendline('cubswin:)')
                        spawn_id.expect('$\s*')
                        datapoolbefore = spawn_id.before
                        datapoolafter = spawn_id.after
                        resultdata = datapoolbefore + datapoolafter
                        print resultdata
                        return spawn_id
                    else:
                        self.logmessage("Finding VM Login prompt is Failed for iteration",0,r) 
                        datapoolbefore = spawn_id.before
                        datapoolafter = spawn_id.after
                        print datapoolbefore
                        print datapoolafter
                        time.sleep(20)
                        spawn_id.close()
        if sflag == 0:
                self.logmessage("VM Login  is Failed",1) 
                #spawn_id.close()
                return self.null
      
    def runCommand(self, cmd1, vmname, pingCmd = 0,  rIP = ""):
        """It runs the command on VM which its handle passed as parameter and returns the command response
           command ---->  the command which needs to be executed on VM
           handle  ---->  the spawnid of spawned screen process for the VM which runs on the screen
           i.e : runVM_command("ifconfig",handle) """
        resultdata = ""
        srcmd = 'screen -dr ' + vmname
        prompt_list = ['\$', pexpect.TIMEOUT, pexpect.EOF]
        if rIP:
            print "Logging to remote server"
            srout,session = self.exec_remote_cmd(rIP,'pwd',1)
            print srout
        else:
            session = pexpect.spawn('/bin/bash')
        #cmd2 = 'screen -x ' + vmname + ' -p0 -X ' + '\"' + 'clear' + '\"' 
        session.sendline('screen -x VM2 -p0 -X stuff "clear\n"')
        #session.sendline(cmd2)
        #os.system('screen -x VM4 -p0 -X stuff "clear\n"')
        #session.sendline('screen -x VM4 -p0 -X "clear\n"')
        #cm1 = 'screen -x ' + vmname + ' -p0 -X eval "stuff \\015"'
        #session.sendline(cm1)
        cm1 = 'screen -x ' + vmname + ' -p0 -X stuff ' + '\"' +  str(cmd1) + '\"'
        session.sendline(cm1)
        cm1 = 'screen -x ' + vmname + ' -p0 -X eval "stuff \\015"'
        session.sendline(cmd1)
        if pingCmd == 1:
             t1 = int(cmd1.split(' ')[2])
             stime = t1 * 5
             time.sleep(stime)
        else:
             time.sleep(1)
        cm1 = 'screen -x ' + vmname + ' -p0 -X hardcopy $(tty); $(uname)'
        session.sendline(cm1)
        session.expect('Linux')
        output = session.before.split('\n')
        #session.sendline(cmd2)
        #session.sendline('screen -x VM4 -p0 -X "clear\n"')
        #session.expect('Linux')
        p1 = []
        i = 0
        for o in output:
            i += 1
            if pingCmd == 1:
                if i > 10:
                    p1.append(o)
            else: 
                if i > 4:
                    p1.append(o)
        p1 = [x.replace("\r","") for x in p1]
        p1 = [x for x in p1 if x]
        p1 = "\n".join(p1)
        session.close()
        resultdata = p1
        return resultdata

    def getVMMac(self, intf, vmname, rIP = ""):
        macaddr = "" 
        ifcgcmd = "ifconfig " + str(intf) + "\n"
        res = self.runCommand('clear\n',vmname,rIP)
        res = self.runCommand(ifcgcmd,vmname,rIP)
        print res
        m = re.search('([0-9A-Fa-f]{1,2})(\:[0-9A-Fa-f]{1,2}){5}',res)
        if m:
            macaddr = m.group().strip()
        return macaddr 
      
    def getVMIP(self, intf, vmname, rIP = ""):
        vmipaddr = ""
        ifcgcmd = "ifconfig " + str(intf) + "\n"
        res = self.runCommand('clear\n',vmname,0,rIP)
        res = self.runCommand(ifcgcmd,vmname,0,rIP)
        print res
        m = re.search('([0-9]{1,3}.){3}[0-9]{1,3}',res)
        if m:
            vmipaddr = m.group().strip()
        return vmipaddr

    def addARPEntry(self, intf,  srvmname, destvmname, srIP = "", drIP = ""):
        # Get the destination ARP IP and Mac and add it at source VM
        vmip = self.getVMIP(intf,destvmname,drIP)
        vmmac = self.getVMMac(intf,destvmname,drIP)
        print "VM IP is",vmip
        print "VM MAC is",vmmac
        arpcmd = "arp -s " + vmip + " " + vmmac + "\n"
        res = self.runCommand(arpcmd,srvmname,srIP)
        res = self.runCommand('clear\n',srvmname,srIP)
        arpcmd = "arp -n\n"
        res = self.runCommand(arpcmd,srvmname,srIP)
        return res  
 
    def deleteARPEntry(self, intf,  srvmname, destvmname, srIP = "", drIP = ""):
        # Get the destination ARP IP and Mac and add it at source VM
        vmip = self.getVMIP(intf,destvmname,drIP)
        arpcmd = "arp -d " + vmip
        res = self.runCommand(arpcmd,srvmname,srIP)
        arpcmd = "arp -n"
        res = self.runCommand(arpcmd,srvmname,srIP)
        return res
  
    def runVM_command(self, command, handle):
        resultdata = ""
        handle.sendline(command)
        if self.imagetype == "ZEROSHELL":
            handle.expect('root>')
        else:
            handle.expect('\$')
        datapoolbefore = handle.before
        datapoolafter = handle.after
        handle.sendline('clear')
        if self.imagetype == "ZEROSHELL":
            handle.expect('root>')
        else:
            handle.expect('\$')
        resultdata = datapoolbefore + datapoolafter
        self.logmessage("RESPONSE:",0,resultdata)
        return resultdata 
          
    def create_subnet(self, mynetname,  subnetname, subnetip, dhcpflag = "true"):
        """It creates the sub network with given name. interface parameters are as shown below.
           mynetname --->  Name of  the network which you are going to create subnet
           subnetname ---> Name of subnetwork name
           subnetip  ----> subnet IP range like 1.1.1.0/24 
           dhcpflag --->  DHCP flag which enable DHCP or not, if you don't pass this, it takes default value as false
           i.e create_subnet("mynetwork","mysubnet1", "1.1.1.0/24")"""

        retval = 0
        self.sindex += 1
        #if  mynetname in self.netnameList.keys():
        netid = self.netnameList[mynetname]
        subnetidlist = self.networkList[netid]
        subnetid = self.tntSubnetId + str(self.sindex).zfill(4)
        subnetidlist.append(subnetid)
        self.networkList[netid] = subnetidlist
        print "Network List : ", self.networkList
        self.subnetIpList[subnetid] = subnetip
        r = '\d{1,3}\.\d{1,3}\.\d{1,3}'
        m = re.search(r,subnetip)
        if m:
             ipdigits = m.group()
             gatewayip = ipdigits + "." + "1"
             startIp =  ipdigits + "." + "2"
             endIp   =  ipdigits + "." + "254"

        if self.datastoreconfig == "NO":
             neutron_subnet = {
                             "subnet": {
                                 "id" : subnetid,
                                 "network_id" : netid,
                                 "name" : subnetname,
                                 "ip_version" : 4,
                                 "cidr" : subnetip,
                                 "gateway_ip" : gatewayip,
                                 "enable_dhcp": dhcpflag,
                                 "dns_nameservers" : [ ],
                                 "allocation_pools" : [ {
                                    "start" : startIp,
                                    "end" : endIp
                                  } ],
                                 "host_routes" : [ ],
                                 "tenant_id" : self.tntId,
                                 "ipv6_address_mode" : "null",
                                 "ipv6_ra_mode" : "null"
                             }
                        }

        else:
             neutron_subnet = {
                             "subnet": {
                                 "uuid" : subnetid,
                                 "network-id" : netid,
                                 "name" : subnetname,
                                 "ip-version" : 4,
                                 "cidr" : subnetip,
                                 "gateway-ip" : gatewayip,
                                 "enable-dhcp": dhcpflag,
                                 "dns-nameservers" : [ ],
                                 "allocation-pools" : [ {
                                    "start" : startIp,
                                    "end" : endIp
                                  } ],
                                 "host-routes" : [ ],
                                 "tenant-id" : self.tntId,
                                 "ipv6-ra-mode" : "off"
                             }
                        }

        self.logmessage("JSON value of neutron_subnet",0,neutron_subnet)
        odlurl = self.odlneutron + "subnets/"
        try:
            resp = res.postjson(self.odlsession, odlurl, data = neutron_subnet)
        except Exception as e:
            self.logmessage("Create Network Exception is",0,e)
            retval += 1
            return retval
        self.subnetnameList[subnetname] = subnetid
        self.logmessage("Subnet Info:",0,resp.content)
        self.logmessage("Status Code is:",0,resp.status_code)
        if resp.status_code == self.postresp:
            self.logmessage("Create SubNetwork with uuid",0,subnetid, "  is success")
            #self.sindex += 1
        else:
            self.logmessage("Create SubNetwork with uuid",0,subnetid, "  is Failed")
            retval += 1
        return retval
   
    def update_subnet(self, subnetname,  **kwargs):
        """It updates the sub network with given subnet name.
           subnetname ---> Name of subnetwork name
           **kwargs --> It accepts the key word arguments as like below.
               gateway="10.20.123.1", dnsnameservers=["8.8.8.8","9.9.9.9"      
           i.e update_subnet("mysubnet1", gateway="10.20.123.1", dnsnameservers=["8.8.8.8","9.9.9.9"])
               update_subnet("mysubnet1", enabldhcp = "true")"""
        retval = 0
        subnetid = self.subnetnameList[subnetname]
        subnetip = self.subnetIpList[subnetid]
        r = '\d{1,3}\.\d{1,3}\.\d{1,3}'
        m = re.search(r,subnetip)
        if m:
             ipdigits = m.group()
        subnetgw = ipdigits + '.1'
        subnet_name = subnetname
        servers_list = []
        hostroutes = []
        dhcpflag = 'false'
        allocated_pools = []
        if kwargs is not None:
            for k,val in kwargs.iteritems():
                print "%s == %s" %(k,val)
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
            for x,v1 in self.networkList.iteritems():
                if subnetid in v1:
                    netid = x
            print netid
            print subnetid
            if len(hostroutes) > 0:
                router_nexthop = hostroutes[0]
            else:     
                router_nexthop = ""

            if len(hostroutes) > 1:
                router_destination = hostroutes[1]
            else:     
                router_destination = ""

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
            self.logmessage("Arguments are not provided for update",0)
            return 1

        self.logmessage("JSON value of neutron_subnet",0,neutron_update_subnet)
        odlurl = self.odlneutron + "subnets/"
        try:
            resp = res.put(self.odlsession, odlurl, data = neutron_update_subnet)
            print resp
            self.logmessage("Update Subnet Info:",0,resp.content)
        except Exception as e:
            self.logmessage("Update subnet work Exception is",0,e)
            retval += 1
            return retval
        if resp.status_code == self.updateresp:
            self.logmessage("Update SubNetwork with uuid",0,subnetid, "  is success")
            self.sindex += 1
        else:
            self.logmessage("Update SubNetwork with uuid",0,subnetid, "  is Failed")
            retval += 1
        return retval

    def update_port(self, portname,  **kwargs):
        """It update the port parameters.
           portname ---> Name of the port
           **kwargs --> It accepts the key word arguments as like below.
               securitygroup = "867e051f-86d3-484f-a5f9-57396878749a", extradhcpopts = {'opt_name':'Agentid', 'opt_value':82}      
           i.e update_port("myport", securitygroup = "867e051f-86d3-484f-a5f9-57396878749a", 
                 extradhcpopts = {'opt_name':'Agentid', 'opt_value':82}"""
        retval = 0
        port_name = portname
        extra_dhcp_options = {}
        if kwargs is not None:
            for k,val in kwargs.iteritems():
                print "%s == %s" %(k,val)
                if k == 'securitygroup':
                    security_groups = val
                if k == 'name':
                    port_name = val
                if k == 'extradhcpopts':
                    extra_dhcp_options = val
            netPortId = self.portnameList[portname]
            portMac = self.portMacList[netPortId]
            # Get network id
            for x,v1 in self.netnamePortList.iteritems():
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
                 extra_dhcp_options_val = extra_dhcp_options[extra_dhcp_options_name]
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
            self.logmessage("JSON value of neutron_subnet",0,neutron_update_port)
            odlurl = self.odlneutron + "ports/"
        try:
            resp = res.put(self.odlsession, odlurl, data = neutron_update_port)
            print resp
            self.logmessage("Update Port Info:",0,resp.content)
        except Exception as e:
            self.logmessage("Update Port Exception is",0,e)
            retval += 1
            return retval
        if resp.status_code == self.updateresp:
            self.logmessage("Update Port with uuid",0,subnetid, "  is success")
            self.sindex += 1
        else:
            self.logmessage("Update Port with uuid",0,subnetid, "  is Failed")
            retval += 1
        return retval
   
    def associate_interface(self, routername, subnetname, interfacename):
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
                              "interfaces":[
                              {
                                  "subnet-id": subnetid,
                                  "uuid": interfaceId,
                                  "tenant-id": self.tntId
                              }
                            ]
                         }
        self.logmessage("JSON value of neutron_interface",0,neutron_interface)
        odlurl = self.odlneutron + "routers/router/" + routerid + "/interfaces/"
        #odlurl = self.odlneutron + "routers/router/" + routerid + "/"
        try:
            resp = res.put(self.odlsession, odlurl, data = neutron_interface)
        except Exception as e:
            self.logmessage("Create Interface Exception is",0,e)
            retval += 1
            return retval
        self.interfaceNameList[interfacename] = interfaceId
        self.logmessage("Response Info:",0,resp)
        self.logmessage("Port Resp Status code:",0,resp.status_code)
        self.logmessage("Response Content",0,resp.content)
        self.logmessage("Interface name to uuid list",0,self.interfaceNameList)
        if resp.status_code == self.postresp:
            self.logmessage("Create Neutron Port with uuid",0,interfaceId, "  is success")
        else:
            self.logmessage("Create Neutron Port with uuid",0,interfaceId, "  is Failed")
            retval += 1
        return retval

    def create_port(self, nwname, portname, **kwargs):
        """It creates the port with given name. interface parameters are as shown below.
           nwname --->  Name of  the network
           portname ---> Name of the port
           kwargs ---> Pass keyword arguments to pass options. like porttype='subport' etc 
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
            for k,val in kwargs.iteritems():
                print "%s == %s" %(k,val)
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
        self.logmessage("Subnet id List is",0,subnetidlist)
        self.logmessage("Subnet Name List is",0,self.subnetnameList)
        if subnetname is  None:
            subnetid = subnetidlist[0]
        else:
            subnetid = self.subnetnameList[subnetname]
        if porttype == "subport":
            parentportId = self.portnameList[parentport]
            firstpart = parentportId.split('-')[0]
            netPortId = firstpart + self.tntNetPortId2 + str(self.pindex).zfill(4)
        else:
            netPortId = self.tntNetPortId1 + str(self.pindex).zfill(4) + self.tntNetPortId2 + str(self.pindex).zfill(4)
        self.netnamePortList[nwname] = netPortId
        iplist = self.subnetIpList[subnetid]
        self.logmessage("IP List is",0,iplist)
        thirdOct = re.search('(\d+).(\d+).(\d+)',iplist).group(3)
        m = re.search('(\d+).(\d+).(\d+)',iplist)
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
        self.logmessage("Port MAC address is",0,portMac)
        self.portMacList[netPortId] = portMac
        self.dindex += 1
        deviceId = self.tntVM_DEVICE_ID + str(self.dindex).zfill(4)
        self.logmessage("Port Device id is",0,deviceId)
        self.portnameList[portname] = netPortId
        self.tapportnameList[portname] = self.tntNetTapPort + str(self.pindex).zfill(4) + "-19"
        self.deviceIdPortNameList[portname] = deviceId
        #neutron_port_ip = self.getIpAddrForVM()
        neutron_port_ip = ipaddr
        self.logmessage("Neutron port IP address",0,neutron_port_ip)
        self.portnameIpList[portname] = neutron_port_ip
        self.logmessage("Tap port info",0,self.tapportnameList[portname])
        self.logmessage("Tap port name list info",0,self.tapportnameList)
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
        self.logmessage("JSON value of neutron_port",0,neutron_port)
        odlurl = self.odlneutron + "ports/"
        print odlurl
        try:
            resp = res.postjson(self.odlsession, odlurl, data = neutron_port)
        except Exception as e:
            self.logmessage("Create Network Exception is",0,e)
            retval += 1
            return retval
        self.logmessage("Response Info:",0,resp)
        self.logmessage("Port Resp Status code:",0,resp.status_code)
        self.logmessage("Port Info:",0,resp.content)
        self.portnameList[portname] = netPortId
        self.portnamesubnetList[portname] = self.subnetnameList.keys()[self.subnetnameList.values().index(subnetid)]
        self.logmessage("Port name list:",0,self.portnameList)
        self.logmessage("Port Mac list:",0,self.portMacList)
        if resp.status_code == self.postresp:
            self.logmessage("Create Neutron Port with uuid",0,netPortId, "  is success")
        else:
            self.logmessage("Create Neutron Port with uuid",0,netPortId, "  is Failed")
            retval += 1
        return retval

    def associate_network(self,netname,vpnid):
        retval = 0
        self.logmessage("Response Info:",0,self.netnameList)
        uuid = self.netnameList[netname]   
    #    l3vpnid = self.l3vpnId + str(self.nindex).zfill(4)
        net_ass_conf = {
                                "input" :
                                {
                                "vpn-id": vpnid,
                                "network-id":[uuid]
                                }
                               }

        self.logmessage("JSON value of l3vpn",0,net_ass_conf)
        odlurl5 = "/restconf/operations/neutronvpn:associateNetworks"
        try:
            resp = res.postjson(self.odlsession, odlurl5, data = net_ass_conf)
        except Exception as e:
            self.logmessage("Create Network Exception is",0,e)
            retval += 1
            return retval
        self.logmessage("Response Info:",0,resp)
        self.logmessage("Port Resp Status code:",0,resp.status_code)
        self.logmessage("Port Info:",0,resp.content)
        #self.portnameList[portname] = netPortId
        if resp.status_code == self.postresp:
            self.logmessage("Associate network through uuid is passed")
            return uuid
        else:
            self.logmessage("Associate network through uuid")
            retval += 1
            return uuid
        return retval
    

    def dissociate_network(self,netname,vpnid):
        retval = 0
        uuid = self.netnameList[netname]
        l3vpnid = self.l3vpnId + str(self.nindex).zfill(4)
        net_ass_conf = {
                                "input" :
                                {
                                "vpn-id": vpnid,
                                "network-id":[uuid]
                                }
                               }

        self.logmessage("JSON value of l3vpn",0,net_ass_conf)
        odlurl5 = "/restconf/operations/neutronvpn:dissociateNetworks"
        try:
            resp = res.postjson(self.odlsession, odlurl5, data = net_ass_conf)
        except Exception as e:
            self.logmessage("Create Network Exception is",0,e)
            retval += 1
            return retval
        self.logmessage("Response Info:",0,resp)
        self.logmessage("Port Resp Status code:",0,resp.status_code)
        self.logmessage("Port Info:",0,resp.content)
        #self.portnameList[portname] = netPortId
        if resp.status_code == self.postresp:
            self.logmessage("Dissociate network through uuid is passed")
            return uuid
        else:
            self.logmessage("Dissociate network through uuid")
            return uuid
            retval += 1
        return retval
 

    def getIpAddrForVM(self):
        self.ipdigit += 1
        subid = self.subnetIdList[0]
        iplist = self.subnetIpList[subid]
        print iplist
        r = '\d{1,3}\.\d{1,3}\.\d{1,3}'
        m = re.search(r,iplist)
        if m:
             ipdigits = m.group()
             ipaddr = ipdigits + "." + str(self.ipdigit)
        else:
             ipaddr = ""
        return ipaddr

    def exec_remote_cmd_zeros(self, remoteIp, rcmd, rhandle = 0, prompt_list=[]):
        login_command = 'ssh ' + remoteIp + ' -l' + self.runame
        spawn_id = pexpect.spawn(login_command)
        spawn_id.timeout = 300
        spawn_id.setecho(True)
        j = 0
        i = spawn_id.expect([pexpect.TIMEOUT, 'assword:', pexpect.EOF])
        if i == 0:
                spawn_id.sendline('yes')
                i = spawn_id.expect([pexpect.TIMEOUT, 'assword:', pexpect.EOF])
        if i == 1:
                spawn_id.sendline(self.rpword)
                spawn_id.expect('#')
                time.sleep(60)
                spawn_id.sendline(rcmd)
                if rhandle == 1:
                    spawn_id.timeout = 300
                    j = spawn_id.expect_exact(prompt_list)
                    print "j---------",j
                else:
                    spawn_id.expect(">")
                datapoolbefore = spawn_id.before
                datapoolafter = spawn_id.after
                resultdata = datapoolbefore + datapoolafter
                print resultdata
                if rhandle == 1:
                    return j,resultdata,spawn_id
                else:
                    spawn_id.close()
                    return resultdata
        elif i == 2:
                die(spawn_id, 'ERROR!\nSSH timed out. Here is what SSH said:')
                return 0

    def exec_remote_cmd(self, remoteIp, rcmd, rhandle = 0, prompt1 = "#"):
        login_command = 'ssh ' + remoteIp + ' -l' + self.runame
        spawn_id = pexpect.spawn(login_command)
        spawn_id.timeout = 300
        spawn_id.setecho(True)
        i = spawn_id.expect([pexpect.TIMEOUT, 'assword:', pexpect.EOF])
        if i == 0:
                spawn_id.sendline('yes')
                i = spawn_id.expect([pexpect.TIMEOUT, 'assword:', pexpect.EOF])
        if i == 1:
                spawn_id.sendline(self.rpword)
                spawn_id.expect('#')
                #time.sleep(10)
                spawn_id.sendline(rcmd)
                if rhandle == 1:
                    spawn_id.expect(prompt1)
                else:
                    spawn_id.expect("#")
                datapoolbefore = spawn_id.before
                datapoolafter = spawn_id.after
                resultdata = datapoolbefore + datapoolafter
                print resultdata
                if rhandle == 1:
                    return resultdata,spawn_id
                else:
                    spawn_id.close()
                    return resultdata
        elif i == 2:
                die(spawn_id, 'ERROR!\nSSH timed out. Here is what SSH said:')
                return 0


    def start_VM_Remote(self, image, portname,  portname2 = None,  rServer = "localhost", vmname = "VM1", delallports = 0, vmprompt = ""):
        """It creates the VM with the provided VM image. API details are as follows
           image --->  image name with absolute path
           vmname ---> Name of the VM, It's default value is VM1
           delallports  ---->  if it set to 1, then it deletes all existing virtual ports on Hipvs. Default value is 0
           vmprompt -----> VM login prompt to be expected. if it is not provided, it takes default value from config file
           return value ----> It returns 0 or 1 and the spwan id of VM to execute some commands on VM
           i.e ret, handle = p.start_VM("/var/lib/libvirt/images/Cirros-01.img","testVM",1)"""
        retval = 0
        handle = self.null
        self.tapindex += 1
        if len(vmprompt) > 0:
            self.VMPrompt = vmprompt 
        # Create a VM with tap portname
        self.setRemoteHipvspath(rServer)
        netPortId = self.portnameList[portname]
        m = re.search('\/[a-zA-Z\]+\-[a-zA-Z0-9_]+\.[a-z]+$',image)
        z = m.group()
        z = re.sub('\/','',z)
        z = re.sub('\-[a-zA-Z0-9\-_]+\.[a-z]+$','',z)
        imageType = z.strip()
        if imageType == "ZeroShell":
            self.imagetype = "ZEROSHELL"
            self.VMPrompt = ost.ZERO_VMPROMPT
        else: 
            self.imagetype = "CIRROS"
            self.VMPrompt = ost.CERROS_VMPROMPT
        self.logmessage("Image Type is ",0,imageType) 
        #tapport = self.tntNetTapPort + str(self.tapindex).zfill(2)
        #### ADDED BY THILAK
        #tapport = self.tntNetTapPort + str(self.pindex).zfill(4) + "-19"
        tapport = self.tapportnameList[portname]
        self.tapPorts.append(tapport)
        tapVmMac = self.portMacList[netPortId]
        if portname2 is not None:
            netPortId1 = self.portnameList[portname2]
            tapport1 = self.tapportnameList[portname2]
            self.tapPorts.append(tapport1)
            tapVmMac1 = self.portMacList[netPortId1]
        #Check HipVS status
        self.logmessage("Check HIPVS status",0) 
        if self.getHipvs_Status(rServer) > 0:
            self.Hipvs_Start(rServer)
        
        if self.getHipvs_Status(rServer) > 0:
            self.logmessage("Hipvs is not started, Please check Hipvs installation",0)
            retval += 1
            return retval,handle
        # Delete all virtual ports
        if delallports == 1:
            self.logmessage("Delete all  HIPVS Virtual Ports",0) 
            self.delAllHipvsPorts(rServer)
        #Add Tap port
        self.logmessage("Add HIPVS Tap Port",0,tapport) 
        if self.hipvsversion == "1.5": 
            #add_port_eth = "hipvsctl" + " --addport "+ tapport +" --porttype vhost"
            add_port_eth = "sudo ovs-vsctl add-port BR0 " + tapport + " -- set Interface " + tapport + " type=vhost"
        else:
            add_port_eth = self.hipvshome + "scripts/" + "hipvsctl" + " --addport "+ tapport +" --porttype vhost"
        self.logmessage("HIPVS Command:",0,add_port_eth) 
        hipvsall_output = self.exec_remote_cmd(rServer,add_port_eth)
        self.logmessage("",0,hipvsall_output)
        if portname2 is not None:
            self.logmessage("Add HIPVS Tap Port",0,tapport1) 
            if self.hipvsversion == "1.5": 
                #add_port_eth = "hipvsctl" + " --addport "+ tapport1 +" --porttype vhost"
                add_port_eth = "ovs-vsctl add-port BR0 " + tapport1 + " -- set Interface " + tapport1 + " type=vhost"
            else:
                add_port_eth = self.hipvshome + "scripts/" + "hipvsctl" + " --addport "+ tapport1 +" --porttype vhost"
            self.logmessage("HIPVS Command:",0,add_port_eth) 
            hipvsall_output = self.exec_remote_cmd(rServer,add_port_eth)
        #Get Hipvs ports
        if self.hipvsversion == "1.5": 
            gethipvsports = "hipvsctl" + " --getports"
        else:
            gethipvsports = self.hipvshome + "scripts/" + "hipvsctl" + " --getports"
        self.logmessage("HIPVS Command:",0,gethipvsports) 
        hipvsall_status = self.exec_remote_cmd(rServer,gethipvsports)
        self.logmessage("",0,hipvsall_output) 
        self.logmessage("Update Tap port details with respect to VM",0) 
        self.vmMacs[vmname] = tapVmMac
        self.vmTapports[vmname] = tapport
        res = self.exec_remote_cmd(rServer,'pwd')
        resp = [] 
        for x in res.split('\n'):
            resp.append(x)
        print resp
        fname = resp[1].strip() + "/" + vmname
        self.rfname = fname
        vmpidfile = fname + "/" + "pid"
        #Spawn SSH process and run the VM script
        rmcmd = 'rm -rf ' + fname
        res = self.exec_remote_cmd(rServer,rmcmd)
        mkdircmd = 'mkdir ' + fname
        res = self.exec_remote_cmd(rServer,mkdircmd)
        self.logmessage("Create VM pid file",0) 
        vmfile = fname + "/" + vmname
        vmpidfile = fname + "/pid"
        self.logmessage("VM pid file",0,vmpidfile) 
        touchcmd = 'touch ' + vmpidfile
        res = self.exec_remote_cmd(rServer,touchcmd)
        ret1, handle = self.createScreen(vmname,rServer)
        if ret1 > 0:
            retval += 1
            self.logmessage("Execution of screen command is failed",0) 
            return retval, handle
        vmcmd = "/usr/bin/qemu-system-x86_64 -name " + vmname + " -cpu host -m 1024 -smp sockets=1,cores=2,threads=1 -drive file="
        vmcmd += image + "," + "if=virtio --enable-kvm"
        vmcmd += " -net none -no-reboot -mem-path /mnt/huge_1G -mem-prealloc -netdev "
        vmcmd += "type=tap,id=hostnet1,script=no,downscript=no,ifname=" + tapport + ",vhost=on,vhostforce=on -device "
        vmcmd += "virtio-net-pci,netdev=hostnet1,id=net1,mac=" + tapVmMac
        if portname2 is not None:
            vmcmd += " -net none -no-reboot -mem-path /mnt/huge_1G -mem-prealloc -netdev "
            vmcmd += "type=tap,id=hostnet2,script=no,downscript=no,ifname=" + tapport1 + ",vhost=on,vhostforce=on -device "
            vmcmd += "virtio-net-pci,netdev=hostnet2,id=net2,mac=" + tapVmMac1
        vmcmd += ",csum=off,gso=off,guest_tso4=off,guest_tso6=off,guest_ecn=off "
        vmcmd += "-pidfile " + vmpidfile + " -nographic" 
        print vmcmd
        self.logmessage("QEMU command for VM creation:",0,vmcmd)
        echocmd = 'echo ' + vmcmd + " >" + vmfile + ";" + "chmod +x " +  vmfile 
        res = self.exec_remote_cmd(rServer,echocmd)
        # Run the VM command to start the VM
        sflag = 0 
        handle.timeout = 300
        handle.sendline(vmfile)
        try:
            if self.imagetype == "ZEROSHELL":
                handle.expect('Loading*')
            else:  
                handle.expect('initramfs*')
        except Exception as e:
                print e
        self.logmessage("VM is started Fine",0) 
        # Check the process is running or not
        self.logmessage("Check the process is running or not",0) 
        catcmd = 'cat ' + vmpidfile
        res = self.exec_remote_cmd(rServer,catcmd)
        resp = [] 
        for x in res.split('\n'):
            resp.append(x)
        fp1 = resp[1].strip()
        try:
            pidval = int(re.sub('\s+',"",fp1))
        except Exception as e:
            print e
            pidval = 0
            self.logmessage("No VM process is running and it returns null, VM creation is failed",1) 
            retval += 1
            handle.close()
            handle = self.null
            return retval, handle
        if pidval > 0:
            self.logmessage("VM process is running and its process id is",0,pidval) 
            self.logmessage("Waiting for 50 seconds to bring up VM",0) 
            time.sleep(50)
            self.logmessage("Check VM login and login to VM",0) 
            handle = self.vmLogin(vmname,rServer)
            if handle == self.null:
                self.logmessage("VM Got hanged, So kill the process",0) 
                self.stop_VM(vmname,rServer)
                retval += 1
                return retval, handle
        #Configure IP address
        #vmip = self.getIpAddrForVM()
        vmip = self.portnameIpList[portname]
        subname = self.portnamesubnetList[portname]
        if self.imagetype == "ZEROSHELL":
            vimipconfig = "ifconfig ETH00 " + vmip + "/24" + " up"
        else:
            vimipconfig = "sudo ifconfig eth0 " + vmip + "/24" + " up"
        if self.get_subnet_params(subname,"enable_dhcp") == 'False' or self.MANUALIP_CONFIG == True:
            res = self.runVM_command(vimipconfig,handle)
            self.logmessage("",0,res) 
        if portname2 is not None:
            vmip = self.portnameIpList[portname2]
            if self.imagetype == "ZEROSHELL":
                vimipconfig = "sudo ifconfig ETH01 " + vmip + "/24" + " up"
            else:
                vimipconfig = "sudo ifconfig eth1 " + vmip + "/24" + " up"
            subname = self.portnamesubnetList[portname2]
            if self.get_subnet_params(subname,"enable_dhcp") == 'False' or self.MANUALIP_CONFIG == True:
                res = self.runVM_command(vimipconfig,handle)
        if self.get_subnet_params(subname,"enable_dhcp") == 'True' and self.MANUALIP_CONFIG == False:
            if self.imagetype == "ZEROSHELL":
                dhcpcmd = "dhclient ETH00"
                res = self.runVM_command(dhcpcmd,handle)
                time.sleep(15)
                if portname2 is not None:
                    dhcpcmd = "dhclient ETH01"
                    res = self.runVM_command(dhcpcmd,handle)
                    time.sleep(15)
        # Check Hipvs tap port
        self.vmpids[vmname] = pidval
        counter = 0
        while counter < 5:
            self.logmessage("Check the HipVS Tap port status which is conencted to VM",0)
            if self.getPortStatus(tapport,rServer) == "up":
                self.logmessage("Hipvs Tap Port",0,tapport,"is UP and Running")
                break
            time.sleep(20)
            counter += 1
        if self.getPortStatus(tapport,rServer) == "up":
            self.logmessage("Hipvs Tap Port",0,tapport,"is UP and Running")
        else:
            self.logmessage("Hipvs Tap Port",1,tapport,"is either not UP or not found")
            retval += 1
        return retval, handle

    def start_VM(self, image, portname1, portname2 = None,  vmname = "VM1", delallports = 0, vmprompt = ""):
        """It creates the VM with the provided VM image. API details are as follows
           image --->  image name with absolute path
           vmname ---> Name of the VM, It's default value is VM1
           delallports  ---->  if it set to 1, then it deletes all existing virtual ports on Hipvs. Default value is 0
           vmprompt -----> VM login prompt to be expected. if it is not provided, it takes default value from config file
           return value ----> It returns 0 or 1 and the spwan id of VM to execute some commands on VM
           i.e ret, handle = p.start_VM("/var/lib/libvirt/images/Cirros-01.img","testVM",1)"""
        retval = 0
        handle = self.null
        self.tapindex += 1
        if len(vmprompt) > 0:
            self.VMPrompt = vmprompt 
        # Create a VM with tap portname
        netPortId = self.portnameList[portname1]
        if portname2 is not None:
            netPortId1 = self.portnameList[portname2]
            tapport1 = self.tapportnameList[portname2]
            self.tapPorts.append(tapport1)
            tapVmMac1 = self.portMacList[netPortId1]
        m = re.search('\/[a-zA-Z\]+\-[a-zA-Z0-9_]+\.[a-z]+$',image)
        z = m.group()
        z = re.sub('\/','',z)
        z = re.sub('\-[a-zA-Z0-9\-_]+\.[a-z]+$','',z)
        imageType = z.strip()
        if imageType == "ZeroShell":
            self.imagetype = "ZEROSHELL"
            self.VMPrompt = ost.ZERO_VMPROMPT
        else: 
            self.imagetype = "CIRROS"
            self.VMPrompt = ost.CERROS_VMPROMPT
        self.logmessage("Image Type is ",0,imageType) 
        #tapport = self.tntNetTapPort + str(self.tapindex).zfill(2)
        #### ADDED BY THILAK
        #tapport = self.tntNetTapPort + str(self.pindex).zfill(4) + "-19"
        tapport = self.tapportnameList[portname1]
        self.tapPorts.append(tapport)
        tapVmMac = self.portMacList[netPortId]
        #Check HipVS status
        self.logmessage("Check HIPVS status",0) 
        if self.getHipvs_Status() > 0:
            self.Hipvs_Start()
            time.sleep(60)
        if self.getHipvs_Status() > 0:
            self.logmessage("Hipvs is not started, Please check Hipvs installation",0)
            retval += 1
            return retval,handle
        # Delete all virtual ports
        #time.sleep(30)
        if delallports == 1:
            self.logmessage("Delete all  HIPVS Virtual Ports",0) 
            self.delAllHipvsPorts()
        #Add Tap port
        self.logmessage("Add HIPVS Tap Port",0,tapport) 
        if self.hipvsversion == "1.5": 
            #add_port_eth = "hipvsctl" + " --addport "+ tapport +" --porttype vhost"
            add_port_eth = "sudo ovs-vsctl add-port BR0 " + tapport + " -- set Interface " + tapport + " type=vhost"
        else:
            add_port_eth = self.hipvshome + "scripts/" + "hipvsctl" + " --addport "+ tapport +" --porttype vhost"
        self.logmessage("HIPVS Command:",0,add_port_eth) 
        f = os.popen(add_port_eth)
        hipvsall_output = f.read()
        self.logmessage("",0,hipvsall_output)
        f.close() 
        if portname2 is not None:
            self.logmessage("Add HIPVS Tap Port",0,tapport1) 
            if self.hipvsversion == "1.5": 
                #add_port_eth = "hipvsctl" + " --addport "+ tapport1 +" --porttype vhost"
                add_port_eth = "ovs-vsctl add-port BR0 " + tapport1 + " -- set Interface " + tapport1 + " type=vhost"
            else:
                add_port_eth = self.hipvshome + "scripts/" + "hipvsctl" + " --addport "+ tapport1 +" --porttype vhost"
            self.logmessage("HIPVS Command:",0,add_port_eth) 
            f = os.popen(add_port_eth)
            hipvsall_output = f.read()
            self.logmessage("",0,hipvsall_output)
            f.close() 
        #Get Hipvs ports
        if self.hipvsversion == "1.5": 
            gethipvsports = "hipvsctl" + " --getports"
        else:
            gethipvsports = self.hipvshome + "scripts/" + "hipvsctl" + " --getports"
        self.logmessage("HIPVS Command:",0,gethipvsports) 
        f = os.popen(gethipvsports)
        hipvsall_output = f.read()
        f.close()
        self.logmessage("",0,hipvsall_output) 
        self.logmessage("Update Tap port details with respect to VM",0)
        tapports = [tapport]
        tapVmMacs = [tapVmMac]
        if portname2 is not None:
            tapVmMacs.append(tapVmMac1)
            tapports.append(tapport1)
        self.vmMacs[vmname] = tapVmMacs
        self.vmTapports[vmname] = tapports
        fname = os.getcwd() + "/" + vmname
        vmpidfile = fname + "/" + "pid"
        #Spawn SSH process and run the VM script
        if os.path.exists(fname):
            shutil.rmtree(fname)
        os.mkdir(fname)
        self.logmessage("Create VM pid file",0) 
        vmfile = fname + "/" + vmname
        vmpidfile = fname + "/pid"
        self.logmessage("VM pid file",0,vmpidfile) 
        fp = open(vmpidfile,'w')
        fp.close()
        ret1, handle = self.createScreen(vmname)
        if ret1 > 0:
            retval += 1
            self.logmessage("Execution of screen command is failed",0) 
            return retval, handle
        fp = open(vmfile, 'w')
        vmcmd = "/usr/bin/qemu-system-x86_64 -name " + vmname + " -cpu host -m 1024 -smp sockets=1,cores=2,threads=1 -drive file="
        vmcmd += image + "," + "if=virtio --enable-kvm"
        vmcmd += " -net none -no-reboot -mem-path /mnt/huge_1G -mem-prealloc -netdev "
        vmcmd += "type=tap,id=hostnet1,script=no,downscript=no,ifname=" + tapport + ",vhost=on,vhostforce=on -device "
        vmcmd += "virtio-net-pci,netdev=hostnet1,id=net1,mac=" + tapVmMac
        if portname2 is not None:
            vmcmd += " -net none -no-reboot -mem-path /mnt/huge_1G -mem-prealloc -netdev "
            vmcmd += "type=tap,id=hostnet2,script=no,downscript=no,ifname=" + tapport1 + ",vhost=on,vhostforce=on -device "
            vmcmd += "virtio-net-pci,netdev=hostnet2,id=net2,mac=" + tapVmMac1
        vmcmd += ",csum=off,gso=off,guest_tso4=off,guest_tso6=off,guest_ecn=off "
        vmcmd += "-pidfile " + vmpidfile + " -nographic" 
        print vmcmd
        self.logmessage("QEMU command for VM creation:",0,vmcmd) 
        fp.write(vmcmd)
        fp.close()
        os.chmod(vmfile,stat.S_IEXEC)
        # Run the VM command to start the VM
        sflag = 0 
        handle.timeout = 300
        handle.sendline(vmfile)
        try:
            if self.imagetype == "ZEROSHELL":
                handle.expect('Loading*')
            else:  
                handle.expect('initramfs*')
        except Exception as e:
                print e
        self.logmessage("VM is started Fine",0) 
        # Check the process is running or not
        self.logmessage("Check the process is running or not",0) 
        catcmd = 'cat ' + vmpidfile
        fp1 = commands.getoutput(catcmd)
        try:
            pidval = int(re.sub('\s+',"",fp1))
        except Exception as e:
            print e
            pidval = 0
            self.logmessage("No VM process is running and it returns null, VM creation is failed",1) 
            retval += 1
            handle.close()
            handle = self.null
            return retval, handle
        if pidval > 0:
            self.logmessage("VM process is running and its process id is",0,pidval) 
            self.logmessage("Waiting for 50 seconds to bring up VM",0) 
            time.sleep(50)
            self.logmessage("Check VM login and login to VM",0) 
            handle = self.vmLogin(vmname)
            if handle == self.null:
                self.logmessage("VM Got hanged, So kill the process",0) 
                self.stop_VM(vmname)
                retval += 1
                return retval, handle
        #Configure IP address
        #vmip = self.getIpAddrForVM()
        vmip = self.portnameIpList[portname1]
        subname = self.portnamesubnetList[portname1]
        #vimipconfig = "sudo ifconfig eth0 " + vmip + "/24" + " up"
        if self.imagetype == "ZEROSHELL":
            vimipconfig = "ifconfig ETH00 " + vmip + "/24" + " up"
        else:
            vimipconfig = "sudo ifconfig eth0 " + vmip + "/24" + " up"
        if self.get_subnet_params(subname,"enable_dhcp") == 'False' or self.MANUALIP_CONFIG == True:
            res = self.runVM_command(vimipconfig,handle)
            self.logmessage("",0,res) 
        if portname2 is not None:
            vmip = self.portnameIpList[portname2]
            if self.imagetype == "ZEROSHELL":
                vimipconfig = "sudo ifconfig ETH01 " + vmip + "/24" + " up"
            else:
                vimipconfig = "sudo ifconfig eth1 " + vmip + "/24" + " up"
            subname = self.portnamesubnetList[portname2]
            if self.get_subnet_params(subname,"enable_dhcp") == 'False' or self.MANUALIP_CONFIG == True:
                res = self.runVM_command(vimipconfig,handle)
                self.logmessage("",0,res) 
        # Check Hipvs tap port
        if self.get_subnet_params(subname,"enable_dhcp") == 'True' and self.MANUALIP_CONFIG == False:
            if self.imagetype == "ZEROSHELL":
                dhcpcmd = "dhclient ETH00"
                res = self.runVM_command(dhcpcmd,handle)
                if portname2 is not None:
                    dhcpcmd = "dhclient ETH01"
                    res = self.runVM_command(dhcpcmd,handle)
        self.vmpids[vmname] = pidval
        counter = 0
        while counter < 5:
            self.logmessage("Check the HipVS Tap port status which is conencted to VM",0)
            if self.getPortStatus(tapport) == "up":
                self.logmessage("Hipvs Tap Port",0,tapport,"is UP and Running")
                break
            time.sleep(20)
            counter += 1
        if self.getPortStatus(tapport) == "up":
            self.logmessage("Hipvs Tap Port",0,tapport,"is UP and Running")
        else:
            self.logmessage("Hipvs Tap Port",1,tapport,"is either not UP or not found")
            retval += 1
        return retval, handle

    def configure_VM(self, image, portname1, portname2 = None,  vmname = "VM1", delallports = 0, vmprompt = ""):
        self.tapindex += 1
        if len(vmprompt) > 0:
            self.VMPrompt = vmprompt 
        # Create a VM with tap portname
        netPortId = self.portnameList[portname1]
        if portname2 is not None:
            netPortId1 = self.portnameList[portname2]
            tapport1 = self.tapportnameList[portname2]
            self.tapPorts.append(tapport1)
            tapVmMac1 = self.portMacList[netPortId1]
        m = re.search('\/[a-zA-Z\]+\-[a-zA-Z0-9]+\.[a-z]+$',image)
        z = m.group()
        z = re.sub('\/','',z)
        z = re.sub('\-[a-zA-Z0-9]+\.[a-z]+$','',z)
        imageType = z.strip()
        if imageType == "ZeroShell":
            self.imagetype = "ZEROSHELL"
            self.VMPrompt = ost.ZERO_VMPROMPT
        else: 
            self.imagetype = "CIRROS"
            self.VMPrompt = ost.CERROS_VMPROMPT
        self.logmessage("Image Type is ",0,imageType) 
        tapport = self.tapportnameList[portname1]
        self.tapPorts.append(tapport)
        tapVmMac = self.portMacList[netPortId]
        #Check HipVS status
        self.logmessage("Check HIPVS status",0) 
        if self.getHipvs_Status() > 0:
            self.Hipvs_Start()
            time.sleep(60)
        if self.getHipvs_Status() > 0:
            self.logmessage("Hipvs is not started, Please check Hipvs installation",0)
            retval += 1
            return retval,handle
        # Delete all virtual ports
        #time.sleep(30)
        if delallports == 1:
            self.logmessage("Delete all  HIPVS Virtual Ports",0) 
            self.delAllHipvsPorts()
        #Add Tap port
        self.logmessage("Add HIPVS Tap Port",0,tapport) 
        if self.hipvsversion == "1.5": 
            #add_port_eth = "hipvsctl" + " --addport "+ tapport +" --porttype vhost"
            add_port_eth = "sudo ovs-vsctl add-port BR0 " + tapport + " -- set Interface " + tapport + " type=vhost"
        else:
            add_port_eth = self.hipvshome + "scripts/" + "hipvsctl" + " --addport "+ tapport +" --porttype vhost"
        self.logmessage("HIPVS Command:",0,add_port_eth) 
        f = os.popen(add_port_eth)
        hipvsall_output = f.read()
        self.logmessage("",0,hipvsall_output)
        f.close() 
        if portname2 is not None:
            self.logmessage("Add HIPVS Tap Port",0,tapport1) 
            if self.hipvsversion == "1.5": 
                #add_port_eth = "hipvsctl" + " --addport "+ tapport1 +" --porttype vhost"
                add_port_eth = "ovs-vsctl add-port BR0 " + tapport1 + " -- set Interface " + tapport1 + " type=vhost"
            else:
                add_port_eth = self.hipvshome + "scripts/" + "hipvsctl" + " --addport "+ tapport1 +" --porttype vhost"
            self.logmessage("HIPVS Command:",0,add_port_eth) 
            f = os.popen(add_port_eth)
            hipvsall_output = f.read()
            self.logmessage("",0,hipvsall_output)
            f.close() 
        #Get Hipvs ports
        if self.hipvsversion == "1.5": 
            gethipvsports = "hipvsctl" + " --getports"
        else:
            gethipvsports = self.hipvshome + "scripts/" + "hipvsctl" + " --getports"
        self.logmessage("HIPVS Command:",0,gethipvsports) 
        f = os.popen(gethipvsports)
        hipvsall_output = f.read()
        f.close()
        self.logmessage("",0,hipvsall_output) 
        self.logmessage("Update Tap port details with respect to VM",0)
        tapports = [tapport]
        tapVmMacs = [tapVmMac]
        if portname2 is not None:
            tapVmMacs.append(tapVmMac1)
            tapports.append(tapport1)
        self.vmMacs[vmname] = tapVmMacs
        self.vmTapports[vmname] = tapports
        fname = os.getcwd() + "/" + vmname
        vmpidfile = fname + "/" + "pid"
        #Spawn SSH process and run the VM script
        if os.path.exists(fname):
            shutil.rmtree(fname)
        os.mkdir(fname)
        self.logmessage("Create VM pid file",0) 
        vmfile = fname + "/" + vmname
        vmpidfile = fname + "/pid"
        self.logmessage("VM pid file",0,vmpidfile) 
        fp = open(vmpidfile,'w')
        fp.close()
        fp = open(vmfile, 'w')
        vmcmd = "/usr/bin/qemu-system-x86_64 -name " + vmname + " -cpu host -m 1024 -smp sockets=1,cores=2,threads=1 -drive file="
        vmcmd += image + "," + "if=virtio --enable-kvm"
        vmcmd += " -net none -no-reboot -mem-path /mnt/huge_1G -mem-prealloc -netdev "
        vmcmd += "type=tap,id=hostnet1,script=no,downscript=no,ifname=" + tapport + ",vhost=on,vhostforce=on -device "
        vmcmd += "virtio-net-pci,netdev=hostnet1,id=net1,mac=" + tapVmMac
        if portname2 is not None:
            vmcmd += " -net none -no-reboot -mem-path /mnt/huge_1G -mem-prealloc -netdev "
            vmcmd += "type=tap,id=hostnet2,script=no,downscript=no,ifname=" + tapport1 + ",vhost=on,vhostforce=on -device "
            vmcmd += "virtio-net-pci,netdev=hostnet2,id=net2,mac=" + tapVmMac1
        vmcmd += ",csum=off,gso=off,guest_tso4=off,guest_tso6=off,guest_ecn=off "
        vmcmd += "-pidfile " + vmpidfile + " -nographic" 
        print vmcmd
        self.logmessage("QEMU command for VM creation:",0,vmcmd) 
        fp.write(vmcmd)
        fp.close()
        os.chmod(vmfile,stat.S_IEXEC)
        return vmfile
        # Run the VM command to start the VM

    def runVM(self,vmfile, portname1, portname2 = None):
        ret1, handle = self.createScreen(vmname)
        if ret1 > 0:
            retval += 1
            self.logmessage("Execution of screen command is failed",0) 
            return retval, handle
        # Run the VM command to start the VM
        sflag = 0 
        handle.timeout = 300
        handle.sendline(vmfile)
        try:
            if self.imagetype == "ZEROSHELL":
                handle.expect('Loading*')
            else:  
                handle.expect('initramfs*')
        except Exception as e:
                print e
        self.logmessage("VM is started Fine",0) 
        # Check the process is running or not
        self.logmessage("Check the process is running or not",0) 
        catcmd = 'cat ' + vmpidfile
        fp1 = commands.getoutput(catcmd)
        try:
            pidval = int(re.sub('\s+',"",fp1))
        except Exception as e:
            print e
            pidval = 0
            self.logmessage("No VM process is running and it returns null, VM creation is failed",1) 
            retval += 1
            handle.close()
            handle = self.null
            return retval, handle
        if pidval > 0:
            self.logmessage("VM process is running and its process id is",0,pidval) 
            self.logmessage("Waiting for 50 seconds to bring up VM",0) 
            time.sleep(50)
            self.logmessage("Check VM login and login to VM",0) 
            handle = self.vmLogin(vmname)
            if handle == self.null:
                self.logmessage("VM Got hanged, So kill the process",0) 
                self.stop_VM(vmname)
                retval += 1
                return retval, handle
        #Configure IP address
        #vmip = self.getIpAddrForVM()
        vmip = self.portnameIpList[portname1]
        #vimipconfig = "sudo ifconfig eth0 " + vmip + "/24" + " up"
        if self.imagetype == "ZEROSHELL":
            vimipconfig = "ifconfig ETH00 " + vmip + "/24" + " up"
        else:
            vimipconfig = "sudo ifconfig eth0 " + vmip + "/24" + " up"
        res = self.runVM_command(vimipconfig,handle)
        self.logmessage("",0,res) 
        if portname2 is not None:
            vmip = self.portnameIpList[portname2]
            if self.imagetype == "ZEROSHELL":
                vimipconfig = "sudo ifconfig ETH01 " + vmip + "/24" + " up"
            else:
                vimipconfig = "sudo ifconfig eth1 " + vmip + "/24" + " up"
            res = self.runVM_command(vimipconfig,handle)
            self.logmessage("",0,res) 
        # Check Hipvs tap port
        self.vmpids[vmname] = pidval
        self.logmessage("Check the HipVS Tap port status which is conencted to VM",0)
        if self.getPortStatus(tapport) == "up":
            self.logmessage("Hipvs Tap Port",0,tapport,"is UP and Running")
        else:
            self.logmessage("Hipvs Tap Port",1,tapport,"is either not UP or not found")
            retval += 1
        return retval, handle

    def killVMProcess(self, vmname, rIP = ""):
        retval = 0
        # Get the pid value
        print "Chandra"
        try:
            pidval = self.vmpids[vmname]
            del self.vmpids[vmname] 
        except Exception as e:
            print e
        if rIP:
            res = self.exec_remote_cmd(rIP,'pwd')
            resp = [] 
            for x in res.split('\n'):
                 resp.append(x)
            print resp
            fname = resp[1].strip() + "/" + vmname
        else:
            fname = os.getcwd() + "/" + vmname
        vmpidfile = fname + "/" + "pid"
        catcmd = 'cat ' + vmpidfile
        print catcmd
        if rIP:
            res = self.exec_remote_cmd(rIP,catcmd)
            resp = [] 
            for x in res.split('\n'):
                resp.append(x)
            fp1 = resp[1].strip()
        else:
            fp1 = commands.getoutput(catcmd)
        print fp1
        self.logmessage("command ",0,catcmd, "output is",fp1)
        pidval = int(re.sub('\s+',"",fp1))
        if pidval == 0:
             retval += 1
             return retval
        vmcmd = 'kill -9 ' + str(pidval)
        self.logmessage("Process pid value is",0,pidval)
        if rIP:
            fp1 = self.exec_remote_cmd(rIP,vmcmd)
        else:
            os.system(vmcmd)
        time.sleep(5)
        return retval

    def delHipvsPort(self, portname, rIP = ""):
        #Delete this tap port from Hipvs
        retval = 0 
        if rIP:
            if self.hipvsversion == "1.5":
                del_port_eth = "sudo ovs-vsctl" + " del-port BR0 " + portname
            else:
                del_port_eth = self.rhipvshome + "scripts/" + "hipvsctl" + " --delport " + portname
                self.logmessage("HIPVS Command:",0,del_port_eth) 
            del_interface_output = self.exec_remote_cmd(rIP,del_port_eth)
        else:
            if self.hipvsversion == "1.5":
		del_port_eth = "sudo ovs-vsctl" + " del-port BR0 " + portname
	    else:
	       del_port_eth = self.hipvshome + "scripts/" + "hipvsctl" + " --delport " + portname
	       self.logmessage("HIPVS Command:",0,del_port_eth) 
            f = os.popen(del_port_eth)
            del_interface_output = f.read()
            print del_interface_output
            f.close()
        self.logmessage("Delete port output :",0,del_interface_output) 
        # Verify that port
        ports = self.getHipvsPorts(rIP)
        self.logmessage("List of all Hipvs ports",0,ports)
        if portname in ports:
            retval += 1
            self.logmessage("Delete interface is Failed",1)
        else:
            self.logmessage("Delete interface is success",0) 
        return retval

    def stop_VM(self, vmname, rIP = ""):
        """It stop the VM and deletes VM configuration. It takes VM name is paramter
           i.e stop_VM()"""
        retval = 0
        # Remove the Tap port
        #Get the tapport information from QEMU command.
        if rIP:
            vmfile = "~/" + vmname + "/" + vmname
            catcmd = 'cat ' + vmfile
            out = self.exec_remote_cmd(rIP,catcmd)
            self.logmessage("Remote cat command output",0,out)
        else:
            fname = os.getcwd() + "/" + vmname
            vmfile = fname + "/" + vmname
            fp = open(vmfile,'r')
            out = fp.read()
        m = re.findall("ifname\=tap[0-9a-fA-F]{8}\-\d+",out)
        if m:
            for tapname in m:
                tapportname = tapname.split('=')[1].strip()
                self.logmessage("Tap Port is ",0,tapportname)
                #Delete this tap port from Hipvs
                if self.delHipvsPort(tapportname,rIP) > 0:
                    retval += 1 
        else:
            retval += 1 
            self.logmessage("Tap Port is not found from VM command",1,0)
        if self.killVMProcess(vmname,rIP) > 0:
            retval += 1
            self.logmessage("Kill VM Process is Failed",0)
            return retval 
        # Stop the screen
        self.destroyScreen(vmname, rIP)
        return retval
        
    def getHipvs_Status(self, rIP = ""):
        retval = 0
        hipvstatus = {}
        if rIP:
            if self.hipvsversion == "1.5": 
                #cmd = "service " + "hipvs_all" + " status"
                cmd = ost.HIPVSBIN + " status"
                cmd1 = "service openvswitch-switch status"
                self.logmessage("HIPVS Command:",0,cmd) 
                self.logmessage("OPENVS Command:",0,cmd1) 
                hipvsall_status = self.exec_remote_cmd(rIP,cmd)
                hipvsall_status1 = self.exec_remote_cmd(rIP,cmd1)
            else:
                cmd = self.rhipvshome +"scripts/" + "hipvs_all" + " status"
                self.logmessage("HIPVS Command:",0,cmd) 
                hipvsall_status = self.exec_remote_cmd(rIP,cmd)
        else:
            if self.hipvsversion == "1.5": 
                #cmd = "service " + "hipvs_all" + " status"
                cmd = ost.HIPVSBIN + " status"
                cmd1 = "service openvswitch-switch status"
                self.logmessage("HIPVS Command:",0,cmd) 
                self.logmessage("OPENVS Command:",0,cmd1) 
                f = os.popen(cmd)
                hipvsall_status = f.read()
                f.close()
                self.logmessage("",0,hipvsall_status) 
                f = os.popen(cmd1)
                hipvsall_status1 = f.read()
                f.close()
                self.logmessage("",0,hipvsall_status1) 
            else:
                cmd = self.hipvshome +"scripts/" + "hipvs_all" + " status"
                self.logmessage("HIPVS Command:",0,cmd) 
                f = os.popen(cmd)
                hipvsall_status = f.read()
                f.close()
                self.logmessage("",0,hipvsall_status) 
        print "HIPVS output", hipvsall_status
        print "HIPVS output", hipvsall_status1
        for x in hipvsall_status.split("\n"):
            if self.hipvsversion == "1.5": 
                if re.search("hipvs_us",x):
                    pname = x.split(" ")[0].strip()
                    pstatus = x.split(" ")[1].strip()
                    hipvstatus[pname] = pstatus.split("/")[0].strip()
            else:
                if re.search("hipvs_us",x) or re.search("syncd_us",x) or re.search("hipvs_dpagent_us",x) or re.search("ofagent_us",x):
                    pname = x.split(" ")[0].strip()
                    pstatus = x.split(" ")[1].strip()
                    hipvstatus[pname] = pstatus.split("/")[0].strip()
        if self.hipvsversion == "1.5":
            for x in hipvsall_status1.split("\n"):
                if re.search("openvswitch-switch",x):
                    pname = x.split(" ")[0].strip()
                    pstatus = x.split(" ")[1].strip()
                    hipvstatus[pname] = pstatus.split("/")[0].strip()
        print hipvstatus
        self.logmessage("",0,hipvstatus) 
        stopflag = 0
        for k,val in hipvstatus.items():
            print k, val
            if val == "stop":
                print "The Process ",k," Status is stop"
                stopflag += 1
        if stopflag > 0:
            self.logmessage("Some processes are STOPPED",0) 
            retval += 1
        return retval 
            
    def Hipvs_Start(self, rIP = ""):
        retval = 0
        if rIP:
            if self.hipvsversion == "1.5": 
                cmd = ost.HIPVSBIN + " start"
                cmd1 = "service openvswitch-switch start"
                hipvsall_status = self.exec_remote_cmd(rIP,cmd)
                hipvsall_status1 = self.exec_remote_cmd(rIP,cmd1)
                self.logmessage("",0,hipvsall_status) 
                self.logmessage("",0,hipvsall_status1) 
            else: 
                cmd = self.rhipvshome +"scripts/" + "hipvs_all" + " start"
                hipvsall_status = self.exec_remote_cmd(rIP,cmd)
                self.logmessage("",0,hipvsall_status) 
        else:
            if self.hipvsversion == "1.5": 
                #cmd = "service " + "hipvs_all" + " restart"
                cmd = ost.HIPVSBIN + " start"
                cmd1 = "service openvswitch-switch start"
                f = os.popen(cmd)
                hipvsall_status = f.read()
                f.close()
                f = os.popen(cmd1)
                hipvsall_status1 = f.read()
                f.close()
                self.logmessage("",0,hipvsall_status) 
                self.logmessage("",0,hipvsall_status1) 
            else: 
                cmd = self.hipvshome +"scripts/" + "hipvs_all" + " restart"
                f = os.popen(cmd)
                hipvsall_status = f.read()
                f.close()
                self.logmessage("",0,hipvsall_status) 
        time.sleep(10)
        #Wait for status
        for i in range(1,10):
            if self.getHipvs_Status(rIP) == 0:
                self.logmessage("Hipvs is running Fine",0) 
                break
            time.sleep(10)
        if self.getHipvs_Status(rIP) > 0:
             retval += 1
        return retval

    def stopVMList(self, *vmlist):
        for vminfo in vmlist:
            for x in vminfo:
                vinfo = x.split(":")
                if len(vinfo) > 2:
                    vmname = vinfo[0]
                    vmip = vinfo[1]
                    vmport1 = vinfo[2]
                    if len(vinfo) > 3:
                        vmport2 = vinfo[3]
                    else:
                        vmport2 = None
                    self.logmessage("VM Info:",0,vmname,vmip,vmport1,vmport2)
                    #vmcmdlist.append(self.configure_VM(image,vmport1,vmport2,vmname))
                    try:
                        if vmip == '0':
                            self.stop_VM(vmname)
                        else:
                            self.stop_VM(vmname,vmip)
                    except:
                        retval += 1
                        self.logmessage("Error: unable to start VM thread",1)
                else:
                    self.logmessage("VM Info is not proper",0,vinfo)
                    continue

    def startVMList(self, *vmlist):
        # Get all VM Info
        retval = 0
        self.threadList = []
        if self.getHipvs_Status() > 0:
            self.Hipvs_Start()
            time.sleep(30)
        self.delAllHipvsPorts()
        time.sleep(5)
        rflag = 0
        vmcmdlist = []
        for vminfo in vmlist:
            for x in vminfo:
                vinfo = x.split(":")
                print vinfo
                if len(vinfo) > 3:
                    vmimage = vinfo[0]
                    vmname = vinfo[1]
                    vmip = vinfo[2]
                    vmport1 = vinfo[3]
                    if len(vinfo) > 4:
                        vmport2 = vinfo[4]
                    else:
                        vmport2 = None
                    self.logmessage("VM Info:",0,vmname,vmip,vmport1,vmport2)
                    #vmcmdlist.append(self.configure_VM(image,vmport1,vmport2,vmname))
                    try:
                        if vmip == '0':
                            t = Thread(target=self.start_VM, args=(vmimage,vmport1,vmport2,vmname,))
                        else:
                            if rflag == 0:
                                if self.getHipvs_Status(vmip) > 0:
                                    self.Hipvs_Start(vmip)
                                    time.sleep(30)
                                self.delAllHipvsPorts(vmip)
                                rflag = 1
                            t = Thread(target=self.start_VM_Remote, args=(vmimage,vmport1,vmport2,vmip,vmname,))
                        self.threadList.append(t)
                        t.start()
                        time.sleep(5)
                    except:
                        retval += 1
                        self.logmessage("Error: unable to start VM thread",1)
                else:
                    self.logmessage("VM Info is not proper",0,vinfo)
                    #continue
        #Verify threads Status
        return self.verifyThreadStatus()
         

    def delete_subnet_uuid(self, uuid):
        """It deletes the sub network with given subnetwork name. interface parameters are as shown below.
           subnetname --->  Name of  the sub network which is going to be created
           i.e delete_subnet("mysubnet1")"""
        retval = 0
        #uuid = self.subnetnameList[subnetname]
        if self.datastoreconfig == "NO":
            odlurl = self.odlneutron + "subnets/" + uuid
        else:
            odlurl = self.odlneutron + "subnets/subnet/" + uuid
        try:
            resp = res.delete(self.odlsession, odlurl)
        except Exception as e:
            self.logmessage("Delete network exception is",0,e)
            retval += 1
            return retval
        self.logmessage("Response is:",0,resp.content)
        self.logmessage("Response is:",0,resp)
        if resp.status_code == self.delresp:
            self.logmessage("Delete subnet network is SUCCESS for uuid",0,uuid)
            #del self.subnetnameList[subnetname]
            del self.subnetIpList[uuid]
            self.logmessage("Subnet Name to uuid mapping List is:",0,self.subnetnameList)
            self.logmessage("Subnet IP to uuid mapping List is:",0,self.subnetIpList)
        else:
            self.logmessage("Delete subnet Network is FAILED for uuid",1,uuid)
            retval += 1
        return retval


    def verifyThreadStatus(self):
        retval = 0
        i = 0
        threadtime = 0
        while i < 30:
            flag = 0 
            for th in self.threadList:
                if th.is_alive() == True:
                    flag = 1
                    self.logmessage("Still Threads are alive",0)
                    break
            if flag == 0:
                self.logmessage("All threads completed execution and execution time is ",0,threadtime)
                break
            time.sleep(60)
            threadtime += 60
        if flag == 1:
            retval += 1
            self.logmessage("Execution all threads is not completed after ",0,threadtime,"and it looks some thread got hanged ")
        self.threadList = []
        return retval    
                       
    def __del__(self):
        self.logmessage("Cleanup the class, closing the REST connection",0) 
        self.sid.close()
        self.datastore.close()

#==================================================================
#p = Openstack("10.183.254.140")
#p.delete_all_net()
#p.create_network("vpn2")
#p.get_network_ids()

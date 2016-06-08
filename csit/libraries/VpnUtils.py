#! /usr/bin/python

import re
import json
from RequestsLibrary import RequestsLibrary
from random import choice
import pexpect

# Library for the robot based system test tool of the Ericsson SDN Project.
# ######################################################################
# Description: This library provides Openstack simulator functions    #
# ######################################################################

"""
Library for the robot based system test tool of the Ericsson SDN Project.
 This library provides L3VPN service functions
"""

__author__ = "Chandra Bammidi"
__copyright__ = "Copyright 2016, Ericsson"
__version__ = "1.0.1"

param = "openstackconfig"
ost = __import__(param)

try:
    import paramiko
except ImportError:
    raise ImportError(
        'Importing Paramiko library failed. '
        'Make sure you have Paramiko installed.'
    )

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

res = RequestsLibrary()


class Openstack(object):
    """This class is used for creating neutron networks,subnets and
       ports with different options"""
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
        self.suname = "jenkins"
        self.minninetpasswd = "jenkins"
        self.ofctlcmd = "sudo ovs-ofctl"
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

    def gen_id(self):
        """It is helper function used inside the main functions"""
        X = choice("0123456789ABCDEF")
        return str(X)

    def getNeutronPorts(self):
        """It is helper function used inside the main functions"""
        return self.portnameIpList

    def getTapPorts(self):
        """It is helper function used inside the main functions"""
        return self.tapportnameList

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
        """ It returns List of ports Information
            which are configured on the node"""
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

    def remoteVMExec(self, host, cmd):
        res = None
        try:
            print "Connecting to the Node"
            self.logmessage("Connecting to the Node  ", 0, host)
            client.connect(host, username=self.suname,
                           password=self.minninetpasswd, timeout=60)
        except:
            return res
        self.logmessage("Executing command  ", 0)
        stdin, stdout, stderr = client.exec_command(cmd)
        res = stdout.read()
        stdout.close()
        stdin.close()
        client.close()
        self.logmessage("Response is   ", res)
        return res

    def get_interfaceConfigData(self):
        """This function gets the ietf interface config data from
           config data store"""
        odlurl = "/restconf/config/ietf-interfaces:interfaces/"
        resp = res.get(self.vpnsession, odlurl)
        print resp.content
        self.logmessage("All vlan interfaces config datastore ", 0,
                        resp.content)
        return resp

    def get_interfaceOperState(self):
        """This function gets the ietf interface states from
           operational data store"""
        odlurl = "/restconf/operational/ietf-interfaces:interfaces-state/"
        resp = res.get(self.vpnsession, odlurl)
        print resp.content
        self.logmessage("All vlan interfaces operational state ", 0,
                        resp.content)
        return resp

    def get_nodeInventory(self):
        """This function gets the node inventory from
           operational data store"""
        odlurl = "/restconf/operational/opendaylight-inventory:nodes/"
        resp = res.get(self.vpnsession, odlurl)
        print resp.content
        self.logmessage("Node inventory data ", 0, resp.content)
        return resp

    def create_l3vpn(self, name, RD, importRT, exportRT):
        """It creates the L3VPN and parameters are as shown below.
           name --->  Name of  the network
           nettype --->  Network type, if you don't pass this,
                         it takes default value as local
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

    def connectNode(self, hostip, uname, pword):
        login_command = 'ssh ' + hostip + ' -l ' + uname
        self.logmessage("login command", 0, login_command)
        print hostip
        spawn_id = pexpect.spawn(login_command)
        spawn_id.setecho(True)
        i = spawn_id.expect([pexpect.TIMEOUT, 'Password:',
                            pexpect.EOF, r"yes/no"])
        if i == 0:
                spawn_id.sendline(pword)
                spawn_id.expect('> ')
                return spawn_id
        elif i == 1:
                spawn_id.sendline(pword)
                spawn_id.expect('> ')
                return spawn_id

        elif i == 3:
                spawn_id.sendline('yes')
                spawn_id.expect('assword:')
                spawn_id.sendline(pword)
                spawn_id.expect('> ')
                return spawn_id

    def getDpnId(self, brname, ovsip, ovs_passwd):
        cmd = self.ofctlcmd + " " + "show " + brname + " -O OpenFlow13"
        self.logmessage("", 0, cmd)
        output = self.remoteVMExec(ovsip, cmd)
        self.logmessage("", 0, output)
        m = re.search("OFPT_FEATURES_REPLY.*", output)
        if m:
            line = m.group()
            self.logmessage("", 0, line)
            l1 = re.search("dpid:[\d\w]+", line)
            if l1:
                dpnid = int(l1.group().split(":")[1].strip(), 16)
            else:
                dpnid = None
        else:
            dpnid = None
        self.logmessage("DPN id: ", 0, dpnid)
        return dpnid

    def remoteExecCmd(self, hostip, ovs_passwd, kvmCmd):
        handle = self.connectNode(hostip, self.suname, ovs_passwd)
        handle.sendline(kvmCmd)
        handle.expect('>')
        datapoolbefore = handle.before
        datapoolafter = handle.after
        resultdata = datapoolbefore + datapoolafter
        print resultdata
        handle.close()
        return resultdata

    def get_Vm_List(self, ovsip, ovs_passwd):
        cmd = "virsh list"
        output = self.remoteVMExec(ovsip, cmd)
        self.logmessage("virsh list output", 0, output)
        vminstList = re.findall("\w+\-\d+\w+", output)
        self.logmessage("VM list is ", 0, vminstList)
        return vminstList

    def run_Command_Nova_VM(self, ovsip, ovs_passwd, vm_indx, cmd, exp_str):
            vmList = self.get_Vm_List(ovsip, ovs_passwd)
            login_nova_vm = "virsh console " + str(vmList[vm_indx])
            self.logmessage("Login to VM instance *** : ", 0, login_nova_vm)
            spawn_id = self.connectNode(ovsip, self.suname, ovs_passwd)
            spawn_id.setecho(True)
            spawn_id.timeout = 300
            self.logmessage("sending virsh console comd-logintoNOVA VM: ", 0)
            spawn_id.sendline(login_nova_vm)
            spawn_id.expect("Escape")
            self.logmessage("Logged in to VM: ", 0)
            spawn_id.sendline('\r')
            i = spawn_id.expect([pexpect.TIMEOUT, 'test',
                                 ".*login: ", pexpect.EOF])
            print i
            result = str(spawn_id.before) + str(spawn_id.after)
            self.logmessage("Output before login: ", 0, result)
            if i == 2:
                self.logmessage("Reached Here: ", 0)
                spawn_id.sendline("cirros")
                spawn_id.expect("assword: ")
                self.logmessage("Reached: ", 0)
                spawn_id.sendline("cubswin:)")
                spawn_id.expect("\$")

            elif i == 1:
                self.logmessage("Already logged in, So Got the prompt: ", 0)

            elif i == 0:
                self.logmessage("Pexpect timed out ", 0)
                return 1
            else:
                self.logmessage("Unknown error ", 0)
                return 1
            self.logmessage("Reached: ", 0)
            spawn_id.setecho(True)
            spawn_id.sendline(cmd)
            spawn_id.expect(exp_str)
            self.logmessage("Logged: ", 0)
            result = spawn_id.before + spawn_id.after
            self.logmessage("Output is: ", 0, result)
            spawn_id.sendline("exit")
            spawn_id.expect('.*login: ')
            spawn_id.close()
            return result

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
           and similarly source and destination bridge,
           gateway ip, vlanid, tunnel-type and zone name"""
        retval = 0
        srcbr = "br-int"
        dstbr = "br-int"
        gwip = "0.0.0.0"
        vlanid = 0
        tuntype = "odl-interface:tunnel-type-vxlan"
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
                if k == 'ovs_pwd':
                    ovs_pwd = val

        # Get tunnel bridge ids
        m = re.search('\d+\.\d+\.\d+', srcip)
        if m:
            prefix_val = m.group() + ".0/24"
        else:
            self.logmessage("Source IP is not proper", 0, srcip)
            retval += 1
            return retval

        dpnId1 = self.getDpnId(srcbr, srcip, ovs_pwd)
        if dpnId1 is None:
            self.logmessage("Source Bridge is None", 0)
            retval += 1
            return retval
        dpnId2 = self.getDpnId(dstbr, dstip, ovs_pwd)
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

    def associate_router(self, routerID, vpnid):
        retval = 0
        net_ass_conf = {"input": {"vpn-id": vpnid, "router-id": routerID}}
        self.logmessage("JSON value of l3vpn", 0, net_ass_conf)
        odlurl5 = "/restconf/operations/neutronvpn:associateRouter"
        try:
            resp = res.postjson(self.vpnsession, odlurl5, data=net_ass_conf)
        except Exception as e:
            self.logmessage("Create Network Exception is", 0, e)
            retval += 1
            return retval
        self.logmessage("Response Info:", 0, resp)
        self.logmessage("Port Resp Status code:", 0, resp.status_code)
        self.logmessage("Port Info:", 0, resp.content)
        if resp.status_code == 200:
            self.logmessage("Associate router through uuid is passed")
        else:
            self.logmessage("Associate router through uuid failed")
            retval += 1
        return retval

    def dissociate_router(self, routerID, vpnid):
        retval = 0
        net_ass_conf = {"input": {"vpn-id": vpnid, "router-id": routerID}}
        self.logmessage("JSON value of l3vpn", 0, net_ass_conf)
        odlurl5 = "/restconf/operations/neutronvpn:dissociateRouter"
        try:
            resp = res.postjson(self.vpnsession, odlurl5, data=net_ass_conf)
        except Exception as e:
            self.logmessage("Create Network Exception is", 0, e)
            retval += 1
            return retval
        self.logmessage("Response Info:", 0, resp)
        self.logmessage("Port Resp Status code:", 0, resp.status_code)
        self.logmessage("Port Info:", 0, resp.content)
        if resp.status_code == self.postresp:
            self.logmessage("dissociate router through uuid is passed")
        else:
            self.logmessage("dissociate router through uuid")
            retval += 1
        return retval

    def __del__(self):
        self.logmessage("Cleanup the class, closing the REST connection", 0)
        self.sid.close()
        self.datastore.close()

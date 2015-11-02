"""
Script to add bridges/ports/termination points to ovsdb config
"""
__author__ = 'Marcus Williams'
__copyright__ = "Copyright (c) 2015, Intel Corp Inc., Cisco Systems Inc. and others"
__credits__ = ["Jan Medved, Lori Jakab"]
__license__ = "New-style BSD"
__email__ = "marcus.williams@intel.com"
__version__ = "0.0.1"

import argparse
import json
import logging
import requests


class OvsdbConfigBlaster (object):
    PUT_HEADER = {'Content-type': 'application/json'}
    GET_HEADER = {'Accept': 'application/json'}
    TIMEOUT = 10

    def __init__(self,
                 controller_ip,
                 controller_port,
                 vswitch_ip,
                 vswitch_ovsdb_port,
                 vswitch_remote_ip,
                 vswitch_remote_ovsdb_port,
                 vswitch_port_type,
                 num_instances):
        """
        Args:
            :param controller_ip: The ODL host ip used to send RPCs
            :param controller_port: The RESTCONF port on the ODL host
            :param vswitch_ip: The ip of Open vSwitch to use
            :param vswitch_ovsdb_port: The ip of Open vSwitch to use
            :param num_instances: The number of instances (bridges, ports etc) to be added
        """
        logging.basicConfig(level=logging.DEBUG)
        self.session = requests.Session()
        self.controller_ip = controller_ip
        self.controller_port = controller_port
        self.vswitch_0_ip = vswitch_ip
        self.vswitch_0_ovsdb_port = vswitch_ovsdb_port
        self.vswitch_0_node_id = "ovsdb://%s:%s" % (self.vswitch_0_ip,
                                                  self.vswitch_0_ovsdb_port)
        self.vswitch_1_ovsdb_port = vswitch_remote_ovsdb_port
        self.vswitch_1_ip = vswitch_remote_ip
        self.vswitch_1_node_id = "ovsdb://%s:%s" % (self.vswitch_1_ip,
                                                    self.vswitch_1_ovsdb_port)
        self.vswitch_port_type = vswitch_port_type
        self.num_instances = num_instances

        # URLs for config / operational rest calls
        self.ovsdb_config_url = 'restconf/config/network-topology:' \
                                'network-topology/topology/ovsdb:1/node/ovsdb:%2F%2F' \
                                + self.vswitch_0_ip + ':' + self.vswitch_0_ovsdb_port
        self.ovsdb_oper_url = 'restconf/operational/network-topology:' \
                              'network-topology/topology/ovsdb:1/node/ovsdb:%2F%2F' \
                              + self.vswitch_0_ip + ':' + self.vswitch_0_ovsdb_port

        self.ovsdb_post_url = 'http://' + self.controller_ip + \
                              ':' + self.controller_port + \
                              '/' + self.ovsdb_config_url

        self.connect_vswitch(self.vswitch_0_node_id, self.vswitch_0_ip, self.vswitch_0_ovsdb_port)
        if self.vswitch_1_ip:
            self.connect_vswitch(self.vswitch_1_node_id, self.vswitch_1_ip, self.vswitch_1_ovsdb_port)

    def connect_vswitch(self, vswitch_node_id, vswitch_ip, vswitch_port):
        # Connecting to ovs instance body of JSON
        connect_ovs_body = {
            u"network-topology:node": [
                {
                    u"node-id": unicode(vswitch_node_id),
                    u"connection-info": {
                        u"ovsdb:remote-port": unicode(vswitch_port),
                        u"ovsdb:remote-ip": unicode(vswitch_ip)
                    }
                }
            ]
        }
        # Send rest COMMAND for ODL to Connect to Open vSwitch instance
        ret = self.send_rest(self.session, self.ovsdb_post_url, connect_ovs_body)
        if ret is not '200':
            raise RuntimeError(ret, self.ovsdb_post_url, json.dumps(dict(connect_ovs_body)))

    def add_bridge(self):
        """Add self.num_instances of bridge to ODL config"""
        bridge_prefix = "br-"

        # URLs for getting/putting OVSDB Bridge
        # self.ovsdb_config_bridge_url = self.ovsdb_config_url + '%2Fbridge%2F'
        # + bridge_name
        # self.ovsdb_oper_bridge_url = self.ovsdb_oper_url + '%2Fbridge%2F'
        # + bridge_name

        for i in range(self.num_instances):
            bridge_name = unicode(bridge_prefix + str(i) + '-test')
            add_bridge_body = {
                u"network-topology:node": [
                    {
                        u"node-id": u"ovsdb://%s/bridge/%s" % (unicode(self.vswitch_0_node_id),
                                                               unicode(bridge_name)),
                        u"ovsdb:bridge-name": unicode(bridge_name),
                        u"ovsdb:datapath-id": u"00:00:b2:bf:48:25:f2:4b",
                        u"ovsdb:protocol-entry": [
                            {
                                u"protocol":
                                    u"ovsdb:ovsdb-bridge-protocol-openflow-13"
                            }
                        ],
                        u"ovsdb:controller-entry": [
                            {
                                u"target": u"tcp:%s:%s" % (self.controller_ip,
                                                           self.controller_port)
                            }
                        ],
                        u"ovsdb:managed-by": u"/network-topology:network-topology/"
                                             u"network-topology:topology"
                                             u"[network-topology:topology-id"
                                             u"='ovsdb:1']/network-topology:node"
                                             u"[network-topology:node-id="
                                             u"'%s']" % unicode(self.vswitch_0_node_id)
                    }
                ]
            }
            ret = self.send_rest(self.session, self.ovsdb_post_url + '/bridge/'
                                 + bridge_name, add_bridge_body)
            if ret is not '200':
                raise RuntimeError(ret, self.ovsdb_post_url + '/bridge/'
                                   + bridge_name, json.dumps(dict(add_bridge_body)))
        self.session.close()

    def add_port(self, remote_ip, port_type=u"ovsdb:interface-type-vxlan"):
        """Add self.num_instances of port to ODL config"""
        tp_prefix = "tp-"

        self.add_bridge()
        bridge_name = 'br-1-test'
        for i in range(self.num_instances):
            tp_name = unicode(tp_prefix + str(i) + 'test')
            add_tp_body = {
                u"network-topology:termination-point":
                [
                    {
                        u"ovsdb:options": [
                            {
                                u"ovsdb:option": u"remote_ip",
                                u"ovsdb:value": unicode(remote_ip)
                            }
                        ],
                        u"ovsdb:name": unicode(tp_name),
                        u"ovsdb:interface-type": unicode(port_type),
                        u"tp-id": unicode(tp_name),
                        u"vlan-tag": unicode(i),
                        u"trunks": [
                            {
                                u"trunk": u"5"
                            }
                        ],
                        u"vlan-mode": u"access"
                    }
                ]
            }
            ret = self.send_rest(self.session, self.ovsdb_post_url + '/bridge/'
                                 + bridge_name
                                 + '/termination-point/'
                                 + tp_name
                                 , add_tp_body)
            if ret is not '200':
                raise RuntimeError(ret, self.ovsdb_post_url + '/bridge/'
                                   + bridge_name, json.dumps(dict(add_tp_body)))
        self.session.close()

    def send_rest(self, session, rest_url, json_body):
        """Send an HTTP POST to the Rest URL and return the status code
        Args:
            :param session: The HTTP session handle
            :param body: the JSON body to be sent
        Returns:
            :return int: status_code - HTTP status code
        """
        rest_call = dict(json_body)
        rest_call_json_body = json.dumps(rest_call)
        ret = session.post(rest_url,
                           data=rest_call_json_body,
                           headers=self.PUT_HEADER,
                           stream=False,
                           auth=('admin', 'admin'),
                           timeout=self.TIMEOUT)
        return ret.status_code

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Add bridge/port/term-points'
                                                 ' to OpenDaylight')

    parser.add_argument('--mode', default='bridge',
                        help='Operating mode, can be "bridge", "port" or "term" \
                            (default is "bridge")')
    parser.add_argument('--controller', default='127.0.0.1',
                        help='IP of running ODL controller (default \
                            is 127.0.0.1)')
    parser.add_argument('--controllerport', default='8181',
                        help='Port of ODL RESTCONF \
                            (default is 8181)')
    parser.add_argument('--vswitch', default='127.0.0.1',
                        help='IP of Open vSwitch \
                            (default is 127.0.0.1)')
    parser.add_argument('--vswitchport', default='6640',
                        help='Port of Open vSwitch OVSDB server \
                            (default is 6640)')
    parser.add_argument('--vswitchremote', default=None,
                        help='IP of remote Open vSwitch \
                            (default is none)')
    parser.add_argument('--vswitchremoteport', default=None,
                        help='Port of remote Open vSwitch OVSDB server \
                            (default is none)')
    parser.add_argument('--vswitchporttype', default=None,
                        help='Port of remote Open vSwitch OVSDB server \
                            (default is none)')
    parser.add_argument('--instances', type=int, default=1,
                        help='Number of instances to add/get (default 1)')

    in_args = parser.parse_args()

    ovsdb_config_blaster = OvsdbConfigBlaster(in_args.controller,
                                              in_args.controllerport,
                                              in_args.vswitch,
                                              in_args.vswitchport,
                                              in_args.vswitchremote,
                                              in_args.vswitchremoteport,
                                              in_args.vswitchporttype,
                                              in_args.instances)

    if in_args.mode == "bridge":
        ovsdb_config_blaster.add_bridge()
    elif in_args.mode == "port" and in_args.vswitchporttype:
        ovsdb_config_blaster.add_port(ovsdb_config_blaster.vswitch_1_ip, in_args.vswitchporttype)
    elif in_args.mode == "term":
        ovsdb_config_blaster.add_port(ovsdb_config_blaster.vswitch_1_ip)
    else:
        print "Unsupported mode:", in_args.mode

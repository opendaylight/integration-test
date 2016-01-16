"""
Script to add bridges/ports/termination points to ovsdb config
"""
import argparse
import logging
import requests

__author__ = 'Marcus Williams'
__copyright__ = "Copyright (c) 2015, Intel Corp Inc., Cisco Systems Inc. and others"
__credits__ = ["Jan Medved, Lori Jakab"]
__license__ = "New-style BSD"
__email__ = "marcus.williams@intel.com"
__version__ = "0.0.1"


class OvsdbConfigBlaster (object):
    PUT_HEADERS = {'Content-Type': 'application/json',
                   'Authorization': 'Basic YWRtaW46YWRtaW4=',
                   'Accept': 'application/json'}
    GET_HEADERS = {'Accept': 'application/json',
                   'Authorization': 'Basic YWRtaW46YWRtaW4='}
    DELETE_HEADERS = {'Accept': 'application/json',
                      'Authorization': 'Basic YWRtaW46YWRtaW4='}
    TIMEOUT = 10

    def __init__(self,
                 controller_ip,
                 controller_port,
                 vswitch_ip,
                 vswitch_ovsdb_port,
                 vswitch_remote_ip,
                 vswitch_remote_ovsdb_port,
                 vswitch_port_type,
                 vswitch_lst_del_br,
                 delete_ports,
                 num_instances):
        """
        Args:
            :param controller_ip: The ODL host ip used to send RPCs
            :param controller_port: The RESTCONF port on the ODL host
            :param vswitch_ip: The ip of OpenvSwitch to use
            :param vswitch_ovsdb_port: The ovsdb port of OpenvSwitch to use
            :param vswitch_remote_ip: The ip of remote OpenvSwitch to use
            :param vswitch_remote_ovsdb_port: The ovsdb port of remote OpenvSwitch to use
            :param vswitch_port_type: Port type to create
            :param vswitch_lst_del_br: string containing a list of ovs switches on which BR'S should be deleted.
            :param num_instances: The number of instances (bridges, ports etc)to be added
            :param delete_ports: The number of ports to be deleted from a bridge
        """
        logging.basicConfig(level=logging.DEBUG)
        self.session = requests.Session()
        self.controller_ip = controller_ip
        self.controller_port = controller_port
        self.vswitch_dict = dict()
        self.add_vswitch_to_dict(
            vswitch_ip,
            vswitch_remote_ip,
            vswitch_ovsdb_port, 'ovs-1')
        if vswitch_remote_ip:
            self.add_vswitch_to_dict(
                vswitch_remote_ip,
                vswitch_ip,
                vswitch_remote_ovsdb_port, 'ovs-2')
        self.vswitch_port_type = vswitch_port_type
        self.vswitch_lst_del_br = vswitch_lst_del_br
        self.num_instances = num_instances
        self.delete_ports = delete_ports
        self.connect_vswitch(self.vswitch_dict['ovs-1'])
        if self.vswitch_dict.get('ovs-2'):
            self.connect_vswitch(self.vswitch_dict['ovs-2'])

    @staticmethod
    def return_ovsdb_url(vswitch_ip, vswitch_ovsdb_port, url_type="config"):
        """ Return an ovsdb restconf url
        Args:
            :param vswitch_ip: The ip of Open vSwitch to use
            :param vswitch_ovsdb_port: The ovsdb port of Open vSwitch to use
            :param url_tyep: The type of url 'config' | 'oper'
        """
        url_prefix = None
        if url_type == "config":
            url_prefix = 'restconf/config/'
        elif url_type == "oper":
            url_prefix = 'restconf/operational/'
        ovsdb_url = url_prefix \
            + 'network-topology:' \
            'network-topology/topology/' \
            'ovsdb:1/node/ovsdb:%2F%2F' \
            + vswitch_ip\
            + ':' \
            + vswitch_ovsdb_port
        return ovsdb_url

    def add_vswitch_to_dict(self, vswitch_ip, vswitch_remote_ip, vswitch_ovsdb_port, vswitch_name):

        """ Add details of an Open vSwitch instance to self.vswitch_dict
        Args:
            :param vswitch_ip: The ip of Open vSwitch to use
            :param vswitch_remote_ip: The ip of remote Open vSwitch to use
            :param vswitch_ovsdb_port: The ovsdb port of Open vSwitch to use
            :param vswitch_name: The name to label the added Open vSwitch instance
        """
        urlprefix = 'http://' \
                    + self.controller_ip + \
                    ':' \
                    + self.controller_port + \
                    '/'
        self.vswitch_dict.update({
            vswitch_name: {
                'name': vswitch_name,
                'ip': vswitch_ip,
                'remote-ip': vswitch_remote_ip,
                'ovsdb-port': vswitch_ovsdb_port,
                'node-id': 'ovsdb://%s:%s'
                           % (vswitch_ip,
                              vswitch_ovsdb_port),
                'post-url': urlprefix +
                OvsdbConfigBlaster.return_ovsdb_url(
                    vswitch_ip,
                    vswitch_ovsdb_port),
                'get-config-url': urlprefix +
                OvsdbConfigBlaster.return_ovsdb_url(
                    vswitch_ip,
                    vswitch_ovsdb_port),
                'get-oper-url': urlprefix +
                OvsdbConfigBlaster.return_ovsdb_url(
                    vswitch_ip,
                    vswitch_ovsdb_port)}})

    def connect_vswitch(self, vswitch_dict):
        """ Connect ODL to an Open vSwitch instance using restconf
        Args:
            :param vswitch_dict: A dictionary detailing
                                 an instance of Open vSwitch
        """
        connect_ovs_body = {
            u'network-topology:node': [
                {
                    u'node-id': unicode(vswitch_dict['node-id']),
                    u'connection-info': {
                        u'ovsdb:remote-port': unicode(vswitch_dict['ovsdb-port']),
                        u'ovsdb:remote-ip': unicode(vswitch_dict['ip'])
                    }
                }
            ]
        }
        self.send_rest(self.session,
                       vswitch_dict['post-url'],
                       connect_ovs_body)

    def add_bridge(self, num_instances, vswitch_name='ovs-1'):
        """Add num_instances of bridge to ODL config
        Args:
            :param num_instances: Number of bridges to create
            :param vswitch_name: A name describing
                                 an instance of Open vSwitch
        """

        for i in range(num_instances):
            bridge_name = unicode('br-' + str(i) + '-test')
            add_bridge_body = {
                u"network-topology:node": [
                    {
                        u"node-id": u"%s/bridge/%s"
                                    % (unicode(self.vswitch_dict[vswitch_name]
                                               .get('node-id')),
                                       unicode(bridge_name)),
                        u"ovsdb:bridge-name": unicode(bridge_name),
                        u"ovsdb:datapath-id": u"00:00:b2:bf:48:25:f2:4b",
                        u"ovsdb:protocol-entry": [
                            {
                                u"protocol":
                                    u"ovsdb:ovsdb-bridge-protocol-openflow-13"
                            }],
                        u"ovsdb:controller-entry": [
                            {
                                u"target": u"tcp:%s:%s" % (self.controller_ip, self.controller_port)
                            }],
                        u"ovsdb:managed-by": u"/network-topology:network-topology/"
                                             u"network-topology:topology"
                                             u"[network-topology:topology-id"
                                             u"='ovsdb:1']/network-topology:node"
                                             u"[network-topology:node-id="
                                             u"'%s']"
                                             % unicode(self.vswitch_dict[vswitch_name]
                                                           .get('node-id'))
                    }
                ]
            }
            self.send_rest(self.session,
                           self.vswitch_dict[vswitch_name]
                           .get('post-url') +
                           '%2Fbridge%2F' +
                           bridge_name,
                           add_bridge_body)
        self.session.close()

    def add_port(self, port_type="ovsdb:interface-type-vxlan"):
        """Add self.num_instances of port to ODL config
        Args:
            :param port_type: The type of port to create
                                default: 'ovsdb:interface-type-vxlan'
        """
        bridge_name = 'br-0-test'
        self.add_bridge(1, 'ovs-1')
#        self.add_bridge(1, 'ovs-2')

        for instance in range(self.num_instances):
            for vswitch in self.vswitch_dict.itervalues():
                if port_type == "ovsdb:interface-type-vxlan":
                    port_prefix = "tp-"
                    ovsdb_rest_url = vswitch.get('post-url') \
                        + '%2Fbridge%2F'\
                        + bridge_name\
                        + '/termination-point/'
                    body_name = 'tp-body'
                else:
                    port_prefix = "port-"
                    ovsdb_rest_url = vswitch.get('post-url') \
                        + '%2Fbridge%2F' \
                        + bridge_name\
                        + '/port/'
                    body_name = 'port-body'
                port_name = port_prefix + str(instance) + '-test-' + vswitch.get('ip')
                body = {'tp-body': {
                    u"network-topology:termination-point": [
                        {
                            u"ovsdb:options": [
                                {
                                    u"ovsdb:option": u"remote_ip",
                                    u"ovsdb:value": unicode(vswitch.get('remote-ip'))
                                }
                            ],
                            u"ovsdb:name": unicode(port_name),
                            u"ovsdb:interface-type": unicode(port_type),
                            u"tp-id": unicode(port_name),
                            u"vlan-tag": unicode(instance + 1),
                            u"trunks": [
                                {
                                    u"trunk": u"5"
                                }
                            ],
                            u"vlan-mode": u"access"
                        }
                    ]
                },
                    # TODO add port-body
                    'port-body': {}}
                self.send_rest(self.session,
                               ovsdb_rest_url + port_name,
                               body.get(body_name))

        self.session.close()

    def delete_bridge(self, vswitch_lst_del_br, num_bridges):
        """Delete num_instances of bridge in ODL config
        Args:
            :param num_bridges: Number of bridges to delete
            :param vswitch_lst_del_br: A list containing instances of Open vSwitch on which bridges should be deleted.
        """
        for vswitch_names in vswitch_lst_del_br:
            for br_num in range(num_bridges):
                bridge_name = unicode('br-' + str(br_num) + '-test')
                self.send_rest_del(self.session,
                                   self.vswitch_dict[vswitch_names]
                                   .get('post-url') +
                                   '%2Fbridge%2F' +
                                   bridge_name)
            self.session.close()

    def delete_port(self, num_ports):
        """Delete ports from ODL config
         Args:
            :param num_ports: Number of ports to delete
        """
        for port in range(num_ports):
            bridge_name = 'br-0-test'
            for vswitch in self.vswitch_dict.itervalues():
                port_prefix = "tp-"
                ovsdb_rest_url = vswitch.get('post-url') \
                    + '%2Fbridge%2F' \
                    + bridge_name \
                    + '/termination-point/'
                port_name = port_prefix + str(port) + '-test-' + vswitch.get('ip')
                self.send_rest_del(self.session,
                                   ovsdb_rest_url + port_name)
                self.session.close()

    def send_rest_del(self, session, rest_url):
        """Send an HTTP DELETE to the Rest URL and return the status code
        Args:
            :param session: The HTTP session handle
            :return int: status_code - HTTP status code
        """
        ret = session.delete(rest_url,
                             headers=self.DELETE_HEADERS,
                             stream=False,
                             timeout=self.TIMEOUT)

        if ret.status_code is not 200:
            raise ValueError(ret.text,
                             ret.status_code,
                             rest_url)
        return ret.status_code

    def send_rest(self, session, rest_url, json_body):
        """Send an HTTP PUT to the Rest URL and return the status code
        Args:
            :param session: The HTTP session handle
            :param json_body: the JSON body to be sent
        Returns:
            :return int: status_code - HTTP status code
        """
        ret = session.put(rest_url,
                          json=json_body,
                          headers=self.PUT_HEADERS,
                          stream=False,
                          timeout=self.TIMEOUT)

        if ret.status_code is not 200:
            raise ValueError(ret.text,
                             ret.status_code,
                             rest_url,
                             json_body)
        return ret.status_code

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Add:delete bridge/port/term-points to OpenDaylight')

    parser.add_argument('--mode', default='None',
                        help='Operating mode, can be "bridge", "port" or "term" \
                            (default is "bridge")')
    parser.add_argument('--controller', default='127.0.0.1',
                        help='IP of running ODL controller \
                             (default is 127.0.0.1)')
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
    parser.add_argument('--deletebridges', nargs='*', type=str, default=None,
                        help='A list of switches on which to delete bridges, '
                             'uses instances for number of bridges. \
                              Example: "ovs-1 ovs2" \
                            (default is none)')
    parser.add_argument('--deleteports', type=int, default=1,
                        help='delete ports of remote open vswitch ovsdb server (default 1)')
    parser.add_argument('--instances', type=int, default=1,
                        help='Number of instances to add/get (default 1)')

    args = parser.parse_args()

    ovsdb_config_blaster = OvsdbConfigBlaster(args.controller,
                                              args.controllerport,
                                              args.vswitch,
                                              args.vswitchport,
                                              args.vswitchremote,
                                              args.vswitchremoteport,
                                              args.vswitchporttype,
                                              args.deletebridges,
                                              args.deleteports,
                                              args.instances)
    if args.mode == "bridge":
        if args.deletebridges is not None:
            ovsdb_config_blaster.delete_bridge(ovsdb_config_blaster.
                                               vswitch_lst_del_br,
                                               ovsdb_config_blaster.
                                               num_instances)
        else:
            ovsdb_config_blaster.add_bridge(ovsdb_config_blaster.num_instances)
    elif args.mode == "term":
        if args.deleteports is not None:
            ovsdb_config_blaster.delete_port(ovsdb_config_blaster.delete_ports)
        else:
            ovsdb_config_blaster.add_port()
    else:
        print "please use: python ovsdbconfigblaster.py --help " \
              "\nUnsupported mode: ", args.mode

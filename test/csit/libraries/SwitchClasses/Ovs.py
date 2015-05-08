"""
Provision 3800 Object Definition
Authors: james.luhrsen@hp.com
Created: 2014-10-02
"""
import re
from BaseSwitch import *  # noqa


class Ovs(BaseSwitch):
    '''
    OpenVswitch Class
    '''

    make = 'OpenVswitch'
    model = 'OVS'

    mgmt_protocol = 'ssh'
    mgmt_ip = ''
    mgmt_port = ''
    mgmt_user = 'mininet'
    mgmt_password = 'mininet'

    mgmt_prompt = '>'

    initialization_type = 'cleanup'

    @property
    def connection_configs(self):
        return ['pwd']

    @property
    def cleanup_cmds(self):
        return ['/sbin/ifconfig -a | egrep \'^s\' | awk \'{print \"sudo ovs-vsctl del-br\",$1}\' | sh']

    @property
    def initialization_cmds(self):
        return [self.cleanup_cmds]

    @property
    def base_openflow_config(self):
        return ['sudo ovs-vsctl add-br s1',
                'sudo ovs-vsctl set bridge s1 protocols=OpenFlow13',
                'sudo ovs-vsctl set-controller s1 tcp:' + self.of_controller_ip,
                'sudo ifconfig s1 up']

    @property
    def openflow_validation_cmd(self):
        return 'sudo ovs-vsctl show'

    @property
    def openflow_enable_config(self):
        return ['sudo ovs-vsctl set-controller s1 tcp:' + self.of_controller_ip]

    @property
    def openflow_enable_validations(self):
        return ['is_connected: true']

    invalid_of_controller_ip = '1.1.1.1'

    @property
    def openflow_disable_config(self):
        return ['sudo ovs-vsctl set-controller s1 tcp:' + self.invalid_of_controller_ip]

    @property
    def openflow_disable_validations(self):
        return []

    @property
    def dump_all_flows(self):
        return 'sudo /usr/bin/ovs-ofctl dump-flows s1 -O OpenFlow13'

    @property
    def flow_validations(self):
        return ['dl_src=' + self.src_mac +
                ',dl_dst=' + self.dst_mac +
                ',nw_src=' + self.ip_src +
                ',nw_dst=' + self.ip_dst +
                ' actions=' + self.action,
                'table=' + self.table_id]

    def create_flow_match_elements(self, flow_xml):
        super(Ovs, self).create_flow_match_elements(flow_xml)
        if (self.action == 'INPORT'):
            self.action = 'IN_PORT'

    @property
    def datapath_id_output_command(self):
        return '/sbin/ifconfig | egrep \'^s1\' | awk \'{print $5}\''

    datapath_id_output_string = ''
    datapath_id = ''

    def update_datapath_id(self):
        if not self.datapath_id_output_string:
            self.datapath_id = 'unknown'
        else:
            # 32:cc:bf:34:ed:4c
            datapath_id_hex = re.sub(':', '', self.datapath_id_output_string)
            self.datapath_id = self.convert_hex_to_decimal_as_string(datapath_id_hex)

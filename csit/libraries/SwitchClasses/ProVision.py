"""
Provision 3800 Object Definition
Authors: james.luhrsen@hp.com
Created: 2014-10-02
"""
import re
from BaseSwitch import *  # noqa


class ProVision(BaseSwitch):
    '''
    ProVision Super Class
    '''

    make = 'provision'
    model = ''

    mgmt_protocol = 'telnet'
    mgmt_ip = ''
    mgmt_port = ''
    mgmt_prompt = model + '.*#'

    initialization_type = 'reboot'

    of_instance_id = '21'

    @property
    def connection_configs(self):
        return ['\rend \
                 \rconfig \
                 \rconsole local-terminal none \
                 \rno page \
                 \rend\r']

    @property
    def initialization_cmds(self):
        return ['\rend\rboot system flash primary config odl_test_startup_config\r',
                'y',
                'n']

    @property
    def cleanup_cmds(self):
        return ['end',
                'config',
                'no openflow\r',
                'y']

    @property
    def base_openflow_config(self):
        return 'end', \
               'config', \
               'openflow', \
               'controller-id ' + self.of_instance_id + ' ip ' + self.of_controller_ip + \
               ' controller-interface oobm', \
               'instance ' + self.of_instance_id, \
               'member vlan 10', \
               'controller-id ' + self.of_instance_id + ' ', \
               'version 1.3', \
               'enable', \
               'openflow enable', \
               'end'

    @property
    def openflow_enable_config(self):
        return ['end',
                'config',
                'openflow enable',
                'end']

    @property
    def openflow_validation_cmd(self):
        return \
            'show openflow'

    @property
    def openflow_enable_validations(self):
        return ['OpenFlow +: Enabled',
                self.of_instance_id + ' +Up +2 +1 +1.3']

    @property
    def openflow_disable_config(self):
        return ['end',
                'config',
                'openflow disable',
                'end']

    @property
    def openflow_disable_validations(self):
        return ['OpenFlow +: Disabled', self.of_instance_id + ' +Down +0 +0 +1.3']

    @property
    def dump_all_flows(self):
        return 'show openflow instance ' + self.of_instance_id + ' flows'

    @property
    def flow_validations(self):
        return ['(?ms)Flow Table ID : 0.*Flow Table ID : 100.*' +
                'Source Protocol Address : ' + self.ip_src + '.*' +
                'Target Protocol Address : ' + self.ip_dst + '.*' +
                'Flow Table ID : ' + self.table_id + '.*' + self.action,
                'Source MAC    : ' + self.src_mac,
                'Destination MAC  : ' + self.dst_mac]

    def create_flow_match_elements(self, flow_xml):
        super(ProVision, self).create_flow_match_elements(flow_xml)
        self.src_mac = self.format_mac_with_no_hyphens_and_one_colon(self.src_mac)
        self.dst_mac = self.format_mac_with_no_hyphens_and_one_colon(self.dst_mac)
        self.action = self.convert_action_to_provision_format(self.action)

    def format_mac_with_no_hyphens_and_one_colon(self, mac):
        mac_no_colons = re.sub(':', '', mac)
        mac_with_hyphen = mac_no_colons[:6] + '-' + mac_no_colons[6:]
        return mac_with_hyphen

    def convert_action_to_provision_format(self, action):
        if (action == 'INPORT'):
            return 'Ingress Port'
        if (action == 'TABLE'):
            return 'Table'
        if (action == 'NORMAL'):
            return 'Normal'
        if (action == 'FLOOD'):
            return 'Flood'
        if (action == 'ALL'):
            return 'All'
        if (action == 'CONTROLLER'):
            return 'Controller Port'
        if (action == 'LOCAL'):
            return 'Local'
        return 'UNKNOWN'

    @property
    def datapath_id_output_command(self):
        return \
            'show openflow instance ' + self.of_instance_id + ' | include Datapath'

    connection_index = ''

    def set_connection_index(self, idx):
        self.connection_index = idx

    datapath_id_output_string = ''
    datapath_id = ''

    def update_datapath_id(self):
        if not self.datapath_id_output_string:
            self.datapath_id = 'unknown'
        else:
            # Datapath ID              : 000af0921c22bac0
            # |-----------------(0)---------------------|
            # |-----------(1)----------| |------(2)-----|
            matches = re.search('(.*: )(\w+)', self.datapath_id_output_string)
            datapath_id_hex = matches.group(2)
            self.datapath_id = self.convert_hex_to_decimal_as_string(datapath_id_hex)

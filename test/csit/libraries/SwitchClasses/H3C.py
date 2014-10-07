"""
Provision 3800 Object Definition
Authors: james.luhrsen@hp.com
Created: 2014-10-02
"""
import string
import robot
import re
from robot.libraries.BuiltIn import BuiltIn
from BaseSwitch import *

class H3C(BaseSwitch):
    '''
    H3C Super Class
    '''

    make = 'h3c'
    model = ''

    mgmt_protocol = 'telnet'
    mgmt_ip = ''
    mgmt_port = ''
    mgmt_prompt = '(' + model + '.*>|' + model + '.*])'


    initialization_type = 'reboot'

    of_controller_ip = ''
    of_instance_id = '21'

    @property
    def connection_configs(self):
        return \
            ['\r\r\r']

    @property
    def initialization_cmds(self):
        return \
            ['\rstartup saved-configuration odl_test_startup_config.cfg main\r', \
             'reboot\r', \
             'Y\r', \
             '\r', \
             'N\r', \
             'Y\r']

    @property
    def cleanup_cmds(self):
        return \
            ['system-view', \
             'undo openflow instance ' + self.of_instance_id, \
             'return']

    @property
    def base_openflow_config(self):
        return \
            ['system-view', \
             'openflow instance ' + self.of_instance_id, \
             'classification vlan 1', \
             'controller ' + self.of_instance_id + ' address ip ' + self.of_controller_ip, \
             'active instance', \
             'return']

    @property
    def openflow_enable_config(self):
        return \
            ['system-view', \
             'openflow instance ' + self.of_instance_id, \
             'classification vlan 1', \
             'active instance', \
             'return']

    @property
    def openflow_validation_cmd(self):
        return \
            'display openflow summary'

    @property
    def openflow_enable_validations(self):
        return \
            [self.of_instance_id + ' +Active', \
             'Connected   1          24        N']

    @property
    def openflow_disable_config(self):
        return \
            ['system-view', \
             'openflow instance ' + self.of_instance_id, \
             'undo classification', \
             'active instance', \
             'return']

    @property
    def openflow_disable_validations(self):
        return \
            [self.of_instance_id + ' +Inactive  - +- +- +- +-']

    @property
    def dump_all_flows(self):
        return \
            ['']

    @property
    def datapath_id_output_command(self):
        return \
            'display openflow summary | include 0x'

    datapath_id_output_string = ''
    datapath_id = ''

    def update_datapath_id(self):
        if not self.datapath_id_output_string:
            self.datapath_id = 'unknown'
        else:
         #21    Active    0x0015cc3e5f42ad23  Connected   1          24        N
         #|---------------------------------(0)---------------------------------|
         #|------(1)-------||------(2)-----|
         matches = re.search('(.*0x)(\w+) +Connected', self.datapath_id_output_string)
         datapath_id_hex = matches.group(2)
         self.datapath_id = self.convert_hex_to_decimal_as_string(datapath_id_hex)

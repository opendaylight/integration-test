"""
Base Switch Object Definition
Authors: james.luhrsen@hp.com
Created: 2014-09-20
"""
import importlib
from xml.etree.ElementTree import *  # noqa


class BaseSwitch(object):
    '''
    Switch Base Class
    '''

    make = ''
    model = ''

    mgmt_protocol = ''
    ssh_key = ''
    mgmt_ip = ''
    mgmt_port = ''
    mgmt_user = ''
    mgmt_password = ''
    mgmt_prompt = ''

    connection_index = ''

    initialization_type = ''

    of_controller_ip = ''

    connection_configs = []

    initialization_cmds = []

    base_openflow_config = []

    openflow_enable_config = []

    openflow_enable_validations = []

    openflow_disable_config = []
    openflow_disable_validations = []

    dump_all_flows = []

    src_mac = ''
    dst_mac = ''
    ip_src = ''
    ip_dst = ''
    table_id = ''
    action = ''

    datapath_id_output_string = ''
    datapath_id_output_command = ''
    datapath_id = ''

    def set_connection_index(self, idx):
        self.connection_index = idx

    def set_controller_ip(self, ip):
        self.of_controller_ip = ip

    def set_mgmt_ip(self, ip):
        self.mgmt_ip = ip

    def set_mgmt_user(self, user):
        self.mgmt_user = user

    def set_mgmt_prompt(self, prompt):
        self.mgmt_prompt = prompt

    def set_ssh_key(self, key):
        self.ssh_key = key

    def update_datapath_id(self):
        raise NotImplementedError("Please implement this method")

    def create_flow_match_elements(self, flow_xml):
        flow_tree = fromstring(flow_xml)
        self.table_id = flow_tree.\
            find('{urn:opendaylight:flow:inventory}table_id').text
        instructions_element = flow_tree.\
            find('{urn:opendaylight:flow:inventory}instructions')
        instruction_element = instructions_element.\
            find('{urn:opendaylight:flow:inventory}instruction')
        apply_actions = instruction_element.\
            find('{urn:opendaylight:flow:inventory}apply-actions')
        action = apply_actions.\
            find('{urn:opendaylight:flow:inventory}action')
        output_action = action.\
            find('{urn:opendaylight:flow:inventory}output-action')
        output_node_connector = \
            output_action.find('{urn:opendaylight:'
                               'flow:inventory}output-node-connector')
        self.action = output_node_connector.text
        match_element = flow_tree.\
            find('{urn:opendaylight:flow:inventory}match')
        ethernet_match_element = match_element.\
            find('{urn:opendaylight:flow:inventory}ethernet-match')
        ethernet_source = ethernet_match_element.\
            find('{urn:opendaylight:flow:inventory}ethernet-source')
        ethernet_source_address = ethernet_source.\
            find('{urn:opendaylight:flow:inventory}address')
        self.src_mac = ethernet_source_address.text
        ethernet_destination = ethernet_match_element.\
            find('{urn:opendaylight:flow:inventory}ethernet-destination')
        ethernet_destination_address = ethernet_destination.\
            find('{urn:opendaylight:flow:inventory}address')
        self.dst_mac = ethernet_destination_address.text
        self.ip_src = match_element.\
            find('{urn:opendaylight:flow:inventory}ipv4-source').text
        self.ip_dst = match_element.\
            find('{urn:opendaylight:flow:inventory}ipv4-destination').text

    def convert_hex_to_decimal_as_string(self, hex_string):
        # TODO: need to add error checking in case the hex_string is
        # not fully hex
        return str(int(hex_string, 16))

    def get_switch(self, switch_type):
        """
        Generic method that will allow Robot Code to pass a string
        to this "keyword - Get Switch" and create an object of that
        type.  (EX: Get Switch  OVS)
        """

        # TODO: what if the module "switch_type" does not exist.  Need some
        # error checking for that.
        module = importlib.import_module(switch_type)
        return getattr(module, switch_type)()

"""
Library for the robot based system test tool of the OpenDaylight project.
Authors: Baohua Yang@IBM, Denghui Huang@IBM
Updated: 2013-11-10
"""
import robot
from robot.libraries.BuiltIn import BuiltIn

class SwitchManager(object):
    def __init__(self):
        self.builtin = BuiltIn()

    def extract_all_nodes(self, content):
        """
        Return all nodes.
        """
        if isinstance(content,dict) and content.has_key('nodeProperties'):
            self.builtin.log("18")
            return [e.get('node') for e in content['nodeProperties']]
        else:
            self.builtin.log("21")
            return None 

    def extract_all_properties(self, content, property_type):
        if isinstance(content,dict) and content.has_key(property_type):
            self.builtin.log("26")
            list1=[e.get('properties') for e in content[property_type]]
            self.builtin.log(list1)
            return [e.get('properties') for e in content[property_type]]
        else:
            self.builtin.log("29")
            return None

    def extract_property_value(self, content, property, property_type):
        res = self.extract_all_properties(content, property_type)
        return [e.get(property) for e in res]

    def extract_all_node_properties(self, content):
        return self.extract_all_properties(content, 'nodeProperties')

    def extract_node_property_values(self, content, property):
        return self.extract_property_value(content, property, 'nodeProperties')

    def extract_all_nodeconnector_properties(self, content):
        return self.extract_all_properties(content, 'nodeConnectorProperties')

    def extract_nodeconnector_property_values(self, content, property):
        return self.extract_property_value(content, property, 'nodeConnectorProperties')

"""
Library for the robot based system test tool of the OpenDaylight project.
Authors: Baohua Yang@IBM, Denghui Huang@IBM
Updated: 2013-11-10
"""
class SwitchManager(object):
    def extract_all_nodes(self, content):
        """
        Return all nodes.
        """
        if isinstance(content,dict) or not content.has_key('nodeProperties'):
            return None
        else:
            return [e.get('node') for e in content['nodeProperties']]

    def extract_all_properties(self, content):
        pass

"""
Library for dynamic flow construction.
Authors: james.luhrsen@hp.com
Updated: 2014-08-29
"""
'''
xmltodict and json libs not needed at this point, but may be useful in
the future.
'''
##import xmltodict
##import json
import string
import robot
from robot.libraries.BuiltIn import BuiltIn

##bare bones xml for building a flow xml for flow:inventory
flow_xml_skeleton = '<?xml version="1.0" encoding="UTF-8" standalone="no"?>' +      \
               '<flow xmlns="urn:opendaylight:flow:inventory">'         +      \
                    '<instructions></instructions>'                     +      \
                    '<match></match>'                                   +      \
               '</flow>'

input_xml_skeleton = '<?xml version="1.0" encoding="UTF-8" standalone="no"?>' +      \
               '<input xmlns="urn:opendaylight:flow:service">'          +      \
               '</input>'


class Flow:
    '''
    Flow class for creating and interacting with OpenFlow flows
    '''

    strict = "false"
    instruction_xmls = ""
    match_xmls = ""
    cookie = 0
    cookie_mask = 0
    table_id = 0
    id = 1
    hard_timeout = 60
    idle_timeout = 30
    flow_name = "No Name"
    priority = 0
    barrier = "false"

    xml = ""

    json = ""

    def set_field(self, field, value):
        '''
           allows for generically setting any attribute in this
           class based on the 'field' passed in.  In the future,
           adding a new attribute only requires that single line
           addition.  no need for additional setter.
        '''
        setattr(self, field, value)

def Make_Inventory_Flow():
    '''
        Robot Keyword to create and return an instance of the Flow
        class.
    '''
    flow = Flow()
    flow.xml = flow_xml_skeleton
    return flow

def Make_Service_Flow():
    '''
        Robot Keyword to create an input XML that can be used to
        directly send to flow:service for things like accessing
        the remove-flow RPC via restconf
    '''
    flow = Flow()
    flow.xml = input_xml_skeleton
    return flow

def Set_Flow_Field(flow, field, value):
    '''
        Robot Keyword to allow the modification (setting) of the 
        flow object attributes
    '''
    flow.set_field(field,value)
    return flow


#def Convert_Flow_XML_To_Json(flow):
#    '''
#       There may be a need in the future to use json to push
#       flows, as opposed to xml format that is prevalent in 
#       test code at this point.  This function will give a 
#       conversion, but unsure if it's proper.  Also, unsure
#       if the xmltodict library is viable in the CSIT environment
#    '''
#    flowXmlDict = xmltodict.parse(flow.xml)
#    flow.json = json.dumps(flowXmlDict)
#    return flow

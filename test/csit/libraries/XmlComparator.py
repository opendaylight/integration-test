'''
Copyright (c) 2014 Cisco Systems, Inc. and others.  All rights reserved.

This program and the accompanying materials are made available under the
terms of the Eclipse Public License v1.0 which accompanies this distribution,
and is available at http://www.eclipse.org/legal/epl-v10.html

Created on May 21, 2014

@author: <a href="mailto:vdemcak@cisco.com">Vaclav Demcak</a>
'''
from xml.dom.minidom import Element
import ipaddr
import xml.dom.minidom as md
import copy

KEY_NOT_FOUND = '<KEY_NOT_FOUND>'  # KeyNotFound for dictDiff


class XMLtoDictParserTools():

    @staticmethod
    def parseTreeToDict(node, returnedDict=None, ignoreList=[]):
        """
        Return Dictionary representation of the xml Tree DOM Element.
        Repeated tags are put to the array sorted by key (id or order)
        otherwise is the value represented by tag key name.
        @param node: DOM Element
        @param returnedDict : dictionary (default value None)
        @param ignereList : list of ignored tags for the xml Tree DOM Element
                            (default value is empty list)
        @return: dict representation for the input DOM Element
        """
        returnedDict = {} if returnedDict is None else returnedDict
        if (node.nodeType == Element.ELEMENT_NODE):
            nodeKey = (node.localName).encode('utf-8', 'ignore')
            if nodeKey not in ignoreList:
                if node.childNodes is not None:
                    childDict = {}
                    for child in node.childNodes:
                        if child.nodeType == Element.TEXT_NODE:
                            nodeValue = (child.nodeValue).encode('utf-8', 'ignore')
                            if (len(nodeValue.strip(' \t\n\r'))) > 0:
                                XMLtoDictParserTools.addDictValue(returnedDict, nodeKey, nodeValue)
                                nodeKey = None
                                break
                        elif child.nodeType == Element.ELEMENT_NODE:
                            childDict = XMLtoDictParserTools.parseTreeToDict(child, childDict, ignoreList)

                    XMLtoDictParserTools.addDictValue(returnedDict, nodeKey, childDict)

        return returnedDict

    @staticmethod
    def addDictValue(m_dict, key, value):

        def _allign_address(value):
            """unifies output"""
            n = ipaddr.IPNetwork(value)
            return '{0}/{1}'.format(n.network.exploded, n.prefixlen)

        def _convert_numbers(value):
            if value.startswith("0x"):
                return str(long(value, 16))
            return str(long(value))

        if key is not None:
            if (isinstance(value, str)):
                # we need to predict possible differences
                # for same value in upper or lower case
                value = value.lower()
            if key not in m_dict:
                # lets add mask for ips withot mask
                if key in ['ipv4-destination', 'ipv4-source', 'ipv6-destination', 'ipv6-source', 'ipv6-nd-target']:
                    nvalue = _allign_address(value)
                    m_dict[key] = nvalue
                elif key in ['tunnel-mask', 'type', 'metadata-mask', 'out_port', 'out_group']:
                    nvalue = _convert_numbers(value)
                    m_dict[key] = nvalue
                else:
                    m_dict[key] = value
            else:
                exist_value = m_dict.get(key)
                if (type(exist_value) is dict):
                    list_values = [exist_value, value]
                    key_for_sort = XMLtoDictParserTools.searchKey(exist_value)
                    if key_for_sort is not None:
                        list_values = sorted(list_values, key=lambda k: k[key_for_sort])
                    m_dict[key] = list_values
                elif (isinstance(exist_value, list)):
                    exist_value.append(value)
                    list_values = exist_value
                    key_for_sort = XMLtoDictParserTools.searchKey(value)
                    if key_for_sort is not None:
                        list_values = sorted(list_values, key=lambda k: k[key_for_sort])
                    m_dict[key] = list_values
                else:
                    m_dict[key] += value

    @staticmethod
    def searchKey(dictionary):
        """
        Return an order key for the array ordering. OF_13
        allows only two possible kind of the order keys
        'order' or '*-id'
        @param dictionary: dictionary with data
        @return: the array order key
        """
        subKeyStr = ['-id', 'order']
        for substr in subKeyStr:
            for key in dictionary:
                if key == substr:
                    return key
                elif key.endswith(substr):
                    return key
        return None

    @staticmethod
    def getDifferenceDict(original_dict, responded_dict):
        """
        Return a dict of keys that differ with another config object.  If a value is
        not found in one fo the configs, it will be represented by KEY_NOT_FOUND.
        @param original_dict:   Fist dictionary to diff.
        @param responded_dict:  Second dictionary to diff.
        @return diff:   Dict of Key => (original_dict.val, responded_dict.val)
                        Dict of Key => (original_key, KEY_NOT_FOUND)
                        Dict of Key => (KEY_NOT_FOUNE, original_key)
        """
        diff = {}
        # Check all keys in original_dict dict
        for key in original_dict.keys():
            if key not in responded_dict:
                # missing key in responded dict
                diff[key] = (key, KEY_NOT_FOUND)
            # check values of the dictionaries
            elif (original_dict[key] != responded_dict[key]):
                # values are not the same #

                orig_dict_val = original_dict[key]
                resp_dict_val = responded_dict[key]

                # check value is instance of dictionary
                if isinstance(orig_dict_val, dict) and isinstance(resp_dict_val, dict):
                    sub_dif = XMLtoDictParserTools.getDifferenceDict(orig_dict_val, resp_dict_val)
                    if sub_dif:
                        diff[key] = sub_dif

                # check value is instance of list
                # TODO - > change a basic comparator to compare by id or order
                elif isinstance(orig_dict_val, list) and isinstance(resp_dict_val, list):
                    sub_list_diff = {}
                    # the list lengths
                    orig_i, resp_i = len(orig_dict_val), len(resp_dict_val)
                    # define a max iteration length (less from both)
                    min_index = orig_i if orig_i < resp_i else resp_i
                    for index in range(0, min_index, 1):
                        if (orig_dict_val[index] != resp_dict_val[index]):
                            sub_list_diff[index] = (orig_dict_val[index], resp_dict_val[index])
                    if (orig_i > min_index):
                        # original is longer as responded dict
                        for index in range(min_index, orig_i, 1):
                            sub_list_diff[index] = (orig_dict_val[index], None)
                    elif (resp_i > min_index):
                        # responded dict is longer as original
                        for index in range(min_index, resp_i, 1):
                            sub_list_diff[index] = (None, resp_dict_val[index])
                    if sub_list_diff:
                        diff[key] = sub_list_diff

                else:
                    diff[key] = (original_dict[key], responded_dict[key])

        # Check all keys in responded_dict dict to find missing
        for key in responded_dict.keys():
            if key not in original_dict:
                diff[key] = (KEY_NOT_FOUND, key)
        return diff

IGNORED_TAGS_FOR_OPERATIONAL_COMPARISON = ['id', 'flow-name', 'barrier', 'cookie_mask', 'installHw', 'flags',
                                           'strict', 'byte-count', 'duration', 'packet-count', 'in-port',
                                           'vlan-id-present', 'out_group', 'out_port', 'hard-timeout', 'idle-timeout',
                                           'flow-statistics', 'cookie', 'clear-actions']  # noqa

IGNORED_PATHS_FOR_OC = [(['flow', 'instructions', 'instruction', 'apply-actions', 'action', 'controller-action'], True),  # noqa
                        (['flow', 'instructions', 'instruction', 'clear-actions', 'action'], False),
                        (['flow', 'instructions', 'instruction', 'apply-actions', 'action', 'push-vlan-action', 'vlan-id'], False),  # noqa
                        (['flow', 'instructions', 'instruction', 'apply-actions', 'action', 'drop-action'], True),
                        (['flow', 'instructions', 'instruction', 'apply-actions', 'action', 'flood-action'], True),
                        ]

TAGS_TO_ADD_FOR_OC = [(['flow', 'instructions', 'instruction', 'apply-actions', 'action', 'output-action'], 'max-length', '0'),  # noqa
                      ]


TAGS_TO_MODIFY_FOR_OC = [(['flow', 'match', 'metadata'], 'metadata', 'metadata-mask'),
                         (['flow', 'match', 'tunnel'], 'tunnel-id', 'tunnel-mask'),
                         ]


class XmlComparator:

    def is_flow_configured(self, requested_flow, configured_flows):

        orig_tree = md.parseString(requested_flow)
        xml_resp_stream = configured_flows.encode('utf-8', 'ignore')
        xml_resp_tree = md.parseString(xml_resp_stream)
        nodeListOperFlows = xml_resp_tree.getElementsByTagNameNS("*", 'flow')
        origDict = XMLtoDictParserTools.parseTreeToDict(orig_tree._get_documentElement())

        reportDict = {}
        index = 0
        for node in nodeListOperFlows:
            nodeDict = XMLtoDictParserTools.parseTreeToDict(node)
            XMLtoDictParserTools.addDictValue(reportDict, index, nodeDict)
            index += 1
            # print nodeDict
            # print origDict
            if nodeDict == origDict:
                return True, ''
            if nodeDict['flow']['priority'] == origDict['flow']['priority']:
                return False, 'Flow found with diferences {0}'.format(
                    XMLtoDictParserTools.getDifferenceDict(nodeDict, origDict))
        return False, ''

    def is_flow_operational2(self, requested_flow, oper_resp):
        def _rem_unimplemented_tags(tagpath, recurs, tdict):
            # print "_rem_unimplemented_tags", tagpath, tdict
            if len(tagpath) > 1 and tagpath[0] in tdict:
                _rem_unimplemented_tags(tagpath[1:], recurs, tdict[tagpath[0]])

            # when not to delete anything
            if len(tagpath) == 1 and tagpath[0] not in tdict:
                return
            if len(tagpath) == 0:
                return

            # when to delete
            if len(tagpath) == 1 and tagpath[0] in tdict:
                del tdict[tagpath[0]]
            if len(tagpath) > 1 and recurs is True and tagpath[0] in tdict and tdict[tagpath[0]] == {}:
                del tdict[tagpath[0]]
            if tdict.keys() == ['order']:
                del tdict['order']
            # print "leaving", tdict

        def _add_tags(tagpath, newtag, value, tdict):
            '''if whole tagpath exists and the tag is not present, it is added with given value'''
            # print "_add_tags", tagpath, newtag, value, tdict
            if len(tagpath) > 0 and tagpath[0] in tdict:
                _add_tags(tagpath[1:], newtag, value, tdict[tagpath[0]])
            elif len(tagpath) == 0 and newtag not in tdict:
                tdict[newtag] = value

        def _to_be_modified_tags(tagpath, tag, related_tag, tdict):
            '''if whole tagpath exists and the tag is not present, it is added with given value'''
            # print "_to_be_modified_tags", tagpath, tag, related_tag, tdict
            if len(tagpath) > 0 and tagpath[0] in tdict:
                _to_be_modified_tags(tagpath[1:], tag, related_tag, tdict[tagpath[0]])
            elif len(tagpath) == 0 and tag in tdict and related_tag in tdict:
                tdict[tag] = str(long(tdict[tag]) & long(tdict[related_tag]))

        orig_tree = md.parseString(requested_flow)
        xml_resp_stream = oper_resp.encode('utf-8', 'ignore')
        xml_resp_tree = md.parseString(xml_resp_stream)
        nodeListOperFlows = xml_resp_tree.getElementsByTagNameNS("*", 'flow')
        origDict = XMLtoDictParserTools.parseTreeToDict(
            orig_tree._get_documentElement(),
            ignoreList=IGNORED_TAGS_FOR_OPERATIONAL_COMPARISON)

        # origDict['flow-statistics'] = origDict.pop( 'flow' )
        reportDict = {}
        index = 0
        for node in nodeListOperFlows:
            nodeDict = XMLtoDictParserTools.parseTreeToDict(
                node,
                ignoreList=IGNORED_TAGS_FOR_OPERATIONAL_COMPARISON)
            XMLtoDictParserTools.addDictValue(reportDict, index, nodeDict)
            index += 1
            # print nodeDict
            # print origDict
            # print reportDict
            if nodeDict == origDict:
                return True, ''
            if nodeDict['flow']['priority'] == origDict['flow']['priority']:
                for p in IGNORED_PATHS_FOR_OC:
                    td = copy.copy(origDict)
                    _rem_unimplemented_tags(p[0], p[1],  td)
                    for (p, t, v) in TAGS_TO_ADD_FOR_OC:
                        _add_tags(p, t, v, td)
                    for (p, t, rt) in TAGS_TO_MODIFY_FOR_OC:
                        _to_be_modified_tags(p, t, rt, td)

                    # print "comparing1", nodeDict
                    # print "comparing2", td
                    if nodeDict == td:
                        return True, ''
                if nodeDict == origDict:
                    return True, ''
                return False, 'Flow found with diferences {0}'.format(
                    XMLtoDictParserTools.getDifferenceDict(nodeDict, origDict))
        return False, ''

    def get_data_for_flow_put_update(self, xml):
        # action only for yet
        xml_dom_input = md.parseString(xml)
        actionList = xml_dom_input.getElementsByTagName('action')
        if actionList is not None and len(actionList) > 0:
            action = actionList[0]
            for child in action.childNodes:
                if child.nodeType == Element.ELEMENT_NODE:
                    nodeKey = (child.localName).encode('utf-8', 'ignore')
                    if nodeKey != 'order':
                        if nodeKey != 'drop-action':
                            new_act = child.ownerDocument.createElement('drop-action')
                        else:
                            new_act = child.ownerDocument.createElement('output-action')
                            onc = child.ownerDocument.createElement('output-node-connector')
                            onc_content = child.ownerDocument.createTextNode('TABLE')
                            onc.appendChild(onc_content)
                            new_act.appendChild(onc)
                            ml = child.ownerDocument.createElement('max-length')
                            ml_content = child.ownerDocument.createTextNode('60')
                            ml.appendChild(ml_content)
                            new_act.appendChild(ml)
                        child.parentNode.replaceChild(new_act, child)
        return xml_dom_input.toxml(encoding='utf-8')

    def get_flow_content(self, tid=1, fid=1, priority=1):
        """Returns an xml flow content identified by given details.

        Args:
            :param tid: table id
            :param fid: flow id
            :param priority: flow priority
        """

        flow_template = '''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<flow xmlns="urn:opendaylight:flow:inventory">
    <strict>false</strict>
    <instructions>
        <instruction>
            <order>0</order>
            <apply-actions>
                <action>
                    <order>0</order>
                    <drop-action/>
                </action>
            </apply-actions>
        </instruction>
    </instructions>
    <table_id>%s</table_id>
    <id>%s</id>
    <cookie_mask>4294967295</cookie_mask>
    <installHw>false</installHw>
    <match>
        <ethernet-match>
            <ethernet-type>
                <type>2048</type>
            </ethernet-type>
        </ethernet-match>
        <ipv4-source>10.0.0.1/32</ipv4-source>
    </match>
    <cookie>%s</cookie>
    <flow-name>%s</flow-name>
    <priority>%s</priority>
    <barrier>false</barrier>
</flow>'''

        flow_data = flow_template % (tid, fid, fid, 'TestFlow-{0}'.format(fid), priority)
        return flow_data

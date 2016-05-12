import json
import pyangbind.lib.pybindJSON as pbJ
import sys
# Bindings must present in /tmp/odl-lispflowmapping-yang-files
sys.path.insert(0, '/tmp/odl-lispflowmapping-yang-files')
from LISPFlowMappingYANGBindings.odl_mappingservice_rpc.add_mapping.input import input


"""Helper Functions """


def Clean_JSON(string_dump):
    string_dump = string_dump.replace("odl-mappingservice:", "")
    string_dump = string_dump.replace("laddr:", "ietf-lisp-address-types:")
    return json.loads(string_dump)


def Merge(first, second):
    first.update(second)
    return first


def Wrap_input(json_dump):
    out_dump = {"input": json_dump}
    return out_dump


def Merge_And_Wrap_input(first, second):
    return Wrap_input(Merge(first, second))


"""Generator Functions"""


def Get_LispAddress_Object(eid_string, vni=None):
    """Returns a lisp address object based its string representation"""
    rpc_input = input()
    laddr_obj = rpc_input.mapping_record.eid

    if vni:
        laddr_obj.virtual_network_id = vni

    eid_string = eid_string.split(':')
    prefix, text = eid_string[0], ':'.join(eid_string[1:])
    if prefix:
        if prefix == 'srcdst':
            # Example: srcdst:192.0.2.1/32|192.0.2.2/32
            laddr_obj.address_type = 'laddr:source-dest-key-lcaf'
            text = text.split('|')
            laddr_obj.source_dest_key.source = text[0]
            laddr_obj.source_dest_key.dest = text[1]
        elif prefix == 'no':
            # Example: no:
            laddr_obj.address_type = 'laddr:no-address-afi'
        elif prefix == 'ipv4':
            if '/' in text:
                # Case: ipv4-prefix
                laddr_obj.address_type = 'laddr:ipv4-prefix-afi'
                laddr_obj.ipv4_prefix = text
            else:
                # Case: ipv4
                laddr_obj.address_type = 'laddr:ipv4-afi'
                laddr_obj.ipv4 = text
        elif prefix == 'ipv6':
            if '/' in text:
                # Case: ipv6-prefix
                laddr_obj.address_type = 'laddr:ipv6-prefix-afi'
                laddr_obj.ipv6_prefix = text
            else:
                laddr_obj.address_type = 'laddr:ipv6-afi'
                laddr_obj.ipv6 = text
        elif prefix == 'mac':
            # Example: mac:00:00:5E:00:53:00
            laddr_obj.address_type = 'laddr:mac-afi'
            laddr_obj.mac = text
        elif prefix == 'dn':
            # Example: dn:stringAsIs
            laddr_obj.address_type = 'laddr:distinguished-name-afi'
            laddr_obj.distinguished_name = text
        elif prefix == 'as':
            # Example: as:AS64500
            laddr_obj.address_type = 'laddr:as-number-afi'
            laddr_obj.as_number = text
        elif prefix == 'list':
            # Example: list:{192.0.2.1,192.0.2.2,2001:db8::1}
            laddr_obj.address_type = 'laddr:afi-list-lcaf'
            list_elements = text[1:len(text) - 1].split(',')  # removed start and end braces
            laddr_obj.afi_list.address_list = list_elements
        elif prefix == 'appdata':
            # Example: appdata:192.0.2.1!128!17!80-81!6667-7000
            laddr_obj.address_type = 'laddr:application-data-lcaf'
            text = text.split('!')
            laddr_obj.application_data.address = text[0]
            laddr_obj.application_data.ip_tos = text[1]
            laddr_obj.application_data.protocol = text[2]
            local_ports = text[3].split('-')
            laddr_obj.application_data.local_port_low = local_ports[0]
            laddr_obj.application_data.local_port_high = local_ports[1]
            remote_ports = text[4].split('-')
            laddr_obj.application_data.remote_port_low = remote_ports[0]
            laddr_obj.application_data.remote_port_high = remote_ports[1]
        elif prefix == 'elp':
            # TODO: BITS_TYPE_for_lps
            # Example: elp:{192.0.2.1->192.0.2.2|lps->192.0.2.3}
            laddr_obj.address_type = 'laddr:explicit-locator-path-lcaf'
            text = text[1:len(text) - 1]
            text = text.split('->')  # all the hops
            for i in range(0, len(text)):
                laddr_obj.explicit_locator_path.hop.add("hop" + str(i))
                text[i] = text[i].split('|')[0]
                laddr_obj.explicit_locator_path.hop["hop" + str(i)].address = text[i]
        elif prefix == 'kv':
            # Example: kv:192.0.2.1->192.0.2.2
            laddr_obj.address_type = 'laddr:key-value-address-lcaf'
            text = text.split('->')
            laddr_obj.key_value_address.key = text[0]
            laddr_obj.key_value_address.value = text[1]
        elif prefix == 'sp':
            # Example: sp:42(3)
            laddr_obj.address_type = 'laddr:service-path-lcaf'
            text = text.split('(')
            laddr_obj.service_path.service_path_id = text[0]
            laddr_obj.service_path.service_index = text[1][:-1]

    return laddr_obj


def Get_LispAddress_JSON(eid_string, vni=None):
    """Returns a lisp address Json object based its string representation"""
    pbj_dump = pbJ.dumps(Get_LispAddress_Object(eid_string, vni), filter=True, mode="default")
    out_dump = {"eid": json.loads(pbj_dump)}
    return Clean_JSON(json.dumps(out_dump))


def Get_LispAddress_JSON_And_Wrap_input(eid_string, vni=None):
    return Wrap_input(Get_LispAddress_JSON(eid_string, vni))


def Get_LocatorRecord_Object(rloc, weights='1/1/255/0', flags=001, loc_id="ISP1"):
    rpc_input = input()
    lrecord_obj = rpc_input.mapping_record.LocatorRecord
    # TODO: What should be the locator-id
    lrecord_obj.add(loc_id)
    lrecord_ele = weights.split('/')
    lrecord_obj[loc_id].priority = lrecord_ele[0]
    lrecord_obj[loc_id].weight = lrecord_ele[1]
    lrecord_obj[loc_id].multicastPriority = lrecord_ele[2]
    lrecord_obj[loc_id].multicastWeight = lrecord_ele[3]
    lrecord_obj[loc_id].rloc = Get_LispAddress_Object(rloc)
    lrecord_obj[loc_id].localLocator = flags % 10
    lrecord_obj[loc_id].rlocProbed = (flags / 10) % 10
    lrecord_obj[loc_id].routed = (flags / 100) % 10
    return lrecord_obj


def Get_LocatorRecord_JSON(rloc, weights='1/1/255/0', flags=001, loc_id="ISP1"):
    # TODO: flags = 101
    # TODO: ietf mode is throwing some errors
    pbj_dump = pbJ.dumps(Get_LocatorRecord_Object(rloc, weights, flags, loc_id), filter=True, mode="default")
    out_dump = {"LocatorRecord": json.loads(pbj_dump)}
    return Clean_JSON(json.dumps(out_dump))


def Get_MappingRecord_Object(eid, locators, ttl=1440, authoritative=True, action='NoAction'):
    rpc_input = input()
    mrecord_obj = rpc_input.mapping_record
    mrecord_obj.recordTtl = ttl
    mrecord_obj.authoritative = authoritative
    mrecord_obj.action = action
    mrecord_obj.eid = eid
    idx = 0
    loc_ids = []
    for loc in locators:
        loc_id = loc.keys()[0]
        loc_obj = loc[loc_id]
        if loc_id in loc_ids:
            print "Locator objects should have different keys"
            break
        # TODO: Locator-id, currently in the format of loc_id0, loc_id1
        mrecord_obj.LocatorRecord.add(loc_id)
        mrecord_loc_obj = mrecord_obj.LocatorRecord[loc_id]
        mrecord_loc_obj.priority = loc_obj.priority
        mrecord_loc_obj.weight = loc_obj.weight
        mrecord_loc_obj.multicastPriority = loc_obj.multicastPriority
        mrecord_loc_obj.multicastWeight = loc_obj.multicastWeight
        mrecord_loc_obj.rloc = loc_obj.rloc
        mrecord_loc_obj.localLocator = loc_obj.localLocator
        mrecord_loc_obj.rlocProbed = loc_obj.rlocProbed
        mrecord_loc_obj.routed = loc_obj.routed
        idx += 1
    return mrecord_obj


def Get_MappingRecord_JSON(eid, locators, ttl=1440, authoritative=True, action='NoAction'):
    pbj_dump = pbJ.dumps(Get_MappingRecord_Object(eid, locators, ttl, authoritative, action), filter=True, mode="ietf")
    out_dump = {"mapping-record": json.loads(pbj_dump)}
    return Clean_JSON(json.dumps(out_dump))


def Get_MappingAuthkey_Object(key_string="password", key_type=1):
    from LISPFlowMappingYANGBindings.odl_mappingservice_rpc.add_key.input import input as add_key_input
    rpc_input = add_key_input()
    authkey_obj = rpc_input.mapping_authkey
    authkey_obj.key_string = key_string
    authkey_obj.key_type = key_type
    return authkey_obj


def Get_MappingAuthkey_JSON(key_string="password", key_type=1):
    pbj_dump = pbJ.dumps(Get_MappingAuthkey_Object(key_string, key_type), filter=True, mode="default")
    out_dump = {"mapping-authkey": json.loads(pbj_dump)}
    return Clean_JSON(json.dumps(out_dump))

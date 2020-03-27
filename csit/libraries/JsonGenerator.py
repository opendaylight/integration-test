import json
import pyangbind.lib.pybindJSON as pbJ
import sys
import os

# Bindings must present in ${WORKSPACE}
workspace = os.environ["WORKSPACE"] + "/odl-lispflowmapping-yang-files"

"""Helper Functions """


def Clean_JSON(string_dump):
    """ Description: clean the pyangbind generated object
        Return: python dictionary
        Params:
         string_dump: string representation of pyangbind generated dictionary
    """
    string_dump = string_dump.replace("odl-mappingservice:", "")
    string_dump = string_dump.replace("laddr:", "ietf-lisp-address-types:")
    dict_obj = clean_hops(json.loads(string_dump))
    return dict_obj


def Merge(first, second):
    """ Description: merge two python dictionaries
        Return: python dictionary
        Params:
         first: python dictionary
         second: python dictionary
    """
    first.update(second)
    return first


def Wrap_input(dict_obj):
    """ Description: Wrap input to python dictionary
        Return: python dictionary
        Params:
         dict_obj: python dictionary
    """
    out_dump = {"input": dict_obj}
    return out_dump


def Merge_And_Wrap_input(first, second):
    """ Description: Merge two python dictionaries and wrap input
        Return: python dictionary
        Params:
         first: python dictionary
         second: python dictionary
    """
    return Wrap_input(Merge(first, second))


def copy_eid(objA, objB):
    """ Description: Copy value of attributes from one eid object to other
        Return: None
        Params:
         objA: eid object of pyangbind generated class
         objB: eid object of pyangbind generated class
    """
    for name in dir(objB):
        if name[:4] == "_eid":
            value = getattr(objB, name)
            try:
                setattr(objA, name, value)
            except AttributeError:
                print("%s giving attribute error in %s" % (name, objA))


def copy_rloc(objA, objB):
    """ Description: Copy value of attributes from one rloc object to other
        Returns: None
        Params:
         objA: rloc object of pyangbind generated class
         objB: rloc object of pyangbind generated class
    """
    for name in dir(objB):
        if name[:5] == "_rloc":
            value = getattr(objB, name)
            try:
                setattr(objA, name, value)
            except AttributeError:
                print(" %s giving attribute error in" % (name, objA))


def clean_hops(obj):
    """ Description: Clean hop-ids and lrs-bits
        Returns: python dictionary
        Params:
         obj: python dictionary for pyangbind generated object
    """
    new_obj = {}
    for key, value in obj.items():
        if key == "hop":
            for hop in value:
                values = hop["hop-id"].split(" ")
                hop["hop-id"] = values[0] + " " + values[1]
                if values[2] != "":
                    hop["lrs-bits"] = " ".join(values[2:])[:-1]
                new_obj[key] = value
        if isinstance(value, dict):
            new_obj[key] = clean_hops(value)
        elif isinstance(value, list):
            if len(value) > 0 and isinstance(value[0], dict):
                cur_items = []
                for items in value:
                    cur_items.append(clean_hops(items))
                new_obj[key] = cur_items
            else:
                new_obj[key] = value
        else:
            new_obj[key] = value
    return new_obj


"""Generator Functions"""


def Get_LispAddress_Object(eid_string, vni=None, laddr_obj=None):
    """ Description: Returns lisp address object from pyangbind generated classes.
        Returns: lisp address object
        Params:
         eid_string: type of lisp address
         vni: virtual network id
         laddr_obj: lisp address object
    """
    if laddr_obj is None:
        sys.path.insert(0, workspace)
        from LISPFlowMappingYANGBindings.odl_mappingservice_rpc.add_mapping.input import (
            input,
        )

        rpc_input = input()
        laddr_obj = rpc_input.mapping_record.eid

    if vni:
        laddr_obj.virtual_network_id = vni

    eid_string = eid_string.split(":")
    prefix, text = eid_string[0], ":".join(eid_string[1:])
    if prefix:
        if prefix == "srcdst":
            # Example: srcdst:192.0.2.1/32|192.0.2.2/32
            laddr_obj.address_type = "laddr:source-dest-key-lcaf"
            text = text.split("|")
            laddr_obj.source_dest_key.source = text[0]
            laddr_obj.source_dest_key.dest = text[1]
        elif prefix == "no":
            # Example: no:
            laddr_obj.address_type = "laddr:no-address-afi"
        elif prefix == "ipv4":
            if "/" in text:
                # Case: ipv4-prefix
                laddr_obj.address_type = "laddr:ipv4-prefix-afi"
                laddr_obj.ipv4_prefix = text
            else:
                # Case: ipv4
                laddr_obj.address_type = "laddr:ipv4-afi"
                laddr_obj.ipv4 = text
        elif prefix == "ipv6":
            if "/" in text:
                # Case: ipv6-prefix
                laddr_obj.address_type = "laddr:ipv6-prefix-afi"
                laddr_obj.ipv6_prefix = text
            else:
                laddr_obj.address_type = "laddr:ipv6-afi"
                laddr_obj.ipv6 = text
        elif prefix == "mac":
            # Example: mac:00:00:5E:00:53:00
            laddr_obj.address_type = "laddr:mac-afi"
            laddr_obj.mac = text
        elif prefix == "dn":
            # Example: dn:stringAsIs
            laddr_obj.address_type = "laddr:distinguished-name-afi"
            laddr_obj.distinguished_name = text
        elif prefix == "as":
            # Example: as:AS64500
            laddr_obj.address_type = "laddr:as-number-afi"
            laddr_obj.as_number = text
        elif prefix == "list":
            # Example: list:{192.0.2.1,192.0.2.2,2001:db8::1}
            laddr_obj.address_type = "laddr:afi-list-lcaf"
            list_elements = text[1 : len(text) - 1].split(
                ","
            )  # removed start and end braces
            laddr_obj.afi_list.address_list = list_elements
        elif prefix == "appdata":
            # Example: appdata:192.0.2.1!128!17!80-81!6667-7000
            laddr_obj.address_type = "laddr:application-data-lcaf"
            text = text.split("!")
            laddr_obj.application_data.address = text[0]
            laddr_obj.application_data.ip_tos = text[1]
            laddr_obj.application_data.protocol = text[2]
            local_ports = text[3].split("-")
            laddr_obj.application_data.local_port_low = local_ports[0]
            laddr_obj.application_data.local_port_high = local_ports[1]
            remote_ports = text[4].split("-")
            laddr_obj.application_data.remote_port_low = remote_ports[0]
            laddr_obj.application_data.remote_port_high = remote_ports[1]
        elif prefix == "elp":
            # TODO: BITS_TYPE_for_lps
            # Example: elp:{192.0.2.1->192.0.2.2|lps->192.0.2.3}
            laddr_obj.address_type = "laddr:explicit-locator-path-lcaf"
            text = text[1 : len(text) - 1]
            text = text.split("->")  # all the hops
            for i in range(0, len(text)):
                cur_hop = text[i].split("|")
                address = cur_hop[0]
                lrs_bits = ""
                hop_id = "Hop " + str(i + 1) + " " + lrs_bits
                if len(cur_hop) > 1:
                    lps = cur_hop[1]
                    if "l" in lps:
                        lrs_bits += "lookup "
                    if "p" in lps:
                        lrs_bits += "rloc-probe "
                    if "s" in lps:
                        lrs_bits += "strict "
                laddr_obj.explicit_locator_path.hop.add(hop_id)
                laddr_obj.explicit_locator_path.hop[hop_id].address = address
        elif prefix == "kv":
            # Example: kv:192.0.2.1->192.0.2.2
            laddr_obj.address_type = "laddr:key-value-address-lcaf"
            text = text.split("->")
            laddr_obj.key_value_address.key = text[0]
            laddr_obj.key_value_address.value = text[1]
        elif prefix == "sp":
            # Example: sp:42(3)
            laddr_obj.address_type = "laddr:service-path-lcaf"
            text = text.split("(")
            laddr_obj.service_path.service_path_id = text[0]
            laddr_obj.service_path.service_index = text[1][:-1]

    return laddr_obj


def Get_LispAddress_JSON(eid_string, vni=None):
    """ Description: Returns lisp address dictionary with eid wrapped
        Returns: python dictionary
        Params:
         eid_string: type of lisp address
         vni: virtual network id
    """
    pbj_dump = pbJ.dumps(
        Get_LispAddress_Object(eid_string, vni), filter=True, mode="ietf"
    )
    out_dump = '{"eid":' + pbj_dump + "}"
    return Clean_JSON(out_dump)


def Get_LispAddress_Noeid_JSON(eid_string, vni=None):
    """ Description: Returns lisp address dictionary
        Returns: python dictionary
        Params:
         eid_string: type of lisp address
         vni: virtual network id
    """
    out_dump = pbJ.dumps(
        Get_LispAddress_Object(eid_string, vni), filter=True, mode="ietf"
    )
    return Clean_JSON(out_dump)


def Get_LispAddress_JSON_And_Wrap_input(eid_string, vni=None):
    """ Description: Returns lisp address dictionary with eid and input wrapped
        Returns: python dictionary
        Params:
         eid_string: type of lisp address
         vni: virtual network id
    """
    return Wrap_input(Get_LispAddress_JSON(eid_string, vni))


def Get_LocatorRecord_Object(rloc, weights="1/1/255/0", flags=0o01, loc_id="ISP1"):
    """ Description: Returns locator record object from pyangbind generated classes
        Returns: locator record object
        Params:
         rloc: eid_string for lisp address object
         weights: priority/weight/multicastPriority/multicastWeight
         flags: Three bit parameter in the sequence routed->rlocProbed->routed
         loc_id: id of locator record object
    """
    sys.path.insert(0, workspace)
    from LISPFlowMappingYANGBindings.odl_mappingservice_rpc.add_mapping.input import (
        input,
    )

    rpc_input = input()
    lrecord_obj = rpc_input.mapping_record.LocatorRecord
    # TODO: What should be the locator-id
    lrecord_obj.add(loc_id)
    lrecord_ele = weights.split("/")
    lrecord_obj[loc_id].priority = lrecord_ele[0]
    lrecord_obj[loc_id].weight = lrecord_ele[1]
    lrecord_obj[loc_id].multicastPriority = lrecord_ele[2]
    lrecord_obj[loc_id].multicastWeight = lrecord_ele[3]
    laddr_obj = lrecord_obj[loc_id].rloc
    laddr_obj = Get_LispAddress_Object(rloc, laddr_obj=laddr_obj)
    lrecord_obj[loc_id].localLocator = flags % 10
    lrecord_obj[loc_id].rlocProbed = (flags / 10) % 10
    lrecord_obj[loc_id].routed = (flags / 100) % 10
    return lrecord_obj


def Get_LocatorRecord_JSON(rloc, weights="1/1/255/0", flags=0o01, loc_id="ISP1"):
    """ Description: Returns locator record dictionary
        Returns: python dictionary
        Params:
         rloc: eid_string for lisp address object
         weights: priority/weight/multicastPriority/multicastWeight
         flags: Three bit parameter in the sequence routed->rlocProbed->routed
         loc_id: id of locator record object
    """
    pbj_dump = pbJ.dumps(
        Get_LocatorRecord_Object(rloc, weights, flags, loc_id),
        filter=True,
        mode="default",
    )
    pbj_dict = json.loads(pbj_dump)
    pbj_dict[loc_id]["rloc"] = Get_LispAddress_Noeid_JSON(rloc)
    out_dump = '{"LocatorRecord":' + str(pbj_dict) + "}"
    return Clean_JSON(out_dump)


def Get_MappingRecord_Object(
    eid, locators, ttl=1440, authoritative=True, action="NoAction"
):
    """ Description: Returns mapping record object from pyangbind generated classes.
        Returns: mapping record object
        Params:
         eid: lisp address object
         locators: list of locator record objects
         ttl: recordTtl
         authoritative: authoritative
         action: action
    """
    sys.path.insert(0, workspace)
    from LISPFlowMappingYANGBindings.odl_mappingservice_rpc.add_mapping.input import (
        input,
    )

    rpc_input = input()
    mrecord_obj = rpc_input.mapping_record
    mrecord_obj.recordTtl = ttl
    mrecord_obj.authoritative = authoritative
    mrecord_obj.action = action
    copy_eid(mrecord_obj.eid, eid)
    idx = 0
    loc_ids = []
    for loc in locators:
        loc_id = loc.keys()[0]
        loc_obj = loc[loc_id]
        if loc_id in loc_ids:
            print("Locator objects should have different keys")
            break
        # TODO: Locator-id, currently in the format of loc_id0, loc_id1
        mrecord_obj.LocatorRecord.add(loc_id)
        mrecord_loc_obj = mrecord_obj.LocatorRecord[loc_id]
        mrecord_loc_obj.priority = loc_obj.priority
        mrecord_loc_obj.weight = loc_obj.weight
        mrecord_loc_obj.multicastPriority = loc_obj.multicastPriority
        mrecord_loc_obj.multicastWeight = loc_obj.multicastWeight
        copy_rloc(mrecord_loc_obj.rloc, loc_obj.rloc)
        mrecord_loc_obj.localLocator = loc_obj.localLocator
        mrecord_loc_obj.rlocProbed = loc_obj.rlocProbed
        mrecord_loc_obj.routed = loc_obj.routed
        idx += 1
    return mrecord_obj


def Get_MappingRecord_JSON(
    eid, locators, ttl=1440, authoritative=True, action="NoAction"
):
    """ Description: Returns mapping record dictionary
        Returns: python dictionary
        Params:
         eid: lisp address object
         locators: list of locator record objects
         ttl: recordTtl
         authoritative: authoritative
         action: action
    """
    pbj_dump = pbJ.dumps(
        Get_MappingRecord_Object(eid, locators, ttl, authoritative, action),
        filter=True,
        mode="ietf",
    )
    out_dump = '{"mapping-record":' + pbj_dump + "}"
    return Clean_JSON(out_dump)


def Get_MappingAuthkey_Object(key_string="password", key_type=1):
    """ Description: Returns mapping auth key object from pyangbind generated classes.
        Returns: mapping auth key object
        Params:
         key_string: key string
         key_type: key type
    """
    sys.path.insert(0, workspace)
    from LISPFlowMappingYANGBindings.odl_mappingservice_rpc.add_key.input import (
        input as add_key_input,
    )

    rpc_input = add_key_input()
    authkey_obj = rpc_input.mapping_authkey
    authkey_obj.key_string = key_string
    authkey_obj.key_type = key_type
    return authkey_obj


def Get_MappingAuthkey_JSON(key_string="password", key_type=1):
    """ Description: Returns mapping auth key dictionary
        Returns: python dictionary
        Params:
         key_string: key string
         key_type: key type
    """
    pbj_dump = pbJ.dumps(
        Get_MappingAuthkey_Object(key_string, key_type), filter=True, mode="default"
    )
    out_dump = '{"mapping-authkey":' + pbj_dump + "}"
    return Clean_JSON(out_dump)

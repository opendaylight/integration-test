import json
from pyangbind.lib.serialise import pybindJSONEncoder
from LISPFlowMappingYANGBindings import ietf_lisp_address_types

def get_eid_json(eid_string, vni=None):
    """Returns an EID object based its string representation"""

    laddr_obj = ietf_lisp_address_types()

    if vni:
        laddr_obj.eid.virtual_network_id = vni

    eid_string = eid_string.split(':')
    prefix, text = eid_string[0], ':'.join(eid_string[1:])
    if prefix:
        if prefix == 'srcdst':
            laddr_obj.eid.address_type = 'laddr:source-dest-key-lcaf'
            text = text.split('|')
            laddr_obj.eid.source_dest_key.source = text[0]
            laddr_obj.eid.source_dest_key.dest = text[1]
        elif prefix == 'no':
            laddr_obj.eid.address_type = 'laddr:no-address-afi'
        elif prefix == 'ipv4':
            laddr_obj.eid.address_type = 'laddr:ipv4-afi'
            laddr_obj.eid.ipv4 = text
        elif prefix == 'ipv4-prefix':
            print text
            laddr_obj.eid.address_type = 'laddr:ipv4-prefix-afi'
            laddr_obj.eid.ipv4_prefix = text
        elif prefix == 'ipv6':
            laddr_obj.eid.address_type = 'laddr:ipv6-afi'
            laddr_obj.eid.ipv6 = text
        elif prefix == 'ipv6-prefix':
            laddr_obj.eid.address_type = 'laddr:ipv6-prefix-afi'
            laddr_obj.eid.ipv6_prefix = text
        elif prefix == 'mac':
            laddr_obj.eid.address_type = 'laddr:mac-afi'
            laddr_obj.eid.mac = text
        elif prefix == 'dn':
            laddr_obj.eid.address_type = 'laddr:distinguished-name-afi'
            laddr_obj.eid.distinguished_name = text
        elif prefix == 'as':
            laddr_obj.eid.address_type = 'laddr:as-number-afi'
            laddr_obj.eid.as_number = text
        elif prefix == 'list':
            laddr_obj.eid.address_type = 'laddr:afi-list-lcaf'
            list_elements = text[1:len(text)-1].split(',') # removed start and end braces
            laddr_obj.eid.afi_list.address_list = list_elements
        elif prefix == 'kv':
            laddr_obj.eid.address_type = 'laddr:key-value-address-lcaf'
            text = text.split('->')
            laddr_obj.eid.key_value_address.key = text[0]
            laddr_obj.eid.key_value_address.value = text[1]
        elif prefix == 'sp':
            laddr_obj.eid.address_type = 'laddr:service-path-lcaf'
            text = text.split('(')
            laddr_obj.eid.service_path.service_path_id = text[0]
            laddr_obj.eid.service_path.service_index = text[1][:-1]

        ## TODO: Implementation

    # else: Instance Id case, [223] 192.0.2.0/24
    ## TODO: Implementation

    return json.dumps(laddr_obj.get(filter=True), cls=pybindJSONEncoder, indent=4)

print get_eid_json("sp:42(3)")
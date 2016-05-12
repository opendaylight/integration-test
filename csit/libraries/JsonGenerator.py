import json
import pyangbind.lib.pybindJSON as pbJ

def get_lisp_address_json(eid_string, vni=None):
    """Returns an EID object based its string representation"""
    from LISPFlowMappingYANGBindings.odl_mappingservice_rpc.add_mapping.input import input

    rpc_input = input()
    laddr_obj = rpc_input.mapping_record

    if vni:
        laddr_obj.eid.virtual_network_id = vni

    eid_string = eid_string.split(':')
    prefix, text = eid_string[0], ':'.join(eid_string[1:])
    if prefix:
        if prefix == 'srcdst':
            # Example: srcdst:192.0.2.1/32|192.0.2.2/32
            laddr_obj.eid.address_type = 'laddr:source-dest-key-lcaf'
            text = text.split('|')
            laddr_obj.eid.source_dest_key.source = text[0]
            laddr_obj.eid.source_dest_key.dest = text[1]
        elif prefix == 'no':
            # Example: no:
            laddr_obj.eid.address_type = 'laddr:no-address-afi'
        elif prefix == 'ipv4':
            if '/' in text:
                # Case: ipv4-prefix
                laddr_obj.eid.address_type = 'laddr:ipv4-prefix-afi'
                laddr_obj.eid.ipv4_prefix = text
            else:
                # Case: ipv4
                laddr_obj.eid.address_type = 'laddr:ipv4-afi'
                laddr_obj.eid.ipv4 = text
        elif prefix == 'ipv6':
            if '/' in text:
                # Case: ipv6-prefix
                laddr_obj.eid.address_type = 'laddr:ipv6-prefix-afi'
                laddr_obj.eid.ipv6_prefix = text
            else:
                laddr_obj.eid.address_type = 'laddr:ipv6-afi'
                laddr_obj.eid.ipv6 = text
        elif prefix == 'mac':
            # Example: mac:00:00:5E:00:53:00
            laddr_obj.eid.address_type = 'laddr:mac-afi'
            laddr_obj.eid.mac = text
        elif prefix == 'dn':
            # Example: dn:stringAsIs
            laddr_obj.eid.address_type = 'laddr:distinguished-name-afi'
            laddr_obj.eid.distinguished_name = text
        elif prefix == 'as':
            # Example: as:AS64500
            laddr_obj.eid.address_type = 'laddr:as-number-afi'
            laddr_obj.eid.as_number = text
        elif prefix == 'list':
            # Example: list:{192.0.2.1,192.0.2.2,2001:db8::1}
            laddr_obj.eid.address_type = 'laddr:afi-list-lcaf'
            list_elements = text[1:len(text)-1].split(',') # removed start and end braces
            laddr_obj.eid.afi_list.address_list = list_elements
        elif prefix == 'appdata':
            # Example: appdata:192.0.2.1!128!17!80-81!6667-7000
            laddr_obj.eid.address_type = 'laddr:application-data-lcaf'
            text = text.split('!')
            laddr_obj.eid.application_data.address = text[0]
            laddr_obj.eid.application_data.ip_tos = text[1]
            laddr_obj.eid.application_data.protocol = text[2]
            local_ports = text[3].split('-')
            laddr_obj.eid.application_data.local_port_low = local_ports[0]
            laddr_obj.eid.application_data.local_port_high = local_ports[1]
            remote_ports = text[4].split('-')
            laddr_obj.eid.application_data.remote_port_low = remote_ports[0]
            laddr_obj.eid.application_data.remote_port_high = remote_ports[1]
        elif prefix == 'elp':
            # TODO: BITS_TYPE_for_lps_AND___YANG_ORDER_IN_JSON
            # Example: elp:{192.0.2.1->192.0.2.2|lps->192.0.2.3}
            laddr_obj.eid.address_type = 'laddr:explicit-locator-path-lcaf'
            text = text[1:len(text)-1]
            text = text.split('->') # all the hops
            for i in range(0, len(text)):
                laddr_obj.eid.explicit_locator_path.hop.add("hop"+str(i))
                text[i] = text[i].split('|')[0]
                laddr_obj.eid.explicit_locator_path.hop["hop"+str(i)].address = text[i]
        elif prefix == 'kv':
            # Example: kv:192.0.2.1->192.0.2.2
            laddr_obj.eid.address_type = 'laddr:key-value-address-lcaf'
            text = text.split('->')
            laddr_obj.eid.key_value_address.key = text[0]
            laddr_obj.eid.key_value_address.value = text[1]
        elif prefix == 'sp':
            # Example: sp:42(3)
            laddr_obj.eid.address_type = 'laddr:service-path-lcaf'
            text = text.split('(')
            laddr_obj.eid.service_path.service_path_id = text[0]
            laddr_obj.eid.service_path.service_index = text[1][:-1]

    return pbJ.dumps(laddr_obj, filter=True, mode="ietf")

print get_lisp_address_json("srcdst:192.0.2.1/32|192.0.2.2/32")

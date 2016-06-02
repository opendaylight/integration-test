import json
import requests


def _process_flow_param(param, value):
    """ Processes and transforms flows parameters if needed """
    if param == 'cookie':
        return param, str(int(value, 16))
    else:
        return param, value


def _process_line(line):
    """ Processes single line of flow entry """
    return dict([_process_flow_param(*p.strip().split('=')) for p in line.split(',') if p.count('=') == 1])


def parse_flow_dump(flow_dump_stdout):
    """ Transforms stdout to list of dicts """
    splitter = 'cookie'
    text = flow_dump_stdout.replace('\r', '')
    return [_process_line(splitter + l) for l in text.split(splitter)[1:]]


def get_elements_with_parameter_value(parsed_flows, parameter, value):
    """ Gets flow dictionaries entries if they have parameter that equals value """
    return [pf for pf in parsed_flows if str(pf[parameter]) == str(value)]


def get_parameter_value_list_from_elements(parsed_flows, parameter):
    """ Gets list of flow parameter's values """
    return [pf[parameter] for pf in parsed_flows]


def get_table_flows_from_response(response):
    """ Gets list of flow from rest response called by api
    /restconf/config/opendaylight-inventory:nodes/node/<node-id>/table/<table-id>
    """
    return json.loads(response)['flow-node-inventory:table'][0]['flow']


def extract_property(table_json, prop):
    """ Transforms list of flows json into flat list with selected flow parameter values
    """
    return [str(f[prop]) for f in table_json]


def sort_cookie_list(l):
    return sorted([int(e) for e in l])
# fd = """OFPST_FLOW reply (OF1.3) (xid=0x2): cookie=0xa, duration=47.093s, table=0, n_packets=5, n_bytes=390, send_flow_rem priority=0 actions=CONTROLLER:65535 cookie=0x11, duration=37.564s, table=2, n_packets=0, n_bytes=0, priority=17,mpls,dl_src=00:00:00:11:23:ae,dl_dst=ff:ff:29:01:19:61,mpls_label=567,mpls_tc=3,mpls_bos=1 actions=dec_mpls_ttl cookie=0x4, duration=39.057s, table=2, n_packets=0, n_bytes=0, priority=4,mpls,dl_src=00:00:00:00:23:ae,dl_dst=ff:ff:ff:ff:ff:ff actions=dec_mpls_ttl cookie=0x2b, duration=34.348s, table=2, n_packets=0, n_bytes=0, priority=43,icmp6,icmp_type=135,icmp_code=1 actions=dec_ttl cookie=0x2f, duration=34.040s, table=2, n_packets=0, n_bytes=0, priority=47,sctp,tp_src=1435,tp_dst=22 actions=drop cookie=0x10, duration=37.684s, table=2, n_packets=0, n_bytes=0, priority=16,ip,dl_vlan=78,dl_vlan_pcp=3,dl_src=00:00:00:11:23:ae,dl_dst=ff:ff:29:01:19:61 actions=dec_ttl cookie=0x3, duration=39.181s, table=2, n_packets=0, n_bytes=0, priority=3,dl_src=00:00:00:00:00:01 actions=drop cookie=0x2, duration=39.303s, table=2, n_packets=0, n_bytes=0, priority=2,ip,nw_src=10.0.0.1 actions=drop cookie=0x9, duration=38.385s, table=2, n_packets=0, n_bytes=0, priority=9,udp,in_port=0,dl_src=00:00:00:11:23:ae,dl_dst=20:14:29:01:19:61,nw_src=19.1.0.0/16,nw_dst=172.168.5.0/24,nw_tos=32,nw_ecn=3,tp_src=25364,tp_dst=8080 actions=dec_ttl cookie=0xd, duration=38.001s, table=2, n_packets=0, n_bytes=0, priority=13,arp,dl_src=00:00:00:01:23:ae,dl_dst=ff:ff:ff:ff:ff:ff,arp_spa=192.168.4.1,arp_tpa=10.21.22.23,arp_op=1 actions=drop cookie=0x2d, duration=34.228s, table=2, n_packets=0, n_bytes=0, priority=45,metadata=0x64/0x46645a66 actions=drop cookie=0x14, duration=37.276s, table=2, n_packets=0, n_bytes=0, priority=20,metadata=0x1010/0x12d692 actions=LOCAL cookie=0x12, duration=37.458s, table=2, n_packets=0, n_bytes=0, priority=18,ipv6,ipv6_src=fe80::2acf:e9ff:fe21:6431,ipv6_dst=aabb:1234:2acf:e9ff::/64 actions=dec_ttl cookie=0xb, duration=38.244s, table=2, n_packets=0, n_bytes=0, priority=11,icmp,in_port=0,dl_src=00:00:00:11:23:ae,dl_dst=ff:ff:29:01:19:61,nw_src=17.0.0.0/8,nw_dst=172.168.0.0/16,nw_tos=108,nw_ecn=3,icmp_type=6,icmp_code=3 actions=dec_ttl cookie=0x8, duration=38.385s, table=2, n_packets=0, n_bytes=0, priority=8,tcp,in_port=0,dl_src=00:00:00:11:23:ae,dl_dst=ff:ff:29:01:19:61,nw_src=17.0.0.0/8,nw_dst=172.168.0.0/16,nw_tos=8,nw_ecn=2,tp_src=25364,tp_dst=8080 actions=dec_ttl cookie=0xa, duration=38.342s, table=2, n_packets=0, n_bytes=0, priority=10,sctp,in_port=0,dl_src=00:00:00:11:23:ae,dl_dst=ff:ff:29:01:19:61,nw_src=17.0.0.0/8,nw_dst=172.168.0.0/16,nw_tos=0,nw_ecn=0,tp_src=768,tp_dst=384 actions=dec_ttl cookie=0x7, duration=38.700s, table=2, n_packets=0, n_bytes=0, priority=7,ip,in_port=0,dl_src=00:00:00:11:23:ae,dl_dst=ff:ff:ff:ff:ff:aa,nw_src=10.1.2.0/24,nw_dst=20.4.0.0/16,nw_proto=56,nw_tos=60,nw_ecn=1 actions=dec_ttl cookie=0x1, duration=39.354s, table=2, n_packets=0, n_bytes=0, priority=1,ip,nw_dst=10.0.1.0/24 actions=dec_ttl cookie=0x2a, duration=34.348s, table=2, n_packets=0, n_bytes=0, priority=42,ip,nw_dst=10.0.0.0/24 actions=drop cookie=0x29, duration=34.348s, table=2, n_packets=0, n_bytes=0, priority=41,ip,nw_dst=10.0.0.0/24 actions=drop cookie=0x26, duration=35.494s, table=2, n_packets=0, n_bytes=0, priority=38,ip,nw_dst=10.0.0.0/24 actions=set_queue:1 cookie=0x25, duration=35.589s, table=2, n_packets=0, n_bytes=0, priority=37,ip,nw_dst=10.0.0.0/24 actions=mod_nw_ttl:1 cookie=0x24, duration=35.700s, table=2, n_packets=0, n_bytes=0, priority=36,ip,nw_dst=10.0.0.0/24 actions=set_field:1->ip_dscp cookie=0x23, duration=35.790s, table=2, n_packets=0, n_bytes=0, priority=35,ip,nw_dst=10.0.0.0/24 actions=set_field:10.0.23.21->ip_src cookie=0x22, duration=35.869s, table=2, n_packets=0, n_bytes=0, priority=34,ip,nw_dst=10.0.0.0/24 actions=set_field:10.0.0.21->ip_dst cookie=0x21, duration=35.970s, table=2, n_packets=0, n_bytes=0, priority=33,ip,nw_dst=10.0.0.0/24 actions=drop cookie=0x1f, duration=36.171s, table=2, n_packets=0, n_bytes=0, priority=31,ip,nw_dst=10.0.0.0/24 actions=drop cookie=0x1e, duration=36.267s, table=2, n_packets=0, n_bytes=0, priority=30,ip,nw_dst=10.0.0.0/24 actions=drop cookie=0x13, duration=37.354s, table=2, n_packets=0, n_bytes=0, priority=19,metadata=0x3039 actions=IN_PORT cookie=0x5, duration=38.956s, table=2, n_packets=0, n_bytes=0, priority=5,ip,in_port=0,dl_src=00:00:00:00:23:ae,dl_dst=ff:ff:ff:ff:ff:ff,nw_src=10.1.2.0/24,nw_dst=20.4.0.0/16 actions=dec_ttl cookie=0x16, duration=37.067s, table=2, n_packets=0, n_bytes=0, priority=22,tcp6,metadata=0x3039,ipv6_src=1234:5678:9abc:def0:fdc0::/76,ipv6_dst=fe80:2acf:e9ff:fe21::/94,nw_tos=240,nw_ecn=3,tp_src=183,tp_dst=8080 actions=dec_ttl cookie=0xc, duration=38.123s, table=2, n_packets=0, n_bytes=0, priority=12,arp,dl_src=00:00:00:01:23:ae,dl_dst=ff:ff:ff:ff:ff:ff,arp_op=1 actions=drop cookie=0xe, duration=37.884s, table=2, n_packets=0, n_bytes=0, priority=14,arp,dl_src=00:00:fc:01:23:ae,dl_dst=ff:ff:ff:ff:ff:ff,arp_spa=192.168.4.1,arp_tpa=10.21.22.23,arp_op=1,arp_sha=12:34:56:78:98:ab,arp_tha=fe:dc:ba:98:76:54 actions=CONTROLLER:60 cookie=0x17, duration=36.953s, table=2, n_packets=0, n_bytes=0, priority=23,tcp6,metadata=0x3039,ipv6_src=1234:5678:9abc:def0:fdc0::/76,ipv6_dst=fe80:2acf:e9ff:fe21::/94,ipv6_label=0x00021,nw_tos=240,nw_ecn=3,tp_src=183,tp_dst=8080 actions=dec_ttl cookie=0x19, duration=36.759s, table=2, n_packets=0, n_bytes=0, priority=25,icmp6,metadata=0x3039,ipv6_src=1234:5678:9abc:def0:fdc0::/76,ipv6_dst=fe80:2acf:e9ff:fe21::/94,ipv6_label=0x00021,nw_tos=240,nw_ecn=3,icmp_type=6,icmp_code=3 actions=dec_ttl cookie=0x18, duration=36.863s, table=2, n_packets=0, n_bytes=0, priority=24,tun_id=0xa1f actions=TABLE cookie=0x15, duration=37.170s, table=2, n_packets=0, n_bytes=0, priority=21,udp6,metadata=0x3039,ipv6_src=1234:5678:9abc:def0:fdc0::/76,ipv6_dst=fe80::2acf:e9ff:fe21:6431,nw_tos=32,nw_ecn=3,tp_src=25364,tp_dst=8080 actions=dec_ttl cookie=0x6, duration=38.827s, table=2, n_packets=0, n_bytes=0, priority=6,ip,dl_src=00:00:00:01:23:ae,dl_dst=ff:ff:ff:ff:ff:ff,nw_src=10.1.2.0/24,nw_dst=40.4.0.0/16 actions=dec_ttl cookie=0xf, duration=37.792s, table=2, n_packets=0, n_bytes=0, priority=15,mpls,dl_vlan=78,dl_src=00:00:00:11:23:ae,dl_dst=ff:ff:29:01:19:61 actions=dec_mpls_ttl [odl@tobereplaced ~]$"""


# ld = parse(fd)

# print(ld)

# print(get_elements_with_parameter_value(ld, 'cookie', '10'))

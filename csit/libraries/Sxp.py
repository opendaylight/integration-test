import json
from string import Template

from ipaddr import IPAddress


def mod(num, base):
    return int(num) % int(base)


def get_ip_from_number(n):
    ip = IPAddress(2130706432 + n)
    return str(ip)


def lower_version(ver1, ver2):
    v1 = int(ver1[-1:])
    v2 = int(ver2[-1:])
    if v1 <= v2:
        return ver1
    else:
        return ver2


def get_filter_entry(seq, type, **kwargs):
    typeofentry = "PL"
    entries = ""
    for name, value in kwargs.items():
        entry = ""
        if name == "SGT":
            args = value.split(',')
            entry = add_sgt_matches_xml(args)
        elif name == "ESGT":
            args = value.split(',')
            entry = add_sgt_range_xml(args[0], args[1])
        elif name == "ACL":
            typeofentry = "ACL"
            args = value.split(',')
            entry = add_acl_entry_xml(args[0], args[1])
        elif name == "EACL":
            typeofentry = "ACL"
            args = value.split(',')
            entry = add_eacl_entry_xml(args[0], args[1], args[2], args[3])
        elif name == "PL":
            entry = add_pl_entry_xml(value)
        elif name == "EPL":
            args = value.split(',')
            entry = add_epl_entry_xml(args[0], args[1], args[2])
        entries = entries + entry
    if typeofentry == "PL":
        return add_pl_entry_default_xml(seq, type, entries)
    return add_acl_entry_default_xml(seq, type, entries)


def add_peers(*args):
    templ = Template('''
        <sxp-peer>
            <peer-address>$ip</peer-address>
        </sxp-peer>''')
    peers = ""
    for count, value in enumerate(args):
        peers = peers + templ.substitute({'ip': value})
    return peers


def add_sgt_matches_xml(input):
    templ = Template('''
        <matches>$sgt</matches>''')
    matches = ""
    for sgt in input:
        matches = matches + templ.substitute({'sgt': sgt})
    return matches


def add_sgt_range_xml(start, end):
    templ = Template('''
        <sgt-start>$start</sgt-start>
        <sgt-end>$end</sgt-end>''')
    match = templ.substitute({'start': start, 'end': end})
    return match


def add_acl_entry_default_xml(seq, type, input):
    templ = Template('''
        <acl-entry>
            <entry-type>$type</entry-type>
            <entry-seq>$seq</entry-seq>$input
        </acl-entry>''')
    matches = templ.substitute({'seq': seq, 'type': type, 'input': input})
    return matches


def add_acl_entry_xml(ip, mask):
    templ = Template('''
        <acl-match>
            <ip-address>$ip</ip-address>
            <wildcard-mask>$mask</wildcard-mask>
        </acl-match>''')
    return templ.substitute({'ip': ip, 'mask': mask})


def add_eacl_entry_xml(ip, mask, amask, wmask):
    templ = Template('''
        <acl-match>
            <ip-address>$ip</ip-address>
            <wildcard-mask>$mask</wildcard-mask>
            <mask>
              <address-mask>$amask</address-mask>
              <wildcard-mask>$wmask</wildcard-mask>
            </mask>
        </acl-match>''')
    return templ.substitute({'ip': ip, 'mask': mask, 'amask': amask, 'wmask': wmask})


def add_pl_entry_default_xml(seq, type, input):
    templ = Template('''
    <prefix-list-entry xmlns="urn:opendaylight:sxp:controller">
          <entry-type>$type</entry-type>
          <entry-seq>$seq</entry-seq>$input
    </prefix-list-entry>''')
    return templ.substitute({'seq': seq, 'type': type, 'input': input})


def add_pl_entry_xml(prefix):
    templ = Template('''
        <prefix-list-match>
            <ip-prefix>$prefix</ip-prefix>
        </prefix-list-match>''')
    return templ.substitute({'prefix': prefix})


def add_epl_entry_xml(prefix, op, mask):
    templ = Template('''
        <prefix-list-match>
            <ip-prefix>$prefix</ip-prefix>
            <mask>
                <mask-range>$op</mask-range>
                <mask-value>$mask</mask-value>
            </mask>
        </prefix-list-match>''')
    return templ.substitute({'prefix': prefix, 'mask': mask, 'op': op})


def parse_peer_groups(input):
    data = json.loads(input)
    groups = data['output']
    output = []
    for list in groups.values():
        output = output + list
    return output


def parse_connections(input):
    data = json.loads(input)
    connections = data['output']['connections']
    output = []
    for list in connections.values():
        output = output + list
    return output


def find_connection(input, version, mode, ip, port, state):
    for connection in parse_connections(input):
        if (connection['peer-address'] == ip and connection['tcp-port'] == int(port) and connection['mode'] == mode and
                    connection['version'] == version):
            if state == 'none':
                return True
            elif connection['state'] == state:
                return True
    return False


def parse_prefix_groups(input, source_):
    data = json.loads(input)
    bindings = data['sxp-node:master-database']
    output = []
    for binding in bindings.values():
        for binding_source in binding:
            if binding_source['binding-source'] == source_:
                for prefix_group in binding_source['prefix-group']:
                    output.append(prefix_group)
    return output


def find_binding(input, sgt, prefix, source_, action):
    found = False
    for prefixgroup in parse_prefix_groups(input, source_):
        if prefixgroup['sgt'] == int(sgt):
            for binding in prefixgroup['binding']:
                if binding['ip-prefix'] == prefix and binding['action'] == action:
                    found = True
    return found


def find_binding_with_peer_sequence(input, sgt, prefix, source_, action, node_id, peer_seq):
    correct_sequence = False
    found_source = False
    for prefixgroup in parse_prefix_groups(input, source_):
        if prefixgroup['sgt'] == int(sgt):
            for binding in prefixgroup['binding']:
                if binding['ip-prefix'] == prefix and binding['action'] == action:
                    for peer in binding['peer-sequence']['peer']:
                        if peer['seq'] == int(peer_seq) and peer['node-id'] == node_id:
                            correct_sequence = True
                    for peer_source in binding['sources']['source']:
                        if peer_source == node_id:
                            found_source = True
    return found_source and correct_sequence


def add_entry_xml(sgt, prefix, ip):
    templ = Template('''<input>
  <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
  <sgt xmlns="urn:opendaylight:sxp:controller">$sgt</sgt>
  <ip-prefix xmlns="urn:opendaylight:sxp:controller">$prefix</ip-prefix>
</input>''')
    data = templ.substitute({'sgt': sgt, 'prefix': prefix, 'ip': ip})
    return data


def add_connection_xml(version, mode, ip, port, ip_, password_):
    templ = Template('''<input>
   <requested-node xmlns="urn:opendaylight:sxp:controller">$ip_</requested-node>
   <connections xmlns="urn:opendaylight:sxp:controller">
      <connection>
         <peer-address>$ip</peer-address>
         <tcp-port>$port</tcp-port>
         <password>$password_</password>
         <mode>$mode</mode>
         <version>$version</version>
         <description>Connection to ISR-G2</description>
         <connection-timers>
            <hold-time-min-acceptable>45</hold-time-min-acceptable>
            <keep-alive-time>30</keep-alive-time>
            <reconciliation-time>120</reconciliation-time>
         </connection-timers>
      </connection>
   </connections>
</input>
''')
    data = templ.substitute(
        {'ip': ip, 'port': port, 'mode': mode, 'version': version, 'ip_': ip_, 'password_': password_})
    return data


def delete_connections_xml(address, port, node):
    templ = Template('''<input>
   <requested-node xmlns="urn:opendaylight:sxp:controller">$node</requested-node>
   <peer-address xmlns="urn:opendaylight:sxp:controller">$address</peer-address>
   <tcp-port xmlns="urn:opendaylight:sxp:controller">$port</tcp-port>
</input>''')
    data = templ.substitute({'address': address, 'port': port, 'node': node})
    return data


def update_binding_xml(sgt0, prefix0, sgt1, prefix1, ip):
    templ = Template('''<input>
  <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
  <original-binding xmlns="urn:opendaylight:sxp:controller">
    <sgt>$sgt0</sgt>
    <ip-prefix>$prefix0</ip-prefix>
  </original-binding>
  <new-binding xmlns="urn:opendaylight:sxp:controller">
    <sgt>$sgt1</sgt>
    <ip-prefix>$prefix1</ip-prefix>
  </new-binding>
</input>''')
    data = templ.substitute(
        {'sgt0': sgt0, 'sgt1': sgt1, 'prefix0': prefix0, 'prefix1': prefix1, 'ip': ip})
    return data


def delete_binding_xml(sgt, prefix, ip):
    templ = Template('''<input>
  <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
  <sgt xmlns="urn:opendaylight:sxp:controller">$sgt</sgt>
  <ip-prefix xmlns="urn:opendaylight:sxp:controller">$prefix</ip-prefix>
</input>''')
    data = templ.substitute({'sgt': sgt, 'prefix': prefix, 'ip': ip})
    return data


def add_peer_group_xml(name, peers, ip):
    templ = Template('''<input>
  <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
  <sxp-peer-group xmlns="urn:opendaylight:sxp:controller">
    <name xmlns="urn:opendaylight:sxp:controller">$name</name>
    <sxp-peers xmlns="urn:opendaylight:sxp:controller">$peers</sxp-peers>
    </sxp-peer-group>
</input>''')
    data = templ.substitute({'name': name, 'peers': peers, 'ip': ip})
    return data


def delete_peer_group_xml(name, ip):
    templ = Template('''<input>
  <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
  <peer-group-name xmlns="urn:opendaylight:sxp:controller">$name</peer-group-name>
</input>''')
    data = templ.substitute({'name': name, 'ip': ip})
    return data


def get_peer_groups_from_node_xml(ip):
    templ = Template('''<input>
   <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
</input>''')
    data = templ.substitute({'ip': ip})
    return data


def add_filter_xml(group, type, entries, ip):
    templ = Template('''<input>
  <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
  <peer-group-name xmlns="urn:opendaylight:sxp:controller">$group</peer-group-name>
  <sxp-filter xmlns="urn:opendaylight:sxp:controller">
    <filter-type>$type</filter-type>$entries
  </sxp-filter>
</input>''')
    data = templ.substitute({'group': group, 'type': type, 'ip': ip, 'entries': entries})
    return data


def delete_filter_xml(group, type, ip):
    templ = Template('''<input>
  <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
  <peer-group-name xmlns="urn:opendaylight:sxp:controller">$group</peer-group-name>
  <filter-type xmlns="urn:opendaylight:sxp:controller">$type</filter-type>
</input>''')
    data = templ.substitute({'group': group, 'type': type, 'ip': ip})
    return data


def get_connections_from_node_xml(ip):
    templ = Template('''<input>
   <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
</input>''')
    data = templ.substitute({'ip': ip})
    return data


def get_bindings_from_node_xml(ip):
    templ = Template('''<input>
  <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
</input>''')
    data = templ.substitute({'ip': ip})
    return data

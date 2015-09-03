import json
from ipaddr import IPAddress
from string import Template


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

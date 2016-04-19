import json
from ipaddr import IPAddress
from string import Template


def mod(num, base):
    """Gets modulo of number

    :param num: Number to be used
    :type num: string
    :param base: Base used
    :type base: string
    :returns: Int representing modulo of specified numbers.

    """
    return int(num) % int(base)


def get_ip_from_number(n):
    """Generate string representing Ipv4 from specified number that is added number 2130706432

    :param n: Number to be converted
    :type n: int
    :returns: String containing Ipv4.

    """
    ip = IPAddress(2130706432 + n)
    return str(ip)


def lower_version(ver1, ver2):
    """Generate xml containing SGT mach data

    :param ver1: Version of SXP protocol for compare
    :type ver1: string
    :param ver2: Version of SXP protocol for compare
    :type ver2: string
    :returns: String containing lower from those two specified versions.

    """
    v1 = int(ver1[-1:])
    v2 = int(ver2[-1:])
    if v1 <= v2:
        return ver1
    else:
        return ver2


def get_filter_entry(seq, entry_type, sgt="", esgt="", acl="", eacl="", pl="", epl="", ps=""):
    """Generate xml containing FilterEntry data

    :param seq: Sequence of entry
    :type seq: string
    :param entry_type: Type of entry (permit/deny)
    :type entry_type: string
    :param sgt: SGT matches to be added to entry
    :type sgt: string
    :param esgt: SGT ranges match to be added to entry
    :type esgt: string
    :param acl: ACL matches to be added to entry
    :type acl: string
    :param eacl: EACL matches to be added to entry
    :type eacl: string
    :param pl: PrefixList matches to be added to entry
    :type pl: string
    :param epl: ExtendedPrefixList matches to be added to entry
    :type epl: string
    :param ps: PeerSequence matches to be added to entry
    :type ps: string
    :returns: String containing xml data for request

    """
    entries = ""
    # Generate XML request containing combination of Matches of different types
    if sgt:
        args = sgt.split(',')
        entries += add_sgt_matches_xml(args)
    elif esgt:
        args = esgt.split(',')
        entries += add_sgt_range_xml(args[0], args[1])
    if pl:
        entries += add_pl_entry_xml(pl)
    elif epl:
        args = epl.split(',')
        entries += add_epl_entry_xml(args[0], args[1], args[2])
    if acl:
        args = acl.split(',')
        entries += add_acl_entry_xml(args[0], args[1])
    elif eacl:
        args = eacl.split(',')
        entries += add_eacl_entry_xml(args[0], args[1], args[2], args[3])
    if ps:
        args = ps.split(',')
        entries += add_ps_entry_xml(args[0], args[1])
    # Wrap entries in ACL/PrefixList according to specified values
    if pl or epl:
        return add_pl_entry_default_xml(seq, entry_type, entries)
    elif ps:
        return add_ps_entry_default_xml(seq, entry_type, entries)
    return add_acl_entry_default_xml(seq, entry_type, entries)


def add_peers(*args):
    """Generate xml containing Peer mach data

    :param args: Peers data
    :type args: dict
    :returns: String containing xml data for request

    """
    templ = Template('''
        <sxp-peer>
            <peer-address>$ip</peer-address>
        </sxp-peer>''')
    peers = ""
    for count, value in enumerate(args):
        peers += templ.substitute({'ip': value})
    return peers


def add_sgt_matches_xml(sgt_entries):
    """Generate xml containing SGT mach data

    :param sgt_entries: SGT matches
    :type sgt_entries: string
    :returns: String containing xml data for request

    """
    templ = Template('''
        <matches>$sgt</matches>''')
    matches = ""
    for sgt in sgt_entries:
        matches += templ.substitute({'sgt': sgt})
    return matches


def add_sgt_range_xml(start, end):
    """Generate xml containing SGT RangeMach data

    :param start: Start range of SGT
    :type start: string
    :param end: End range of SGT
    :type end: string
    :returns: String containing xml data for request

    """
    templ = Template('''
        <sgt-start>$start</sgt-start>
        <sgt-end>$end</sgt-end>''')
    match = templ.substitute({'start': start, 'end': end})
    return match


def add_acl_entry_default_xml(seq, entry_type, acl_entries):
    """Generate xml containing AccessList data

    :param seq: Sequence of PrefixList entry
    :type seq: string
    :param entry_type: Entry type (permit/deny)
    :type entry_type: string
    :param acl_entries: XML data containing AccessList entries
    :type acl_entries: string
    :returns: String containing xml data for request

    """
    templ = Template('''
        <acl-entry>
            <entry-type>$entry_type</entry-type>
            <entry-seq>$seq</entry-seq>$acl_entries
        </acl-entry>''')
    matches = templ.substitute(
        {'seq': seq, 'entry_type': entry_type, 'acl_entries': acl_entries})
    return matches


def add_acl_entry_xml(ip, mask):
    """Generate xml containing AccessList data

    :param ip: Ipv4/6 address
    :type ip: string
    :param mask: Ipv4/6 wildcard mask
    :type mask: string
    :returns: String containing xml data for request

    """
    templ = Template('''
        <acl-match>
            <ip-address>$ip</ip-address>
            <wildcard-mask>$mask</wildcard-mask>
        </acl-match>''')
    return templ.substitute({'ip': ip, 'mask': mask})


def add_eacl_entry_xml(ip, mask, amask, wmask):
    """Generate xml containing ExtendedAccessList data

    :param ip: Ipv4/6 address
    :type ip: string
    :param mask: Ipv4/6 wildcard mask
    :type mask: string
    :param amask: Ipv4/6 address mask
    :type amask: string
    :param wmask: Ipv4/6 address wildcard mask
    :type wmask: string
    :returns: String containing xml data for request

    """
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


def add_ps_entry_default_xml(seq, entry_type, ps_entries):
    """Generate xml containing PeerSequence data

    :param seq: Sequence of PrefixList entry
    :type seq: string
    :param entry_type: Entry type (permit/deny)
    :type entry_type: string
    :param ps_entries: XML data containing PeerSequence entries
    :type ps_entries: string
    :returns: String containing xml data for request

    """
    templ = Template('''
    <peer-sequence-entry xmlns="urn:opendaylight:sxp:controller">
          <entry-type>$entry_type</entry-type>
          <entry-seq>$seq</entry-seq>$ps_entries
    </peer-sequence-entry>''')
    return templ.substitute({'seq': seq, 'entry_type': entry_type, 'ps_entries': ps_entries})


def add_pl_entry_default_xml(seq, entry_type, pl_entries):
    """Generate xml containing PrefixList data

    :param seq: Sequence of PrefixList entry
    :type seq: string
    :param entry_type: Entry type (permit/deny)
    :type entry_type: string
    :param pl_entries: XML data containing PrefixList entries
    :type pl_entries: string
    :returns: String containing xml data for request

    """
    templ = Template('''
    <prefix-list-entry xmlns="urn:opendaylight:sxp:controller">
          <entry-type>$entry_type</entry-type>
          <entry-seq>$seq</entry-seq>$pl_entries
    </prefix-list-entry>''')
    return templ.substitute({'seq': seq, 'entry_type': entry_type, 'pl_entries': pl_entries})


def add_pl_entry_xml(prefix):
    """Generate xml containing PrefixList data

    :param prefix: Ipv4/6 prefix
    :type prefix: string
    :returns: String containing xml data for request

    """
    templ = Template('''
        <prefix-list-match>
            <ip-prefix>$prefix</ip-prefix>
        </prefix-list-match>''')
    return templ.substitute({'prefix': prefix})


def add_epl_entry_xml(prefix, op, mask):
    """Generate xml containing Extended PrefixList data

    :param prefix: Ipv4/6 prefix
    :type prefix: string
    :param op: PrefixList option (ge/le/eq)
    :type op: string
    :param mask: Ipv4/6 Mask
    :type mask: string
    :returns: String containing xml data for request

    """
    templ = Template('''
        <prefix-list-match>
            <ip-prefix>$prefix</ip-prefix>
            <mask>
                <mask-range>$op</mask-range>
                <mask-value>$mask</mask-value>
            </mask>
        </prefix-list-match>''')
    return templ.substitute({'prefix': prefix, 'mask': mask, 'op': op})


def add_ps_entry_xml(op, length):
    """Generate xml containing Extended PrefixList data

    :param op: PrefixList option (ge/le/eq)
    :type op: string
    :param length: PeerSequence length
    :type length: string
    :returns: String containing xml data for request

    """
    templ = Template('''
        <peer-sequence-length>$length</peer-sequence-length>
        <peer-sequence-range>$op</peer-sequence-range>
        ''')
    return templ.substitute({'length': length, 'op': op})


def parse_peer_groups(groups_json):
    """Parse JSON string into Array of PeerGroups

    :param groups_json: JSON containing PeerGroups
    :type groups_json: string
    :returns: Array containing PeerGroups.

    """
    data = json.loads(groups_json)
    groups = data['output']
    output = []
    for group in groups.values():
        output += group
    return output


def parse_connections(connections_json):
    """Parse JSON string into Array of Connections

    :param connections_json: JSON containing Connections
    :type connections_json: string
    :returns: Array containing Connections.

    """
    data = json.loads(connections_json)
    connections = data['output']['connections']
    output = []
    for connection in connections.values():
        output += connection
    return output


def find_connection(connections_json, version, mode, ip, port, state):
    """Test if Connection with specified values is contained in JSON

    :param connections_json: JSON containing Connections
    :type connections_json: string
    :param version: Version of SXP protocol (version1/2/3/4)
    :type version: string
    :param mode: Mode of SXP peer (speaker/listener/both)
    :type mode: string
    :param ip: Ipv4/6 address of remote peer
    :type ip: string
    :param port: Port on with remote peer listens
    :type port: string
    :param state: State of connection (on/off/pendingOn/deleteHoldDown)
    :type state: string
    :returns: True if Connection with specified params was found, otherwise False.

    """
    for connection in parse_connections(connections_json):
        if (connection['peer-address'] == ip and connection['tcp-port'] == int(port) and connection['mode'] == mode and
                connection['version'] == version):
            if state == 'none':
                return True
            elif connection['state'] == state:
                return True
    return False


def parse_bindings(bindings_json):
    """Parse JSON string into Array of Bindings

    :param bindings_json: JSON containing Bindings
    :type bindings_json: string
    :returns: Array containing Bindings.

    """
    data = json.loads(bindings_json)
    output = []
    for bindings_json in data['output'].values():
        for binding in bindings_json:
            output.append(binding)
    return output


def find_binding(bindings, sgt, prefix):
    """Test if Binding with specified values is contained in JSON

    :param bindings: JSON containing Bindings
    :type bindings: string
    :param sgt: Source Group Tag
    :type sgt: string
    :param prefix: Ipv4/6 prefix
    :type prefix: string
    :returns: True if Binding with specified params was found, otherwise False.

    """
    for binding in parse_bindings(bindings):
        if binding['sgt'] == int(sgt):
            for ip_prefix in binding['ip-prefix']:
                if ip_prefix == prefix:
                    return True
    return False


def parse_prefix_groups(prefix_groups_json, source_):
    """Parse JSON string into Array of PrefixGroups

    :param prefix_groups_json: JSON containing PrefixGroups
    :type prefix_groups_json: string
    :param source_: Source of PrefixGroups (sxp/local)
    :type source_: string
    :returns: Array containing PrefixGroups.

    """
    data = json.loads(prefix_groups_json)
    bindings = data['sxp-node:master-database']
    output = []
    for binding in bindings.values():
        for binding_source in binding:
            if source_ == "any" or binding_source['binding-source'] == source_:
                for prefix_group in binding_source['prefix-group']:
                    output.append(prefix_group)
    return output


def find_binding_legacy(prefix_groups_json, sgt, prefix, source_, action):
    """Test if Binding with specified values is contained in JSON

    :param prefix_groups_json: JSON containing Bindings and PrefixGroups
    :type prefix_groups_json: string
    :param sgt: Source Group Tag
    :type sgt: string
    :param prefix: Ipv4/6 prefix
    :type prefix: string
    :param source_: Source of binding (local/sxp)
    :type source_: string
    :param action: Action for binding (add/delete)
    :type action: string
    :returns: True if Binding with specified params was found, otherwise False.

    """
    found = False
    for prefixgroup in parse_prefix_groups(prefix_groups_json, source_):
        if prefixgroup['sgt'] == int(sgt):
            for binding in prefixgroup['binding']:
                if binding['ip-prefix'] == prefix and binding['action'] == action:
                    found = True
    return found


def add_entry_xml(sgt, prefix, ip):
    """Generate xml for Add Bindings request

    :param sgt: Source Group Tag
    :type sgt: string
    :param prefix: Ipv4/6 prefix
    :type prefix: string
    :param ip: Ipv4 address of node
    :type ip: string
    :returns: String containing xml data for request

    """
    templ = Template('''<input>
  <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
  <sgt xmlns="urn:opendaylight:sxp:controller">$sgt</sgt>
  <ip-prefix xmlns="urn:opendaylight:sxp:controller">$prefix</ip-prefix>
</input>''')
    data = templ.substitute({'sgt': sgt, 'prefix': prefix, 'ip': ip})
    return data


def add_connection_xml(version, mode, ip, port, node, password_):
    """Generate xml for Add Connection request

    :param version: Version of SXP protocol (version1/2/3/4)
    :type version: string
    :param mode: Mode of SXP peer (speaker/listener/both)
    :type mode: string
    :param ip: Ipv4/6 address of remote peer
    :type ip: string
    :param port: Port on with remote peer listens
    :type port: string
    :param node: Ipv4 address of node
    :type node: string
    :param password_: Password type (none/default)
    :type password_: string
    :returns: String containing xml data for request

    """
    templ = Template('''<input>
   <requested-node xmlns="urn:opendaylight:sxp:controller">$node</requested-node>
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
        {'ip': ip, 'port': port, 'mode': mode, 'version': version, 'node': node, 'password_': password_})
    return data


def delete_connections_xml(address, port, node):
    """Generate xml for Delete Connection request

    :param address: Ipv4/6 address of remote peer
    :type address: string
    :param port: Port on with remote peer listens
    :type port: string
    :param node: Ipv4 address of node
    :type node: string
    :returns: String containing xml data for request

    """
    templ = Template('''<input>
   <requested-node xmlns="urn:opendaylight:sxp:controller">$node</requested-node>
   <peer-address xmlns="urn:opendaylight:sxp:controller">$address</peer-address>
   <tcp-port xmlns="urn:opendaylight:sxp:controller">$port</tcp-port>
</input>''')
    data = templ.substitute({'address': address, 'port': port, 'node': node})
    return data


def update_binding_xml(sgt0, prefix0, sgt1, prefix1, ip):
    """Generate xml for Update Binding request

    :param sgt0: Original Source Group Tag
    :type sgt0: string
    :param prefix0: Original Ipv4/6 prefix
    :type prefix0: string
    :param sgt1: New Source Group Tag
    :type sgt1: string
    :param prefix1: New Ipv4/6 prefix
    :type prefix1: string
    :param ip: Ipv4 address of node
    :type ip: string
    :returns: String containing xml data for request

    """
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
    """Generate xml for Delete Binding request

    :param sgt: Source Group Tag
    :type sgt: string
    :param prefix: Ipv4/6 prefix
    :type prefix: string
    :param ip: Ipv4 address of node
    :type ip: string
    :returns: String containing xml data for request

    """
    templ = Template('''<input>
  <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
  <sgt xmlns="urn:opendaylight:sxp:controller">$sgt</sgt>
  <ip-prefix xmlns="urn:opendaylight:sxp:controller">$prefix</ip-prefix>
</input>''')
    data = templ.substitute({'sgt': sgt, 'prefix': prefix, 'ip': ip})
    return data


def add_peer_group_xml(name, peers, ip):
    """Generate xml for Add PeerGroups request

    :param name: Name of PeerGroup
    :type name: string
    :param peers: XML formatted peers that will be added to group
    :type peers: string
    :param ip: Ipv4 address of node
    :type ip: string
    :returns: String containing xml data for request

    """
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
    """Generate xml for Delete PeerGroup request

    :param name: Name of PeerGroup
    :type name: string
    :param ip: Ipv4 address of node
    :type ip: string
    :returns: String containing xml data for request

    """
    templ = Template('''<input>
  <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
  <peer-group-name xmlns="urn:opendaylight:sxp:controller">$name</peer-group-name>
</input>''')
    data = templ.substitute({'name': name, 'ip': ip})
    return data


def get_peer_groups_from_node_xml(ip):
    """Generate xml for Get PeerGroups request

    :param ip: Ipv4 address of node
    :type ip: string
    :returns: String containing xml data for request

    """
    templ = Template('''<input>
   <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
</input>''')
    data = templ.substitute({'ip': ip})
    return data


def add_filter_xml(group, filter_type, entries, ip):
    """Generate xml for Add Filter request

    :param group: Name of group containing filter
    :type group: string
    :param filter_type: Type of filter
    :type filter_type: string
    :param entries: XML formatted entries that will be added in filter
    :type entries: string
    :param ip: Ipv4 address of node
    :type ip: string
    :returns: String containing xml data for request


    """
    templ = Template('''<input>
  <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
  <peer-group-name xmlns="urn:opendaylight:sxp:controller">$group</peer-group-name>
  <sxp-filter xmlns="urn:opendaylight:sxp:controller">
    <filter-type>$filter_type</filter-type>$entries
  </sxp-filter>
</input>''')
    data = templ.substitute(
        {'group': group, 'filter_type': filter_type, 'ip': ip, 'entries': entries})
    return data


def delete_filter_xml(group, filter_type, ip):
    """Generate xml for Delete Filter request

    :param group: Name of group containing filter
    :type group: string
    :param filter_type: Type of filter
    :type filter_type: string
    :param ip: Ipv4 address of node
    :type ip: string
    :returns: String containing xml data for request

    """
    templ = Template('''<input>
  <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
  <peer-group-name xmlns="urn:opendaylight:sxp:controller">$group</peer-group-name>
  <filter-type xmlns="urn:opendaylight:sxp:controller">$filter_type</filter-type>
</input>''')
    data = templ.substitute(
        {'group': group, 'filter_type': filter_type, 'ip': ip})
    return data


def get_connections_from_node_xml(ip):
    """Generate xml for Get Connections request

    :param ip: Ipv4 address of node
    :type ip: string
    :returns: String containing xml data for request

    """
    templ = Template('''<input>
   <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
</input>''')
    data = templ.substitute({'ip': ip})
    return data


def get_bindings_from_node_xml(ip, binding_range):
    """Generate xml for Get Bindings request

    :param binding_range: All or only Local bindings
    :type binding_range: string
    :param ip: Ipv4 address of node
    :type ip: string
    :returns: String containing xml data for request

    """
    templ = Template('''<input>
  <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
  <bindings-range xmlns="urn:opendaylight:sxp:controller">$range</bindings-range>
</input>''')
    data = templ.substitute({'ip': ip, 'range': binding_range})
    return data

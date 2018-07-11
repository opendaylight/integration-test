import json
from netaddr import IPAddress
from string import Template


def get_active_controller_from_json(resp, service):
    """Gets index of active controller running specified service

    :param resp: JSON formatted response from EOS
    :type resp: str
    :param service: EOS Service to look for
    :type service: str
    :return: Index of controller
    """
    entities = json.loads(resp)['entity-owners']['entity-type']
    for entity in entities:
        if entity['type'] == "org.opendaylight.mdsal.ServiceEntityType":
            for instance in entity['entity']:
                if service in instance['id']:
                    return int(instance['owner'][-1:])
    return 0


def mod(num, base):
    """Gets modulo of number

    :param num: Number to be used
    :type num: str
    :param base: Base used
    :type base: str
    :returns: Int representing modulo of specified numbers.

    """
    return int(num) % int(base)


def get_average_of_items(items):
    """Gets average of items in provided list

    :param items: To be proceed
    :return: Average value

    """
    return sum(items) / len(items)


def get_opposing_mode(mode):
    """Generate string representing opposing SXP peer mode

        :param mode: SXP peer mode
        :type mode: str
        :returns: String with opposing SXP peer mode.

        """
    if 'speaker' == mode:
        return 'listener'
    elif 'listener' == mode:
        return 'speaker'
    return 'both'


def get_ip_from_number(n, base=2130706432):
    """Generate string representing Ipv4 from specified number plus base value

    :param n: Number to be converted
    :type n: int
    :param base: Starting index
    :type base: int
    :returns: String containing Ipv4.

    """
    ip = IPAddress(int(base) + n)
    return str(ip)


def get_ip_from_number_and_ip(n, ip_address):
    """Generate string representing Ipv4 from specified number and IPAddress

    :param n: Number to be converted
    :type n: int
    :param ip_address: Base address
    :type ip_address: str
    :returns: String containing Ipv4.

    """
    ip = IPAddress(int(IPAddress(ip_address)) + n)
    return str(ip)


def lower_version(ver1, ver2):
    """Generate xml containing SGT mach data

    :param ver1: Version of SXP protocol for compare
    :type ver1: str
    :param ver2: Version of SXP protocol for compare
    :type ver2: str
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
    :type seq: str
    :param entry_type: Type of entry (permit/deny)
    :type entry_type: str
    :param sgt: SGT matches to be added to entry
    :type sgt: str
    :param esgt: SGT ranges match to be added to entry
    :type esgt: str
    :param acl: ACL matches to be added to entry
    :type acl: str
    :param eacl: EACL matches to be added to entry
    :type eacl: str
    :param pl: PrefixList matches to be added to entry
    :type pl: str
    :param epl: ExtendedPrefixList matches to be added to entry
    :type epl: str
    :param ps: PeerSequence matches to be added to entry
    :type ps: str
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


def add_domains(*args):
    """Generate xml containing Domain mach data

    :param args: Domain data
    :type args: dict
    :returns: String containing xml data for request

    """
    templ = Template('''
        <domain>
            <name>$name</name>
        </domain>''')
    peers = ""
    for count, value in enumerate(args):
        peers += templ.substitute({'name': value})
    return peers


def add_sgt_matches_xml(sgt_entries):
    """Generate xml containing SGT mach data

    :param sgt_entries: SGT matches
    :type sgt_entries: str
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
    :type start: str
    :param end: End range of SGT
    :type end: str
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
    :type seq: str
    :param entry_type: Entry type (permit/deny)
    :type entry_type: str
    :param acl_entries: XML data containing AccessList entries
    :type acl_entries: str
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
    :type ip: str
    :param mask: Ipv4/6 wildcard mask
    :type mask: str
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
    :type ip: str
    :param mask: Ipv4/6 wildcard mask
    :type mask: str
    :param amask: Ipv4/6 address mask
    :type amask: str
    :param wmask: Ipv4/6 address wildcard mask
    :type wmask: str
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
    :type seq: str
    :param entry_type: Entry type (permit/deny)
    :type entry_type: str
    :param ps_entries: XML data containing PeerSequence entries
    :type ps_entries: str
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
    :type seq: str
    :param entry_type: Entry type (permit/deny)
    :type entry_type: str
    :param pl_entries: XML data containing PrefixList entries
    :type pl_entries: str
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
    :type prefix: str
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
    :type prefix: str
    :param op: PrefixList option (ge/le/eq)
    :type op: str
    :param mask: Ipv4/6 Mask
    :type mask: str
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
    :type op: str
    :param length: PeerSequence length
    :type length: str
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
    :type groups_json: str
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
    :type connections_json: str
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
    :type connections_json: str
    :param version: Version of SXP protocol (version1/2/3/4)
    :type version: str
    :param mode: Mode of SXP peer (speaker/listener/both)
    :type mode: str
    :param ip: Ipv4/6 address of remote peer
    :type ip: str
    :param port: Port on with remote peer listens
    :type port: str
    :param state: State of connection (on/off/pendingOn/deleteHoldDown)
    :type state: str
    :returns: True if Connection with specified params was found, otherwise False.

    """
    for connection in parse_connections(connections_json):
        if (connection['peer-address'] == ip and connection['tcp-port'] == int(port) and (
                mode.strip() == 'any' or connection['mode'] == mode) and connection['version'] == version):
            if state == 'none':
                return True
            elif connection['state'] == state:
                return True
    return False


def parse_bindings(bindings_json):
    """Parse JSON string into Array of Bindings

    :param bindings_json: JSON containing Bindings
    :type bindings_json: str
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
    :type bindings: str
    :param sgt: Source Group Tag
    :type sgt: str
    :param prefix: Ipv4/6 prefix
    :type prefix: str
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
    :type prefix_groups_json: str
    :param source_: Source of PrefixGroups (sxp/local)
    :type source_: str
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
    :type prefix_groups_json: str
    :param sgt: Source Group Tag
    :type sgt: str
    :param prefix: Ipv4/6 prefix
    :type prefix: str
    :param source_: Source of binding (local/sxp)
    :type source_: str
    :param action: Action for binding (add/delete)
    :type action: str
    :returns: True if Binding with specified params was found, otherwise False.

    """
    found = False
    for prefixgroup in parse_prefix_groups(prefix_groups_json, source_):
        if prefixgroup['sgt'] == int(sgt):
            for binding in prefixgroup['binding']:
                if binding['ip-prefix'] == prefix and binding['action'] == action:
                    found = True
    return found


def add_connection_xml(version, mode, ip, port, node, password_, domain_name, bindings_timeout=0, security_mode=''):
    """Generate xml for Add Connection request

    :param version: Version of SXP protocol (version1/2/3/4)
    :type version: str
    :param mode: Mode of SXP peer (speaker/listener/both)
    :type mode: str
    :param ip: Ipv4/6 address of remote peer
    :type ip: str
    :param port: Port on with remote peer listens
    :type port: str
    :param node: Ipv4 address of node
    :type node: str
    :param password_: Password type (none/default)
    :type password_: str
    :param domain_name: Name of Domain
    :type domain_name: str
    :param security_mode: Default/TSL security
    :type security_mode: str
    :param bindings_timeout: Specifies DHD and Reconciliation timers
    :type bindings_timeout: int
    :returns: String containing xml data for request

    """
    templ = Template('''<input>
   <requested-node xmlns="urn:opendaylight:sxp:controller">$node</requested-node>
   $domain
   <connections xmlns="urn:opendaylight:sxp:controller">
      <connection>
         <peer-address>$ip</peer-address>
         <tcp-port>$port</tcp-port>
         <password>$password_</password>
         <mode>$mode</mode>
         <version>$version</version>
         <description>Connection to ISR-G2</description>
         $security_type
         <connection-timers>
            <hold-time-min-acceptable>45</hold-time-min-acceptable>
            <keep-alive-time>30</keep-alive-time>
            <reconciliation-time>$timeout</reconciliation-time>
            <delete-hold-down-time>$timeout</delete-hold-down-time>
         </connection-timers>
      </connection>
   </connections>
</input>
''')
    data = templ.substitute(
        {'ip': ip, 'port': port, 'mode': mode, 'version': version, 'node': node,
         'password_': password_, 'domain': get_domain_name(domain_name), 'timeout': bindings_timeout,
         'security_type': '<security-type>' + security_mode + '</security-type>' if security_mode else ''})
    return data


def delete_connections_xml(address, port, node, domain_name):
    """Generate xml for Delete Connection request

    :param address: Ipv4/6 address of remote peer
    :type address: str
    :param port: Port on with remote peer listens
    :type port: str
    :param node: Ipv4 address of node
    :type node: str
    :param domain_name: Name of Domain
    :type domain_name: str
    :returns: String containing xml data for request

    """
    templ = Template('''<input>
   <requested-node xmlns="urn:opendaylight:sxp:controller">$node</requested-node>
   $domain
   <peer-address xmlns="urn:opendaylight:sxp:controller">$address</peer-address>
   <tcp-port xmlns="urn:opendaylight:sxp:controller">$port</tcp-port>
</input>''')
    data = templ.substitute({'address': address, 'port': port, 'node': node, 'domain': get_domain_name(domain_name)})
    return data


def update_binding_xml(sgt0, prefix0, sgt1, prefix1, ip, domain_name):
    """Generate xml for Update Binding request

    :param sgt0: Original Source Group Tag
    :type sgt0: str
    :param prefix0: Original Ipv4/6 prefix
    :type prefix0: str
    :param sgt1: New Source Group Tag
    :type sgt1: str
    :param prefix1: New Ipv4/6 prefix
    :type prefix1: str
    :param ip: Ipv4 address of node
    :type ip: str
    :param domain_name: Name of Domain
    :type domain_name: str
    :returns: String containing xml data for request

    """
    templ = Template('''<input>
  <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
  $domain
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
        {'sgt0': sgt0, 'sgt1': sgt1, 'prefix0': prefix0, 'prefix1': prefix1, 'ip': ip,
         'domain': get_domain_name(domain_name)})
    return data


def delete_binding_xml(sgt, prefix, ip, domain_name):
    """Generate xml for Delete Binding request

    :param sgt: Source Group Tag
    :type sgt: str
    :param prefix: Ipv4/6 prefix
    :type prefix: str
    :param ip: Ipv4 address of node
    :type ip: str
    :param domain_name: Name of Domain
    :type domain_name: str
    :returns: String containing xml data for request

    """
    templ = Template('''<input>
  <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
  <sgt xmlns="urn:opendaylight:sxp:controller">$sgt</sgt>
  <ip-prefix xmlns="urn:opendaylight:sxp:controller">$prefix</ip-prefix>
  $domain
</input>''')
    data = templ.substitute({'sgt': sgt, 'prefix': prefix, 'ip': ip, 'domain': get_domain_name(domain_name)})
    return data


def add_peer_group_xml(name, peers, ip):
    """Generate xml for Add PeerGroups request

    :param name: Name of PeerGroup
    :type name: str
    :param peers: XML formatted peers that will be added to group
    :type peers: str
    :param ip: Ipv4 address of node
    :type ip: str
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
    :type name: str
    :param ip: Ipv4 address of node
    :type ip: str
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
    :type ip: str
    :returns: String containing xml data for request

    """
    templ = Template('''<input>
   <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
</input>''')
    data = templ.substitute({'ip': ip})
    return data


def add_filter_xml(group, filter_type, entries, ip, policy=None):
    """Generate xml for Add Filter request

    :param group: Name of group containing filter
    :type group: str
    :param filter_type: Type of filter
    :type filter_type: str
    :param entries: XML formatted entries that will be added in filter
    :type entries: str
    :param ip: Ipv4 address of node
    :type ip: str
    :param policy: Policy of filter update mechanism
    :type policy: str
    :returns: String containing xml data for request

    """
    if policy:
        policy = "<filter-policy>" + policy + "</filter-policy>"
    else:
        policy = ""
    templ = Template('''<input>
  <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
  <peer-group-name xmlns="urn:opendaylight:sxp:controller">$group</peer-group-name>
  <sxp-filter xmlns="urn:opendaylight:sxp:controller">
    $filter_policy
    <filter-type>$filter_type</filter-type>$entries
  </sxp-filter>
</input>''')
    data = templ.substitute(
        {'group': group, 'filter_type': filter_type, 'ip': ip, 'entries': entries, 'filter_policy': policy})
    return data


def add_domain_filter_xml(domain, domains, entries, ip, filter_name=None):
    """Generate xml for Add Domain Filter request

    :param domain: Name of Domain containing filter
    :type domain: str
    :param domains: Domains on which filter will be applied
    :type domains: str
    :param entries: XML formatted entries that will be added in filter
    :type entries: str
    :param ip: Ipv4 address of node
    :type ip: str
    :param filter_name: Name of filter
    :type filter_name: str
    :returns: String containing xml data for request

    """
    if filter_name:
        filter_name = "<filter-name>" + filter_name + "</filter-name>"
    templ = Template('''<input>
  <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
  <domain-name xmlns="urn:opendaylight:sxp:controller">$domain</domain-name>
  <sxp-domain-filter xmlns="urn:opendaylight:sxp:controller">
    $filter_name
    <domains>$domains</domains>
    $entries
  </sxp-domain-filter>
</input>''')
    data = templ.substitute(
        {'domain': domain, 'domains': domains, 'ip': ip, 'entries': entries, 'filter_name': filter_name})
    return data


def delete_filter_xml(group, filter_type, ip):
    """Generate xml for Delete Filter request

    :param group: Name of group containing filter
    :type group: str
    :param filter_type: Type of filter
    :type filter_type: str
    :param ip: Ipv4 address of node
    :type ip: str
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


def delete_domain_filter_xml(domain, ip, filter_name=None):
    """Generate xml for Delete Filter request

    :param domain: Name of Domain containing filter
    :type domain: str
    :param ip: Ipv4 address of node
    :type ip: str
    :param filter_name: Name of filter
    :type filter_name: str
    :returns: String containing xml data for request

    """
    if filter_name:
        filter_name = '<filter-name xmlns="urn:opendaylight:sxp:controller">' + filter_name + "</filter-name>"
    templ = Template('''<input>
  <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
  <domain-name xmlns="urn:opendaylight:sxp:controller">$domain</domain-name>
  $filter_name
</input>''')
    data = templ.substitute(
        {'domain': domain, 'ip': ip, 'filter_name': filter_name})
    return data


def get_connections_from_node_xml(ip, domain_name):
    """Generate xml for Get Connections request

    :param ip: Ipv4 address of node
    :type ip: str
    :param domain_name: Name of Domain
    :type domain_name: str
    :returns: String containing xml data for request

    """
    templ = Template('''<input>
   <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
   $domain
</input>''')
    data = templ.substitute({'ip': ip, 'domain': get_domain_name(domain_name)})
    return data


def get_bindings_from_node_xml(ip, binding_range, domain_name):
    """Generate xml for Get Bindings request

    :param binding_range: All or only Local bindings
    :type binding_range: str
    :param ip: Ipv4 address of node
    :type ip: str
    :param domain_name: Name of Domain
    :type domain_name: str
    :returns: String containing xml data for request

    """
    templ = Template('''<input>
  <requested-node xmlns="urn:opendaylight:sxp:controller">$ip</requested-node>
  <bindings-range xmlns="urn:opendaylight:sxp:controller">$range</bindings-range>
  $domain
</input>''')
    data = templ.substitute({'ip': ip, 'range': binding_range, 'domain': get_domain_name(domain_name)})
    return data


def add_node_xml(node_id, port, password, version, node_ip=None, expansion=0, bindings_timeout=0, keystores=None,
                 retry_open_timer=1):
    """Generate xml for Add Node request

    :param node_id: Ipv4 address formatted node id
    :type node_id: str
    :param node_ip: Ipv4 address of node
    :type node_ip: strl
    :param port: Node port number
    :type port: int
    :param password: TCP-MD5 password
    :type password: str
    :param version: Sxp device version
    :type version: str
    :param expansion: Bindings expansion
    :type expansion: int
    :param bindings_timeout: Specifies DHD and Reconciliation timers
    :type bindings_timeout: int
    :param keystores: SSL keystore and truststore specification
    :type keystores: dict
    :returns: String containing xml data for request

    """
    tls = ''
    if keystores:
        tls = Template('''
        <tls>
            <keystore>
              <location>$keystore</location>
              <type>JKS</type>
              <path-type>PATH</path-type>
              <password>$passwd</password>
            </keystore>
            <truststore>
              <location>$truststore</location>
              <type>JKS</type>
              <path-type>PATH</path-type>
              <password>$passwd</password>
            </truststore>
            <certificate-password>$passwd</certificate-password>
        </tls>
    ''').substitute(
            {'keystore': keystores['keystore'], 'truststore': keystores['truststore'], 'passwd': keystores['password']})

    templ = Template('''<input xmlns="urn:opendaylight:sxp:controller">
    <node-id>$id</node-id>
    <timers>
        <retry-open-time>$retry_open_timer</retry-open-time>
        <hold-time-min-acceptable>120</hold-time-min-acceptable>
        <delete-hold-down-time>$timeout</delete-hold-down-time>
        <hold-time-min>90</hold-time-min>
        <reconciliation-time>$timeout</reconciliation-time>
        <hold-time>90</hold-time>
        <hold-time-max>180</hold-time-max>
        <keep-alive-time>30</keep-alive-time>
    </timers>
    <mapping-expanded>$expansion</mapping-expanded>
    <security>
        $tls
        <password>$password</password>
    </security>
    <tcp-port>$port</tcp-port>
    <version>$version</version>
    <description>ODL SXP Controller</description>
    <source-ip>$ip</source-ip>
</input>''')
    data = templ.substitute(
        {'ip': node_ip or node_id, 'id': node_id, 'port': port, 'password': password,
         'version': version, 'expansion': expansion, 'timeout': bindings_timeout, 'tls': tls,
         'retry_open_timer': retry_open_timer})
    return data


def delete_node_xml(node_id):
    """Generate xml for Delete node request

    :param node_id: Ipv4 address formatted node id
    :type node_id: str
    :returns: String containing xml data for request

    """
    templ = Template('''<input xmlns="urn:opendaylight:sxp:controller">
  <node-id>$id</node-id>
</input>''')
    data = templ.substitute({'id': node_id})
    return data


def add_domain_xml(node_id, name):
    """Generate xml for Add Domain request

    :param node_id: Id of node
    :type node_id: str
    :param name: Name of Domain
    :type name: str
    :returns: String containing xml data for request

    """
    templ = Template('''<input>
  <node-id xmlns="urn:opendaylight:sxp:controller">$id</node-id>
  <domain-name xmlns="urn:opendaylight:sxp:controller">$name</domain-name>
</input>''')
    data = templ.substitute({'name': name, 'id': node_id})
    return data


def delete_domain_xml(node_id, name):
    """Generate xml for Remove Domain request

    :param node_id: Id of node
    :type node_id: str
    :param name: Name of Domain
    :type name: str
    :returns: String containing xml data for request

    """
    return add_domain_xml(node_id, name)


def get_domain_name(domain_name):
    """Generate xml for Get Bindings request

    :param domain_name: Name of Domain
    :type domain_name: str
    :returns: String containing xml data for request

    """
    if domain_name == 'global':
        return ''
    else:
        return '<domain-name xmlns="urn:opendaylight:sxp:controller">' + domain_name + '</domain-name>'


def add_bindings_xml(node_id, domain, sgt, prefixes):
    """Generate xml for Add Bindings request

    :param node_id: Id of node
    :type node_id: str
    :param domain: Name of Domain
    :type domain: str
    :param sgt: Security group
    :type sgt: int
    :param prefixes: List of ip-prefixes
    :type prefixes: str
    :returns: String containing xml data for request

    """
    bindings = ''
    for prefix in prefixes.split(','):
        bindings += '\n' + '<ip-prefix>' + prefix + '</ip-prefix>'
    templ = Template('''<input>
  <node-id xmlns="urn:opendaylight:sxp:controller">$id</node-id>
  <domain-name xmlns="urn:opendaylight:sxp:controller">$name</domain-name>
  <binding xmlns="urn:opendaylight:sxp:controller">
      <sgt>$sgt</sgt>
      $bindings
  </binding>
</input>''')
    data = templ.substitute({'name': domain, 'id': node_id, 'sgt': sgt, 'bindings': bindings})
    return data


def delete_bindings_xml(node_id, domain, sgt, prefixes):
    """Generate xml for Remove Bindings request

    :param node_id: Id of node
    :type node_id: str
    :param domain: Name of Domain
    :type domain: str
    :param sgt: Security group
    :type sgt: int
    :param prefixes: List of ip-prefixes
    :type prefixes: str
    :returns: String containing xml data for request

    """
    return add_bindings_xml(node_id, domain, sgt, prefixes)


def prefix_range(start, end):
    """Generate and concatenate ip-prefixes

    :param start: Start index
    :type start: str
    :param end: End index
    :type end: str
    :returns: String containing concatenated ip-prefixes

    """
    start = int(start)
    end = int(end)
    index = 0
    prefixes = ''
    while index < end:
        prefixes += get_ip_from_number(index + start) + '/32'
        index += 1
        if index < end:
            prefixes += ','
    return prefixes


def route_definition_xml(virtual_ip, net_mask, interface):
    """Generate xml for Add Bindings request

    :param interface: Network interface name
    :type interface: str
    :param net_mask: NetMask of virtual ip
    :type net_mask: str
    :param virtual_ip: Virtual ip
    :type virtual_ip: str
    :returns: String containing xml data for request

    """
    templ = Template('''
    <routing-definition>
        <ip-address>$vip</ip-address>
        <interface>$interface</interface>
        <netmask>$mask</netmask>
    </routing-definition>
    ''')
    data = templ.substitute({'mask': net_mask, 'vip': virtual_ip, 'interface': interface})
    return data


def route_definitions_xml(routes, old_routes=None):
    """Generate xml for Add Bindings request

    :param routes: XML formatted data containing RouteDefinitions
    :type routes: str
    :param old_routes: Routes add to request that needs to persist
    :type old_routes: str
    :returns: String containing xml data for request

    """
    if old_routes and "</sxp-cluster-route>" in old_routes:
        templ = Template(old_routes.replace("</sxp-cluster-route>", "$routes</sxp-cluster-route>"))
    else:
        templ = Template('''<sxp-cluster-route xmlns="urn:opendaylight:sxp:cluster:route">
    $routes
</sxp-cluster-route>
    ''')
    data = templ.substitute({'routes': routes})
    return data

import collections
import errno
import logging
import os
import re

# Make sure to have unique matches in different lines
# Order the list in alphabetical order based on the "issue" key
_whitelist = [
    {
        "issue": "https://jira.opendaylight.org/browse/NETVIRT-XXXX",
        "id": "EncapsulatedValueCodec",
        "context": [
            "org.opendaylight.mdsal.binding.dom.codec.impl.EncapsulatedValueCodec@",
            + "org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv4Prefix",
        ],
    },
    {
        "issue": "https://jira.opendaylight.org/browse/NETVIRT-972",
        "id": "ConflictingModificationAppliedException",
        "context": [
            "Node was created by other transaction",
            "Optimistic lock failed for path /(urn:opendaylight:inventory?revision=2013-08-19)nodes/node/node"
            + "[{(urn:opendaylight:inventory?revision=2013-08-19)id=openflow",
            "table/table[{(urn:opendaylight:flow:inventory?revision=2013-08-19)id=21}]/flow/flow"
            + "[{(urn:opendaylight:flow:inventory?revision=2013-08-19)id=L3.",
        ],
    },
    # oxygen
    {
        "issue": "https://jira.opendaylight.org/browse/NETVIRT-972",
        "id": "ConflictingModificationAppliedException",
        "context": [
            "Node was created by other transaction",
            "OptimisticLockFailedException: Optimistic lock failed."
            "Conflicting modification for path /(urn:opendaylight:inventory?revision=2013-08-19)nodes/node/node"
            + "[{(urn:opendaylight:inventory?revision=2013-08-19)id=",
            "table/table[{(urn:opendaylight:flow:inventory?revision=2013-08-19)id=21}]/flow/flow"
            + "[{(urn:opendaylight:flow:inventory?revision=2013-08-19)id=L3.",
            ".21.",
            ".42.",
        ],
    },
    {
        "issue": "https://jira.opendaylight.org/browse/NETVIRT-1135",
        "id": "ConflictingModificationAppliedException",
        "context": [
            "Node was created by other transaction",
            "Optimistic lock failed for path /(urn:opendaylight:inventory?revision=2013-08-19)nodes/node/node"
            + "[{(urn:opendaylight:inventory?revision=2013-08-19)id=openflow:",
        ],
    },
    # oxygen
    {
        "issue": "https://jira.opendaylight.org/browse/NETVIRT-1135",
        "id": "ConflictingModificationAppliedException",
        "context": [
            "OptimisticLockFailedException: Optimistic lock failed."
            "Conflicting modification for path /(urn:opendaylight:inventory?revision=2013-08-19)nodes/node/node"
            + "[{(urn:opendaylight:inventory?revision=2013-08-19)id=openflow:",
            "table/table[{(urn:opendaylight:flow:inventory?revision=2013-08-19)id=47}]/flow/flow"
            + "[{(urn:opendaylight:flow:inventory?revision=2013-08-19)id=SNAT.",
            ".47.",
        ],
    },
    {
        "issue": "https://jira.opendaylight.org/browse/NETVIRT-1136",
        "id": "ConflictingModificationAppliedException",
        "context": [
            "Node was deleted by other transaction",
            "Optimistic lock failed for path /(urn:opendaylight:netvirt:elan?revision=2015-06-02)elan-"
            + "forwarding-tables/mac-table/mac-table[{(urn:opendaylight:netvirt:elan?revision=2015-06-02)"
            + "elan-instance-name=",
        ],
    },
    # oxygen version of NETVIRT-1136
    {
        "issue": "https://jira.opendaylight.org/browse/NETVIRT-1136",
        "id": "ConflictingModificationAppliedException",
        "context": [
            "Node was deleted by other transaction",
            "OptimisticLockFailedException: Optimistic lock failed.",
            "Conflicting modification for path /(urn:opendaylight:netvirt:elan?revision=2015-06-02)elan-"
            + "forwarding-tables/mac-table/mac-table[{(urn:opendaylight:netvirt:elan?revision=2015-06-02)"
            + "elan-instance-name=",
        ],
    },
    {
        "issue": "https://jira.opendaylight.org/browse/NETVIRT-1260",
        "id": "ConflictingModificationAppliedException",
        "context": [
            "Optimistic lock failed for path /(urn:ietf:params:xml:ns:yang:ietf-interfaces?revision=2014-05-08)"
            + "interfaces/interface/interface[{(urn:ietf:params:xml:ns:yang:ietf-interfaces?revision=2014-05-08)name="
        ],
    },
    {
        "issue": "https://jira.opendaylight.org/browse/NETVIRT-1270",
        "id": "ConflictingModificationAppliedException",
        "context": [
            "OptimisticLockFailedException",
            "/(urn:opendaylight:netvirt:l3vpn?revision=2013-09-11)"
            + "vpn-instance-op-data/vpn-instance-op-data-entry/vpn-instance-op-data-entry"
            + "[{(urn:opendaylight:netvirt:l3vpn?revision=2013-09-11)vrf-id=",
            "vrf-id=",
            "/vpn-to-dpn-list/vpn-to-dpn-list",
            "dpnId=",
        ],
    },
    {
        "issue": "https://jira.opendaylight.org/browse/NETVIRT-1270",
        "id": "ExecutionException",
        "context": [
            "OptimisticLockFailedException: Optimistic lock failed",
            "removeOrUpdateVpnToDpnList: Error removing from dpnToVpnList for vpn ",
        ],
    },
    {
        "issue": "https://jira.opendaylight.org/browse/NETVIRT-1270",
        "id": "OptimisticLockFailedException",
        "context": [
            "OptimisticLockFailedException",
            "VpnInterfaceOpListener",
            "Direct Exception (not failed Future) when executing job, won't even retry: JobEntry{key='VPNINTERFACE-",
            "vpn-instance-op-data/vpn-instance-op-data-entry/vpn-instance-op-data-entry"
            + "[{(urn:opendaylight:netvirt:l3vpn?revision=2013-09-11)vrf-id=",
            "vrf-id=",
            "/vpn-to-dpn-list/vpn-to-dpn-list",
            "dpnId=",
        ],
    },
    {
        "issue": "https://jira.opendaylight.org/browse/NETVIRT-1281",
        "id": "OptimisticLockFailedException",
        "context": [
            "OptimisticLockFailedException: Optimistic lock failed.",
            "ConflictingModificationAppliedException: Node children was modified by other transaction",
            "Direct Exception (not failed Future) when executing job, won't even retry: JobEntry{key='VPNINTERFACE-",
        ],
    },
    {
        "issue": "https://jira.opendaylight.org/browse/NETVIRT-1304",
        "id": "ModifiedNodeDoesNotExistException",
        "context": [
            "ModifiedNodeDoesNotExistException",
            "/(urn:opendaylight:netvirt:fibmanager?revision=2015-03-30)fibEntries/"
            + "vrfTables/vrfTables[{(urn:opendaylight:netvirt:fibmanager?revision=2015-03-30)routeDistinguisher=",
        ],
    },
    {
        "issue": "https://jira.opendaylight.org/browse/NETVIRT-1304",
        "id": "TransactionCommitFailedException",
        "context": [
            "TransactionCommitFailedException",
            "/(urn:opendaylight:netvirt:fibmanager?revision=2015-03-30)fibEntries/"
            + "vrfTables/vrfTables[{(urn:opendaylight:netvirt:fibmanager?revision=2015-03-30)routeDistinguisher=",
        ],
    },
    {
        "issue": "https://jira.opendaylight.org/browse/NETVIRT-1427",
        "id": "ModifiedNodeDoesNotExistException",
        "context": [
            "/(urn:huawei:params:xml:ns:yang:l3vpn?revision=2014-08-15)vpn-interfaces/vpn-interface/vpn-interface"
            + "[{(urn:huawei:params:xml:ns:yang:l3vpn?revision=2014-08-15)name=",
            "AugmentationIdentifier{childNames=[(urn:opendaylight:netvirt:l3vpn?revision=2013-09-11)adjacency]}",
        ],
    },
    {
        "issue": "https://jira.opendaylight.org/browse/NETVIRT-1428",
        "id": "ModifiedNodeDoesNotExistException",
        "context": [
            "/(urn:huawei:params:xml:ns:yang:l3vpn?revision=2014-08-15)vpn-interfaces/vpn-interface/vpn-interface"
            + "[{(urn:huawei:params:xml:ns:yang:l3vpn?revision=2014-08-15)name="
        ],
    },
    {
        "issue": "https://jira.opendaylight.org/browse/NEUTRON-157",
        "id": "ConflictingModificationAppliedException",
        "context": [
            "Optimistic lock failed for path /(urn:opendaylight:neutron?revision=2015-07-12)"
            + "neutron/networks/network/network[{(urn:opendaylight:neutron?revision=2015-07-12)uuid=",
            "Conflicting modification for path /(urn:opendaylight:neutron?revision=2015-07-12)"
            + "neutron/networks/network/network[{(urn:opendaylight:neutron?revision=2015-07-12)uuid=",
        ],
    },
    {
        "issue": "https://jira.opendaylight.org/browse/NEUTRON-157",
        "id": "OptimisticLockFailedException",
        "context": [
            "Got OptimisticLockFailedException",
            "AbstractTranscriberInterface",
        ],
    },
    {
        "issue": "https://jira.opendaylight.org/browse/NEUTRON-157",
        "id": "ConflictingModificationAppliedException",
        "context": [
            "Optimistic lock failed for path /(urn:opendaylight:neutron?revision=2015-07-12)neutron"
        ],
    },
    # oxygen
    {
        "issue": "https://jira.opendaylight.org/browse/NEUTRON-157",
        "id": "ConflictingModificationAppliedException",
        "context": [
            "OptimisticLockFailedException: Optimistic lock failed.",
            "Conflicting modification for path /(urn:opendaylight:neutron?revision=2015-07-12)"
            + "neutron/networks/network/network[{(urn:opendaylight:neutron?revision=2015-07-12)uuid=",
        ],
    },
    {
        "issue": "https://jira.opendaylight.org/browse/OPNFLWPLUG-917",
        "id": "IllegalStateException",
        "context": [
            "java.lang.IllegalStateException: Deserializer for key: msgVersion: 4 objectClass: "
            + "org.opendaylight.yang.gen.v1.urn.opendaylight.openflow.oxm.rev150225.match.entries.grouping.MatchEntry "
            + "msgType: 1 oxm_field: 33 experimenterID: null was not found "
            + "- please verify that all needed deserializers ale loaded correctly"
        ],
    },
    {
        "issue": "https://jira.opendaylight.org/browse/NETVIRT-1640",
        "id": "ElasticsearchAppender",
        "context": [
            "Can't append into Elasticsearch",
            "org.apache.karaf.decanter.appender.elasticsearch - 1.0.0",
        ],
    },
]

_re_ts = re.compile(r"^[0-9]{4}(-[0-9]{2}){2}T([0-9]{2}:){2}[0-9]{2},[0-9]{3}")
_re_ts_we = re.compile(
    r"^[0-9]{4}(-[0-9]{2}){2}T([0-9]{2}:){2}[0-9]{2},[0-9]{3}( \| ERROR \| | \| WARN  \| )"
)
_re_ex = re.compile(r"(?i)exception")
_ex_map = collections.OrderedDict()
_ts_list = []
_fail = []


def get_exceptions(lines):
    """
    Create a map of exceptions that also has a list of warnings and errors preceeding
    the exception to use as context.

    The lines are parsed to create a list where all lines related to a timestamp
    are aggregated. Timestamped lines with exception (case insensitive) are copied
    to the exception map keyed to the index of the timestamp line. Each exception value
    also has a list containing WARN and ERROR lines proceeding the exception.

    :param list lines:
    :return OrderedDict _ex_map: map of exceptions
    """
    global _ex_map
    _ex_map = collections.OrderedDict()
    global _ts_list
    _ts_list = []
    cur_list = []
    warnerr_deq = collections.deque(maxlen=5)

    for line in lines:
        ts = _re_ts.search(line)

        # Check if this is the start or continuation of a timestamp line
        if ts:
            cur_list = [line]
            _ts_list.append(cur_list)
            ts_we = _re_ts_we.search(line)
            # Track WARN and ERROR lines
            if ts_we:
                warn_err_index = len(_ts_list) - 1
                warnerr_deq.append(warn_err_index)
        # Append to current timestamp line since this is not a timestamp line
        else:
            cur_list.append(line)

        # Add the timestamp line to the exception map if it has an exception
        ex = _re_ex.search(line)
        if ex:
            index = len(_ts_list) - 1
            if index not in _ex_map:
                _ex_map[index] = {"warnerr_list": list(warnerr_deq), "lines": cur_list}
                warnerr_deq.clear()  # reset the deque to only track new ERROR and WARN lines

    return _ex_map


def check_exceptions():
    """
    Return a list of exceptions that were not in the whitelist.

    Each exception found is compared against all the patterns
    in the whitelist.

    :return list _fail: list of exceptions not in the whitelist
    """
    global _fail
    _fail = []
    _match = []
    for ex_idx, ex in _ex_map.items():
        ex_str = "__".join(ex.get("lines"))
        for whitelist in _whitelist:
            # skip the current whitelist exception if not in the current exception
            if whitelist.get("id") not in ex_str:
                continue
            whitelist_contexts = whitelist.get("context")
            num_context_matches = 0
            for whitelist_context in whitelist_contexts:
                for exwe_index in reversed(ex.get("warnerr_list")):
                    exwe_str = "__".join(_ts_list[exwe_index])
                    if whitelist_context in exwe_str:
                        num_context_matches += 1
            # Mark this exception as a known issue if all the context's matched
            if num_context_matches >= len(whitelist_contexts):
                ex["issue"] = whitelist.get("issue")
                _match.append(ex)
                logging.info("known exception was seen: {}".format(ex["issue"]))
                break
        # A new exception when it isn't marked with a known issue.
        if "issue" not in ex:
            _fail.append(ex)
    return _fail, _match


def verify_exceptions(lines):
    """
    Return a list of exceptions not in the whitelist for the given lines.

    :param list lines: list of lines from a log
    :return list, list: one list of exceptions not in the whitelist, and a second with matching issues
    """
    if not lines:
        return
    get_exceptions(lines)
    return check_exceptions()


def write_exceptions_map_to_file(testname, filename, mode="a+"):
    """
    Write the exceptions map to a file under the testname header. The output
    will include all lines in the exception itself as well as any previous
    contextual warning or error lines. The output will be appended or overwritten
    depending on the mode parameter. It is assumed that the caller has called
    verify_exceptions() earlier to populate the exceptions map, otherwise only
    the testname and header will be printed to the file.

    :param str testname: The name of the test
    :param str filename: The file to open for writing
    :param str mode: Append (a+) or overwrite (w+)
    """
    try:
        os.makedirs(os.path.dirname(filename))
    except OSError as exception:
        if exception.errno != errno.EEXIST:
            raise

    with open(filename, mode) as fp:
        fp.write("{}\n".format("=" * 60))
        fp.write("Starting test: {}\n".format(testname))
        for ex_idx, ex in _ex_map.items():
            fp.write("{}\n".format("-" * 40))
            if "issue" in ex:
                fp.write("Exception was matched to: {}\n".format(ex.get("issue")))
            else:
                fp.write("Exception is new\n")
            for exwe_index in ex.get("warnerr_list")[:-1]:
                for line in _ts_list[exwe_index]:
                    fp.write("{}\n".format(line))
            fp.writelines(ex.get("lines"))
            fp.write("\n")

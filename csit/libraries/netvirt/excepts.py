import collections
import logging
import re

# Make sure to have unique matches in different lines
# Order the list in alphabetical order based on the "issue" key
_whitelist = [
    {"issue": "https://jira.opendaylight.org/browse/OPNFLWPLUG-917",
     "id": "IllegalStateException",
     "context": [
         "java.lang.IllegalStateException: Deserializer for key: msgVersion: 4 objectClass: " +
         "org.opendaylight.yang.gen.v1.urn.opendaylight.openflow.oxm.rev150225.match.entries.grouping.MatchEntry " +
         "msgType: 1 oxm_field: 33 experimenterID: null was not found " +
         "- please verify that all needed deserializers ale loaded correctly"
     ]},
    {"issue": "https://jira.opendaylight.org/browse/NETVIRT-792",
     "id": "ConflictingModificationAppliedException",
     "context": [
         "Node was created by other transaction",
         "Optimistic lock failed for path /(urn:opendaylight:inventory?revision=2013-08-19)nodes/node/node" +
         "[{(urn:opendaylight:inventory?revision=2013-08-19)id=openflow",
         "table/table[{(urn:opendaylight:flow:inventory?revision=2013-08-19)id=21}]/flow/flow" +
         "[{(urn:opendaylight:flow:inventory?revision=2013-08-19)id=L3."
         "Conflicting modification for path /(urn:opendaylight:inventory?revision=2013-08-19)nodes/node/node" +
         "[{(urn:opendaylight:inventory?revision=2013-08-19)id=",
         "table/table[{(urn:opendaylight:flow:inventory?revision=2013-08-19)id=21}]/flow/flow" +
         "[{(urn:opendaylight:flow:inventory?revision=2013-08-19)id=L3."
     ]},
    {"issue": "https://jira.opendaylight.org/browse/NETVIRT-1136",
     "id": "ConflictingModificationAppliedException",
     "context": [
         "Node was deleted by other transaction",
         "Optimistic lock failed for path /(urn:opendaylight:netvirt:elan?revision=2015-06-02)elan-" +
         "forwarding-tables/mac-table/mac-table[{(urn:opendaylight:netvirt:elan?revision=2015-06-02)" +
         "elan-instance-name=",
         "Conflicting modification for path /(urn:opendaylight:netvirt:elan?revision=2015-06-02)elan-" +
         "forwarding-tables/mac-table/mac-table[{(urn:opendaylight:netvirt:elan?revision=2015-06-02)" +
         "elan-instance-name="
     ]},
    # oxygen version of NETVIRT-1136
    {"issue": "https://jira.opendaylight.org/browse/NETVIRT-1136",
     "id": "ConflictingModificationAppliedException",
     "context": [
         "Node was deleted by other transaction",
         "Conflicting modification for path /(urn:opendaylight:netvirt:elan?revision=2015-06-02)elan-" +
         "forwarding-tables/mac-table/mac-table[{(urn:opendaylight:netvirt:elan?revision=2015-06-02)" +
         "elan-instance-name="
     ]},
    {"issue": "https://jira.opendaylight.org/browse/NEUTRON-157",
     "id": "ConflictingModificationAppliedException",
     "context": [
         "Node was deleted by other transaction",
         "Optimistic lock failed for path /(urn:opendaylight:neutron?revision=2015-07-12)" +
         "neutron/networks/network/network[{(urn:opendaylight:neutron?revision=2015-07-12)uuid=",
         "Got OptimisticLockFailedException"
     ]}
]

_re_ts = re.compile(r"^[0-9]{4}(-[0-9]{2}){2}T([0-9]{2}:){2}[0-9]{2},[0-9]{3}")
_re_ts_we = re.compile(r"^[0-9]{4}(-[0-9]{2}){2}T([0-9]{2}:){2}[0-9]{2},[0-9]{3}( \| ERROR \| | \| WARN  \| )")
_re_ex = re.compile(r"(?i)exception")
_ex_map = collections.OrderedDict()
_ts_list = []
_fail = []


def get_exceptions(lines):
    """
    Create a map of exceptions that also has a list of warnings and errors preceding
    the exception to use as context.

    The lines are parsed to create a list where all lines related to a timestamp
    are aggregated. Timestamped lines with exception (case insensitive) are copied
    to the exception map keyed to the index of the timestamp line. Each exception value
    also has a 3 element list containing the last three WARN and ERROR lines.

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
                we_index = len(_ts_list) - 1
                warnerr_deq.append(we_index)
        # Append to current timestamp line since this is not a timestamp line
        else:
            cur_list.append(line)

        # Add the timestamp line to the exception map if it has an exception
        ex = _re_ex.search(line)
        if ex:
            index = len(_ts_list) - 1
            if index not in _ex_map:
                _ex_map[index] = {"warnerr_list": list(warnerr_deq), 'lines': cur_list}
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
                        break
            # Mark this exception as a known issue if all the context's matched
            if num_context_matches == len(whitelist_contexts):
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

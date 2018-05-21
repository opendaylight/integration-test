import collections
import re

# Make sure to have unique matches in different lines
_whitelist = [
    {"id": "ConflictingModificationAppliedException",
     "context": ["Node children was modified by other transaction", "ietf-interfaces"],
     "issue": "NETVIRT-0001"},
    {"id": "ConflictingModificationAppliedException",
     "context": ["Node children was modified by other transaction", "Job still failed on final retry"],
     "issue": "NETVIRT-0002"},
    {"id": "ConflictingModificationAppliedException",
     "context": [
         "Node was deleted by other transaction",
         "Conflicting modification for path /(urn:opendaylight:netvirt:elan?revision=2015-06-02)elan-" +
         "forwarding-tables/mac-table/mac-table[{(urn:opendaylight:netvirt:elan?revision=2015-06-02)" +
         "elan-instance-name="
     ],
     "issue": "NETVIRT-0003"}
]

_re_ts = re.compile(r"^[0-9]{4}(-[0-9]{2}){2}T([0-9]{2}:){2}[0-9]{2},[0-9]{3}")
_re_ts_we = re.compile(r"^[0-9]{4}(-[0-9]{2}){2}T([0-9]{2}:){2}[0-9]{2},[0-9]{3}( \| ERROR \| | \| WARN  \| )")
_re_ex = re.compile(r"(?i)exception")
_ex_map = collections.OrderedDict()
_ts_list = []
_fail = []


def get_exceptions(lines):
    """
    Create a map of exceptions

    The lines are parsed to create a list where all lines related to a timestamp
    are aggregated. Timestamped lines with exception (case insensitive) are copied
    to the exception map keyed to the index of the timestamp line. Each exception value
    also has a 3 element list containing the last three WARN and ERROR lines.

    :param list lines:
    :return OrderedDict _ex_map: map of exceptions
    """
    global _ts_list
    cur_list = []
    we_q = collections.deque(maxlen=3)
    _ts_list = []

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
                we_q.append(we_index)
        # Append to current timestamp line since this is not a timestamp line
        else:
            cur_list.append(line)

        # Add the timestamp line to the exception map if it has an exception
        ex = _re_ex.search(line)
        if ex:
            index = len(_ts_list) - 1
            if index not in _ex_map:
                _ex_map[index] = {'we': list(we_q), 'lines': cur_list}
                we_q.clear()  # reset the deque to only track new ERROR and WARN lines

    return _ex_map


def check_exceptions():
    global _fail
    _fail = []
    for ex_idx, ex in _ex_map.items():
        ex_str = "__".join(ex.get("lines"))
        for whitelist in _whitelist:
            if whitelist.get("id") not in ex_str:
                continue
            whitelist_contexts = whitelist.get("context")
            num_context_matches = 0
            for whitelist_context in whitelist_contexts:
                for exwe_index in reversed(ex.get("we")):
                    exwe_str = "__".join(_ts_list[exwe_index])
                    if whitelist_context in exwe_str:
                        num_context_matches += 1
                        break
            if num_context_matches == len(whitelist_contexts):
                ex["issue"] = whitelist.get("issue")
                break
        if "issue" not in ex:
            _fail.append(ex)
    return _fail


def verify_exceptions(lines):
    get_exceptions(lines)
    return check_exceptions()

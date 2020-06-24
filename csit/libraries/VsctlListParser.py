"""
Library for the robot based system test tool of the OpenDaylight project.

This library will parse 'ovs-vstcl list Bridge' and 'ovs-vstcl list Controller'
commands and create dictionaries with parsed details which will be used
for another pruposes.

Authors: pgubka@cisco.com
Created: 2016-04-04
"""

import re
import copy
import traceback


def _parse_stdout(stdout):
    """ Transforms stdout to dict """
    text = stdout.replace(" ", "")
    text = text.replace("\r", "")
    pat = re.compile(r'(?P<key>\w+):(?P<value>.+)')
    regroups = re.finditer(pat, text)
    outdict = {}
    for g in regroups:
        print((g.group()))
        if g.group('key') == '_uuid':
            cntl_uuid = g.group('value')
            outdict[cntl_uuid] = {}
        outdict[cntl_uuid][g.group('key')] = g.group('value')
    return outdict


def _postprocess_data(bridges, controllers):
    """What is done here:
    - merge bridges and controllers
    - replace controller 'key' (ip instead uuid)
    - transformed controller's connected status to bool
    """
    brs = copy.deepcopy(bridges)
    cntls = copy.deepcopy(controllers)

    # replacing string value of is_connected key with boolean
    for key, cntl in cntls.items():
        if cntl['is_connected'] == 'false':
            cntl['is_connected'] = False
        elif cntl['is_connected'] == 'true':
            cntl['is_connected'] = True
        else:
            cntl['is_connected'] = None

    # replacing keys with the same values
    for key, value in bridges.items():
        brs[value['name'][1:-1]] = brs[key]
        del brs[key]

    for key, value in brs.items():
        # replace string with references with dict of controllers
        ctl_refs = value['controller'][1:-1].split(',')
        value['controller'] = {}
        for ctl_ref in ctl_refs:
            if ctl_ref is not '':
                value['controller'][ctl_ref] = cntls[ctl_ref]

    for brkey, bridge in brs.items():
        new_cntls = {}
        for cnkey, cntl in bridge['controller'].items():
            # port 6654 is set by OvsMAnager.robot to disconnect from controller
            if '6653' in cntl['target'] or '6633' in cntl['target'] or '6654' in cntl['target']:
                new_key = cntl['target'].split(":")[1]     # getting middle from "tcp:ip:6653"
            else:
                new_key = cntl['target'][1:-1]  # getting string without quotes "ptcp:6638"
            new_cntls[new_key] = cntl
        bridge['controller'] = new_cntls

    return brs


def parse(bridge_stdout, cntl_stdout):
    """Produces dictionary with data for future usege

    Args:
        :param bridge_stdout: output of 'ovs-vsclt list Bridge' command

        :param cntl_stdout: output of 'ovs-vsclt list Controller' command

    Returns:
        :returns processed: processed output dictionary

        :returns bridges: list bridge command output transformed to dist

        :returns controllers: list controller command output transformed to dist
    """

    try:
        bridges = _parse_stdout(bridge_stdout)
        controllers = _parse_stdout(cntl_stdout)
        processed = _postprocess_data(bridges, controllers)
    except Exception:
        traceback.print_exc()
        raise
    return processed, bridges, controllers

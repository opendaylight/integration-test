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


def _parse_stdout(stdout):
    text = stdout.replace(" ","")
    pat = re.compile(r'(?P<key>\w+):(?P<value>.+)')
    regroups = re.finditer(pat, text)
    controllers = {}
    for g in regroups:
        if g.group('key') == '_uuid':
            cntl_uuid = g.group('value')
            controllers[cntl_uuid] = {}
        controllers[cntl_uuid][g.group('key')] = g.group('value')
    return controllers

def _postprocess_data(bridges, controllers):
    """What is done here:
    - merge bridges and controllers
    - replace controller 'key' (ip instead uuid)
    - removing ptcp controllers
    """
    brs = copy.deepcopy(bridges)
    cntls = copy.deepcopy(controllers)

    # replacing keys witht the same values
    for key,cntl in cntls.iteritems():
        if cntl['is_connected'] == 'false':
            cntl['is_connected'] = False
        elif cntl['is_connected'] == 'true':
            cntl['is_connected'] = True
        else:
            raise Exception('Unable to convert to boolean: {}',format(cntl['is_connected']))

    # replacing keys witht the same values
    for key,value in bridges.iteritems():
        brs[value['name'][1:-1]] = brs[key]
        del brs[key]

    for key,value in brs.iteritems():
        # replace string with references with dict of controllers
        ctl_refs = value['controller'][1:-1].split(',')
        value['controller'] = {}
        for ctl_ref in ctl_refs:
            if ctl_ref is not '':
                value['controller'][ctl_ref] = cntls[ctl_ref]

    # 
    for brkey,bridge in brs.iteritems():
        new_cntls = {}
        for cnkey,cntl in bridge['controller'].iteritems():
            if '6653' in cntl['target'] or '6633' in cntl['target']:
                new_key = cntl['target'].split(":")[1] # getting middle from "tcp:ip:6653"
            else:
                new_key = cntl['target'][1:-1]  # getting string without quotes "ptcp:6638"
            new_cntls[new_key] = cntl
        bridge['controller'] = new_cntls

    return brs
     


def parse(bridge_stdout, cntl_stdout):
    bridges = _parse_stdout(bridge_stdout)
    controllers = _parse_stdout(cntl_stdout)

    processed = _postprocess_data(bridges, controllers)
    return processed, bridges, controllers

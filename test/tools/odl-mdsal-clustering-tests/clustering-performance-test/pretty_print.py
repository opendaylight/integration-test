#!/usr/bin/python
__author__ = "Jan Medved"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "jmedved@cisco.com"

import json
import sys

if __name__ == "__main__":

    data = sys.stdin.readlines()
    payload = json.loads(data.pop(0))
    s = json.dumps(payload, sort_keys=True, indent=4, separators=(',', ': '))
    print '%s\n\n' % s

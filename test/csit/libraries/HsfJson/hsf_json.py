"""This module contains single a function for normalizing JSON strings."""
# Copyright (c) 2015 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html

__author__ = "Vratko Polak"
__copyright__ = "Copyright(c) 2015, Cisco Systems, Inc."
__license__ = "Eclipse Public License v1.0"
__email__ = "vrpolak@cisco.com"

try:
    import simplejson as _json
except ImportError:  # Python2.7 calls it json.
    import json as _json
from hsfl import Hsfl as _Hsfl
from hsfod import Hsfod as _Hsfod


def _hsfl_array(s_and_end, scan_once, **kwargs):
    """Scan JSON array as usual, but return hsfl instead of list."""
    values, end = _json.decoder.JSONArray(s_and_end, scan_once, **kwargs)
    return _Hsfl(values), end


class _Decoder(_json.JSONDecoder):
    """Private class to act as customized JSON decoder.

    Based on: http://stackoverflow.com/questions/10885238/
    python-change-list-type-for-json-decoding"""
    def __init__(self, **kwargs):
        """Initialize decoder with special array implementation."""
        _json.JSONDecoder.__init__(self, **kwargs)
        # Use the custom JSONArray
        self.parse_array = _hsfl_array
        # Use the python implemenation of the scanner
        self.scan_once = _json.scanner.py_make_scanner(self)


def hsf_json(text):  # pylint likes lowercase, Robot shall understand Hsf_Json
    """Return sorted indented JSON string, or an error message string."""
    try:
        object_decoded = _json.loads(text, cls=_Decoder, object_hook=_Hsfod)
    except ValueError as err:
        return str(err) + '\n' + text
    pretty_json = _json.dumps(object_decoded, separators=(',', ': '), indent=1)
    return pretty_json + '\n'  # to avoid diff "no newline" warning line

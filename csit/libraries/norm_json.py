"""This module contains single a function for normalizing JSON strings."""
# Copyright (c) 2015 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html

import collections as _collections
try:
    import simplejson as _json
except ImportError:  # Python2.7 calls it json.
    import json as _json


__author__ = "Vratko Polak"
__copyright__ = "Copyright(c) 2015-2016, Cisco Systems, Inc."
__license__ = "Eclipse Public License v1.0"
__email__ = "vrpolak@cisco.com"


# Internal details.


class _Hsfl(list):
    """
    Hashable sorted frozen list implementation stub.

    Supports only __init__, __repr__ and __hash__ methods.
    Other list methods are available, but they may break contract.
    """

    def __init__(self, *args, **kwargs):
        """Contruct super, sort and compute repr and hash cache values."""
        sup = super(_Hsfl, self)
        sup.__init__(*args, **kwargs)
        sup.sort(key=repr)
        self.__repr = repr(tuple(self))
        self.__hash = hash(self.__repr)

    def __repr__(self):
        """Return cached repr string."""
        return self.__repr

    def __hash__(self):
        """Return cached hash."""
        return self.__hash


class _Hsfod(_collections.OrderedDict):
    """
    Hashable sorted (by key) frozen OrderedDict implementation stub.

    Supports only __init__, __repr__ and __hash__ methods.
    Other OrderedDict methods are available, but they may break contract.
    """

    def __init__(self, *args, **kwargs):
        """Put arguments to OrderedDict, sort, pass to super, cache values."""
        self_unsorted = _collections.OrderedDict(*args, **kwargs)
        items_sorted = sorted(self_unsorted.items(), key=repr)
        sup = super(_Hsfod, self)  # possibly something else than OrderedDict
        sup.__init__(items_sorted)
        # Repr string is used for sorting, keys are more important than values.
        self.__repr = '{' + repr(self.keys()) + ':' + repr(self.values()) + '}'
        self.__hash = hash(self.__repr)

    def __repr__(self):
        """Return cached repr string."""
        return self.__repr

    def __hash__(self):
        """Return cached hash."""
        return self.__hash


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


# Robot Keywords.


def loads_sorted(text, strict=False):
    """
    Return Python object with sorted arrays and dictionary keys.

    If strict is true, raise exception on parse error.
    If strict is not true, return string with error message.
    """
    try:
        object_decoded = _json.loads(text, cls=_Decoder, object_hook=_Hsfod)
    except ValueError as err:
        if strict:
            raise err
        else:
            return str(err) + '\n' + text
    return object_decoded


def dumps_indented(obj, indent=1):
    """
    Wrapper for json.dumps with default indentation level. Adds newline.

    The main value is that BuiltIn.Evaluate cannot easily accept Python object
    as part of its argument.
    Also, allows to use something different from RequestsLibrary.To_Json
    """
    pretty_json = _json.dumps(obj, separators=(',', ': '), indent=indent)
    return pretty_json + '\n'  # to avoid diff "no newline" warning line


def normalize_json_text(text, strict=False, indent=1):  # pylint likes lowercase
    """Return sorted indented JSON string, or an error message string."""
    object_decoded = loads_sorted(text, strict=strict)
    pretty_json = dumps_indented(object_decoded, indent=indent)
    return pretty_json

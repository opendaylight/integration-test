"""This module contains single class, to store a sorted dict."""
# Copyright (c) 2015 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html

__author__ = "Vratko Polak"
__copyright__ = "Copyright(c) 2015, Cisco Systems, Inc."
__license__ = "Eclipse Public License v1.0"
__email__ = "vrpolak@cisco.com"

import collections as _collections


class Hsfod(_collections.OrderedDict):
    """
    Hashable sorted (by key) frozen OrderedDict implementation stub.

    Supports only __init__, __repr__ and __hash__ methods.
    Other OrderedDict methods are available, but they may break contract.
    """

    def __init__(self, *args, **kwargs):
        """Put arguments to OrderedDict, sort, pass to super, cache values."""
        self_unsorted = _collections.OrderedDict(*args, **kwargs)
        items_sorted = sorted(self_unsorted.items(), key=repr)
        sup = super(Hsfod, self)  # possibly something else than OrderedDict
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

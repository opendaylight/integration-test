"""This module contains single class, to store a sorted list."""
# Copyright (c) 2015 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html

__author__ = "Vratko Polak"
__copyright__ = "Copyright(c) 2015, Cisco Systems, Inc."
__license__ = "Eclipse Public License v1.0"
__email__ = "vrpolak@cisco.com"


class Hsfl(list):
    """
    Hashable sorted frozen list implementation stub.

    Supports only __init__, __repr__ and __hash__ methods.
    Other list methods are available, but they may break contract.
    """

    def __init__(self, *args, **kwargs):
        """Contruct super, sort and compute repr and hash cache values."""
        sup = super(Hsfl, self)
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

"""
 Defines abstract classes which describe fundamental data concepts as
 abstract classes.
"""

#
# Copyright (c) 2017 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html
#


class IoTData(object):
    """Data exchanged in IoT communication"""

    def clone(self):
        """Returns copy of this object"""
        raise NotImplementedError()

    def _compare(self, data2):
        """
        Compares two IoT data instances, return True if they are equal,
        false otherwise
        """
        raise NotImplementedError()


class IoTDataBuilder(object):
    """Builder class of IoTData objects"""

    def clone(self):
        """Returns copy of this builder object"""
        raise NotImplementedError()

    def build(self):
        """Builds the IoTData object"""
        raise NotImplementedError()


class IoTDataEncoder(object):
    """Encodes IoTData object to protocol specific message"""

    def encode(self, iotdm_data):
        """Returns protocol specific message including encoded IoTData"""
        raise NotImplementedError()


class IoTDataEncodeError(Exception):
    """IoTData encoding error"""
    pass


class IoTDataDecoder(object):
    """Decoded protocol specific message to IoTData"""

    def decode(self, protocol_message):
        """Returns IoTData  decoded of the protocol specific message"""
        raise NotImplementedError()


class IoTDataDecodeError(Exception):
    """Protocol message decoding error"""
    pass

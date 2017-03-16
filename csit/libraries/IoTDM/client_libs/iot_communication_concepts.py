"""
 Defines abstract classes which describe fundamental communication concepts as
 abstract classes.
"""

#
# Copyright (c) 2017 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html
#


class IoTCommunication(object):
    """Aggregates Rx and Tx channel for sending and receiving IoTData."""
    def __init__(self, tx, rx):
        pass


class IotComm(object):
    """
    Implements communication concepts of starting and stopping communication.
    Only methods _start() and _stop() should be implemented by child classes.
    """
    def __init__(self):
        self._started = False

    def _start(self):
        """
        Called by start() method, should contain implementation specific
        procedures
        """
        raise NotImplementedError()

    def start(self):
        """Starts communication"""
        if not self._started:
            self._start()
            self._started = True

    def _stop(self):
        """
        Called by stop() method, should contain implementation specific
        procedures to stop communication and release resources.
        """
        raise NotImplementedError()

    def stop(self):
        """Stops communication"""
        if self._started:
            self._stop()
            self._started = False

    def is_started(self):
        """Returns True if the communication is started, False otherwise"""
        return self._started


class IoTTx(IotComm):
    """
    Describes protocol specific blocking sync TX channel.
    Uses protocol specific encoder to encode IoTData and protocol specific
    decoder to decode result.
    """
    def __init__(self, encoder, decoder):
        self.encoder = encoder
        self.decoder = decoder
        super(IoTTx, self).__init__()

    def send(self, iotdata):
        """
        Uses encoder to encode iotdata to protocol specific message, sends the
        message and decodes result to iotdata and returns the decoded result
        """
        raise NotImplementedError()


class IoTRx(IotComm):
    """
    Describes protocol specific non-blocking async RX channel.
    Uses protocol specific decoder to decode received protocol message to
    IoTData and protocol specific encoder is used to encode result of
    handling.
    """
    def __init__(self, decoder, encoder):
        self.encoder = encoder
        self.decoder = decoder
        self.receive_cb = None
        super(IoTRx, self).__init__()

    def start(self, receive_cb):
        """
        Starts communication and stores receive_cb() method which process iotdata
        input and returns result as iotdata object.
        The receive_cb() is called when protocol specific message is received and
        decoded. Result of the receive_cb() is encoded to the protocol specific
        message and sent as reply if needed.
        """
        self.receive_cb = receive_cb
        super(IoTRx, self).start()

    def stop(self):
        """
        Stops the communication, releases resources and clears stored
        receive_cb() method
        """
        super(IoTRx, self).stop()
        self.receive_cb = None


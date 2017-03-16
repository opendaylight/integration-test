"""
 Implementation of IoTDM communication class implementing generic
 (protocol independent) send and receive functionality
"""

#
# Copyright (c) 2017 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html
#

from Queue import Queue
from Queue import Empty

import onem2m_http
from onem2m_http import OneM2MHttpJsonEncoderTx
from onem2m_http import OneM2MHttpJsonDecoderTx
from onem2m_http import OneM2MHttpJsonDecoderRx
from onem2m_http import OneM2MHttpJsonEncoderRx
from onem2m_http import OneM2MHttpTx
from onem2m_http import OneM2MHttpRx
from onem2m_http import OneM2MHttpJsonPrimitive
from onem2m_json_primitive import OneM2MJsonPrimitiveBuilder
from iot_communication_concepts import IotComm
from onem2m_primitive import OneM2M


class IoTDMItCommunication(IotComm):
    """
    Generic IoTDM communication implementation which can be used for
    all supported protocols
    """

    __blocking_call_timeout = 3  # seconds

    def __init__(self, tx, rx, entity_id, protocol, protocol_params, auto_handling_descriptions={}):
        super(IoTDMItCommunication, self).__init__()
        self.tx = tx
        self.rx = rx
        self.requestId = 0
        self.entity_id = entity_id
        self.protocol = protocol
        self.protocol_params = protocol_params
        self.auto_handling_descriptions = auto_handling_descriptions

        self.rx_request_queue = None
        self.rx_response_queue = None

    def create_auto_response(self, notification_request_primitive, onem2m_result_code):
        """
        Creates and returns response to provided notification request with
        provided result code
        """
        builder = IoTDMJsonPrimitiveBuilder() \
            .set_communication_protocol(self.get_protocol()) \
            .set_param(OneM2M.short_request_identifier,
                       notification_request_primitive.get_param(OneM2M.short_request_identifier)) \
            .set_param(OneM2M.short_response_status_code, onem2m_result_code) \
            .set_proto_param(onem2m_http.http_result_code, onem2m_http.onem2m_to_http_result_codes[onem2m_result_code])
        return builder.build()

    def add_auto_reply_description(self, auto_reply_description):
        """
        Adds description of automatic reply for requests matching described
        criteria
        """
        if not isinstance(auto_reply_description, RequestAutoHandlingDescription):
            raise RuntimeError("Invalid automatic handling description object passed")

        if auto_reply_description in self.auto_handling_descriptions:
            raise RuntimeError("Attempt to insert the same auto handling description multiple times")

        self.auto_handling_descriptions[auto_reply_description] = AutoHandlingStatistics()

    def remove_auto_reply_description(self, auto_reply_description):
        """Removes description of automatic reply"""
        if not isinstance(auto_reply_description, RequestAutoHandlingDescription):
            raise RuntimeError("Invalid automatic handling description object passed")

        if auto_reply_description not in self.auto_handling_descriptions:
            raise RuntimeError("No such auto handling description")

        del(self.auto_handling_descriptions[auto_reply_description])

    def get_auto_handling_statistics(self, auto_criteria):
        """
        Returns statistics of automatic handling according to auto reply
        descriptions stored
        """
        return self.auto_handling_descriptions[auto_criteria]

    def _receive_cb(self, request_primitive):
        """
        Callback called by Rx channel when request primitive is received.
        Auto response descriptions are checked first and the received request
        is handled automatically if matches at least one of stored auto reply
        descriptions. Created automatic reply is returned immediately.
        If the received request is not handled automatically (because it
        doesn't match any auto reply description) it is stored in
        rx_request_queue and processing stays blocked on get() method of
        rx_response_queue where a response to the request is expected.
        When the response to the request is retrieved from rx_respnose_queue in
        specified timeout then the response is returned from this callback.
        None is returned if the timeout expires.
        """
        if not self.rx_request_queue:
            raise RuntimeError("No rx request queue")
        if not self.rx_response_queue:
            raise RuntimeError("No rx response queue")

        # Use auto handling if match criteria
        for auto_response_desc, statistics in self.auto_handling_descriptions.items():
            if auto_response_desc.match(request_primitive):
                response = self.create_auto_response(request_primitive, auto_response_desc.get_result_code())
                # this request was successfully handled automatically,
                # increment statistics and return the resulting response
                statistics.counter += 1
                return response

        # put the request to the queue to be processed by upper layer
        self.rx_request_queue.put_nowait(request_primitive)

        try:
            # get response from the queue and return as result
            return self.rx_response_queue.get(timeout=self.__blocking_call_timeout)
        except Empty:
            # timeouted
            return None

    def get_protocol_params(self):
        """Returns default protocol specific parameters"""
        return self.protocol_params

    def get_protocol(self):
        """Returns protocol used for this communication instance"""
        return self.protocol

    def get_primitive_params(self):
        """Returns default primitive parameters"""
        params = {
            OneM2M.short_from: self.entity_id,
            OneM2M.short_request_identifier: str(self.get_next_request_id())
        }
        return params

    def _start(self):
        if not self.rx and not self.tx:
            raise RuntimeError("Nothing to start!")
        if None is not self.tx:
            self.tx.start()
        if None is not self.rx:
            self.rx_request_queue = Queue()
            self.rx_response_queue = Queue()
            self.rx.start(self._receive_cb)

    def _stop(self):
        if None is not self.tx:
            self.tx.stop()
        if None is not self.rx:
            self.rx.stop()
            req_size = self.rx_request_queue.qsize()
            rsp_size = self.rx_response_queue.qsize()
            self.rx_request_queue = None
            self.rx_response_queue = None
            if req_size or rsp_size:
                raise RuntimeError("No all requests: {} or responses: {} were processed".format(
                                   req_size, rsp_size))

    def get_next_request_id(self):
        """Returns unique request ID"""
        # TODO how to make this thread safe ?
        self.requestId += 1
        return self.requestId

    def send(self, primitive):
        if not self.is_started():
            raise RuntimeError("Communication not started yet!")
        return self.tx.send(primitive)

    def receive(self):
        """
        Blocking receive requests waits till request is received and returns the
        request or returns None when timeouted.
        Receiving thread stays blocked when request was returned from this method
        and it waits for related response to be inserted into the queue by
        respond() method.
        """
        try:
            req = self.rx_request_queue.get(timeout=self.__blocking_call_timeout)
            return req
        except Empty:
            # call timeouted and nothing received
            return None

    def respond(self, response_primitive):
        """
        This method expects response to the last request returned by
        receive() method. This response is put to the rx_respnose_queue.
        """
        self.rx_response_queue.put_nowait(response_primitive)


class IoTDMItCommunicationFactory(object):
    """
    Factory classs which should be used for instantiation objects of
    IoTDMItCommunication class
    """

    def create_http_json_primitive_communication(self, entity_id, protocol, protocol_params, rx_port, rx_interface=""):
        """
        Instantiates encoder/decoder and rx/tx objects required by
        IoTDMItCommunication and returns new instance of the
        IoTDMItCommunication class
        """
        protocol = protocol.lower()
        if protocol == "http":
            encoder = OneM2MHttpJsonEncoderTx()
            decoder = OneM2MHttpJsonDecoderTx()

            tx = OneM2MHttpTx(encoder, decoder)

            if not rx_port:
                rx = None
            else:
                encoder_rx = OneM2MHttpJsonEncoderRx()
                decoder_rx = OneM2MHttpJsonDecoderRx()

                rx = OneM2MHttpRx(decoder_rx, encoder_rx, port=rx_port, interface=rx_interface)

            return IoTDMItCommunication(tx, rx, entity_id, protocol, protocol_params)

        raise RuntimeError("Unsupported communication protocol specified: {}".format(protocol))


class IoTDMJsonPrimitiveBuilder(OneM2MJsonPrimitiveBuilder):
    """
    Helper class providing single point of access for multiple primitive
    builder classes of all supported protocols
    """

    IoTDMProtoPrimitiveClasses = {
        "http": OneM2MHttpJsonPrimitive
    }

    def build(self):
        if not self.protocol or self.protocol not in self.IoTDMProtoPrimitiveClasses:
            return super(IoTDMJsonPrimitiveBuilder, self).build()

        primitive_class = self.IoTDMProtoPrimitiveClasses[self.protocol]
        return primitive_class(self.parameters, self.content, self.protocol,
                               self.proto_params)


class RequestAutoHandlingDescription(object):
    """Class stores auto handling matching criteria for request primitives"""

    def __init__(self, parameters_match_dict, content_match_dict, proto_param_match_dict,
                 onem2m_result_code, matching_cb=None):
        self.onem2m_result_code = onem2m_result_code

        self.parameters_match_dict = parameters_match_dict
        if not self.parameters_match_dict:
            self.parameters_match_dict = {}

        self.content_match_dict = content_match_dict
        if not self.content_match_dict:
            self.content_match_dict = {}

        self.proto_param_match_dict = proto_param_match_dict
        if not self.proto_param_match_dict:
            self.proto_param_match_dict = {}

        self.matching_cb = matching_cb

    def match(self, request_primitive):
        """
        Returns True if the request_primitive object matches stored criteria,
        False otherwise
        """
        for name, value in self.parameters_match_dict.items():
            if not request_primitive.has_param(name):
                return False

            val = request_primitive.get_param(name)
            if val != value:
                return False

        for name, value in self.content_match_dict.items():
            if not request_primitive.has_attr(name):
                return False

            val = request_primitive.get_attr(name)
            if val != value:
                return False

        for name, value in self.proto_param_match_dict.items():
            if not request_primitive.has_proto_param(name):
                return False

            val = request_primitive.get_proto_param(name)
            if val != value:
                return False

        if None is not self.matching_cb:
            return self.matching_cb(request_primitive)

        return True

    def get_result_code(self):
        """
        Returns result code which should be used for resulting response
        primitive as result of automatic handling
        """
        return self.onem2m_result_code


class AutoHandlingStatistics(object):
    """Statistics gathered by auto handling"""

    def __init__(self):
        # TODO might store requests for further processing / verification
        self.counter = 0  # number of automatically handled requests


class RequestAutoHandlingDescriptionBuilder(object):
    """Builder class for auto handling description objects"""

    def __init__(self):
        self.onem2m_result_code = None
        self.parameter_match_dict = {}
        self.content_match_dict = {}
        self.proto_param_match_dict = {}

    def _add_critieria(self, json_pointer, value, match_dict):
        if str(json_pointer) in match_dict:
            raise RuntimeError("JSON pointer: {} already added".format(str(json_pointer)))
        match_dict[json_pointer] = value

    def add_param_criteria(self, json_pointer, value):
        self._add_critieria(json_pointer, value, self.parameter_match_dict)
        return self

    def add_content_criteria(self, json_pointer, value):
        self._add_critieria(json_pointer, value, self.content_match_dict)
        return self

    def add_proto_param_criteria(self, json_pointer, value):
        self._add_critieria(json_pointer, value, self.proto_param_match_dict)
        return self

    def set_onem2m_result_code(self, result_code):
        self.onem2m_result_code = result_code
        return self

    def build(self):
        if None is self.onem2m_result_code:
            raise RuntimeError("Result code not set")

        return RequestAutoHandlingDescription(self.parameter_match_dict,
                                              self.content_match_dict,
                                              self.proto_param_match_dict,
                                              self.onem2m_result_code)

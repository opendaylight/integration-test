"""
 Specific implementation of OneM2MPrimitive abstract class which uses JSON
 strings and dictionaries as well as JSON pointers to store and access data
 as OneM2M primitive objects
"""

#
# Copyright (c) 2017 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html
#

import json

from onem2m_primitive import OneM2M
from onem2m_primitive import OneM2MPrimitive
from onem2m_primitive import OneM2MPrimitiveBuilder
from onem2m_primitive import OneM2MPrimitiveBuilderException
from jsonpointer import JsonPointer
from jsonpointer import JsonPointerException


class OneM2MJsonPrimitive(OneM2MPrimitive):
    """
    Implementation of OneM2M primitive which allows to use JSON as strings or dictionaries
    to work with the request/response primitives.
    Using particular encoder/decoder, this primitive can be encoded/decoded to/from desired
    content type:
        JSON short scheme, JSON long scheme,
        XML short scheme, XML long scheme
    """

    def __init__(self, parameters, content,
                 protocol_name, protocol_parameters, short_scheme=True):
        self.parameters = parameters
        self.content = content
        self.protocol = protocol_name
        self.proto_params = protocol_parameters
        self.short_scheme = short_scheme

    def get_parameters(self):
        return self.parameters

    def get_parameters_str(self):
        return json.dumps(self.parameters)

    def _create_json_pointer(self, pointer_string):
        try:
            json_pointer = str(pointer_string)
            # add leading slash if missing
            if json_pointer[0] != '/':
                json_pointer = '/' + json_pointer

            # remove slash from the end if exists
            if json_pointer[-1] == '/':
                json_pointer = json_pointer[:-1]

            json_pointer = JsonPointer(json_pointer)
        except Exception as e:
            raise RuntimeError("Invalid JSON pointer passed: {}, error: {}".format(pointer_string, e.message))
        return json_pointer

    def _get_item_by_pointer(self, data_dict, pointer):
        if None is data_dict:
            raise AttributeError("No JSON data passed")

        if not isinstance(pointer, JsonPointer):
            json_pointer = self._create_json_pointer(pointer)
        else:
            json_pointer = pointer

        try:
            item = json_pointer.resolve(data_dict)
        except JsonPointerException as e:
            raise RuntimeError("Failed to get JSON item by JSON pointer: {}, error: {}".format(pointer, e.message))

        return item

    def _has_item_by_pointer(self, data_dict, pointer):
        if None is data_dict:
            raise AttributeError("No JSON data passed")

        if not isinstance(pointer, JsonPointer):
            json_pointer = self._create_json_pointer(pointer)
        else:
            json_pointer = pointer

        try:
            item = json_pointer.resolve(data_dict)
        except JsonPointerException as e:
            return False

        return True

    def get_param(self, param):
        """Returns container or item value identified by string or JsonPointer object"""
        return self._get_item_by_pointer(self.parameters, param)

    def has_param(self, param):
        """Returns True if parameter identified by string or JsonPointer object exists, False otherwise"""
        return self._has_item_by_pointer(self.parameters, param)

    def get_content(self):
        return self.content

    def get_content_str(self):
        if not self.content:
            return ""
        return json.dumps(self.content)

    def get_attr(self, attr):
        """Returns container or item value identified by string or JsonPointer object"""
        return self._get_item_by_pointer(self.content, attr)

    def has_attr(self, attr):
        """Returns True if attribute identified by string or JsonPointer object exists, False otherwise"""
        return self._has_item_by_pointer(self.content, attr)

    def get_protocol_specific_parameters(self):
        return self.proto_params

    def get_protocol_specific_parameters_str(self):
        return json.dumps(self.proto_params)

    def get_proto_param(self, proto_param):
        """Returns container or item value identified by string or JsonPointer object"""
        return self._get_item_by_pointer(self.proto_params, proto_param)

    def has_proto_param(self, proto_param):
        """Returns True if parameter identified by string or JsonPointer object exists, False otherwise"""
        return self._has_item_by_pointer(self.proto_params, proto_param)

    def get_primitive_str(self):
        """
        Returns whole OneM2M primitive as JSON string including primitive
        parameters and primitive content
        """
        primitive = {}
        if self.parameters:
            primitive = self.parameters.copy()

        if self.content:
            primitive[OneM2M.short_primitive_content] = self.content.copy()

        return json.dumps(primitive)

    def get_communication_protocol(self):
        return self.protocol

    def _check_protocol_of_request(self):
        if not self.get_communication_protocol():
            raise AssertionError("Communication protocol of request primitive not set")

    def _check_protocol_of_response(self, response_primitive):
        if not response_primitive.get_communication_protocol():
            raise AssertionError("Communication protocol of response primitive not set")

    def _check_exchange_protocols(self, response_primitive):
        self._check_protocol_of_request()
        self._check_protocol_of_response(response_primitive)
        if not self.get_communication_protocol() == response_primitive.get_communication_protocol():
            raise AssertionError("Request {} and response {} primitives' communication protocols doesn't match.".
                                 format(self.get_communication_protocol(),
                                        response_primitive.get_communication_protocol()))

    def _check_request_common(self):
        op = self.get_param(OneM2M.short_operation)
        if not op:
            raise AssertionError("Request primitive without operation set")

        if not isinstance(op, int):
            raise AssertionError("Invalid data type ({}) of operation where integer is expected".format(op.__class__))

        if op not in OneM2M.operation_valid_values:
            raise AssertionError("Request primitive with unknown operation set: {}".format(op))

        rqi = self.get_param(OneM2M.short_request_identifier)
        if not rqi:
            raise AssertionError("Request primitive without request id")

        if not isinstance(rqi, basestring):
            raise AssertionError("Invalid data type ({}) of request identifier where string is expected".
                                 format(rqi.__class__))
        return op, rqi

    def _check_response_common(self, response_primitive, rqi=None, rsc=None):
        rsp_rqi = response_primitive.get_param(OneM2M.short_request_identifier)
        if not rsp_rqi:
            raise AssertionError("Response primitive without request id")

        if not isinstance(rsp_rqi, basestring):
            raise AssertionError("Invalid data type ({}) of request identifier where string is expected".
                                 format(rsp_rqi.__class__))

        if rqi and rqi != rsp_rqi:
            raise AssertionError("Request IDs mismatch: req: {}, rsp: {}".format(rqi, rsp_rqi))

        r_rsc = response_primitive.get_param(OneM2M.short_response_status_code)
        if not r_rsc:
            raise AssertionError("Response primitive without status code")

        if not isinstance(r_rsc, int):
            raise AssertionError("Invalid data type ({}) of response status code where integer is expected".
                                 format(r_rsc.__class__))

        if r_rsc not in OneM2M.supported_result_codes:
            raise AssertionError("Unsupported response primitive result code: {}".format(r_rsc))

        if None is not rsc:
            if r_rsc != rsc:
                raise AssertionError("Unexpected result code: {}, expected: {}".format(r_rsc, rsc))

        return r_rsc

    def _check_exchange_common(self, response_primitive, rsc=None):
        self._check_exchange_protocols(response_primitive)
        op, rqi = self._check_request_common()
        r_rsc = self._check_response_common(response_primitive, rqi, rsc)
        return op, r_rsc

    def _check_response_positive_result(self, response_rsc=None, request_operation=None):
        if response_rsc and response_rsc not in OneM2M.positive_result_codes:
            raise AssertionError("Response with negative status code: {}".format(response_rsc))

        if None is request_operation:
            return

        expected_rsc = OneM2M.expected_result_codes[request_operation]
        if expected_rsc != response_rsc:
            raise AssertionError("Unexpected positive result code for operation: {}, received: {}, expected: {}".format(
                                 request_operation, response_rsc, expected_rsc))

    def check_exchange(self, response_primitive, rsc=None):
        op, r_rsc = self._check_exchange_common(response_primitive, rsc)
        self._check_response_positive_result(r_rsc, op)

    def _check_response_negative_result(self, response_primitive, error_message):
        if not response_primitive:
            raise AttributeError("Response primitive not passed")

        if not error_message:
            return

        msg = response_primitive.get_attr(OneM2M.error_message_item)
        if not msg:
            raise AssertionError("Negative response primitive without error message, expected message: {}".format(
                                 error_message))

        if not isinstance(msg, basestring):
            raise AssertionError("Invalid data type ({}) of response error message where string is expected".
                                 format(msg.__class__))

        if not msg == error_message:
            raise AssertionError("Negative response with unexpected error message: {}, expected: {}".format(
                                 msg, error_message))

    def check_exchange_negative(self, response_primitive, rsc, error_message=None):
        op, r_rsc = self._check_exchange_common(response_primitive, rsc)
        self._check_response_negative_result(response_primitive, error_message)

    def check_request(self):
        self._check_protocol_of_request()
        self._check_request_common()

    def check_response(self, rqi=None, rsc=None, request_operation=None):
        self._check_protocol_of_response(self)
        self._check_response_common(self, rqi, rsc)
        self._check_response_positive_result(rsc, request_operation)

    def check_response_negative(self, rqi=None, rsc=None, error_message=None):
        self._check_protocol_of_response(self)
        self._check_response_common(self, rqi, rsc)
        self._check_response_negative_result(self, error_message)

    def _compare(self, primitive2):
        raise NotImplementedError()


class OneM2MJsonPrimitiveBuilder(OneM2MPrimitiveBuilder, OneM2MJsonPrimitive):
    """Generic implementation of builder class for OneM2M JSON primitives"""

    def __init__(self):
        self.parameters = {}
        self.content = {}
        self.protocol = None
        self.proto_params = {}
        self.short_scheme = None

    def _prepare_params(self, params):
        if not params:
            return {}

        if isinstance(params, unicode):
            params = str(params)

        if isinstance(params, basestring):
            params = json.loads(params)
            return params

        if isinstance(params, dict):
            return params.copy()

        raise OneM2MPrimitiveBuilderException("Unsupported parameters object type")

    def set_parameters(self, parameters):
        self.parameters = self._prepare_params(parameters)
        return self

    def append_parameters(self, parameters):
        if not parameters:
            return self
        parameters = self._prepare_params(parameters)
        self.parameters.update(parameters)
        return self

    def set_param(self, param_name, param_value):
        self.parameters.update({param_name: param_value})
        return self

    def set_content(self, attributes):
        self.content = self._prepare_params(attributes)
        return self

    def append_content_attributes(self, attributes):
        if not attributes:
            return self
        attributes = self._prepare_params(attributes)
        self.content.update(attributes)
        return self

    def set_att(self, attr_name, attr_value):
        self.content.update({attr_name: attr_value})
        return self

    def set_communication_protocol(self, proto_name):
        self.protocol = proto_name
        return self

    def set_protocol_specific_parameters(self, proto_params):
        self.proto_params = self._prepare_params(proto_params)
        return self

    def append_protocol_specific_parameters(self, proto_params):
        if not proto_params:
            return self
        proto_params = self._prepare_params(proto_params)
        self.proto_params.update(proto_params)
        return self

    def set_proto_param(self, param_name, param_value):
        self.proto_params.update({param_name: param_value})
        return self

    def clone(self):
        raise NotImplementedError()

    def build(self):
        return OneM2MJsonPrimitive(self.parameters,
                                   self.content,
                                   self.protocol,
                                   self.proto_params)

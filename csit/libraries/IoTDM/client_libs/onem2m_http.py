"""
 Implementation of HTTP protocol specific classes of Tx, Rx, encoder, decoder
 primitive and related builder
"""

#
# Copyright (c) 2017 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html
#

from requests import Request
from requests import Response
from requests import Session
from requests import status_codes
from tornado import httpserver
from tornado import ioloop
from tornado import httputil
import threading
import json
import httplib

from iot_communication_concepts import IoTTx
from iot_communication_concepts import IoTRx
from iot_data_concepts import IoTDataEncoder
from iot_data_concepts import IoTDataDecoder
from iot_data_concepts import IoTDataEncodeError
from iot_data_concepts import IoTDataDecodeError
from onem2m_json_primitive import OneM2MJsonPrimitiveBuilder
from onem2m_json_primitive import OneM2MJsonPrimitive
from onem2m_primitive import OneM2M
from onem2m_primitive import OneM2MEncodeDecodeData


HTTPPROTOCOLNAME = "http"

protocol_address = "proto_addr"
protocol_port = "proto_port"

http_header_content_type = "Content-Type"
http_header_content_location = "Content-Location"
http_header_content_length = "Content-Length"
http_result_code = "Result-Code"

http_specific_headers = [
    http_header_content_type.lower(),
    http_header_content_location.lower(),
    http_header_content_length.lower()
]

http_header_origin = "X-M2M-Origin"
http_header_ri = "X-M2M-RI"
http_header_gid = "X-M2M-GID"
http_header_rtu = "X-M2M-RTU"
http_header_ot = "X-M2M-OT"
http_header_rst = "X-M2M-RST"
http_header_ret = "X-M2M-RET"
http_header_oet = "X-M2M-OET"
http_header_ec = "X-M2M-EC"
http_header_rsc = "X-M2M-RSC"
http_header_ati = "X-M2M-ATI"

# TODO add missing element mappings
http_headers = OneM2MEncodeDecodeData("HTTPHeaders")\
    .add(http_header_content_type, http_header_content_type)\
    .add(http_header_content_location, http_header_content_location)\
    .add(http_header_content_length, http_header_content_length)\
    .add(OneM2M.short_from, http_header_origin)\
    .add(OneM2M.short_request_identifier, http_header_ri)\
    .add(OneM2M.short_group_request_identifier, http_header_gid)\
    .add(OneM2M.short_originating_timestamp, http_header_ot)\
    .add(OneM2M.short_response_status_code, http_header_rsc)

http_query_params = [
    OneM2M.short_resource_type,
    OneM2M.short_result_persistence,
    OneM2M.short_result_content,
    OneM2M.short_delivery_aggregation,
    OneM2M.short_discovery_result_type,
    OneM2M.short_role_ids,
    OneM2M.short_token_ids,
    OneM2M.short_local_token_ids,
    OneM2M.short_token_request_indicator
    # TODO add filter criteria elements
]

onem2m_to_http_result_codes = {
    OneM2M.result_code_accepted: httplib.ACCEPTED,

    OneM2M.result_code_ok: httplib.OK,
    OneM2M.result_code_created: httplib.CREATED,
    OneM2M.result_code_deleted: httplib.OK,
    OneM2M.result_code_updated: httplib.OK,

    OneM2M.result_code_bad_request: httplib.BAD_REQUEST,
    OneM2M.result_code_not_found: httplib.NOT_FOUND,
    OneM2M.result_code_operation_not_allowed: httplib.METHOD_NOT_ALLOWED,
    OneM2M.result_code_request_timeout: httplib.REQUEST_TIMEOUT,
    OneM2M.result_code_subscription_creator_has_no_privilege: httplib.FORBIDDEN,
    OneM2M.result_code_contents_unacceptable: httplib.BAD_REQUEST,
    OneM2M.result_code_originator_has_no_privilege: httplib.FORBIDDEN,
    OneM2M.result_code_group_request_identifier_exists: httplib.CONFLICT,
    OneM2M.result_code_conflict: httplib.CONFLICT,
    OneM2M.result_code_originator_has_not_registered: httplib.FORBIDDEN,
    OneM2M.result_code_security_association_required: httplib.FORBIDDEN,
    OneM2M.result_code_invalid_child_resource_type: httplib.FORBIDDEN,
    OneM2M.result_code_no_members: httplib.FORBIDDEN,
    # OneM2M.result_code_group_member_type_inconsistent: httplib., not supported by HTTP binding spec
    OneM2M.result_code_esprim_unsupported_option: httplib.FORBIDDEN,
    OneM2M.result_code_esprim_unknown_key_id: httplib.FORBIDDEN,
    OneM2M.result_code_esprim_unknown_orig_rand_id: httplib.FORBIDDEN,
    OneM2M.result_code_esprim_unknown_recv_rand_id: httplib.FORBIDDEN,
    OneM2M.result_code_esprim_bad_mac: httplib.FORBIDDEN,

    OneM2M.result_code_internal_server_error: httplib.INTERNAL_SERVER_ERROR,
    OneM2M.result_code_not_implemened: httplib.NOT_IMPLEMENTED,
    OneM2M.result_code_target_not_reachable: httplib.NOT_FOUND,
    OneM2M.result_code_receiver_has_no_privilege: httplib.FORBIDDEN,
    OneM2M.result_code_already_exists: httplib.FORBIDDEN,
    OneM2M.result_code_target_not_subscribable: httplib.FORBIDDEN,
    OneM2M.result_code_subscription_verification_initiation_failed: httplib.INTERNAL_SERVER_ERROR,
    OneM2M.result_code_subscription_host_has_no_privilege: httplib.FORBIDDEN,
    OneM2M.result_code_non_blocking_request_not_supported: httplib.NOT_IMPLEMENTED,
    OneM2M.result_code_not_acceptable: httplib.NOT_ACCEPTABLE,
    # OneM2M.result_code_discovery_denied_by_ipe: httplib., not supported by HTTP binding spec
    OneM2M.result_code_group_members_not_responded: httplib.INTERNAL_SERVER_ERROR,
    OneM2M.result_code_esprim_decryption_error: httplib.INTERNAL_SERVER_ERROR,
    OneM2M.result_code_esprim_encryption_error: httplib.INTERNAL_SERVER_ERROR,
    OneM2M.result_code_sparql_update_error: httplib.INTERNAL_SERVER_ERROR,

    OneM2M.result_code_external_object_not_reachable: httplib.NOT_FOUND,
    OneM2M.result_code_external_object_not_found: httplib.NOT_FOUND,
    OneM2M.result_code_max_number_of_member_exceeded: httplib.BAD_REQUEST,
    OneM2M.result_code_member_type_inconsistent: httplib.BAD_REQUEST,
    OneM2M.result_code_mgmt_session_cannot_be_established: httplib.INTERNAL_SERVER_ERROR,
    OneM2M.result_code_mgmt_session_establishment_timeout: httplib.INTERNAL_SERVER_ERROR,
    OneM2M.result_code_invalid_cmd_type: httplib.BAD_REQUEST,
    OneM2M.result_code_invalid_arguments: httplib.BAD_REQUEST,
    OneM2M.result_code_insufficient_argument: httplib.BAD_REQUEST,
    OneM2M.result_code_mgmt_conversion_error: httplib.INTERNAL_SERVER_ERROR,
    OneM2M.result_code_mgmt_cancellation_failed: httplib.INTERNAL_SERVER_ERROR,
    OneM2M.result_code_already_complete: httplib.BAD_REQUEST,
    OneM2M.result_code_mgmt_command_not_cancellable: httplib.BAD_REQUEST
}


class OneM2MHttpTx(IoTTx):
    """Implementation of HTTP OneM2M Tx channel"""
    def __init__(self, encoder, decoder):
        super(OneM2MHttpTx, self).__init__(encoder, decoder)
        self.session = None

    def _start(self):
        self.session = Session()

    def _stop(self):
        if self.session:
            self.session.close()
        self.session = None

    def send(self, jsonprimitive):
        try:
            message = self.encoder.encode(jsonprimitive)
        except IoTDataEncodeError as e:
            return None

        rsp_message = self.session.send(message)

        rsp_primitive = None
        try:
            rsp_primitive = self.decoder.decode(rsp_message)
        except IoTDataDecodeError as e:
            return None

        return rsp_primitive


class OneM2MHttpRx(IoTRx):
    """Implementation of HTTP OneM2M Rx channel"""
    def __init__(self, decoder, encoder, port, interface=""):
        super(OneM2MHttpRx, self).__init__(decoder, encoder)
        self.interface = interface
        self.port = port
        self.server_address = (interface, port)
        self.server = None
        self.thread = None

    def _handle_request(self, request):
        """
        Callback method called directly by the HTTP server. This method
        decodes received HTTP request and calls provided upper layer
        receive_cb() method which process decoded primitive and returns another
        primitive object as result. The resulting primitive object is encoded
        to HTTP response message and sent back to client.
        """
        primitive = self.decoder.decode(request)

        rsp_primitive = self.receive_cb(primitive)
        if not rsp_primitive:
            code = httplib.INTERNAL_SERVER_ERROR
            reason = status_codes._codes[code]
            start_line = httputil.ResponseStartLine(version='HTTP/1.1', code=code, reason=reason)
            request.connection.write_headers(start_line, httputil.HTTPHeaders())
            request.finish()
            return

        encoded = self.encoder.encode(rsp_primitive)

        headers = httputil.HTTPHeaders()
        headers.update(encoded.headers)

        code = encoded.status_code
        reason = encoded.reason

        start_line = httputil.ResponseStartLine(version='HTTP/1.1', code=code, reason=reason)
        request.connection.write_headers(start_line, headers)

        # set content
        if encoded.content:
            request.connection.write(json.dumps(encoded.content))

        request.finish()

    def _worker(self):
        ioloop.IOLoop.instance().start()

    def _start(self):
        self.server = httpserver.HTTPServer(self._handle_request)
        self.server.listen(self.port, self.interface)
        # start worker thread which calls blocking ioloop start
        self.thread = threading.Thread(target=self._worker)
        self.thread.start()

    def _stop(self):
        ioloop.IOLoop.instance().stop()
        self.thread.join


class OneM2MHttpJsonEncoderRx(IoTDataEncoder):
    """
    HTTP Rx encoder encodes OneM2M JSON primitive objects to HTTP message
    objects used by Rx channel (different objects than used by Tx channel)
    """

    def encode(self, onem2m_primitive):
        """
        Encodes OneM2M JSON primitive object to Rx specific HTTP message
        with JSON content type
        """

        # This is Rx encoder so we use Response
        msg = Response()

        params = onem2m_primitive.get_parameters()
        proto_params = onem2m_primitive.get_protocol_specific_parameters()

        # set result code and reason
        if http_result_code not in proto_params:
            raise IoTDataEncodeError("Result code not passed for HTTP response")

        result_code = proto_params[http_result_code]
        try:
            reason = status_codes._codes[result_code][0]
        except KeyError:
            raise IoTDataEncodeError("Invalid result code passed: {}", result_code)

        msg.status_code = result_code
        msg.reason = reason

        # Headers from protocol specific parameters
        if proto_params:
            for key, value in proto_params.items():
                encoded = http_headers.encode_default_ci(key, None)
                if None is not encoded:
                    msg.headers[encoded] = str(value)

        # onem2m parameters
        for key, value in params.items():
            encoded = http_headers.encode_default_ci(key, None)
            if None is not encoded:
                msg.headers[encoded] = str(value)

        # Body (content)
        content = onem2m_primitive.get_content()
        if content:
            msg._content = content

        return msg


class OneM2MHttpJsonEncoderTx(IoTDataEncoder):
    """
    HTTP Tx encoder encodes OneM2M JSON primitive objects to HTTP message
    objects used by Tx channel (different objects than used by Rx channel)
    """

    onem2m_oper_to_http_method = {
        OneM2M.operation_create: "post",
        OneM2M.operation_retrieve: "get",
        OneM2M.operation_update: "put",
        OneM2M.operation_delete: "delete",
        OneM2M.operation_notify: "post"
    }

    def _encode_operation(self, onem2m_operation):
        return self.onem2m_oper_to_http_method[onem2m_operation]

    def _translate_uri_from_onem2m(self, uri):
        if 0 == uri.find("//"):
            return "/_/" + uri[2:]
        if 0 == uri.find("/"):
            return "/~" + uri
        return "/" + uri

    def encode(self, onem2m_primitive):
        """
        Encodes OneM2M JSON primitive object to Tx specific HTTP message
        with JSON content type
        """

        params = onem2m_primitive.get_parameters()
        proto_params = onem2m_primitive.get_protocol_specific_parameters()

        # This is Tx encoder so we use Request
        msg = Request()

        if params:
            # Method (Operation)
            if OneM2M.short_operation in params:
                msg.method = self._encode_operation(params[OneM2M.short_operation])

            # URL
            if OneM2M.short_to in params:
                resource_uri = self._translate_uri_from_onem2m(params[OneM2M.short_to])
                entity_address = ""
                if proto_params:
                    if protocol_address in proto_params:
                        entity_address = proto_params[protocol_address]
                        if protocol_port in proto_params:
                            entity_address += (":" + str(proto_params[protocol_port]))

                msg.url = "http://" + entity_address + resource_uri

            # encode headers and query parameters
            delimiter = "?"
            for key, value in params.items():

                # Query parameters
                if msg.url and key in http_query_params:
                    msg.url += (delimiter + key + "=" + str(value))
                    delimiter = "&"
                    continue

                # Headers from primitive parameters
                encoded = http_headers.encode_default_ci(key, None)
                if None is not encoded:
                    msg.headers[encoded] = str(value)

        # Headers from protocol specific parameters
        if proto_params:
            for key, value in proto_params.items():
                encoded = http_headers.encode_default_ci(key, None)
                if None is not encoded:
                    msg.headers[encoded] = str(value)

        # Body (content)
        content = onem2m_primitive.get_content()
        if content:
            msg.json = content
        return msg.prepare()


class OneM2MHttpDecodeUtils:
    """Implementation of utility methods for decoder classes"""

    @staticmethod
    def translate_http_method_to_onem2m_operation(method, has_resource_type):
        m = method.lower()
        if "post" == m:
            if has_resource_type:
                return OneM2M.operation_create
            else:
                return OneM2M.operation_notify

        if "get" == m:
            return OneM2M.operation_retrieve

        if "put" == m:
            return OneM2M.operation_update

        if "delete" == m:
            return OneM2M.operation_delete

        raise IoTDataDecodeError("Unsupported HTTP method: {}".format(method))

    @staticmethod
    def translate_uri_to_onem2m(uri):
        if 0 == uri.find("/_/"):
            return "/" + uri[2:]
        if 0 == uri.find("/~/"):
            return uri[2:]
        if 0 == uri.find("/"):
            return uri[1:]

    @staticmethod
    def decode_headers(primitive_param_dict, http_specifics, headers):
        for name, value in headers.items():
            decoded_name = http_headers.decode_default_ci(name, None)
            if None is not decoded_name:
                if name.lower() in http_specific_headers:
                    if name.lower() == http_header_content_length.lower():
                        # decode as integer values
                        try:
                            int(value)
                        except Exception as e:
                            raise IoTDataDecodeError("Invalid Content-Length value: {}, error: {}".format(value, e))

                    http_specifics[decoded_name] = value
                else:
                    if decoded_name is OneM2M.short_response_status_code:
                        # decode as integer value
                        try:
                            value = int(value)
                        except Exception as e:
                            raise IoTDataDecodeError("Invalid status code value: {}, error: {}".format(value, e))

                    primitive_param_dict[decoded_name] = value


class OneM2MHttpJsonDecoderRx(IoTDataDecoder):
    """
    HTTP Rx decoder decodes HTTP message objects used by Rx channel (different
    objects than used by Tx channel) to OneM2M JSON primitive objects
    """

    def decode(self, protocol_message):
        """
        Decodes Tx specific HTTP message with JSON content type to OneM2M JSON
        primitive object
        """
        builder = OneM2MHttpJsonPrimitiveBuilder() \
            .set_communication_protocol(HTTPPROTOCOLNAME)

        primitive_param_dict = {}
        http_specifics = {}
        OneM2MHttpDecodeUtils.decode_headers(primitive_param_dict, http_specifics, protocol_message.headers)

        builder.set_parameters(primitive_param_dict)
        builder.set_protocol_specific_parameters(http_specifics)

        if protocol_message.path:
            builder.set_param(OneM2M.short_to, OneM2MHttpDecodeUtils.translate_uri_to_onem2m(protocol_message.path))

        if protocol_message.body:
            builder.set_content(protocol_message.body)

        if protocol_message.query_arguments:
            for param, value in protocol_message.query_arguments.items():
                if len(value) == 1:
                    value = value[0]
                builder.set_param(param, value)

        if protocol_message.method:
            operation = OneM2MHttpDecodeUtils.translate_http_method_to_onem2m_operation(
                            protocol_message.method, builder.has_param(OneM2M.short_resource_type))
            builder.set_param(OneM2M.short_operation, operation)

        return builder.build()


class OneM2MHttpJsonDecoderTx(IoTDataDecoder):
    """
    HTTP Tx decoder decodes HTTP message objects used by Tx channel (different
    objects than used by Rx channel) to OneM2M JSON primitive objects
    """

    def decode(self, protocol_message):
        """
        Decodes Rx specific HTTP message with JSON content type to OneM2M JSON
        primitive object
        """
        builder = OneM2MHttpJsonPrimitiveBuilder() \
            .set_communication_protocol(HTTPPROTOCOLNAME)

        primitive_param_dict = {}
        http_specifics = {}
        OneM2MHttpDecodeUtils.decode_headers(primitive_param_dict, http_specifics, protocol_message.headers)

        # TODO decode query if needed

        # http result code
        if hasattr(protocol_message, "status_code"):
            http_specifics[http_result_code] = protocol_message.status_code

        builder.set_parameters(primitive_param_dict)
        builder.set_protocol_specific_parameters(http_specifics)

        # set content
        if hasattr(protocol_message, "content"):
            builder.set_content(protocol_message.content)

        # builder.set_proto_param(original_content_string, protocol_message.content)
        return builder.build()


class OneM2MHttpJsonPrimitive(OneM2MJsonPrimitive):
    """
    Specialization of OneM2M JSON primitive for HTTP protocol.
    Extends verification methods of the OneM2MJsonPrimitive with HTTP specific
    checks
    """

    @staticmethod
    def _check_http_primitive_content(primitive):
        content = primitive.get_content_str()
        if not content:
            # nothing to check
            return

        content_type = primitive.get_proto_param(http_header_content_type)
        if not content_type:
            raise AssertionError("HTTP primitive without Content-Type")

        # TODO add support for other content types if needed
        if "json" not in content_type:
            raise AssertionError("HTTP primitive with unsupported Content-Type: {}".format(content_type))

        content_length = primitive.get_proto_param(http_header_content_length)
        if not content_length:
            raise AssertionError("HTTP primitive without Content-Length")

        if not isinstance(content_length, basestring):
            raise AssertionError(
                "HTTP primitive with Content-Length value of invalid data type: {}, string is expected".format(
                    content_length.__class__))

        # verify length of content if exists
        # TODO commented out because this fails for primitives built by builder
        # TODO the correct place to check the value is in encoder/decoder
        # computed_length = len(content)
        # if content_length != computed_length:
        #     raise AssertionError("HTTP primitive Content-Length inconsistency: header value: {}, real length: {}".
        #                          format(content_length, computed_length))

    def _check_request_common(self):
        op, rqi = super(OneM2MHttpJsonPrimitive, self)._check_request_common()
        self._check_http_primitive_content(self)
        return op, rqi

    def _check_response_common(self, response_primitive, rqi=None, rsc=None):
        response_rsc = super(OneM2MHttpJsonPrimitive, self)._check_response_common(response_primitive, rqi, rsc)
        self._check_http_primitive_content(response_primitive)

        http_res = response_primitive.get_proto_param(http_result_code)
        if not http_res:
            raise AssertionError("HTTP response primitive without Result-Code")

        if not isinstance(http_res, int):
            raise AssertionError(
                "HTTP response primitive with Result-Code value of invalid data type: {}, expected is integer".format(
                    http_res.__class__))

        try:
            expected_http_res = onem2m_to_http_result_codes[response_rsc]
        except KeyError as e:
            raise RuntimeError("Failed to map OneM2M rsc ({}) to HTTP status code: {}".format(response_rsc, e))

        if expected_http_res != http_res:
            raise AssertionError(
                "Incorrect HTTP status code mapped to OneM2M status code {}, http: {}, expected http: {}".format(
                    response_rsc, http_res, expected_http_res))

        # Content-Location
        if response_rsc == OneM2M.result_code_created:
            content_location = response_primitive.get_proto_param(http_header_content_location)
            if not content_location:
                raise AssertionError("HTTP response primitive without Content-Location")

            if not isinstance(content_location, basestring):
                raise AssertionError(
                    "HTTP response primitive with invalid Content-Location value data type: {}, string is expected".
                        format(content_location.__class__))

        return response_rsc


class OneM2MHttpJsonPrimitiveBuilder(OneM2MJsonPrimitiveBuilder):
    """Builder class specialized for OneM2MHttpJsonPrimitive objects"""
    def build(self):
        return OneM2MHttpJsonPrimitive(self.parameters, self.content, self.protocol, self.proto_params)

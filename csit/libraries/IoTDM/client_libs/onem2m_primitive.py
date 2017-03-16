"""
 Definition of IoT data concepts specific to OneM2M
"""

#
# Copyright (c) 2017 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html
#

from iot_data_concepts import IoTData
from iot_data_concepts import IoTDataBuilder
from iot_data_concepts import IoTDataEncoder
from iot_data_concepts import IoTDataDecoder
from iot_data_concepts import IoTDataEncodeError
from iot_data_concepts import IoTDataDecodeError


class OneM2MPrimitiveDefinitions:
    """OneM2M constants and definitions"""

    # Operations
    operation_create = 1
    operation_retrieve = 2
    operation_update = 3
    operation_delete = 4
    operation_notify = 5

    operation_valid_values = [
        operation_create,
        operation_retrieve,
        operation_update,
        operation_delete,
        operation_notify
    ]

    # Long naming schema definitions
    long_primitive_content = "primitiveContent"

    # Short naming schema definitions
    short_operation = "op"
    short_to = "to"
    short_from = "fr"
    short_request_identifier = "rqi"
    short_resource_type = "ty"
    short_primitive_content = "pc"
    short_role_ids = "rids"
    short_originating_timestamp = "ot"
    short_request_expiration_timestamp = "rset"
    short_operation_execution_time = "oet"
    short_response_type = "rt"
    short_result_persistence = "rp"
    short_result_content = "rcn"
    short_event_category = "ec"
    short_delivery_aggregation = "da"
    short_group_request_identifier = "gid"
    short_filter_criteria = "fc"
    short_discovery_result_type = "drt"
    short_response_status_code = "rsc"
    short_tokens = "ts"
    short_token_ids = "tids"
    short_token_request_indicator = "tqi"
    short_local_token_ids = "ltids"
    short_assigned_token_identifiers = "ati"
    short_token_request_information = "tqf"
    short_content_status = "cnst"
    short_content_offset = "cnot"

    # OneM2M result codes
    result_code_accepted = 1000

    result_code_ok = 2000
    result_code_created = 2001
    result_code_deleted = 2002
    result_code_updated = 2004

    result_code_bad_request = 4000
    result_code_not_found = 4004
    result_code_operation_not_allowed = 4005
    result_code_request_timeout = 4008
    result_code_subscription_creator_has_no_privilege = 4101
    result_code_contents_unacceptable = 4102
    result_code_originator_has_no_privilege = 4103
    result_code_group_request_identifier_exists = 4104
    result_code_conflict = 4105
    result_code_originator_has_not_registered = 4106
    result_code_security_association_required = 4107
    result_code_invalid_child_resource_type = 4108
    result_code_no_members = 4109
    result_code_group_member_type_inconsistent = 4110
    result_code_esprim_unsupported_option = 4111
    result_code_esprim_unknown_key_id = 4112
    result_code_esprim_unknown_orig_rand_id = 4113
    result_code_esprim_unknown_recv_rand_id = 4114
    result_code_esprim_bad_mac = 4115

    result_code_internal_server_error = 5000
    result_code_not_implemened = 5001
    result_code_target_not_reachable = 5103
    result_code_receiver_has_no_privilege = 5105
    result_code_already_exists = 5106
    result_code_target_not_subscribable = 5203
    result_code_subscription_verification_initiation_failed = 5204
    result_code_subscription_host_has_no_privilege = 5205
    result_code_non_blocking_request_not_supported = 5206
    result_code_not_acceptable = 5207
    result_code_discovery_denied_by_ipe = 5208
    result_code_group_members_not_responded = 5209
    result_code_esprim_decryption_error = 5210
    result_code_esprim_encryption_error = 5211
    result_code_sparql_update_error = 5212

    result_code_external_object_not_reachable = 6003
    result_code_external_object_not_found = 6005
    result_code_max_number_of_member_exceeded = 6010
    result_code_member_type_inconsistent = 6011
    result_code_mgmt_session_cannot_be_established = 6020
    result_code_mgmt_session_establishment_timeout = 6021
    result_code_invalid_cmd_type = 6022
    result_code_invalid_arguments = 6023
    result_code_insufficient_argument = 6024
    result_code_mgmt_conversion_error = 6025
    result_code_mgmt_cancellation_failed = 6026
    result_code_already_complete = 6028
    result_code_mgmt_command_not_cancellable = 6029

    supported_result_codes = [
        result_code_accepted,

        result_code_ok,
        result_code_created,
        result_code_deleted,
        result_code_updated,

        result_code_bad_request,
        result_code_not_found,
        result_code_operation_not_allowed,
        result_code_request_timeout,
        result_code_subscription_creator_has_no_privilege,
        result_code_contents_unacceptable,
        result_code_originator_has_no_privilege,
        result_code_group_request_identifier_exists,
        result_code_conflict,
        result_code_originator_has_not_registered,
        result_code_security_association_required,
        result_code_invalid_child_resource_type,
        result_code_no_members,
        result_code_group_member_type_inconsistent,
        result_code_esprim_unsupported_option,
        result_code_esprim_unknown_key_id,
        result_code_esprim_unknown_orig_rand_id,
        result_code_esprim_unknown_recv_rand_id,
        result_code_esprim_bad_mac,

        result_code_internal_server_error,
        result_code_not_implemened,
        result_code_target_not_reachable,
        result_code_receiver_has_no_privilege,
        result_code_already_exists,
        result_code_target_not_subscribable,
        result_code_subscription_verification_initiation_failed,
        result_code_subscription_host_has_no_privilege,
        result_code_non_blocking_request_not_supported,
        result_code_not_acceptable,
        result_code_discovery_denied_by_ipe,
        result_code_group_members_not_responded,
        result_code_esprim_decryption_error,
        result_code_esprim_encryption_error,
        result_code_sparql_update_error,

        result_code_external_object_not_reachable,
        result_code_external_object_not_found,
        result_code_max_number_of_member_exceeded,
        result_code_member_type_inconsistent,
        result_code_mgmt_session_cannot_be_established,
        result_code_mgmt_session_establishment_timeout,
        result_code_invalid_cmd_type,
        result_code_invalid_arguments,
        result_code_insufficient_argument,
        result_code_mgmt_conversion_error,
        result_code_mgmt_cancellation_failed,
        result_code_already_complete,
        result_code_mgmt_command_not_cancellable
    ]

    positive_result_codes = [
        result_code_ok,
        result_code_deleted,
        result_code_updated,
        result_code_created,
        result_code_accepted
    ]

    # Expected positive result codes per operation
    expected_result_codes = {
        operation_create: result_code_created,
        operation_retrieve: result_code_ok,
        operation_update: result_code_updated,
        operation_delete: result_code_deleted,
        operation_notify: result_code_ok
    }

    # Error message content item
    error_message_item = "error"

    # Resource types
    resource_type_access_control_policy = 1
    resource_type_application_entity = 2
    resource_type_container = 3
    resource_type_content_instance = 4
    resource_type_cse_base = 5
    resource_type_delivery = 6
    resource_type_event_config = 7
    resource_type_exec_instance = 8
    resource_type_group = 9
    resource_type_location_policy = 10
    resource_type_m2m_service_subscription_profile = 11
    resource_type_mgmt_cmd = 12
    resource_type_mgmt_obj = 13
    resource_type_node = 14
    resource_type_polling_channel = 15
    resource_type_remote_cse = 16
    resource_type_request = 17
    resource_type_schedule = 18
    resource_type_service_subscribed_app_rule = 19
    resource_type_service_subscribed_node = 20
    resource_type_stats_collect = 21
    resource_type_stats_config = 22
    resource_type_subscription = 23
    resource_type_semantic_descriptor = 24
    resource_type_notification_target_mgmt_policy_ref = 25
    resource_type_notification_target_policy = 26
    resource_type_policy_deletion_rules = 27
    resource_type_flex_container = 28
    resource_type_time_series = 29
    resource_type_time_series_instance = 30
    resource_type_role = 31
    resource_type_token = 32
    resource_type_traffic_pattern = 33
    resource_type_dynamic_authorization_consultation = 34


# Instantiates definitions (used by robot framework test suites)
OneM2M = OneM2MPrimitiveDefinitions()


class OneM2MEncodeDecodeData(object):
    """Utility class which allows to define encoding/decoding dictionaries"""
    def __init__(self, data_type):
        if not data_type:
            raise Exception("No data type string specified")

        self.data_type = data_type  # name of data type
        self._encode = {}   # dictionary stores OneM2M: protocol mapping
        self._decode = {}   # dictionary stores protocol: OneM2M mapping
        self._encode_ci = {}    # stores case insensitive OneM2M: protocol mapping
        self._decode_ci = {}    # stores case insensitive protocol: OneM2M mapping

    def add(self, onem2m, protocol_specific):
        """Adds new encoding/decoding pair"""
        if onem2m in self._encode:
            raise Exception("Data type: {}, Encoding key {} already exists".format(self.data_type, onem2m))
        self._encode[onem2m] = protocol_specific
        decoded_ci = onem2m if not isinstance(onem2m, basestring) else onem2m.lower()
        self._encode_ci[decoded_ci] = protocol_specific

        if protocol_specific in self._decode:
            raise Exception("Data type: {}, Decoding key {} already exists".format(self.data_type, protocol_specific))
        self._decode[protocol_specific] = onem2m
        encoded_ci = protocol_specific if not isinstance(protocol_specific, basestring) else protocol_specific.lower()
        self._decode_ci[encoded_ci] = onem2m
        return self

    def encode(self, key):
        """Returns key encoded to protocol specific form"""
        if key not in self._encode:
            raise IoTDataEncodeError("Data type: {}, Encoding key {} not found".format(self.data_type, key))
        return self._encode[key]

    def encode_default(self, key, default):
        """Returns encoded key or default value if the key doesn't exist"""
        if key not in self._encode:
            return default
        return self._encode[key]

    def encode_ci(self, key):
        """Performs case insensitive encoding and returns encoded key"""
        k = key if not isinstance(key, basestring) else key.lower()
        if k not in self._encode_ci:
            raise IoTDataEncodeError(
                "Data type: {}, Case Insensitive Encoding key {} not found".format(self.data_type, key))
        return self._encode_ci[k]

    def encode_default_ci(self, key, default):
        """
        Performs case insensitive encoding and returns encoded key or default
        value if the key doesn't exit
        """
        k = key if not isinstance(key, basestring) else key.lower()
        if k not in self._encode_ci:
            return default
        return self._encode_ci[k]

    def decode(self, key):
        """Decodes protocol specific key and returns decoded OneM2M string"""
        if key not in self._decode:
            raise IoTDataDecodeError("Data type: {}, Decoding key {} not found".format(self.data_type, key))
        return self._decode[key]

    def decode_default(self, key, default):
        """
        Decodes protocol specific key and returns decoded OneM2M string
        or default value if the key doesn't exist
        """
        if key not in self._decode:
            return default
        return self._decode[key]

    def decode_ci(self, key):
        """Performs case insensitive decoding and returns decoded OneM2M string"""
        k = key if not isinstance(key, basestring) else key.lower()
        if k not in self._decode_ci:
            raise IoTDataDecodeError(
                "Data type: {}, Case Insensitive Decoding key {} not found".format(self.data_type, key))
        return self._decode_ci[k]

    def decode_default_ci(self, key, default):
        """
        Performs case insensitive decoding and returns decoded OneM2M string
        or default value if the key doesn't exist
        """
        k = key if not isinstance(key, basestring) else key.lower()
        if k not in self._decode_ci:
            return default
        return self._decode_ci[k]


class OneM2MPrimitive(IoTData):
    """
    Abstract class, specialization of IoTData which describes
    OneM2M primitive. Primitive data object is divided into three parts:
        1. Primitive parameters - consists of items called param
        2. Primitive content - consists of items called attr
        3. Protocol specific parameters - consists of items called proto_param
    """

    def get_parameters(self):
        """Returns all primitive parameters as dict"""
        raise NotImplementedError()

    def get_param(self, param):
        """Returns value of specific parameter"""
        raise NotImplementedError()

    def get_content(self):
        """Returns primitive content as dict"""
        raise NotImplementedError()

    def get_attr(self, attr):
        """Returns value of specific attribute of primitive content"""
        raise NotImplementedError()

    def get_protocol_specific_parameters(self):
        """Returns protocol specific primitive parameters as dict"""
        raise NotImplementedError()

    def get_proto_param(self, proto_param):
        """Returns value of specific protocol parameter"""
        raise NotImplementedError()

    def get_primitive_str(self):
        """Returns string representation of primitive including parameters and content"""
        raise NotImplementedError()

    def get_communication_protocol(self):
        """Returns communication protocol used when sending / receiving this primitive"""
        raise NotImplementedError()

    def check_request(self):
        """Verifies this instance as request"""
        raise NotImplementedError("Request validation not implemented")

    def check_response(self, rqi=None, rsc=None, request_operation=None):
        """
        Verifies this instance as response and checks parameter values
        if provided
        """
        raise NotImplementedError("Response validation not implemented")

    def check_response_negative(self, rqi=None, rsc=None, error_message=None):
        """
        Verifies this instance as negative response primitive and checks
        parameters if provided
        """
        raise NotImplementedError("Negative response validation not implemented")

    def check_exchange(self, response_primitive, rsc=None):
        """
        Verifies this instance as request primitive, verifies provided response
        primitive and checks request and response primitive parameters if the
        request and response primitive represents valid data exchange
        """
        raise NotImplementedError("Exchange validation not implemented")

    def check_exchange_negative(self, response_primitive, rsc, error_message=None):
        """
        Verifies this instance as request primitive, verifies provided negative
        response primitive and checks request and response primitive parameters
        if the request and response primitive represents valid data exchange
        """
        raise NotImplementedError("Negative exchange validation not implemented")


class OneM2MPrimitiveBuilderException(Exception):
    """OneM2M primitive build error"""
    pass


class OneM2MPrimitiveBuilder(IoTDataBuilder, OneM2MPrimitive):
    """Abstract class describes OneM2M primitive object builder"""
    def set_parameters(self, parameters):
        raise NotImplementedError()

    def set_param(self, param_name, param_value):
        raise NotImplementedError()

    def set_content(self, attributes):
        raise NotImplementedError()

    def set_att(self, attr_name, attr_value):
        raise NotImplementedError()

    def set_communication_protocol(self, proto_name):
        raise NotImplementedError()

    def set_protocol_specific_parameters(self, proto_params):
        raise NotImplementedError()

    def set_proto_param(self, param_name, param_value):
        raise NotImplementedError()

    def clone(self):
        raise NotImplementedError()

    def build(self):
        raise NotImplementedError()


class OneM2MPrimitiveEncoder(IoTDataEncoder):
    """IoT Data Encoder specialization for OneM2M primitives"""
    def encode(self, onem2m_primitive):
        raise NotImplementedError()


class OneM2MPrimitiveDecoder(IoTDataDecoder):
    """IoT Data Decoder specialization for OneM2M primitives"""
    def decode(self, protocol_message):
        raise NotImplementedError()

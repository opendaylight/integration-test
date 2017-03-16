"""
 This library provides methods using IoTDM client libs for testing
 of communication with IoTDM.
"""

#
# Copyright (c) 2017 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html
#

import json

from client_libs.iotdm_it_test_com import IoTDMItCommunicationFactory
from client_libs.iotdm_it_test_com import IoTDMJsonPrimitiveBuilder
from client_libs.iotdm_it_test_com import RequestAutoHandlingDescriptionBuilder
from client_libs.iotdm_it_test_com import RequestAutoHandlingDescription
import client_libs.onem2m_http as onem2m_http
from client_libs.onem2m_primitive import OneM2M


# Mapping of alliases to communication objects
__sessions = {}


def __get_session(allias, session):
    if session:
        return session

    if allias in __sessions:
        return __sessions[allias]

    return None


def prepare_primitive_builder_raw(protocol, primitive_params, content=None, proto_specific_params=None):
    """Creates primitive builder without any default data"""
    builder = IoTDMJsonPrimitiveBuilder()\
        .set_communication_protocol(protocol)\
        .set_content(content)\
        .set_parameters(primitive_params)\
        .set_protocol_specific_parameters(proto_specific_params)
    return builder


def new_primitive_raw(protocol, primitive_params, content=None, proto_specific_params=None):
    """Creates primitive object without any default data"""
    return prepare_primitive_builder_raw(protocol, primitive_params, content, proto_specific_params).build()


def prepare_primitive_builder(primitive_params, content=None, proto_specific_params=None,
                              allias="default", communication=None):
    """Creates primitive builder with default data set according communication object used"""
    communication = __get_session(allias, communication)

    builder = IoTDMJsonPrimitiveBuilder()\
        .set_communication_protocol(communication.get_protocol())\
        .set_parameters(communication.get_primitive_params())\
        .set_protocol_specific_parameters(communication.get_protocol_params())\
        .set_content(content)

    if communication.get_protocol() == onem2m_http.HTTPPROTOCOLNAME and content:
        builder.set_proto_param(onem2m_http.http_header_content_length, str(len(content)))

    builder.append_parameters(primitive_params)\
           .append_protocol_specific_parameters(proto_specific_params)

    return builder


def new_primitive(primitive_params, content=None, proto_specific_params=None,
                  allias="default", communication=None):
    """Creates new primitive object with default data set according communication object used"""
    return prepare_primitive_builder(primitive_params, content, proto_specific_params, allias, communication).build()


def _add_param(params, name, value):
    if not name or not value:
        return
    params[name] = value


def prepare_request_primitive_builder(target_resource, content=None, operation=None, resource_type=None,
                                      result_content=None, allias="default", communication=None):
    """
    Creates builder for request primitive with default data set according
    communication object used
    """
    communication = __get_session(allias, communication)
    if not communication or not target_resource:
        raise AttributeError("Mandatory attributes not specified")

    primitive_params = {}
    _add_param(primitive_params, OneM2M.short_to, target_resource)
    _add_param(primitive_params, OneM2M.short_operation, operation)
    _add_param(primitive_params, OneM2M.short_resource_type, resource_type)
    _add_param(primitive_params, OneM2M.short_result_content, result_content)

    primitive_params = json.dumps(primitive_params)

    builder = prepare_primitive_builder(primitive_params, content, communication=communication)
    return builder


def new_create_request_primitive(target_resource, content, resource_type, result_content=None,
                                 allias="default", communication=None):
    """Creates request primitive for Create operation"""
    return prepare_request_primitive_builder(target_resource, content, operation=OneM2M.operation_create,
                                             resource_type=resource_type, result_content=result_content,
                                             allias=allias, communication=communication).build()


def new_update_request_primitive(target_resource, content, result_content=None, allias="default", communication=None):
    """Creates request primitive for Update operation"""
    return prepare_request_primitive_builder(target_resource, content, operation=OneM2M.operation_update,
                                             resource_type=None, result_content=result_content,
                                             allias=allias, communication=communication).build()


def new_retrieve_request_primitive(target_resource, result_content=None, allias="default", communication=None):
    """Creates request primitive for Retrieve operation"""
    return prepare_request_primitive_builder(target_resource, content=None,
                                             operation=OneM2M.operation_retrieve,
                                             resource_type=None, result_content=result_content,
                                             allias=allias, communication=communication).build()


def new_delete_request_primitive(target_resource, result_content=None, allias="default", communication=None):
    """Creates request primitive for Delete operation"""
    return prepare_request_primitive_builder(target_resource, content=None,
                                             operation=OneM2M.operation_delete, result_content=result_content,
                                             allias=allias, communication=communication).build()


def send_primitive(primitive, allias="default", communication=None):
    """Sends primitive object using the communication object"""
    communication = __get_session(allias, communication)
    rsp = communication.send(primitive)
    return rsp


def verify_exchange(request_primitive, response_primitive, status_code=None):
    """Verifies request and response primitive parameters"""
    request_primitive.check_exchange(response_primitive, rsc=status_code)


def verify_exchange_negative(request_primitive, response_primitive, status_code, error_message=None):
    """Verifies request and error response primitive parameters"""
    request_primitive.check_exchange_negative(response_primitive, status_code, error_message)


def verify_request(request_primitive):
    """Verifies request primitive only"""
    request_primitive.check_request()


def verify_response(response_primitive, rqi=None, rsc=None, request_operation=None):
    """Verifies response primitive only"""
    response_primitive.check_response(rqi, rsc, request_operation)


def verify_response_negative(response_primitive, rqi=None, rsc=None, error_message=None):
    """Verifies error response primitive only"""
    response_primitive.check_response_negative(rqi, rsc, error_message)


def receive_request_primitive(allias="default", communication=None):
    """
    Blocking call which receives request primitive. If the request
    primitive was received, the underlying Rx channel stays blocked
    until response primitive (related to the request primitive) is
    provided using respond_response_primitive() method
    """
    communication = __get_session(allias, communication)
    req = communication.receive()
    return req


def respond_response_primitive(response_primitive, allias="default", communication=None):
    """
    Sends response primitive related to the last request primitive received by
    receive_request_primitive() method
    """
    communication = __get_session(allias, communication)
    communication.respond(response_primitive)


def create_notification_response(notification_request_primitive, allias="default", communication=None):
    """Creates response primitive for provided notification request primitive"""
    communication = __get_session(allias, communication)
    return communication.create_auto_response(notification_request_primitive,
                                               OneM2M.result_code_ok)


def create_notification_response_negative(notification_request_primitive, result_code, error_message,
                                          allias="default", communication=None):
    """Creates negative response primitive for provided notification request primitive"""
    communication = __get_session(allias, communication)
    builder = IoTDMJsonPrimitiveBuilder() \
        .set_communication_protocol(communication.get_protocol()) \
        .set_param(OneM2M.short_request_identifier,
                   notification_request_primitive.get_param(OneM2M.short_request_identifier)) \
        .set_param(OneM2M.short_response_status_code, result_code) \
        .set_proto_param(onem2m_http.http_result_code, onem2m_http.onem2m_to_http_result_codes[result_code])\
        .set_content('{"error": "' + error_message + '"}')
    return builder.build()


# JSON pointer strings used by methods providing automatic reply mechanism
JSON_POINTER_NOTIFICATION_RN = "/nev/rep/rn"
JSON_POINTER_NOTIFICATION_SUR = "/sur"


def _on_subscription_create_notificaton_matching_cb(request_primitive):
    """
    Is used as callback which returns True if the provided request primitive is
    notification request triggered by creation of new subscription resource.
    """
    if request_primitive.get_param(OneM2M.short_operation) != OneM2M.operation_notify:
        return False

    if not request_primitive.has_attr(JSON_POINTER_NOTIFICATION_RN):
        return False

    if not request_primitive.has_attr(JSON_POINTER_NOTIFICATION_SUR):
        return False

    rn = request_primitive.get_attr(JSON_POINTER_NOTIFICATION_RN)
    sur = request_primitive.get_attr(JSON_POINTER_NOTIFICATION_SUR)

    if rn != sur:
        return False
    return True


# Description of such notification request primitive which is received
# as result of new subscription resource
ON_SUBSCRIPTION_CREATE_DESCRIPTION =\
    RequestAutoHandlingDescription(None, None, None,
                                   onem2m_result_code=OneM2M.result_code_ok,
                                   matching_cb=_on_subscription_create_notificaton_matching_cb)


def _prepare_notification_auto_reply_builder():
    return RequestAutoHandlingDescriptionBuilder()\
        .add_param_criteria(OneM2M.short_operation, OneM2M.operation_notify)\
        .set_onem2m_result_code(OneM2M.result_code_ok)


def add_notification_auto_reply_on_subscription_create(allias="default", communication=None):
    """Sets auto reply for notification requests received due to subscription resource creation"""
    communication = __get_session(allias, communication)
    communication.add_auto_reply_description(ON_SUBSCRIPTION_CREATE_DESCRIPTION)


def remove_notification_auto_reply_on_subscription_create(allias="default", communication=None):
    """Removes auto reply for notification requests received due to subscription resource creation"""
    communication = __get_session(allias, communication)
    communication.remove_auto_reply_description(ON_SUBSCRIPTION_CREATE_DESCRIPTION)


def get_number_of_auto_replies_on_subscription_create(allias="default", communication=None):
    """Returns number of auto replies on notification requests received when new subscription created"""
    communication = __get_session(allias, communication)
    return communication.get_auto_handling_statistics(ON_SUBSCRIPTION_CREATE_DESCRIPTION).counter


def verify_number_of_auto_replies_on_subscription_create(replies, allias="default", communication=None):
    """Compares number of auto replies on notifications received when new subscription created"""
    count = get_number_of_auto_replies_on_subscription_create(allias, communication)
    if replies != count:
        raise AssertionError("Unexpected number of auto replies on subscription create: {}, expected: {}".format(
                             count, replies))


__SUBSCRIPTION_RESOURCE_ID_DESCRIPTION_MAPPING = {}


def add_auto_reply_to_notification_from_subscription(subscription_resource_id, allias="default", communication=None):
    """
    Sets auto reply for notifications from specific subscription resource
    identified by its CSE-relative resource ID
    """
    communication = __get_session(allias, communication)
    builder = _prepare_notification_auto_reply_builder()
    if subscription_resource_id in __SUBSCRIPTION_RESOURCE_ID_DESCRIPTION_MAPPING:
        raise RuntimeError("Auto reply for subscription resource {} already set".format(subscription_resource_id))

    builder.add_content_criteria(JSON_POINTER_NOTIFICATION_SUR, subscription_resource_id)
    new_description = builder.build()
    __SUBSCRIPTION_RESOURCE_ID_DESCRIPTION_MAPPING[subscription_resource_id] = new_description
    communication.add_auto_reply_description(new_description)


def remove_auto_reply_to_notification_from_subscription(subscription_resource_id, allias="default", communication=None):
    """Removes auto reply for specific subscription identified by its CSE-relative resource ID"""
    communication = __get_session(allias, communication)
    description = __SUBSCRIPTION_RESOURCE_ID_DESCRIPTION_MAPPING[subscription_resource_id]
    if not description:
        raise RuntimeError("No auto reply set for specific subscription resource: {}".format(subscription_resource_id))
    communication.remove_auto_reply_description(description)


def get_number_of_auto_replies_to_notifications_from_subscription(subscription_resource_id,
                                                                  allias="default", communication=None):
    """
    Returns number of automatic replies for specific subscription resource
    identified by its CSE-relative resource ID
    """
    communication = __get_session(allias, communication)
    description = __SUBSCRIPTION_RESOURCE_ID_DESCRIPTION_MAPPING[subscription_resource_id]
    if not description:
        raise RuntimeError("No auto reply set for specific subscription resource: {}".format(subscription_resource_id))
    return communication.get_auto_handling_statistics(description).counter


def verify_number_of_auto_replies_to_notification_from_subscription(subscription_resource_id, replies,
                                                                    allias="default", communication=None):
    """
    Compares number of automatic replies for specific subscription resource
    identified by its CSE-relative resource ID
    """
    count = get_number_of_auto_replies_to_notifications_from_subscription(subscription_resource_id, allias, communication)
    if replies != count:
        raise AssertionError(("Unexpected number of auto replies to notification from subscription {}, " +
                             "auto replies: {}, expected: {}").format(subscription_resource_id, count, replies))


# Primitive getters uses JSON pointer object or string
# to identify specific parameter/attribute/protocol_specific_parameter
def get_primitive_content(primitive):
    return primitive.get_content_str()


def get_primitive_content_attribute(primitive, pointer):
    return primitive.get_attr(pointer)


def get_primitive_parameters(primitive):
    return primitive.get_parameters_str()


def get_primitive_param(primitive, pointer):
    return primitive.get_param(pointer)


def get_primitive_protocol_specific_parameters(primitive):
    return primitive.get_protocol_specific_parameters_str()


def get_primitive_protocol_specific_param(primitive, pointer):
    return primitive.get_proto_param(pointer)


# Communication
def close_iotdm_communication(allias="default", communication=None):
    """Closes communication identified by allias or provided as object"""
    communication = __get_session(allias, communication)
    communication.stop()
    if allias in __sessions:
        del __sessions[allias]


def create_iotdm_communication(entity_id, protocol, protocol_params=None, rx_port=None, allias="default"):
    """
    Creates communication object and starts the communication.
    :param entity_id: ID which will be used in From parameter of request primitives
    :param protocol: Communication protocol to use for communication
    :param protocol_params: Default protocol specific parameters to be used
    :param rx_port: Local Rx port number
    :param allias: Allias to be assigned to the created communication object
    :return: The new communication object
    """
    if protocol == onem2m_http.HTTPPROTOCOLNAME:
        conn = IoTDMItCommunicationFactory().create_http_json_primitive_communication(entity_id, protocol,
                                                                                      protocol_params, rx_port)
    else:
        raise RuntimeError("Unsupported protocol: {}".format(protocol))

    conn.start()
    if allias:
        __sessions[allias] = conn
    return conn


def get_local_ip_from_list(iotdm_ip, local_ip_list_str):
    """
    Looks for longest prefix matching local interface IP address with the
    IP address of IoTDM.
    :param iotdm_ip: IP address of IoTDM
    :param local_ip_list_str: String of IP address of local interfaces separated with space
    :return: The longed prefix matching IP or the first one
    """
    if not local_ip_list_str:
        raise RuntimeError("Local IP address not provided")

    if not iotdm_ip:
        raise RuntimeError("IoTDM IP address not provided")

    list = local_ip_list_str.split(" ")

    if (len(list) == 1):
        return list[0]

    for i in range(len(iotdm_ip), 0, -1):
        # TODO this is not real longest prefix match
        # TODO fix if needed
        for ip in list:
            if ip.startswith(iotdm_ip[0: i]):
                return ip

    # no match, just choose the first one
    return list[0]


# HTTP
def create_http_default_communication_parameters(address, port, content_type):
    """Returns JSON string including default HTTP specific parameters"""
    return '{{"{}": "{}", "{}": {}, "Content-Type": "{}"}}'.format(
                onem2m_http.protocol_address, address,
                onem2m_http.protocol_port, port,
                content_type)


def create_iotdm_http_connection(entity_id, address, port, content_type, rx_port=None, allias="default"):
    """Creates HTTP communication"""
    default_params = create_http_default_communication_parameters(address, port, content_type)
    return create_iotdm_communication(entity_id, "http", default_params, rx_port, allias)


*** Settings ***
Documentation     Basic tests for TELEMETRY information configuration and verification.
...               Copyright (c) 2018-2019 Zte, Inc. All rights reserved.
...               Test suite performs basic TELEMETRY information configuration and verification test cases for sensor, destination, and subscription as follows:
...               Test Case 1: Configure sensor with add and delete operation
...               Expected result: The Configure result with corresponding operation verified as expected
...               Test Case 2: Configure destination with add and delete operation
...               Expected result: The Configure result with corresponding operation verified as expected
...               Test Case 3: Configure subscription with add and delete operation
...               Expected result: The Configure result with corresponding operation verified as expected
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../variables/Variables.robot
Library           RequestsLibrary

*** Variables ***
@{SENSOR_ID_LIST}    ${sensor1}    ${sensor2}
@{PATH_LIST}      ${path1}    ${path2}
@{FILTER_LIST}    ${filter1}    ${filter2}
${TELEMETRY_VAR_FOLDER}    ${CURDIR}/../../../variables/telemetry
@{DESTINATION_ID_LIST}    ${destination1}    ${destination2}
@{ADDRESS_LIST}    ${10.42.89.15}    ${10.96.33.30}
${PORT}           50051
@{NODE_ID_LIST}    ${node1}    ${node2}
@{SUBSCRIPTION_ID_LIST}    ${subscription1}    ${subscription2}
@{PROTOCOL_TYPE_LIST}    ${STREAM_SSH}    ${STREAM_GRPC}    ${STREAM_JSON_RPC}    ${STREAM_THRIFT_RPC}    ${STREAM_WEBSOCKET_RPC}
@{ENCODING_TYPE_LIST}    ${ENC_XML}    ${ENC_JSON_IETF}    ${ENC_PROTO3}
${LOCAL_SOURCE_ADDRESS}    127.0.0.1
@{QOS_MARKING_LIST}    ${0}    ${1}    ${2}    ${3}    ${4}    ${5}
@{SAMPLE_INTERVAL_LIST}    ${100}    ${200}    ${300}
@{HEARTBEAT_INTERVAL_LIST}    ${30}    ${60}

*** Test Cases ***
TC1_Configure Sensor
    [Documentation]    Configure two sensors with sensor id list ${SENSOR_ID_LIST}, sensor path list ${PATH_LIST}, and sensor exclude filter list ${FILTER_LIST}.
    ${mapping}    Create Dictionary    SENSOR1=${SENSOR_ID_LIST[0]}    SENSOR2=${SENSOR_ID_LIST[1]}    PATH1=${PATH_LIST[0]}    PATH2=${PATH_LIST[1]}    FILTER1=${FILTER_LIST[0]}
    ...    FILTER2=${FILTER_LIST[1]}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${TELEMETRY_VAR_FOLDER}/telemetry_sensor_configuration/configure_sensor    ${mapping}    session
    Verify_Response_As_Json_Templated    ${resp}    ${TELEMETRY_VAR_FOLDER}/response    success_response

TC1_Delete Sensor
    [Documentation]    Delete the second sensor created in the test case TC1_Configure Sensor.
    ${mapping}    Create Dictionary    SENSOR2=${SENSOR_ID_LIST[1]}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${TELEMETRY_VAR_FOLDER}/telemetry_sensor_configuration/delete_sensor    ${mapping}    session
    Verify_Response_As_Json_Templated    ${resp}    ${TELEMETRY_VAR_FOLDER}/response    success_response

TC1_Query Sensor
    [Documentation]    Query the sensor created in the datastore.
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${TELEMETRY_VAR_FOLDER}/telemetry_sensor_configuration/query_sensor    {}    session    True

TC2_Configure Destination
    [Documentation]    Configure two destinations with destination id list ${DESTINATION_ID_LIST}, address list ${ADDRESS_LIST} and port ${PORT}.
    ${mapping}    Create Dictionary    DESTINATION1=${DESTINATION_ID_LIST[0]}    DESTINATION2=${DESTINATION_ID_LIST[1]}    ADDRESS1=${ADDRESS_LIST[0]}    ADDRESS2=${ADDRESS_LIST[1]}    PORT=${PORT}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${TELEMETRY_VAR_FOLDER}/telemetry_destination_configuration/configure_destination    ${mapping}    session
    Verify_Response_As_Json_Templated    ${resp}    ${TELEMETRY_TE_VAR_FOLDER}/response    success_response

TC2_Delete Destination
    [Documentation]    Delete the second destination created in the test case TC2_Configure Destination.
    ${mapping}    Create Dictionary    DESTINATION2=${DESTINATION_ID_LIST[1]}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${TELEMETRY_VAR_FOLDER}/telemetry_destination_configuration/delete_destination    ${mapping}    session
    Verify_Response_As_Json_Templated    ${resp}    ${TELEMETRY_VAR_FOLDER}/response    success_response

TC2_Query Destination
    [Documentation]    Query the destination created in the datastore.
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${TELEMETRY_VAR_FOLDER}/telemetry_destination_configuration/query_destination    {}    session    True

TC3_Configure Subscription
    [Documentation]    Configure one node with two subscriptions with subscription id list ${SUBSCRIPTION_ID_LIST}, a series of parameters, and sensor destination configured in front.
    ${mapping}    Create Dictionary    NODE1=${NODE_ID_LIST[0]}    SUBSCRIPTION1=${SUBSCRIPTION_ID_LIST[0]}    PROTOCOLTYPE1=${PROTOCOL_TYPE_LIST[1]}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${TELEMETRY_VAR_FOLDER}/telemetry_subscription_configuration/configure_subscription    ${mapping}    session
    Verify_Response_As_Json_Templated    ${resp}    ${TELEMETRY_VAR_FOLDER}/response    success_response

TC3_Delete Subscription
    [Documentation]    Delete the second subscription created in the test case TC3_Configure Subscription.
    ${mapping}    Create Dictionary    NODE1=${NODE_ID_LIST[0]}    SUBSCRIPTION2=${SUBSCRIPTION_ID_LIST[1]}
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${TELEMETRY_VAR_FOLDER}/telemetry_subscription_configuration/delete_subscription    ${mapping}    session
    Verify_Response_As_Json_Templated    ${resp}    ${TELEMETRY_VAR_FOLDER}/response    success_response

TC3_Query Subscription
    [Documentation]    Query the subscription created in the datastore.
    ${resp}    TemplatedRequests.Post_As_Json_Templated    ${TELEMETRY_VAR_FOLDER}/telemetry_subscription_configuration/query_subscription    {}    session    True

*** Settings ***
Documentation     Keywords for sanity test suites testing basic functionality
...               using multiple communication protocols
Library           Collections
Resource          ../../variables/Variables.robot
Resource          IoTDMKeywords.robot
Library           iotdm_comm.py
Library           criotdm.py
Library           OperatingSystem
Variables         client_libs/onem2m_primitive.py

*** Keywords ***
Sanity Test Create AE
    [Documentation]    Create AE resource and verify response
    ${attr} =    Set Variable    {"m2m:ae": {"api":"jb","apn":"jb2","or":"http://hey/you","rr":true}}
    ${primitive} =    New Create Request Primitive    InCSE1    ${attr}    ${OneM2M.resource_type_application_entity}
    ${rsp_primitive} =    Send Primitive    ${primitive}
    Verify Exchange    ${primitive}    ${rsp_primitive}

Sanity Test Retrieve AE
    [Documentation]    Retrieve AE resource and verify response
    ${primitive} =    New Retrieve Request Primitive    InCSE1/robotTestAe
    ${rsp_primitive} =    Send Primitive    ${primitive}
    Verify Exchange    ${primitive}    ${rsp_primitive}

Sanity Test Update AE
    [Documentation]    Update AE resource and verify response
    ${attr} =    Set Variable    {"m2m:ae": {"or":"http://hey/you/updated"}}
    ${primitive} =    New Update Request Primitive    InCSE1/robotTestAe    ${attr}
    ${rsp_primitive} =    Send Primitive    ${primitive}
    Verify Exchange    ${primitive}    ${rsp_primitive}

Sanity Test Retrieve Updated AE
    [Documentation]    Retrieve updated AE, verify updated element and verify response
    ${primitive} =    New Retrieve Request Primitive    InCSE1/robotTestAe
    ${rsp_primitive} =    Send Primitive    ${primitive}
    Verify Exchange    ${primitive}    ${rsp_primitive}
    ${update_or} =    Get Primitive Content Attribute    ${rsp_primitive}    /m2m:ae/or
    Should Be Equal    ${update_or}    http://hey/you/updated

Sanity Test Delete AE
    [Documentation]    Delete AE resource and verify response
    ${primitive} =    New Delete Request Primitive    InCSE1/robotTestAe
    ${rsp_primitive} =    Send Primitive    ${primitive}
    Verify Exchange    ${primitive}    ${rsp_primitive}

Sanity Test Retrieve Deleted AE
    [Documentation]    Try to retrieve already deleted AE. Expect and verify error response
    ${primitive} =    New Retrieve Request Primitive    InCSE1/robotTestAe
    ${rsp_primitive} =    Send Primitive    ${primitive}
    ${expected_message} =    Set Variable    Resource target URI not found: InCSE1/robotTestAe
    Verify Exchange Negative    ${primitive}    ${rsp_primitive}    ${OneM2M.result_code_not_found}    ${expected_message}

Sanity Test Create AE Container Subscription
    [Arguments]    ${notification_uri}
    [Documentation]    Create AE, Container and Subscription resources. Subscription resource has set
    ...    eventType 3 so notification will be trigerred when child resource of Container resource is
    ...    created. Notifications will be sent to communication Rx channel.
    ...    Verify response of create requests.
    ${attr} =    Set Variable    {"m2m:ae": {"api":"jb","apn":"jb2","or":"http://hey/you","rr":true}}
    ${primitive} =    New Create Request Primitive    InCSE1    ${attr}    ${OneM2M.resource_type_application_entity}
    ${rsp_primitive} =    Send Primitive    ${primitive}
    Verify Exchange    ${primitive}    ${rsp_primitive}
    ${empty_content}    Set Variable    {"m2m:cnt": {"rn": "Container1"}}
    ${primitive} =    New Create Request Primitive    InCSE1/robotTestAe    ${empty_content}    ${OneM2M.resource_type_container}
    ${rsp_primitive} =    Send Primitive    ${primitive}
    ${status_code} =    Get Primitive Param    ${rsp_primitive}    ${OneM2M.short_response_status_code}
    ${content} =    Get Primitive Content    ${rsp_primitive}
    ${debug} =    Catenate    Status code:    ${status_code}    Content:    ${content}
    Log    ${debug}
    Verify Exchange    ${primitive}    ${rsp_primitive}
    # Setup automatic responses due to BUG: https://bugs.opendaylight.org/show_bug.cgi?id=7971
    Add Notification Auto Reply On Subscription Create
    ${attr}    Set Variable    {"m2m:sub":{"nu":["${notification_uri}"],"nct": 3,"rn":"TestSubscription", "enc":{"net":[3]}}}
    ${primitive} =    New Create Request Primitive    InCSE1/robotTestAe/Container1    ${attr}    ${OneM2M.resource_type_subscription}
    ${rsp_primitive} =    Send Primitive    ${primitive}
    ${status_code} =    Get Primitive Param    ${rsp_primitive}    ${OneM2M.short_response_status_code}
    ${content} =    Get Primitive Content    ${rsp_primitive}
    ${debug} =    Catenate    Status code:    ${status_code}    Content:    ${content}
    Log    ${debug}
    Verify Exchange    ${primitive}    ${rsp_primitive}
    Wait Until Keyword Succeeds    3x    100ms    Verify Number Of Auto Replies On Subscription Create    ${1}
    Remove Notification Auto Reply On Subscription Create

Sanity Test Create Content Instance And Handle Notification
    [Documentation]    Create contentInstance resource what should trigger notification. Receive the notification
    ...    and create positive response and send. Verify the received notification request.
    Create Content Instance
    ${notification} =    Receive Notification And Verify
    # response must be sent becaue Rx is waiting for the response and Rx thread is blocked
    ${notification_rsp} =    Create Notification Response    ${notification}
    Respond Response Primitive    ${notification_rsp}
    Verify Exchange    ${notification}    ${notification_rsp}

Sanity Test Create Content Instance And Use Automatic Notification Response
    [Documentation]    Set up automatic reply for notifications from specific subscription resource. Create
    ...    contentInstance resource what will trigger the notification and check if was handled
    ...    automatically.
    ${subscription_resource_id}    Set Variable    InCSE1/robotTestAe/Container1/TestSubscription
    Add Auto Reply To Notification From Subscription    ${subscription_resource_id}
    Create Content Instance
    Wait Until Keyword Succeeds    3x    100ms    Verify Number Of Auto Replies To Notification From Subscription    ${subscription_resource_id}    ${1}
    Remove Auto Reply To Notification From Subscription    ${subscription_resource_id}

Create Content Instance
    ${attr}    Set Variable    {"m2m:cin":{"con":"testingContentValue"}}
    ${primitive} =    New Create Request Primitive    InCSE1/robotTestAe/Container1    ${attr}    ${OneM2M.resource_type_content_instance}
    ${rsp_primitive} =    Send Primitive    ${primitive}
    ${status_code} =    Get Primitive Param    ${rsp_primitive}    ${OneM2M.short_response_status_code}
    ${content} =    Get Primitive Content    ${rsp_primitive}
    ${debug} =    Catenate    Status code:    ${status_code}    Content:    ${content}
    Log    ${debug}
    Verify Exchange    ${primitive}    ${rsp_primitive}

Receive Notification And Verify
    ${notification} =    Receive Request Primitive
    Verify Request    ${notification}
    ${from} =    Get Primitive Param    ${notification}    ${OneM2M.short_from}
    Should Be Equal    ${from}    /InCSE1
    ${operation} =    Get Primitive Param    ${notification}    ${OneM2M.short_operation}
    Should Be Equal As Integers    ${operation}    ${OneM2M.operation_notify}
    Return From Keyword    ${notification}

Resolve Local Ip Address
    ${ip_list}    OperatingSystem.Run    hostname -I
    Log    iotdm_ip: ${ODL_SYSTEM_1_IP}
    Log    hostname -I: ${ip_list}
    ${local_ip} =    Get Local Ip From List    ${ODL_SYSTEM_1_IP}    ${ip_list}
    Set Global Variable    ${local_ip}
    Log    local_ip: ${local_ip}

Connect And Provision cseBase
    [Documentation]    Connects to IoTDM RESTCONF interface and provisions cseBase resource InCSE1
    Connect To Iotdm    ${ODL_SYSTEM_1_IP}    ${ODL_RESTCONF_USER}    ${ODL_RESTCONF_PASSWORD}

Clear The Resource Tree
    [Documentation]    Connects to IoTDM RESTCONF interface and clears whole resource tree
    Kill The Tree    ${ODL_SYSTEM_1_IP}    InCSE1    ${ODL_RESTCONF_USER}    ${ODL_RESTCONF_PASSWORD}

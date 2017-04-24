*** Settings ***
Documentation     Keywords for sanity test suites testing basic functionality
...               using multiple communication protocols
Library           Collections
Resource          ../../variables/Variables.robot
Resource          IoTDMKeywords.robot
Resource          IoTDMResources.robot
Library           iotdm_comm.py
Library           OperatingSystem
Variables         client_libs/onem2m_primitive.py

*** Keywords ***
Sanity Test Create AE
    [Documentation]    Create AE resource and verify response
    Create Resource AE

Sanity Test Retrieve AE
    [Documentation]    Retrieve AE resource and verify response
    Retrieve Resource    ${defAeUri}

Sanity Test Update AE
    [Documentation]    Update AE resource and verify response
    ${attr} =    Set Variable    {"m2m:ae": {"or":"http://hey/you/updated"}}
    Update Resource    ${attr}    ${defAeUri}

Sanity Test Retrieve Updated AE
    [Documentation]    Retrieve updated AE, verify updated element and verify response
    ${rsp_primitive}    Retrieve Resource    ${defAeUri}
    ${update_or} =    Get Primitive Content Attribute    ${rsp_primitive}    /m2m:ae/or
    Should Be Equal    ${update_or}    http://hey/you/updated

Sanity Test Delete AE
    [Documentation]    Delete AE resource and verify response
    Delete Resource    ${defAeUri}

Sanity Test Retrieve Deleted AE
    [Documentation]    Try to retrieve already deleted AE. Expect and verify error response
    ${primitive} =    New Retrieve Request Primitive    ${defAeUri}
    Log Primitive    ${primitive}
    ${rsp_primitive} =    Send Primitive    ${primitive}
    Log Primitive    ${rsp_primitive}
    ${expected_message} =    Set Variable    Resource target URI not found: ${defAeUri}
    Verify Exchange Negative    ${primitive}    ${rsp_primitive}    ${OneM2M.result_code_not_found}    ${expected_message}

Sanity Test Create AE Container Subscription
    [Arguments]    ${notification_uri}
    [Documentation]    Create AE, Container and Subscription resources. Subscription resource has set
    ...    eventType 3 so notification will be trigerred when child resource of Container resource is
    ...    created. Notifications will be sent to communication Rx channel.
    ...    Verify response of create requests.
    Sanity Test Create AE
    Create Resource Container    ${defAeUri}    Container1
    Create Resource Subscription    ${defAeUri}/Container1    ${notification_uri}    notifEventType=${OneM2M.net_create_of_direct_child_resource}    notifContentType=${OneM2M.nct_resource_id}
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
    ${subscription_resource_id}    Set Variable    ${defAeUri}/Container1/${defSubscriptionName}
    Add Auto Reply To Notification From Subscription    ${subscription_resource_id}
    Create Content Instance
    Wait Until Keyword Succeeds    3x    100ms    Verify Number Of Auto Replies To Notification From Subscription    ${subscription_resource_id}    ${1}
    Remove Auto Reply To Notification From Subscription    ${subscription_resource_id}

Create Content Instance
    Create Resource ContentInstance    contentValue=testingContentValue    parentResourceUri=${defAeUri}/Container1

Receive Notification And Verify
    ${notification} =    Receive Request Primitive
    Verify Request    ${notification}
    ${from} =    Get Primitive Param    ${notification}    ${OneM2M.short_from}
    Should Be Equal    ${from}    /${defCseBaseName}
    ${operation} =    Get Primitive Param    ${notification}    ${OneM2M.short_operation}
    Should Be Equal As Integers    ${operation}    ${OneM2M.operation_notify}
    Return From Keyword    ${notification}

*** Settings ***
Documentation     Sanity test suite verifies basic functionality of IoTDM but also
...               functionality of testing client libraries.
...               CRUD + N operations are performed on minimal resource tree using HTTP protocol.
Suite Setup       Setup Suite
Suite Teardown    End Suite
Resource          ../../../libraries/IoTDM/iotdm_sanity_tests.robot

*** Variables ***
${rx_port}        ${5000}

*** Test Cases ***
1.01 HTTP Sanity test - Create AE
    [Documentation]    Create AE resource and verify response
    Sanity Test Create AE

1.02 HTTP Sanity test - Retrieve AE
    [Documentation]    Retrieve AE resource and verify response
    Sanity Test Retrieve AE

1.03 HTTP Sanity test - Update AE
    [Documentation]    Update AE resource and verify response
    Sanity Test Update AE

1.04 HTTP Sanity test - Retrieve updated AE
    [Documentation]    Retrieve updated AE, verify updated element and verify response
    Sanity Test Retrieve Updated AE

1.05 HTTP Sanity test - Delete AE
    [Documentation]    Delete AE resource and verify response
    Sanity Test Delete AE

1.06 HTTP Sanity test - Retrieve deleted AE
    [Documentation]    Try to retrieve already deleted AE. Expect and verify error response
    Sanity Test Retrieve Deleted AE

1.07 HTTP Sanity test - Create AE, Container and Subscription
    [Documentation]    Create AE, Container and Subscription resources. Subscription resource has set
    ...    eventType 3 so notification will be trigerred when child resource of Container resource is
    ...    created. Notifications will be sent to communication Rx channel.
    ...    Verify response of create requests.
    Sanity Test Create AE Container Subscription    http://${local_ip}:${rx_port}

1.08 HTTP Sanity test - Create Content Instance and handle notification
    [Documentation]    Create contentInstance resource what should trigger notification. Receive the notification
    ...    and create positive response and send. Verify the received notification request.
    Sanity Test Create Content Instance And Handle Notification

1.09 HTTP Sanity test - Create Content Instance and use automatic notification response
    [Documentation]    Set up automatic reply for notifications from specific subscription resource. Create
    ...    contentInstance resource what will trigger the notification and check if was handled
    ...    automatically.
    Sanity Test Create Content Instance And Use Automatic Notification Response

*** Keywords ***
Setup Suite
    [Documentation]    Connect to IoTDM and prepare testing resource tree
    IOTDM Basic Suite Setup    ${ODL_SYSTEM_1_IP}    ${ODL_RESTCONF_USER}    ${ODL_RESTCONF_PASSWORD}
    Connect And Provision cseBase
    Create Iotdm Http Connection    robotTestAe    ${ODL_SYSTEM_1_IP}    8282    application/json    ${rx_port}
    Resolve Local Ip Address

End Suite
    Clear The Resource Tree
    Close Iotdm Communication

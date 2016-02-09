*** Settings ***
Documentation     Test suite for all Uni Manager operations
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           String
Library           Collections
Library           SSHLibrary
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot

*** Variables ***
${DEFAULT_LINUX_PROMPT}
${mininet1_IP}    192.168.1.139
${mininet2_IP}    192.168.1.106
${UNI1_MAC}    68:5b:35:bb:f8:3e
${UNI2_MAC}    52:7b:25:cb:a7:3c
${OVS_PORT}     6640

*** Test Cases ***
Make the OVS instance listen to a passive connection
    [Documentation]    connect to the ovs instances then delete and set the ovs manager
    [Tags]    UniMgr Mininet Manager
    Run Command On Remote System    ${mininet1_IP}    sudo ovs-vsctl del-manager    mininet     mininet
    Run Command On Remote System    ${mininet1_IP}    sudo ovs-vsctl set-manager ptcp:${OVS_PORT}        mininet     mininet
    ${stdout}=    Run Command On Remote System    ${mininet1_IP}    sudo ovs-vsctl show    mininet     mininet
    Should Contain     ${stdout}    "ptcp:${OVS_PORT}"
    Run Command On Remote System    ${mininet2_IP}    sudo ovs-vsctl del-manager    mininet     mininet
    Run Command On Remote System    ${mininet2_IP}    sudo ovs-vsctl set-manager ptcp:${OVS_PORT}    mininet     mininet
    ${stdout}=    Run Command On Remote System    ${mininet2_IP}    sudo ovs-vsctl show    mininet     mininet
    Should Contain     ${stdout}    "ptcp:${OVS_PORT}"

Create source and destination UNIs at the OVS instances using Restconf API
    [Documentation]    Create source and destination UNIs
    [Tags]    UniMgr UNIs Create
    ${uni}=    Issue Command On Karaf Console    uni-add -ip ${mininet1_IP} -ma ${UNI1_MAC}
    Should Contain     ${uni}    ${mininet1_IP} created
    ${uni}=    Issue Command On Karaf Console    uni-add -ip ${mininet2_IP} -ma ${UNI2_MAC}
    Should Contain     ${uni}    ${mininet2_IP} created

Show UNI
    [Documentation]    Show the information of the created Unis
    [Tags]    UniMgr

List All UNIs
    [Documentation]    List all exist UNIs
    [Tags]    UniMgr


Update the Unis Speed
    [Documentation]    Update Created Unis speed
    [Tags]    UniMgr


Create EVC connection between the Unis
    [Documentation]    Create Evc connection between Unis
    [Tags]    UniMgr EVC Speed


Delete EVC tunnel between the Unis
    [Documentation]    Delete EVC
    [Tags]    UniMgr EVC Delete


Delete UNIs source and destination
    [Documentation]    Delete both UNIs source and destination
    [Tags]    UniMgr UNI Delete

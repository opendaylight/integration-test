*** Settings ***
Documentation       Test suite for NETCONF client
...                 FIXME: this test suite is based on the config subsystem, which has been long gone, and currently
...                 it is not used.

Library             Collections
Library             OperatingSystem
Library             RequestsLibrary
Library             String
Library             ../../../libraries/Common.py
Variables           ../../../variables/Variables.py

Suite Setup         Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown      Delete All Sessions


*** Variables ***
${NETOPEER}                 ${TOOLS_SYSTEM_IP}
${NETOPEER_USER}            ${TOOLS_SYSTEM_USER}
${FILE}                     ${CURDIR}/../../../variables/xmls/netconf.xml
${REST_TOPOLOGY_NETCONF}    /rests/data/network-topology:network-topology/topology=topology-netconf
${REST_NTPR_CONF}           node=controller-config/yang-ext:mount/config:modules
${REST_NTPR_MOUNT}          node=netopeer/yang-ext:mount


*** Test Cases ***
Add NetConf device
    [Documentation]    Add NetConf device using REST
    [Tags]    netconf
    ${XML1}    Get File    ${FILE}
    ${XML2}    Replace String    ${XML1}    127.0.0.1    ${NETOPEER}
    ${body}    Replace String    ${XML2}    mininet    ${NETOPEER_USER}
    Log    ${body}
    ${resp}    POST On Session
    ...    session
    ...    url=${REST_TOPOLOGY_NETCONF}/${REST_NTPR_CONF}
    ...    data=${body}
    ...    expected_status=204
    Log    ${resp.content}

Get Controller Inventory
    [Documentation]    Get Controller operational inventory
    [Tags]    netconf
    Wait Until Keyword Succeeds    30s    2s    Get Inventory

Pull External Device configuration
    [Documentation]    Pull Netopeer configuration
    [Tags]    netconf
    ${resp}    GET On Session
    ...    session
    ...    url=${REST_TOPOLOGY_NETCONF}/${REST_NTPR_MOUNT}?content=config
    ...    expected_status=200
    Log    ${resp.content}
    Should Contain    ${resp.content}    {}

Verify Device Operational data
    [Documentation]    Verify Netopeer operational data
    [Tags]    exclude
    ${resp}    GET On Session
    ...    session
    ...    url=${REST_TOPOLOGY_NETCONF}/${REST_NTPR_MOUNT}?content=nonconfig
    ...    expected_status=200
    Log    ${resp.content}
    Should Contain    ${resp.content}    schema
    Should Contain    ${resp.content}    statistics
    Should Contain    ${resp.content}    datastores


*** Keywords ***
Get Inventory
    ${resp}    GET On Session
    ...    session
    ...    url=${REST_TOPOLOGY_NETCONF}/node=netopeer?content=nonconfig
    ...    expected_status=200
    Log    ${resp.content}
    Should Contain    ${resp.content}    "node-id":"netopeer"
    Should Contain    ${resp.content}    "netconf-node-topology:connection-status":"connected"
    Should Contain    ${resp.content}    "netconf-node-topology:available-capabilities"

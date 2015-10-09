*** Settings ***
Documentation     Test suite for NETCONF client
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           Collections
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py

*** Variables ***
${NETOPEER}       ${MININET}
${NETOPEER_USER}    ${MININET_USER}
${FILE}           ${CURDIR}/../../../variables/xmls/netconf.xml
${REST_CONT_CONF}    /restconf/config/network-topology:network-topology/topology/topology-netconf
${REST_CONT_OPER}    /restconf/operational/network-topology:network-topology/topology/topology-netconf
${REST_NTPR_CONF}    node/controller-config/yang-ext:mount/config:modules
${REST_NTPR_MOUNT}    node/netopeer/yang-ext:mount/

*** Test Cases ***
Add NetConf device
    [Documentation]    Add NetConf device using REST
    [Tags]    netconf
    ${XML1}    Get File    ${FILE}
    ${XML2}    Replace String    ${XML1}    127.0.0.1    ${NETOPEER}
    ${body}    Replace String    ${XML2}    mininet    ${NETOPEER_USER}
    Log    ${body}
    ${resp}    Post    session    ${REST_CONT_CONF}/${REST_NTPR_CONF}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204

Get Controller Inventory
    [Documentation]    Get Controller operational inventory
    [Tags]    netconf
    Wait Until Keyword Succeeds    30s    2s    Get Inventory

Pull External Device configuration
    [Documentation]    Pull Netopeer configuration
    [Tags]    netconf
    ${resp}    Get    session    ${REST_CONT_CONF}/${REST_NTPR_MOUNT}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    {}

Verify Device Operational data
    [Documentation]    Verify Netopeer operational data
    [Tags]    exclude
    ${resp}    Get    session    ${REST_CONT_OPER}/${REST_NTPR_MOUNT}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    schema
    Should Contain    ${resp.content}    statistics
    Should Contain    ${resp.content}    datastores

*** Keywords ***
Get Inventory
    ${resp}    Get    session    ${REST_CONT_OPER}/node/netopeer
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    "node-id":"netopeer"
    Should Contain    ${resp.content}    "netconf-node-topology:connection-status":"connected"
    Should Contain    ${resp.content}    "netconf-node-topology:available-capabilities"

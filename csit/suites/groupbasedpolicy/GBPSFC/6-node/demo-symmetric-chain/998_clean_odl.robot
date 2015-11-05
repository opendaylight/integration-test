*** Settings ***
Documentation     Test suite for cleaning up / unregister infrastructure constructs like endpoints for demo-symmetric-chain
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           OperatingSystem
Library           Collections
Library           json
Variables         ../../../../../variables/Variables.py
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/RestconfUtils.robot

*** Variables ***

${GBP_TENENT_ID}           f5c7d344-d1c7-4208-8531-2c2693657e12
${TENANT_PATH}             /restconf/config/policy:tenants/tenant/${GBP_TENENT_ID}
${TUNNELS_PATH}            /restconf/config/opendaylight-inventory:nodes

${OPER_ENDPOINTS_PATH}     /restconf/operational/endpoint:endpoints
${UNREG_ENDPOINTS_PATH}    /restconf/operations/endpoint:unregister-endpoint

${SF_PATH}                 /restconf/config/service-function:service-functions
${SFF_PATH}                /restconf/config/service-function-forwarder:service-function-forwarders
${SFC_PATH}                /restconf/config/service-function-chain:service-function-chains
${SFP_PATH}                /restconf/config/service-function-path:service-function-paths

${TOPOLOGY_PATH}           /restconf/config/network-topology:network-topology/topology/ovsdb:1
${OPER_NODES}              /restconf/operational/opendaylight-inventory:nodes/

${NODES_GBPSFC1}         /restconf/config/opendaylight-inventory:nodes/node/openflow:1
${NODES_GBPSFC2}         /restconf/config/opendaylight-inventory:nodes/node/openflow:2

*** Test Cases ***

Delete Service Function Paths
    [Documentation]    Delete Service Function Paths from ODL
    [Tags]    GBPSFCTEAR
    Remove All Elements At URI And Verify    ${SFP_PATH}
    Sleep    30s
Delete Service Function Chains
    [Documentation]    Delete Service Function Chains from ODL
    [Tags]    GBPSFCTEAR
    Remove All Elements At URI And Verify    ${SFC_PATH}
    Sleep    30s

Delete Service Functions
    [Documentation]    Delete Service Function from ODL
    [Tags]    GBPSFCTEAR
    Remove All Elements At URI And Verify    ${SF_PATH}
    Sleep    30s
Delete Service Function Forwarders
    [Documentation]    Delete Service Function Forwarders from ODL
    [Tags]    GBPSFCTEAR
    Remove All Elements At URI And Verify    ${SFF_PATH}
    Sleep    30s
Delete Tunnels
    [Documentation]    Delete Tenant from ODL
    [Tags]    GBPSFCTEAR
    Remove All Elements At URI And Verify    ${NODES_GBPSFC1}
    Remove All Elements At URI And Verify    ${NODES_GBPSFC2}
    Sleep    30s

Delete Tenant
    [Documentation]    Delete Tenant from ODL
    [Tags]    GBPSFCTEAR
    Remove All Elements At URI And Verify    ${TENANT_PATH}
    Sleep    30s

Unregister Endpoints
    [Documentation]    Unregister Endpoints Endpoints from ODL
    [Tags]    GBPSFCTEAR
    Unregister Endpoints    ${OPER_ENDPOINTS_PATH}
    Sleep    30s
Delete OVSDB Topology If Present
    [Documentation]    Delete Tenant from ODL
    [Tags]    GBPSFCTEAR
    ${resp}    RequestsLibrary.Get    session    ${TOPOLOGY_PATH}
    Run Keyword If    ${resp.status_code} == 200
    ...    Remove All Elements At URI And Verify    ${TOPOLOGY_PATH}
    Sleep    30s
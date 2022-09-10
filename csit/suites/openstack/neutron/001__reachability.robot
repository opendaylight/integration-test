*** Settings ***
Library             RequestsLibrary
Resource            ../../../variables/Variables.robot

Suite Setup         Create Session    ODL    http://${ODL_SYSTEM_IP}:${PORT}    headers=${HEADERS}    auth=${AUTH}
Suite Teardown      Delete All Sessions


*** Test Cases ***
Get the complete list of networks
    [Documentation]    Get the complete list of networks
    [Tags]    reachability
    ${resp}    get request    ODL    ${NEUTRON_NETWORKS_API}
    Should be Equal As Strings    ${resp.status_code}    200

Get the complete list of subnets
    [Documentation]    Get the complete list of subnets
    [Tags]    reachability
    ${resp}    get request    ODL    ${NEUTRON_SUBNETS_API}
    Should be Equal As Strings    ${resp.status_code}    200

Get the complete list of ports
    [Documentation]    Get the complete list of ports
    [Tags]    reachability
    ${resp}    get request    ODL    ${NEUTRON_PORTS_API}
    Should be Equal As Strings    ${resp.status_code}    200

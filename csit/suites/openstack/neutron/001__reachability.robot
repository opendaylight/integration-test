*** Variables ***
${NeutronNorthbound}    /controller/nb/v2/neutron
${NetworkNorthbound}    ${NeutronNorthbound}/networks
${SubnetNorthbound}     ${NeutronNorthbound}/subnets
${PortNorthbound}       ${NeutronNorthbound}/ports

*** Settings ***
Suite Setup       Create Session    ODL    http://${ODL_SYSTEM_IP}:${PORT}    headers=${HEADERS}    auth=${AUTH}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Variables         ../../../variables/Variables.py

*** Test Cases ***
Get the complete list of networks
    [Documentation]    Get the complete list of networks
    [Tags]    reachability
    ${resp}   get request    ODL    ${NetworkNorthbound}
    Should be Equal As Strings    ${resp.status_code}    200

Get the complete list of subnets
    [Documentation]    Get the complete list of subnets
    [Tags]    reachability
    ${resp}   get request    ODL    ${SubnetNorthbound}
    Should be Equal As Strings    ${resp.status_code}    200

Get the complete list of ports
    [Documentation]    Get the complete list of ports
    [Tags]    reachability
    ${resp}   get request    ODL    ${PortNorthbound}
    Should be Equal As Strings    ${resp.status_code}    200

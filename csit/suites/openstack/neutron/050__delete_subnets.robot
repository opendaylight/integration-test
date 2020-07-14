*** Settings ***
Documentation     Checking Subnets deleted in OpenStack are deleted also in OpenDaylight
Suite Setup       Start Suite
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../variables/Variables.robot

*** Variables ***
${OSREST}         /v2.0/subnets/${SUBNETID}
${data}           {"subnet":{"network_id":"${NETID}","ip_version":4,"cidr":"172.16.64.0/24","allocation_pools":[{"start":"172.16.64.20","end":"172.16.64.120"}]}}

*** Test Cases ***
Delete New subnet
    [Documentation]    Delete previously created subnet in OpenStack
    [Tags]    Delete Subnet OpenStack Neutron
    Log    ${data}
    ${resp}    delete request    OSSession    ${OSREST}
    Should be Equal As Strings    ${resp.status_code}    204
    Log    ${resp.text}
    sleep    2

Check New subnet deleted
    [Documentation]    Check subnet deleted in OpenDaylight
    [Tags]    Check subnet deleted OpenDaylight
    ${resp}    get request    ODLSession    ${NEUTRON_SUBNETS_API}
    Should be Equal As Strings    ${resp.status_code}    200
    ${ODLResult}    To Json    ${resp.text}
    Log    ${ODLResult}
    ${resp}    get request    ODLSession    ${NEUTRON_SUBNETS_API}/${SUBNETID}
    Should be Equal As Strings    ${resp.status_code}    404

*** Keywords ***
Check Subnet Exists
    [Arguments]    ${subnetid}
    ${resp}    get request    ODLSession    ${NEUTRON_SUBNETS_API}/${subnetid}
    Should be Equal As Strings    ${resp.status_code}    200

Start Suite
    Create Session    OSSession    ${NEUTRONURL}    headers=${X-AUTH-NOCONTENT}
    Create Session    ODLSession    http://${ODL_SYSTEM_IP}:${PORT}    headers=${HEADERS}    auth=${AUTH}
    Check Subnet Exists    ${SUBNETID}

*** Settings ***
Documentation     Checking Subnets deleted in OpenStack are deleted also in OpenDaylight
Suite Setup       Start Suite
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Variables         ../../../variables/Variables.py

*** Variables ***
${ODLREST}       /controller/nb/v2/neutron/subnets
${OSREST}        /v2.0/subnets/${SUBNETID}
${data}          {"subnet":{"network_id":"${NETID}","ip_version":4,"cidr":"172.16.64.0/24","allocation_pools":[{"start":"172.16.64.20","end":"172.16.64.120"}]}}

*** Test Cases ***
Delete New subnet
    [Documentation]    Delete previously created subnet in OpenStack
    [Tags]    Delete Subnet OpenStack Neutron
    Log    ${data}
    ${resp}    delete request    OSSession    ${OSREST}
    Should be Equal As Strings    ${resp.status_code}    204
    Log    ${resp.content}
    sleep    2

Check New subnet deleted
    [Documentation]    Check subnet deleted in OpenDaylight
    [Tags]    Check subnet deleted OpenDaylight
    ${resp}    get request    ODLSession    ${ODLREST}
    Should be Equal As Strings    ${resp.status_code}    200
    ${ODLResult}    To Json    ${resp.content}
    Log    ${ODLResult}
    ${resp}    get request    ODLSession    ${ODLREST}/${SUBNETID}
    Should be Equal As Strings    ${resp.status_code}    404

*** Keywords ***
Check Subnet Exists
    [Arguments]    ${subnetid}
    ${resp}    get request    ODLSession    ${ODLREST}/${subnetid}
    Should be Equal As Strings    ${resp.status_code}    200

Start Suite
    Create Session    OSSession    http://${NEUTRON}:9696    headers=${X-AUTH}
    Create Session    ODLSession    http://${ODL_SYSTEM_IP}:${PORT}    headers=${HEADERS}    auth=${AUTH}
    Check Subnet Exists    ${SUBNETID}

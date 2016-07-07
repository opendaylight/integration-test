*** Settings ***
Documentation     Test suite for Neutron Plugin
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py

*** Variables ***
${OSTENANTNAME}   "admin"
${OSUSERNAME}     "admin"
${OSPASSWORD}     "admin"
${UserInfo}       {"auth": {"tenantName": ${OSTENANTNAME}, "passwordCredentials": {"username": ${OSUSERNAME}, "password": ${OSPASSWORD}}}}

*** Keywords ***
Start Suite
    Create Session    KeyStoneSession    http://${OPENSTACK}:5000    headers=${HEADERS}
    ${resp}    post    KeyStoneSession    /v2.0/tokens    ${UserInfo}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${result}    Get From Dictionary    ${result}    access
    ${result}    Get From Dictionary    ${result}    token
    ${TOKEN}    Get From Dictionary    ${result}    id
    ${X-AUTH}    Create Dictionary    X-Auth-Token=${TOKEN}    Content-Type=application/json
    Set Global Variable    ${X-AUTH}

Stop Suite
    Delete All Sessions

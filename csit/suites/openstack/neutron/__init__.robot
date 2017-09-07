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
${OSTENANTNAME}    "admin"
${OSUSERNAME}     "admin"
${OSPASSWORD}     "admin"
${OSUSERDOMAINNAME}    "Default"
${OSPROJECTDOMAINNAME}    "Default"
${PASSWORD}       {"user":{"name":${OSUSERNAME},"domain":{"name": ${OSUSERDOMAINNAME}},"password":${OSPASSWORD}}}
${SCOPE}          {"project":{"name":${OSTENANTNAME},"domain":{"name": ${OSPROJECTDOMAINNAME}}}}
${UserInfo}       {"auth":{"identity":{"methods":["password"],"password":${PASSWORD}},"scope":${SCOPE}}}

*** Keywords ***
Start Suite
    Create Session    KeyStoneSession    http://${KEYSTONE}:5000    headers=${HEADERS}
    ${resp}    post    KeyStoneSession    /v3/auth/tokens    ${UserInfo}
    Should Be Equal As Strings    ${resp.status_code}    201
    ${TOKEN}    Get From Dictionary    ${resp.headers}    X-Subject-Token
    ${X-AUTH}    Create Dictionary    X-Auth-Token=${TOKEN}    Content-Type=application/json
    ${X-AUTH-NOCONTENT}    Create Dictionary    X-Auth-Token=${TOKEN}
    Set Global Variable    ${X-AUTH}
    Set Global Variable    ${X-AUTH-NOCONTENT}

Stop Suite
    Delete All Sessions

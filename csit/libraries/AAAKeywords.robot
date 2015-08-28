*** Settings ***
Library           RequestsLibrary
Variables         ../variables/Variables.py

*** Variables ***
${WORKSPACE}      /tmp
${BUNDLEFOLDER}    distribution-karaf-0.3.0-SNAPSHOT
${AUTHN_CFG_FILE}    ${WORKSPACE}/${BUNDLEFOLDER}/etc/org.opendaylight.aaa.authn.cfg
${CONTROLLER_USER}  ${MININET_USER}

*** Keywords ***
AAA Login
    [Arguments]    ${controller_ip}    ${auth_data}
    [Documentation]    Makes a POST REST call to the AUTH_TOKEN_API with the given auth_data and returns the response
    Create Session    ODL_SESSION    http://${controller_ip}:8181
    ${headers}=    Create Dictionary    Content-Type    application/x-www-form-urlencoded
    ${resp}=    RequestsLibrary.POST    ODL_SESSION    ${AUTH_TOKEN_API}    data=${auth_data}    headers=${headers}
    Delete All Sessions
    [Return]    ${resp}

Create Auth Data
    [Arguments]    ${user}=${USER}    ${password}=${PWD}    ${scope}=${SCOPE}    ${client_id}=${EMPTY}    ${client_secret}=${EMPTY}
    [Documentation]    returns a string in the direct authentacation format (e.g., grant_type=password&username=admin&password=admin).
    ...    It can also be passed scope, client_id and client_secret arguments for the case of client specific authorization
    ${data}=    Set Variable    grant_type=password&username=${user}&password=${password}&scope=${scope}
    ${data}=    Run Keyword If    "${client_id}" != "${EMPTY}"    Set Variable    ${data}&client_id=${client_id}    ELSE    Set Variable
    ...    ${data}
    ${data}=    Run Keyword If    "${client_secret}" != "${EMPTY}"    Set Variable    ${data}&client_secret=${client_secret}    ELSE    Set Variable
    ...    ${data}
    [Return]    ${data}

Disable Authentication On Controller
    [Arguments]    ${controller_ip}
    [Documentation]    Will disable token based authentication. Currently, that is done with a config file change
    SSHLibrary.Open Connection    ${controller_ip}
    Login With Public Key    ${CONTROLLER_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    ${cmd}=    Set Variable    sed -i 's/^authEnabled=.*$/authEnabled=false/g' ${AUTHN_CFG_FILE}
    SSHLibrary.Execute Command    ${cmd}
    SSHLibrary.Close Connection

Enable Authentication On Controller
    [Arguments]    ${controller_ip}
    [Documentation]    Will enable token based authentication. Currently, that is done with a config file change
    SSHLibrary.Open Connection    ${controller_ip}
    Login With Public Key    ${CONTROLLER_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    ${cmd}=    Set Variable    sed -i 's/^authEnabled=.*$/authEnabled=true/g' ${AUTHN_CFG_FILE}
    SSHLibrary.Execute Command    ${cmd}
    SSHLibrary.Close Connection

Get Auth Token
    [Arguments]    ${user}=${USER}    ${password}=${PWD}    ${scope}=${SCOPE}    ${client_id}=${EMPTY}    ${client_secret}=${EMPTY}
    [Documentation]    Wrapper used to login to controller and retrieve an auth token. Optional argumented available for client based credentials.
    ${auth_data}=    Create Auth Data    ${USER}    ${PWD}    ${scope}    ${client_id}    ${client_secret}
    ${resp}=    AAA Login    ${CONTROLLER}    ${auth_data}
    Should Be Equal As Strings    ${resp.status_code}    201
    ${auth_token}=    Extract Value From Content    ${resp.content}    /access_token    strip
    [Return]    ${auth_token}

Revoke Auth Token
    [Arguments]    ${token}
    [Documentation]    Requests the given token be revoked via POST to ${REVOKE_TOKEN_API}
    ${headers}=    Create Dictionary    Content-Type    application/x-www-form-urlencoded
    ${resp}=    RequestsLibrary.POST    ODL_SESSION    ${REVOKE_TOKEN_API}    data=${token}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    204

Validate Token Format
    [Arguments]    ${token}
    [Documentation]    Validates the given string is in the proper "token" format
    Should Match Regexp    ${token}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}

Get User From IDM DB
    [Documentation]    Will return user information. If no user id is passed, it will retrieve all users in DB
    [Arguments]    ${user_id}=${EMPTY}
    Create Session    httpbin    http://${CONTROLLER}:${RESTPORT}
    ${headers}=    Create Dictionary    Content-Type    application/x-www-form-urlencoded
    ${resp}=    RequestsLibrary.GET    httpbin    ${idmurl}/users/${user_id}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    [Return]    ${resp}

Create User
    [Documentation]    Will return user information. If no user id is passed, it will retrieve all users in DB
    [Arguments]    ${user_data}
    Create Session    httpbin    http://${CONTROLLER}:${RESTPORT}
    ${headers}=    Create Dictionary    Content-Type    application/json
    ${resp}=    RequestsLibrary.POST    httpbin    ${idmurl}/users    headers=${headers}    data=${user_data}
    Should Be Equal As Strings    ${resp.status_code}    201
    Log    ${resp.content}
    [Return]    ${resp}

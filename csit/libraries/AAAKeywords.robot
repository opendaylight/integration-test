*** Settings ***
Library     RequestsLibrary
Resource    ../variables/Variables.robot


*** Variables ***
${WORKSPACE}            /tmp
${AUTHN_CFG_FILE}       ${WORKSPACE}/${BUNDLEFOLDER}/etc/org.opendaylight.aaa.authn.cfg


*** Keywords ***
AAA Login
    [Documentation]    Makes a POST REST call to the AUTH_TOKEN_API with the given auth_data and returns the response
    [Arguments]    ${controller_ip}    ${auth_data}
    Create Session    ODL_SESSION    http://${controller_ip}:8181
    ${headers}=    Create Dictionary    Content-Type=application/x-www-form-urlencoded
    ${resp}=    RequestsLibrary.POST Request
    ...    ODL_SESSION
    ...    ${AUTH_TOKEN_API}
    ...    data=${auth_data}
    ...    headers=${headers}
    Delete All Sessions
    RETURN    ${resp}

Create Auth Data
    [Documentation]    returns a string in the direct authentacation format (e.g., grant_type=password&username=admin&password=admin).
    ...    It can also be passed scope, client_id and client_secret arguments for the case of client specific authorization
    [Arguments]    ${user}=${USER}    ${password}=${PWD}    ${scope}=${SCOPE}    ${client_id}=${EMPTY}    ${client_secret}=${EMPTY}
    ${data}=    Set Variable    grant_type=password&username=${user}&password=${password}&scope=${scope}
    IF    "${client_id}" != "${EMPTY}"
        ${data}=    Set Variable    ${data}&client_id=${client_id}
    ELSE
        ${data}=    Set Variable    ${data}
    END
    IF    "${client_secret}" != "${EMPTY}"
        ${data}=    Set Variable    ${data}&client_secret=${client_secret}
    ELSE
        ${data}=    Set Variable    ${data}
    END
    RETURN    ${data}

Disable Authentication On Controller
    [Documentation]    Will disable token based authentication. Currently, that is done with a config file change
    [Arguments]    ${controller_ip}
    SSHLibrary.Open Connection    ${controller_ip}
    Login With Public Key    ${ODL_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    ${cmd}=    Set Variable    sed -i 's/^authEnabled=.*$/authEnabled=false/g' ${AUTHN_CFG_FILE}
    SSHLibrary.Execute Command    ${cmd}
    SSHLibrary.Close Connection

Enable Authentication On Controller
    [Documentation]    Will enable token based authentication. Currently, that is done with a config file change
    [Arguments]    ${controller_ip}
    SSHLibrary.Open Connection    ${controller_ip}
    Login With Public Key    ${ODL_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    ${cmd}=    Set Variable    sed -i 's/^authEnabled=.*$/authEnabled=true/g' ${AUTHN_CFG_FILE}
    SSHLibrary.Execute Command    ${cmd}
    SSHLibrary.Close Connection

Get Auth Token
    [Documentation]    Wrapper used to login to controller and retrieve an auth token. Optional argumented available for client based credentials.
    [Arguments]    ${user}=${USER}    ${password}=${PWD}    ${scope}=${SCOPE}    ${client_id}=${EMPTY}    ${client_secret}=${EMPTY}
    ${auth_data}=    Create Auth Data    ${USER}    ${PWD}    ${scope}    ${client_id}    ${client_secret}
    ${resp}=    AAA Login    ${ODL_SYSTEM_IP}    ${auth_data}
    Should Be Equal As Strings    ${resp.status_code}    201
    ${auth_token}=    Extract Value From Content    ${resp.text}    'access_token'
    RETURN    ${auth_token}

Revoke Auth Token
    [Documentation]    Requests the given token be revoked via POST to ${REVOKE_TOKEN_API}
    [Arguments]    ${token}
    ${headers}=    Create Dictionary    Content-Type=application/x-www-form-urlencoded
    ${resp}=    RequestsLibrary.POST Request
    ...    ODL_SESSION
    ...    ${REVOKE_TOKEN_API}
    ...    data=${token}
    ...    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    204

Validate Token Format
    [Documentation]    Validates the given string is in the proper "token" format
    [Arguments]    ${token}
    Should Match Regexp    ${token}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}

Get User From IDM DB
    [Documentation]    Will return user information. If no user id is passed, it will retrieve all users in DB
    [Arguments]    ${user_id}=${EMPTY}
    Create Session    httpbin    http://${ODL_SYSTEM_IP}:${RESTPORT}
    ${headers}=    Create Dictionary    Content-Type=application/x-www-form-urlencoded
    ${resp}=    RequestsLibrary.GET Request    httpbin    ${idmurl}/users/${user_id}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.text}
    RETURN    ${resp}

Create User
    [Documentation]    Will return user information. If no user id is passed, it will retrieve all users in DB
    [Arguments]    ${user_data}
    Create Session    httpbin    http://${ODL_SYSTEM_IP}:${RESTPORT}
    ${headers}=    Create Dictionary    Content-Type=application/json
    ${resp}=    RequestsLibrary.POST Request    httpbin    ${idmurl}/users    headers=${headers}    data=${user_data}
    Should Be Equal As Strings    ${resp.status_code}    201
    Log    ${resp.text}
    RETURN    ${resp}

#
# Copyright (c) Lumina Networks 2020 and others.
# All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html
#

*** Settings ***
Documentation     Test Basic Authentication support in RESTCONF
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           String
Resource          ../../../variables/Variables.robot

*** Variables ***
${ADMIN_USER}     ${ODL_RESTCONF_USER}
${ADMIN_PW}       ${ODL_RESTCONF_PASSWORD}
${RESTCONF_TEST_URL}    ${MODULES_API}
${JOLOKIA_TEST_URL}    jolokia
${JOLOKIA_USER}    ${ODL_RESTCONF_USER}
${JOLOKIA_PW}     ${ODL_RESTCONF_PASSWORD}
${BAD_USER}       bad_user
${BAD_PW}         bad_pw
${JOLOKIA_BAD_USER}    ${BAD_USER}
${USERS_REST_URL}    auth/v1/users
${USER_USER}      user
${USER_PW}        user

*** Test Cases ***
No RESTCONF Credentials
    [Documentation]    Given no credentials GET RESTCONF fails
    Auth Should Fail    ${RESTCONF_TEST_URL}    ${EMPTY}    ${EMPTY}

Incorrect RESTCONF Password
    [Documentation]    Given incorrect password GET RESTCONF fails
    Auth Should Fail    ${RESTCONF_TEST_URL}    ${ADMIN_USER}    ${BAD_PW}

Incorrect RESTCONF Username
    [Documentation]    Given incorrect username GET RESTCONF fails
    Auth Should Fail    ${RESTCONF_TEST_URL}    ${BAD_USER}    ${ADMIN_PW}

Correct RESTCONF Credentials
    [Documentation]    Given correct credentials GET RESTCONF succeeds
    Auth Should Pass    ${RESTCONF_TEST_URL}    ${ADMIN_USER}    ${ADMIN_PW}

No Jolokia REST Credentials
    [Documentation]    Given no credentials, HTTP GET on a Jolokia endpoint fails
    Auth Should Fail    ${JOLOKIA_TEST_URL}    ${EMPTY}    ${EMPTY}

Incorrect Jolokia REST Password
    [Documentation]    Given incorrect password, GET on a Jolokia endpoint fails
    Auth Should Fail    ${JOLOKIA_TEST_URL}    ${JOLOKIA_USER}    ${BAD_PW}

Incorrect Jolokia REST Username
    [Documentation]    Given incorrect username, GET on a Jolokia endpoint fails
    Auth Should Fail    ${JOLOKIA_TEST_URL}    ${JOLOKIA_BAD_USER}    ${JOLOKIA_PW}

Correct Jolokia REST Credentials
    [Documentation]    Given correct credentials, GET on a Jolokia endpoint succeeds
    Auth Should Pass    ${JOLOKIA_TEST_URL}    ${JOLOKIA_USER}    ${JOLOKIA_PW}

IDM Endpoints Only Available To admin Role
    [Documentation]    A user with a non-"admin" role should not have access to AAA endpoints
    ${auth}    Create List    ${USER_USER}    ${USER_PW}
    Create Session    httpbin    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${auth}    headers=${HEADERS}
    ${resp} =    RequestsLibrary.GET On Session    httpbin    ${USERS_REST_URL}
    Should Be Equal As Numbers    ${resp.status_code}    401

*** Keywords ***
Auth Should Fail
    [Arguments]    ${url}    ${user}    ${password}
    [Documentation]    Checks the given HTTP RESTCONF response for authentication failure
    @{auth} =    Create List    ${user}    ${password}
    Create Session    httpbin    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${auth}    headers=${HEADERS}
    ${resp} =    RequestsLibrary.GET On Session    httpbin    ${url}
    Should Be Equal As Strings    ${resp.status_code}    401
    ${header_value} =    Convert To Uppercase    ${resp.headers}[www-authenticate]
    Should Contain    ${header_value}    BASIC
    Log    ${resp.content}

Auth Should Pass
    [Arguments]    ${url}    ${user}    ${password}
    [Documentation]    Checks the given HTTP RESTCONF response for authentication failure
    @{auth} =    Create List    ${user}    ${password}
    Create Session    httpbin    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${auth}    headers=${HEADERS}
    ${resp} =    RequestsLibrary.GET On Session    httpbin    ${url}
    Should Be Equal As Strings    ${resp.status_code}    200

*** Settings ***
Documentation     Test suite for legato topology of 1 switch
Suite Setup       Setup Test Environment
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/LegatoUtils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${UniMgr_variables_DIR}    ${CURDIR}/../../../variables/unimgr
${REST_CON}       /restconf/config/
${start}          sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo single,2 --switch ovsk,protocols=OpenFlow13

*** Test Cases ***
Check no connectivity before creating service
    [Documentation]    Verify packet loss before creating the service between h1 to h2
    Check No Ping

Create epl service
    [Documentation]    Create point to point service between the eth ports
    ${body}=    OperatingSystem.Get File    ${UniMgr_variables_DIR}/add_epl.json
    Sleep    20s
    ${resp}    RequestsLibrary.Put Request    session    ${REST_CON}mef-services:mef-services/    headers=${HEADERS_YANG_JSON}    data=${body}
    Log    ${resp.content}
    Sleep    20s
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Check ping after service creation
    [Documentation]    Verify ping between the hosts h1 - h2
    Check Ping

Delete epl service
    [Documentation]    Delete the evc point to point & verify no ping
    ${resp}    RequestsLibrary.Delete Request    session    ${REST_CON}mef-services:mef-services/    headers=${HEADERS_YANG_JSON}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Sleep    20s

Check no connectivity after deleting service
    [Documentation]    Verify no ping after deleteing the eplan service
    Check No Ping

*** Keywords ***
Setup Test Environment
    [Documentation]    Establish the Opendayligh session and prepair 1 Mininet VMs
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Utils.Start Suite    cmd=${start}

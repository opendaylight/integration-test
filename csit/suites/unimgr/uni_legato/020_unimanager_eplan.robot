*** Settings ***
Documentation     Test suite for legato topology of 1 switch
Suite Setup       Setup Test Environment
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/MininetKeyword.robot
Resource          ../../../libraries/TemplatedRequests.robot
Variables         ../../../variables/Variables.py
Variables         ../../../variables/Variables.robot

*** Variables ***
${UniMgr_variables_DIR}    ${CURDIR}/../../../variables/unimgr
${CONFIG_API}     /restconf/config/
${start}          sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo single,5 --switch ovsk,protocols=OpenFlow13

*** Test Cases ***
Check no connectivity before creating service
    [Documentation]    Verify packet loss before creating the service between h3 to h4
    Check No Ping    h3    h4

Create epl service
    [Documentation]    Create multi point to multi point service between the eth ports
    ${body}=    OperatingSystem.Get File    ${UniMgr_variables_DIR}/add_eplan.json
    ${resp}    RequestsLibrary.Put Request    session    ${REST_CON}mef-services:mef-services/    headers=${HEADERS_YANG_JSON}    data=${body}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${elements}    Create List    eth3    eth4    eth5
    Wait Until Keyword Succeeds    10s    6s    Check For Elements At URI    ${REST_CON}elan:elan-interfaces/    ${elements}

Check ping after service creation h3-h4
    [Documentation]    Verify ping between the hosts h3 - h4
    Check Ping    h3    h4

Check ping after service creation h4-h5
    [Documentation]    Verify ping between the hosts h4 - h5
    Check Ping    h4    h5

Check ping after service creation h3-h5
    [Documentation]    Verify ping between the hosts h3 - h5
    Check Ping    h3    h5

Delete epl service
    [Documentation]    Delete the evc multi point to multi point & verify no ping
    ${resp}    RequestsLibrary.Delete Request    session    ${REST_CON}mef-services:mef-services/    headers=${HEADERS_YANG_JSON}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Sleep    2s

Check no connectivity after deleting service
    [Documentation]    Verify no ping after deleteing the eplan service
    Check No Ping    h3    h4

*** Keywords ***
Setup Test Environment
    [Documentation]    Establish the Opendayligh session and prepair 1 Mininet VMs
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Utils.Start Suite

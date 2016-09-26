*** Settings ***
Documentation     Test suite for legato topology of 1 switch
Suite Setup       Setup Test Environment
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${UniMgr_variables_DIR}    ${CURDIR}/../../../variables/unimgr
${options}        --topo single,2 --switch ovsk,protocols=OpenFlow13

*** Test Cases ***
Check no connectivity before creating service
    [Documentation]    Verify no connectivity before creating the service between h1 to h2
    MininetKeywords.Verify Mininet No Ping    h1    h2

Create epl service
    [Documentation]    Create point to point service between the eth ports
    ${body}=    OperatingSystem.Get File    ${UniMgr_variables_DIR}/add_epl.json
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_API}/mef-services:mef-services/    headers=${HEADERS_YANG_JSON}    data=${body}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${elements}    Create List    eth1    eth2
    Wait Until Keyword Succeeds    20s    26s    Check For Elements At URI    ${CONFIG_API}/elan:elan-interfaces/    ${elements}

Check ping after service creation
    [Documentation]    Verify ping between the hosts h1 - h2
    MininetKeywords.Verify Mininet Ping    h1    h2
    Wait Until Keyword Succeeds    6s    10s    MininetKeywords.Verify Mininet Ping    h1    h2
    Sleep    1200s
Delete epl service
    [Documentation]    Delete the evc point to point & verify no ping
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_API}/mef-services:mef-services/    headers=${HEADERS_YANG_JSON}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Check no connectivity after deleting service
    [Documentation]    Verify no ping after deleteing the eplan service
    Wait Until Keyword Succeeds    6s    10s    MininetKeywords.Verify Mininet No Ping    h1    h2

*** Keywords ***
Setup Test Environment
    [Documentation]    Establish the Opendayligh session and prepair 1 Mininet VMs
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Mininetkeywords.Start Mininet Single Controller    options=${options}

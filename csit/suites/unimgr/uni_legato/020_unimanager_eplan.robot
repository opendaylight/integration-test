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
${options}        --topo single,5 --switch ovsk,protocols=OpenFlow13

*** Test Cases ***
Check no connectivity before creating service
    [Documentation]    Verify packet loss before creating the service between h3 to h4
    MininetKeywords.Verify Mininet No Ping    h3    h4

Create device
    ${device}=    OperatingSystem.Get File    ${UniMgr_variables_DIR}/add_device.json
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_API}/mef-topology:mef-topology/devices/    headers=${HEADERS_YANG_JSON}    data=${device}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${el}    Create List    1
    Wait Until Keyword Succeeds    16s    2s    Check For Elements At URI    ${CONFIG_API}/mef-topology:mef-topology/devices/    ${el}

Create tenant
    ${ten}=    OperatingSystem.Get File    ${UniMgr_variables_DIR}/add_tenant.json
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_API}/mef-global:mef-global/tenants-instances/    headers=${HEADERS_YANG_JSON}    data=${ten}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${ten}    Create List    tenant
    Wait Until Keyword Succeeds    16s    2s    Check For Elements At URI    ${CONFIG_API}/mef-global:mef-global/tenants-instances    ${ten}

Create linkUni
    ${link}=    OperatingSystem.Get File    ${UniMgr_variables_DIR}/eplan_uni_link.json
    ${resp}    RequestsLibrary.Post Request    session    ${CONFIG_API}/mef-interfaces:mef-interfaces/unis/    headers=${HEADERS_YANG_JSON}    data=${link}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${aa}    Create List    eth3    eth4    eth5
    Wait Until Keyword Succeeds    56s    2s    Check For Elements At URI    ${CONFIG_API}/mef-interfaces:mef-interfaces/unis/    ${aa}

Create epl service
    [Documentation]    Create multi point to multi point service between the eth ports
    ${interface}    Create List    s1-eth3    s1-eth4    eth5
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${OPERATIONAL_API}/mef-interfaces:mef-interfaces/    ${interface}
    ${body}=    OperatingSystem.Get File    ${UniMgr_variables_DIR}/add_eplan.json
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_API}/mef-services:mef-services/    headers=${HEADERS_YANG_JSON}    data=${body}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${elements}    Create List    eth3    eth4    eth5
    Wait Until Keyword Succeeds    56s    8s    Check For Elements At URI    ${CONFIG_API}/mef-services:mef-services/    ${elements}

Check ping between h3-h4 after service creation
    [Documentation]    Verify ping between the hosts h3 - h4
    MininetKeywords.Verify Mininet Ping    h3    h4
    Wait Until Keyword Succeeds    8s    2s    MininetKeywords.Verify Mininet Ping    h3    h4

Check ping between h4-h5 after service creation
    [Documentation]    Verify ping between the hosts h4 - h5
    MininetKeywords.Verify Mininet Ping    h4    h5
    Wait Until Keyword Succeeds    8s    2s    MininetKeywords.Verify Mininet Ping    h4    h5

Check ping between h3-h5 after service creation
    [Documentation]    Verify ping between the hosts h3 - h5
    MininetKeywords.Verify Mininet Ping    h3    h5
    Wait Until Keyword Succeeds    8s    2s    MininetKeywords.Verify Mininet Ping    h3    h5

Delete epl service
    [Documentation]    Delete the evc multi point to multi point & verify no ping
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_API}/mef-services:mef-services/    headers=${HEADERS_YANG_JSON}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Check no connectivity after deleting service
    [Documentation]    Verify no ping after deleteing the eplan service
    Wait Until Keyword Succeeds    8s    2s    MininetKeywords.Verify Mininet No Ping    h3    h4

*** Keywords ***
Setup Test Environment
    [Documentation]    Establish the Opendayligh session and prepair 1 Mininet VMs
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Mininetkeywords.Start Mininet Single Controller    options=${options}

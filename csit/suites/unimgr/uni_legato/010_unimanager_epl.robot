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

Create interface from mininet
    [Documentation]    create interface from mininet
    ${interface}    Create List    s1-eth1    s1-eth2
    Wait Until Keyword Succeeds    16s    8s    Check For Elements At URI    ${OPERATIONAL_API}/mef-interfaces:mef-interfaces/    ${interface}

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
    ${link}=    OperatingSystem.Get File    ${UniMgr_variables_DIR}/link_unis.json
    ${resp}    RequestsLibrary.Post Request    session    ${CONFIG_API}/mef-interfaces:mef-interfaces/unis/    headers=${HEADERS_YANG_JSON}    data=${link}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${aa}    Create List    eth1    eth2
    Wait Until Keyword Succeeds    16s    2s    Check For Elements At URI    ${CONFIG_API}/mef-interfaces:mef-interfaces/unis/    ${aa}

Create epl
    ${body}=    OperatingSystem.Get File    ${UniMgr_variables_DIR}/add_epl.json
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_API}/mef-services:mef-services/    headers=${HEADERS_YANG_JSON}    data=${body}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${elem}    Create List    eth1    eth2
    Wait Until Keyword Succeeds    16s    8s    Check For Elements At URI    ${CONFIG_API}/mef-services:mef-services/    ${elem}

Check ping between h1-h2 after service creation
    [Documentation]    Verify ping between the hosts h1 - h2
    MininetKeywords.Verify Mininet Ping    h1    h2
    Wait Until Keyword Succeeds    8s    2s    MininetKeywords.Verify Mininet Ping    h1    h2

Delete epl service
    [Documentation]    Delete the evc point to point & verify no ping
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_API}/mef-services:mef-services/    headers=${HEADERS_YANG_JSON}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_API}/mef-global:mef-global/tenants-instances/    headers=${HEADERS_YANG_JSON}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_API}/mef-interfaces:mef-interfaces/unis/    headers=${HEADERS_YANG_JSON}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_API}/mef-topology:mef-topology/devices/    headers=${HEADERS_YANG_JSON}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Check no connectivity after deleting service
    [Documentation]    Verify no ping after deleteing the eplan service
    Wait Until Keyword Succeeds    8s    2s    MininetKeywords.Verify Mininet No Ping    h1    h2

*** Keywords ***
Setup Test Environment
    [Documentation]    Establish the Opendayligh session and prepair 1 Mininet VMs
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Mininetkeywords.Start Mininet Single Controller    options=${options}

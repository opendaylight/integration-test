*** Settings ***
Documentation     Test suite for all Uni Manager operations
Suite Setup       Setup Unimgr Test Environment
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           String
Library           Collections
Library           SSHLibrary
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/UnimgrKeywords.robot

*** Variables ***
${DEFAULT_LINUX_PROMPT}    ${EMPTY}
${Mininet1_IP}    ${TOOLS_SYSTEM_IP}
${Mininet2_IP}    ${TOOLS_SYSTEM_2_IP}
${UNI1_MAC}       68:5b:35:bb:f8:3e
${UNI2_MAC}       52:7b:25:cb:a7:3c
${Evc_topo_API}    topology/unimgr:evc/link/evc:%2F%2F1
${Uni_topo_API}    topology/unimgr:uni/node/uni:%2F%2F
${UniMgr_variables_DIR}    ${CURDIR}/../../../variables/unimgr

*** Test Cases ***
Create source and destination UNIs at the OVS instances using Restconf API
    [Documentation]    Create source and destination UNIs
    [Tags]    UniMgr UNIs Create
    ${uniSource}    Get Add Uni Json    ${Mininet1_IP}    ${UNI1_MAC}
    ${uniDest}    Get Add Uni Json    ${Mininet2_IP}    ${UNI2_MAC}
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}/${Uni_topo_API}${Mininet1_IP}    data=${uniSource}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}/${Uni_topo_API}${Mininet2_IP}    data=${uniDest}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${elements}    Create List    ${Mininet1_IP}    ${Mininet2_IP}
    Wait Until Keyword Succeeds    16s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/unimgr:uni/    ${elements}

Update UNI Speed
    [Documentation]    Update the Unis source and destenation speed
    [Tags]    UniMgr UNIs Speed
    ${speedJson}    OperatingSystem.Get File    ${UniMgr_variables_DIR}/uni_speed.json
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}/${Uni_topo_API}${Mininet1_IP}/cl-unimgr-mef:speed    data=${speedJson}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}/${Uni_topo_API}${Mininet2_IP}/cl-unimgr-mef:speed    data=${speedJson}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${elements}    Create List    speed-10G
    Wait Until Keyword Succeeds    16s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/unimgr:uni/    ${elements}

Create EVC tunnel between the Unis
    [Documentation]    Create EVC between Unis
    [Tags]    UniMgr EVC Create
    ${evc}    Get Add Evc Json    ${Mininet1_IP}    ${Mininet2_IP}
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}/${Evc_topo_API}    data=${evc}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${elements}    Create List    evc://1
    Wait Until Keyword Succeeds    16s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/unimgr:evc/    ${elements}

Update EVC Ingress and Egress Speed
    [Documentation]    Update the EVC connection Ingress and Egress Speed
    [Tags]    UniMgr EVC Speed
    ${ingressJson}    OperatingSystem.Get File    ${UniMgr_variables_DIR}/evc_ingress_speed.json
    ${egressJson}    OperatingSystem.Get File    ${UniMgr_variables_DIR}/evc_egress_speed.json
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}/${Evc_topo_API}/cl-unimgr-mef:ingress-bw    data=${ingressJson}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}/${Evc_topo_API}/cl-unimgr-mef:egress-bw    data=${egressJson}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${elements}    Create List    speed-1G
    Wait Until Keyword Succeeds    16s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/unimgr:evc/    ${elements}

Delete EVC tunnel between the Unis
    [Documentation]    Delete EVC
    [Tags]    UniMgr EVC Delete
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/${Evc_topo_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${elements}    Create List    evc://1
    Wait Until Keyword Succeeds    16s    2s    Check For Elements Not At URI    ${CONFIG_TOPO_API}/topology/unimgr:evc/    ${elements}

Delete UNIs source and destination
    [Documentation]    Delete both UNIs source and destination
    [Tags]    UniMgr UNI Delete
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/${Uni_topo_API}${Mininet1_IP}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/${Uni_topo_API}${Mininet2_IP}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${elements}    Create List    ${Mininet1_IP}    ${Mininet2_IP}
    Wait Until Keyword Succeeds    16s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}/topology/unimgr:uni/    ${elements}

*** Settings ***
Documentation     Test suite for all Uni Manager operations
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           String
Library           Collections
Library           SSHLibrary
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${DEFAULT_LINUX_PROMPT}
${mininet1_IP}    192.168.2.8
${mininet2_IP}    192.168.2.9
${OVS_PORT}     6640
${Unimgr_config_API}    /restconf/config/network-topology:network-topology
${Unimgr_operation_API}     /restconf/operational/network-topology:network-topology
${Uni_topo_API}    /topology/unimgr:uni/node/uni:%2F%2F
${Evc_topo_API}    /topology/unimgr:evc/link/evc:%2F%2F1
${UniMgr_Variables_DIR}    ../../../variables/unimgr

*** Test Cases ***
Make the OVS instance listen to a passive connection
    [Documentation]    connect to the ovs instances then delete and set the ovs manager
    [Tags]    UniMgr Mininet Manager
    Run Command On Remote System    ${mininet1_IP}    sudo ovs-vsctl del-manager    mininet     mininet
    Run Command On Remote System    ${mininet1_IP}    sudo ovs-vsctl set-manager ptcp:${OVS_PORT}        mininet     mininet
    ${stdout}=    Run Command On Remote System    ${mininet1_IP}    sudo ovs-vsctl show    mininet     mininet
    Should Contain     ${stdout}    "ptcp:${OVS_PORT}"
    Run Command On Remote System    ${mininet2_IP}    sudo ovs-vsctl del-manager    vagrant     vagrant
    Run Command On Remote System    ${mininet2_IP}    sudo ovs-vsctl set-manager ptcp:${OVS_PORT}    vagrant     vagrant
    ${stdout}=    Run Command On Remote System    ${mininet2_IP}    sudo ovs-vsctl show    vagrant     vagrant
    Should Contain     ${stdout}    "ptcp:${OVS_PORT}"

Create source and destination UNIs at the OVS instances using Restconf API
    [Documentation]    Create source and destination UNIs
    [Tags]    UniMgr UNIs Create
    ${uniJson}    OperatingSystem.Get File    ${UniMgr_Variables_DIR}/add_uni.json
    ${uniSource}    Replace String    ${uniJson}    {uni-ip}    ${mininet1_IP}
    ${uniDest}    Replace String    ${uniJson}    {uni-ip}    ${mininet2_IP}
    ${resp}    RequestsLibrary.Put Request    session    ${Unimgr_config_API}${Uni_topo_API}${mininet1_IP}    data=${uniSource}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Put Request    session    ${Unimgr_config_API}${Uni_topo_API}${mininet2_IP}    data=${uniDest}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Sleep    10s
    ${resp}    RequestsLibrary.Get Request    session    ${Unimgr_operation_API}/topology/unimgr:uni/
    Should Contain    ${resp.content}    ${mininet1_IP}
    Should Contain    ${resp.content}    ${mininet2_IP}

Update UNI Speed
    [Documentation]    Update the Unis source and destenation speed
    [Tags]    UniMgr UNIs Speed
    ${speedJson}    OperatingSystem.Get File    ${UniMgr_Variables_DIR}/uni_speed.json
    ${resp}    RequestsLibrary.Put Request    session    ${Unimgr_config_API}${Uni_topo_API}${mininet1_IP}/cl-unimgr-mef:speed    data=${speedJson}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Put Request    session    ${Unimgr_config_API}${Uni_topo_API}${mininet2_IP}/cl-unimgr-mef:speed    data=${speedJson}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Sleep    10s
    ${resp}    RequestsLibrary.Get Request    session    ${Unimgr_operation_API}/topology/unimgr:uni/
    Should Contain    ${resp.content}    speed-10G


Create EVC tunnel between the Unis
    [Documentation]    Create EVC between Unis
    [Tags]    UniMgr EVC Create
    ${evcJson}    OperatingSystem.Get File    ${UniMgr_Variables_DIR}/add_evc.json
    ${temp}    Replace String    ${evcJson}    {uni1-ip}    ${mininet1_IP}
    ${evc}    Replace String    ${temp}    {uni2-ip}    ${mininet2_IP}
    ${resp}    RequestsLibrary.Put Request    session    ${Unimgr_config_API}${Evc_topo_API}    data=${evc}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Sleep    10s
    ${resp}    RequestsLibrary.Get Request    session    ${Unimgr_operation_API}/topology/unimgr:evc/
    Should Contain    ${resp.content}    evc://1

Update EVC Ingress and Egress Speed
    [Documentation]    Update the EVC connection Ingress and Egress Speed
    [Tags]    UniMgr EVC Speed
    ${ingressJson}    OperatingSystem.Get File    ${UniMgr_Variables_DIR}/evc_ingress_speed.json
    ${egressJson}    OperatingSystem.Get File    ${UniMgr_Variables_DIR}/evc_egress_speed.json
    ${resp}    RequestsLibrary.Put Request    session    ${Unimgr_config_API}${Evc_topo_API}/cl-unimgr-mef:ingress-bw    data=${ingressJson}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Put Request    session    ${Unimgr_config_API}${Evc_topo_API}/cl-unimgr-mef:egress-bw    data=${egressJson}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Sleep    10s
    ${resp}    RequestsLibrary.Get Request    session    ${Unimgr_operation_API}/topology/unimgr:evc/
    Should Contain    ${resp.content}    speed-1G


Delete EVC tunnel between the Unis
    [Documentation]    Delete EVC
    [Tags]    UniMgr EVC Delete
    ${resp}    RequestsLibrary.DELETE Request    session    ${Unimgr_config_API}${Evc_topo_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Sleep    10s
    ${resp}    RequestsLibrary.Get Request    session    ${Unimgr_config_API}/topology/unimgr:evc/
    Should not Contain    ${resp.content}    evc://1

Delete UNIs source and destination
    [Documentation]    Delete both UNIs source and destination
    [Tags]    UniMgr UNI Delete
    ${resp}    RequestsLibrary.DELETE Request    session    ${Unimgr_config_API}${Uni_topo_API}${mininet1_IP}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.DELETE Request    session    ${Unimgr_config_API}${Uni_topo_API}${mininet2_IP}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Sleep    10s
    ${resp}    RequestsLibrary.Get Request    session    ${Unimgr_operation_API}/topology/unimgr:uni/
    Should not Contain    ${resp.content}    ${mininet1_IP}
    Should not Contain    ${resp.content}    ${mininet2_IP}
*** Settings ***
Suite Setup       Start Connections
Library           SSHLibrary    120 seconds
Library           RequestsLibrary
Resource          ../connections.robot
Resource          ../../../../libraries/KarafKeywords.robot
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBP/ConnUtils.robot

*** Variables ***
${VPP1}
${VPP2}
${VPP3}

*** Test Cases ***
Connect Controller
    [Documentation]    Setup odl to connect it with controller node
    Set Suite Variable    ${ODL_SYSTEM_IP}    ${ODL_SYSTEM_${GBP_MASTER_INDEX}_IP}
    Issue Command On Karaf Console    log:clear
    Register Node    controller    ${VPP1}
    Wait For Karaf Log    controller is capable and ready    karaf_ip=${ODL_SYSTEM_IP}
    Issue Command On Karaf Console    log:clear

Connect Compute 0
    [Documentation]    Setup odl to connect it with first compute node
    Set Suite Variable    ${ODL_SYSTEM_IP}    ${ODL_SYSTEM_${GBP_MASTER_INDEX}_IP}
    Issue Command On Karaf Console    log:clear
    Register Node    compute0    ${VPP2}
    Wait For Karaf Log    compute0 is capable and ready    karaf_ip=${ODL_SYSTEM_IP}
    Issue Command On Karaf Console    log:clear

Connect Compute 1
    [Documentation]    Setup odl to connect it with second compute node
    Set Suite Variable    ${ODL_SYSTEM_IP}    ${ODL_SYSTEM_${GBP_MASTER_INDEX}_IP}
    Issue Command On Karaf Console    log:clear
    Register Node    compute1    ${VPP3}
    Wait For Karaf Log    compute1 is capable and ready    karaf_ip=${ODL_SYSTEM_IP}
    Issue Command On Karaf Console    log:clear

Verify Connections In Vpp Renderer
    [Documentation]    Verify nodes are available in vpp-renderer operational datastore on every cluster node
    Issue Command On Karaf Console    log:clear
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${out}  Get Data From URI  session /restconf/operational/renderer:renderers/renderer/vpp-renderer headers
    Log  ${out}
    Issue Command On Karaf Console    log:clear
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_2_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${out}  Get Data From URI  session /restconf/operational/renderer:renderers/renderer/vpp-renderer headers
    Log  ${out}
    Issue Command On Karaf Console    log:clear
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_3_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${out}  Get Data From URI  session /restconf/operational/renderer:renderers/renderer/vpp-renderer headers
    Log  ${out}

*** Keywords ***
Register Node
    [Arguments]    ${VPP_NAME}    ${VPP_IP}
    [Documentation]    Write node to netconf topology in ODL datastore
    ConnUtils.Connect and Login    ${VPP_IP}    timeout=10s
    Register VPP Node In ODL    ${VPP_NAME}    ${VPP_IP}
    SSHLibrary.Close Connection

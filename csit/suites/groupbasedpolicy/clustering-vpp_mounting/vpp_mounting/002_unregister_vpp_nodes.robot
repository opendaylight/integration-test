*** Settings ***
Suite Setup       Start Connections
Library           SSHLibrary    120 seconds
Library           RequestsLibrary
Resource          ../connections.robot
Resource          ../vars.robot
Resource          ../../../../libraries/KarafKeywords.robot
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBP/ConnUtils.robot
Resource          ../keywords.robot

*** Variables ***
${VPP1}
${VPP2}
${VPP3}

*** Test Cases ***
Disconnect Controller
    [Documentation]    Remove controller node data from ODL to discard connection
    Set Suite Variable    ${ODL_SYSTEM_IP}    ${ODL_SYSTEM_${GBP_MASTER_INDEX}_IP}
    Issue Command On Karaf Console    log:clear
    Unregister Node    controller    ${VPP1}
    Wait For Karaf Log    Node controller is removed    karaf_ip=${ODL_SYSTEM_IP}
    Issue Command On Karaf Console    log:clear

Disconnect Compute 0
    [Documentation]    Remove compute 0 node data from ODL to discard connection
    Set Suite Variable    ${ODL_SYSTEM_IP}    ${ODL_SYSTEM_${GBP_MASTER_INDEX}_IP}
    Issue Command On Karaf Console    log:clear
    Unregister Node    compute0    ${VPP2}
    Wait For Karaf Log    Node compute0 is removed    karaf_ip=${ODL_SYSTEM_IP}
    Issue Command On Karaf Console    log:clear

Disconnect Compute 1
    [Documentation]    Remove compute 1 node data from ODL to discard connection
    Set Suite Variable    ${ODL_SYSTEM_IP}    ${ODL_SYSTEM_${GBP_MASTER_INDEX}_IP}
    Issue Command On Karaf Console    log:clear
    Unregister Node    compute1    ${VPP3}
    Wait For Karaf Log    Node compute1 is removed    karaf_ip=${ODL_SYSTEM_IP}
    Issue Command On Karaf Console    log:clear

Verify Disconnections In Vpp Renderer
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
Unregister Node
    [Arguments]    ${VPP_NAME}    ${VPP_IP}
    [Documentation]    Delete node from ODL netconf topology
    ConnUtils.Connect and Login    ${VPP_IP}    timeout=10s
    Unregister VPP Node In ODL    ${VPP_NAME}    ${VPP_IP}
    SSHLibrary.Close Connection

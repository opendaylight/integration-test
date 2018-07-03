*** Settings ***
Suite Setup       Start Suite for ha
Test Teardown     Genius Test Teardown    ${data_models}
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Resource          ../../libraries/ClusterManagement.robot
Resource          ../../libraries/Genius.robot
Variables         ../../variables/genius/Modules.py

*** Variables ***
${bridgename}     BR1
${interface_name}    l2vlan-trunk
${trunk_json}     l2vlan.json
@{itm_created}    TZA

*** Test Cases ***
Take Down ODL1
    ${NEW_CLUSTER_LIST} =    ClusterManagement.Kill Single Member    1
    BuiltIn.Set Suite Variable    ${NEW_CLUSTER_LIST}
    Verify OVS Configuration    ${ODL_SYSTEM_2_IP}    session2

Bring Up ODL1
    ClusterManagement.Start Single Member    1
    Verify OVS Configuration    ${ODL_SYSTEM_1_IP}    session

Take Down ODL2
    ${NEW_CLUSTER_LIST} =    ClusterManagement.Kill Single Member    2
    BuiltIn.Set Suite Variable    ${NEW_CLUSTER_LIST}
    Verify OVS Configuration    ${ODL_SYSTEM_3_IP}    session3

Bring Up ODL2
    ClusterManagement.Start Single Member    2
    Verify OVS Configuration    ${ODL_SYSTEM_2_IP}    session2

Take Down ODL3
    ${NEW_CLUSTER_LIST} =    ClusterManagement.Kill Single Member    3
    BuiltIn.Set Suite Variable    ${NEW_CLUSTER_LIST}
    Verify OVS Configuration    ${ODL_SYSTEM_1_IP}    session

Bring Up ODL3
    ClusterManagement.Start Single Member    3
    Verify OVS Configuration    ${ODL_SYSTEM_3_IP}    session3

Delete VTEP and Verify
    ${Dpn_id_1} =    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2} =    Genius.Get Dpn Ids    ${conn_id_2}
    ${type} =    Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-1} =    Genius.Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}    ${type}
    ${tunnel-2} =    Genius.Get Tunnel    ${Dpn_id_2}    ${Dpn_id_1}    ${type}
    Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    Should Not Contain    ${resp}    ${tunnel-1}    ${tunnel-2}
    Run Command On Remote System And Log    ${TOOLS_SYSTEM_1_IP}    sudo ovs-vsctl show
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel-1}
    Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_2}    ${tunnel-2}

Delete Interface
    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/ietf-interfaces:interfaces/
    Utils.No Content From URI    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces/
    BuiltIn.Wait Until Keyword Succeeds    30    10    No table0 entry

*** Keywords ***
Start Suite for ha
    ClusterManagement.ClusterManagement Setup
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}    timeout=5
    RequestsLibrary.Create Session    session2    http://${ODL_SYSTEM_2_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}    timeout=5
    RequestsLibrary.Create Session    session3    http://${ODL_SYSTEM_3_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}    timeout=5
    ${conn_id_1} =    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Set Suite Variable    ${conn_id_1}
    ${conn_id_2} =    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    BuiltIn.Set Suite Variable    ${conn_id_2}
    : FOR    ${i}    IN RANGE    1    ${NUM_TOOLS_SYSTEM}
    \    Create Bridge    ${TOOLS_SYSTEM_${i}_IP}    BR${i}
    Create VTEP and Verify
    Create Interfaces and Verify

Create Bridge
    [Arguments]    ${ovs_ip}    ${bridge}
    Utils.Run Command On Remote System    ${ovs_ip}    sudo ovs-vsctl add-br ${bridge}
    Utils.Run Command On Remote System    ${ovs_ip}    sudo ovs-vsctl set bridge ${bridge} protocols=OpenFlow13
    Utils.Run Command On Remote System    ${ovs_ip}    sudo ifconfig ${bridge} up
    Utils.Run Command On Remote System    ${ovs_ip}    sudo ovs-vsctl add-port ${bridge} tap8ed70586-6c -- set Interface tap8ed70586-6c type=tap
    Utils.Run Command On Remote System    ${ovs_ip}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:${OVSDBPORT}
    Utils.Run Command On Remote System    ${ovs_ip}    sudo ovs-vsctl set-controller ${bridge} tcp:${ODL_SYSTEM_1_IP}:${ODL_OF_PORT_6653} tcp:${ODL_SYSTEM_2_IP}:${ODL_OF_PORT_6653} tcp:${ODL_SYSTEM_3_IP}:${ODL_OF_PORT_6653}
    Utils.Run Command On Remote System And Log    ${ovs_ip}    sudo ovs-vsctl show

Create VTEP and Verify
    ${Dpn_id_1} =    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2} =    Genius.Get Dpn Ids    ${conn_id_2}
    ${vlan} =    Set Variable    0
    ${gateway-ip} =    Set Variable    0.0.0.0
    Genius.Create Vteps    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    ${type} =    Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-1} =    Wait Until Keyword Succeeds    70    20    Genius.Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    ${type}
    ${tunnel-2} =    Wait Until Keyword Succeeds    70    20    Genius.Get Tunnel    ${Dpn_id_2}    ${Dpn_id_1}
    ...    ${type}
    Run Command On Remote System And Log    ${TOOLS_SYSTEM_1_IP}    sudo ovs-vsctl show
    Wait Until Keyword Succeeds    2 min    2    Verify Tunnel Status    TZA    ${ODL_SYSTEM_1_IP}

Create IETF Interface
    [Arguments]    ${json_file}    ${interface_mode}
    ${body} =    OperatingSystem.Get File    ${genius_config_dir}/${json_file}
    log    ${genius_config_dir}/${json_file}
    ${body} =    replace string    ${body}    "l2vlan-mode":"trunk"    "l2vlan-mode":"${interface_mode}"
    log    "l2vlan-mode":"${interface_mode}"
    log    ${body}
    ${post_resp} =    RequestsLibrary.Post Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/    data=${body}
    Log    ${post_resp.content}
    Log    ${post_resp.status_code}
    Should Be Equal As Strings    ${post_resp.status_code}    204
    Run Command On Remote System And Log    ${TOOLS_SYSTEM_1_IP}    sudo ovs-vsctl show

Create Interfaces and Verify
    Create IETF Interface    ${trunk_json}    transparent
    Verify IETF Interfaces    session

Verify IETF Interfaces
    [Arguments]    ${session}
    BuiltIn.Wait Until Keyword Succeeds    50    5    Get operational interface    ${interface_name}    ${session}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Table0 entry    ${conn_id_1}    ${bridgename}

Get operational interface
    [Arguments]    ${interface_name}    ${session}
    ${get_oper_resp} =    RequestsLibrary.Get Request    ${session}    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${interface_name}/
    ${respjson} =    RequestsLibrary.To Json    ${get_oper_resp.content}    pretty_print=True
    log    ${respjson}
    log    ${get_oper_resp.status_code}
    Should Be Equal As Strings    ${get_oper_resp.status_code}    200
    Should not contain    ${get_oper_resp.content}    down
    Should Contain    ${get_oper_resp.content}    up    up

Table0 entry
    [Arguments]    ${connection-id}    ${bridgename}
    switch connection    ${connection-id}
    ${ovs-check} =    execute command    sudo ovs-ofctl -O OpenFlow13 dump-flows ${bridgename}
    log    sudo ovs-ofctl -O OpenFlow13 dump-flows ${bridgename}
    log    ${ovs-check}
    should contain    ${ovs-check}    table=0

No table0 entry
    switch connection    ${conn_id_1}
    ${ovs-check} =    execute command    sudo ovs-ofctl -O OpenFlow13 dump-flows ${bridgename}
    log    ${ovs-check}
    should not contain    ${ovs-check}    table=0
    should not contain    ${ovs-check}    goto_table:17

Verify OVS Configuration
    [Arguments]    ${odl_ip}    ${session}
    BuiltIn.Wait Until Keyword Succeeds    2 min    2    Verify Tunnel Status    TZA    ${odl_ip}
    Verify IETF Interfaces    ${session}

Verify Tunnel Status
    [Arguments]    ${Transport_zone}    ${odl_ip}
    ${No_of_Teps} =    Issue_Command_On_Karaf_Console    ${TEP_SHOW}    ${odl_ip}
    ${Lines_of_TZA} =    Get Lines Containing String    ${No_of_Teps}    ${Transport_zone}
    ${Expected_Node_Count} =    Get Line Count    ${Lines_of_TZA}
    ${no_of_tunnels} =    Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}    ${odl_ip}
    ${lines_of_VXLAN} =    Get Lines Containing String    ${no_of_tunnels}    VXLAN
    Should Contain    ${no_of_tunnels}    ${STATE_UP}
    Should Not Contain    ${no_of_tunnels}    ${STATE_DOWN}
    Should Not Contain    ${no_of_tunnels}    ${STATE_UNKNOWN}
    ${Actual_Tunnel_Count} =    Get Line Count    ${lines_of_VXLAN}
    ${Expected_Tunnel_Count} =    Set Variable    ${Expected_Node_Count*${Expected_Node_Count - 1}}
    Should Be Equal As Strings    ${Actual_Tunnel_Count}    ${Expected_Tunnel_Count}

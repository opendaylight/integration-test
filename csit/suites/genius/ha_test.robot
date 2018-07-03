*** Settings ***
Suite Setup       Start Suite for HA
Test Teardown     Genius Test Teardown    ${data_models}    ${odl_ip_for_teardown}
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Resource          ../../libraries/ClusterManagement.robot
Resource          ../../libraries/Genius.robot
Variables         ../../variables/genius/Modules.py
Resource          ../../libraries/ToolsSystem.robot

*** Variables ***
${BRIDGENAME}     BR1
${interface_name}    l2vlan-trunk
${trunk_json}     l2vlan.json
@{itm_created}    TZA

*** Test Cases ***
Take Down ODL1
    ${NEW_CLUSTER_LIST} =    ClusterManagement.Kill Single Member    1
    BuiltIn.Set Suite Variable    ${NEW_CLUSTER_LIST}
    Verify OVS Configuration    ${ODL_SYSTEM_2_IP}    session2
    ${odl_ip_for_teardown} =    BuiltIn.Set Variable    ${ODL_SYSTEM_2_IP}

Bring Up ODL1
    ClusterManagement.Start Single Member    1
    Verify OVS Configuration    ${ODL_SYSTEM_1_IP}    session
    ${odl_ip_for_teardown} =    BuiltIn.Set Variable    ${ODL_SYSTEM_1_IP}

Take Down ODL2
    ${NEW_CLUSTER_LIST} =    ClusterManagement.Kill Single Member    2
    BuiltIn.Set Suite Variable    ${NEW_CLUSTER_LIST}
    Verify OVS Configuration    ${ODL_SYSTEM_3_IP}    session3
    ${odl_ip_for_teardown} =    BuiltIn.Set Variable    ${ODL_SYSTEM_3_IP}

Bring Up ODL2
    ClusterManagement.Start Single Member    2
    Verify OVS Configuration    ${ODL_SYSTEM_2_IP}    session2
    ${odl_ip_for_teardown} =    BuiltIn.Set Variable    ${ODL_SYSTEM_2_IP}

Take Down ODL3
    ${NEW_CLUSTER_LIST} =    ClusterManagement.Kill Single Member    3
    BuiltIn.Set Suite Variable    ${NEW_CLUSTER_LIST}
    Verify OVS Configuration    ${ODL_SYSTEM_1_IP}    session
    ${odl_ip_for_teardown} =    BuiltIn.Set Variable    ${ODL_SYSTEM_1_IP}

Bring Up ODL3
    ClusterManagement.Start Single Member    3
    Verify OVS Configuration    ${ODL_SYSTEM_3_IP}    session3
    ${odl_ip_for_teardown} =    BuiltIn.Set Variable    ${ODL_SYSTEM_3_IP}

Delete VTEP and Verify
    ${Dpn_id_1} =    Genius.Get Dpn Ids    ${conn_id_1}
    ${Dpn_id_2} =    Genius.Get Dpn Ids    ${conn_id_2}
    ${type} =    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-1} =    Genius.Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}    ${type}
    ${tunnel-2} =    Genius.Get Tunnel    ${Dpn_id_2}    ${Dpn_id_1}    ${type}
    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/itm-state:tunnels_state/
    BuiltIn.Should Not Contain    ${resp}    ${tunnel-1}    ${tunnel-2}
    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_1_IP}    sudo ovs-vsctl show
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_1}    ${tunnel-1}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Check Tunnel Delete On OVS    ${conn_id_2}    ${tunnel-2}

Delete Interface
    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/ietf-interfaces:interfaces/
    Utils.No Content From URI    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces/
    BuiltIn.Wait Until Keyword Succeeds    40    10    OVSDB.Verify Dump Flows For Specific Table    ${conn_id_1}    ${EMPTY}    False
    ...    ${EMPTY}    table=0    goto_table:17

*** Keywords ***
Start Suite for HA
    ClusterManagement.ClusterManagement Setup
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}    timeout=5
    RequestsLibrary.Create Session    session2    http://${ODL_SYSTEM_2_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}    timeout=5
    RequestsLibrary.Create Session    session3    http://${ODL_SYSTEM_3_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}    timeout=5
    Comment    ToolsSystem.Get Tools System Nodes Data
    Comment    : FOR    ${conn_id}    IN    @{TOOLS_SYSTEM_ALL_CONN_IDS}
    Comment    \    SSHLibrary.Switch Connection    ${conn_id}
    Comment    \    SSHKeywords.Flexible_SSH_Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
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
    ${vlan} =    BuiltIn.Set Variable    0
    ${gateway-ip} =    BuiltIn.Set Variable    0.0.0.0
    Genius.Create Vteps    ${Dpn_id_1}    ${Dpn_id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    ${type} =    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    ${tunnel-1} =    BuiltIn.Wait Until Keyword Succeeds    70    20    Genius.Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    ${type}
    ${tunnel-2} =    BuiltIn.Wait Until Keyword Succeeds    70    20    Genius.Get Tunnel    ${Dpn_id_2}    ${Dpn_id_1}
    ...    ${type}
    BuiltIn.Wait Until Keyword Succeeds    60s    2s    Genius.Verify Tunnel Status as UP    TZA

Create Interfaces and Verify
    Genius.Create Interface    ${trunk_json}    transparent
    Verify IETF Interfaces    session

Verify IETF Interfaces
    [Arguments]    ${session}
    BuiltIn.Wait Until Keyword Succeeds    50    5    Get operational interface    ${interface_name}    ${session}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OVSDB.Verify Dump Flows For Specific Table    ${TOOLS_SYSTEM_1_IP}    ${EMPTY}    True
    ...    ${EMPTY}    table=0

Get operational interface
    [Arguments]    ${interface_name}    ${session}
    ${get_oper_resp} =    RequestsLibrary.Get Request    ${session}    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${interface_name}/
    ${respjson} =    RequestsLibrary.To Json    ${get_oper_resp.content}    pretty_print=True
    BuiltIn.log    ${respjson}
    BuiltIn.log    ${get_oper_resp.status_code}
    BuiltIn.Should Be Equal As Strings    ${get_oper_resp.status_code}    200
    BuiltIn.Should not contain    ${get_oper_resp.content}    down
    BuiltIn.Should contain    ${get_oper_resp.content}    up    up
    Comment    @{status} =    Create List    "admin-status":"up"    "oper-status":"up"
    Comment    Utils.Check For Elements At URI    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${interface_name}/    ${status}
    Comment    Utils.Check For Elements Not At URI    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${interface_name}/    down

Verify OVS Configuration
    [Arguments]    ${odl_ip}    ${session}
    BuiltIn.Wait Until Keyword Succeeds    60    2    Genius.Verify Tunnel Status as UP    TZA    ${odl_ip}
    Verify IETF Interfaces    ${session}

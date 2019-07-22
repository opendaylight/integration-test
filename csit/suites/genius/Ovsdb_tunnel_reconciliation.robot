*** Settings ***
Documentation     This test suite is to verify the create and delete reconciliation functionality of OVSDB to handle creation of tunnel ports and deletion of tunnel ports from OVS on switch connect.
Suite Setup       Genius Suite Setup
Suite Teardown    Genius Suite Teardown
Test Setup        Genius Test Setup
Test Teardown     Genius Test Teardown    ${data_models}
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Resource          ../../libraries/ClusterManagement.robot
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../variables/netvirt/Variables.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/ToolsSystem.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../variables/Variables.robot
Variables         ../../variables/genius/Modules.py

*** Variables ***
${BRIDGE}         br-int

*** Test Cases ***
Verify OVSDB Create Reconciliation of Tunnel Ports
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs
	${output} =    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    BuiltIn.Should Not Contain    ${output}    local_ip="${TOOLS_SYSTEM_1_IP}", remote_ip="${TOOLS_SYSTEM_2_IP}"
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    Genius.Create Vteps    ${NO_VLAN}    ${gateway_ip}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Get ITM    ${itm_created[0]}    ${SUBNET}    ${NO_VLAN}
    ${type} =    BuiltIn.Set Variable    odl-interface:tunnel-type-vxlan
    Genius.Update Dpn id list and get tunnels    ${type}
    Genius.Verify Response Code Of Dpn Endpointconfig API
    ${output} =    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    BuiltIn.Should Not Contain    ${output}    local_ip="${TOOLS_SYSTEM_1_IP}", remote_ip="${TOOLS_SYSTEM_2_IP}"
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:${OVSDBPORT}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Genius.Ovs Interface Verification
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up
    ${output} =    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    BuiltIn.Should Contain    ${output}    local_ip="${TOOLS_SYSTEM_1_IP}", remote_ip="${TOOLS_SYSTEM_2_IP}"

Verify OVSDB Delete Reconciliation of Tunnel Ports
    [Documentation]    This testcase verify the deletion of stale tunnels post OVSDB reconciliation.
    ${output} =    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    ${tunnel_list} =    Genius.Get Tunnels List
    : FOR    ${dpn_id}    IN    @{DPN_ID_LIST}
    \    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/subnets/${SUBNET}%2F16/vteps/${dpn_id}/${port_name}
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Not Contain    ${output}    ${itm_created[0]}
    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    ${output} =    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    BuiltIn.Should Contain    ${output}    local_ip="${TOOLS_SYSTEM_1_IP}", remote_ip="${TOOLS_SYSTEM_2_IP}"
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:${OVSDBPORT}
    ${output} =    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    BuiltIn.Should Not Contain    ${output}    local_ip="${TOOLS_SYSTEM_1_IP}", remote_ip="${TOOLS_SYSTEM_2_IP}"
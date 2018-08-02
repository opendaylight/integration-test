*** Settings ***
Documentation     This test suite is for OF Tunnel Testing.
Suite Setup       Pretest Setup
Suite Teardown    Pretest Cleanup
Test Setup        Genius Test Setup
Test Teardown     Genius Test Teardown    ${data_models}
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           re
Library           String
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/Utils.robot
Resource          ../../variables/Variables.robot
Variables         ../../variables/genius/Modules.py

*** Variables ***
${TUN}            tun
${OF_DISABLED}    DISABLED
${DOWN}           DOWN
${FILENAME1}      vtep_two_dpns_with_of_tunnel.json
${FILENAME2}      vtep_two_dpns_with_mix_match.json
${OF_ENABLED}     ENABLED
${REMOTE_FLOW}    remote_ip=flow
${TUNNELTYPE}    type: vxlan
*** Test Cases ***
Verify Creation and Deletion of OF based tunnels on 2 DPNs
    [Documentation]    This testcase creates and deletes OF tunnels - ITM tunnel between 2 DPNs configured in Json and verifies the same.
    Genius.Create Vteps    ${dpn_Id_1}    ${dpn_Id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    ...    ${FILENAME1}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Get Tunnel From OVS Show    ${conn_id_1}    ${Bridge-1}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Get Tunnel From OVS Show    ${conn_id_2}    ${Bridge-2}
    @{Itm-no-vlan} =    BuiltIn.Create List    ${itm_created[0]}    ${SUBNET}    ${vlan}    ${dpn_id_1}    ${Bridge-1}-eth1
    ...    ${TOOLS_SYSTEM_IP}    ${dpn_id_2}    ${Bridge-1}-eth1    ${TOOLS_SYSTEM_2_IP}
    Utils.Check For Elements At URI    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}    ${Itm-no-vlan}
    ${output} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    BuiltIn.Should Contain    ${output}    ${REMOTE_FLOW}
    \    ELSE    BuiltIn.Should Contain    ${output}    ${TOOLS_SYSTEM_IP}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OVSDB.Ovs Verification For Tunnels    ${conn_id_2}    True    local_ip="${TOOLS_SYSTEM_2_IP}"
    ...    ${REMOTE_FLOW}    ${ovs_of_tunnel_2}    ${TUNNELTYPE}
    ${resp} =    BuiltIn.Wait Until Keyword Succeeds    40    10    Get Network Topology with Tunnel    ${Bridge-1}    ${Bridge-2}
    ...    ${ovs_of_tunnel_1}    ${ovs_of_tunnel_2}    ${url-2}
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    BuiltIn.Should Contain    ${resp.content}    ${dpn_id_1}    ${ovs_of_tunnel_1}
    BuiltIn.Should Contain    ${resp.content}    ${dpn_id_2}    ${ovs_of_tunnel_2}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    ${respjson} =    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${VXLAN_SHOW}
    BuiltIn.Should Not Contain    ${output}    ${OF_DISABLED}
    BuiltIn.Should Not Contain    ${output}    ${DOWN}
    : FOR    ${connection_id}    IN    @{CONNECTION_IDS}
    \    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    \    OVSDB.Ovs Verification For Tunnels    ${connection_id}    False    ${REMOTE_FLOW}

Verify creation and deletion of OF tunnel on 1 DPN and non-OF tunnel on another DPN
    [Documentation]    creates Ond delets OF tunnel on 1 dpn and ITM tunnel on another dpn and verify the same.
    Genius.Create Vteps    ${dpn_Id_1}    ${dpn_Id_2}    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    ${vlan}    ${gateway-ip}
    ...    ${FILENAME2}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Get Tunnel From OVS Show    ${conn_id_1}    ${Bridge-1}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Get Tunnel From OVS Show    ${conn_id_2}    ${Bridge-2}
    BuiltIn.Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${SUBNET}    ${vlan}
    ...    ${dpn_id_1}    ${TOOLS_SYSTEM_IP}    ${dpn_id_2}    ${TOOLS_SYSTEM_2_IP}
    Utils.Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${dpn_id_1}/
    Utils.Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${dpn_id_2}/
    BuiltIn.Wait Until Keyword Succeeds    40    10    OVSDB.Ovs Verification For Tunnels    ${conn_id_2}    True    local_ip="${TOOLS_SYSTEM_2_IP}"
    ...    remote_ip="${TOOLS_SYSTEM_IP}"    ${ovs_of_tunnel_2}    ${TUNNELTYPE}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OVSDB.Ovs Verification For Tunnels    ${conn_id_1}    True    local_ip="${TOOLS_SYSTEM_IP}"
    ...    ${ovs_of_tunnel_1}    ${TUNNELTYPE}
    ${url-2} =    BuiltIn.Set Variable    ${OPERATIONAL_API}/network-topology:network-topology/
    ${resp} =    BuiltIn.Wait Until Keyword Succeeds    40    10    Get Network Topology with Tunnel    ${Bridge-1}    ${Bridge-2}
    ...    ${ovs_of_tunnel_1}    ${ovs_of_tunnel_2}    ${url-2}
    BuiltIn.Log    Verify Operational data base of Interface state
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/
    ${respjson}    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    BuiltIn.Should Contain    ${resp.content}    ${dpn_id_1}    ${ovs_of_tunnel_1}
    BuiltIn.Should Contain    ${resp.content}    ${dpn_id_2}    ${ovs_of_tunnel_2}
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    ${respjson} =    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${VXLAN_SHOW}
    BuiltIn.Should Not Contain    ${output}    ${OF_DISABLED}
    BuiltIn.Should Contain    ${output}    ${OF_ENABLED}
    : FOR    ${connection_id}    IN    @{CONNECTION_IDS}
    \    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    \    OVSDB.Ovs Verification For Tunnels    ${connection_id}    False    ${REMOTE_FLOW}

*** Keywords ***
Pretest Setup
    [Documentation]    Initial setup for 3 nodes
    Genius.Genius Suite Setup
    Genius.Start Suite For Third Node
    @{CONNECTION_IDS} =    BuiltIn.Create List    ${conn_id_1}    ${conn_id_2}    ${conn_id_3}
    BuiltIn.Set Suite Variable    @{CONNECTION_IDS}

Pretest Cleanup
    [Documentation]    Delete session for Three nodes
    Genius.Genius Suite Teardown
    Genius.Stop Suite For Third Node

Get ITM
    [Arguments]    ${itm}    ${subnet}    ${vlan}    ${dpn1_id}    ${dpn1_ip}    ${dpn2_id}
    ...    ${dpn2_ip}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    @{Itm-no-vlan}    BuiltIn.Create List    ${itm_created[0]}    ${subnet}    ${vlan}    ${dpn1_id}    ${Bridge-1}-eth1
    ...    ${dpn1_ip}    ${dpn2_id}    ${Bridge-2}-eth1    ${dpn2_ip}
    Utils.Check For Elements At URI    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm}    ${Itm-no-vlan}

Get Network Topology with Tunnel
    [Arguments]    br1    br2    ${tunnel-1}    ${tunnel-2}    ${url}
    [Documentation]    Returns the Network topology with Tunnel info in it.
    @{bridges} =    BuiltIn.Create List    br1    br2    ${tunnel-1}    ${tunnel-2}
    Utils.Check For Elements At URI    ${url}    ${bridges}

Get Tunnel From OVS Show
    [Arguments]    ${connection_id}    ${bridge}
    [Documentation]    This keyword gets the tunnel id from ovs switch and return it.
    SSHLibrary.Switch connection    ${connection_id}
    ${cmd}    set Variable    sudo ovs-vsctl list-ports
    ${cmd1} =    BuiltIn.Catenate    ${cmd}    ${bridge}
    ${output} =    Execute command    ${cmd1}
    BuiltIn.Log    ${output}
    BuiltIn.Should Match Regexp    ${output}    ${TUN}

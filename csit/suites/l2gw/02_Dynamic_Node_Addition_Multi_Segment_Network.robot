*** Settings ***
Suite Setup       BuiltIn.Run Keywords    Basic Suite Setup    Setup Network Configuration
Suite Teardown    BuiltIn.Run Keywords    Cleanup Network Configuration    Basic Suite Teardown
Test Teardown     Get L2gw Debug Info
Resource          ../../libraries/L2GatewayOperations.robot
Library           Collections

*** Test Cases ***
01 Set Manager And Verify On Hwvtep1
    [Documentation]    Connect one hwvtep node with two ports to the controller
    L2GatewayOperations.Add Vtep Manager And Verify    ${ODL_IP}    ${hwvtep_conn_id}

02 Configure L2gateway for Hwvtep Node and verify
    [Documentation]    Configure l2gateway and l2gateway connection with two interfaces and verify
    ${output}=    L2GatewayOperations.Create Verify L2Gateway    ${HWVTEP_BRIDGE}    ${NS_PORT1};${NS_PORT2}    ${L2GW_NAME1}
    Log    ${output}
    ${output}=    Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Create Verify L2Gateway Connection    ${L2GW_NAME1}    ${NET_1}
    ...    --default-segmentation-id ${PHY_VLAN_ID_1}
    Log    ${output}

03 Verify VXLAN Tunnels
    [Documentation]    One of the computes connected to controller will be selected as designated ovs to punt dhcp packets to controller. Verify tunnels towards this OVS
    Wait Until Keyword Succeeds    20s    2s    L2GatewayOperations.Verify Ovs Tunnel    ${HWVTEP_IP}    ${OVS_IP}    ${NET_1_SEGID}
    ...    ${hwvtep_conn_id}    ${OS_CNTL_CONN_ID}
    ${output}=    ITM Get Tunnels
    Log    ${output}
    Should Contain    ${output}    physicalswitch/${HWVTEP_BRIDGE}
    ${list}=    Create List    ${OVS_IP}    ${HWVTEP_IP}
    Wait Until Keyword Succeeds    20s    1s    L2GatewayOperations.Verify Vtep List    ${hwvtep_conn_id}    ${PHYSICAL_LOCATOR_TABLE}    ${list}

04 Verify DHCP IP allocation to SR-IOV ports
    [Documentation]    The namespace ports connected to HWVTEP node are configured such that they simulate traffic as if coming from SR-IOV VMs. \ These ports are used to validate DHCP ip assignment for SR-IOV VMs.
    Wait Until Keyword Succeeds    60s    10s    L2GatewayOperations.Namespace Dhclient Verify    ${HWVTEP_NS1}    ${NS_TAP1}.${PHY_VLAN_ID_1}    ${port_ip_list[1]}
    Wait Until Keyword Succeeds    60s    10s    L2GatewayOperations.Namespace Dhclient Verify    ${HWVTEP_NS2}    ${NS2_TAP1}.${PHY_VLAN_ID_1}    ${port_ip_list[2]}
    ${mac_list}=    Create List    ${port_mac_list[1]}    ${port_mac_list[2]}
    Verify Entries In Flow Table    ${OS_CNTL_CONN_ID}    ${DHCP_HWVTEP_TABLE}    true    ${mac_list}

05 Verify Hwvtep Db Entries
    [Documentation]    Verify HWVTEP database entries for the l2gateway connection created
    ${NET1_ID} =    Get Net Id    ${NET_1}
    Set Suite Variable    ${NET1_ID}
    ${mac_entries}=    Create List    unknown-dst
    ${port_list}=    Create List    ${NS_PORT1}    ${NS_PORT2}
    Verify Entries in Hwvtep DB Dump    ${hwvtep_conn_id}    ${NET1_ID}    ${HWVTEP_BRIDGE}    ${PHY_VLAN_ID_1}    ${mac_entries}    ${port_list}
    ${LS_entries}=    Create List    ${NET1_ID}    ${NS_PORT1}    ${NS_PORT2}    ${PHY_VLAN_ID_1}
    Wait Until Keyword Succeeds    30s    10s    Check For Elements At URI    ${CONFIG_API}/network-topology:network-topology/topology/hwvtep:1    ${LS_entries}    session

06 Verify Ping Between Namespaces Of Hwvtep Node1
    [Documentation]    Verify datapath between the two ports connected to HWVTEP Node.
    Wait Until Keyword Succeeds    30s    5s    L2GatewayOperations.Verify Ping In Namespace Extra Timeout    ${HWVTEP_NS1}    ${port_mac_list[1]}    ${port_ip_list[2]}

07 Add New Vm On Compute Node And Verify Ping
    [Documentation]    Datapath validation when a new VM is spawned on one of the compute nodes.
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${OVS_PORT_1}    ${OVS_VM1_NAME}    ${OS_CNTL_HOSTNAME}
    ${vm_ip}=    Wait Until Keyword Succeeds    120s    3s    L2GatewayOperations.Verify Nova VM IP    ${OVS_VM1_NAME}
    Log    ${vm_ip}
    Should Contain    ${vm_ip[0]}    ${port_ip_list[0]}
    ${output}=    Wait Until Keyword Succeeds    30s    5s    Execute Command on VM Instance    ${NET_1}    ${port_ip_list[0]}
    ...    ping -c 3 ${port_ip_list[1]}
    Log    ${output}
    Verify Ping Is Successful    ${output}
    ${output}=    Wait Until Keyword Succeeds    30s    10s    Execute Command on VM Instance    ${NET_1}    ${port_ip_list[0]}
    ...    ping -c 3 ${port_ip_list[2]}
    Log    ${output}
    Verify Ping Is Successful    ${output}
    Start Command In Hwvtep    ${NETNS_EXEC} ${HWVTEP_NS1} ping -c20 ${port_ip_list[2]} &    ${HWVTEP_IP}
    ${dst_mac_list}=    Create List    ${port_mac_list[0]}    ${port_mac_list[1]}    ${port_mac_list[2]}
    L2GatewayOperations.Verify Flow And Group Entries    ${OS_CNTL_CONN_ID}    ${dst_mac_list}    ${NET_1_SEGID}    True
    ${mac_list}=    Create List    ${port_mac_list[0]}    unknown-dst
    Wait Until Keyword Succeeds    12s    3s    Verify Remote Macs In Hwvtep DB    ${hwvtep_conn_id}    ${NET1_ID}    ${mac_list}

08 Preprovision New Hwvtep Node And Verify
    [Documentation]    Verify if the l2gateway configuration works when the HWVTEP Node connects later after configuration.
    ${output}=    L2GatewayOperations.Create Verify L2Gateway    ${HWVTEP2_BRIDGE}    ${NS2_PORT1}    ${L2GW_NAME2}
    Log    ${output}
    ${output}=    Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Create Verify L2Gateway Connection    ${L2GW_NAME2}    ${NET_1}
    ...    --default-segmentation-id ${PHY_VLAN_ID_1}
    Log    ${output}
    L2GatewayOperations.Add Vtep Manager And Verify    ${ODL_IP}    ${hwvtep2_conn_id}
    ${mac_entries}=    Create List    ${port_mac_list[0]}    unknown-dst
    ${port_list}=    Create List    ${NS2_PORT1}
    Verify Entries in Hwvtep DB Dump    ${hwvtep2_conn_id}    ${NET1_ID}    ${HWVTEP2_BRIDGE}    ${PHY_VLAN_ID_1}    ${mac_entries}    ${port_list}
    ${LS_entries}=    Create List    ${NET1_ID}    ${NS2_PORT1}    ${PHY_VLAN_ID_1}
    Wait Until Keyword Succeeds    30s    15s    Check For Elements At URI    ${CONFIG_API}/network-topology:network-topology/topology/hwvtep:1    ${LS_entries}    session
    ${list}=    Create List    ${OVS_IP}    ${HWVTEP_IP}    ${HWVTEP2_IP}
    Wait Until Keyword Succeeds    30s    1s    L2GatewayOperations.Verify Vtep List    ${hwvtep2_conn_id}    ${PHYSICAL_LOCATOR_TABLE}    ${list}

09 Verify Tunnels And Dhcp To New Hwvtep Node
    [Documentation]    Verify the tunnels and DHCP assignment when the new HWVTEP is added to the existing topology
    Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Verify Ovs Tunnel    ${HWVTEP2_IP}    ${OVS_IP}    ${NET1_SEG_ID}
    ...    ${hwvtep2_conn_id}    ${OS_CNTL_CONN_ID}
    ${output}=    ITM Get Tunnels
    Log    ${output}
    Should Contain    ${output}    physicalswitch/${HWVTEP2_BRIDGE}
    ${list}=    Create List    ${OVS_IP}    ${HWVTEP_IP}    ${HWVTEP2_IP}
    Wait Until Keyword Succeeds    30s    1s    L2GatewayOperations.Verify Vtep List    ${hwvtep2_conn_id}    ${PHYSICAL_LOCATOR_TABLE}    ${list}
    Wait Until Keyword Succeeds    60s    10s    L2GatewayOperations.Namespace Dhclient Verify    ${HWVTEP2_NS1}    ${NS3_TAP1}.${PHY_VLAN_ID_1}    ${port_ip_list[4]}
    ...    ${hwvtep2_conn_id}
    ${mac_list}=    Create List    ${port_mac_list[4]}    ${port_mac_list[1]}    ${port_mac_list[2]}
    Verify Entries In Flow Table    ${OS_CNTL_CONN_ID}    ${DHCP_HWVTEP_TABLE}    true    ${mac_list}

10 Verify Ping Among All Nodes
    [Documentation]    Verify Datapath connectivity among all Nodes
    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NET_1}    ${port_ip_list[0]}
    ...    ping -c 3 ${port_ip_list[4]}
    Log    ${output}
    Verify Ping Is Successful    ${output}
    Wait Until Keyword Succeeds    30s    5s    L2GatewayOperations.Verify Ping In Namespace Extra Timeout    ${HWVTEP_NS1}    ${port_mac_list[1]}    ${port_ip_list[4]}
    ...    ${hwvtep2_conn_id}
    Start Command In Hwvtep    ${NETNS_EXEC} $${HWVTEP2_NS1} ping -c20 ${port_ip_list[0]} &    ${HWVTEP2_IP}
    ${dst_mac_list}=    Create List    ${port_mac_list[0]}    ${port_mac_list[1]}    ${port_mac_list[2]}    ${port_mac_list[4]}
    L2GatewayOperations.Verify Flow And Group Entries    ${OS_CNTL_CONN_ID}    ${dst_mac_list}    ${NET_1_SEGID}    True    2
    ${mac_list}=    Create List    ${port_mac_list[0]}    ${port_mac_list[1]}    ${port_mac_list[2]}    unknown-dst
    Wait Until Keyword Succeeds    12s    3s    Verify Remote Macs In Hwvtep DB    ${hwvtep2_conn_id}    ${NET1_ID}    ${mac_list}

11 Add New Compute With Vm And Verify
    [Documentation]    Add new compute to the existing topology and verify datapath.
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${OVS2_PORT_1}    ${OVS2_VM1_NAME}    ${OS_CMP1_HOSTNAME}
    ${vm_ip}=    Wait Until Keyword Succeeds    180s    3s    L2GatewayOperations.Verify Nova VM IP    ${OVS2_VM1_NAME}
    Log    ${vm_ip}
    Should Contain    ${vm_ip[0]}    ${port_ip_list[3]}

12 Verify Vxlan Tunnels
    [Documentation]    Verify tunnels configured in all the compute and hwvtep nodes.
    Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Verify Ovs Tunnel    ${HWVTEP_IP}    ${OVS2_IP}    ${NET1_SEG_ID}
    ...    ${hwvtep_conn_id}    ${OS_CMP1_CONN_ID}
    Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Verify Ovs Tunnel    ${HWVTEP2_IP}    ${OVS2_IP}    ${NET1_SEG_ID}
    ...    ${hwvtep2_conn_id}    ${OS_CMP1_CONN_ID}
    ${list}=    Create List    ${OVS_IP}    ${OVS2_IP}    ${HWVTEP_IP}    ${HWVTEP2_IP}
    Wait Until Keyword Succeeds    30s    1s    L2GatewayOperations.Verify Vtep List    ${hwvtep_conn_id}    ${PHYSICAL_LOCATOR_TABLE}    ${list}
    Wait Until Keyword Succeeds    30s    1s    L2GatewayOperations.Verify Vtep List    ${hwvtep2_conn_id}    ${PHYSICAL_LOCATOR_TABLE}    ${list}

13 Verify Ping And Remote Macs On All Nodes
    [Documentation]    Verify datapath among all the nodes.
    @{ip_list}=    Create List    ${port_ip_list[0]}    ${port_ip_list[1]}    ${port_ip_list[4]}
    : FOR    ${ip}    IN    @{ip_list}
    \    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NET_1}
    \    ...    ${port_ip_list[3]}    ping -c 3 ${ip}
    \    Log    ${output}
    \    Verify Ping Is Successful    ${output}
    ${dst_mac_list}=    Create List    ${port_mac_list[0]}    ${port_mac_list[1]}    ${port_mac_list[2]}    ${port_mac_list[3]}    ${port_mac_list[4]}
    L2GatewayOperations.Verify Flow And Group Entries    ${OS_CMP1_CONN_ID}    ${dst_mac_list}    ${NET_1_SEGID}    True    2
    ${mac_list}=    Create List    ${port_mac_list[0]}    ${port_mac_list[1]}    ${port_mac_list[2]}    ${port_mac_list[3]}    unknown-dst
    Wait Until Keyword Succeeds    12s    3s    Verify Remote Macs In Hwvtep DB    ${hwvtep2_conn_id}    ${NET1_ID}    ${mac_list}
    ${mac_list}=    Create List    ${port_mac_list[0]}    ${port_mac_list[3]}    ${port_mac_list[4]}    unknown-dst
    Wait Until Keyword Succeeds    12s    3s    Verify Remote Macs In Hwvtep DB    ${hwvtep1_conn_id}    ${NET1_ID}    ${mac_list}

14 Delete Vm On Compute And Verify MAC Sync
    [Documentation]    Validate the datapath when one of the VMs is deleted.
    OpenStackOperations.Delete Vm Instance    ${OVS_VM1_NAME}
    ${mac_list}=    Create List    ${port_mac_list[0]}
    Wait Until Keyword Succeeds    12s    3s    Verify Remote Macs Not In Hwvtep DB    ${hwvtep_conn_id}    ${NET1_ID}    ${mac_list}
    Wait Until Keyword Succeeds    12s    3s    Verify Remote Macs Not In Hwvtep DB    ${hwvtep2_conn_id}    ${NET1_ID}    ${mac_list}
    Wait Until Keyword Succeeds    6s    2s    Verify Entries In Flow Table    ${OS_CMP1_CONN_ID}    ${DEST_MAC_TABLE}    False
    ...    ${mac_list}
    ${dst_mac_list}=    Create List    ${port_mac_list[0]}    ${port_mac_list[1]}    ${port_mac_list[2]}    ${port_mac_list[3]}    ${port_mac_list[4]}
    L2GatewayOperations.Verify Flow And Group Entries    ${OS_CNTL_CONN_ID}    ${dst_mac_list}    ${NET_1_SEGID}    False    0

15 Create The Deleted VM On Different Compute
    [Documentation]    Spawn the deleted VM on different compute.
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${OVS_PORT_1}    ${OVS_VM1_NAME}    ${OVS2_IP}
    ${vm_ip}=    Wait Until Keyword Succeeds    60s    2s    L2GatewayOperations.Verify Nova VM IP    ${OVS_VM1_NAME}
    Log    ${vm_ip}
    Should Contain    ${vm_ip[0]}    ${port_ip_list[0]}

16 Verify Ping And MAC Sync
    [Documentation]    Verify datapath
    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NET_1}    ${port_ip_list[0]}
    ...    ping -c 3 ${port_ip_list[1]}
    Log    ${output}
    Verify Ping Is Successful    ${output}
    ${mac_list}=    Create List    ${port_mac_list[0]}    ${port_mac_list[1]}    ${port_mac_list[2]}    ${port_mac_list[3]}    unknown-dst
    Wait Until Keyword Succeeds    12s    3s    Verify Remote Macs In Hwvtep DB    ${hwvtep2_conn_id}    ${NET1_ID}    ${mac_list}
    ${mac_list}=    Create List    ${port_mac_list[0]}    ${port_mac_list[3]}    ${port_mac_list[4]}    unknown-dst
    Wait Until Keyword Succeeds    12s    3s    Verify Remote Macs In Hwvtep DB    ${hwvtep1_conn_id}    ${NET1_ID}    ${mac_list}
    ${dst_mac_list}=    Create List    ${port_mac_list[0]}    ${port_mac_list[1]}    ${port_mac_list[2]}    ${port_mac_list[3]}    ${port_mac_list[4]}
    L2GatewayOperations.Verify Flow And Group Entries    ${OS_CMP1_CONN_ID}    ${dst_mac_list}    ${NET_1_SEGID}    True    2
    ${dst_mac_list}=    Create List    ${port_mac_list[0]}    ${port_mac_list[1]}    ${port_mac_list[2]}    ${port_mac_list[3]}    ${port_mac_list[4]}
    L2GatewayOperations.Verify Flow And Group Entries    ${OS_CNTL_CONN_ID}    ${dst_mac_list}    ${NET_1_SEGID}    False    0

17 Delete L2gateway For Second Hwvtep And Verify
    [Documentation]    Deleted l2gateway connection for one hwvtep and verify datapath.
    L2GatewayOperations.Delete L2Gateway Connection    ${L2GW_NAME2}
    L2GatewayOperations.Delete L2Gateway    ${L2GW_NAME2}
    ${mac_entries}=    Create List    ${port_mac_list[0]}    ${port_mac_list[1]}    ${port_mac_list[2]}    ${port_mac_list[3]}    unknown-dst
    ${port_list}=    Create List    ${NS2_PORT1}    ${NS2_PORT2}
    Verify Entries Not in Hwvtep DB Dump    ${hwvtep2_conn_id}    ${NET1_ID}    ${hwvtep_bridge}    ${PHY_VLAN_ID_1}    ${mac_entries}    ${port_list}
    ${mac_list}=    Create List    ${port_mac_list[4]}
    Wait Until Keyword Succeeds    20s    3s    Verify Remote Macs Not In Hwvtep DB    ${hwvtep_conn_id}    ${NET1_ID}    ${mac_list}
    L2GatewayOperations.Verify Flow And Group Entries    ${OS_CMP1_CONN_ID}    ${mac_list}    ${NET_1_SEGID}    False    1
    L2GatewayOperations.Verify Flow And Group Entries    ${OS_CNTL_CONN_ID}    ${mac_list}    ${NET_1_SEGID}    False    1

18 Delete L2gateway For First Hwvtep And Verify
    [Documentation]    Delete all the l2gateway connections and verify datapath on all nodes.
    L2GatewayOperations.Delete L2Gateway Connection    ${L2GW_NAME1}
    L2GatewayOperations.Delete L2Gateway    ${L2GW_NAME1}
    ${mac_entries}=    Create List    ${port_mac_list[0]}    ${port_mac_list[3]}    ${port_mac_list[4]}    unknown-dst
    ${port_list}=    Create List    ${NS_PORT1}    ${NS_PORT2}
    Verify Entries Not in Hwvtep DB Dump    ${hwvtep_conn_id}    ${NET1_ID}    ${hwvtep_bridge}    ${PHY_VLAN_ID_1}    ${mac_entries}    ${port_list}
    ${mac_list}=    Create List    ${port_mac_list[1]}    ${port_mac_list[2]}    ${port_mac_list[4]}
    L2GatewayOperations.Verify Flow And Group Entries    ${OS_CNTL_CONN_ID}    ${mac_list}    ${NET_1_SEGID}    False    0
    L2GatewayOperations.Verify Flow And Group Entries    ${OS_CMP1_CONN_ID}    ${mac_list}    ${NET_1_SEGID}    False    0

*** Keywords ***
Basic Suite Setup
    OpenStackOperations.OpenStack Suite Setup
    OpenStackOperations.Get ControlNode Connection
    Write Commands Until Prompt    cd ${DEVSTACK_DEPLOY_PATH}; source openrc admin admin    30s

Basic Suite Teardown
    OpenStackOperations.OpenStack Suite Teardown

Setup Network Configuration
    [Documentation]    Openstack network, subnet and port configuration required for the test suite.
    OpenstackOperations.Create Neutron Multisegment Network    ${NET_1}    ${VXLAN_VLAN_SEG}
    ${output}=    OpenStackOperations.List Networks
    Should Contain    ${output}    ${NET_1}
    OpenStackOperations.Create SubNet    ${NET_1}    ${SUBNET_1}    ${SUBNET_RANGE1}    ${SUBNET_ADDT_ARG}
    ${output}=    OpenStackOperations.List Subnets
    Should Contain    ${output}    ${SUBNET_1}
    OpenStackOperations.Create And Configure Security Group    ${SECURITY_GROUP_L2GW}
    OpenStackOperations.Create Port    ${NET_1}    ${OVS_PORT_1}    ${SECURITY_GROUP_L2GW}
    OpenStackOperations.Create Direct Port    ${NET_1}    ${HWVTEP_PORT_1}    --disable-port-security
    OpenStackOperations.Create Direct Port    ${NET_1}    ${HWVTEP_PORT_2}    --disable-port-security
    OpenStackOperations.Create Port    ${NET_1}    ${OVS2_PORT_1}    ${SECURITY_GROUP_L2GW}
    OpenStackOperations.Create Direct Port    ${NET_1}    ${HWVTEP2_PORT_1}    --disable-port-security
    OpenStackOperations.Create Direct Port    ${NET_1}    ${HWVTEP2_PORT_2}    --disable-port-security
    @{port_list}=    Create List    ${OVS_PORT_1}    ${HWVTEP_PORT_1}    ${HWVTEP_PORT_2}    ${OVS2_PORT_1}    ${HWVTEP2_PORT_1}
    ...    ${HWVTEP2_PORT_2}
    : FOR    ${port}    IN    @{port_list}
    \    ${port_mac}=    Get Port Mac    ${port}
    \    ${port_ip}=    Get Port Ip    ${port}
    \    Append To List    ${port_mac_list}    ${port_mac}
    \    Append To List    ${port_ip_list}    ${port_ip}
    @{hwvtep_port_list}=    Create List    ${HWVTEP_PORT_1}    ${HWVTEP_PORT_2}    ${HWVTEP2_PORT_1}
    : FOR    ${hwvtep_port}    IN    @{hwvtep_port_list}
    \    L2GatewayOperations.Update Port For Hwvtep    ${hwvtep_port}
    Wait Until Keyword Succeeds    4s    2s    L2GatewayOperations.Attach Port To Hwvtep Namespace    ${port_mac_list[1]}    ${HWVTEP_NS1}    ${NS_TAP1}
    ...    ${EMPTY}    ${hwvtep_conn_id}    ${PHY_VLAN_ID_1}
    Wait Until Keyword Succeeds    4s    2s    L2GatewayOperations.Attach Port To Hwvtep Namespace    ${port_mac_list[2]}    ${HWVTEP_NS2}    ${NS2_TAP1}
    ...    ${EMPTY}    ${hwvtep_conn_id}    ${PHY_VLAN_ID_1}
    Wait Until Keyword Succeeds    4s    2s    L2GatewayOperations.Attach Port To Hwvtep Namespace    ${port_mac_list[4]}    ${HWVTEP2_NS1}    ${NS3_TAP1}
    ...    ${EMPTY}    ${hwvtep2_conn_id}    ${PHY_VLAN_ID_1}
    Wait Until Keyword Succeeds    4s    2s    L2GatewayOperations.Attach Port To Hwvtep Namespace    ${port_mac_list[5]}    ${HWVTEP2_NS2}    ${NS4_TAP1}
    ...    ${EMPTY}    ${hwvtep2_conn_id}    ${PHY_VLAN_ID_1}

Cleanup Network Configuration
    [Documentation]    Openstack network configuration cleanup for the test suite.
    OpenStackOperations.Delete Vm Instance    ${OVS_VM1_NAME}
    OpenStackOperations.Delete Vm Instance    ${OVS2_VM1_NAME}
    ${port_list}=    Create List    ${OVS_PORT_1}    ${HWVTEP_PORT_1}    ${HWVTEP_PORT_2}
    Append To List    ${port_list}    ${OVS2_PORT_1}    ${HWVTEP2_PORT_1}    ${HWVTEP2_PORT_2}
    : FOR    ${port}    IN    @{port_list}
    \    OpenStackOperations.Delete Port    ${port}
    OpenStackOperations.Delete SubNet    ${SUBNET_1}
    OpenStackOperations.Delete Network    ${NET_1}
    OpenStackOperations.Delete Security Group    ${SECURITY_GROUP_L2GW}

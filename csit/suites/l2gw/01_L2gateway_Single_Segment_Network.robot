*** Settings ***
Documentation     Test Suite for verification of l2gateway for baremetal server usecase
Suite Setup       Basic Suite Setup
Suite Teardown    Basic Suite Teardown
Test Teardown     Get L2gw Debug Info    1
Library           SSHLibrary
Library           Collections
Resource          ../../variables/Variables.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/DevstackUtils.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../variables/l2gw/Variables.robot
Resource          ../../libraries/L2GatewayOperations.robot
Resource          ../../libraries/L2gwUtils.robot
Variables         ../../variables/l2gw/l2gw_datastore_dumps.py

*** Variables ***

*** Test Cases ***
TC01 Create L2Gateway And Connection
    [Documentation]    Configure L2gateway device and connection and verify
    L2GatewayOperations.Add Vtep Manager And Verify    ${ODL_IP}
    L2GatewayOperations.Create Verify L2Gateway    ${HWVTEP_BRIDGE}    ${NS_PORT1}    ${L2GW_NAME1}
    L2GatewayOperations.Create Verify L2Gateway Connection    ${L2GW_NAME1}    ${NET_1}

TC02 Verify Hwvtep Node DB Entries
    [Documentation]    Validation of entries installed in HWVTEP Database.
    ${NET1_ID} =    OpenstackOperations.Get Net Id    ${NET_1}
    Set Suite Variable    ${NET1_ID}
    ${mac_entries}=    Create List    ${port_mac_list[0]}    unknown-dst
    ${port_list}=    Create List    ${NS_PORT1}
    L2GatewayOperations.Verify Entries in Hwvtep DB Dump    ${hwvtep_conn_id}    ${NET1_ID}    ${hwvtep_bridge}    ${DEF_CONN_SEG_ID}    ${mac_entries}    ${port_list}
    ${LS_entries}=    Create List    ${NET1_ID}    ${port_mac_list[0]}
    Wait Until Keyword Succeeds    30s    15s    Utils.Check For Elements At URI    ${HWVTEP_NETWORK_TOPOLOGY}    ${LS_entries}    session

TC03 Verify VXLAN Tunnels
    [Documentation]    Validation of VXLAN tunnels configured between compute and HWVTEP Nodes.
    Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Verify Ovs Tunnel    ${HWVTEP_IP}    ${OVS_IP}
    ${output}=    VpnOperations.ITM Get Tunnels
    Log    ${output}
    Should Contain    ${output}    physicalswitch/${HWVTEP_BRIDGE}
    ${list}=    Create List    ${OS_CMP1_IP}    ${HWVTEP_IP}
    Wait Until Keyword Succeeds    30s    1s    L2GatewayOperations.Verify Vtep List    ${hwvtep_conn_id}    ${PHYSICAL_LOCATOR_TABLE}    ${list}

TC04 Verify Ping Between Compute Node And Hwvtep VMs
    [Documentation]    Validation of datapath connectivity between VM connected to OVS and the namespace connected to HWVTEP node.
    ${output}=    Wait Until Keyword Succeeds    60s    10s    OpenstackOperations.Execute Command on VM Instance    ${NET_1}    ${port_ip_list[0]}
    ...    ping -c 3 ${BM_PORT1_IP}
    Log    ${output}
    L2GatewayOperations.Verify Ping Is Successful    ${output}
    Wait Until Keyword Succeeds    30s    5s    L2GatewayOperations.Verify Ping In Namespace Extra Timeout    ${HWVTEP_NS1}    ${BM_PORT1_MAC}    ${port_ip_list[0]}

TC05 Verify Flow And Group Entries
    [Documentation]    Flow and Group validation to explicitly verify unicast and broadcast paths for data. Unicast path failure can go undetected with only ping test.
    L2GatewayOperations.Start Command In Hwvtep    ${NETNS_EXEC} ${HWVTEP_NS1} nohup ping -c20 ${port_ip_list[0]} &    ${HWVTEP_IP}
    ${dst_mac_list}=    Create List    ${port_mac_list[0]}    ${BM_PORT1_MAC}
    L2GatewayOperations.Verify Flow And Group Entries    ${OS_CMP1_CONN_ID}    ${dst_mac_list}    ${NET_1_SEGID}    True    2

TC06 Configure L2gateway Connection to Second Network
    [Documentation]    Configure L2gateway connection for second openstack network and validate
    L2GatewayOperations.Create Verify L2Gateway    ${HWVTEP_BRIDGE}    ${NS_PORT2}    ${L2GW_NAME2}
    L2GatewayOperations.Create Verify L2Gateway Connection    ${L2GW_NAME2}    ${NET_2}
    ${NET2_ID} =    OpenstackOperations.Get Net Id    ${NET_2}
    Set Suite Variable    ${NET2_ID}
    ${mac_entries}=    Create List    ${port_mac_list[1]}    unknown-dst
    ${port_list}=    Create List    ${NS_PORT2}
    L2GatewayOperations.Verify Entries in Hwvtep DB Dump    ${hwvtep_conn_id}    ${NET2_ID}    ${hwvtep_bridge}    ${DEF_CONN_SEG_ID}    ${mac_entries}    ${port_list}
    ${LS_entries}=    Create List    ${NET2_ID}    ${port_mac_list[1]}
    Wait Until Keyword Succeeds    30s    15s    Utils.Check For Elements At URI    ${HWVTEP_NETWORK_TOPOLOGY}    ${LS_entries}    session

TC07 Verify Ping Within Second Network and Flows
    [Documentation]    Datapath connectivity validation for second network.
    ${output}=    Wait Until Keyword Succeeds    60s    10s    OpenstackOperations.Execute Command on VM Instance    ${NET_2}    ${port_ip_list[1]}
    ...    ping -c 3 ${BM_PORT2_IP}
    Log    ${output}
    L2GatewayOperations.Verify Ping Is Successful    ${output}
    Wait Until Keyword Succeeds    30s    5s    L2GatewayOperations.Verify Ping In Namespace Extra Timeout    ${HWVTEP_NS2}    ${BM_PORT2_MAC}    ${port_ip_list[1]}

TC08 Verify Flows, Groups And Ping From Hwvtep Namespace
    [Documentation]    Unicast and Broadcast traffic path validations
    L2GatewayOperations.Start Command In Hwvtep    ${NETNS_EXEC} ${HWVTEP_NS2} nohup ping -c20 ${port_ip_list[1]} &    ${HWVTEP_IP}
    ${dst_mac_list}=    Create List    ${BM_PORT2_MAC}    ${port_mac_list[1]}
    L2GatewayOperations.Verify Flow And Group Entries    ${OS_CMP1_CONN_ID}    ${dst_mac_list}    ${NET_2_SEGID}    True    2

TC09 Verify Ping Fails Between Two Networks
    [Documentation]    Validate that HWVTEP does not allow connectivity between two L2 networks.
    ${output}=    Wait Until Keyword Succeeds    60s    10s    OpenstackOperations.Execute Command on VM Instance    ${NET_2}    ${port_ip_list[1]}
    ...    ping -c 3 ${BM_PORT1_IP}
    Log    ${output}
    L2GatewayOperations.Verify If Ping Failed    ${output}

TC10 Delete L2-gateway-connection with Second Network And Verify
    [Documentation]    Validate the entries and datapath after deleting L2gateway connection.
    L2GatewayOperations.Delete L2Gateway Connection    ${L2GW_NAME2}
    ${output}=    Wait Until Keyword Succeeds    60s    10s    OpenstackOperations.Execute Command on VM Instance    ${NET_2}    ${port_ip_list[1]}
    ...    ping -c 3 ${BM_PORT2_IP}
    Log    ${output}
    L2GatewayOperations.Verify If Ping Failed    ${output}
    ${mac_entries}=    Create List    ${port_mac_list[1]}    unknown-dst
    ${port_list}=    Create List    ${NS_PORT2}
    L2GatewayOperations.Verify Entries Not in Hwvtep DB Dump    ${hwvtep_conn_id}    ${NET2_ID}    ${hwvtep_bridge}    ${DEF_CONN_SEG_ID}    ${mac_entries}    ${port_list}
    ${LS_entries}=    Create List    ${NET2_ID}    ${port_mac_list[1]}
    Wait Until Keyword Succeeds    30s    15s    Utils.Check For Elements Not At URI    ${HWVTEP_NETWORK_TOPOLOGY}    ${LS_entries}    session
    ${dst_mac_list}=    Create List    ${BM_PORT2_MAC}
    L2GatewayOperations.Verify Flow And Group Entries    ${OS_CMP1_CONN_ID}    ${dst_mac_list}    ${NET_2_SEGID}    False    1

TC11 Reconfigure L2gateway Connection and Verify
    [Documentation]    Reconfigure L2gateway connection and verify datapath connectivity
    L2GatewayOperations.Create Verify L2Gateway Connection    ${L2GW_NAME2}    ${NET_2}
    ${mac_entries}=    Create List    ${port_mac_list[1]}    unknown-dst
    ${port_list}=    Create List    ${NS_PORT2}
    L2GatewayOperations.Verify Entries in Hwvtep DB Dump    ${hwvtep_conn_id}    ${NET2_ID}    ${hwvtep_bridge}    ${DEF_CONN_SEG_ID}    ${mac_entries}    ${port_list}
    ${output}=    Wait Until Keyword Succeeds    60s    10s    OpenstackOperations.Execute Command on VM Instance    ${NET_2}    ${port_ip_list[1]}
    ...    ping -c 3 ${BM_PORT2_IP}
    Log    ${output}
    L2GatewayOperations.Verify Ping Is Successful    ${output}
    Wait Until Keyword Succeeds    30s    5s    L2GatewayOperations.Verify Ping In Namespace Extra Timeout    ${HWVTEP_NS2}    ${BM_PORT2_MAC}    ${port_ip_list[1]}
    ${LS_entries}=    Create List    ${NET2_ID}    ${port_mac_list[1]}
    Wait Until Keyword Succeeds    30s    15s    Utils.Check For Elements At URI    ${HWVTEP_NETWORK_TOPOLOGY}    ${LS_entries}    session
    ${dst_mac_list}=    Create List    ${BM_PORT2_MAC}
    L2GatewayOperations.Verify Flow And Group Entries    ${OS_CMP1_CONN_ID}    ${dst_mac_list}    ${NET_2_SEGID}    True    2

TC12 Delete All L2gateway Connections and Verify Ping
    [Documentation]    Delete all existing l2gateway connections and devices and validate the removal of all entries previously configured.
    L2GatewayOperations.Delete L2Gateway Connection    ${L2GW_NAME1}
    L2GatewayOperations.Delete L2Gateway Connection    ${L2GW_NAME2}
    L2GatewayOperations.Delete L2Gateway    ${L2GW_NAME1}
    L2GatewayOperations.Delete L2Gateway    ${L2GW_NAME2}
    ${output}=    Wait Until Keyword Succeeds    60s    10s    OpenstackOperations.Execute Command on VM Instance    ${NET_1}    ${port_ip_list[0]}
    ...    ping -c 3 ${BM_PORT1_IP}
    Log    ${output}
    L2GatewayOperations.Verify If Ping Failed    ${output}
    ${output}=    Wait Until Keyword Succeeds    60s    10s    OpenstackOperations.Execute Command on VM Instance    ${NET_2}    ${port_ip_list[1]}
    ...    ping -c 3 ${BM_PORT2_IP}
    Log    ${output}
    L2GatewayOperations.Verify If Ping Failed    ${output}
    ${dst_mac_list}=    Create List    ${BM_PORT1_MAC}
    L2GatewayOperations.Verify Flow And Group Entries    ${OS_CMP1_CONN_ID}    ${dst_mac_list}    ${NET_1_SEGID}    False    1
    ${dst_mac_list}=    Create List    ${BM_PORT2_MAC}
    L2GatewayOperations.Verify Flow And Group Entries    ${OS_CMP1_CONN_ID}    ${dst_mac_list}    ${NET_2_SEGID}    False    1

TC13 Verify Hwvtep DB After Deletion of L2GWs
    [Documentation]    Validate the removal of entries in the HWVTEP database.
    ${mac_entries}=    Create List    ${port_mac_list[0]}    unknown-dst
    ${port_list}=    Create List    ${NS_PORT1}
    L2GatewayOperations.Verify Entries Not in Hwvtep DB Dump    ${hwvtep_conn_id}    ${NET1_ID}    ${hwvtep_bridge}    ${DEF_CONN_SEG_ID}    ${mac_entries}    ${port_list}
    ${mac_entries}=    Create List    ${port_mac_list[1]}    unknown-dst
    ${port_list}    Create List    ${NS_PORT2}
    L2GatewayOperations.Verify Entries Not in Hwvtep DB Dump    ${hwvtep_conn_id}    ${NET2_ID}    ${hwvtep_bridge}    ${DEF_CONN_SEG_ID}    ${mac_entries}    ${port_list}
    ${LS_entries}=    Create List    ${NET1_ID}    ${port_mac_list[0]}    ${NET2_ID}    ${port_mac_list[1]}
    Wait Until Keyword Succeeds    30s    3s    Utils.Check For Elements Not At URI    ${HWVTEP_NETWORK_TOPOLOGY}    ${LS_entries}    session

TC14 Disconnect Hwvtep Node And Verify
    [Documentation]    Validate the operational topology in controller when the HWVTEP device is disconnected.
    ${output}=    L2gatewayOperations.Exec Command    ${hwvtep_conn_id}    sudo vtep-ctl del-manager
    Log    ${output}
    ${output}=    L2gatewayOperations.Exec Command    ${hwvtep_conn_id}    sudo vtep-ctl list Manager
    Log    ${output}
    Should Not Contain Any    ${output}    ${odl_ip}    ACTIVE
    ${list_to_check}=    Create List    ${hwvtep_ip}    ${hwvtep_bridge}
    Wait Until Keyword Succeeds    30s    3s    Utils.Check For Elements Not At URI    ${HWVTEP_NETWORK_TOPOLOGY}    ${list_to_check}    session

*** Keywords ***
Network Suite Setup
    [Documentation]    Configuration of openstack networks and VMs
    OpenStackOperations.Create Network    ${NET_1}    ${NET_ADDT_ARG} ${NET_1_SEGID}
    OpenStackOperations.Create Network    ${NET_2}    ${NET_ADDT_ARG} ${NET_2_SEGID}
    OpenStackOperations.Create SubNet    ${NET_1}    ${SUBNET_1}    ${SUBNET_RANGE1}    ${SUBNET_ADDT_ARG}
    OpenStackOperations.Create SubNet    ${NET_2}    ${SUBNET_2}    ${SUBNET_RANGE2}    ${SUBNET_ADDT_ARG}
    OpenStackOperations.Create And Configure Security Group    ${SECURITY_GROUP_L2GW}
    OpenStackOperations.Create Port    ${NET_1}    ${OVS_PORT_1}    ${SECURITY_GROUP_L2GW}
    OpenStackOperations.Create Port    ${NET_2}    ${OVS_PORT_2}    ${SECURITY_GROUP_L2GW}
    ${output}=    OpenStackOperations.List Networks
    Should Contain    ${output}    ${NET_1}
    Should Contain    ${output}    ${NET_2}
    ${output}=    OpenStackOperations.List Subnets
    Should Contain    ${output}    ${SUBNET_1}
    Should Contain    ${output}    ${SUBNET_2}
    OpenStackOperations.Create Nano Flavor
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${OVS_PORT_1}    ${OVS_VM1_NAME}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP_L2GW}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${OVS_PORT_2}    ${OVS_VM2_NAME}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP_L2GW}
    Wait Until Keyword Succeeds    12s    3s    L2GatewayOperations.Attach Port To Hwvtep Namespace    ${BM_PORT1_MAC}    ${HWVTEP_NS1}    ${NS_TAP1}
    ...    ${hwvtep_conn_id}    ${BM_PORT1_IP}
    Wait Until Keyword Succeeds    12s    3s    L2GatewayOperations.Attach Port To Hwvtep Namespace    ${BM_PORT2_MAC}    ${HWVTEP_NS2}    ${NS2_TAP1}
    ...    ${hwvtep_conn_id}    ${BM_PORT2_IP}
    ${port_mac_list}=    Create List
    Set Suite Variable    ${port_mac_list}
    ${port_ip_list}=    Create List
    Set Suite Variable    ${port_ip_list}
    @{port_list}=    Create List    ${OVS_PORT_1}    ${OVS_PORT_2}
    : FOR    ${port}    IN    @{port_list}
    \    ${port_mac}=    OpenstackOperations.Get Port Mac    ${port}
    \    ${port_ip}=    OpenstackOperations.Get Port Ip    ${port}
    \    Append To List    ${port_mac_list}    ${port_mac}
    \    Append To List    ${port_ip_list}    ${port_ip}
    @{VM_list}=    Create List    ${OVS_VM1_NAME}    ${OVS_VM2_NAME}
    Wait Until Keyword Succeeds    120s    10s    L2GatewayOperations.Verify Nova VM IP    ${port_ip_list}    @{VM_list}

Hwvtep Suite Setup
    [Documentation]    Configures hwvtep on Tools system VM
    ${hwvtep_conn_id}=    L2gwUtils.Create And Get Hwvtep Connection Id    ${HWVTEP_IP}
    Set Suite Variable    ${hwvtep_conn_id}
    L2gwUtils.Cleanup Hwvtep Configuration    ${hwvtep_conn_id}    ${HWVTEP_BRIDGE}
    L2gwUtils.Cleanup Namespace Configuration    ${hwvtep_conn_id}    ${HWVTEP_PORT_LIST}    ${HWVTEP_NS_LIST}
    L2gwUtils.Create And Configure Hwvtep    ${hwvtep_conn_id}    ${HWVTEP_IP}    ${HWVTEP_BRIDGE}
    L2gwUtils.Create Namespace And Port    ${hwvtep_conn_id}    ${HWVTEP_NS_LIST[0]}    ${HWVTEP_PORT_LIST[0]}    ${NS_TAP1}    ${HWVTEP_BRIDGE}
    L2gwUtils.Create Namespace And Port    ${hwvtep_conn_id}    ${HWVTEP_NS_LIST[1]}    ${HWVTEP_PORT_LIST[1]}    ${NS2_TAP1}    ${HWVTEP_BRIDGE}
    Wait Until Keyword Succeeds    15s    1s    L2gwUtils.Validate Hwvtep Configuration    ${hwvtep_conn_id}    ${HWVTEP_BRIDGE}    ${HWVTEP_IP}
    ...    ${HWVTEP_PORT_LIST}

Basic Suite Setup
    [Documentation]    Test Suite setup
    OpenStackOperations.OpenStack Suite Setup
    Hwvtep Suite Setup
    Network Suite Setup

Basic Suite Teardown
    [Documentation]    Test Suite Teardown
    L2gwUtils.Cleanup Hwvtep Configuration    ${hwvtep_conn_id}    ${HWVTEP_BRIDGE}
    L2gwUtils.Cleanup Namespace Configuration    ${hwvtep_conn_id}    ${HWVTEP_PORT_LIST}    ${HWVTEP_NS_LIST}
    Openstack Suite Teardown

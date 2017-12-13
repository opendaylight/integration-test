*** Settings ***
Documentation     Test Suite for verification of HWVTEP usecases
Suite Setup       BuiltIn.Run Keywords    Basic Suite Setup
Suite Teardown    Basic Suite Teardown
Test Teardown     Get L2gw Debug Info
Resource          ../../libraries/L2GatewayOperations.robot

*** Test Cases ***
TC01 Configure Hwvtep Manager OVS Manager Controller And Verify
    L2GatewayOperations.Add Vtep Manager And Verify    ${ODL_IP}

TC02 Create First Set Of Network Subnet And Ports
    OpenStackOperations.Create Network    ${NET_1}    ${NET_ADDT_ARG} ${NET_1_SEGID}
    ${output}=    OpenStackOperations.List Networks
    Should Contain    ${output}    ${NET_1}
    OpenStackOperations.Create SubNet    ${NET_1}    ${SUBNET_1}    ${SUBNET_RANGE1}    ${SUBNET_ADDT_ARG}
    ${output}=    OpenStackOperations.List Subnets
    Should Contain    ${output}    ${SUBNET_1}
    OpenStackOperations.Create And Configure Security Group    ${SECURITY_GROUP_L2GW}
    OpenStackOperations.Create Port    ${NET_1}    ${OVS_PORT_1}    sg=${SECURITY_GROUP_L2GW}
    OpenStackOperations.Create Neutron Port With Additional Params    ${NET_1}    ${HWVTEP_PORT_1}    ${SECURITY_GROUP_L2GW_NONE}
    ${port_mac}=    Get Port Mac    ${OVS_PORT_1}    #port_mac[0]
    ${port_ip}=    Get Port Ip    ${OVS_PORT_1}    #port_ip[0]
    Append To List    ${port_mac_list}    ${port_mac}
    Append To List    ${port_ip_list}    ${port_ip}
    ${port_mac}=    Get Port Mac    ${HWVTEP_PORT_1}    #port_mac[1]
    ${port_ip}=    Get Port Ip    ${HWVTEP_PORT_1}    #port_ip[1]
    Append To List    ${port_mac_list}    ${port_mac}
    Append To List    ${port_ip_list}    ${port_ip}

TC03 Update Port For Hwvtep And Attach Port To Namespace
    L2GatewayOperations.Update Port For Hwvtep    ${HWVTEP_PORT_1}
    Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Attach Port To Hwvtep Namespace    ${port_mac_list[1]}    ${HWVTEP_NS1}    ${NS_TAP1}

TC04 Create Vms On Compute Node
    OpenStackOperations.Create Nano Flavor
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${OVS_PORT_1}    ${OVS_VM1_NAME}    ${OVS_IP}
    ${vm_ip}=    Wait Until Keyword Succeeds    60s    2s    L2GatewayOperations.Verify Nova VM IP    ${OVS_VM1_NAME}
    Log    ${vm_ip}
    Should Contain    ${vm_ip}    ${port_ip_list[0]}

TC05 Create L2Gateway And Connection And Verify
    ${output}=    L2GatewayOperations.Create Verify L2Gateway    ${HWVTEP_BRIDGE}    ${NS_PORT1}    ${L2GW_NAME1}
    Log    ${output}
    ${output}=    Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Create Verify L2Gateway Connection    ${L2GW_NAME1}    ${NET_1}
    Log    ${output}
    Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Verify Ovs Tunnel    ${HWVTEP_IP}    ${OVS_IP}
    ${output}=    ITM Get Tunnels
    Log    ${output}
    Should Contain    ${output}    physicalswitch/${HWVTEP_BRIDGE}
    Wait Until Keyword Succeeds    30s    1s    L2GatewayOperations.Verify Vtep List    ${hwvtep_conn_id}    ${TUNNEL_TABLE}    enable="true"
    ${phy_port_out}=    Get Vtep List    ${PHYSICAL_PORT_TABLE}
    Validate Regexp In String    ${phy_port_out}    ${VLAN_BINDING_REGEX}    1
    ${list}=    Create List    ${OVS_IP}    ${HWVTEP_IP}
    Wait Until Keyword Succeeds    30s    1s    L2GatewayOperations.Verify Vtep List    ${hwvtep_conn_id}    ${PHYSICAL_LOCATOR_TABLE}    @{list}
    Wait Until Keyword Succeeds    30s    1s    L2GatewayOperations.Verify Vtep List    ${hwvtep_conn_id}    ${UCAST_MACS_REMOTE_TABLE}    ${port_mac_list[0]}

TC06 Dhcp Ip Allocation For Hwvtep Tap Port
    Wait Until Keyword Succeeds    180s    10s    L2GatewayOperations.Namespace Dhclient Verify    ${HWVTEP_NS1}    ${NS_TAP1}    ${port_ip_list[1]}

TC07 Verify Ping From Compute Node Vm To Hwvtep
    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NET_1}    ${port_ip_list[0]}
    ...    ping -c 3 ${port_ip_list[1]}
    Log    ${output}
    Should Not Contain    ${output}    ${PACKET_LOSS}
    ${src_mac_list}=    Create List    ${port_mac_list[0]}
    ${dst_mac_list}=    Create List    ${port_mac_list[1]}
    Wait Until Keyword Succeeds    30s    5s    L2GatewayOperations.Verify Elan Flow Entries    ${OVS_IP}    ${src_mac_list}    ${dst_mac_list}

TC08 Ping Verification From Namespace Tap To Ovs Vm
    Wait Until Keyword Succeeds    30s    5s    L2GatewayOperations.Verify Ping In Namespace Extra Timeout    ${HWVTEP_NS1}    ${port_mac_list[1]}    ${port_ip_list[0]}

TC09 Additional Network Subnet Port Creation
    OpenStackOperations.Create Network    ${NET_2}    ${NET_ADDT_ARG} ${NET_2_SEGID}
    ${output}=    OpenStackOperations.List Networks
    Should Contain    ${output}    ${NET_2}
    OpenStackOperations.Create SubNet    ${NET_2}    ${SUBNET_2}    ${SUBNET_RANGE2}    ${SUBNET_ADDT_ARG}
    ${output}=    OpenStackOperations.List Subnets
    Should Contain    ${output}    ${SUBNET_2}
    OpenStackOperations.Create Port    ${NET_2}    ${OVS_PORT_2}    sg=${SECURITY_GROUP_L2GW}
    OpenStackOperations.Create Neutron Port With Additional Params    ${NET_2}    ${HWVTEP_PORT_2}    ${SECURITY_GROUP_L2GW_NONE}
    ${port_mac}=    Get Port Mac    ${OVS_PORT_2}    #port_mac[2]
    ${port_ip}=    Get Port Ip    ${OVS_PORT_2}    #port_ip[2]
    Append To List    ${port_mac_list}    ${port_mac}
    Append To List    ${port_ip_list}    ${port_ip}
    ${port_mac}=    Get Port Mac    ${HWVTEP_PORT_2}    #port_mac[3]
    ${port_ip}=    Get Port Ip    ${HWVTEP_PORT_2}    #port_ip[3]
    Append To List    ${port_mac_list}    ${port_mac}
    Append To List    ${port_ip_list}    ${port_ip}

TC10 Update And Attach Second Port To Hwvtep Create L2gw Connection
    L2GatewayOperations.Update Port For Hwvtep    ${HWVTEP_PORT_2}
    Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Attach Port To Hwvtep Namespace    ${port_mac_list[3]}    ${HWVTEP_NS2}    ${NS2_TAP1}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${OVS_PORT_2}    ${OVS_VM2_NAME}    ${OVS_IP}
    ${vm_ip}=    Wait Until Keyword Succeeds    60s    2s    L2GatewayOperations.Verify Nova VM IP    ${OVS_VM2_NAME}
    Log    ${vm_ip}
    Should Contain    ${vm_ip}    ${port_ip_list[2]}
    ${output}=    L2GatewayOperations.Create Verify L2Gateway    ${HWVTEP_BRIDGE}    ${NS_PORT2}    ${L2GW_NAME2}
    Log    ${output}
    ${output}=    L2GatewayOperations.Create Verify L2Gateway Connection    ${L2GW_NAME2}    ${NET_2}
    Log    ${output}
    ${phy_port_out}=    Get Vtep List    ${PHYSICAL_PORT_TABLE}
    Validate Regexp In String    ${phy_port_out}    ${VLAN_BINDING_REGEX}    2

TC11 Dhcp Ip Allocation And Ping Validation Within Second Network
    Wait Until Keyword Succeeds    180s    10s    L2GatewayOperations.Namespace Dhclient Verify    ${HWVTEP_NS2}    ${NS2_TAP1}    ${port_ip_list[3]}
    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NET_2}    ${port_ip_list[2]}
    ...    ping -c 3 ${port_ip_list[3]}
    Log    ${output}
    Should Not Contain    ${output}    ${PACKET_LOSS}
    ${src_mac_list}=    Create List    ${port_mac_list[2]}
    ${dst_mac_list}=    Create List    ${port_mac_list[3]}
    Wait Until Keyword Succeeds    30s    5s    L2GatewayOperations.Verify Elan Flow Entries    ${OVS_IP}    ${src_mac_list}    ${dst_mac_list}
    Wait Until Keyword Succeeds    30s    5s    L2GatewayOperations.Verify Ping In Namespace Extra Timeout    ${HWVTEP_NS2}    ${port_mac_list[3]}    ${port_ip_list[2]}

TC12 Ping Between Vm In Second Network To Namespace In First Network
    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NET_2}    ${port_ip_list[2]}
    ...    ping -c 3 ${port_ip_list[1]}
    Log    ${output}
    Should Contain    ${output}    ${PACKET_LOSS}

TC13 Ping Between Namespace In Second Network To Vm In First Network
    Wait Until Keyword Succeeds    30s    5s    L2GatewayOperations.Verify Ping Fails In Namespace    ${HWVTEP_NS2}    ${port_mac_list[3]}    ${port_ip_list[0]}

TC99 Cleanup L2Gateway Connection Itm Tunnel Port Subnet And Network
    L2GatewayOperations.Delete L2Gateway Connection    ${L2GW_NAME1}
    L2GatewayOperations.Delete L2Gateway Connection    ${L2GW_NAME2}
    L2GatewayOperations.Delete L2Gateway    ${L2GW_NAME1}
    L2GatewayOperations.Delete L2Gateway    ${L2GW_NAME2}
    OpenStackOperations.Delete Vm Instance    ${OVS_VM1_NAME}
    OpenStackOperations.Delete Vm Instance    ${OVS_VM2_NAME}
    OpenStackOperations.Delete Port    ${OVS_PORT_1}
    OpenStackOperations.Delete Port    ${OVS_PORT_2}
    OpenStackOperations.Delete Port    ${HWVTEP_PORT_1}
    OpenStackOperations.Delete Port    ${HWVTEP_PORT_2}
    OpenStackOperations.Delete SubNet    ${SUBNET_1}
    OpenStackOperations.Delete SubNet    ${SUBNET_2}
    OpenStackOperations.Delete Network    ${NET_1}
    OpenStackOperations.Delete Network    ${NET_2}

*** Keywords ***
Basic Suite Setup
    [Documentation]    Basic Suite Setup required for the HWVTEP Test Suite
    RequestsLibrary.Create Session    alias=session    url=http://${ODL_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${os_cntl_conn_id}=    SSHLibrary.Open Connection    ${OS_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${os_cntl_conn_id}
    Set Suite Variable    ${os_cntl_conn_id}
    Log    ${OS_IP}
    Log    ${OS_USER}
    Log    ${OS_PASSWORD}
    Wait Until Keyword Succeeds    30s    5s    Flexible SSH Login    ${OS_USER}    ${OS_PASSWORD}
    Write Commands Until Prompt    cd ${DEVSTACK_DEPLOY_PATH}; source openrc admin admin    30s
    ${hwvtep_conn_id}=    SSHLibrary.Open Connection    ${HWVTEP_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${hwvtep_conn_id}
    Set Suite Variable    ${hwvtep_conn_id}
    Log    ${DEFAULT_USER}
    Log    ${DEFAULT_PASSWORD}
    Wait Until Keyword Succeeds    30s    5s    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${ovs_conn_id}=    SSHLibrary.Open Connection    ${OVS_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${ovs_conn_id}
    Set Suite Variable    ${ovs_conn_id}
    Wait Until Keyword Succeeds    30s    5s    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${port_mac_list}=    Create List
    Set Suite Variable    ${port_mac_list}
    ${port_ip_list}=    Create List
    Set Suite Variable    ${port_ip_list}

Basic Suite Teardown
    Switch Connection    ${os_cntl_conn_id}
    close connection
    Switch Connection    ${hwvtep_conn_id}
    close connection
    Switch Connection    ${ovs_conn_id}
    close connection

*** Settings ***
Documentation     Test Suite for verification of HWVTEP usecases
Suite Setup       BuiltIn.Run Keywords    Basic Suite Setup
Suite Teardown    Basic Suite Teardown
Test Teardown     Get L2gw Debug Info
Resource          ../../libraries/L2GatewayOperations.robot

*** Test Cases ***
TC01 Connect Hwvtep Manager For First Tor
    L2GatewayOperations.Add Vtep Manager And Verify    ${ODL_IP}

TC02 Create Network Subnet And Ports For Hwvtep
    OpenStackOperations.Create Network    ${NET_1}    ${NET_ADDT_ARG}${NET_1_SEGID}
    ${output}=    OpenStackOperations.List Networks
    Should Contain    ${output}    ${NET_1}
    OpenStackOperations.Create SubNet    ${NET_1}    ${SUBNET_1}    ${SUBNET_RANGE1}    ${SUBNET_ADDT_ARG}
    ${output}=    OpenStackOperations.List Subnets
    Should Contain    ${output}    ${SUBNET_1}
    OpenStackOperations.Create And Configure Security Group    ${SECURITY_GROUP_L2GW}
    OpenStackOperations.Create Port    ${NET_1}    ${HWVTEP_PORT_1}    sg=${SECURITY_GROUP_L2GW}
    OpenStackOperations.Create Port    ${NET_1}    ${HWVTEP_PORT_2}    sg=${SECURITY_GROUP_L2GW}
    ${port_mac}=    Get Port Mac    ${HWVTEP_PORT_1}    #port_mac[0]
    ${port_ip}=    Get Port Ip    ${HWVTEP_PORT_1}    #port_ip[0]
    Append To List    ${port_mac_list}    ${port_mac}
    Append To List    ${port_ip_list}    ${port_ip}
    ${port_mac}=    Get Port Mac    ${HWVTEP_PORT_2}    #port_mac[1]
    ${port_ip}=    Get Port Ip    ${HWVTEP_PORT_2}    #port_ip[1]
    Append To List    ${port_mac_list}    ${port_mac}
    Append To List    ${port_ip_list}    ${port_ip}

TC03 Update Port For Hwvtep And Attach Port To Namespace
    L2GatewayOperations.Update Port For Hwvtep    ${HWVTEP_PORT_1}
    L2GatewayOperations.Update Port For Hwvtep    ${HWVTEP_PORT_2}
    Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Attach Port To Hwvtep Namespace    ${port_mac_list[0]}    ${HWVTEP_NS1}    ${NS_TAP1}
    Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Attach Port To Hwvtep Namespace    ${port_mac_list[1]}    ${HWVTEP_NS2}    ${NS2_TAP1}

TC04 Create L2Gateway And Connection Between First Hwvtep Namespaces
    ${output}=    L2GatewayOperations.Create Verify L2Gateway    ${HWVTEP_BRIDGE}    "${NS_PORT1};${NS_PORT2}"    ${L2GW_NAME1}
    Log    ${output}
    ${output}=    L2GatewayOperations.Create Verify L2Gateway Connection    ${L2GW_NAME1}    ${NET_1}
    Log    ${output}
    ${output}=    ITM Get Tunnels
    Log    ${output}
    Should Contain    ${output}    physicalswitch/${HWVTEP_BRIDGE}
    Wait Until Keyword Succeeds    30s    1s    L2GatewayOperations.Verify Vtep List    ${hwvtep_conn_id}    ${TUNNEL_TABLE}    enable="true"
    ${phy_port_out}=    Get Vtep List    ${PHYSICAL_PORT_TABLE}
    Validate Regexp In String    ${phy_port_out}    ${VLAN_BINDING_REGEX}    2
    ${list}=    Create List    ${OS_IP}    ${HWVTEP_IP}
    Wait Until Keyword Succeeds    30s    1s    L2GatewayOperations.Verify Vtep List    ${hwvtep_conn_id}    ${PHYSICAL_LOCATOR_TABLE}    @{list}
    #Wait Until Keyword Succeeds    30s    1s    L2GatewayOperations.Verify Vtep List    ${hwvtep_conn_id}    ${UCAST_MACS_REMOTE_TABLE}    ${port_mac_list[0]}

TC05 Dhcp Ip Allocation For Hwvtep First Port
    Wait Until Keyword Succeeds    180s    10s    L2GatewayOperations.Namespace Dhclient Verify    ${HWVTEP_NS1}    ${NS_TAP1}    ${port_ip_list[0]}

TC06 Dhcp Ip Allocation For Hwvtep Second Port
    Wait Until Keyword Succeeds    180s    10s    L2GatewayOperations.Namespace Dhclient Verify    ${HWVTEP_NS2}    ${NS2_TAP1}    ${port_ip_list[1]}

TC07 Ping Verification In Hwvtep From First Port To Second
    Wait Until Keyword Succeeds    30s    5s    L2GatewayOperations.Verify Ping In Namespace Extra Timeout    ${HWVTEP_NS1}    ${port_mac_list[0]}    ${port_ip_list[1]}

TC08 Ping Verification In Hwvtep From Second Port To First
    Wait Until Keyword Succeeds    30s    5s    L2GatewayOperations.Verify Ping In Namespace Extra Timeout    ${HWVTEP_NS2}    ${port_mac_list[1]}    ${port_ip_list[0]}

TC09 Ovs Manager Addition
    L2GatewayOperations.Add Ovs Bridge Manager Controller And Verify

TC10 Create Ovs Port
    OpenStackOperations.Create Port    ${NET_1}    ${OVS_PORT_1}    sg=${SECURITY_GROUP_L2GW}
    ${port_mac}=    Get Port Mac    ${OVS_PORT_1}    #port_mac[2]
    ${port_ip}=    Get Port Ip    ${OVS_PORT_1}    #port_ip[2]
    Append To List    ${port_mac_list}    ${port_mac}
    Append To List    ${port_ip_list}    ${port_ip}

TC11 Create Nova Vm On Compute Node1
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${OVS_PORT_1}    ${OVS_VM1_NAME}    ${OVS_IP}
    ${vm_ip}=    Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Verify Nova VM IP    ${OVS_VM1_NAME}
    Log    ${vm_ip}
    Should Contain    ${vm_ip[0]}    ${port_ip_list[2]}

TC12 Verify Ping From Compute Node1 Vm To First Namespace Port
    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NET_1}    ${port_ip_list[2]}
    ...    ping -c 3 ${port_ip_list[0]}
    Log    ${output}
    Should Not Contain    ${output}    ${PACKET_LOSS}

TC13 Verify Ping From Compute Node1 Vm To Second Namespace Port
    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NET_1}    ${port_ip_list[2]}
    ...    ping -c 3 ${port_ip_list[1]}
    Log    ${output}
    Should Not Contain    ${output}    ${PACKET_LOSS}

TC31 Connect Hwvtep Manager For Second Hwvtep
    L2GatewayOperations.Add Vtep Manager And Verify    ${ODL_IP}    ${hwvtep2_conn_id}

TC32 Create Network Subnet And Ports For Second Hwvtep
    OpenStackOperations.Create Port    ${NET_1}    ${HWVTEP2_PORT_1}    sg=${SECURITY_GROUP_L2GW}
    OpenStackOperations.Create Port    ${NET_1}    ${HWVTEP2_PORT_2}    sg=${SECURITY_GROUP_L2GW}
    ${port_mac}=    Get Port Mac    ${HWVTEP2_PORT_1}    #port_mac[3]
    ${port_ip}=    Get Port Ip    ${HWVTEP2_PORT_1}    #port_ip[3]
    Append To List    ${port_mac_list}    ${port_mac}
    Append To List    ${port_ip_list}    ${port_ip}
    ${port_mac}=    Get Port Mac    ${HWVTEP2_PORT_2}    #port_mac[4]
    ${port_ip}=    Get Port Ip    ${HWVTEP2_PORT_2}    #port_ip[4]
    Append To List    ${port_mac_list}    ${port_mac}
    Append To List    ${port_ip_list}    ${port_ip}

TC33 Update Port For Hwvtep And Attach Port To Namespace
    L2GatewayOperations.Update Port For Hwvtep    ${HWVTEP2_PORT_1}
    L2GatewayOperations.Update Port For Hwvtep    ${HWVTEP2_PORT_2}
    Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Attach Port To Hwvtep Namespace    ${port_mac_list[3]}    ${HWVTEP2_NS1}    ${NS3_TAP1}
    ...    ${hwvtep2_conn_id}
    Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Attach Port To Hwvtep Namespace    ${port_mac_list[4]}    ${HWVTEP2_NS2}    ${NS4_TAP1}
    ...    ${hwvtep2_conn_id}

TC34 Create L2Gateway And Connection Between First Hwvtep Namespaces
    L2GatewayOperations.Create Itm Tunnel Between Hwvtep and Ovs    ${ovs2_conn_id}    ${OVS2_IP}
    ${output}=    L2GatewayOperations.Create Verify L2Gateway    ${HWVTEP2_BRIDGE}    "${NS2_PORT1};${NS2_PORT2}"    ${L2GW_NAME2}
    Log    ${output}
    ${output}=    L2GatewayOperations.Create Verify L2Gateway Connection    ${L2GW_NAME2}    ${NET_1}
    Log    ${output}
    ${output}=    ITM Get Tunnels
    Log    ${output}
    Should Contain    ${output}    physicalswitch/${HWVTEP2_BRIDGE}
    Wait Until Keyword Succeeds    30s    1s    L2GatewayOperations.Verify Vtep List    ${hwvtep2_conn_id}    ${TUNNEL_TABLE}    enable="true"
    ${phy_port_out}=    Get Vtep List    ${PHYSICAL_PORT_TABLE}    ${hwvtep2_conn_id}
    Validate Regexp In String    ${phy_port_out}    ${VLAN_BINDING_REGEX}    2
    ${list}=    Create List    ${OS_IP}    ${HWVTEP2_IP}
    Wait Until Keyword Succeeds    30s    1s    L2GatewayOperations.Verify Vtep List    ${hwvtep2_conn_id}    ${PHYSICAL_LOCATOR_TABLE}    @{list}
    #Wait Until Keyword Succeeds    30s    1s    L2GatewayOperations.Verify Vtep List    ${hwvtep2_conn_id}    ${UCAST_MACS_REMOTE_TABLE}    ${port_mac_list[3]}

TC35 Dhcp Ip Allocation For Hwvtep First Port
    Wait Until Keyword Succeeds    180s    10s    L2GatewayOperations.Namespace Dhclient Verify    ${HWVTEP2_NS1}    ${NS3_TAP1}    ${port_ip_list[3]}
    ...    ${hwvtep2_conn_id}    ${HWVTEP2_IP}

TC36 Dhcp Ip Allocation For Hwvtep Second Port
    Wait Until Keyword Succeeds    180s    10s    L2GatewayOperations.Namespace Dhclient Verify    ${HWVTEP2_NS2}    ${NS4_TAP1}    ${port_ip_list[4]}
    ...    ${hwvtep2_conn_id}    ${HWVTEP2_IP}

TC37 Ping Verification In Hwvtep From First Port To Second
    Wait Until Keyword Succeeds    30s    5s    L2GatewayOperations.Verify Ping In Namespace Extra Timeout    ${HWVTEP2_NS1}    ${port_mac_list[3]}    ${port_ip_list[4]}
    ...    ${hwvtep2_conn_id}    ${HWVTEP2_IP}

TC38 Ping Verification In Hwvtep From Second Port To First
    Wait Until Keyword Succeeds    30s    5s    L2GatewayOperations.Verify Ping In Namespace Extra Timeout    ${HWVTEP2_NS2}    ${port_mac_list[4]}    ${port_ip_list[3]}
    ...    ${hwvtep2_conn_id}    ${HWVTEP2_IP}

TC39 Ovs Manager Addition
    L2GatewayOperations.Add Ovs Bridge Manager Controller And Verify    ${ovs2_conn_id}    ${HWVTEP2_BRIDGE}

TC40 Create Ovs Port
    OpenStackOperations.Create Port    ${NET_1}    ${OVS2_PORT_1}    sg=${SECURITY_GROUP_L2GW}
    ${port_mac}=    Get Port Mac    ${OVS2_PORT_1}    #port_mac[5]
    ${port_ip}=    Get Port Ip    ${OVS2_PORT_1}    #port_ip[5]
    Append To List    ${port_mac_list}    ${port_mac}
    Append To List    ${port_ip_list}    ${port_ip}

TC41 Create Nova Vm On Compute Node2
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${OVS2_PORT_1}    ${OVS2_VM1_NAME}    ${OVS2_IP}
    ${vm_ip}=    Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Verify Nova VM IP    ${OVS2_VM1_NAME}
    Log    ${vm_ip}
    Should Contain    ${vm_ip[0]}    ${port_ip_list[5]}

TC42 Verify Ping From Compute Node2 Vm To First Namespace Port
    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NET_1}    ${port_ip_list[5]}
    ...    ping -c 3 ${port_ip_list[3]}
    Log    ${output}
    Should Not Contain    ${output}    ${PACKET_LOSS}

TC43 Verify Ping From Compute Node2 Vm To Second Namespace Port
    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NET_1}    ${port_ip_list[5]}
    ...    ping -c 3 ${port_ip_list[4]}
    Log    ${output}
    Should Not Contain    ${output}    ${PACKET_LOSS}

TC51 Ping From Compute Node2 Vm To First Namespace In First Hwvtep
    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NET_1}    ${port_ip_list[5]}
    ...    ping -c 3 ${port_ip_list[0]}
    Log    ${output}
    Should Not Contain    ${output}    ${PACKET_LOSS}

TC52 Ping From Compute Node2 Vm To Second Namespace In First Hwvtep
    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NET_1}    ${port_ip_list[5]}
    ...    ping -c 3 ${port_ip_list[1]}
    Log    ${output}
    Should Not Contain    ${output}    ${PACKET_LOSS}

TC53 Ping From Compute Node1 Vm To First Namespace In Second Hwvtep
    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NET_1}    ${port_ip_list[2]}
    ...    ping -c 3 ${port_ip_list[3]}
    Log    ${output}
    Should Not Contain    ${output}    ${PACKET_LOSS}

TC54 Ping From Compute Node1 Vm To Second Namespace In Second Hwvtep
    ${output}=    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NET_1}    ${port_ip_list[2]}
    ...    ping -c 3 ${port_ip_list[4]}
    Log    ${output}
    Should Not Contain    ${output}    ${PACKET_LOSS}

TC99 Clean L2Gw Connection
    L2GatewayOperations.Delete L2Gateway Connection    ${L2GW_NAME1}

TC99 Clean L2Gw
    L2GatewayOperations.Delete L2Gateway    ${L2GW_NAME1}

TC99 Clean Nova Vms
    OpenStackOperations.Delete Vm Instance    ${OVS_VM1_NAME}

TC99 Clean Ports
    OpenStackOperations.Delete Port    ${HWVTEP_PORT_1}
    OpenStackOperations.Delete Port    ${HWVTEP_PORT_2}
    OpenStackOperations.Delete Port    ${OVS_PORT_1}

TC99 Clean Subnet
    OpenStackOperations.Delete SubNet    ${SUBNET_1}

TC99 Clean Net
    OpenStackOperations.Delete Network    ${NET_1}

*** Keywords ***
Basic Suite Setup
    [Documentation]    Basic Suite Setup required for the HWVTEP Test Suite
    RequestsLibrary.Create Session    alias=session    url=http://${ODL_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${devstack_conn_id}=    SSHLibrary.Open Connection    ${OS_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${devstack_conn_id}
    Set Suite Variable    ${devstack_conn_id}
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
    ${hwvtep2_conn_id}=    SSHLibrary.Open Connection    ${HWVTEP2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${hwvtep2_conn_id}
    Set Suite Variable    ${hwvtep2_conn_id}
    Wait Until Keyword Succeeds    30s    5s    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${ovs_conn_id}=    SSHLibrary.Open Connection    ${OVS_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${ovs_conn_id}
    Set Suite Variable    ${ovs_conn_id}
    Wait Until Keyword Succeeds    30s    5s    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${ovs2_conn_id}=    SSHLibrary.Open Connection    ${OVS2_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${ovs2_conn_id}
    Set Suite Variable    ${ovs2_conn_id}
    Wait Until Keyword Succeeds    30s    5s    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${port_mac_list}=    Create List
    Set Suite Variable    ${port_mac_list}
    ${port_ip_list}=    Create List
    Set Suite Variable    ${port_ip_list}

Basic Suite Teardown
    Switch Connection    ${devstack_conn_id}
    Close Connection
    Switch Connection    ${hwvtep_conn_id}
    Close Connection
    Switch Connection    ${hwvtep2_conn_id}
    Close Connection
    Switch Connection    ${ovs_conn_id}
    Close Connection
    Switch Connection    ${ovs2_conn_id}
    Close Connection

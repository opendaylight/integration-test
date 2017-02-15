*** Settings ***
Documentation     Test Suite for verification of HWVTEP usecases
Suite Setup       BuiltIn.Run Keywords    Basic Suite Setup
Suite Teardown    Basic Suite Teardown
Test Teardown     Get L2gw Debug Info
Resource          ../../libraries/L2GatewayOperations.robot

*** Test Cases ***
TC1 Configure Hwvtep Manager OVS Manager Controller And Verify
    L2GatewayOperations.Add Vtep Manager And Verify    ${ODL_IP}
    L2GatewayOperations.Add Ovs Bridge Manager Controller And Verify

TC2 Create First Set Network Subnet Port And Vms
    OpenStackOperations.Create Network    ${NET_1}    ${NET_ADDT_ARG}${NET_1_SEGID}
    ${output}=    OpenStackOperations.List Networks
    Should Contain    ${output}    ${NET_1}
    OpenStackOperations.Create SubNet    ${NET_1}    ${SUBNET_1}    ${SUBNET_RANGE1}    ${SUBNET_ADDT_ARG}
    ${output}=    OpenStackOperations.List Subnets
    Should Contain    ${output}    ${SUBNET_1}
    OpenStackOperations.Create Neutron Port With Additional Params    ${NET_1}    ${OVS_PORT_1}
    OpenStackOperations.Create Neutron Port With Additional Params    ${NET_1}    ${HWVTEP_PORT_1}
    ${port_mac}=    Get Port Mac    ${OVS_PORT_1}
    ${port_ip}=    Get Port Ip    ${OVS_PORT_1}
    Append To List    ${port_mac_list}    ${port_mac}
    Append To List    ${port_ip_list}    ${port_ip}
    ${port_mac}=    Get Port Mac    ${HWVTEP_PORT_1}
    ${port_ip}=    Get Port Ip    ${HWVTEP_PORT_1}
    Append To List    ${port_mac_list}    ${port_mac}
    Append To List    ${port_ip_list}    ${port_ip}

TC3 Update Port For Hwvtep Configuration And Attach To Namespace
    L2GatewayOperations.Update Port For Hwvtep    ${HWVTEP_PORT_1}
    Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Attach Port To Hwvtep Namespace    ${port_mac_list[1]}    ${HWVTEP_NS1}    ${NS_TAP1}

TC4 Update First Set Ovs Port And Create Vm
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${OVS_PORT_1}    ${OVS_VM1_NAME}    ${OVS_IP}
    ${vm_ip}=    Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Verify Nova VM IP    ${OVS_VM1_NAME}
    Log    ${vm_ip}
    Should Contain    ${vm_ip[0]}    ${port_ip_list[0]}

TC5 Create Itm Tunnel L2Gateway And Connection And Verify
    L2GatewayOperations.Create Itm Tunnel Between Hwvtep and Ovs    ${OVS_IP}
    ${output}=    L2GatewayOperations.Create Verify L2Gateway    ${HWVTEP_BRIDGE}    ${NS_PORT1}    ${L2GW_NAME1}
    Log    ${output}
    ${output}=    L2GatewayOperations.Create Verify L2Gateway Connection    ${L2GW_NAME1}    ${NET_1}
    Log    ${output}
    L2GatewayOperations.Verify Ovs Tunnel    ${HWVTEP_IP}    ${OVS_IP}
    ${output}=    ITM Get Tunnels
    Log    ${output}
    Should Contain    ${output}    physicalswitch/${HWVTEP_BRIDGE}
    Wait Until Keyword Succeeds    30s    1s    L2GatewayOperations.Verify Vtep List    ${TUNNEL_TABLE}    enable="true"
    ${phy_port_out}=    Get Vtep List    ${PHYSICAL_PORT_TABLE}
    Validate Regexp In String    ${phy_port_out}    ${VLAN_BINDING_REGEX}    1
    ${list}=    Create List    ${OVS_IP}    ${HWVTEP_IP}
    Wait Until Keyword Succeeds    30s    1s    L2GatewayOperations.Verify Vtep List    ${PHYSICAL_LOCATOR_TABLE}    @{list}

TC6 Dhcp Ip Allocation To Hwvtep Tap Port
    L2GatewayOperations.Namespace Dhclient Verify    ${HWVTEP_NS1}    ${NS_TAP1}    ${port_ip_list[1]}

TC13 MCAS REMOTE Validation
    Wait Until Keyword Succeeds    30s    1s    L2GatewayOperations.Verify Vtep List    ${UCAST_MACS_REMOTE_TABLE}    ${port_mac_list[0]}

TC7 Ping Verification From Namespace Tap To Ovs Vm Background Ping
    L2GatewayOperations.Verify Ping In Namespace    ${HWVTEP_NS1}    ${port_mac_list[1]}    ${port_ip_list[0]}

TC8 Ping Verification From Namespace Tap To Ovs Vm Normal Ping Extra Timeout
    L2GatewayOperations.Verify Ping In Namespace_B    ${HWVTEP_NS1}    ${port_mac_list[1]}    ${port_ip_list[0]}

TC9 Ping From Ovs To Hwvtep
    ${output}=    Execute Command on VM Instance    ${NET_1}    ${port_ip_list[0]}    ping -c 3 ${port_ip_list[1]}
    Log    ${output}    #TC8 Ping Verification From Namespace Tap To Ovs Vm Normal Ping    #    L2GatewayOperations.Verify Ping In Namespace_A    ${HWVTEP_NS1}    ${port_mac_list[1]}
    ...    # ${port_ip_list[0]}    #TC15 Create Second Set Neutron Network Subnet Ports and Verify    #    OpenStackOperations.Create Network    # ${NET_2}    ${NET_ADDT_ARG}${NET_2_SEGID}
    ...    #    ${output}=    OpenStackOperations.List Networks    #    # Should Contain    ${output}
    ...    # ${NET_2}    #    OpenStackOperations.Create SubNet    ${NET_2}    # ${SUBNET_2}    ${SUBNET_RANGE2}
    ...    # ${SUBNET_ADDT_ARG}    #    ${output}=    OpenStackOperations.List Subnets    #    Should Contain
    ...    # ${output}    ${SUBNET_2}    #    OpenStackOperations.Create Neutron Port With Additional Params    # ${NET_2}    ${OVS_PORT_2}
    ...    #    OpenStackOperations.Create Neutron Port With Additional Params    ${NET_2}    ${HWVTEP_PORT_2}    #    ${port_mac}=
    ...    # Get Port Mac    ${OVS_PORT_2}    #    ${port_ip}=    # Get Port Ip    ${OVS_PORT_2}
    ...    #    Append To List    ${port_mac_list}    ${port_mac}    #    Append To List
    ...    # ${port_ip_list}    ${port_ip}    #    ${port_mac}=    # Get Port Mac    ${HWVTEP_PORT_2}
    ...    #    ${port_ip}=    Get Port Ip    ${HWVTEP_PORT_2}    #    Append To List
    ...    # ${port_mac_list}    ${port_mac}    #    Append To List    # ${port_ip_list}    ${port_ip}
    ...    #    #TC16 Update Second Set Ports In Controller Add To Hwvtep and Ovs    #    L2GatewayOperations.Update Port For Hwvtep    # ${HWVTEP_PORT_2}    #
    ...    # OpenStackOperations.Create Vm Instance With Port On Compute Node    ${OVS_PORT_2}    ${OVS_VM2_NAME}    ${OVS_IP}    #    ${vm_ip}=
    ...    # Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Verify Nova VM IP    # ${OVS_VM2_NAME}    #
    ...    # Log    ${vm_ip}    #    Should Contain    # ${vm_ip[0]}    ${port_ip_list[2]}
    ...    #    Wait Until Keyword Succeeds    30s    2s    # L2GatewayOperations.Attach Port To Hwvtep Namespace    ${port_mac_list[3]}
    ...    # ${HWVTEP_NS1}    # ${NS_TAP2}    #    #TC17 Create Second Set L2Gateway Connection And Verify    #    ${output}=
    ...    # L2GatewayOperations.Create Verify L2Gateway    ${HWVTEP_BRIDGE}    ${NS_PORT2}    ${L2GW_NAME2}    #    Log
    ...    # ${output}    #    ${output}=    L2GatewayOperations.Create Verify L2Gateway Connection    # ${L2GW_NAME2}    ${NET_2}
    ...    #    Log    ${output}    #    # Get L2gw Debug Info    #
    ...    # Wait Until Keyword Succeeds    30s    1s    L2GatewayOperations.Verify Vtep List    # ${TUNNEL_TABLE}    enable="true"
    ...    #    Wait Until Keyword Succeeds    30s    1s    # L2GatewayOperations.Verify Vtep List    ${UCAST_MACS_REMOTE_TABLE}
    ...    # ${port_mac_list[2]}    #    ${phy_port_out}=    Get Vtep List    # ${PHYSICAL_PORT_TABLE}    #
    ...    # L2GatewayOperations.Validate Regexp In String    ${phy_port_out}    ${VLAN_BINDING_REGEX}    2    #    #TC18 Dhcp Ip Allocation To The Namespace Second Set On Vtep And Ovs
    ...    #    Wait Until Keyword Succeeds    10s    2s    # L2GatewayOperations.Namespace Dhclient Verify    ${HWVTEP_NS1}
    ...    # ${NS_TAP2}    # ${port_ip_list[3]}
    #
    #TC19 Ping Verification From Namespace Second Set To Ovs Vm
    #    L2GatewayOperations.Verify Ping In Namespace    ${HWVTEP_NS1}    ${port_mac_list[3]}    ${port_ip_list[2]}
    #

TC99 Cleanup L2Gateway Connection Itm Tunnel Port Subnet And Network
    L2GatewayOperations.Delete L2Gateway Connection    ${L2GW_NAME1}
    #L2GatewayOperations.Delete L2Gateway Connection    ${L2GW_NAME2}
    L2GatewayOperations.Delete L2Gateway    ${L2GW_NAME1}
    #L2GatewayOperations.Delete L2Gateway    ${L2GW_NAME2}
    VpnOperations.ITM Delete Tunnel    TZA
    OpenStackOperations.Delete Vm Instance    ${OVS_VM1_NAME}
    #OpenStackOperations.Delete Vm Instance    ${OVS_VM2_NAME}
    OpenStackOperations.Delete Port    ${OVS_PORT_1}
    #OpenStackOperations.Delete Port    ${OVS_PORT_2}
    OpenStackOperations.Delete Port    ${HWVTEP_PORT_1}
    #OpenStackOperations.Delete Port    ${HWVTEP_PORT_2}
    OpenStackOperations.Delete SubNet    ${SUBNET_1}
    #OpenStackOperations.Delete SubNet    ${SUBNET_2}
    OpenStackOperations.Delete Network    ${NET_1}
    #OpenStackOperations.Delete Network    ${NET_2}

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
    ${ovs_conn_id}=    SSHLibrary.Open Connection    ${OVS_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${ovs_conn_id}
    Set Suite Variable    ${ovs_conn_id}
    Wait Until Keyword Succeeds    30s    5s    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${port_mac_list}=    Create List
    Set Suite Variable    ${port_mac_list}
    ${port_ip_list}=    Create List
    Set Suite Variable    ${port_ip_list}

Basic Suite Teardown
    Switch Connection    ${devstack_conn_id}
    close connection
    Switch Connection    ${hwvtep_conn_id}
    close connection
    Switch Connection    ${ovs_conn_id}
    close connection

Enable ODL DHCP Service
    [Documentation]    Enable and Verify ODL DHCP service
    TemplatedRequests.Post_As_Json_Templated    folder=${CURDIR}/../../variables/vpnservice/enable_dhcp    mapping={}    session=session
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/dhcpservice-config:dhcpservice-config
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    "controller-dhcp-enabled":true

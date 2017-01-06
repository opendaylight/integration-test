*** Settings ***
Documentation     Test Suite for verification of HWVTEP usecases
Suite Setup       BuiltIn.Run Keywords    Basic Suite Setup
#...               AND    Enable ODL DHCP Service
Suite Teardown    Basic Suite Teardown
Resource          ../../libraries/L2GatewayOperations.robot

*** Test Cases ***
TC1 Connect Hwvtep And Ovs To Controller Verify
    L2GatewayOperations.Add Vtep Manager And Verify    ${ODL_IP}
    L2GatewayOperations.Add Ovs Bridge Manager Controller And Verify

TC2 Create Neutron Network Subnet Ports and Verify
    OpenStackOperations.Create Network    ${NET_1}    ${NET_ADDT_ARG}${NET_1_SEGID}
    ${output}=    OpenStackOperations.List Networks
    Should Contain    ${output}    ${NET_1}
    OpenStackOperations.Create SubNet    ${NET_1}    ${SUBNET_1}    ${SUBNET_RANGE1}    ${SUBNET_ADDT_ARG}
    ${output}=    OpenStackOperations.List Subnets
    Should Contain    ${output}    ${SUBNET_1}
    OpenStackOperations.Create Neutron Port With Additional Params    ${NET_1}    ${OVS_PORT_1}
    OpenStackOperations.Create Neutron Port With Additional Params    ${NET_1}    ${HWVTEP_PORT_1}
    ${port_mac}=    Get Port Mac    ${OVS_PORT_1}
    Append To List    ${port_mac_list}    ${port_mac}
    ${port_mac}=    Get Port Mac    ${HWVTEP_PORT_1}
    Append To List    ${port_mac_list}    ${port_mac}
    DUMP

TC3 Update Ports In Controller Add To Hwvtep and Ovs
    L2GatewayOperations.Update Port For Hwvtep    ${HWVTEP_PORT_1}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${OVS_PORT_1}    ${OVS_VM1_NAME}    ${OVS_IP}
    ${vm_ip}=    Verify VMs Received DHCP Lease    ${OVS_VM1_NAME}
    Log    ${vm_ip}
    ${port_ip}=    L2GatewayOperations.Get Port Ip    ${OVS_PORT_1}
    Should Contain    ${vm_ip[0]}    ${port_ip}
    L2GatewayOperations.Attach Port To Hwvtep Namespace    ${HWVTEP_PORT_1}    ${HWVTEP_NS1}    ${NS_TAP1}
    DUMP

TC4 Create Itm L2Gateway Connection And Verify
    L2GatewayOperations.Create Itm Tunnel Between Hwvtep and Ovs    ${OVS_IP}
    ${output}=    L2GatewayOperations.Create L2Gateway    ${HWVTEP_BRIDGE}    ${NS_PORT1}    ${L2GW_NAME1}
    Log    ${output}
    ${output}=    L2GatewayOperations.Create L2Gateway Connection    ${L2GW_NAME1}    ${NET_1}
    Log    ${output}
    DUMP
    #    ${list}=    Create List    ${OVS_SWITCH_IP}    ${HWVTEP_IP}
    #    L2GatewayOperations.Verify Vtep List    ${PHYSICAL_LOCATOR_TABLE}    ${list}
    #    L2GatewayOperations.Verify Vtep List    ${TUNNEL_TABLE}    enable="true"
    #    ${remote_port_mac}=    L2GatewayOperations.Get Port Mac    ${OVS_PORT_1}
    #    Verify Vtep List    ${UCAST_MACS_REMOTE_TABLE}    ${remote_port_mac}
    #    ${logical_switch_uuid}=    L2GatewayOperations.Get Vtep Field Values From Table    ${LOGICAL_SWITCH_TABLE}    ${UUID_COL_NAME}
    #    L2GatewayOperations.Verify Vtep List    ${MCAST_MACS_LOCAL_TABLE}    ${logical_switch_uuid}
    #    L2GatewayOperations.Verify Vtep List    ${MCAST_MACS_REMOTE_TABLE}    ${logical_switch_uuid}
    #    L2GatewayOperations.Verify Vtep List    ${PHYSICAL_PORT_TABLE}    ${logical_switch_uuid}
    #    L2GatewayOperations.Verify Ovs Tunnel    ${HWVTEP_IP}    ${OVS_SWITCH_IP}
    #    ${phy_port_out}=    Get Vtep List    ${PHYSICAL_PORT_TABLE}
    #    Validate Regexp In String    ${phy_port_out}    ${VLAN_BINDING_REGEX}    1
    #    DUMP
    #
    #Dhcp Ip Allocation To The Namespace On Vtep And Ovs
    #    L2GatewayOperations.Namespace Dhclient Verify    ${HWVTEP_NS1}    ${NS_TAP1}
    #    DUMP
    #

TC10 Cleanup L2Gateway Connection Itm Tunnel Port Subnet And Network
    L2GatewayOperations.Delete L2Gateway Connection    ${L2GW_NAME1}
    L2GatewayOperations.Delete L2Gateway    ${L2GW_NAME2}
    VpnOperations.ITM Delete Tunnel    TZA
    OpenStackOperations.Delete Vm Instance    ${OVS_VM1_NAME}
    OpenStackOperations.Delete Port    ${OVS_PORT_1}
    OpenStackOperations.Delete Port    ${HWVTEP_PORT_1}
    OpenStackOperations.Delete SubNet    ${SUBNET_1}
    OpenStackOperations.Delete Network    ${NET_1}

*** Keywords ***
Basic Suite Setup
    [Documentation]    Basic Suite Setup required for the HWVTEP Test Suite
    RequestsLibrary.Create Session    alias=session    url=http://${ODL_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${devstack_conn_id}=    SSHLibrary.Open Connection    ${OS_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${devstack_conn_id}
    Set Suite Variable    ${devstack_conn_id}
    Login    ${OS_USER}    ${OS_PASSWORD}
    Write Commands Until Prompt    cd ${DEVSTACK_DEPLOY_PATH}; source openrc admin admin    30s
    ${hwvtep_conn_id}=    SSHLibrary.Open Connection    ${HWVTEP_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${hwvtep_conn_id}
    Set Suite Variable    ${hwvtep_conn_id}
    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${ovs_conn_id}=    SSHLibrary.Open Connection    ${OVS_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${ovs_conn_id}
    Set Suite Variable    ${ovs_conn_id}
    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    ${port_mac_list}=    Create List
    Set Suite Variable    ${port_mac_list}

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

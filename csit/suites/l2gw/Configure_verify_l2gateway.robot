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
    ${port_mac}=    OpenStackOperations.Get Port Mac    ${OVS_PORT_1}
    ${port_ip}=    OpenStackOperations.Get Port Ip    ${OVS_PORT_1}
    Append To List    ${port_mac_list}    ${port_mac}
    Append To List    ${port_ip_list}    ${port_ip}
    ${port_mac}=    OpenStackOperations.Get Port Mac    ${HWVTEP_PORT_1}
    ${port_ip}=    OpenStackOperations.Get Port Ip    ${HWVTEP_PORT_1}
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
    Wait Until Keyword Succeeds    30s    1s    L2GatewayOperations.Verify Vtep List    ${TUNNEL_TABLE}    enable="true"
    ${phy_port_out}=    Get Vtep List    ${PHYSICAL_PORT_TABLE}
    Validate Regexp In String    ${phy_port_out}    ${VLAN_BINDING_REGEX}    1

TC99 Cleanup L2Gateway Connection Itm Tunnel Port Subnet And Network
    L2GatewayOperations.Delete L2Gateway Connection    ${L2GW_NAME1}
    L2GatewayOperations.Delete L2Gateway    ${L2GW_NAME1}
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

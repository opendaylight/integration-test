*** Settings ***
Documentation     Test suite for SNAT and DNAT functionality testing
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/CompareStream.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
@{NETWORKS}       NET1    NET2    NET3    NET4
@{SUBNETS}        SUBNET1    SUBNET2    SUBNET3    SUBNET4
@{SUBNET_CIDR}    10.10.10.0/24    10.20.20.0/24    10.30.30.0/24    10.40.40.0/24
@{PORT_LIST}      PORT1    PORT2    PORT3    PORT4    PORT5    PORT6    PORT7
...               PORT8    PORT9    PORT10
@{VM_INSTANCES_NET1}    VM1    VM2    VM3
@{VM_INSTANCES_NET2}    VM4    VM5    VM6    VM7
@{VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a261112    4ae8cd92-48ca-49b5-94e1-b2921a261113
@{VPN_NAME}       vpn1    vpn2    vpn3
${CREATE_RD}      ["2200:2"]
${CREATE_EXPORT_RT}    ["2200:2"]
${CREATE_IMPORT_RT}    ["2200:2"]
${EXT_NETWORK}    ext-net
${EXT_SUBNET}     ext-subnet
${EXT_MULTISUBNET}    ext-subnet1    ext-subnet1
@{ROUTERS}        ROUTER_1    ROUTER_2
${PING_REGEXP}    , 0% packet loss
${Enable_SNAT}    --enable-snat
${Disable_SNAT}    --disable-snat
${SNAT_VERIFY_ENABLE}    "enable_snat": true
${SNAT_VERIFY_DISABLE}    "enable_snat": false
${SUBNET_EXT_IP1}    13.13.13.0/24
${SUBNET_EXT_IP2}    14.14.14.0/24
@{IP_LIST}              13.13.13.2    14.14.14.2
${ALLOCATION_POOL}    12.12.12.0/24
${NETWORK_URL}    ${CONFIG_API}/neutron:neutron/networks/
${SUBNETWORK_URL}    ${CONFIG_API}/neutron:neutron/subnets/
${FIB_ENTRIES_URL}    ${CONFIG_API}/odl-fib:fibEntries/
${FLOATING_IP_URL}    /restconf/config/neutron:neutron/floatingips/
${NAPT_URL}       /restconf/config/odl-nat:napt-switches/

*** Test Cases ***
TC00 Verify Setup
    [Documentation]    Verify if tunnels are present. If not then create new tunnel.
    : FOR    ${VM}    IN    @{VM_INSTANCES_NET1}    @{VM_INSTANCES_NET2}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    ${VM_IP_NET1}    ${VM_IP_NET2}    Wait Until Keyword Succeeds    180s    10s    Verify VMs received IP
    Set Suite Variable    ${VM_IP_NET2}
    Set Suite Variable    ${VM_IP_NET1}
#    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ping -c 3 ${VM_IP_NET1[1]}
#    Should Contain    ${output}    ${PING_REGEXP}
#    ${output}=    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ping -c 3 ${VM_IP_NET2[2]}
#    Should Contain    ${output}    ${PING_REGEXP}
#    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ping -c 3 ${VM_IP_NET2[1]}
#    Should Contain    ${output}    ${PING_REGEXP}
#    ${output}=    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ping -c 3 ${VM_IP_NET1[1]}
#    Should Contain    ${output}    ${PING_REGEXP}

TC01 Verify_update_router_with_single_external_IP_while_router_is_hosting_single_subnet
    [Documentation]    Verify_update_router_with_single_external_IP_while_router_is_hosting_single_subnet
    Log    Create External Network
    Create Network    ${EXT_NETWORK}    --router:external=True --provider:network_type gre
    ${NET_LIST}    List Networks
    Log    ${NET_LIST}
    Should Contain    ${NET_LIST}    ${EXT_NETWORK}
    Log    Create External Subnet
    Create SubNet    ${EXT_NETWORK}    ${EXT_SUBNET}    ${ALLOCATION_POOL}    --gateway 12.12.12.200
    ${SUB_LIST}    List Subnets
    Log    ${SUB_LIST}
    Should Contain    ${SUB_LIST}    ${EXT_SUBNET}
    Log    Flows before creating floating IP
    ${dpn1_flows}    ${dpn2_flows}    Dump Flows
    Add Router Gateway    ${ROUTERS[0]}    ${EXT_NETWORK}    ${Disable_SNAT}
    Add Router Gateway    ${ROUTERS[0]}    ${EXT_NETWORK}    ${Enable_SNAT}
    ${resp}    Show Router    ${ROUTERS[0]}    | grep external_gateway_info
    Should Contain    ${resp}    ${SNAT_VERIFY_ENABLE}
    Log    Flows before creating floating IP
    ${dpn1_flows}    ${dpn2_flows}    Dump Flows
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${ext_net_id1}    Get Net ID    ${EXT_NETWORK}    ${devstack_conn_id}
    Set Global Variable    ${ext_net_id1}
    ${tenant_id}    Get Tenant ID From Network    ${ext_net_id1}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=${CREATE_RD}    exportrt=${CREATE_EXPORT_RT}    importrt=${CREATE_IMPORT_RT}    tenantid=${tenant_id}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}
    Associate L3VPN To Network    networkid=${ext_net_id1}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${ext_net_id1}
    ${output}=    Get Fib Entries    session
    Log    ${output}
    Should Contain    ${output}    ${VM_IP_NET1[0]}
    Should Contain    ${output}    ${VM_IP_NET1[1]}
    ${dpn1_flows}    ${dpn2_flows}    Dump Flows
    Log    "Ping external n/w from Vm1 and Vm2"
    ${resp}    RequestsLibrary.Get Request    session    /restconf/config/odl-nat:napt-switches/
    Log    ${resp}
    ${output}=    Execute Command on VM Instance    ${NETWORKS[0]}    ${VM_IP_NET1[0]}    nc ${VM_IP_NET1[1]} 3333
    Log    ${output}
    ${dpn1_flows}    ${dpn2_flows}    Dump Flows

#TC12 FT97_TC13_Verify_flow_entries_are_removed_after_SNAT_session_time_out
#    [Documentation]    Verify_flow_entries_are_removed_after_SNAT_session_time_out
#    Sleep    300
#    ${output}=    Get Fib Entries    session
#    ${dpn1_flows}    ${dpn2_flows}    Dump Flows

TC13 Verify successful update of router with disable SNAT and then with enable SNAT with external_gateway_info disable SNAT
    [Documentation]    Verify successful update of router with disable SNAT and then with enable SNAT with external_gateway_info disableSNAT
    Log    Disable SNAT
    Add Router Gateway    ${ROUTERS[0]}    ${EXT_NETWORK}    ${Disable_SNAT}
    Log    Verify no table 26
    ${dpn1_flows}    ${dpn2_flows}    Dump Flows
    Log    Enable SNAT
    Add Router Gateway    ${ROUTERS[0]}    ${EXT_NETWORK}    ${Disable_SNAT}
    Log    Check for table 26
    ${dpn1_flows}    ${dpn2_flows}    Dump Flows
    Log    Ping external network
    ${output}=    Execute Command on VM Instance    ${NETWORKS[0]}    ${VM_IP_NET2[0]}    nc ${VM_IP_NET2[0]} 3333
    Log    ${output}
    Log    Verify FIB table
    ${output}=    Get Fib Entries    session
    Log    ${output}
    ${dpn1_flows}    ${dpn2_flows}    Dump Flows
    ${dpid1}    Get DPID    ${OS_COMPUTE_1_IP}
    Set Global Variable    ${dpid1}
    ${dpid2}    Get DPID    ${OS_COMPUTE_2_IP}
    Set Global Variable    ${dpid2}
    ${dpnid1}=    Get DPID    ${OS_COMPUTE_1_IP}
    ${dpnid2}=    Get DPID    ${OS_COMPUTE_2_IP}
    ${primary_dpid}=    Get Primary DPN ID    session
    ${primary_flow}    Run Keyword If    ${primary_dpid}=${dpnid1}    Get Flows For Primary DPN    ${OS_COMPUTE_1_IP}
    ${Primary_flow}    Run Keyword If    ${primary_dpid}=${dpnid2}    Get Flows For Primary DPN    ${OS_COMPUTE_2_IP}

TC13 Verify_update_router_with_scenario_where_externalIPs_are_more_than_subnet_associated_to_router
    [Documentation]    Verify_update_router_with_scenario_where_externalIPs_are_more_than_subnet_associated_to_router
    Log    Clear the gateway attached to the router
    Delete Router Gateway    ${ROUTERS[0]}
    Delete SubNet    ${EXT_SUBNET}
    Log    Create 2 new external subnets
    Create SubNet    ${EXT_NETWORK}    ${EXT_MULTISUBNET[0]}    ${SUBNET_EXT_IP1}
    Create SubNet    ${EXT_NETWORK}    ${EXT_MULTISUBNET[1]}    ${SUBNET_EXT_IP2}
    Router Multi Gw Set     ${ROUTERS[0]}    ${EXT_NETWORK}     ${EXT_MULTISUBNET}     ${IP_LIST}
    ${primary_dpid}=    Get Primary DPN ID    session
    ${dpn1_flows}    ${dpn2_flows}    Dump Flows
    ${primary_flow}    Run Keyword If    ${primary_dpid}=${dpnid1}    Get Flows For Primary DPN    ${OS_COMPUTE_1_IP}
    ${Primary_flow}    Run Keyword If    ${primary_dpid}=${dpnid2}    Get Flows For Primary DPN    ${OS_COMPUTE_2_IP}
    Log    TO DO PING

TC14 Verify_update_router_with_scenario_where_externalIPs_are_less_than_subnets_associated_to_router
    [Documentation]    Verify_update_router_with_scenario_where_externalIPs_are_less_than_subnets_associated_to_router
    Log    Adding one more interface
    Add Router Interface    ${ROUTERS[0]}    ${SUBNETS[2]}
    Log    "Verify ping to external IP with 3 internal subnets and 2 external fixed IPs"
    Log    "one to one correspondance takes round robin method between 2 external and 3 internal subnets with third subnet again getting mapped to first fixed external IP"
    ${dpn1_flows}    ${dpn2_flows}    Dump Flows
    Log    TO DO PING
    ${primary_dpid}=    Get Primary DPN ID    session
    ${primary_flow}    Run Keyword If    ${primary_dpid}=${dpnid1}    Get Flows For Primary DPN    ${OS_COMPUTE_1_IP}
    ${Primary_flow}    Run Keyword If    ${primary_dpid}=${dpnid2}    Get Flows For Primary DPN    ${OS_COMPUTE_2_IP}
    [Teardown]     BuiltIn.Run Keywords    Remove Interface    ${ROUTERS[0]}    ${SUBNETS[2]}    AND     Get Test Teardown Debugs

#TC15 Verify_update_router_from_multiple_externalIPs_to_single_externalIP
#    [Documentation]    Verify_update_router_from_multiple_externalIPs_to_single_externalIP
    

*** Keywords ***
Start Suite
    [Documentation]    Run before the suite execution
    DevstackUtils.Devstack Suite Setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    Create Setup

Stop Suite
    [Documentation]    Run after the tests execution
    Delete Setup
    Close All Connections

Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports And Four VMs
    Log    Create two networks
    : FOR    ${network}    IN    @{NETWORKS}
    \    Create Network    ${network}
    #    Create Network    ${NETWORKS[0]}
    #    Create Network    ${NETWORKS[1]}
    ${NET_LIST}    List Networks
    : FOR    ${network}    IN    @{NETWORKS}
    \    Should Contain    ${NET_LIST}    ${network}
    #    Should Contain    ${NET_LIST}    ${NETWORKS[0]}
    #    Should Contain    ${NET_LIST}    ${NETWORKS[1]}
    Log    Create two subnets for previously created networks
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    Create SubNet    ${NETWORKS[2]}    ${SUBNETS[2]}    ${SUBNET_CIDR[2]}
    Create SubNet    ${NETWORKS[3]}    ${SUBNETS[3]}    ${SUBNET_CIDR[3]}
    ${SUB_LIST}    List Subnets
    : FOR    ${subnet}    IN    @{SUBNETS}
    \    Should Contain    ${SUB_LIST}    ${subnet}
    #    Should Contain    ${SUB_LIST}    ${SUBNETS[0]}
    #    Should Contain    ${SUB_LIST}    ${SUBNETS[1]}
    Neutron Security Group Create    sg-vpnservice1
    Neutron Security Group Rule Create    sg-vpnservice1    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice1    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice1    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice1    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice1    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice1    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Log    Create four ports under previously created subnets
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}    sg=sg-vpnservice1
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}    sg=sg-vpnservice1
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[2]}    sg=sg-vpnservice1
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[3]}    sg=sg-vpnservice1
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[4]}    sg=sg-vpnservice1
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[5]}    sg=sg-vpnservice1
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[6]}    sg=sg-vpnservice1
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[7]}    sg=sg-vpnservice1
    Create Port    ${NETWORKS[2]}    ${PORT_LIST[8]}    sg=sg-vpnservice1
    Create Port    ${NETWORKS[3]}    ${PORT_LIST[9]}    sg=sg-vpnservice1
#    ${devstack_conn_id} =    Get ControlNode Connection
#    Switch Connection    ${devstack_conn_id}
#    ${port_id0}    Get Port Id    ${PORT_LIST[0]}    ${devstack_conn_id}
#    ${port_id1}    Get Port Id    ${PORT_LIST[1]}    ${devstack_conn_id}
#    ${port_id2}    Get Port Id    ${PORT_LIST[2]}    ${devstack_conn_id}
#    ${port_id3}    Get Port Id    ${PORT_LIST[3]}    ${devstack_conn_id}
#    ${port_id4}    Get Port Id    ${PORT_LIST[4]}    ${devstack_conn_id}
#    ${port_id5}    Get Port Id    ${PORT_LIST[5]}    ${devstack_conn_id}
#    ${port_id6}    Get Port Id    ${PORT_LIST[6]}    ${devstack_conn_id}
#    ${port_id7}    Get Port Id    ${PORT_LIST[7]}    ${devstack_conn_id}
#    ${port_id8}    Get Port Id    ${PORT_LIST[8]}    ${devstack_conn_id}
#    Set Global Variable    ${port_id0}
#    Set Global Variable    ${port_id1}
#    Set Global Variable    ${port_id2}
#    Set Global Variable    ${port_id3}
#    Set Global Variable    ${port_id4}
#    Set Global Variable    ${port_id5}
#    Set Global Variable    ${port_id6}
#    Set Global Variable    ${port_id7}
#    Set Global Variable    ${port_id8}
    #    ${port_id_list}    Create List
    #    : FOR    ${i}    IN RANGE    0    8
    #    ${port_id}    Get Port Id    ${PORT_LIST[${i}]}    ${devstack_conn_id}
    #    Append To List    ${port_id_list}    ${port_id}
    #    Set Global Variable    ${port_id${i}}
    Log    Create VM Instances
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES_NET1[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice1
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES_NET1[1]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice1
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES_NET1[2]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice1
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[4]}    ${VM_INSTANCES_NET2[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice1
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[5]}    ${VM_INSTANCES_NET2[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice1
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[6]}    ${VM_INSTANCES_NET2[2]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice1
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[7]}    ${VM_INSTANCES_NET2[3]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice1
    Log    Create Router
    Create Router    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NEUTRON_ROUTERS_API}    ${router_list}
    Log    Add Interfaces to router
    Add Router Interface    ${ROUTERS[0]}    ${SUBNETS[0]}
    Add Router Interface    ${ROUTERS[0]}    ${SUBNETS[1]}

Verify VMs received IP
    [Documentation]    Verify VM received IP
    ${VM_IP_NET1}    ${DHCP_IP1}    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET1}
    Log    ${VM_IP_NET1}
    ${VM_IP_NET2}    ${DHCP_IP2}    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET2}
    Log    ${VM_IP_NET2}
    Should Not Contain    ${VM_IP_NET2}    None
    Should Not Contain    ${VM_IP_NET1}    None
    [Return]    ${VM_IP_NET1}    ${VM_IP_NET2}

Delete Setup
    [Documentation]    Delete the created VMs, ports, subnet and networks
    Delete Router Gateway    ${ROUTERS[0]}
    ${dpn1_flows}    ${dpn2_flows}    Dump Flows
    Log    Deleting L3VPN
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Delete SubNet    ${EXT_MULTISUBNET[0]}
    Delete SubNet    ${EXT_MULTISUBNET[1]}
    Delete Network    ${EXT_NETWORK}
    Remove Interface    ${ROUTERS[0]}    ${SUBNETS[0]}
    Remove Interface    ${ROUTERS[0]}    ${SUBNETS[1]}
    Remove Interface    ${ROUTERS[0]}    ${SUBNETS[2]}
    Delete Router    ${ROUTERS[0]}
    Log    Delete the VM instances
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_NET1}    @{VM_INSTANCES_NET2}
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}
    Log    Delete neutron ports
    : FOR    ${Port}    IN    @{PORT_LIST}
    \    Delete Port    ${Port}
    Log    Delete subnets
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Delete SubNet    ${Subnet}
    Log    Delete networks
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Delete Network    ${Network}

Verify Floating Ip Creation
    [Arguments]    ${id}    ${session}
    ${resp}    RequestsLibrary.Get Request    ${session}    ${FLOATING_IP_URL}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${ext_net_id}
    Should Contain    ${resp.content}    ${id}

Get Primary DPN ID
    [Arguments]    ${session}
    [Documentation]    Get ID of the primary DPN
    ${resp}    RequestsLibrary.Get Request    ${session}    ${NAPT_URL}
    Log    ${resp.content}
    ${regex}=    Set Variable    [0-9]{14,16}
    ${id}=    Get Regexp Matches    ${resp.content}    ${regex}
    Log To Console    ${id}
    [Return]    ${id}

Dump Flows
    [Documentation]    Dump flows of both DPN
    ${flow_output_1}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output_1}
    ${flow_output_2}=    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output_2}
    [Return]    ${flow_output_1}    ${flow_output_2}

Get Flows For Primary DPN
    [Arguments]    ${primary_ip}
    [Documentation]    Returns the flows for the primary DPN
    ${flows}=    Run Command On Remote System    ${primary_ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flows}
    [Return]    ${flows}

Get Fib Entries
    [Arguments]    ${session}
    [Documentation]    Get Fib table entries from ODL
    ${resp}    RequestsLibrary.Get Request    ${session}    ${FIB_ENTRIES_URL}
    Log    ${resp.content}
    [Return]    ${resp.content}

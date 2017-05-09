*** Settings ***
Documentation     Test suite for ARP Request. More test cases to be added in subsequent patches.
Suite Setup       Start Suite
Suite Teardown    End Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           RequestsLibrary
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${SECURITY_GROUP}    sg-vpnservice1
@{VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a261112
@{VPN_NAME}       vpn1    vpn2
${CREATE_RD}      ["2200:2"]
${CREATE_RD1}     ["2200:3"]
${CREATE_EXPORT_RT}    ["2200:2","2200:3"]
${CREATE_IMPORT_RT}    ["2200:2","2200:3"]

*** Test Cases ***
TC00 Verify Setup
    [Documentation]    Verify that VMs received ip and ping is happening between different VM
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_NET1}    @{VM_INSTANCES_NET2}    @{VM_INSTANCES_NET3}
    : FOR    ${VM}    IN    @{VM_INSTANCES}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    ${VM_IP_NET1}    ${DHCP_IP1}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET1}
    ${VM_IP_NET2}    ${DHCP_IP2}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET2}
    ${VM_IP_NET3}    ${DHCP_IP3}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET3}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${VM_INSTANCES_NET1}    ${VM_INSTANCES_NET2}    ${VM_INSTANCES_NET3}
    ${VM_IPS}=    Collections.Combine Lists    ${VM_IP_NET1}    ${VM_IP_NET2}    ${VM_IP_NET3}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES_NET1}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    nova console-log @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${VM_IP_NET1}
    Set Suite Variable    ${VM_IP_NET2}
    Set Suite Variable    ${VM_IP_NET3}
    Should Not Contain    ${VM_IP_NET1}    None
    Should Not Contain    ${VM_IP_NET2}    None
    Should Not Contain    ${VM_IP_NET3}    None
    ${vm_instances} =    Create List    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${FIB_ENTRIES_URL}    ${vm_instances}
    Verify Ping On Same Networks
    Verify Ping On Different Networks

TC01 Verify GARP Requests
    [Documentation]    Verify that GARP request are sent to controller
    Set Suite Variable    ${FIB_ENTRY_1}    ${VM_IP_NET1[0]}
    Set Suite Variable    ${FIB_ENTRY_3}    ${VM_IP_NET1[1]}
    Wait Until Keyword Succeeds    10s    1s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    10s    1s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    ${output}=    Get Fib Entries    session
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_3}\/32".*"${OS_COMPUTE_2_IP}\\"
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_1}\/32".*"${OS_COMPUTE_1_IP}\\"
    Log    Checking the RX Packets Count on VM1 and VM2 before ARP Broadcast
    ${rx_packet1_before} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ifconfig eth0
    ${rx_packet0_before} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ifconfig eth0
    ${CONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${CONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ifconfig
    Should Contain    ${output}    eth0:1
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${RPING_MIP_IP}
    Should Contain    ${output}    broadcast
    Should Contain    ${output}    Received 0 reply
    Log    Checking the RX Packets Count on VM1 and VM2 after ARP Broadcast
    ${rx_packet1_after} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ifconfig eth0
    ${rx_packet0_after} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ifconfig eth0
    Should Not Be Equal    ${rx_packet0_before}    ${rx_packet0_after}
    Should Not Be Equal    ${rx_packet1_before}    ${rx_packet1_after}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    Wait Until Keyword Succeeds    5s    1s    Verify Learnt IP    ${FIB_ENTRY_2}    session
    ${output}=    Get Fib Entries    session
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_3}\\/32".*"${OS_COMPUTE_2_IP}\\"
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_1}\\/32".*"${OS_COMPUTE_1_IP}\\"
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\\/32".*"${OS_COMPUTE_2_IP}\\"
    Verify Ping To Sub Interface    ${FIB_ENTRY_2}

TC02 Verify MIP Migration
    [Documentation]    Verify that after migration of movable ip across compute nodes, the controller updates the routes
    Log    Bring down the Sub Interface on DPN2
    ${UNCONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 down
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${UNCONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ifconfig
    Should Not Contain    ${output}    eth0:1
    ${CONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${CONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ifconfig
    Should Contain    ${output}    eth0:1
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ifconfig eth0:1
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${RPING_MIP_IP}
    Should Contain    ${output}    Received 0 reply
    Should Contain    ${output}    broadcast
    Wait Until Keyword Succeeds    5s    1s    Verify Learnt IP    ${FIB_ENTRY_2}    session
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${RPING_MIP_IP}
    ${output}    Get Fib Entries    session
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\\/32".*"${OS_COMPUTE_1_IP}\\"
    Verify Ping To Sub Interface    ${FIB_ENTRY_2}
    Log    Removing the created sub-interface
    ${UNCONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 down
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${UNCONFIG_EXTRA_ROUTE_IP1}

TC03 Verify ping to subnet gateway
    [Documentation]    Verify pig happens to subnet gateway. To be sobmitted in next patch
    [Tags]    not-implemented    exclude
    TODO

TC04 If anything other than subnet ip then no reply
    [Documentation]    If anything other than subnet ip then no reply. To be sobmitted in next patch
    [Tags]    not-implemented    exclude
    TODO

TC05 Validate multiple mip migration
    [Documentation]    Validate multiple mip migration. To be sobmitted in next patch
    [Tags]    not-implemented    exclude
    TODO

TC06 Same DPN MIP Migration
    [Documentation]    Same DPN MIP Migration. To be sobmitted in next patch
    [Tags]    not-implemented    exclude
    TODO

*** Keywords ***
Start Suite
    [Documentation]    Run at start of the suite
    DevstackUtils.Devstack Suite Setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    Create Setup

End Suite
    [Documentation]    Run at end of the suite
    Delete Setup
    Close All Connections

Create Setup
    [Documentation]    Create networks,subnets,ports and VMs
    : FOR    ${network}    IN    @{NETWORKS}
    \    Create Network    ${network}
    ${NET_LIST}    List Networks
    : FOR    ${network}    IN    @{NETWORKS}
    \    Should Contain    ${NET_LIST}    ${network}
    : FOR    ${i}    IN RANGE    0    3
    \    Create SubNet    ${NETWORKS[${i}]}    ${SUBNETS[${i}]}    ${SUBNET_CIDR[${i}]}
    ${SUB_LIST}    List Subnets
    : FOR    ${subnet}    IN    @{SUBNETS}
    \    Should Contain    ${SUB_LIST}    ${subnet}
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    ${allowed_address_pairs_args}=    Set Variable    --allowed-address-pairs type=dict list=true ip_address=@{EXTRA_NW_IP}[0] ip_address=@{EXTRA_NW_IP}[1]
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[2]}    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Port    ${NETWORKS[2]}    ${PORT_LIST[4]}    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Port    ${NETWORKS[2]}    ${PORT_LIST[5]}    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES_NET1[0]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES_NET1[1]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES_NET2[0]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES_NET2[1]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[4]}    ${VM_INSTANCES_NET3[0]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[5]}    ${VM_INSTANCES_NET3[1]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Create Router    ${ROUTERS}
    Add Router Interface    ${ROUTERS}    ${SUBNETS[1]}
    Add Router Interface    ${ROUTERS}    ${SUBNETS[2]}
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    ${NETWORKS[0]}    ${devstack_conn_id}
    Set Suite Variable    ${net_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    Set Suite Variable    ${tenant_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=${CREATE_RD}    exportrt=${CREATE_EXPORT_RT}    importrt=${CREATE_IMPORT_RT}    tenantid=${tenant_id}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}
    Associate L3VPN To Network    networkid=${net_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${net_id}
    ${router_id}=    Get Router Id    ${ROUTERS}    ${devstack_conn_id}
    Set Suite Variable    ${router_id}
    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${router_id}

Verify Ping On Same Networks
    [Documentation]    Verify ping among VM of same network
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ping -c 3 ${VM_IP_NET1[1]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ping -c 3 ${VM_IP_NET2[1]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ping -c 3 ${VM_IP_NET1[0]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ping -c 3 ${VM_IP_NET2[0]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[2]    ${VM_IP_NET3[0]}    ping -c 3 ${VM_IP_NET3[1]}
    Should Contain    ${output}    ${PING_REGEXP}

Verify Ping On Different Networks
    [Documentation]    Verify ping among VMs of different network
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ping -c 3 ${VM_IP_NET2[0]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ping -c 3 ${VM_IP_NET3[0]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ping -c 3 ${VM_IP_NET2[1]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ping -c 3 ${VM_IP_NET3[1]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[2]    ${VM_IP_NET3[0]}    ping -c 3 ${VM_IP_NET1[1]}
    Should Contain    ${output}    ${PING_REGEXP}

Verify Flows Are Present
    [Arguments]    ${ip}
    [Documentation]    Verify Flows Are Present
    ${flow_output}=    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    ${resp}=    Should Contain    ${flow_output}    table=50
    ${resp}=    Should Contain    ${flow_output}    table=21,
    @{vm_ip}=    Create List    @{VM_IP_NET1}    @{VM_IP_NET2}    @{VM_IP_NET3}
    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:36
    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:17
    : FOR    ${i}    IN    @{vm_ip}
    \    ${resp}=    Should Match regexp    ${flow_output}    table=21.*nw_dst=${i}

Verify Ping To Sub Interface
    [Arguments]    ${sub_interface_ip}
    [Documentation]    Verify ping to the sub-interface
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ping -c 3 ${sub_interface_ip}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ping -c 3 ${sub_interface_ip}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[2]    ${VM_IP_NET3[0]}    ping -c 3 ${sub_interface_ip}
    Should Contain    ${output}    ${PING_REGEXP}

Verify Learnt IP
    [Arguments]    ${ip}    ${session}
    [Documentation]    Check that sub interface ip has been learnt after ARP request
    ${resp}    RequestsLibrary.Get Request    ${session}    /restconf/operational/odl-l3vpn:learnt-vpn-vip-to-port-data/
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${ip}

TODO
    Fail    "Not implemented"

Delete Setup
    [Documentation]    Delete the setup
    Dissociate L3VPN From Networks    networkid=${net_id}    vpnid=${VPN_INSTANCE_ID[0]}
    Dissociate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Remove Interface    ${ROUTERS}    ${SUBNETS[1]}
    Remove Interface    ${ROUTERS}    ${SUBNETS[2]}
    Delete Router    ${ROUTERS}
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_NET1}    @{VM_INSTANCES_NET2}    @{VM_INSTANCES_NET3}
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}
    : FOR    ${Port}    IN    @{PORT_LIST}
    \    Delete Port    ${Port}
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Delete SubNet    ${Subnet}
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Delete Network    ${Network}
    Delete SecurityGroup    ${SECURITY_GROUP}

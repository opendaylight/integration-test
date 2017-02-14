*** Settings ***
Documentation     Test suite to validate GWMAC Table.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
@{NETWORKS}       NET10    NET20
@{SUBNETS}        SUBNET10    SUBNET20
@{SUBNET_CIDR}    10.1.1.0/24    20.1.1.0/24
@{PORTS}      PORT11    PORT21    PORT12    PORT22
@{VM_INSTANCES_NET10}    VM11    VM21
@{VM_INSTANCES_NET20}    VM12    VM22
@{ROUTERS}        ROUTER_1    ROUTER_2
${DISPATCHER_TABLE}    17
${GWMAC_TABLE}    19
${ARP_RESPONDER_TABLE}    81
${L3_TABLE}       21
${ARP_FLOWENTRY_REGEX}    arp,arp_op=\\d actions=CONTROLLER:65535,resubmit\\(,${DISPATCHER_TABLE}\\)
${ARP_RESPONDER_FLOWENTRY_REGEX}    arp,arp_op=\\d actions=group:\\d+
${ARP_RESPONDER_GROUP}    actions=CONTROLLER:65535,bucket=actions=resubmit\\(,${DISPATCHER_TABLE}\\),bucket=actions=resubmit\\(,${ARP_RESPONDER_TABLE}\\)
${SG_GWMAC}      sg-gwmac
${MAC_REGEX}      (([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2}))

*** Test Cases ***
Verify FIB Table GWMAC Table
    [Documentation]    Verify fib table, GWMAC table , ARP reponder table and dispatcher table
    ODL Suite Setup
    Log To Console      Verify FIB and Flow TABLE
    ${vm_instances} =    Create List    @{VM_IP_NET10}    @{VM_IP_NET20}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/    ${vm_instances}
    Log    L3 Datapath test across the networks using router
    ${dst_ip_list} =    Create List    ${VM_IP_NET10[1]}    @{VM_IP_NET20}
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[0]}    ${VM_IP_NET10[1]}    ${dst_ip_list}
    ${dst_ip_list} =    Create List    ${VM_IP_NET20[1]}    @{VM_IP_NET10}
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[1]}    ${VM_IP_NET20[0]}    ${dst_ip_list}
    Log To Console     Get GWMAC address
    ${GWMAC_ADDRS} =    Get GWMAC Address     ${ROUTERS[0]}
    Log    ${GWMAC_ADDRS}
    Set Suite Variable    ${GWMAC_ADDRS}
    #Verify GWMAC Table
    Validate GWMAC Entry From ODL    ${GWMAC_ADDRS}
    ${FLOW_OUTPUT}    ${GROUP_OUTPUT}    Get Flow and Group Table    ${OS_COMPUTE_1_IP}
    Validate GWMAC FLOW TABLE    ${FLOW_OUTPUT}    ${GROUP_OUTPUT}    ${GWMAC_ADDRS}
    ${FLOW_OUTPUT}    ${GROUP_OUTPUT}    Get Flow and Group Table    ${OS_COMPUTE_2_IP}
    Validate GWMAC FLOW TABLE    ${FLOW_OUTPUT}    ${GROUP_OUTPUT}    ${GWMAC_ADDRS}
    ODL Suite TearDown

*** Keywords ***
Get Flow and Group Table
    [Arguments]    ${ip}
    [Documentation]    Return flow and group table output for given node
    ${flow_output}=    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    ${group_output}=    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    Log    ${group_output}
    [Return]    ${flow_output}    ${group_output}

Get GWMAC Address
    [Arguments]    ${router_Name}
    [Documentation]    Get GWMAC Address
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output} =    Write Commands Until Prompt    neutron router-port-list ${router_Name} | awk '{print $5}'    30s
    @{MacAddr-list} =    Get Regexp Matches    ${output}    ${MAC_REGEX} 
    [Return]    ${MacAddr-list}

Validate GWMAC FLOW TABLE
    [Arguments]    ${flow_output}    ${group_output}    ${GWMAC_ADDRS}
    [Documentation]    ODL config for BGP and VPN service
    #Verify DISPATCHER_TABLE - 17
    Should Contain    ${flow_output}    table=${DISPATCHER_TABLE}
    Should Not Contain    ${flow_output}    goto_table:${ARP_RESPONDER_TABLE}
    ${dispatcher_table} =    Get Lines Containing String    ${flow_output}    table=${DISPATCHER_TABLE}
    Log    ${dispatcher_table}
    Should Contain    ${dispatcher_table}    goto_table:${GWMAC_TABLE}
    #Verify GWMAC_TABLE - 19
    Should Contain    ${flow_output}    table=${GWMAC_TABLE}
    ${gwmac_table} =    Get Lines Containing String    ${flow_output}    table=${GWMAC_TABLE}
    Log    ${gwmac_table}
    #Verify GWMAC address present in table 19
    : FOR    ${macAdd}    IN    @{GWMAC_ADDRS}
    \    Should Contain    ${gwmac_table}    dl_dst=${macAdd} actions=goto_table:${L3_TABLE}
    #verify Miss entry
    Should Contain    ${gwmac_table}    actions=resubmit(,17)
    #arp responder
    Should Match Regexp    ${gwmac_table}    ${ARP_FLOWENTRY_REGEX}
    ${match} =    Should Match Regexp    ${gwmac_table}    ${ARP_RESPONDER_FLOWENTRY_REGEX}
    ${groupID} =    Split String    ${match}    separator=:
    Log    groupID
    Verify ARP RESPONDER in groupTable    ${group_output}    ${groupID[1]}
    #Verify L3_TABLE - 21
    Should Contain    ${flow_output}    table=${L3_TABLE}
    ${l3_table} =    Get Lines Containing String    ${flow_output}    table=${L3_TABLE}
    Log    ${l3_table}
    : FOR    ${ip}    IN    @{VM_IP_NET10}    @{VM_IP_NET20}
    \    ${resp}=    Should Contain    ${l3_table}    ${ip}
    #Verify ARP_RESPONDER_TABLE - 81
    Should Contain    ${flow_output}    table=${ARP_RESPONDER_TABLE}
    ${arpResponder_table} =    Get Lines Containing String    ${flow_output}    table=${ARP_RESPONDER_TABLE}
    Log    ${arpResponder_table}
    Should Contain    ${arpResponder_table}    priority=0 actions=drop

Verify ARP RESPONDER in groupTable
    [Arguments]    ${group_output}    ${Group-ID}
    [Documentation]    get flow dump for group ID
    Should Contain    ${group_output}    group_id=${Group-ID}
    ${arp_group} =    Get Lines Containing String    ${flow_output}    group_id==${Group-ID}
    Log    ${arp_group}
    Should Contain    ${arp_group}    ${ARP_RESPONDER_GROUP}

Validate GWMAC Entry From ODL
    [Arguments]    ${GWMAC_ADDRS}
    [Documentation]    get ODL GWMAC table entry
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/neutronvpn:neutron-vpn-portip-port-data/
    Log    ${resp.content}
    #Should Be Equal As Strings    ${resp.status_code}    200
    #: FOR    ${macAdd}    IN    @{GWMAC_ADDRS}
    #\    Should Contain    ${gwmac_table}    ${macAdd}

ODL Suite Setup
    [Documentation]    ODL config
    #Start Quagga Processes on ODL
    Log To Console     Create Networks , subnet , port and corresponding VM
    Add Ssh Allow Rule     sg-gwmac
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Create Network    ${Network}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/networks/    ${NETWORKS}
    ${length}=    Get Length    ${SUBNETS}
    : FOR    ${idx}    IN RANGE    ${length}
    \    Create SubNet    ${NETWORKS[${idx}]}    ${SUBNETS[${idx}]}    ${SUBNET_CIDR[${idx}]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/subnets/    ${SUBNETS}
    Create Port    ${NETWORKS[0]}    ${PORTS[0]}    sg=${SG_GWMAC}
    Create Port    ${NETWORKS[0]}    ${PORTS[1]}    sg=${SG_GWMAC}
    Create Port    ${NETWORKS[1]}    ${PORTS[2]}    sg=${SG_GWMAC}
    Create Port    ${NETWORKS[1]}    ${PORTS[3]}    sg=${SG_GWMAC}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${PORTS}
    Create Vm Instance With Port On Compute Node    ${PORTS[0]}    ${VM_INSTANCES_NET10[0]}    ${OS_COMPUTE_1_IP}    sg=${SG_GWMAC}
    Create Vm Instance With Port On Compute Node    ${PORTS[1]}    ${VM_INSTANCES_NET10[1]}    ${OS_COMPUTE_2_IP}    sg=${SG_GWMAC}
    Create Vm Instance With Port On Compute Node    ${PORTS[2]}    ${VM_INSTANCES_NET20[0]}    ${OS_COMPUTE_1_IP}    sg=${SG_GWMAC}
    Create Vm Instance With Port On Compute Node    ${PORTS[3]}    ${VM_INSTANCES_NET20[1]}    ${OS_COMPUTE_2_IP}    sg=${SG_GWMAC}
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_NET10}    @{VM_INSTANCES_NET20}
    : FOR    ${VM}    IN    @{VM_INSTANCES}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    ${VM_IP_NET10}    Wait Until Keyword Succeeds    30s    10s    Verify VMs received IP    ${VM_INSTANCES_NET10}
    Log    ${VM_IP_NET10}
    Set Suite Variable    ${VM_IP_NET10}
    ${VM_IP_NET20}    Wait Until Keyword Succeeds    30s    10s    Verify VMs received IP    ${VM_INSTANCES_NET20}
    Log    ${VM_IP_NET20}
    Set Suite Variable    ${VM_IP_NET20}
    #Get MACAddress
    ${VM_MACADDR} =    Get Ports MacAddr    ${PORTS}
    Set Suite Variable    ${VM_MACADDR}
    Log To Console    Create router And Associate to subnet
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Router
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/    ${router_list}
    ${devstack_conn_id} =    Get ControlNode Connection
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Add Router Interface    ${ROUTERS[0]}    ${INTERFACE}
    ${interface_output} =    Show Router Interface    ${ROUTERS[0]}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Contain    ${interface_output}    ${subnet_id}

ODL Suite TearDown
    [Documentation]    Clear ODL suit setup
    Log To Console     Remove interface and Delete Interface
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Remove Interface    ${ROUTERS[0]}    ${INTERFACE}
    ${interface_output} =    Show Router Interface    ${ROUTERS[0]}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Not Contain    ${interface_output}    ${subnet_id}
    # Delete Router and Interface to the subnets.
    Delete Router    ${ROUTERS[0]}
    ${router_output} =    List Router
    Log    ${router_output}
    Should Not Contain    ${router_output}    ${ROUTERS[0]}
    Log To Console     Delete vm, port , subnet and networks
    : FOR    ${vmName}    IN    @{VM_INSTANCES_NET10}    @{VM_INSTANCES_NET20}
    \    Delete Vm Instance    ${vmName}
    : FOR    ${port}    IN    @{PORTS}
    \    Delete Port    ${port}
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Delete SubNet    ${Subnet}
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Delete Network    ${Network}
    Delete Ssh Allow Rule     sg-gwmac

Verify VMs received IP
    [Arguments]    ${VM_NAMES}
    [Documentation]    Verify VM Instance received IP
    ${VM_IPS}    ${DHCP_IP1}    Verify VMs Received DHCP Lease    @{VM_NAMES}
    Log    ${VM_IPS}
    Should Not Contain    ${VM_IPS}    None
    [Return]    ${VM_IPS}

Delete Ssh Allow Rule 
    [Arguments]    ${sg_name}
    [Documentation]    Delete Security group
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron security-group-delete ${sg_name}    40s
    Log     ${output}
    Should Match Regexp    ${output}    Deleted security_group: ${sg_name}|Deleted security_group\\(s\\): ${sg_name}
    Close Connection

Add Ssh Allow Rule
    [Arguments]    ${sg_name}
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    Neutron Security Group Create    ${sg_name} 
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0

Get Ports MacAddr
    [Arguments]    ${portName_list}
    [Documentation]    Retrieve the port MacAddr for the given list of port name and return the MAC address list.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${MacAddr-list}    Create List
    : FOR    ${portName}    IN    @{portName_list}
    \    ${output} =    Write Commands Until Prompt    neutron port-list | grep "${portName}" | awk '{print $6}'    30s
    \    Log      ${output}
    \    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    \    ${macAddr}=    Get from List    ${splitted_output}    0
    \    Log    ${macAddr}
    \    Append To List    ${MacAddr-list}    ${macAddr}
    [Return]    ${MacAddr-list}


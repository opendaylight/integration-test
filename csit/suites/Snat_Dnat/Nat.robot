*** Settings ***
Documentation     Test Suite to check funtionality of snat and dnat.
Library           SSHLibrary    
Library           Collections
Library           String
Library           RequestsLibrary
Resource          ../../../csit/libraries/Utils.robot
Resource          ../../../csit/libraries/OpenStackOperations.robot
Resource          ../../../csit/libraries/DevstackUtils.robot
Resource          ../../libraries/SetupUtils.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../../csit/libraries/Utils.robot
Resource          ../../libraries/BgpOperations.robot
Resource          ../../libraries/Snat_Dnat.robot
Resource          ../../variables/Snat_Dnat/Snat_Dnat.robot
Resource          ../../variables/Variables.robot

*** Variables ***
${DCGW_SYSTEM_IP}    ${TOOLS_SYSTEM_IP}
@{PORT_LIST_NEW}    PORT15
@{VM_NAME_NEW}    VM15
${MAC_REGEX}      (([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2}))
${IP_REGEX}       (([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])
${user}           bgpd
${password}       sdncbgpc
${ping_packet_count}    5
@{TABLE_NO}       25    26    44    46    47
${vm1_ip}         10.1.0.10

*** Test Cases ***

Verify update router with single external IP while router is hosting single subnet
    Create Allow All SecurityGroup    ${SECURITY_GROUP}
    Create Network    ${REQ_NETWORKS[0]}
    Create Ext Network    ${REQ_EXTERNAL_NETWORKS[0]}    ${BOOL_VALUES[0]}    ${NETWORK_TYPE[0]}
    Create SubNet    ${REQ_NETWORKS[0]}    ${REQ_SUBNETS[0]}    ${REQ_SUBNET_CIDR[0]}
    Create SubNet    ${REQ_EXTERNAL_NETWORKS[0]}    ${REQ_EXTERNAL_SUBNETWORKS[0]}    ${REQ_EXT_SUBNET_CIDR[0]}
    Create Port    ${REQ_NETWORKS[0]}    ${REQ_PORT_LIST[0]}    sg=${SECURITY_GROUP}
    Create Port    ${REQ_NETWORKS[0]}    ${REQ_PORT_LIST[1]}    sg=${SECURITY_GROUP}
    Create Router    ${ROUTER_NAME[0]}
    Add Router Interface    ${ROUTER_NAME[0]}    ${REQ_SUBNETS[0]}
    #Add Router Interface    ${ROUTER_NAME[0]}    ${REQ_SUBNETS[1]}
    Create L3vpn    ${VPN_NAME[0]}
    Associate L3vpn To Network    ${REQ_EXTERNAL_NETWORKS[0]}    ${VPN_NAME[0]}
    ${subnetid}=    Write Commands Until Expected Prompt    neutron subnet-list | grep ${REQ_EXTERNAL_SUBNETWORKS[0]} | awk '{print $2}'    >
    ${output}    Add Router Gatewayy    ${ROUTER_NAME[0]}    ${REQ_EXTERNAL_NETWORKS[0]}    --enable-snat
    Log    ${output}
    ${output}    Write Commands Until Expected Prompt    neutron router-show ${ROUTER_NAME[0]}    >
    Log    ${output}
    Should Contain    ${output}    "enable_snat": true
    Create Vm Instance With Port On Compute Node    ${REQ_PORT_LIST[0]}    ${VM_INSTANCES_DPN1[0]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${REQ_PORT_LIST[1]}    ${VM_INSTANCES_DPN1[1]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    log    ping from vm instance1 to vm instance2
    sleep    10s
    ${ex_ip}    Get External Ip For Snat
    Set Global Variable    ${ex_ip}
    ${vm1_ip}    Wait Until Keyword Succeeds    180s    10s    Get Vm Ip    ${VM_INSTANCES_DPN1[0]}    ${REQ_NETWORKS[0]}
    Set Global Variable    ${vm1_ip}
    ${vm2_ip}    Wait Until Keyword Succeeds    180s    10s    Get Vm Ip    ${VM_INSTANCES_DPN2[1]}    ${REQ_NETWORKS[1]}
    Set Global Variable    ${vm2_ip}
    Verify telnet Status    ${REQ_NETWORKS[0]}    ${vm1_ip}    ${LOOPBACK_IP}    Connection timed out
    #switch connection    ${compute_1}
    ${output}=    Write Commands Until Expected Prompt    sudo ovs-ofctl -O Openflow13 dump-flows br-int | grep table=${TABLE_NO[3]},    Openstack-Controller:
    Log    ${output}
    should contain    ${output}    actions=set_field:${ex_ip}
    ${output}=    Write Commands Until Expected Prompt    sudo ovs-ofctl -O Openflow13 dump-flows br-int | grep table=${TABLE_NO[2]},    Openstack-Controller:
    Log    ${output}
    should contain    ${output}    nw_dst=${ex_ip}

Verify update router by removing the external IP while router is hosting single subnet
    ${output}    Clear Router Gateway    ${ROUTER_NAME[0]}    ${REQ_EXTERNAL_NETWORKS[0]}
    Verify telnet Status    ${REQ_NETWORKS[0]}    ${vm1_ip}    ${LOOPBACK_IP}    Connection timed out
    ${output}=    Write Commands Until Expected Prompt    sudo ovs-ofctl -O Openflow13 dump-flows br-int | grep table=${TABLE_NO[3]},    Openstack-Controller:
    Log    ${output}
    Should Not Contain    ${output}    actions=set_field:${ex_ip}
    ${output}=    Write Commands Until Expected Prompt    sudo ovs-ofctl -O Openflow13 dump-flows br-int | grep table=${TABLE_NO[2]},    Openstack-Controller:
    Log    ${output}
    Should Not Contain    ${output}    nw_dst=${ex_ip}

Verify update router with new single external IP while router is hosting single subnet
    ${output}    Add Router Gatewayy    ${ROUTER_NAME[0]}    ${REQ_EXTERNAL_NETWORKS[0]}    --enable-snat
    Log    ${output}
    ${ex_ip}    Get External Ip For Snat
    Log    ${ex_ip}
    Verify telnet Status    ${REQ_NETWORKS[0]}    ${vm1_ip}    ${LOOPBACK_IP}    Connection timed out
    ${output}=    Write Commands Until Expected Prompt    sudo ovs-ofctl -O Openflow13 dump-flows br-int | grep table=${TABLE_NO[3]},    Openstack-Controller:
    Log    ${output}
    should contain    ${output}    actions=set_field:${ex_ip}
    ${output}=    Write Commands Until Expected Prompt    sudo ovs-ofctl -O Openflow13 dump-flows br-int | grep table=${TABLE_NO[2]},    Openstack-Controller:
    Log    ${output}
    should contain    ${output}    nw_dst=${ex_ip}

Verify update router with scenario where externalIPs are more than subnet associated to router
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    neutron subnet-list | grep ${REQ_EXTERNAL_SUBNETWORKS[0]} | awk {'print $2'}    >
    ${ext_subid}    Should Match Regexp    ${output}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${ext_subid}
    ${output}=    Write Commands Until Expected Prompt    neutron router-gateway-set ${ROUTER_NAME[0]} ${REQ_EXTERNAL_NETWORKS[0]} --fixed-ip subnet_id=${ext_subid},ip_address=100.100.100.30 --fixed-ip subnet_id=${ext_subid},ip_address=100.100.100.40    >
    Log    ${output}
    Verify telnet Status    ${REQ_NETWORKS[0]}    ${vm1_ip}    ${LOOPBACK_IP}    Connection timed out
    ${output}=    Write Commands Until Expected Prompt    sudo ovs-ofctl -O Openflow13 dump-flows br-int | grep table=${TABLE_NO[3]},    Openstack-Controller:
    Log    ${output}
    should contain    ${output}    actions=set_field:100.100.100.
    ${output}=    Write Commands Until Expected Prompt    sudo ovs-ofctl -O Openflow13 dump-flows br-int | grep table=${TABLE_NO[2]},    Openstack-Controller:
    Log    ${output}
    should contain    ${output}    nw_dst=100.100.100.
    [Teardown]    Clean

*** Keywords ***
Create Ext Network
    [Arguments]    ${external_network}    ${ext_value}    ${type}    ${verbose}=TRUE
    ${command}    Set Variable If    "${verbose}" == "TRUE"    neutron net-create ${external_network} \ --router:external=${ext_value} \ --provider:network_type ${type}
    ${output}=    Write Commands Until Prompt    ${command}    30s
    Log    ${output}
    Should Contain    ${output}    Created a new network:

Add Router Gatewayy
    [Arguments]    ${router_name}    ${external_network_name}    ${additional_args}=${EMPTY}
    Comment    ${cmd}=    Set Variable If    '${OPENSTACK_BRANCH}'=='stable/newton'    neutron -v router-gateway-set ${router_name} ${external_network_name} \ ${additional_args}    openstack router set ${router_name} --external-gateway ${external_network_name}
    ${output}=    Write Commands Until Expected Prompt    neutron router-gateway-set ${router_name} ${external_network_name} \ ${additional_args}    >
    Comment    ${rc}    ${output}=    Run And Return Rc And Output    ${cmd}
    Comment    Should Not Be True    ${rc}
    Should Contain    ${output}    Set gateway for router

Create L3vpn
    [Arguments]    ${vpn_name}    ${verbose}=TRUE
    ${command}    Set Variable If    "${verbose}" == "TRUE"    neutron bgpvpn-create --name ${vpn_name} --route-distinguishers ${DCGW_RD} --route-targets ${DCGW_RD} --import-targets ${DCGW_RD} --export-targets ${DCGW_RD} \
    ${output}=    Write Commands Until Prompt    ${command}    30s
    Log    ${output}
    Should Contain    ${output}    Created a new bgpvpn:

Associate L3vpn To Network
    [Arguments]    ${net}    ${vpn}    ${verbose}=TRUE
    ${command}    Set Variable If    "${verbose}" == "TRUE"    neutron bgpvpn-net-assoc-create --network ${net} ${vpn}
    ${output}=    Write Commands Until Prompt    ${command}    30s
    Log    ${output}
    Should Contain    ${output}    Created a new network_association:

Create BGP Config On DCGW
    [Documentation]    Configure BGP on DCGW
    Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    ${VPN_NAME[0]}    ${DCGW_RD}
    ...    ${LOOPBACK_IP}
    Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    lo    ${LOOPBACK_IP}
    Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    lo1    ${LOOPBACK_IP1}
    ${output} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show running-config
    Log    ${output}
    ${output} =    Wait Until Keyword Succeeds    180s    10s    Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
    Log    ${output}
    ${output1} =    Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show ip bgp vrf ${DCGW_RD}
    Log    ${output1}

Create Floating Ip
    [Arguments]    ${ip}    ${net}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    neutron floatingip-create ${net} --floating-ip-address ${ip}    >
    Should Contain    ${output}    Created a new floatingip:

Associate Floating Ip To Port
    [Arguments]    ${ip}    ${port_name}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    neutron floatingip-associate $(neutron floatingip-list | grep -w '${ip}' | awk '{print $2}') $(neutron port-list | grep -w '${port_name}' | awk '{print $2}')    >
    Should Contain    ${output}    Associated floating IP

Devstack Login
    [Arguments]    ${ip}    ${username}    ${password}    ${prompt}    ${devstack_path}=/home/openstack/devstack
    ${dev_stack_conn_id}=    SSHLibrary.Open Connection    ${ip}    prompt=${prompt}
    Set Suite Variable    ${dev_stack_conn_id}
    log    ${username},${password}
    Login    ${username}    ${password}
    ${cd}    Write Commands Until Expected Prompt    cd ${devstack_path}    $    30
    ${openrc}    Write Commands Until Expected Prompt    source openrc admin admin    $    30
    ${pwd}    Write Commands Until Expected Prompt    pwd    $    30
    log    ${pwd}
    [Return]    ${dev_stack_conn_id}

Clean
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    Log    Delete the VM instances
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES_DPN1}
    \    Delete Vm Instance    ${VmInstance}
    Log    Delete neutron ports
    : FOR    ${idx}    IN RANGE    0    4
    \    Delete Port    ${REQ_PORT_LIST[${idx}]}
    Log    Delete Interface From Router
    : FOR    ${INTERFACE}    IN    @{REQ_SUBNETS}
    \    Remove Interface    ${ROUTER_NAME[0]}    ${INTERFACE}
    Log    Delete subnets
    : FOR    ${Subnet}    IN    @{REQ_SUBNETS}
    \    Delete SubNet    ${Subnet}
    Log    Delete Routers
    : FOR    ${Router}    IN    @{REQ_SUBNETS}
    \    Delete Router    ${Router}
    Log    Delete External Subnets
    : FOR    ${ExtSubnet}    IN    @{REQ_EXTERNAL_SUBNETWORKS}
    \    Delete SubNet    ${ExtSubnet}
    Log    Delete networks
    : FOR    ${Network}    IN    @{REQ_NETWORKS}
    \    Delete Network    ${Network}
    Delete SecurityGroup    ${SECURITY_GROUP}

Get Vm Ip
    [Arguments]    ${vm}    ${Net}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${ip}=    Write Commands Until Prompt    nova show ${vm} | grep ${Net} | awk '{print$5}'    30s
    ${vms_ip}    Should Match Regexp    ${ip}    [0-9]\.+
    @{vm}    Split String    ${vms_ip}    ,
    ${vm_out}    Set Variable    ${vm[0]}
    [Return]    ${vm_out}

Get External Ip For Snat
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${ip}=    Write Commands Until Prompt    openstack router show RTR1 | grep ip_address | awk '{print $12}'    30s
    ${flt_ip}    Should Match Regexp    ${ip}    [0-9]\.+
    @{vm}    Split String    ${flt_ip}    "
    ${flt_out}    Set Variable    ${vm[0]}
    [Return]    ${flt_out}

Verify telnet Status
    [Arguments]    ${net}    ${vm_ip1}    ${ip}    ${telnet_regx}
    [Documentation]    Verify Ping Success among VMs
    ${output}=    Wait Until Keyword Succeeds    180s    10s    Execute Command on VM Instance    ${net}    ${vm_ip1}
    ...    telnet ${ip}
    Should Contain    ${output}    ${telnet_regx}
    [Return]    ${output}

Clear Router Gateway
    [Arguments]    ${router_name}    ${external_network_name}    ${additional_args}=${EMPTY}
    Comment    ${cmd}=    Set Variable If    '${OPENSTACK_BRANCH}'=='stable/newton'    neutron -v router-gateway-set ${router_name} ${external_network_name} \ ${additional_args}    openstack router set ${router_name} --external-gateway ${external_network_name}
    ${output}=    Write Commands Until Expected Prompt    neutron router-gateway-clear ${router_name} ${external_network_name} \ ${additional_args}    >
    Comment    ${rc}    ${output}=    Run And Return Rc And Output    ${cmd}
    Comment    Should Not Be True    ${rc}
    Should Contain    ${output}    Removed gateway from router

Delete Floating Ip
    [Documentation]    Verify Ping Success among VMs
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    neutron floatingip-list | awk {'print $2'}    >
    ${ext_subid}    Should Match Regexp    ${output}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Log    ${ext_subid}
    ${output}=    Write Commands Until Expected Prompt    neutron floatingip-delete ${ext_subid}    >
    Log    ${output} 


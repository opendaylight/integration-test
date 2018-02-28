*** Settings ***
Documentation     Test Suite for Gateway mac based L2L3 seggragation
Suite Setup       Start Suite
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           Collections
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${REQ_NUM_NET}    2
${REQ_NUM_SUBNET}    2
${REQ_NUM_OF_PORTS}    4
${REQ_NUM_OF_VMS_PER_DPN}    2
${REQ_NO_OF_ROUTERS}    1
${REQ_NUM_OF_PORTS_PER_DPN}    2
${NUM_OF_PORTS_PER_HOST}    2
@{REQ_NETWORKS}    NET1    NET2
@{VM_INSTANCES_DPN1}    VM1    VM2
@{VM_INSTANCES_DPN2}    VM3    VM4
@{VM_NAMES}       VM1    VM2    VM3    VM4
@{NET_1_VMS}      VM1    VM2
@{NET_2_VMS}      VM3    VM4
@{PORT_LIST}      PORT1    PORT2    PORT3    PORT4
${NUM_OF_PORTS_PER_HOST}    2
@{REQ_SUBNETS}    SUBNET1    SUBNET2
@{ROUTER_INTERFACE}    SUBNET1    SUBNET2
@{REQ_SUBNET_CIDR}    10.1.0.0/16    10.2.0.0/16
${REQ_ROUTER}     RTR1
@{DEFAULT_GATEWAY_IPS}    10.1.0.1    10.2.0.1
${NEXTHOP}        0.0.0.0
${VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261112
${VPN_NAME}       vpn1
${NUM_OF_L3VPN}    1
${CREATE_RD}      ["100:31"]
${CREATE_EXPORT_RT}    ["100:31"]
${CREATE_IMPORT_RT}    ["100:31"]
${SECURITY_GROUP}    sg-vpnservice
${TABLE_NO_0}     table=0
${TABLE_NO_17}    table=17
${TABLE_NO_19}    table=19
${TABLE_NO_21}    table=21
${TABLE_NO_43}    table=43
${TABLE_NO_81}    table=81
${TABLE_NO_220}    table=220
${ARP_RESPONSE}    arp_op=2
${ARP_REQUEST}    arp_op=1
${RESUBMIT_VALUE}    17
${GWMAC_TABLE}    19
${DISPATCHER_TABLE}    17
${ARP_RESPONDER_TABLE}    81
${PKT_DIVARIABLE1}    n_packets=0
${ODL_FLOWTABLE_L3VPN}    21
${TABLE_43}       43
${DUMP_FLOWS}     sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
${GROUP_FLOWS}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
${CONTROLLER_ACTION}    CONTROLLER:65535
${ARP_REQUEST_REGEX}    arp,arp_op=1 actions=group:\\d+

*** Test Cases ***
Verify that table Miss entry for GWMAC table 19 points to table 17 dispatcher table
    [Documentation]    To Verify there should be an entry for table=17,in the table=19 DUMP_FLOWS
    ${flow_output}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${DUMP_FLOWS}|grep table=${GWMAC_TABLE}
    Should Contain    ${flow_output}    priority=0    actions=resubmit(,17)

Verify the pipeline flow from dispatcher table 17 (L3VPN) to table 19
    [Documentation]    To Verify the end to end pipeline flow from table=17 to table=19 DUMP_FLOWS
    ${subport_id_1}    Get Sub Port Id    ${PORT_LIST[0]}
    ${subport_id_2}    Get Sub Port Id    ${PORT_LIST[1]}
    ${port_num_1}    Get Port Number    ${subport_id_1}    ${OS_COMPUTE_1_IP}
    ${port_num_2}    Get Port Number    ${subport_id_2}    ${OS_COMPUTE_1_IP}
    ${flow_output}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${DUMP_FLOWS}|grep ${TABLE_NO_0}
    Should Contain    ${flow_output}    in_port=${port_num_1}    goto_table:${DISPATCHER_TABLE}
    ${metadata}    Get Metadata    ${OS_COMPUTE_1_IP}    ${port_num_1}
    ${vpn_id}    VPN Get L3VPN ID
    ${flow_output}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${DUMP_FLOWS}|grep ${TABLE_NO_17} | grep ${vpn_id}
    Should Contain    ${flow_output}    ${vpn_id}
    Should Contain    ${flow_output}    goto_table:${GWMAC_TABLE}
    ${gw_mac_addr}    Get Default Mac Addr    ${DEFAULT_GATEWAY_IPS[0]}
    ${port_mac_addr}    OpenStackOperations.Get Port Mac    ${PORT_LIST[0]}
    ${flow_output}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${DUMP_FLOWS} |grep ${TABLE_NO_19}
    Should Contain    ${flow_output}    resubmit(,17)
    ${flow_output}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${DUMP_FLOWS}|grep ${TABLE_NO_17} |grep ${metadata}
    Should Contain    ${flow_output}    goto_table:${TABLE_43}
    ${flow_output}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${DUMP_FLOWS}|grep ${TABLE_NO_43}
    @{group_id}    Get Regexp Matches    ${flow_output}    group:(\\d+)    1
    Should Contain    ${flow_output}    arp,arp_op=1 actions=group:${group_id[0]}
    ${flow_output}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${GROUP_FLOWS} |grep group_id=${group_id[0]}
    Should Contain    ${flow_output}    bucket=actions=resubmit(,81)
    ${flow_output}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${DUMP_FLOWS}|grep ${TABLE_NO_81}
    Should Contain    ${flow_output}    set_field:${gw_mac_addr}
    Should Contain    ${flow_output}    resubmit(,220)
    ${flow_output}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${DUMP_FLOWS}|grep ${TABLE_NO_220}
    Should Contain    ${flow_output}    output:${port_num_2}

Verify that ARP requests received on GWMAC table are punted to controller for learning ,resubmitted to table 17,sent to ARP responder
    [Documentation]    To verify the ARP Request entry should be there after the dump_groups and dispatcher table should point to ARP responder
    ${flow_output}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${DUMP_FLOWS}|grep ${TABLE_NO_19}
    Should Contain    ${flow_output}    arp,arp_op=1 actions=resubmit(,17)
    ${flow_output}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${DUMP_FLOWS}|grep ${TABLE_NO_17}
    Should Contain    ${flow_output}    goto_table:${TABLE_43}
    ${flow_output}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${DUMP_FLOWS}|grep ${TABLE_NO_43}
    @{group_id}    Get Regexp Matches    ${flow_output}    group:(\\d+)    1
    BuiltIn.Log    ${group_id[0]}
    Should Contain    ${flow_output}    arp,arp_op=1 actions=group:${group_id[0]}
    ${flow_output}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${GROUP_FLOWS}|grep group_id=${group_id[0]}
    Should Contain    ${flow_output}    bucket=actions=resubmit(,81)

Verify that ARP response received on GWMAC table are punted to controller for learning, resubmitted to table 17
    [Documentation]    Verify that ARP response received on GWMAC table are punted to controller for learning, resubmitted to table 17
    ${flow_output}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${DUMP_FLOWS}|grep ${TABLE_NO_19}
    Should Contain    ${flow_output}    arp,arp_op=2 actions=resubmit(,17)
    ${flow_output}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${DUMP_FLOWS}|grep ${TABLE_NO_17}
    Should Contain    ${flow_output}    goto_table:${TABLE_43}
    ${flow_output}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${DUMP_FLOWS}|grep ${TABLE_NO_43}
    @{group_id}    Get Regexp Matches    ${flow_output}    group:(\\d+)    1
    Log    ${group_id[0]}
    Should Contain    ${flow_output}    arp,arp_op=1 actions=group:${group_id[0]}
    ${flow_output}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${GROUP_FLOWS}|grep group_id=${group_id[0]}
    Should Contain    ${flow_output}    bucket=actions=resubmit(,81)

Verify that table miss entry for table 17 should not point to table 81 arp table
    [Documentation]    To Verify there should not be an entry for the arp_responder_table in table=17
    ${flow_output}=    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${DUMP_FLOWS} |grep ${TABLE_NO_17} |grep priority=0
    Should Not Contain    ${flow_output}    goto_table:${ARP_RESPONDER_TABLE}

*** Keywords ***
Start Suite
    [Documentation]    Test Suite for Gateway mac based L2L3 seggragation
    VpnOperations.Basic Suite Setup
    OpenStackOperations.Create Nano Flavor
    Create Setup

Create Neutron Networks
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of networks
    : FOR    ${NET}    IN    @{REQ_NETWORKS}
    \    OpenStackOperations.Create Network    ${NET}
    ${network1_id}    OpenStackOperations.Get Net Id    @{REQ_NETWORKS}[0]
    ${network2_id}    OpenStackOperations.Get Net Id    @{REQ_NETWORKS}[1]
    Set Suite Variable    ${network1_id}
    Set Suite Variable    ${network2_id}
    ${NET_LIST}    OpenStackOperations.List Networks
    BuiltIn.Log    ${NET_LIST}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    BuiltIn.Should Contain    ${NET_LIST}    ${REQ_NETWORKS[${index}]}

Create Neutron Subnets
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of subnets for previously created networks
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    OpenStackOperations.Create SubNet    ${REQ_NETWORKS[${index}]}    ${REQ_SUBNETS[${index}]}    ${REQ_SUBNET_CIDR[${index}]}
    ${SUB_LIST}    OpenStackOperations.List Subnets
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    BuiltIn.Should Contain    ${SUB_LIST}    ${REQ_SUBNETS[${index}]}

Create Neutron Ports
    [Arguments]    ${NUM_OF_PORTS}
    [Documentation]    Create required number of ports under previously created subnets
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_PORTS_PER_HOST}
    \    Create Port    @{REQ_NETWORKS}[${index}]    @{PORT_LIST}[${index}]    sg=${SECURITY_GROUP}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_PORTS_PER_HOST}
    \    ${start} =    Evaluate    ${index}+2
    \    Create Port    @{REQ_NETWORKS}[${index}]    @{PORT_LIST}[${start}]    sg=${SECURITY_GROUP}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${PORT_URL}    ${PORT_LIST}

Create Nova VMs
    [Arguments]    ${NUM_OF_VMS_PER_DPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create Vm instances on compute nodes
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${index}]}    ${VM_NAMES[${index}]}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    ${start} =    Evaluate    ${index}+1
    ${NUM_OF_VMS_PER_DPN} =    Evaluate    ${start}+${NUM_OF_VMS_PER_DPN}
    : FOR    ${index}    IN RANGE    ${start}    ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${index}]}    ${VM_NAMES[${index}]}    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    @{NET_2_VM_IPS}    ${NET_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_2_VM_IPS}
    BuiltIn.Should Not Contain    @{NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    @{NET_2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IP}    None
    @{VM_IPs}=    Create List    @{NET_1_VM_IPS}    @{NET_2_VM_IPS}
    Set Suite Variable    ${VM_IPs}

Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports And Four VMs on each DPN
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Create Neutron Networks    ${REQ_NUM_NET}
    Create Neutron Subnets    ${REQ_NUM_SUBNET}
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    Create Neutron Ports    ${REQ_NUM_OF_PORTS}
    Create Nova VMs    ${REQ_NUM_OF_VMS_PER_DPN}
    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID}    name=${VPN_NAME}    rd=${CREATE_RD}    exportrt=${CREATE_EXPORT_RT}    importrt=${CREATE_IMPORT_RT}
    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID}
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID}
    Should Contain    ${resp}    ${router_id}

Create Sub Interfaces And Verify
    [Documentation]    Create Sub Interface and verify for all VMs
    : FOR    ${vm_ip}    IN    @{VM_IP_NET1}
    \    BuiltIn.BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}
    : FOR    ${vm_ip}    IN    @{VM_IP_NET2}
    \    BuiltIn.BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[1]}    ${ALLOWED_IP[2]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[1]}    ${ALLOWED_IP[2]}
    \    ...    ${vm_ip}
    : FOR    ${vm_ip}    IN    @{VM_IP_NET3}
    \    BuiltIn.BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[2]}    ${ALLOWED_IP[4]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[2]}    ${ALLOWED_IP[4]}
    \    ...    ${vm_ip}

Configure_IP_On_Sub_Interface
    [Arguments]    ${network_name}    ${ip}    ${vm_ip}    ${mask}    ${interface}=eth0    ${sub_interface_number}=1
    [Documentation]    Keyword for configuring specified IP on specified interface and the corresponding specified sub interface
    OpenStackOperations.Execute Command on VM Instance    ${network_name}    ${vm_ip}    sudo ifconfig ${interface}:${sub_interface_number} ${ip} netmask ${mask} up

Verify_IP_Configured_On_Sub_Interface
    [Arguments]    ${network_name}    ${ip}    ${vm_ip}    ${interface}=eth0    ${sub_interface_number}=1
    [Documentation]    Keyword for verifying specified IP on specified interface and the corresponding specified sub interface
    ${resp}    OpenStackOperations.Execute Command on VM Instance    ${network_name}    ${vm_ip}    sudo ifconfig ${interface}:${sub_interface_number}
    BuiltIn.Should Contain    ${resp}    ${ip}

Get Sub Port Id
    [Arguments]    ${portname}
    [Documentation]    Get the Sub Port ID
    ${port_id}    OpenStackOperations.Get Port Id    ${portname}
    Should Match Regexp    ${port_id}    \\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}
    @{output}    Get Regexp Matches    ${port_id}    (\\w{8}-\\w{2})
    [Return]    ${output[0]}

Get Port Number
    [Arguments]    ${portname}    ${ip_addr}
    [Documentation]    Get the port number for given portname
    ${command_1}    Set Variable    sudo ovs-ofctl -O OpenFlow13 show br-int | grep ${portname} | awk '{print$1}'
    BuiltIn.Log    sudo ovs-ofctl -O OpenFlow13 show br-int | grep ${portname} | awk '{print$1}'
    ${num}=    Utils.Run Command On Remote System    ${ip_addr}    ${command_1}
    ${port_number}    Should Match Regexp    ${num}    [0-9]+
    [Return]    ${port_number}

Get Metadata
    [Arguments]    ${ip_addr}    ${port}
    [Documentation]    Get the Metadata for a given port
    ${cmd}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 br-int| grep table=0 | grep in_port=${port}
    ${output}    Utils.Run Command On Remote System    ${ip_addr}    ${cmd}
    @{list_any_matches} =    String.Get_Regexp_Matches    ${output}    metadata:(\\w{12})    1
    ${metadata1}    Convert To String    @{list_any_matches}
    ${output}    Get Substring    ${metadata1}    2
    [Return]    ${output}

Get Default Mac Addr
    [Arguments]    ${default_gw_ip}
    [Documentation]    Retrieve the port id for the given port name to attach specific vm instance to a particular port
    ${output}=    OpenStack CLI    openstack port list | grep -w ${default_gw_ip} | awk '{print $5}'
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${gw_mac_addr}=    Get from List    ${splitted_output}    0
    [Return]    ${gw_mac_addr}

VPN Get L3VPN ID
    [Documentation]    Check that sub interface ip has been learnt after ARP request
    ${resp}    RequestsLibrary.Get Request    session    ${VPN_REST}
    BuiltIn.Log    ${resp.content}
    @{list_any_matches} =    String.Get_Regexp_Matches    ${resp.content}    \"vpn-instance-name\":\"${VPN_INSTANCE_ID}\",\"vpn-id\":(\\d+)    1
    ${result}=    Evaluate    ${list_any_matches[0]} * 2
    ${vpn_id_hex}=    Convert To Hex    ${result}
    [Return]    ${vpn_id_hex.lower()}

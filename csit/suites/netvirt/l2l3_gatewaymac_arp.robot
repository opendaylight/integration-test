*** Settings ***
Documentation     Test Suite for Gateway mac based L2L3 seggragation
Suite Setup       Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           Collections
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Resource          ../../libraries/BgpOperations.robot
Resource          ../../libraries/DevstackUtils.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/OpenStackOperations.robot
Resource          ../../libraries/OvsManager.robot
Resource          ../../libraries/SetupUtils.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../variables/netvirt/Variables.robot
Resource          ../../variables/Variables.robot

*** Variables ***
${REQ_NUM_NET}    2
${REQ_NUM_SUBNET}    2
${REQ_NUM_OF_PORTS}    4
${REQ_NUM_OF_VMS_PER_DPN}    2
${NUM_OF_PORTS_PER_HOST}    2
${NEXTHOP}        0.0.0.0
@{REQ_NETWORKS}    l2l3_gw_mac_arp_net1    l2l3_gw_mac_arp_net2
@{VM_NAMES}       l2l3_gw_mac_arp_vm1    l2l3_gw_mac_arp_vm2    l2l3_gw_mac_arp_vm3    l2l3_gw_mac_arp_vm4
@{NET_1_VMS}      l2l3_gw_mac_arp_vm1    l2l3_gw_mac_arp_vm2
@{NET_2_VMS}      l2l3_gw_mac_arp_vm3    l2l3_gw_mac_arp_vm4
@{PORT_LIST}      l2l3_gw_mac_arp_port1    l2l3_gw_mac_arp_port2    l2l3_gw_mac_arp_port3    l2l3_gw_mac_arp_port4
@{REQ_SUBNETS}    l2l3_gw_mac_arp_subnet1    l2l3_gw_mac_arp_subnet2
@{REQ_SUBNET_CIDR}    10.1.0.0/16    10.2.0.0/16
${REQ_ROUTER}     l2l3_gw_mac_arp_rtr1
@{DEFAULT_GATEWAY_IPS}    10.1.0.1    10.2.0.1
${VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261112
${VPN_NAME}       l2l3_gw_mac_arp_vpn1
${VPN_REST}       ${CONFIG_API}/odl-l3vpn:vpn-instance-to-vpn-id/
${VRF_ID}         100:31
${L3VPN_RD}       ["${VRF_ID}"]
${SECURITY_GROUP}    l2l3_gw_mac_arp_sg
${TABLE_NO_0}     0
${TABLE_NO_220}    220
${DUMP_FLOWS}     sudo ovs-ofctl -O OpenFlow13 dump-flows ${INTEGRATION_BRIDGE}
${GROUP_FLOWS}    sudo ovs-ofctl -O OpenFlow13 dump-groups ${INTEGRATION_BRIDGE}
${ARP_REQUEST_OPERATIONAL_CODE}    1
${ARP_RESPONSE_OPERATIONAL_CODE}    2
${RESUBMIT_VALUE}    actions=resubmit\(,${DISPATCHER_TABLE}\)
${PING_COUNT_VALUE}    0

*** Test Cases ***
Verify that table Miss entry for GWMAC table 19 points to table 17 dispatcher table
    [Documentation]    To Verify there should be an entry for table=17,in the table=19 DUMP_FLOWS
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${GWMAC_TABLE}    True    ${EMPTY}    priority=0    actions=resubmit(,17)

Verify the pipeline flow from dispatcher table 17 (L3VPN) to table 19
    [Documentation]    To Verify the end to end pipeline flow from table=17 to table=19 DUMP_FLOWS
    ${subport_id_1} =    OpenStackOperations.Get Sub Port Id    ${PORT_LIST[0]}
    ${subport_id_2} =    OpenStackOperations.Get Sub Port Id    ${PORT_LIST[1]}
    ${port_num_1} =    OVSDB.Get Port Number    ${subport_id_1}    ${OS_CMP1_IP}
    ${port_num_2} =    OVSDB.Get Port Number    ${subport_id_2}    ${OS_CMP1_IP}
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${TABLE_NO_0}    True    ${EMPTY}    in_port=${port_num_1}    goto_table:${DISPATCHER_TABLE}
    ${metadata} =    OVSDB.Get Port Metadata    ${OS_CMP1_IP}    ${port_num_1}
    ${vpn_id} =    VpnOperations.VPN Get L3VPN ID    ${VRF_ID}
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${DISPATCHER_TABLE}    True    |grep ${vpn_id}    ${vpn_id}    goto_table:${GWMAC_TABLE}
    ${gw_mac_addr} =    OpenStackOperations.Get Port Mac Address From Ip    ${DEFAULT_GATEWAY_IPS[0]}
    Verify Flows Are Present For ARP    ${ARP_REQUEST_OPERATIONAL_CODE}    |grep ${metadata}
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_RESPONSE_TABLE}    True    ${EMPTY}    set_field:${gw_mac_addr}    resubmit(,220)
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${TABLE_NO_220}    True    ${EMPTY}    output:${port_num_2}

Verify that ARP requests and ARP response received on GWMAC table are punted to controller for learning ,resubmitted to table 17,sent to ARP responder
    [Documentation]    To verify the ARP Request and ARP response entry should be there after the dump_groups and dispatcher table should point to ARP responder
    Verify Flows Are Present For ARP    ${ARP_REQUEST_OPERATIONAL_CODE}
    Verify Flows Are Present For ARP    ${ARP_RESPONSE_OPERATIONAL_CODE}

Verify that table miss entry for table 17 should not point to table 81 arp table
    [Documentation]    To Verify there should not be an entry for the arp_responder_table in table=17
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${DISPATCHER_TABLE}    False    |grep priority=0    goto_table:${ARP_RESPONSE_TABLE}

Verify that Multiple GWMAC entries in GWMAC table points to FIB table 21 (L3VPN pipeline)
    [Documentation]    To Verify the one or more default gateway mac enteries on the table=19 flows that points to FIB table 21
    ${gw_mac_addr_1} =    OpenStackOperations.Get Port Mac Address From Ip    ${DEFAULT_GATEWAY_IPS[0]}
    ${gw_mac_addr_2} =    OpenStackOperations.Get Port Mac Address From Ip    ${DEFAULT_GATEWAY_IPS[1]}
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${GWMAC_TABLE}    True    ${EMPTY}    dl_dst=${gw_mac_addr_1}    actions=goto_table:${L3_TABLE}
    ${pkt_count_before_ping} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=${GWMAC_TABLE} | grep dl_dst=${gw_mac_addr_1}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 8 @{NET_2_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${pkt_count_after_ping} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=${GWMAC_TABLE} | grep dl_dst=${gw_mac_addr_1}
    ${pkt_diff} =    Evaluate    int(${pkt_count_after_ping})-int(${pkt_count_before_ping})
    BuiltIn.Should Be True    ${pkt_diff} > ${PING_COUNT_VALUE}
    ${pkt_count_before_ping} =    OvsManager.Get Packet Count From Table    ${OS_CMP2_IP}    ${INTEGRATION_BRIDGE}    table=${GWMAC_TABLE} | grep dl_dst=${gw_mac_addr_1}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{NET_2_VM_IPS}[0]    ping -c 8 @{NET_1_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${pkt_count_after_ping} =    OvsManager.Get Packet Count From Table    ${OS_CMP2_IP}    ${INTEGRATION_BRIDGE}    table=${GWMAC_TABLE} | grep dl_dst=${gw_mac_addr_1}
    ${pkt_diff} =    Evaluate    int(${pkt_count_after_ping})-int(${pkt_count_before_ping})
    BuiltIn.Should Be True    ${pkt_diff} > ${PING_COUNT_VALUE}

Verify table miss entry of ARP responder table points to drop actions
    [Documentation]    To Verify the default flow entry of table=81 drops when openflow controller connected to compute node
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_RESPONSE_TABLE}    True    |grep priority=0    actions=drop

Verify ARP eth_type entries and actions for ARP request and ARP response are populated on GWMAC table
    [Documentation]    To Verify the entry of ARP request(arp=1) and ARP response(arp=2) in table=19
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${GWMAC_TABLE}    True    ${EMPTY}    arp_op=${ARP_REQUEST_OPERATIONAL_CODE}    ${RESUBMIT_VALUE}

Verify GWMAC entires are populated with Neutron Router MAC address per network in GWMAC table
    [Documentation]    To Verify gateway mac entires are populated with neutron router mac address for network with vpn dissociation from router
    VpnOperations.Dissociate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID}
    ${gw_mac_addr} =    OpenStackOperations.Get Port Mac Address From Ip    ${DEFAULT_GATEWAY_IPS[1]}
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${GWMAC_TABLE}    True
    ...    ${EMPTY}    dl_dst=${gw_mac_addr}    actions=goto_table:${L3_TABLE}
    ${output} =    VpnOperations.Get Fib Entries    session
    BuiltIn.Should Match Regexp    ${output}    .*@{DEFAULT_GATEWAY_IPS}[1]/32.*${NEXTHOP}

Verify GWMAC entires are populated with port MAC address for network with vpn association to router in GWMAC table
    [Documentation]    To Verify gateway mac entires are populated with port MAC address for network with vpn association to router
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID}
    ${gw_mac_addr} =    OpenStackOperations.Get Port Mac Address From Ip    ${DEFAULT_GATEWAY_IPS[1]}
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${GWMAC_TABLE}    True
    ...    ${EMPTY}    dl_dst=${gw_mac_addr}    actions=goto_table:${L3_TABLE}
    ${output} =    VpnOperations.Get Fib Entries    session
    BuiltIn.Should Match Regexp    ${output}    .*${VRF_ID}.*${REQ_SUBNET_CIDR[0]}
    BuiltIn.Should Match Regexp    ${output}    .*${VRF_ID}.*${REQ_SUBNET_CIDR[1]}

*** Keywords ***
Suite Setup
    [Documentation]    Test Suite for Gateway mac based L2L3 seggragation
    VpnOperations.Basic Suite Setup
    Create Setup
    OpenStackOperations.Show Debugs    @{NET_1_VMS}    @{NET_2_VMS}
    OpenStackOperations.Get Suite Debugs

Create Neutron Networks
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of networks
    FOR    ${NET}    IN    @{REQ_NETWORKS}
        OpenStackOperations.Create Network    ${NET}
    END
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${REQ_NETWORKS}

Create Neutron Subnets
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of subnets for previously created networks
    FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
        OpenStackOperations.Create SubNet    ${REQ_NETWORKS[${index}]}    ${REQ_SUBNETS[${index}]}    ${REQ_SUBNET_CIDR[${index}]}
    END
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${REQ_SUBNETS}

Create Neutron Ports
    [Documentation]    Create required number of ports under previously created subnets
    FOR    ${index}    IN RANGE    0    ${NUM_OF_PORTS_PER_HOST}
        OpenStackOperations.Create Port    @{REQ_NETWORKS}[${index}]    @{PORT_LIST}[${index}]    sg=${SECURITY_GROUP}
        OpenStackOperations.Create Port    @{REQ_NETWORKS}[${index}]    @{PORT_LIST}[${index + 2}]    sg=${SECURITY_GROUP}
    END
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${PORT_URL}    ${PORT_LIST}

Create Nova VMs
    [Arguments]    ${NUM_OF_VMS_PER_DPN}
    [Documentation]    Create Vm instances on compute nodes
    FOR    ${index}    IN RANGE    0    ${NUM_OF_VMS_PER_DPN}
        OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORT_LIST[${index}]}    ${VM_NAMES[${index}]}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    END
    ${start} =    Evaluate    ${index}+1
    ${NUM_OF_VMS_PER_DPN} =    Evaluate    ${start}+${NUM_OF_VMS_PER_DPN}
    FOR    ${index}    IN RANGE    ${start}    ${NUM_OF_VMS_PER_DPN}
        OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORT_LIST[${index}]}    ${VM_NAMES[${index}]}    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    END
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    @{NET_2_VM_IPS}    ${NET_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_2_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IP}    None

Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports And Four VMs on each DPN
    ${output} =    Issue Command On Karaf Console    ${TEP_SHOW}
    Create Neutron Networks    ${REQ_NUM_NET}
    Create Neutron Subnets    ${REQ_NUM_SUBNET}
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    Create Neutron Ports
    OpenStackOperations.Create Router    ${REQ_ROUTER}
    Add Interfaces To Routers
    Create Nova VMs    ${REQ_NUM_OF_VMS_PER_DPN}
    ${router_id} =    OpenStackOperations.Get Router Id    ${REQ_ROUTER}
    Builtin.Set Suite Variable    ${router_id}
    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID}    name=${VPN_NAME}    rd=${L3VPN_RD}    exportrt=${L3VPN_RD}    importrt=${L3VPN_RD}
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID}

Add Interfaces To Routers
    [Documentation]    Add Multiple Interfaces to Router and Verify
    FOR    ${INTERFACE}    IN    @{REQ_SUBNETS}
        OpenStackOperations.Add Router Interface    ${REQ_ROUTER}    ${INTERFACE}
    END
    ${interface_output} =    OpenStackOperations.Show Router Interface    ${REQ_ROUTER}
    FOR    ${INTERFACE}    IN    @{REQ_SUBNETS}
        ${subnet_id} =    OpenStackOperations.Get Subnet Id    ${INTERFACE}
        BuiltIn.Should Contain    ${interface_output}    ${subnet_id}
    END

Verify Flows Are Present For ARP
    [Arguments]    ${arp_op_code}    ${additional_args}=${EMPTY}
    [Documentation]    Verify Flows Are Present For ARP entry
    ${flow_output} =    Utils.Run Command On Remote System    ${OS_CMP1_IP}    ${DUMP_FLOWS} | grep table=${GWMAC_TABLE}
    BuiltIn.Should Contain    ${flow_output}    arp,arp_op=${arp_op_code} ${RESUBMIT_VALUE}
    ${flow_output} =    Utils.Run Command On Remote System    ${OS_CMP1_IP}    ${DUMP_FLOWS} | grep table=${DISPATCHER_TABLE} ${additional_args}
    BuiltIn.Should Contain    ${flow_output}    goto_table:${ARP_CHECK_TABLE}
    ${flow_output} =    Utils.Run Command On Remote System    ${OS_CMP1_IP}    ${DUMP_FLOWS} | grep table=${ARP_CHECK_TABLE}
    @{group_id} =    String.Get Regexp Matches    ${flow_output}    group:(\\d+)    1
    BuiltIn.Should Contain    ${flow_output}    arp,arp_op=1 actions=group:${group_id[0]}
    ${flow_output} =    Utils.Run Command On Remote System    ${OS_CMP1_IP}    ${GROUP_FLOWS} | grep group_id=${group_id[0]}
    BuiltIn.Should Contain    ${flow_output}    bucket=actions=resubmit(,81)

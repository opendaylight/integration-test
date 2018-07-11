*** Settings ***
Documentation     Test Suite for Elan interface and service recovery
Suite Setup       Start Suite
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_BuiltIn.Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           Collections
Library           DebugLibrary
Library           RequestsLibrary
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
${REQ_NUM_NET}    1
${REQ_NUM_SUBNET}    1
${REQ_NUM_OF_PORTS}    4
${REQ_NUM_OF_VMS_PER_DPN}    2
${REQ_NETWORK}    NET1
@{VM_INSTANCES_DPN1}    elan_vm1_dpn1    elan_vm2_dpn1
@{VM_INSTANCES_DPN2}    elan_vm3_dpn2    elan_vm4_dpn2
@{VM_NAMES}       elan_recovery_vm1    elan_recovery_vm2    elan_recovery_vm3    elan_recovery_vm4
@{NET_1_VMS}      elan_recovery_vm1    elan_recovery_vm2
@{NET_2_VMS}      elan_recovery_vm3    elan_recovery_vm4
@{PORT_LIST}      elan_net1_port1    elan_net1_port2    elan_net1_port3    elan_net1_port4
${REQ_SUBNETS}    elan_subnet1
${REQ_SUBNET_CIDR}    10.1.0.0/16
@{DEFAULT_GATEWAY_IPS}    10.1.0.1    10.2.0.1
${SECURITY_GROUP}    sg-elanservice
${ELAN_SMAC_TABLE}    50
${ELAN_DMAC_TABLE}    51
${SHOW-SRM-STATUS}    srm:recover service elan
${SHOW-INTERFACE-STATUS}    srm:recover instance elan-interface
${NUM_OF_PORTS_PER_HOST}    2
${DUMP_FLOWS}     sudo ovs-ofctl -O OpenFlow13 dump-flows br-int

*** Test Cases ***
TC1_To Verify ELAN Service Recovery
    [Documentation]    To Verify Elan Service recovery by deleting and recovering multiple flows
    Verify Dump Flows For Specific Table    ${OS_COMPUTE_1_IP}    ${ELAN_SMAC_TABLE}    True    dl_src=${PORT_MAC_ADDR[0]}    actions=goto_table:${ELAN_DMAC_TABLE}
    Verify Dump Flows For Specific Table    ${OS_COMPUTE_2_IP}    ${ELAN_SMAC_TABLE}    True    dl_src=${PORT_MAC_ADDR[2]}    actions=goto_table:${ELAN_DMAC_TABLE}
    Delete Flows From ODL    ${DPNID_1}    ${ELAN_SMAC_TABLE}    ${PORT_MAC_ADDR[0]}
    Delete Flows From ODL    ${DPNID_2}    ${ELAN_SMAC_TABLE}    ${PORT_MAC_ADDR[2]}
    Verify Flows on ODL    ${DPNID_1}    ${ELAN_SMAC_TABLE}    ${PORT_MAC_ADDR[0]}    False
    Verify Flows on ODL    ${DPNID_2}    ${ELAN_SMAC_TABLE}    ${PORT_MAC_ADDR[2]}    False
    Verify Dump Flows For Specific Table    ${OS_COMPUTE_1_IP}    ${ELAN_SMAC_TABLE}    False    dl_src=${PORT_MAC_ADDR[0]}
    Verify Dump Flows For Specific Table    ${OS_COMPUTE_2_IP}    ${ELAN_SMAC_TABLE}    False    dl_src=${PORT_MAC_ADDR[2]}
    ${output}=    Issue Command On Karaf Console    ${SHOW-SRM-STATUS}
    Verify Dump Flows For Specific Table    ${OS_COMPUTE_1_IP}    ${ELAN_SMAC_TABLE}    True    dl_src=${PORT_MAC_ADDR[0]}    actions=goto_table:${ELAN_DMAC_TABLE}
    Verify Dump Flows For Specific Table    ${OS_COMPUTE_2_IP}    ${ELAN_SMAC_TABLE}    True    dl_src=${PORT_MAC_ADDR[2]}    actions=goto_table:${ELAN_DMAC_TABLE}
    Verify Flows on ODL    ${DPNID_1}    ${ELAN_SMAC_TABLE}    ${PORT_MAC_ADDR[0]}
    Verify Flows on ODL    ${DPNID_2}    ${ELAN_SMAC_TABLE}    ${PORT_MAC_ADDR[2]}

TC2_To Verify Elan Interface recovery by deleting single flow
    [Documentation]    To Verify the Elan Interface recovery by deleting single Flow
    Verify Dump Flows For Specific Table    ${OS_COMPUTE_1_IP}    ${ELAN_SMAC_TABLE}    True    dl_src=${PORT_MAC_ADDR[0]}    actions=goto_table:${ELAN_DMAC_TABLE}
    Delete Flows From ODL    ${DPNID_1}    ${ELAN_SMAC_TABLE}    ${PORT_MAC_ADDR[0]}
    Verify Flows on ODL    ${DPNID_1}    ${ELAN_SMAC_TABLE}    ${PORT_MAC_ADDR[0]}    False
    Verify Dump Flows For Specific Table    ${OS_COMPUTE_1_IP}    ${ELAN_SMAC_TABLE}    False    dl_src=${PORT_MAC_ADDR[0]}
    ${elan_instance_id}    Get Elan Instance ID
    ${elan_interface_id}    Get Elan Interfaces ID    ${elan_instance_id}    ${PORT_MAC_ADDR[0]}
    Recover Elan Flows    ${elan_interface_id}
    Verify Flows on ODL    ${DPNID_1}    ${ELAN_SMAC_TABLE}    ${PORT_MAC_ADDR[0]}
    Verify Dump Flows For Specific Table    ${OS_COMPUTE_1_IP}    ${ELAN_SMAC_TABLE}    True    dl_src=${PORT_MAC_ADDR[0]}    actions=goto_table:${ELAN_DMAC_TABLE}

*** Keywords ***
Start Suite
    [Documentation]    Test Suite for Elan interface and service recovery
    VpnOperations.Basic Suite Setup
    Create Setup

Create Neutron Subnets
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of subnets for previously created networks
    OpenStackOperations.Create SubNet    ${REQ_NETWORKS}    ${REQ_SUBNETS}    ${REQ_SUBNET_CIDR}

Create Neutron Ports
    [Documentation]    Create required number of ports under previously created subnets
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_PORTS_PER_HOST}
    \    OpenStackOperations.Create Port    ${REQ_NETWORKS}    @{PORT_LIST}[${index}]    sg=${SECURITY_GROUP}
    \    OpenStackOperations.Create Port    ${REQ_NETWORKS}    @{PORT_LIST}[${index + 2}]    sg=${SECURITY_GROUP}
    @{port_mac_addr}=    OpenStackOperations.Get Ports MacAddr    ${PORT_LIST}
    BuiltIn.Set Suite Variable    ${PORT_MAC_ADDR}

Create Nova VMs
    [Arguments]    ${num_of_vms_per_dpn}
    [Documentation]    Create Vm instances on compute nodes
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_VMS_PER_DPN}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORT_LIST[${index}]}    ${VM_NAMES[${index}]}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    ${start} =    Evaluate    ${index}+1
    ${NUM_OF_VMS_PER_DPN} =    Evaluate    ${start}+${NUM_OF_VMS_PER_DPN}
    : FOR    ${index}    IN RANGE    ${start}    ${NUM_OF_VMS_PER_DPN}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORT_LIST[${index}]}    ${VM_NAMES[${index}]}    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    @{NET_2_VM_IPS}    ${NET_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_2_VM_IPS}
    BuiltIn.Should Not Contain    @{NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    @{NET_2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IP}    None
    ${VM_IPS}    Combine Lists    ${NET_1_VM_IPS}    ${NET_2_VM_IPS}
    BuiltIn.Set Suite Variable    ${VM_IPS}

Create Setup
    [Documentation]    Create basic topology
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    VpnOperations.Verify Tunnel Status as UP
    OpenStackOperations.Create Network    ${REQ_NETWORKS}
    Create Neutron Subnets    ${REQ_NUM_SUBNET}
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    Create Neutron Ports
    Create Nova VMs    ${REQ_NUM_OF_VMS_PER_DPN}
    ${DPNID_1}    OVSDB.Get DPID    ${OS_COMPUTE_1_IP}
    ${DPNID_2}    OVSDB.Get DPID    ${OS_COMPUTE_2_IP}
    BuiltIn.Set Suite Variable    ${DPNID_1}
    BuiltIn.Set Suite Variable    ${DPNID_2}

Get Elan Instance ID
    [Documentation]    Retrieving ELAN instance ID
    ${output}=    Issue Command On Karaf Console    elaninterface:show
    ${elan_instance}    String.Split String    ${output}
    ${elan_instance_with_tag}    BuiltIn.Set Variable    ${elan_instance[5]}
    ${elan_instance_id}    String.Split String    ${elan_instance_with_tag}    /
    [Return]    @{elan_instance_id}[0]

Get Elan Interfaces ID
    [Arguments]    ${elan_id}    ${mac}
    [Documentation]    Getting the ELAN interface ID with corresponding max address and returning interface ID list
    ${elan_output} =    Issue Command On Karaf Console    elanmactable:show ${elan_id}
    ${interface_id} =    Get Regexp Matches    ${elan_output}    (${REGEX_UUID})\\s*${mac}    1
    [Return]    @{interface_id}[0]

Recover Elan Flows
    [Arguments]    ${interface}
    [Documentation]    Recover ELAN flows for the gievn interafces
    ${recover_msg}    Issue Command On Karaf Console    srm:recover instance elan-interface ${interface}
    BuiltIn.Should Contain    ${recover_msg}    RPC call to recover was successful

Verify Dump Flows For Specific Table
    [Arguments]    ${compute_ip}    ${table_num}    ${flag}=True    @{matching_paras}
    [Documentation]    To Verify flows are present for the corresponding table Number
    ${flow_output}=    Utils.Run Command On Remote System    ${compute_ip}    ${DUMP_FLOWS}|grep table=${table_num}
    : FOR    ${matching_str}    IN    @{matching_paras}
    \    Run Keyword If    ${flag}==True    BuiltIn.Should Contain    ${flow_output}    ${matching_str}
    \    ...    ELSE    BuiltIn.Should Not Contain    ${flow_output}    ${matching_str}

Get OpenFlow Id
    [Arguments]    ${dpnid}    ${table_id}    ${mac_addr}
    [Documentation]    To get the DPNID from the particular compute nodes
    ${resp}    Get Request    session    ${CONFIG_NODES_API}/node/openflow:${dpnid}/table/${table_id}
    BuiltIn.Log    ${resp.content}
    @{flow_id}    Get Regexp Matches    ${resp.content}    id\":\"(\\d+${mac_addr})    1
    [Return]    ${flow_id[0]}

Delete Flows From ODL
    [Arguments]    ${dpnid}    ${table_id}    ${mac_addr}
    [Documentation]    To delete the flows from the controller using REST
    ${flow_id}    Get OpenFlow Id    ${dpnid}    ${table_id}    ${mac_addr}
    ${resp}    Delete Request    session    ${CONFIG_NODES_API}/node/openflow:${dpnid}/table/${table_id}/flow/${flow_id}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify Flows on ODL
    [Arguments]    ${dpnid}    ${table_id}    ${mac_addr}    ${flag}=True
    [Documentation]    To Verify whether the flows are deleted on the controller
    ${resp}    Get Request    session    ${CONFIG_NODES_API}/node/openflow:${dpnid}/table/${table_id}
    BuiltIn.Log    ${resp.content}
    Run Keyword If    ${flag}==True    Should Contain    ${resp.content}    ${mac_addr}
    ...    ELSE    Should Not Contain    ${resp.content}    ${mac_addr}

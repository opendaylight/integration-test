*** Settings ***
Documentation     Test Suite for elan interface and service recovery
Suite Setup       Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           Collections
Library           String
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/FlowLib.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${REQ_NETWORK}    elansr_net_1
${REQ_SUBNET}     elansr_sub_1
${REQ_SUBNET_CIDR}    85.1.0.0/16
${SECURITY_GROUP}    elansr_sg
${SERVICE-STATUS-CLI}    srm:recover service elan
${INTERFACE-STATUS-CLI}    srm:recover instance elan-interface
${NUM_OF_PORTS_PER_HOST}    2
@{NET_1_VMS}      elansr_net_1_vm_1    elansr_net_1_vm_2
@{NET_2_VMS}      elansr_net_2_vm_3    elansr_net_2_vm_4
@{PORT_LIST}      elansr_net_1_port_1    elansr_net_1_port_2    elansr_net_1_port_3    elansr_net_1_port_4

*** Test Cases ***
To Verify ELAN Service Recovery
    [Documentation]    To Verify Elan Service recovery by deleting and recovering multiple flows
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ELAN_SMAC_TABLE}    True    ${EMPTY}    dl_src=@{PORT_MAC_ADDR}[0]    actions=goto_table:${ELAN_DMACTABLE}
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP2_IP}    ${ELAN_SMAC_TABLE}    True    ${EMPTY}    dl_src=@{PORT_MAC_ADDR}[2]    actions=goto_table:${ELAN_DMACTABLE}
    ${flow_id} =    FlowLib.Get Flow Id    ${DPNID_1}    ${ELAN_SMAC_TABLE}    @{PORT_MAC_ADDR}[0]
    FlowLib.Delete Flow Via Restconf    ${DPNID_1}    ${ELAN_SMAC_TABLE}    ${flow_id}
    ${flow_id} =    FlowLib.Get Flow Id    ${DPNID_2}    ${ELAN_SMAC_TABLE}    @{PORT_MAC_ADDR}[2]
    FlowLib.Delete Flow Via Restconf    ${DPNID_2}    ${ELAN_SMAC_TABLE}    ${flow_id}
    ${mac_elements} =    BuiltIn.Create List    @{PORT_MAC_ADDR}[0]
    Utils.Check For Elements Not At URI    ${CONFIG_NODES_API}/node/openflow:${DPNID_1}/table/${ELAN_SMAC_TABLE}    ${mac_elements}
    ${mac_elements} =    BuiltIn.Create List    @{PORT_MAC_ADDR}[2]
    Utils.Check For Elements Not At URI    ${CONFIG_NODES_API}/node/openflow:${DPNID_2}/table/${ELAN_SMAC_TABLE}    ${mac_elements}
    BuiltIn.Wait Until Keyword Succeeds    10s    5s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ELAN_SMAC_TABLE}    False
    ...    ${EMPTY}    dl_src=@{PORT_MAC_ADDR}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    5s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP2_IP}    ${ELAN_SMAC_TABLE}    False
    ...    ${EMPTY}    dl_src=@{PORT_MAC_ADDR}[2]
    KarafKeywords.Issue Command On Karaf Console    ${SERVICE-STATUS-CLI}
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ELAN_SMAC_TABLE}    True    ${EMPTY}    dl_src=@{PORT_MAC_ADDR}[0]    actions=goto_table:${ELAN_DMACTABLE}
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP2_IP}    ${ELAN_SMAC_TABLE}    True    ${EMPTY}    dl_src=@{PORT_MAC_ADDR}[2]    actions=goto_table:${ELAN_DMACTABLE}
    ${mac_elements} =    BuiltIn.Create List    @{PORT_MAC_ADDR}[0]
    Utils.Check For Elements At URI    ${CONFIG_NODES_API}/node/openflow:${DPNID_1}/table/${ELAN_SMAC_TABLE}    ${mac_elements}
    ${mac_elements} =    BuiltIn.Create List    @{PORT_MAC_ADDR}[2]
    Utils.Check For Elements At URI    ${CONFIG_NODES_API}/node/openflow:${DPNID_2}/table/${ELAN_SMAC_TABLE}    ${mac_elements}

To Verify Elan Interface recovery
    [Documentation]    To Verify the Elan Interface recovery by deleting single Flow
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ELAN_SMAC_TABLE}    True
    ...    ${EMPTY}    dl_src=@{PORT_MAC_ADDR}[0]    actions=goto_table:${ELAN_DMACTABLE}
    ${flow_id} =    FlowLib.Get Flow Id    ${DPNID_1}    ${ELAN_SMAC_TABLE}    @{PORT_MAC_ADDR}[0]
    FlowLib.Delete Flow Via Restconf    ${DPNID_1}    ${ELAN_SMAC_TABLE}    ${flow_id}
    ${mac_elements} =    BuiltIn.Create List    @{PORT_MAC_ADDR}[0]
    Utils.Check For Elements Not At URI    ${CONFIG_NODES_API}/node/openflow:${DPNID_1}/table/${ELAN_SMAC_TABLE}    ${mac_elements}
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ELAN_SMAC_TABLE}    False
    ...    ${EMPTY}    dl_src=@{PORT_MAC_ADDR}[0]
    ${elan_instance_id} =    Get Elan Instance ID
    ${elan_interface_id} =    Get Elan Interfaces ID    ${elan_instance_id}    @{PORT_MAC_ADDR}[0]
    Recover Elan Flows    ${elan_interface_id}
    ${mac_elements} =    BuiltIn.Create List    @{PORT_MAC_ADDR}[0]
    BuiltIn.Wait Until Keyword Succeeds    10s    5s    Utils.Check For Elements At URI    ${CONFIG_NODES_API}/node/openflow:${DPNID_1}/table/${ELAN_SMAC_TABLE}    ${mac_elements}
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ELAN_SMAC_TABLE}    True    ${EMPTY}    dl_src=@{PORT_MAC_ADDR}[0]    actions=goto_table:${ELAN_DMACTABLE}

*** Keywords ***
Suite Setup
    [Documentation]    Test Suite for Elan interface and service recovery
    OpenStackOperations.OpenStack Suite Setup
    Create Setup
    OpenStackOperations.Show Debugs    @{NET_1_VMS}    @{NET_2_VMS}
    OpenStackOperations.Get Suite Debugs

Create Neutron Ports
    [Documentation]    Create required number of ports under previously created subnets
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_PORTS_PER_HOST}
    \    OpenStackOperations.Create Port    ${REQ_NETWORK}    @{PORT_LIST}[${index}]    sg=${SECURITY_GROUP}
    \    OpenStackOperations.Create Port    ${REQ_NETWORK}    @{PORT_LIST}[${index + 2}]    sg=${SECURITY_GROUP}
    @{PORT_MAC_ADDR} =    OpenStackOperations.Get Ports MacAddr    ${PORT_LIST}
    BuiltIn.Set Suite Variable    @{PORT_MAC_ADDR}

Create Nova VMs
    [Arguments]    ${num_of_vms_per_dpn}
    [Documentation]    Create Vm instances on compute nodes
    : FOR    ${index}    IN RANGE    0    ${num_of_vms_per_dpn}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORT_LIST}[${index}]    @{NET_1_VMS}[${index}]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORT_LIST}[${index + 2}]    @{NET_2_VMS}[${index}]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    @{NET_2_VM_IPS}    ${NET_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    BuiltIn.Should Not Contain    ${NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IP}    None

Create Setup
    [Documentation]    Create basic topology
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    VpnOperations.Verify Tunnel Status as UP
    OpenStackOperations.Create Network    ${REQ_NETWORK}
    OpenStackOperations.Create SubNet    ${REQ_NETWORK}    ${REQ_SUBNET}    ${REQ_SUBNET_CIDR}
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    Create Neutron Ports
    Create Nova VMs    ${2}
    ${DPNID_1} =    OVSDB.Get DPID    ${OS_CMP1_IP}
    ${DPNID_2} =    OVSDB.Get DPID    ${OS_CMP2_IP}
    BuiltIn.Set Suite Variable    ${DPNID_1}
    BuiltIn.Set Suite Variable    ${DPNID_2}

Get Elan Instance ID
    [Documentation]    Retrieving ELAN instance ID
    ${output} =    KarafKeywords.Issue Command On Karaf Console    elaninterface:show
    ${elan_instance} =    String.Split String    ${output}
    ${elan_instance_with_tag} =    BuiltIn.Set Variable    ${elan_instance[5]}
    ${elan_instance_id} =    String.Split String    ${elan_instance_with_tag}    /
    [Return]    @{elan_instance_id}[0]

Get Elan Interfaces ID
    [Arguments]    ${elan_id}    ${mac}
    [Documentation]    Getting the ELAN interface ID with corresponding mac address and returning interface ID list
    ${elan_output} =    KarafKeywords.Issue Command On Karaf Console    elanmactable:show ${elan_id}
    ${interface_id} =    String.Get Regexp Matches    ${elan_output}    (${REGEX_UUID})\\s*${mac}    1
    [Return]    @{interface_id}[0]

Recover Elan Flows
    [Arguments]    ${interface}
    [Documentation]    Recover ELAN flows for the given interfaces
    ${recover_msg} =    KarafKeywords.Issue Command On Karaf Console    ${INTERFACE-STATUS-CLI} ${interface}
    BuiltIn.Should Contain    ${recover_msg}    RPC call to recover was successful

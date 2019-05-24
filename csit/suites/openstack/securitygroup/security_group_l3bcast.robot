*** Settings ***
Documentation     Test Suite for Network and Subnet Broadcast with security group
Suite Setup       Start Suite
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           String
Library           RequestsLibrary
Library           SSHLibrary
Library           Collections
Library           json
Library           OperatingSystem
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/OvsManager.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
@{SECURITY_GROUP}    sgbcast1    sgbcast2
@{NETWORKS}       sgbcast_net_1    sgbcast_net_2
@{SUBNETS}        sgbcast_sub_1    sgbcast_sub_2
@{SUBNET_CIDRS}    55.0.0.0/24    56.0.0.0/24
${ROUTER}         sgbcast_router
@{NET_1_PORTS}    sgbcast_net_1_port_1    sgbcast_net_1_port_2    sgbcast_net_1_port_3
@{NET_2_PORTS}    sgbcast_net_2_port_1    sgbcast_net_2_port_2
@{NET_1_VMS}      sgbcast_net_1_vm_1    sgbcast_net_1_vm_2    sgbcast_net_1_vm_3
@{NET_2_VMS}      sgbcast_net_2_vm_1    sgbcast_net_2_vm_2
${DUMP_FLOW}      sudo ovs-ofctl dump-flows br-int -OOpenflow13
${DUMP_PORT_DESC}    sudo ovs-ofctl dump-ports-desc br-int -OOpenflow13
${PACKET_COUNT}    5
${BCAST_IP}       255.255.255.255
${SUBNET1_BCAST_IP}    55.0.0.255
${SUBNET2_BCAST_IP}    56.0.0.255
${ENABLE_BCAST}    echo 0 | sudo tee /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts

*** Test case ***
Verify Network Broadcast traffic between the VMs hosted in Single Network
    [Documentation]    This TC is to verify Network Broadcast traffic between the VMs hosted in Same Network on same/different compute node
    ${pkt_check} =    BuiltIn.Set Variable If    "${OPENSTACK_TOPO}" == "1cmb-0ctl-0cmp"    10    5
    Wait Until Keyword Succeeds    30s    5s    Verify L3Broadcast With Antispoofing Table    ${OS_CMP1_IP}    ${EGRESS_ACL_TABLE}    ${BCAST_IP}
    ...    @{VM_IPS}[0]    same    pingsuccess    pkt_check=${pkt_check}

Verify Network Broadcast traffic between the VMs hosted in Multi Network
    [Documentation]    This TC is to verify Network Broadcast traffic between the VMs hosted in Different Network on same/different compute node.
    ${pkt_check} =    BuiltIn.Set Variable If    "${OPENSTACK_TOPO}" == "1cmb-0ctl-0cmp"    5    0
    Wait Until Keyword Succeeds    30s    5s    Verify L3Broadcast With Antispoofing Table    ${OS_CMP1_IP}    ${EGRESS_ACL_TABLE}    ${BCAST_IP}
    ...    @{VM_IPS}[3]    different    pingsuccess    pkt_check=${pkt_check}

Verify Subnet Broadcast traffic between the VMs hosted on same compute node in Single Network
    [Documentation]    Verify L3-Subnet Broadcast traffic between the VMs hosted on same compute node in Single Network
    Wait Until Keyword Succeeds    30s    5s    Verify L3Broadcast With Antispoofing Table    ${OS_CMP1_IP}    ${EGRESS_ACL_TABLE}    ${SUBNET1_BCAST_IP}
    ...    @{VM_IPS}[0]    same    pingsuccess    ${VM2_SUBMETA}    pkt_check=5    additional_args=| grep ${VM2_SUBMETA}

Verify Subnet Broadcast traffic between the VMs hosted on Different compute node in Single Network
    [Documentation]    Verify L3-Subnet Broadcast traffic between the VMs hosted on same compute node in Single Network
    Wait Until Keyword Succeeds    30s    5s    Verify L3Broadcast With Antispoofing Table    ${OS_CMP2_IP}    ${EGRESS_ACL_TABLE}    ${SUBNET1_BCAST_IP}
    ...    @{VM_IPS}[0]    same    pingsuccess    ${VM3_SUBMETA}    pkt_check=5    additional_args=| grep ${VM3_SUBMETA}

Verify Subnet Broadcast traffic between the VMs hosted on same compute node in Multi Network
    [Documentation]    Verify L3-Subnet Broadcast traffic between the VMs hosted on same compute node in Multi Network
    Wait Until Keyword Succeeds    30s    5s    Verify L3Broadcast With Antispoofing Table    ${OS_CMP1_IP}    ${EGRESS_ACL_TABLE}    ${SUBNET2_BCAST_IP}
    ...    @{VM_IPS}[0]    different    nosuccess    ${VM4_SUBMETA}    pkt_check=0    additional_args=| grep ${VM4_SUBMETA}

Verify Subnet Broadcast traffic between the VMs hosted on Different compute node in Multi Network
    [Documentation]    Verify L3-Subnet Broadcast traffic between the VMs hosted on Different compute node in Multi Network
    Wait Until Keyword Succeeds    30s    5s    Verify L3Broadcast With Antispoofing Table    ${OS_CMP2_IP}    ${EGRESS_ACL_TABLE}    ${SUBNET2_BCAST_IP}
    ...    @{VM_IPS}[0]    different    nosuccess    ${VM5_SUBMETA}    pkt_check=0    additional_args=| grep ${VM5_SUBMETA}

*** Keywords ***
Start Suite
    [Documentation]    Test Suite for Network and Subnet Broadcast with security group
    OpenStackOperations.OpenStack Suite Setup
    Create Setup
    OpenStackOperations.Show Debugs    @{NET_1_VMS}    @{NET_2_VMS}
    OpenStackOperations.Get Suite Debugs

Create Setup
    FOR    ${network}    IN    @{NETWORKS}
        OpenStackOperations.Create Network    ${network}
    END
    FOR    ${i}    IN RANGE    len(${NETWORKS})
        OpenStackOperations.Create SubNet    @{NETWORKS}[${i}]    @{SUBNETS}[${i}]    @{SUBNET_CIDRS}[${i}]
    END
    OpenStackOperations.Create Allow All SecurityGroup    @{SECURITY_GROUP}[0]
    OpenStackOperations.Create Router    ${ROUTER}
    FOR    ${interface}    IN    @{SUBNETS}
        OpenStackOperations.Add Router Interface    ${ROUTER}    ${interface}
    END
    FOR    ${port_net1}    IN    @{NET_1_PORTS}
        OpenStackOperations.Create Port    @{NETWORKS}[0]    ${port_net1}    sg=@{SECURITY_GROUP}[0]
    END
    FOR    ${port_net2}    IN    @{NET_2_PORTS}
        OpenStackOperations.Create Port    @{NETWORKS}[1]    ${port_net2}    sg=@{SECURITY_GROUP}[0]
    END
    @{ports} =    BuiltIn.Create List    @{NET_1_PORTS}[0]    @{NET_1_PORTS}[1]    @{NET_1_PORTS}[2]    @{NET_2_PORTS}[0]    @{NET_2_PORTS}[1]
    @{vms} =    BuiltIn.Create List    @{NET_1_VMS}[0]    @{NET_1_VMS}[1]    @{NET_1_VMS}[2]    @{NET_2_VMS}[0]    @{NET_2_VMS}[1]
    @{nodes} =    BuiltIn.Create List    ${OS_CMP1_HOSTNAME}    ${OS_CMP1_HOSTNAME}    ${OS_CMP2_HOSTNAME}    ${OS_CMP1_HOSTNAME}    ${OS_CMP2_HOSTNAME}
    FOR    ${port}    ${vm}    ${node}    IN ZIP    ${ports}    ${vms}
    ...    ${nodes}
        OpenStackOperations.Create Vm Instance With Port On Compute Node    ${port}    ${vm}    ${node}    sg=@{SECURITY_GROUP}[0]
    END
    @{vms} =    Collections.Combine Lists    ${NET_1_VMS}    ${NET_2_VMS}
    @{VM_IPS} =    OpenStackOperations.Get VM IPs    @{vms}
    BuiltIn.Should Not Contain    ${VM_IPS}    None
    BuiltIn.Set Suite Variable    @{VM_IPS}
    OpenStackOperations.Execute Command on VM Instance    ${NETWORKS[0]}    @{VM_IPS}[0]    ${ENABLE_BCAST}
    OpenStackOperations.Execute Command on VM Instance    ${NETWORKS[1]}    @{VM_IPS}[3]    ${ENABLE_BCAST}
    ${vm1_in_port}    ${vm1_meta} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Get VMs Metadata and In Port    @{NET_1_PORTS}[0]
    ...    ${OS_CMP1_IP}
    ${vm2_in_port}    ${vm2_meta} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Get VMs Metadata and In Port    @{NET_1_PORTS}[1]
    ...    ${OS_CMP1_IP}
    ${vm3_in_port}    ${vm3_meta} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Get VMs Metadata and In Port    @{NET_1_PORTS}[2]
    ...    ${OS_CMP2_IP}
    ${vm4_in_port}    ${vm4_meta} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Get VMs Metadata and In Port    @{NET_2_PORTS}[0]
    ...    ${OS_CMP1_IP}
    ${vm5_in_port}    ${vm5_meta} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Get VMs Metadata and In Port    @{NET_2_PORTS}[1]
    ...    ${OS_CMP2_IP}
    ${VM1_SUBMETA} =    Get Submetadata    ${vm1_meta}
    ${VM2_SUBMETA} =    Get Submetadata    ${vm2_meta}
    ${VM3_SUBMETA} =    Get Submetadata    ${vm3_meta}
    ${VM4_SUBMETA} =    Get Submetadata    ${vm4_meta}
    ${VM5_SUBMETA} =    Get Submetadata    ${vm5_meta}
    BuiltIn.Set Suite Variable    ${VM1_SUBMETA}
    BuiltIn.Set Suite Variable    ${VM2_SUBMETA}
    BuiltIn.Set Suite Variable    ${VM3_SUBMETA}
    BuiltIn.Set Suite Variable    ${VM4_SUBMETA}
    BuiltIn.Set Suite Variable    ${VM5_SUBMETA}

Get VMs Metadata and In Port
    [Arguments]    ${portname}    ${OS_COMPUTE_IP}
    [Documentation]    This keyword is to get the VM metadata and the in_port Id of the VM
    ${subport} =    OpenStackOperations.Get Sub Port Id    ${portname}
    ${get_vm_in_port} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_IP}    ${DUMP_PORT_DESC} | grep ${subport} | awk '{print$1}'
    ${vms_in_port} =    BuiltIn.Should Match Regexp    ${get_vm_in_port}    [0-9]+
    ${grep_metadata} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_IP}    ${DUMP_FLOW} | grep table=${VLAN_INTERFACE_INGRESS_TABLE} | grep in_port=${vms_in_port} | awk '{print$7}'
    @{metadata} =    String.Split string    ${grep_metadata}    ,
    ${get_write_metadata} =    Collections.get from list    ${metadata}    0
    @{complete_metadata} =    String.Split string    ${get_write_metadata}    :
    ${extract_metadata} =    Collections.get from list    ${complete_metadata}    1
    @{split_metadata} =    String.Split string    ${extract_metadata}    /
    ${vm_metadata} =    Collections.Get From List    ${split_metadata}    0
    [Return]    ${vms_in_port}    ${vm_metadata}

Get Submetadata
    [Arguments]    ${vm_metadata}
    [Documentation]    Get the submetadata of the VM
    ${cmd1} =    Utils.Run Command On Remote System And Log    ${OS_CMP1_IP}    ${DUMP_FLOW} | grep ${EGRESS_LPORT_DISPATCHER_TABLE} | grep write_metadata:
    ${output1} =    String.Get Regexp Matches    ${cmd1}    reg6=(\\w+)    1
    ${cmd2} =    Utils.Run Command On Remote System And Log    ${OS_CMP2_IP}    ${DUMP_FLOW} | grep ${EGRESS_LPORT_DISPATCHER_TABLE} | grep write_metadata:
    ${output2} =    String.Get Regexp Matches    ${cmd2}    reg6=(\\w+)    1
    ${metalist} =    Collections.Combine Lists    ${output1}    ${output2}
    FOR    ${meta}    IN    @{metalist}
        ${metadata_check_status} =    Run Keyword And Return Status    should contain    ${vm_metadata}    ${meta}
        Return From Keyword if    ${metadata_check_status} == True    ${meta}
    END

Verify L3Broadcast With Antispoofing Table
    [Arguments]    ${OS_COMPUTE_IP}    ${EGRESS_ACL_TABLE}    ${BCAST_IP}    ${vm_ip}    ${subnet_var}    ${ping_response}='pingsuccess'
    ...    ${vm_submeta}=''    ${pkt_check}=0    ${additional_args}=${EMPTY}
    [Documentation]    Verify the l3 broadcast requests are hitting to antispoofing table in same subnet
    ${get_pkt_count_before_bcast} =    OvsManager.Get Packet Count In Table For IP    ${OS_COMPUTE_IP}    ${EGRESS_ACL_TABLE}    ${BCAST_IP}    additional_args=| grep ${vm_submeta}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${vm_ip}    ping -c ${PACKET_COUNT} ${BCAST_IP}
    BuiltIn.Run Keyword If    '${ping_response}'=='pingsuccess'    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ...    ELSE    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_IP}    ${DUMP_FLOW} | grep table=${EGRESS_ACL_TABLE} | grep ${BCAST_IP} ${additional_args}
    ${get_pkt_count_after_bcast} =    OvsManager.Get Packet Count In Table For IP    ${OS_COMPUTE_IP}    ${EGRESS_ACL_TABLE}    ${BCAST_IP}    additional_args=| grep ${vm_submeta}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    BuiltIn.Should Be Equal As Numbers    ${pkt_diff}    ${pkt_check}

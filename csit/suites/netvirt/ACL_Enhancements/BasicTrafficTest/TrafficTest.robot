*** Settings ***
Documentation     Test suite to validate Basic Traffic for ICMP, TCP and UDP traffic.

Suite Setup       Create Setup
Suite Teardown    Openstack Suite Teardown
Test Setup
Test Teardown     
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Library           BuiltIn
Resource          ../../../../libraries/KarafKeywords.robot
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/OVSDB.robot
Resource          ../../../../libraries/OpenStackOperations.robot
Resource          ../../../../libraries/DevstackUtils.robot
Resource          ../../../../libraries/SetupUtils.robot
Resource          ../../../../variables/Variables.robot
#Resource          ../../../../variables/netvirt/Variables_ACL.robot
Resource          ../../../../variables/netvirt/Variables.robot

*** Variables ***
${NUM_OF_NETWORK}   2
${Req_no_of_net}    2
${Req_no_of_subNet}    2
${Req_no_of_ports}    2
${Req_no_of_vms_per_dpn}    2
#${OS_CONTROL_NODE_IP}    192.168.56.100
@{DPN1_PORT_LIST}    port_1    port_2    port_5
@{DPN2_PORT_LIST}    port_7    port_8    port_3
@{egress_table_list}    table=17    table=210    goto_table:211
@{igress_table_list}    table=220
@{DPN1_VM_NAMES}    NET1_VM1    NET1_VM2
@{DPN2_VM_NAMES}    NET2_VM7    NET2_VM8
@{SECURITY_GROUP}    SG1    SG2    SG3
@{REQ_NETWORKS}    NET1    NET2
@{REQ_SUBNETS}    SUBNET1    SUBNET2
${ROUTER}    R1
@{REQ_SUBNET_CIDR}    30.30.30.0/24    40.40.40.0/24
${NUM_OF_VMS_PER_DPN}    2
${br_name}    br-int
${No_Port}    No Port found
${Invalid_Aap}    not a valid IP address
${DEVSTACK_DEPLOY_PATH}    /opt/stack/devstack
${openrc}         source openrc admin admin
${AAP_VM}    NET1_VM5 
@{AAP_VMS}    AAPVM1    AAPVM2
${INVALID_AAP_VM}    INVALIDAAPVM
@{AAP_PARAMS}    50.50.50.10    01:00:5e:00:00:12    60.60.60.10

*** Test Cases ***
Verify ICMP traffic in same subnet and different subnet across DPNs with default security group
    [Documentation]    Verify ICMP traffic in same subnet and different subnet across DPNs with default security group
    Log    Suite testing
    Sleep    180s
    ${VM1_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}    ${DPN1_VM_NAMES[0]}
    ${VM2_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}    ${DPN1_VM_NAMES[1]}
    ${VM7_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP2_CONN_ID}    ${DPN2_VM_NAMES[0]}
    ${VM1_Port}    In Port VM    ${OS_CMP1_CONN_ID}    ${br_name}    ${DPN1_PORT_LIST[0]}
    ${VM2_Port}    In Port VM    ${OS_CMP1_CONN_ID}    ${br_name}    ${DPN1_PORT_LIST[1]}
    ${VM7_Port}    In Port VM    ${OS_CMP2_CONN_ID}    ${br_name}    ${DPN2_PORT_LIST[0]}
    Check In Port    ${VM1_Port}   ${OS_CMP1_CONN_ID}
    Check In Port    ${VM2_Port}   ${OS_CMP1_CONN_ID}
    Check In Port    ${VM7_Port}   ${OS_CMP2_CONN_ID}
    ${vm1_metadata}    Get Metadata    ${OS_CMP1_CONN_ID}    ${VM1_Port}
    ${vm2_metadata}    Get Metadata    ${OS_CMP1_CONN_ID}    ${VM2_Port}
    ${vm7_metadata}    Get Metadata    ${OS_CMP2_CONN_ID}    ${VM7_Port}
    Log    >>>>>Data path validation before Ping>>>>>>
    #@{validation}    Create List    ${vm1_metadata}    ${egress_table_list[2]}
    #${pckt_before_ping_egress}    Data Path Validation Egress Dispatcher Table    ${br_name}    ${OS_CMP1_CONN_ID}    ${egress_table_list[0]}   @{validation}
    @{validation}    Create List    ${vm2_metadata}    output:
    ${pckt_before_ping_ingress}    Data Path Validation Ingress Dispatcher Table    ${br_name}    ${OS_CMP1_CONN_ID}    ${igress_table_list[0]}   @{validation}
    Log    >>>>>>Ping from VM1 in DPN1 to VM2 in DPN1 with same subnet>>>>>>
    ${output} =    OpenStackOperations.Execute Command on VM Instance    ${REQ_NETWORKS[0]}    ${VM1_IP}    ping -c 3 ${VM2_IP}
    BuiltIn.Should Contain    ${output}    64 bytes
    Sleep    10s
    Log    >>>>>Data path validation>>>>>>
    #@{validation}    Create List    ${vm1_metadata}    goto_table:210
    #${pckt_after_ping_egress}    Data Path Validation Egress Dispatcher Table    ${br_name}    ${OS_CMP1_CONN_ID}    ${egress_table_list[0]}    @{validation}
    @{validation}    Create List    ${vm2_metadata}    output:
    ${pckt_after_ping_ingress}    Data Path Validation Ingress Dispatcher Table    ${br_name}    ${OS_CMP1_CONN_ID}    ${igress_table_list[0]}   @{validation}
    #${pkt_cnt_diff_egress}    Evaluate    ${pckt_after_ping_egress}-${pckt_before_ping_egress}
    #Should Be True    ${pkt_cnt_diff_egress}==0
    ${pkt_cnt_diff_ingress}    Evaluate    ${pckt_after_ping_ingress}-${pckt_before_ping_ingress}
    Should Be True    ${pkt_cnt_diff_ingress}==0
    Log    >>>>>>Ping from VM1 in DPN1 to VM7 in DPN2 with different subnet>>>>>>
    ${output} =    OpenStackOperations.Execute Command on VM Instance    ${REQ_NETWORKS[0]}    ${VM1_IP}    ping -c 3 ${VM7_IP}
    BuiltIn.Should Contain    ${output}    64 bytes

Verify TCP traffic in same subnet and different subnet across DPNs with default security group
    [Documentation]    Verify TCP traffic in same subnet and different subnet across DPNs with default security group
    Log    Suite testing
    Log    >>>>>>Test TCP traffic>>>>>>>>>
    ${VM1_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}    ${DPN1_VM_NAMES[0]}
    ${VM2_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}    ${DPN1_VM_NAMES[1]}
    ${VM7_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP2_CONN_ID}    ${DPN2_VM_NAMES[0]}
    ${VM1_Port}    In Port VM    ${OS_CMP1_CONN_ID}    ${br_name}    ${DPN1_PORT_LIST[0]}
    ${VM2_Port}    In Port VM    ${OS_CMP1_CONN_ID}    ${br_name}    ${DPN1_PORT_LIST[1]}
    ${VM7_Port}    In Port VM    ${OS_CMP2_CONN_ID}    ${br_name}    ${DPN2_PORT_LIST[0]}
    Check In Port    ${VM1_Port}   ${OS_CMP1_CONN_ID}
    Check In Port    ${VM2_Port}   ${OS_CMP1_CONN_ID}
    Check In Port    ${VM7_Port}   ${OS_CMP2_CONN_ID}
    ${vm1_metadata}    Get Metadata    ${OS_CMP1_CONN_ID}    ${VM1_Port}
    ${vm2_metadata}    Get Metadata    ${OS_CMP1_CONN_ID}    ${VM2_Port}
    ${vm7_metadata}    Get Metadata    ${OS_CMP2_CONN_ID}    ${VM7_Port}
    Log    >>>>>>Test TCP traffic between VM1 in DPN1 to VM2 in DPN1 with same subnet>>>>>>
    Log    >>>>>Data path validation before TCP traffic>>>>>>
    @{validation}    Create List    ${vm1_metadata}    goto_table:210
    ${pckt_before_tcp_egress}    Data Path Validation Egress Dispatcher Table    ${br_name}    ${OS_CMP1_CONN_ID}    ${egress_table_list[0]}    @{validation}
    @{validation}    Create List    ${vm2_metadata}    output:
    ${pckt_before_tcp_ingress}    Data Path Validation Ingress Dispatcher Table    ${br_name}    ${OS_CMP1_CONN_ID}    ${igress_table_list[0]}   @{validation} 
    Verify TCP/UDP Traffic Using Netcat    ${REQ_NETWORKS[0]}    ${REQ_NETWORKS[0]}    ${VM1_IP}    ${VM2_IP}    12345    Hello    tcp
    Sleep    5s
    Log    >>>>>Data path validation after TCP traffic>>>>>>
    @{validation}    Create List    ${vm1_metadata}    goto_table:210
    ${pckt_after_tcp_egress}    Data Path Validation Egress Dispatcher Table    ${br_name}    ${OS_CMP1_CONN_ID}    ${egress_table_list[0]}    @{validation}
    @{validation}    Create List    ${vm2_metadata}    output:
    ${pckt_after_tcp_ingress}    Data Path Validation Ingress Dispatcher Table    ${br_name}    ${OS_CMP1_CONN_ID}    ${igress_table_list[0]}   @{validation}
    ${pkt_cnt_diff_egress}    Evaluate    ${pckt_after_tcp_egress}-${pckt_before_tcp_egress}
    Should Be True    ${pkt_cnt_diff_egress}==0
    ${pkt_cnt_diff_ingress}    Evaluate    ${pckt_after_tcp_ingress}-${pckt_before_tcp_ingress}
    Should Be True    ${pkt_cnt_diff_ingress}==0
    Log    >>>>>>Test TCP traffic between VM1 in DPN1 to VM7 in DPN2 with diff subnet>>>>>>
    Verify TCP/UDP Traffic Using Netcat    ${REQ_NETWORKS[0]}    ${REQ_NETWORKS[1]}    ${VM1_IP}    ${VM7_IP}    12345    Hello    tcp
    

Verify UDP traffic in same subnet and different subnet across DPNs with default security group
    [Documentation]    Verify UDP traffic in same subnet and different subnet across DPNs with default security group
    Log    Suite testing
    Log    >>>>>>Test TCP traffic>>>>>>>>>
    ${VM1_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}    ${DPN1_VM_NAMES[0]}
    ${VM2_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}    ${DPN1_VM_NAMES[1]}
    ${VM7_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP2_CONN_ID}    ${DPN2_VM_NAMES[0]}
    ${VM1_Port}    In Port VM    ${OS_CMP1_CONN_ID}    ${br_name}    ${DPN1_PORT_LIST[0]}
    ${VM2_Port}    In Port VM    ${OS_CMP1_CONN_ID}    ${br_name}    ${DPN1_PORT_LIST[1]}
    ${VM7_Port}    In Port VM    ${OS_CMP2_CONN_ID}    ${br_name}    ${DPN2_PORT_LIST[0]}
    Check In Port    ${VM1_Port}   ${OS_CMP1_CONN_ID}
    Check In Port    ${VM2_Port}   ${OS_CMP1_CONN_ID}
    Check In Port    ${VM7_Port}   ${OS_CMP2_CONN_ID}
    ${vm1_metadata}    Get Metadata    ${OS_CMP1_CONN_ID}    ${VM1_Port}
    ${vm2_metadata}    Get Metadata    ${OS_CMP1_CONN_ID}    ${VM2_Port}
    ${vm7_metadata}    Get Metadata    ${OS_CMP2_CONN_ID}    ${VM7_Port}
    Log    >>>>>Data path validation before UDP traffic>>>>>>
    @{validation}    Create List    ${vm1_metadata}    goto_table:210
    ${pckt_before_udp_egress}    Data Path Validation Egress Dispatcher Table    ${br_name}    ${OS_CMP1_CONN_ID}    ${egress_table_list[0]}    @{validation}
    @{validation}    Create List    ${vm2_metadata}    output:
    ${pckt_before_udp_ingress}    Data Path Validation Ingress Dispatcher Table    ${br_name}    ${OS_CMP1_CONN_ID}    ${igress_table_list[0]}   @{validation}
    Log    >>>>>>Test UDP traffic between VM1 in DPN1 to VM2 in DPN1 with same subnet>>>>>>
    Verify TCP/UDP Traffic Using Netcat    ${REQ_NETWORKS[0]}    ${REQ_NETWORKS[0]}    ${VM1_IP}    ${VM2_IP}    12345    Hello
    Log    >>>>>Data path validation after UDP traffic>>>>>>
    sleep    5s
    @{validation}    Create List    ${vm1_metadata}    goto_table:210
    ${pckt_after_udp_egress}    Data Path Validation Egress Dispatcher Table    ${br_name}    ${OS_CMP1_CONN_ID}    ${egress_table_list[0]}    @{validation}
    @{validation}    Create List    ${vm2_metadata}    output:
    ${pckt_after_udp_ingress}    Data Path Validation Ingress Dispatcher Table    ${br_name}    ${OS_CMP1_CONN_ID}    ${igress_table_list[0]}   @{validation}
    ${pkt_cnt_diff_egress}    Evaluate    ${pckt_after_udp_egress}-${pckt_before_udp_egress}
    Should Be True    ${pkt_cnt_diff_egress}==0
    ${pkt_cnt_diff_ingress}    Evaluate    ${pckt_after_udp_ingress}-${pckt_before_udp_ingress}
    Should Be True    ${pkt_cnt_diff_ingress}==0
    Log    >>>>>>Test UDP traffic between VM1 in DPN1 to VM7 in DPN2 with diff subnet>>>>>>
    Verify TCP/UDP Traffic Using Netcat    ${REQ_NETWORKS[0]}    ${REQ_NETWORKS[1]}    ${VM1_IP}    ${VM7_IP}    12345    Hello
    

*** Keywords ***
Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports And Four VMs on each DPN
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DevstackUtils.Devstack Suite Setup
    Log    Create tunnels between the 2 compute nodes
    ${devstack_conn_id}    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    Create Neutron Networks
    Create Neutron Subnets
    OpenStackOperations.Create Router       ${ROUTER}
    : FOR    ${interface}    IN    @{REQ_SUBNETS}
    \    OpenStackOperations.Add Router Interface    ${ROUTER}    ${interface}
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP[0]}
    Create Neutron Ports    ${Req_no_of_ports}
    Create Nova VMs    ${Req_no_of_vms_per_dpn}
    OpenStackOperations.Neutron Security Group Create    ${SECURITY_GROUP[1]}
    Security Group Rule with Remote SG    ${SECURITY_GROUP[1]}
    OpenStackOperations.Neutron Security Group Create    ${SECURITY_GROUP[2]}
    Security Group Rule with Remote Prefix    ${SECURITY_GROUP[2]}

Security Group Rule with Remote Prefix
    [Arguments]    ${SEC_GRP}
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    Neutron Security Group Rule Create    ${SEC_GRP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SEC_GRP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SEC_GRP}    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SEC_GRP}    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SEC_GRP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SEC_GRP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0

Security Group Rule with Remote SG
    [Arguments]    ${SEC_GRP}
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    Neutron Security Group Rule Create    ${SEC_GRP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote-group-id=${SEC_GRP}
    Neutron Security Group Rule Create    ${SEC_GRP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote-group-id=${SEC_GRP}
    Neutron Security Group Rule Create    ${SEC_GRP}    direction=ingress    protocol=icmp    remote-group-id=${SEC_GRP}
    Neutron Security Group Rule Create    ${SEC_GRP}    direction=egress    protocol=icmp    remote-group-id=${SEC_GRP}
    Neutron Security Group Rule Create    ${SEC_GRP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_group_id=${SEC_GRP}
    Neutron Security Group Rule Create    ${SEC_GRP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote-group-id=${SEC_GRP}


Create Neutron Networks
    [Documentation]    Create required number of networks
    Create Network    ${REQ_NETWORKS[0]}
    ${NET_LIST}    List Networks
    Should Contain    ${NET_LIST}    ${REQ_NETWORKS[0]}
    Create Network    ${REQ_NETWORKS[1]}
    ${NET_LIST}    List Networks
    Should Contain    ${NET_LIST}    ${REQ_NETWORKS[1]}

Create Neutron Subnets
    [Documentation]    Create required number of subnets for previously created networks
    Create SubNet    ${REQ_NETWORKS[0]}    ${REQ_SUBNETS[0]}    ${REQ_SUBNET_CIDR[0]}
    ${SUB_LIST}    List Subnets
    Should Contain    ${SUB_LIST}    ${REQ_SUBNETS[0]}
    Create SubNet    ${REQ_NETWORKS[1]}    ${REQ_SUBNETS[1]}    ${REQ_SUBNET_CIDR[1]}
    ${SUB_LIST}    List Subnets
    Should Contain    ${SUB_LIST}    ${REQ_SUBNETS[1]}

Get Security Group Id
    [Arguments]    ${SEC_GRP}    ${conn_id}
    [Documentation]    Get Security Group id
    Switch Connection    ${conn_id}
    ${cmd}    Set Variable    openstack security group list | grep "${SEC_GRP}" | awk '{print $2}'
    ${output}    OpenStack CLI    ${cmd}
    Log    ${output}
    ${splitted_output}    Split String    ${output}    ${EMPTY}
    ${sg_id}    Get from List    ${splitted_output}    0
    Log    ${sg_id}
    [Return]    ${sg_id}
    

Create Neutron Ports
    [Arguments]    ${NUM_OF_PORTS}
    [Documentation]    Create required number of ports under previously created subnets
    :FOR    ${index}    IN RANGE    0    ${NUM_OF_PORTS}
    \    Create Port    ${REQ_NETWORKS[0]}    ${DPN1_PORT_LIST[${index}]}    ${SECURITY_GROUP[0]}
    :FOR    ${index}    IN RANGE    0    ${NUM_OF_PORTS}
    \    Create Port    ${REQ_NETWORKS[1]}    ${DPN2_PORT_LIST[${index}]}    ${SECURITY_GROUP[0]}

Create Nova VMs
    [Arguments]    ${NUM_OF_VMS_PER_DPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create Vm instances on compute nodes
    Create Vm Instance With Port On Compute Node    ${DPN1_PORT_LIST[0]}    ${DPN1_VM_NAMES[0]}    ${OS_CMP1_HOSTNAME}    flavor=m1.tiny    sg=${SECURITY_GROUP[0]}
    Create Vm Instance With Port On Compute Node    ${DPN1_PORT_LIST[1]}    ${DPN1_VM_NAMES[1]}    ${OS_CMP1_HOSTNAME}    flavor=m1.tiny    sg=${SECURITY_GROUP[0]}
    Create Vm Instance With Port On Compute Node    ${DPN2_PORT_LIST[1]}    ${DPN2_VM_NAMES[1]}    ${OS_CMP2_HOSTNAME}    flavor=m1.tiny    sg=${SECURITY_GROUP[0]}
    Create Vm Instance With Port On Compute Node    ${DPN2_PORT_LIST[0]}    ${DPN2_VM_NAMES[0]}    ${OS_CMP2_HOSTNAME}    flavor=m1.tiny    sg=${SECURITY_GROUP[0]}
    List Nova VMs
    : FOR    ${VM}    IN    @{DPN1_VM_NAMES}
    \    Wait Until Keyword Succeeds    60s    10s    Verify VM Is ACTIVE    ${VM}
    : FOR    ${VM}    IN    @{DPN2_VM_NAMES}
    \    Wait Until Keyword Succeeds    60s    10s    Verify VM Is ACTIVE    ${VM}


Alllowed Adress Pair Config
    [Arguments]    ${NUM_OF_PORTS}
    [Documentation]    Update Port with AAP
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_PORTS}
    \    ${port-id}    Get Port Id    ${PORT_LIST[${index}]}    ${OS_CMP1_CONN_ID}
    \    Update Port    ${port-id}    --allowed-address-pair ip_address=224.0.0.5 mac_address=01:00:5e:00:00:05

Get Port Id
    [Arguments]    ${port_name}    ${conn_id}
    [Documentation]    Retrieve the port id for the given port name to attach specific vm instance to a particular port
    Switch Connection    ${conn_id}
    ${cmd}    Set Variable    openstack port list | grep "${port_name}" | awk '{print $2}'
    ${output}    OpenStack CLI    ${cmd}
    Log    ${output}
    ${splitted_output}    Split String    ${output}    ${EMPTY}
    ${port_id}    Get from List    ${splitted_output}    0
    Log    ${port_id}
    [Return]    ${port_id}

Get Sub Port Id
    [Arguments]    ${portname}    ${conn_id}
    [Documentation]    Get the Sub Port ID
    ${port_id}    Get Port Id    ${portname}    ${conn_id}
    Should Match Regexp    ${port_id}    \\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}
    @{output}    Get Regexp Matches    ${port_id}    (\\w{8}-\\w{2})
    [Return]    ${output[0]}

Get Port Number
    [Arguments]    ${connec_id}    ${br_name}    ${portname}
    [Documentation]    Get the port number for given portname
    SSHLibrary.Switch Connection    ${connec_id}
    ${pnum}    Get Sub Port Id    ${portname}    ${connec_id}
    ${command_1}    Set Variable    sudo ovs-ofctl -O OpenFlow13 show ${br_name} | grep ${pnum} | awk '{print$1}'
    log    sudo ovs-ofctl -O OpenFlow13 show ${br_name} | grep ${pnum} | awk '{print$1}'
    ${num}    DevstackUtils.Write Commands Until Prompt    ${command_1}    30
    log    ${num}
    ${port_number}    Should Match Regexp    ${num}    [0-9]+
    log    ${port_number}
    [Return]    ${port_number}

In Port VM
    [Arguments]    ${conn_id}    ${br_name}    ${portname}
    [Documentation]    Get the port number for given portname
    ${VM_Port}    Get Port Number    ${conn_id}    ${br_name}    ${portname}
    [Return]    ${VM_port}

Check In Port
    [Arguments]    ${port}    ${conn_id}
    [Documentation]    Check the port present in table 0
    SSHLibrary.Switch Connection    ${conn_id}
    ${cmd}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep table=0
    ${output}    DevstackUtils.Write Commands Until Prompt   ${cmd}    60
    log    ${output}
    should contain    ${output}    in_port=${port}

Data Path Validation Egress Dispatcher Table
    [Arguments]    ${br_name}    ${conn_id}    ${table_no}    @{validation}
    [Documentation]    Data path validation
    ${pkt_count1}    Get Packetcount    ${br_name}    ${conn_id}    ${table_no}    ${validation[0]}
    ${Write_Metadata}    Get WriteMetadata    ${br_name}    ${conn_id}    ${table_no}    ${validation[0]}
    ${pkt_count2}    Get Packetcount    ${br_name}    ${conn_id}    ${table_no}    ${Write_Metadata} | grep -v ${validation[1]}
    ${pkt_cnt_diff_before}    Evaluate    ${pkt_count2}-${pkt_count1}
    Log    ${pkt_cnt_diff_before}
    [Return]    ${pkt_cnt_diff_before}


Data Path Validation Ingress Dispatcher Table
    [Arguments]    ${br_name}    ${conn_id}    ${table_no}    @{validation}
    [Documentation]    Data path validation
    Log    >>>>>To get the reg6 value of metadata>>>>>>>
    ${metadata}  Get Regexp Matches   ${validation[0]}     \\w{5}
    ${pkt_count1}    Get Packetcount    ${br_name}    ${conn_id}    ${table_no}    reg6=${metadata[0]}
    ${Load_Metadata}    Get LoadMetadata    ${br_name}    ${conn_id}    ${table_no}    reg6=${metadata[0]}
    ${pkt_count2}    Get Packetcount    ${br_name}    ${conn_id}    ${table_no}    ${Load_Metadata} | grep ${validation[1]}
    ${pkt_cnt_diff_before}    Evaluate    ${pkt_count2}-${pkt_count1}
    Log    ${pkt_cnt_diff_before}
    [Return]    ${pkt_cnt_diff_before}

Get Metadata
    [Arguments]    ${conn_id}    ${port}
    Switch Connection    ${conn_id}
    ${grep_metadata}    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name}| grep table=0 | grep in_port=${port} | awk '{print$7}'    ${DEFAULT_LINUX_PROMPT}    30s
    @{metadata}    Split string    ${grep_metadata}    ,
    ${index1}    get from list    ${metadata}    0
    @{complete_meta}    Split string    ${index1}    :
    ${m_data}    get from list    ${complete_meta}    1
    log    ${m_data}
    @{split_meta}    Split string    ${m_data}    /
    ${only_meta}    get from list    ${split_meta}    0
    log    ${only_meta}
    [Return]    ${only_meta}

Table Check
    [Arguments]    ${connection_id}    ${br_name}    ${table_cmdSuffix}    ${validation_list}
    [Documentation]    Check the table
    Switch Connection    ${connection_id}
    ${cmd}    DevstackUtils.Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table_cmdSuffix}   30
    Log    ${cmd}
    : FOR    ${elem}    IN    @{validation_list}
    \    Should Contain    ${cmd}    ${elem}

Table Check With Negative Scenario
    [Arguments]    ${connection_id}    ${br_name}    ${table_cmdSuffix}    ${validation_list}
    [Documentation]    Filtering the flows based on the \ argument and flowtable id for negative testing.
    ${cmd}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table_cmdSuffix}
    Log    ${cmd}
    : FOR    ${elem}    IN    @{validation_list}
    \    Should Not Contain    ${cmd}    ${elem}

Table Check for 220
    [Arguments]    ${connection_id}    ${br_name}    ${table_cmdSuffix}    ${validation_list}
    [Documentation]    Check the table
    Switch Connection    ${connection_id}
    ${cmd}    DevstackUtils.Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table_cmdSuffix}    30
    Log    ${cmd}
    ${i}    Create List
    ${p}    Get Line Count    ${cmd}
    : FOR    ${line}    IN RANGE    0    2
    \    ${line1}    Get Line    ${cmd}    ${line}
    \    ${match}    Get Regexp Matches    ${line1}    n_packets=(\\d+)
    \    Append To List    ${i}    ${match}
    Should Be Equal    ${i[0]}    ${i[1]}

Verify TCP/UDP Traffic Using Netcat
     [Arguments]    ${net_name1}    ${net_name2}    ${vm1_ip}    ${vm2_ip}    ${port_no}    ${verify_string}    ${protocol}=udp    ${user}=cirros    ${password}=cubswin:)
    ${proto_arg}    Set Variable If    '${protocol}'=='udp'    nc -u    nc
    ${Server_Command}    Set Variable    ${proto_arg} -l -p ${port_no}
    ${Client_Command}    Set Variable    ${proto_arg} ${vm1_ip} ${port_no} -v
     Wait Until Keyword Succeeds    240 sec    60 sec    OpenStackOperations.Execute Command on VM Instance    ${net_name1}    ${vm1_ip}    ${Server_Command} > abc &
     Wait Until Keyword Succeeds    240 sec    60 sec    OpenStackOperations.Execute Command on VM Instance    ${net_name2}    ${vm2_ip}    echo Opendaylight|${proto_arg} ${vm1_ip} 12345 &
     ${abc}    Wait Until Keyword Succeeds    240 sec    60 sec    OpenStackOperations.Execute Command on VM Instance    ${net_name1}    ${vm1_ip}     cat abc
     Should Contain    ${abc}    Opendaylight

Get Packetcount
    [Arguments]    ${br_name}    ${conn_id}    ${table_no}    ${conn_state}
    [Documentation]    Getting Packet count
    Switch Connection    ${conn_id}
    ${cmd}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table_no} | grep ${conn_state}
    @{cmdoutput}    Split String    ${cmd}    \r\n
    log    ${cmdoutput}
    ${flow}    get from list    ${cmdoutput}    0
    ${packetcountlist}    Get Regexp Matches    ${flow}    n_packets=([0-9]+),    1
    ${packetcount}    Get From List    ${packetcountlist}    0
    [Return]    ${packetcount}


Get WriteMetadata
    [Arguments]    ${br_name}    ${conn_id}    ${table_no}    ${conn_state}
    [Documentation]    Getting write metadata value
    Switch Connection    ${conn_id}
    ${cmd}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table_no} | grep ${conn_state}
    @{cmdoutput}    Split String    ${cmd}    \r\n
    log    ${cmdoutput}
    ${flow}    get from list    ${cmdoutput}    0
    ${writemetalist}    Get Regexp Matches    ${flow}    write_metadata:(\\w{12})    1
    ${writemetadata}    Get From List    ${writemetalist}    0
    [Return]    ${writemetadata}

Get LoadMetadata
    [Arguments]    ${br_name}    ${conn_id}    ${table_no}    ${conn_state}
    [Documentation]    Getting Load Meta data value
    Switch Connection    ${conn_id}
    ${cmd}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table_no} | grep ${conn_state}
    @{cmdoutput}    Split String    ${cmd}    \r\n
    log    ${cmdoutput}
    ${flow}    get from list    ${cmdoutput}    0
    ${loadmetalist}    Get Regexp Matches    ${flow}    load:(\\w{10})    1
    ${loadmetadata}    Get From List    ${loadmetalist}    0
    [Return]    ${loadmetadata}


Get VM IP Address
    [Arguments]    ${conn_id}    ${vm_name}
    [Documentation]    Show information of a given VM and grep for ip address. VM name should be sent as arguments.
    SSHLibrary.Switch Connection    ${conn_id}
    ${cmd}    Set Variable    openstack server show ${vm_name} | grep "addresses" | awk '{print $4}'
    ${output} =    OpenStack CLI     ${cmd}
    @{z}    Split String    ${output}    =
    [Return]    ${z[1]}


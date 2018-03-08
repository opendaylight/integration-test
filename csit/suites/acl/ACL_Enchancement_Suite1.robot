#Script header:
#Name:
# 	ACL Enhancement
#Purpose :
#	 Enhanced ACL to support protocols like OSPF, VRRP etc that are not supported by conntrack in stateful mode
#Author:
#	Tabassum Sharieff ---(tabassum.s@altencalsoftlabs.com)
#Maintainer:
#	Tabassum Sharieff --(tabassum.s@altencalsoftlabs.com)
#
#References:
#	http://docs.opendaylight.org/en/latest/submodules/netvirt/docs/specs/acl-non-conntrack.html
#
#Description:
#	Tests OF Enhanced ACL to support protocols like OSPF, VRRP etc
#
#Known Bugs:
#
#Script status:
#       automated
#
#TEST TOPOLOGY                                     
#                        |--------------| 
#                        |  CONTROLLER  |
#                        |--------------| 
#                         /           \ 
#                        /             \
#			/               \
##           |----------|               |----------|
#            |  DPN1    |               | DPN2     |
#            |----------|               |----------|
#               |                            |
#               |                            |
#             VM1                           VM2     
#         (30.30.30.1)                 (30.30.30.2) 
#
# End of Header
#=============================================================================================================

*** Settings ***
Documentation     Test suite to validate Enhanced ACL to support protocols like OSPF, VRRP etc that are not supported by conntrack in stateful mode.
...               The Image type used for VM are VYOS and Ubuntu.
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Library           BuiltIn
Library           DebugLibrary
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/OpenStackOperations.robot
Resource          ../../libraries/DevstackUtils.robot
Resource          ../../libraries/SetupUtils.robot
Resource          ../../variables/Variables.robot
Resource          ../../variables/netvirt/Variables.robot

*** Variables ***
${NUM_OF_NETWORK}           1
${Req_no_of_net}            1
${Req_no_of_subNet}         1
${Req_no_of_ports}          2
${Req_no_of_vms_per_dpn}    1
#${OS_CONTROL_NODE_IP}      192.168.56.100
@{PORT_LIST}                port_1    port_2
@{table_list}               goto_table:239    goto_table:210
${VM1_ROUTER_ID}    	    127.1.1.100
${VM2_ROUTER_ID}    	    127.1.1.200
${VM1_Loopback_address}     127.1.1.1/32
${VM2_Loopback_address}     127.1.1.2/32
${Virtual_address}          30.30.30.100/24
${OSPF_Area}                0.0.0.0
${OSPF_Network1}            127.1.1.0/24
${OSPF_Network2}            30.30.30.0/24
@{VM_NAMES}                 myvm1    myvm2
@{SECURITY_GROUP}           SG1
@{REQ_NETWORKS}             _Net1   
@{REQ_SUBNETS}              subnet1
@{REQ_SUBNET_CIDR}          30.30.30.0/24
${NUM_OF_VMS_PER_DPN}       1
${VYOS_USER}                vyos
${VYOS_PASS}                vyos
${br_name}                  br-int
${VYOS_CONFIG_PROMPT}       \#
${VYOS_FLAVOR}              m1.medium
${VM1_OSPF_CONFIG}          configure \n set interfaces loopback lo address ${VM1_Loopback_address} \n set protocols ospf area ${OSPF_Area} \n set protocols ospf area ${OSPF_Area} ${OSPF_Network1} \n set protocols ospf area ${OSPF_Area} network ${OSPF_Network2} \n set protocols ospf parameters router-id ${VM1_ROUTER_ID} \n set protocols ospf log-adjacency-changes\n set protocols ospf redistribute connect\n commit
${VM2_OSPF_CONFIG}          configure \n set interfaces loopback lo address ${VM2_Loopback_address} \n set protocols ospf area ${OSPF_Area} \n set protocols ospf area ${OSPF_Area} ${OSPF_Network1} \n set protocols ospf area ${OSPF_Area} network ${OSPF_Network2} \n set protocols ospf parameters router-id ${VM2_ROUTER_ID} \n set protocols ospf log-adjacency-changes \n set protocols ospf redistribute connect \n commit
${VM1_VRRP_CONFIG}          configure \n delete interfaces tunnel tun0 \n deltete protocols \n set interfaces ethernet eth0 vrrp vrrp-group 1 priority ${Priority[0]} \n set interfaces ethernet eth0 vrrp vrrp-group 1 'rfc3768-compatibility' \n set interfaces ethernet eth0 vrrp vrrp-group 1 virtual-address ${Virtual_address}
${VM2_VRRP_CONFIG}          configure \n delete interfaces tunnel tun0 \n deltete protocols \n set interfaces ethernet eth0 vrrp vrrp-group 1 priority ${Priority[1]} \n set interfaces ethernet eth0 vrrp vrrp-group 1 'rfc3768-compatibility' \n set interfaces ethernet eth0 vrrp vrrp-group 1 virtual-address ${Virtual_address}


*** Test Cases ***
TC1_Verify OSPF traffic ( Hello Packets-Multicast) works fine with Default SG in same subnet
    [Documentation]    Verify OSPF traffic ( Hello Packets-Multicast) works fine with Default SG in same subnet
    Log    Suite testing
    Create Nova VMs    ${Req_no_of_vms_per_dpn}
    ${VM_IP_DPN1}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}    ${VM_NAMES[0]}
    ${VM_IP_DPN2}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP2_CONN_ID}    ${VM_NAMES[1]}
    ${VM1_Port}    In Port VM    ${OS_CMP1_CONN_ID}    ${br_name}    ${PORT_LIST[0]}
    ${VM2_Port}    In Port VM    ${OS_CMP2_CONN_ID}    ${br_name}    ${PORT_LIST[1]}
    Check In Port    ${VM1_Port}   ${OS_CMP1_CONN_ID}
    Check In Port    ${VM2_Port}   ${OS_CMP2_CONN_ID}
    ${vm1_metadata}    Get Metadata    ${OS_CMP1_CONN_ID}    ${VM1_Port}
    ${vm2_metadata}    Get Metadata    ${OS_CMP2_CONN_ID}    ${VM2_Port}
    Allowed Adress Pair Config    ${Req_no_of_ports}
    Verify VM to VM Ping Status    ${REQ_NETWORKS[0]}    ${VM_IP_DPN1}    ${VM_IP_DPN2}    ${PING_REGEXP}
    OSPF CONFIG ON VM    ${REQ_NETWORKS[0]}    ${VM_IP_DPN1}    ${VM_IP_DPN2}
    Verify VM to VM Ping Status    ${REQ_NETWORKS[0]}    ${VM_IP_DPN1}    ${VM_IP_DPN2}    ${PING_REGEXP}
    Verify OSPF Neighbourship FULL State    ${REQ_NETWORKS[0]}    ${VM_IP_DPN2}    ${VM1_ROUTER_ID}
    Wait Until Keyword Succeeds    40 sec    10 sec    Table Check    ${OS_CMP1_CONN_ID}    ${br_name}    ${vm1_metadata}
    ...    ${table_list[0]}
    Wait Until Keyword Succeeds    40 sec    10 sec    Table Check    ${OS_CMP2_CONN_ID}    ${br_name}    ${vm2_metadata}
    ...    ${table_list[1]}
    @{table_220}    Create List    reg6=${vm1_metadata}    actions=output:${VM2_Port}    actions=load:${vm1_metadata}    goto_table:241
    Wait Until Keyword Succeeds    40 sec    10 sec    Table Check    ${OS_CMP2_CONN_ID}    ${br_name}    reg6=
    ...    @{table_220}
    Table Check for 220    ${OS_CMP2_CONN_ID}    ${br_name}    reg6=
    [Teardown]    Delete Setup

TC2_Verify VRRP traffic (Advertisements-Multicast) works fine with Default SG in same subnet
    [Documentation]    Verify VRRP traffic (Advertisements-Multicast) works fine with Default SG in same subnet
    Log    Suite testing
    Create Nova VMs    ${Req_no_of_vms_per_dpn}
    ${VM_IP_DPN1}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}    ${VM_NAMES[0]}
    ${VM_IP_DPN2}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP2_CONN_ID}    ${VM_NAMES[1]}
    ${VM1_Port}    In Port VM    ${OS_CMP1_CONN_ID}    ${br_name}    ${PORT_LIST[0]}
    ${VM2_Port}    In Port VM    ${OS_CMP2_CONN_ID}    ${br_name}    ${PORT_LIST[1]}
    Check In Port    ${VM1_Port}   ${OS_CMP1_CONN_ID}
    Check In Port    ${VM2_Port}   ${OS_CMP2_CONN_ID}
    ${vm1_metadata}    Get Metadata    ${OS_CMP1_CONN_ID}    ${VM1_Port}
    ${vm2_metadata}    Get Metadata    ${OS_CMP2_CONN_ID}    ${VM2_Port}
    Verify VM to VM Ping Status    ${REQ_NETWORKS[0]}    ${VM_IP_DPN1}    ${VM_IP_DPN2}    ${PING_REGEXP}
    Allowed Adress Pair Config    ${Req_no_of_ports}
    VRRP CONFIG ON VM    ${REQ_NETWORKS[0]}    ${VM_IP_DPN1}    ${VM1_VRRP_CONFIG} 
    VRRP CONFIG ON VM    ${REQ_NETWORKS[0]}    ${VM_IP_DPN2}    ${VM2_VRRP_CONFIG}
    Verify VRRP State    ${REQ_NETWORKS[0]}    ${VM_IP_DPN1}
    Verify VRRP State    ${REQ_NETWORKS[0]}    ${VM_IP_DPN2}    BACKUP
    Verify VM to VM Ping Status    ${REQ_NETWORKS[0]}    ${VM_IP_DPN1}    ${VM_IP_DPN2}    ${PING_REGEXP}
    Wait Until Keyword Succeeds    40 sec    10 sec    Table Check    ${OS_CMP1_CONN_ID}    ${br_name}    ${vm1_metadata}
    ...    ${table_list[0]}
    Wait Until Keyword Succeeds    40 sec    10 sec    Table Check    ${OS_CMP2_CONN_ID}    ${br_name}    ${vm2_metadata}
    ...    ${table_list[1]}
    @{table_220}    Create List    reg6=${vm1_metadata}    actions=output:${VM2_Port}    actions=load:${vm1_metadata}    goto_table:241
    Wait Until Keyword Succeeds    40 sec    10 sec    Table Check    ${OS_CMP2_CONN_ID}    ${br_name}    reg6=
    ...    @{table_220}
    Table Check for 220    ${OS_CMP2_CONN_ID}    ${br_name}    reg6=
    ${Pkt_cnt_before_ping}    get packetcount    ${br_name}    ${OS_CMP1_CONN_ID}    table=0    ${load_vm1_metadata}


*** Keywords ***
Start Suite
    [Documentation]    Test Suite for CR156 Multicast
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DevstackUtils.Devstack Suite Setup
    Create Setup

Stop Suite
    [Documentation]    Run after the tests execution
    Close All Connections

Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports And Four VMs on each DPN
    Log    Create tunnels between the 2 compute nodes
    ${devstack_conn_id}    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    Create Neutron Networks    ${Req_no_of_net}
    Create Neutron Subnets    ${Req_no_of_subNet}
    OpenStackOperations.Neutron Security Group Create    ${SECURITY_GROUP[0]}
    Create Neutron Ports    ${Req_no_of_ports}
    Security Group Rule with Remote IP Prefix

Security Group Rule with Remote IP Prefix
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=egress    protocol=ospf    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=ingress    protocol=ospf    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=egress    protocol=vrrp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=ingress    protocol=vrrp    remote-ip=0.0.0.0/0

Create Neutron Networks
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of networks
    : FOR    ${NET}    IN    @{REQ_NETWORKS}
    \    Create Network    ${NET}
    ${NET_LIST}    List Networks
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    Should Contain    ${NET_LIST}    ${REQ_NETWORKS[${index}]}

Create Neutron Subnets
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of subnets for previously created networks
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    Create SubNet    ${REQ_NETWORKS[${index}]}    ${REQ_SUBNETS[${index}]}    ${REQ_SUBNET_CIDR[${index}]}
    ${SUB_LIST}    List Subnets
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    Should Contain    ${SUB_LIST}    ${REQ_SUBNETS[${index}]}

Create Neutron Ports
    [Arguments]    ${NUM_OF_PORTS}
    [Documentation]    Create required number of ports under previously created subnets
    :FOR    ${index}    IN RANGE    0    ${NUM_OF_PORTS}
    \    Create Port    ${REQ_NETWORKS[0]}    ${PORT_LIST[${index}]}    sg=${SECURITY_GROUP[0]}

Create Nova VMs
    [Arguments]    ${NUM_OF_VMS_PER_DPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create Vm instances on compute nodes
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_NAMES[0]}    ${OS_CNTL_HOSTNAME}    ${VYOS_USER}    ${VYOS_FLAVOR}    sg=${SECURITY_GROUP[0]}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_NAMES[1]}    ${OS_CMP1_HOSTNAME}    ${VYOS_USER}    ${VYOS_FLAVOR}    sg=${SECURITY_GROUP[0]}
    List Nova VMs
    : FOR    ${VM}    IN    @{VM_NAMES}
    \    Wait Until Keyword Succeeds    60s    10s    Verify VM Is ACTIVE    ${VM}

Verify VM to VM Ping Status
    [Arguments]    ${NETWORK}    ${VM_IP1}    ${VM_IP2}    ${PING_REGEXP}
    [Documentation]    Verify Ping Success among VMs
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NETWORK}    ${VM_IP1}
    ...    ping ${VM_IP2} count 8    ${VYOS_USER}    ${VYOS_PASS}
    Should Contain    ${output}    ${PING_REGEXP}

OSPF CONFIG ON VM
    [Arguments]    ${NETWORK}    ${VM_IP1}    ${VM_IP2}
    [Documentation]    Verify Ping Success among VMs
    ${net_id} =    OpenStackOperations.Get Net Id    ${NETWORK}
    ${output} =    Utils.Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh vyos@${VM_IP1} -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null    password:
    ${output} =    Utils.Write Commands Until Expected Prompt    ${VYOS_USER}    ${OS_SYSTEM_PROMPT}
    ${count}    Get Line Count    ${VM1_Config}
    :FOR    ${index}    IN RANGE    0    ${count}
    \    ${cmd}    Get Line    ${VM1_Config}    ${index}
    \    Utils.Write Commands Until Expected Prompt    ${cmd}    ${VYOS_CONFIG_PROMPT}
    Utils.Write Commands Until Expected Prompt    exit    ${OS_SYSTEM_PROMPT}
    ${net_id} =    OpenStackOperations.Get Net Id    ${NETWORK}
    ${output} =    Utils.Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh vyos@${VM_IP2} -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null    $
    ${output} =    Utils.Write Commands Until Expected Prompt    ${VYOS_USER}    ${OS_SYSTEM_PROMPT}
    ${count}    Get Line Count    ${VM2_Config}
    :FOR    ${index}    IN RANGE    0    ${count}
    \    ${cmd}    Get Line    ${VM2_Config}    ${index}
    \    Utils.Write Commands Until Expected Prompt    ${cmd}    ${VYOS_CONFIG_PROMPT}
    Utils.Write Commands Until Expected Prompt    exit    ${OS_SYSTEM_PROMPT}

Show IP OSPF Neighbour
    [Arguments]    ${NETWORK}    ${VM_IP1}
    [Documentation]    Display OSPF neighbour output
    ${cmd}    Set Variable    show ip ospf neighbor
    ${output}    Wait Until Keyword Succeeds    80s    10s    Execute Command on VM Instance    ${NETWORK}    ${VM_IP1}
    ...    ${cmd}    ${VYOS_USER}    ${VYOS_PASS}
    log    ${output}
    ${Return}    ${output}

Verify OSPF Neighbourship FULL State
    [Arguments]    ${Network}    ${VM_IP}    ${ROUTER_ID}
    [Documentation]    Verify OSPF Neighbourship FULL State Established
    ${output}    Show IP OSPF Neighbour    ${Network}    ${VM_IP}
    ${rc}    Should Match Regexp    ${output}    (${ROUTER_ID})(\\W+\\d\\W)(Full/Backup)
    Should Be True    '${rc}' == '0'

Allowed Adress Pair Config
    [Arguments]    ${NUM_OF_PORTS}
    [Documentation]    Update Port with AAP
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_PORTS}
    \    ${port-id}    Get Port Id    ${PORT_LIST[${index}]}    ${OS_CMP1_CONN_ID}
    \    Update Port    ${port-id}    --allowed-address mac-address=01:00:5e:00:00:05,ip-address=224.0.0.5

VRRP CONFIG
    [Arguments]    ${Network}    ${VM_IP}    ${vrrp_config}  
    [Documentation]    Configure VRRP
    : FOR    ${item}    IN    ${vrrp_config}
    \    ${rc}    Execute Command on VM Instance    ${Network}    ${VM_IP_DPN1}    ${item}    user=${VYOS_USER}    password=${VYOS_PASS}
    \    Should Be True    '${rc}' == '0'

Run Show VRRP
    [Arguments]    ${NETWORK}    ${VM_IP}
    [Documentation]    Display run Show VRRP output.
    ${cmd}    Set Variable    run show vrrp
    ${rc}    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NETWORK}
    ...    ${VM_IP1}    ${cmd}    user=${VYOS_USER}    password=${VYOS_PASS}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Verify VRRP State
    [Arguments]    ${NETWORK}    ${VM_IP}    ${State}=MASTER
    [Documentation]    Verify the RUN SHOW VRRP o/p for MASTER and BACKUP.
    ${output}    Run Show VRRP    ${NETWORK}    ${VM_IP}
    Should Contain    ${output}    ${State}

Add Static Route to Multicast IP
    [Arguments]    ${Network}    ${VM_IP1}
    [Documentation]    Add static route to Multicast IP.
    ${cmd}    Set Variable    Sudo route add -host 224.0.0.1 ${ens}
    ${rc}    ${output}=    Execute Command on VM Instance    ${Network}    ${VM_IP1}    ${cmd}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Add Static Route to Multicast IP
    [Arguments]    ${Network}    ${VM_IP1}
    [Documentation]    Add static route to Multicast IP

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

Get Metadata
    [Arguments]    ${conn_id}    ${port}
    [Documentation]    Get the Metadata for a given port
    Switch Connection    ${conn_id}
    ${grep_metadata}    DevstackUtils.Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name}| grep table=0 | grep in_port=${port}    30
    log    ${grep_metadata}
    @{metadata}    Get Regexp Matches    ${grep_metadata}    metadata:(\\w{12})
    ${metadata1}    Convert To String    @{metadata}
    ${y}    strip string    ${metadata1}    mode=right    characters=0000
    ${z}    set variable    00
    ${i}    Concatenate the String    ${y}    ${z}
    ${metadata2}    Remove Space on String    ${i}
    [Return]    ${metadata2}

Table Check
    [Arguments]    ${connection_id}    ${br_name}    ${table_cmdSuffix}    ${validation_list}
    [Documentation]    Check the table
    Switch Connection    ${connection_id}
    ${cmd}    DevstackUtils.Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table_cmdSuffix}   30
    Log    ${cmd}
    : FOR    ${elem}    IN    @{validation_list}
    \    Should Contain    ${cmd}    ${elem}

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

Delete Setup
    [Documentation]    Delete the created VMs, ports, subnets, networks etc.
    Log    Delete the VM instance
    :FOR    ${VM_NAME}    IN    @{VM_NAMES}
    \    Run Keyword And Ignore Error    Delete Vm Instance    ${VM_NAME}
    Log    Delete the Port created
    :FOR    ${port_name}    IN    @{PORT_LIST}
    \    Run Keyword And Ignore Error    Delete Port    ${port_name}
    Log    Delete-Subnet
    :FOR    ${Snet}    IN    @{REQ_SUBNETS}
    \    Run Keyword And Ignore Error    Delete SubNet    ${Snet}
    Log    Delete-networks
    :FOR    ${net}    IN    @{REQ_NETWORKS}
    \    Run Keyword And Ignore Error    Delete Network    ${net}
    :FOR    ${Sec_grp}    IN    @{SECURITY_GROUP} 
    \    Run Keyword And Ignore Error    Delete SecurityGroup    ${Sec_grp}


Get VM IP Address
    [Arguments]    ${conn_id}    ${vm_name}
    [Documentation]    Show information of a given VM and grep for ip address. VM name should be sent as arguments.
    SSHLibrary.Switch Connection    ${conn_id}
    ${cmd}    Set Variable    openstack server show ${vm_name} | grep "addresses" | awk '{print $4}'
    ${output} =    OpenStack CLI     ${cmd}
    @{z}    Split String    ${output}    =
    [Return]    ${z[1]}

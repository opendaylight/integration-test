*** Settings ***
Documentation     Test suite to validate elan service functionality in ODL environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       OpenStackOperations.OpenStack Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${NUM_OF_NETWORK}   2
${REQ_NO_OF_NET}    2
${REQ_NO_OF_SUBNET}    2
${REQ_NO_OF_PORTS}    6
${REQ_NO_OF_VMS_PER_DPN}    1
@{REQ_NETWORKS}    _Net1    _Net2
@{REQ_SUBNETS}    subnet1    subnet2
@{REQ_SUBNET_CIDR}    30.30.30.0/24    40.40.40.0/24
@{PORTS}    port_1    port_2    port_3    port_4    port_5    port_6
@{TABLE_LIST}    table=220    table=17
${VM1_ROUTER_ID}    127.1.1.100
${VM2_ROUTER_ID}    127.1.1.200
${VM1_LOOPBACK_ADDRESS}    127.1.1.1/32
${VM2_LOOPBACK_ADDRESS}    127.1.1.2/32
${OSPF_AREA}    0.0.0.0
${OSPF_NETWORK1}    127.1.1.0/24
${OSPF_NETWORK2}    30.30.30.0/24
@{VM_NAMES}    myvm1    myvm2    myvm3 
@{SECURITY_GROUP}    SG1    SG2
${BR_NAME}    br-int
${VIRTUAL_IP}    30.30.30.100/24
@{PRIORITY}    100    90
${ROUTER_NAME}    router1
${CIRROS_USER}     cirros
${CIRRIOS_PASSWORD}    cubswin:)
${TABLE_NO}    table=210
${PACKET_COUNT}    5
${RANDOM_IP}    11.11.11.11
@{SPOOF_MAC_ADDRESS}    FA:17:3E:73:65:86    fa:16:3e:3d:3b:5e
${PACKET_COUNT_ZERO}    0
@{SPOOF_IP}    30.30.30.100
${NETMASK}    255.255.255.0
@{CHECK_LIST}    goto_table:239    goto_table:210    reg6=
${INCOMPLETE}    incomplete
 
*** Test Cases ***
TC1_Verify ARP request Valid MAC and Valid IP for the VM Egress Table
    Create Setup
    Create Nova VMs    3    cirros
    @{VM_IP_DPN1}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}    ${VM_NAMES[0]}
    @{VM_IP_DPN2}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP2_CONN_ID}    ${VM_NAMES[1]}
    @{VM_IP_DPN3}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}    ${VM_NAMES[2]}
    Set Global Variable    @{VM_IP_DPN1}
    Set Global Variable    @{VM_IP_DPN3}
    Set Global Variable    @{VM_IP_DPN2}
    ${VM1_Port}    In Port VM    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${PORTS[0]}
    ${VM2_Port}    In Port VM    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${PORTS[2]}
    ${VM3_Port}    In Port VM    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${PORTS[4]}
    Check In Port    ${VM1_Port}   ${OS_CMP1_CONN_ID}
    Check In Port    ${VM2_Port}   ${OS_CMP2_CONN_ID}
    Check In Port    ${VM3_Port}   ${OS_CMP1_CONN_ID}
    ${vm1_metadata}    Get Metadata    ${OS_CMP1_CONN_ID}    ${VM1_Port}
    ${vm2_metadata}    Get Metadata    ${OS_CMP2_CONN_ID}    ${VM2_Port}
    ${vm3_metadata}    Get Metadata    ${OS_CMP1_CONN_ID}    ${VM3_Port}
    Set Global Variable    ${vm1_metadata}
    Set Global Variable    ${vm2_metadata} 
    Set Global Variable    ${vm3_metadata}
    Set Global Variable    ${VM1_Port}   
    Set Global Variable    ${VM2_Port}
    Set Global Variable    ${VM3_Port}
    ${VM1_Port_MAC}    Get Port Mac    ${PORTS[0]}
    Set Global Variable    ${VM1_Port_MAC}
    ${cmd}    Set Variable    ifconfig eth0  
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN1[0]}    ${cmd}    ${CIRROS_USER}    ${CIRRIOS_PASSWORD}
    ${flow_dump_cmd}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 br-int
    ${ovs1_output}    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${flow_dump_cmd}
    ${get_pkt_count_before_arp}     Get Packetcount    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm1_metadata}|grep arp_sha
    ${cmd}    Set Variable    sudo /sbin/cirros-dhcpc up eth1
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN1[0]}    ${cmd}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN2[0]}    ${cmd}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN3[0]}    ${cmd}
    ${cmd}    Set Variable    sudo arping -I eth0 -c ${PACKET_COUNT} \ ${RANDOM_IP} 
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN1[1]}    ${cmd}    
    ${flow_dump_cmd}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 br-int
    ${ovs1_output}    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${flow_dump_cmd}
    ${get_pkt_count_after_arp}     Get Packetcount    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm1_metadata}|grep arp_sha
    ${pkt_diff}    Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT} 
    Delete Setup


*** Keywords ***

Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports And Four VMs on each DPN
    Log    Create tunnels between the 2 compute nodes
    @{availibity_zone}    Create List    ${OS_CMP1_HOSTNAME}    ${OS_CMP2_HOSTNAME}    ${OS_CMP1_HOSTNAME}
    Set Global Variable    @{availibity_zone}    
    Create Neutron Networks    ${REQ_NO_OF_NET}
    Create Neutron Subnets    ${REQ_NO_OF_SUBNET}
    OpenStackOperations.Neutron Security Group Create    ${SECURITY_GROUP[0]}
    OpenStackOperations.Delete All Security Group Rules    ${SECURITY_GROUP[0]}
    Create Neutron Ports    6
    Security Group Rule with Remote IP Prefix

Security Group Rule with Remote IP Prefix
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=ingress    protocol=icmp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=egress    protocol=icmp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=egress    protocol=ospf    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=ingress    protocol=ospf    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=egress    protocol=vrrp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=ingress    protocol=vrrp    remote-ip=0.0.0.0/0


Create Neutron Networks
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of networks
    : FOR    ${net}    IN    @{REQ_NETWORKS}
    \    Create Network    ${net}
    ${net_list}    List Networks
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    Should Contain    ${net_list}    ${REQ_NETWORKS[${index}]}

Create Neutron Subnets
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of subnets for previously created networks
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    Create SubNet    ${REQ_NETWORKS[${index}]}    ${REQ_SUBNETS[${index}]}    ${REQ_SUBNET_CIDR[${index}]}
    ${sub_list}    List Subnets
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    Should Contain    ${sub_list}    ${REQ_SUBNETS[${index}]}

Create Neutron Ports
    [Arguments]    ${NUM_OF_PORTS}
    [Documentation]    Create required number of ports under previously created subnets
    Create Port    ${REQ_NETWORKS[0]}    ${PORTS[0]}    sg=${SECURITY_GROUP[0]}
    Create Port    ${REQ_NETWORKS[1]}    ${PORTS[1]}    sg=${SECURITY_GROUP[0]}
    Create Port    ${REQ_NETWORKS[0]}    ${PORTS[2]}    sg=${SECURITY_GROUP[0]}
    Create Port    ${REQ_NETWORKS[1]}    ${PORTS[3]}    sg=${SECURITY_GROUP[0]}
    Create Port    ${REQ_NETWORKS[0]}    ${PORTS[4]}    sg=${SECURITY_GROUP[0]}
    Create Port    ${REQ_NETWORKS[1]}    ${PORTS[5]}    sg=${SECURITY_GROUP[0]}

Create Nova VMs
    [Arguments]    ${index}    ${image}=vyos    ${flavor}=m1.medium   
    [Documentation]    Create Vm instances on compute nodes
    Run Keyword If    '${image}' == 'vyos'    VYOS VM    ${index}    ${image}    ${flavor}
    ...    ELSE    CIRROS VM    ${index}        
    : FOR    ${i}    IN RANGE    0    ${index}
    \    Wait Until Keyword Succeeds    60s    10s    Verify VM Is ACTIVE    ${VM_NAMES[${i}]}

VYOS VM
    [Arguments]    ${index}    ${image}    ${flavor}
    [Documentation]    Create Vm instances on compute nodes
    : For    ${i}    IN RANGE    0    ${index}
    \    Create Vm Instance With Port On Compute Node    ${PORTS[${i}]}    ${VM_NAMES[${i}]}    ${availibity_zone[${i}]}    ${image}    ${flavor}    sg=${SECURITY_GROUP[0]}

CIRROS VM
    [Arguments]    ${index}   
    [Documentation]    Create Vm instances on compute nodes
    Create Vm Instance With Ports    ${PORTS[0]}    ${PORT_LIST[1]}    ${VM_NAMES[0]}    ${availibity_zone[0]}    flavor=m1.tiny    sg=${SECURITY_GROUP[0]}
    Create Vm Instance With Ports    ${PORTS[2]}    ${PORT_LIST[3]}    ${VM_NAMES[1]}    ${availibity_zone[1]}    flavor=m1.tiny    sg=${SECURITY_GROUP[0]}
    Create Vm Instance With Ports    ${PORTS[4]}    ${PORT_LIST[5]}    ${VM_NAMES[2]}    ${availibity_zone[2]}    flavor=m1.tiny    sg=${SECURITY_GROUP[0]}


Alllowed Adress Pair Config
    [Arguments]    ${NUM_OF_PORTS}
    [Documentation]    Update Port with AAP
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_PORTS}
    \    ${port-id}    Get Port Id    ${PORTS[${index}]}    ${OS_CMP1_CONN_ID}
    \    Update Port    ${port-id}    --allowed-address mac-address=01:00:5e:00:00:05,ip-address=224.0.0.5

VRRP Alllowed Adress Pair Config
    [Arguments]    ${NUM_OF_PORTS}    ${VM_IP_DPN1}    ${VM_IP_DPN2}
    [Documentation]    Update Port with AAP
    ${port-id}    Get Port Id    ${PORTS[0]}    ${OS_CMP1_CONN_ID}
    Update Port    ${port-id}    --allowed-address mac-address=01:00:5e:00:00:12,ip-address=224.0.0.18 --allowed-address mac-address=00:00:5e:00:01:01,ip-address=${VM_IP_DPN1}
    ${port-id}    Get Port Id    ${PORTS[1]}    ${OS_CMP1_CONN_ID}
    Update Port    ${port-id}    --allowed-address mac-address=01:00:5e:00:00:12,ip-address=224.0.0.18 --allowed-address mac-address=00:00:5e:00:01:01,ip-address=${VM_IP_DPN2}
    


VRRP CONFIG
    [Arguments]    ${NETWORK}    ${VM_IP1}    ${VM_IP2}    
    [Documentation]    Configure VRRP
    ${net_id} =    OpenStackOperations.Get Net Id    ${NETWORK}
    ${output} =    Utils.Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh vyos@${VM_IP1} -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null    password:
    ${output} =    Utils.Write Commands Until Expected Prompt    vyos    ${OS_SYSTEM_PROMPT}
    ${count}    Get Line Count    ${VM1_VRRP_CONFIG}
    :FOR    ${index}    IN RANGE    0    ${count}
    \    ${cmd}    Get Line    ${VM1_VRRP_CONFIG}    ${index}
    \    Utils.Write Commands Until Expected Prompt    ${cmd}    \#
    Utils.Write Commands Until Expected Prompt    exit    $
    Utils.Write Commands Until Expected Prompt    exit    $
    ${net_id} =    OpenStackOperations.Get Net Id    ${NETWORK}
    ${output} =    Utils.Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh vyos@${VM_IP2} -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null    password:
    ${output} =    Utils.Write Commands Until Expected Prompt    vyos    ${OS_SYSTEM_PROMPT}
    ${count}    Get Line Count    ${VM2_VRRP_CONFIG}
    :FOR    ${index}    IN RANGE    0    ${count}
    \    ${cmd}    Get Line    ${VM2_VRRP_CONFIG}    ${index}
    \    Utils.Write Commands Until Expected Prompt    ${cmd}    \#
    Utils.Write Commands Until Expected Prompt    exit    $
    Utils.Write Commands Until Expected Prompt    exit    $


Run Show VRRP
    [Arguments]    ${NETWORK}    ${VM_IP}
    [Documentation]    Display run Show VRRP output.
    ${cmd}    Set Variable    show vrrp
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NETWORK}
    ...    ${VM_IP}    ${cmd}    vyos    vyos
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
    [Arguments]    ${connec_id}    ${BR_NAME}    ${portname}
    [Documentation]    Get the port number for given portname
    SSHLibrary.Switch Connection    ${connec_id}
    ${pnum}    Get Sub Port Id    ${portname}    ${connec_id}
    ${command_1}    Set Variable    sudo ovs-ofctl -O OpenFlow13 show ${BR_NAME} | grep ${pnum} | awk '{print$1}'
    log    sudo ovs-ofctl -O OpenFlow13 show ${BR_NAME} | grep ${pnum} | awk '{print$1}'
    ${num}    DevstackUtils.Write Commands Until Prompt    ${command_1}    30
    log    ${num}
    ${port_number}    Should Match Regexp    ${num}    [0-9]+
    log    ${port_number}
    [Return]    ${port_number}

In Port VM
    [Arguments]    ${conn_id}    ${BR_NAME}    ${portname}
    [Documentation]    Get the port number for given portname
    ${VM_Port}    Get Port Number    ${conn_id}    ${BR_NAME}    ${portname}
    [Return]    ${VM_port}

Check In Port
    [Arguments]    ${port}    ${conn_id}
    [Documentation]    Check the port present in table 0
    SSHLibrary.Switch Connection    ${conn_id}
    ${cmd}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 ${BR_NAME} | grep table=0
    ${output}    DevstackUtils.Write Commands Until Prompt   ${cmd}    60
    log    ${output}
    should contain    ${output}    in_port=${port}

Get Metadata
    [Arguments]    ${conn_id}    ${port}
    [Documentation]    Get the Metadata for a given port
    Switch Connection    ${conn_id}
    ${grep_metadata}    DevstackUtils.Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${BR_NAME}| grep table=0 | grep in_port=${port} | awk '{print$7}'    30
    log    ${grep_metadata}
    @{metadata}    Split String    ${grep_metadata}    ,
    ${metadata1}    Get From List    ${metadata}    0
    @{final_meta}    Split String    ${metadata1}    :
    ${metadata_final}    Get From List    ${final_meta}    1
    @{metadata_final1}    Split String    ${metadata_final}    /
    ${meta}    Get From List    ${metadata_final1}    0
    #@{metadata}  Get Regexp Matches   ${grep_metadata}     metadata:(\\w{12})
    #${metadata1}    Convert To String    @{metadata}
    #${y}    strip string    ${metadata1}    mode=right    characters=0000
    #${z}    set variable    00
    #${i}    Concatenate the String    ${y}    ${z}
    #${metadata2}    Remove Space on String    ${i}
    [Return]    ${meta}

Table Check
    [Arguments]    ${connection_id}    ${BR_NAME}    ${table_cmdSuffix}    @{validation_list}
    [Documentation]    Check the table
    Switch Connection    ${connection_id}
    ${cmd}    DevstackUtils.Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${BR_NAME} | grep ${table_cmdSuffix}   30
    Log    ${cmd}
    : FOR    ${elem}    IN    @{validation_list}
    \    Should Contain    ${cmd}    ${elem}

Table Check for 220
    [Arguments]    ${connection_id}    ${BR_NAME}    ${table_cmdSuffix}    ${validation_list}
    [Documentation]    Check the table
    Switch Connection    ${connection_id}
    ${cmd}    DevstackUtils.Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${BR_NAME} | grep ${table_cmdSuffix}    30
    Log    ${cmd}
    ${i}    Create List
    ${p}    Get Line Count    ${cmd}
    : FOR    ${line}    IN RANGE    0    2
    \    ${line1}    Get Line    ${cmd}    ${line}
    \    ${match}    Get Regexp Matches    ${line1}    n_packets=(\\d+)
    \    Append To List    ${i}    ${match}
    Should Be Equal    ${i[0]}    ${i[1]}

Send Traffic Using Netcat
    [Arguments]    ${virshid1}    ${virshid2}    ${vm1_ip}    ${vm2_ip}    ${compute_1_conn_id}    ${compute_2_conn_id}
    ...    ${port_no}    ${verify_string}    ${protocol}=udp
    [Documentation]    Send traffic using netcat
    ${proto_arg}    Set Variable If    '${protocol}'=='udp'    nc -u    nc
    Log    >>>Logging into the vm1>>>
    Switch Connection    ${compute_1_conn_id}
    Virsh Login    ${virshid1}
    DevstackUtils.Write Until Expected Output    ${proto_arg} -s ${vm1_ip} -l -p ${port_no} -v\r    expected=listening    timeout=5s    retry_interval=1s
    Log    >>>Logging into the vm2>>>
    Switch Connection    ${compute_2_conn_id}
    Virsh Login    ${virshid2}
    DevstackUtils.Write Until Expected Output    ${proto_arg} ${vm1_ip} ${port_no} -v\r    expected=open    timeout=5s    retry_interval=1s
    DevstackUtils.Write Until Expected Output    60s    10s    Execute Command on VM Instance    ${NETWORK}    ${VM_IP1}
    Write    ${verify_string}
    Write    ${verify_string}
    Write    ${verify_string}
    Write    ${verify_string}
    Write_Bare_Ctrl_C
    Virsh Exit
    Switch Connection    ${compute_1_conn_id}
    ${cmdoutput}    Read
    Log    ${cmdoutput}
    Write_Bare_Ctrl_C
    Virsh Exit
    Should Contain    ${cmdoutput}    ${verify_string}

Delete TestSetup
    [Documentation]    Delete the created VMs, ports, subnets, networks etc.
    Log    Delete the VM instance
    :FOR    ${vm_name}    IN    @{VM_NAMES}
    \    Run Keyword And Ignore Error    Delete Vm Instance    ${vm_name}

Delete Setup
    [Documentation]    Delete the created VMs, ports, subnets, networks etc.
    Log    Dumping all the flows
    Log    Delete the VM instance
    :FOR    ${vm_name}    IN    @{VM_NAMES}
    \    Run Keyword And Ignore Error    Delete Vm Instance    ${vm_name}
    Log    Delete the Port created
    :FOR    ${port_name}    IN    @{PORTS}
    \    Run Keyword And Ignore Error    Delete Port    ${port_name}
    Log    Delete-Subnet
    :FOR    ${snet}    IN    @{REQ_SUBNETS}
    \    Run Keyword And Ignore Error    Delete SubNet    ${snet}
    Log    Delete-networks
    :FOR    ${net}    IN    @{REQ_NETWORKS}
    \    Run Keyword And Ignore Error    Delete Network    ${net}
    :FOR    ${sec_grp}    IN    @{SECURITY_GROUP} 
    \    Run Keyword And Ignore Error    Delete SecurityGroup    ${sec_grp}


Get VM IP Address
    [Arguments]    ${conn_id}    ${vm_name}
    [Documentation]    Show information of a given VM and grep for ip address. VM name should be sent as arguments.
    SSHLibrary.Switch Connection    ${conn_id}
    ${cmd}    Set Variable    openstack server show ${vm_name} | grep "addresses" | awk '{print $4$5}'
    ${output} =    OpenStack CLI     ${cmd}
    @{output}    Split String    ${output}    ;
    ${output_string1}    Convert To String    ${output[0]}
    ${output_string2}    Convert To String    ${output[1]}
    @{net1_string}    Split String    ${output_string1}    =
    @{net2_string}    Split String    ${output_string2}    =
    @{final_list}    Create List    ${net1_string[1]}    ${net2_string[1]}
    [Return]    @{final_list}

Capture Flows  
    [Arguments]    ${conn_id}    ${BR_NAME}    ${cmd}
    [Documentation]    Capture flows
    Switch Connection    ${conn_id}
    ${output}     Execute Command    ${cmd}
    Log    ${output}

Get Packetcount
    [Arguments]    ${conn_id}    ${BR_NAME}    ${TABLE_NO}    ${conn_state}
    [Documentation]    Capture flows
    Switch Connection    ${conn_id}
    ${output}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${BR_NAME} | grep ${TABLE_NO} | grep ${conn_state}  
    @{output_list}    Split String    ${output}    \r\n
    ${flow}    Get From List    ${output_list}     0 
    ${packetcount_list}    Get Regexp Matches    ${flow}    n_packets=([0-9]+)     1 
    ${count}    Get From List    ${packetcount_list}    0
    [Return]    ${count}

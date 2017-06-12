*** Settings ***
Documentation     Test suite for IPV6 addr assignment and dual stack testing
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           Collections
Resource          Utils.robot
Resource          OpenStackOperations.robot
Resource          DevstackUtils.robot
Resource          Genius.robot
Resource          ../variables/Variables.robot

*** Variables ***
${br_name1}       br-int
${Bridge-1}       br0
${Bridge-2}       br0
${Interface-1}    eth1
${Interface-2}    eth1

*** Keywords ***
Virsh Login
    [Arguments]    ${virshid}    ${user}=cirros    ${pwd}=cubswin:)    ${vm_prompt}=$
    [Documentation]    Logging in to virsh console
    Write Commands Until Expected Prompt    virsh console ${virshid}    ^]    30
    Write Commands Until Expected Prompt    \r    login:    30
    Write Commands Until Expected Prompt    ${user}    Password:    30
    Write Commands Until Expected Prompt    ${pwd}    ${vm_prompt}    30

Virsh Exit
    [Documentation]    Virsh console exit
    Write Commands Until Expected Prompt    exit    login:    30
    ${ctrl_char}    Evaluate    chr(int(29))
    Write Bare    ${ctrl_char}

Get Vm Instance
    [Arguments]    ${vm_name}
    [Documentation]    Getting the vm instance id wrt the instance name
    ${instance_name}    Write Commands Until Expected Prompt    nova show ${vm_name} | grep OS-EXT-SRV-ATTR:instance_name | awk '{print$4}'    $    60
    [Return]    ${instance_name}

Spawn Vm
    [Arguments]    ${net_name}    ${vm_name}    ${image_name}    ${host_name}    ${flavor_name}    ${additional_args}=${EMPTY}
    [Documentation]    Creating VM instance
    ${vm_spawn}    Write Commands Until Expected Prompt    nova boot --flavor ${flavor_name} --image ${image_name} ${vm_name} --availability-zone nova:${host_name} --nic net-name=${net_name} ${additional_args}    $    420
    should contain    ${vm_spawn}    ${vm_name}
    Wait Until Keyword Succeeds    900 sec    10 sec    Verify Vm Creation    ${vm_name}

Get Vm Ipv6 Addr
    [Arguments]    ${vm_name}    ${network_name}
    [Documentation]    Getting the ipv6 address from VM
    ${op}    Write Commands Until Expected Prompt    nova list | grep ${vm_name}    $    30
    ${m}=    Get Regexp Matches    ${op}    ${network_name}=(\.\*)    1
    ${elem1}    Get From List    ${m}    0
    ${ip1}    Get Substring    ${elem1}    \    -2
    ${ip}=    Strip String    ${ip1}
    [Return]    ${ip}

Virsh Output
    [Arguments]    ${virshid1}    ${cmd}    ${ComputeNode_1}    ${ComputeNode_2}    ${Os_User}    ${stack_System_Password}
    ...    ${Stack_Deploy_Path}    ${user}=cirros    ${pwd}=cubswin:)    ${vm_prompt}=$
    [Documentation]    Executing commands on virsh console and getting the return value
    Write Commands Until Expected Prompt    virsh console ${virshid1}    ^]    60
    Write Commands Until Expected Prompt    \r    login:    300
    Write Commands Until Expected Prompt    ${user}    Password:    300
    Write Commands Until Expected Prompt    ${pwd}    ${vm_prompt}    30
    ${output}    Write Commands Until Expected Prompt    ${cmd}    ${vm_prompt}    30
    Write Commands Until Expected Prompt    exit    login:    30
    ${ctrl_char}    Evaluate    chr(int(29))
    Write Bare    ${ctrl_char}
    ${pwd_output}    Write Commands Until Expected Prompt    pwd    $    30
    Close All Connections
    ${conn_id_1}    devstack login    ${ComputeNode_1}    ${Os_User}    ${stack_System_Password}    ${Stack_Deploy_Path}
    ${conn_id_2}    devstack login    ${ComputeNode_2}    ${Os_User}    ${stack_System_Password}    ${Stack_Deploy_Path}
    Set Global Variable    ${conn_id_1}
    Set Global Variable    ${conn_id_2}
    Switch Connection    ${conn_id_1}
    [Return]    ${output}

Extract_Mac_From_Ifconfig
    [Arguments]    ${output_ifconfig}    ${os}=cirros
    [Documentation]    Extracting the mac address from the ifconfig output . This keyword can be used for "cirros" or "ubuntu-sg" to fetch the ifconfig details.
    ${pattern}    Set Variable if    '${os}'=='cirros'    HWaddr \[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]\    ether [0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]\
    ${HWaddr_list}    Get Regexp Matches    ${output_ifconfig}    ${pattern}
    ${HWaddr}    Get From List    ${HWaddr_list}    0
    ${extract_mac}=    Get Substring    ${HWaddr}    -17
    [Return]    ${extract_mac}

Table 0 Check For VM Creation
    [Arguments]    ${br_name}    ${conn_id}    ${port}
    [Documentation]    Validating the flows in table=0
    Switch Connection    ${conn_id}
    ${cmd}=    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep table=0 | grep in_port=${port}
    Should Contain    ${cmd}    in_port=${port}
    ${metadatamatch}    Get Regexp Matches    ${cmd}    :0x(\.\*)/    1
    ${metavalue}    Get From List    ${metadatamatch}    0
    [Return]    ${metavalue}

Create Invalid IPV6 Subnet
    [Arguments]    ${network}    ${invalid_subnet}    ${subnet_value}
    [Documentation]    Checking by vreating invalid ipv6 subnet
    ${command}    Set Variable    neutron subnet-create ${network} ${subnet_value} --name ${invalid_subnet} --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    ${subnet}=    Write Commands Until Expected Prompt    ${command}    $    30
    Should Contain    ${subnet}    Invalid input for operation: Invalid CIDR

Get Dpn Ids For ITM
    [Arguments]    ${connection_id}    ${br_name}
    [Documentation]    This keyword gets the DPN id of the switch after configuring bridges on it.It returns the captured DPN id.
    Switch connection    ${connection_id}
    ${output1}    Execute command    sudo ovs-ofctl show -O Openflow13 ${br_name} | head -1 | awk -F "dpid:" '{ print $2 }'
    ${Dpn_id}    Execute command    echo \$\(\(16\#${output1}\)\)
    [Return]    ${Dpn_id}

Devstack Login
    [Arguments]    ${ip}    ${username}    ${password}    ${DEVSTACK_DEPLOY_PATH}
    [Documentation]    Devstack Login
    ${dev_stack_conn_id}    Open Connection    ${ip}
    set suite variable    ${dev_stack_conn_id}
    Login    ${username}    ${password}
    ${cd}    Write Commands Until Expected Prompt    cd ${DEVSTACK_DEPLOY_PATH}    $    30
    ${openrc}    Write Commands Until Expected Prompt    source openrc admin admin    $    30
    ${pwd}    Write Commands Until Expected Prompt    pwd    $    30
    [Return]    ${dev_stack_conn_id}

Get VM Ip Addresses From Instance Details
    [Arguments]    ${vm_name}    ${network}
    [Documentation]    Fetching the ip details from \ vm instances \ for both the subnets.
    ${ip1_temp}=    Write Commands Until Expected Prompt    nova show ${vm_name} | grep ${network} | awk '{print$5}'    $    30
    ${templ1}    Split To Lines    ${ip1_temp}
    ${str1}=    Get From List    ${templ1}    0
    ${str1}=    Remove String    ${str1}    ,
    ${ip1}=    Strip String    ${str1}
    ${ip2_temp}    Write Commands Until Expected Prompt    nova show ${vm_name} | grep ${network} | awk '{print$6}'    $    30
    ${templ2}    Split To Lines    ${ip2_temp}
    ${str2}=    Get From List    ${templ2}    0
    ${str2}=    Remove String    ${str2}    ,
    ${ip2}=    Strip String    ${str2}
    Should Not Contain    ${ip2}    |
    @{lst}    Create List    ${ip1}    ${ip2}
    [Return]    ${lst}

Get Network Specific Ip Address
    [Arguments]    ${vm_name}    ${network}
    ${ip1_temp}=    Write Commands Until Expected Prompt    nova show ${vm_name} | grep ${network} | awk '{print$5}'    $    30
    ${templ1}    Split To Lines    ${ip1_temp}
    ${str1}=    Get From List    ${templ1}    0
    ${ip1}=    Strip String    ${str1}
    [Return]    ${ip1}

Check Ip On Vm
    [Arguments]    ${conn_id}    ${virshid}    ${cmd}    ${target_ip}
    ${output1}    Virsh Output    ${conn_id}    ${virshid}    ${cmd}
    Should Contain    ${output1}    ${target_ip}

Table 0 Check
    [Arguments]    ${br_name}    ${conn_id}    ${port}
    [Documentation]    Validating the flows in table=0
    Switch Connection    ${conn_id}
    ${cmd}=    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep table=0 | grep in_port=${port}
    Should Contain    ${cmd}    in_port=${port}
    ${metadatamatch}    Get Regexp Matches    ${cmd}    :0x(\.\*)/    1
    ${metavalue}    Get From List    ${metadatamatch}    0
    [Return]    ${metavalue}

Get In Port Number For VM
    [Arguments]    ${br_name}    ${pid}
    [Documentation]    This keyword fetch the in port number for VM by using mac address.
    ${num}    Write Commands Until Expected Prompt    sudo ovs-ofctl -O OpenFlow13 show ${br_name} | grep ${pid} |awk '{print$1}'    $    30
    @{portNum}    Get Regexp Matches    ${num}    [0-9]+
    ${port_number}    Set Variable    ${portNum[0]}
    [Return]    ${port_number}

Ping From Virsh Console
    [Arguments]    ${virshid}    ${dest_ip}    ${connection_id}    ${string_tobe_verified}    ${user}=cirros    ${pwd}=cubswin:)
    ...    ${vm_prompt}=$
    [Documentation]    Login to virsh console and ping the destination IP
    Switch Connection    ${connection_id}
    Write Commands Until Expected Prompt    virsh console ${virshid}    ^]    30
    Write Commands Until Expected Prompt    \r    login:    30
    Write Commands Until Expected Prompt    ${user}    Password:    30
    Write Commands Until Expected Prompt    ${pwd}    ${vm_prompt}    30
    ${output}=    Write Commands Until Expected Prompt    ping -c 5 ${dest_ip}    ${vm_prompt}
    Write Commands Until Expected Prompt    exit    login:    30
    ${ctrl_char}    Evaluate    chr(int(29))
    Write Bare    ${ctrl_char}
    ${pwd_output}    Write Commands Until Expected Prompt    pwd    $    30
    Should Contain    ${output}    ${string_tobe_verified}

Extract Linklocal Addr
    [Arguments]    ${ifconfigoutput}    ${os}=cirros
    [Documentation]    Extracting link local address
    ${str}    Set Variable If    '${os}'=='cirros'    Scope:Link    <link>
    ${output}    Get Lines Containing String    ${ifconfigoutput}    ${str}
    ${linklocaliplist}    Get Regexp Matches    ${output}    [0-9a-f]+::[0-9a-f]+:[0-9a-f]+:[0-9a-f]+:[0-9a-f]+
    ${link_addr}    Get From List    ${linklocaliplist}    0
    [Return]    ${link_addr}

Get Packetcount
    [Arguments]    ${br_name}    ${conn_id}    ${table_no}    ${conn_state}
    [Documentation]    Getting Packet count
    Switch Connection    ${conn_id}
    ${cmd}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table_no} | grep ${conn_state}
    @{cmdoutput}    Split String    ${cmd}    \r\n
    ${flow}    get from list    ${cmdoutput}    0
    ${packetcountlist}    Get Regexp Matches    ${flow}    n_packets=([0-9]+),    1
    ${packetcount}    Get From List    ${packetcountlist}    0
    [Return]    ${packetcount}

Table Check
    [Arguments]    ${connection_id}    ${br_name}    ${table_cmdSuffix}    ${validation_list}
    [Documentation]    Filtering the flows based on the \ argument and flowtable id.
    Switch Connection    ${connection_id}
    ${cmd}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table_cmdSuffix}
    : FOR    ${elem}    IN    @{validation_list}
    \    Should Contain    ${cmd}    ${elem}

Get Port Id of instance
    [Arguments]    ${mac}    ${conn_id}
    [Documentation]    Getting port id of instance by using mac address.
    Switch Connection    ${conn_id}
    ${mac_lower}=    Convert To Lowercase    ${mac}
    ${port_id_command}    Write Commands Until Expected Prompt    neutron port-list | grep '${mac_lower}' | awk '{print$2}'    $    30
    @{port_array}    Split String    ${port_id_command}    -
    ${first_set}    get from list    ${port_array}    0
    ${second_set}    get from list    ${port_array}    1
    ${sub_str}    Get Substring    ${second_set}    0    2
    ${id}    catenate    ${first_set}-${sub_str}
    [Return]    ${id}

Get Neutron Port
    [Arguments]    ${mac}    ${conn_id}
    [Documentation]    Getting neutron port id
    Switch Connection    ${conn_id}
    ${mac_lower}=    Convert To Lowercase    ${mac}
    sleep    10
    ${op}    Write Commands Until Expected Prompt    neutron port-list | grep '${mac_lower}' | awk '{print$2}'    $    30
    ${templ1}    Split To Lines    ${op}
    ${str1}=    Get From List    ${templ1}    0
    ${id}=    Strip String    ${str1}
    [Return]    ${id}

Get ITM
    [Arguments]    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${ip1}    ${Dpn_id_2}
    ...    ${ip2}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    @{Itm-no-vlan}    Create List    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${ip1}
    ...    ${Dpn_id_2}    ${ip2}
    Check For Elements At URI    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}    ${Itm-no-vlan}

Create ITM Tunnel
    [Documentation]    Creating ITM tunnel
    Switch Connection    ${conn_id_1}
    Write Commands Until Expected Prompt    sudo ovs-vsctl del-br ${Bridge-1}    $    10
    Write Commands Until Expected Prompt    sudo ovs-vsctl add-br ${Bridge-1}    $    10
    Write Commands Until Expected Prompt    sudo ovs-vsctl add-port ${Bridge-1} ${Interface-1}    $    10
    Write Commands Until Expected Prompt    sudo ifconfig ${Bridge-1} \ ${dpip[0]}/24 up    $    10
    Switch Connection    ${conn_id_2}
    Write Commands Until Expected Prompt    sudo ovs-vsctl del-br ${Bridge-1}    $    10
    Write Commands Until Expected Prompt    sudo ovs-vsctl add-br ${Bridge-1}    $    10
    Write Commands Until Expected Prompt    sudo ovs-vsctl add-port ${Bridge-1} ${Interface-2}    $    10
    Write Commands Until Expected Prompt    sudo ifconfig ${Bridge-1} \ ${dpip[1]}/24 up    $    10
    ${Dpn_id_1}    Get Dpn Ids For ITM    ${conn_id_1}    ${br_name1}
    ${Dpn_id_2}    Get Dpn Ids For ITM    ${conn_id_2}    ${br_name1}
    Set Global Variable    ${Dpn_id_1}
    Set Global Variable    ${Dpn_id_2}
    ${vlan}=    Set Variable    0
    ${gateway-ip}    Set Variable    0.0.0.0
    ${ip1}    Set Variable    ${dpip[0]}
    ${ip2}    Set Variable    ${dpip[1]}
    Create Vteps    ${ip1}    ${ip2}    ${vlan}    ${gateway-ip}
    Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${subnet}    ${vlan}
    ...    ${Dpn_id_1}    ${ip1}    ${Dpn_id_2}    ${ip2}

Verify Vm Creation
    [Arguments]    ${vm_name}
    [Documentation]    Verify after VM creation.
    ${novaverify}    Write Commands Until Expected Prompt    nova list | grep ${vm_name}    $    60
    Should Contain    ${novaverify}    ACTIVE
    Should Contain    ${novaverify}    Running

Get Ip List Specific To Prefixes
    [Arguments]    ${vm_name}    ${network_name}    ${prefix1}    ${prefix2}
    [Documentation]    Getting the prefixes based on the ip list.
    ${op}    Write Commands Until Expected Prompt    nova list | grep ${vm_name}    $    20
    Should Contain    ${op}    ${prefix1}
    Should Contain    ${op}    ${prefix2}
    ${match}    Get Regexp Matches    ${op}    ${network_name}=(\.\*)    1
    @{temp_list}    Split String    ${match[0]}    ,
    @{ip_list}    Create List
    : FOR    ${i}    IN    @{temp_list}
    \    ${check}    Check Substring    ${i}    ${prefix1}
    \    ${ip}    Remove String    ${i}    |
    \    ${ip}    Strip String    ${ip}
    \    Run Keyword If    '${check}'=='True'    Append To List    ${ip_list}    ${ip}
    \    ${check}    Check Substring    ${i}    ${prefix2}
    \    ${ip}    Remove String    ${i}    |
    \    ${ip}    Strip String    ${ip}
    \    Run Keyword If    '${check}'=='True'    Append To List    ${ip_list}    ${ip}
    ${EMPTY}
    ${EMPTY}
    ${EMPTY}
    [Return]    ${ip_list}

Check Substring
    [Arguments]    ${s1}    ${s2}
    [Documentation]    Checking the substring
    ${match}    Get Regexp Matches    ${s1}    (${s2})    1
    ${len}    Get Length    ${match}
    ${status}    Set Variable If    ${len}>0    True    False
    [Return]    ${status}

Get Subnet Specific Ipv6
    [Arguments]    ${ip_list}    ${prefix}
    [Documentation]    Get subnet specific ipv6
    ${prefix}    Remove String    ${prefix}    ::/64
    ${check}    Check Substring    ${ip_list[0]}    ${prefix}
    ${ip}    Set Variable If    '${check}'=='True'    ${ip_list[0]}    ${ip_list[1]}
    [Return]    ${ip}

Verify Vm Deletion
    [Arguments]    ${vm}    ${mac}    ${conn_id}    ${br_name}
    [Documentation]    Verify after VM deletion.
    ${vm_list}    List Nova VMs
    Should Not Contain    ${vm_list}    ${vm}
    Switch Connection    ${conn_id}
    ${cmd}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep table=40
    ${lower_mac}    Convert To Lowercase    ${mac}
    Should Not Contain    ${cmd}    ${lower_mac}

Fetch Topology Details
    [Arguments]    ${conn_id_1}    ${conn_id_2}    ${vm1}    ${vm2}    ${vm5}
    [Documentation]    Fetching topology details.
    Switch Connection    ${conn_id_1}
    ${hostname1}    Get Vm Hostname    ${conn_id_1}
    Set Global Variable    ${hostname1}
    Switch Connection    ${conn_id_2}
    ${hostname2}    Get Vm Hostname    ${conn_id_2}
    Set Global Variable    ${hostname2}
    Switch Connection    ${conn_id_1}
    ${virshid1}    Get Vm Instance    ${vm1}
    ${virshid2}    Get Vm Instance    ${vm2}
    Set Global Variable    ${virshid1}
    Set Global Variable    ${virshid2}
    ${ip_list1}    Wait Until Keyword Succeeds    50 sec    10 sec    Get VM Ip Addresses From Instance Details    ${vm1}    ${Networks[0]}
    ${ip_list2}    Wait Until Keyword Succeeds    50 sec    10 sec    Get VM Ip Addresses From Instance Details    ${vm2}    ${Networks[0]}
    Set Global Variable    ${ip_list1}
    Set Global Variable    ${ip_list2}
    ${output1}    Virsh Output    ${virshid1}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}
    ...    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)    $
    ${linkaddr1}    Extract Linklocal Addr    ${output1}
    Set Global Variable    ${linkaddr1}
    ${output2}    Virsh Output    ${virshid2}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}
    ...    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)    $
    ${linkaddr2}    Extract Linklocal Addr    ${output2}
    Set Global Variable    ${linkaddr2}
    ${prefixstr1} =    Remove String    ${Prefixes[0]}    ::
    ${prefixstr2} =    Remove String    ${Prefixes[1]}    ::
    Should Contain    ${output1}    ${prefixstr1}
    Should Contain    ${output1}    ${prefixstr2}
    Should Contain    ${output2}    ${prefixstr1}
    Should Contain    ${output2}    ${prefixstr2}
    Set Global Variable    ${ip_list1[0]}
    Set Global Variable    ${ip_list1[1]}
    Set Global Variable    ${ip_list2[0]}
    Set Global Variable    ${ip_list2[1]}
    Should Contain    ${output1}    ${ip_list1[0]}
    Should Contain    ${output1}    ${ip_list1[1]}
    Should Contain    ${output2}    ${ip_list2[0]}
    Should Contain    ${output2}    ${ip_list2[1]}
    ${mac1}    Extract_Mac_From_Ifconfig    ${output1}
    ${port_id1}    Get Port Id of instance    ${mac1}    ${conn_id_1}
    ${port1}    Get In Port Number For VM    ${br_name1}    ${port_id1}
    Set Global Variable    ${mac1}
    Set Global Variable    ${port1}
    ${mac2}    Extract_Mac_From_Ifconfig    ${output2}
    ${port_id2}    Get Port Id of instance    ${mac2}    ${conn_id_1}
    ${port2}    Get In Port Number For VM    ${br_name1}    ${port_id2}
    Set Global Variable    ${mac2}
    Set Global Variable    ${port2}
    ${virshid5}    Get Vm Instance    ${vm5}
    Set Global Variable    ${virshid5}
    ${ip_list5}    Wait Until Keyword Succeeds    5 min    10 sec    Get VM Ip Addresses From Instance Details    ${vm5}    ${Networks[0]}
    Set Global Variable    ${ip_list5}
    Switch Connection    ${conn_id_2}
    ${output5}    Virsh Output    ${virshid5}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}
    ...    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)    $
    ${linkaddr5}    Extract Linklocal Addr    ${output5}
    Set Global Variable    ${linkaddr5}
    Should Contain    ${output5}    ${ip_list5[0]}
    Should Contain    ${output5}    ${ip_list5[1]}
    ${mac5}    Extract_Mac_From_Ifconfig    ${output5}
    ${port_id5}    Get Port Id of instance    ${mac5}    ${conn_id_2}
    ${port5}    Get In Port Number For VM    ${br_name1}    ${port_id5}
    Set Global Variable    ${mac5}
    Set Global Variable    ${port5}
    Switch Connection    ${conn_id_1}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name1}
    ${metadata1}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${br_name1}    ${conn_id_1}
    ...    ${port1}
    Set Global Variable    ${metadata1}
    ${metadata5}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${br_name1}    ${conn_id_2}
    ...    ${port5}
    Set Global Variable    ${metadata5}
    Switch Connection    ${conn_id_1}

Verify Remote IP On DPN
    [Arguments]    ${conn_id}    ${remoteip_list}    ${pmt}=$
    [Documentation]    Verify ovs installation.
    Switch Connection    ${conn_id}
    ${output}    Write Commands Until Expected Prompt    sudo ovs-vsctl show    ${pmt}    30
    : FOR    ${elem}    IN    @{remoteip_list}
    \    Should Contain    ${output}    ${elem}

Ssh Connection Check
    [Arguments]    ${virshid1}    ${dest_ip}    ${src_ip}    ${compute_1_conn_id}    ${compute_2_conn_id}    ${string_tobe_verified}
    [Documentation]    SSH Connection check
    Switch Connection    ${compute_1_conn_id}
    Write Commands Until Expected Prompt    virsh console ${virshid1}    ^]    30
    Write Commands Until Expected Prompt    \r    login:    30
    Write Commands Until Expected Prompt    cirros    Password:    30
    Write Commands Until Expected Prompt    cubswin:)    $    30
    ${output}    Write Commands Until Expected Prompt    ssh -y ${dest_ip}    password:    30
    Write Commands Until Expected Prompt    cubswin:)    $    30
    ${output}    Write Commands Until Expected Prompt    ping -c 5 ${src_ip}    $
    Write Commands Until Expected Prompt    exit    $    30
    Virsh Exit
    ${pwd_output}    Write Commands Until Expected Prompt    pwd    $    30
    Should Contain    ${output}    ${string_tobe_verified}

Send Traffic Using Netcat
    [Arguments]    ${virshid1}    ${virshid2}    ${vm1_ip}    ${vm2_ip}    ${compute_1_conn_id}    ${compute_2_conn_id}
    ...    ${port_no}    ${verify_string}    ${protocol}=udp
    [Documentation]    Send traffic using netcat using the protocols tcp6/udp6
    ${proto_arg}    Set Variable If    '${protocol}'=='udp'    nc -u    nc
    Switch Connection    ${compute_1_conn_id}
    Virsh Login    ${virshid1}
    Write Until Expected Output    ${proto_arg} -s ${vm1_ip} -l -p ${port_no} -v\r    expected=listening    timeout=5s    retry_interval=1s
    Switch Connection    ${compute_2_conn_id}
    Virsh Login    ${virshid2}
    Write Until Expected Output    ${proto_arg} ${vm1_ip} ${port_no} -v\r    expected=open    timeout=5s    retry_interval=1s
    Write    ${verify_string}
    Write    ${verify_string}
    Write    ${verify_string}
    Write    ${verify_string}
    Write_Bare_Ctrl_C
    Virsh Exit
    Switch Connection    ${compute_1_conn_id}
    ${cmdoutput}    Read
    Write_Bare_Ctrl_C
    Virsh Exit
    Should Contain    ${cmdoutput}    ${verify_string}

Create SG Rule IPV6
    [Arguments]    ${direction}    ${protocol}    ${min_port}    ${max_port}    ${ether_type}    ${sg_name}
    ...    ${remote_param}    ${remote_type}=prefix
    [Documentation]    Create IPv6 SG rule
    ${cmd}    Set Variable If    '${remote_type}'=='SG'    neutron security-group-rule-create --direction ${direction} --ethertype ${ether_type} --protocol ${protocol} --port-range-min ${min_port} --port-range-max ${max_port} --remote-group-id ${remote_param} ${sg_name}    neutron security-group-rule-create --direction ${direction} --ethertype ${ether_type} --protocol ${protocol} --port-range-min ${min_port} --port-range-max ${max_port} --remote-ip-prefix ${remote_param} ${sg_name}
    ${output}=    Write Commands Until Expected Prompt    ${cmd}    $    10

Data Store Validation With Remote Prefix
    [Arguments]    ${port_id}    ${prefix}
    [Documentation]    Data store validation with remote prefix.
    ${op}    Write Commands Until Expected Prompt    neutron port-show ${port_id} | grep security_groups | awk '{print$4}'    $    30
    ${templ1}    Split To Lines    ${op}
    ${str1}    Get From List    ${templ1}    0
    ${sg_id}    Strip String    ${str1}
    ${json}    Get Data From URI    session    /restconf/config/neutron:neutron/security-rules/
    ${object}    Evaluate    json.loads('''${json}''')    json
    ${obj1}    Set Variable    ${object["security-rules"]["security-rule"]}
    : FOR    ${i}    IN    @{obj1}
    \    Run Keyword If    '${i["security-group-id"]}'=='${sg_id}'    Should Be Equal    ${prefix}    ${i["remote-ip-prefix"]}
    ${EMPTY}
    ${EMPTY}

Table Check With Negative Scenario
    [Arguments]    ${connection_id}    ${br_name}    ${table_cmdSuffix}    ${validation_list}
    [Documentation]    Filtering the flows based on the \ argument and flowtable id for negative testing.
    ${cmd}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table_cmdSuffix}
    : FOR    ${elem}    IN    @{validation_list}
    \    Should Not Contain    ${cmd}    ${elem}

Get Security Group Id
    [Arguments]    ${sg}    ${network}
    [Documentation]    Getting security group id.
    ${cmd}    Write Commands Until Expected Prompt    neutron net-show ${network} | grep tenant_id | awk '{print$4}'    $    30
    ${templ1}    Split To Lines    ${cmd}
    ${str1}    Get From List    ${templ1}    0
    ${tenantid}    Strip String    ${str1}
    ${op}    Write Commands Until Expected Prompt    neutron security-group-list | grep ${sg} | awk '{print$2}'    $    30
    ${templ1}    Split To Lines    ${op}
    ${str1}    Get From List    ${templ1}    0
    ${id}    Strip String    ${str1}
    [Return]    ${id}

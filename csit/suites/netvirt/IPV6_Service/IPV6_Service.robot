*** Settings ***
Documentation     Test suite for IPV6 addr assignment and dual stack testing
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           Collections
Library           re
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot

*** Variables ***
@{Networks}       mynet1    mynet2
@{Subnets}        ipv6s1    ipv6s2    ipv6s3    ipv6s4
@{Net_ips}        30.1.1.0/24    31.1.1.0/24    32.1.1.0/24
@{VM_list}        vm1    vm2    vm3    vm4    vm5    vm6    vm7
@{Routers}        router1    router2
@{Prefixes}       2001:db8:1234::    2001:db8:5678::    2001:db8:4321::    2001:db8:6789::
@{V4subnets}      13.0.0.0    14.0.0.0
@{V4subnet_names}    subnet1v4    subnet2v4
${ipv6securitygroups_config_dir}    ${CURDIR}/../../variables/ipv6securitygroups
${br_name1}       br-int
@{login_credentials}    stack    stack    root    password
${devstack_path}    /opt/stack/devstack
@{image_name}     cirros-0.3.4-x86_64-uec    ubuntu-sg
${br_name1}       br-int
${netvirt_config_dir}    ${CURDIR}/../../../variables/netvirt
@{itm_created}    TZA
${Bridge-1}       br0
${Bridge-2}       br0
@{dpip}           20.0.0.9    20.0.0.10
${Interface-1}    eth1
${Interface-2}    eth1

*** Test Cases ***
IPV6_Multiple_DPN_Validate multiple IPv6 address assignment to Neutron VMs on same interface after booting up with IPv6 configuration mode as SLAAC
    [Documentation]    Validate multiple IPv6 address assignment to Neutron VMs on same interface after booting up with IPv6 configuration mode as SLAAC
    Switch Connection    ${conn_id_1}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name1}
    log    ${flowdump}
    Create Topology    ${image_name[0]}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name1}
    log    ${flowdump}
    Log    >>>table 0 check>>>
    ${metadatavalue1}    Wait Until Keyword Succeeds    30 sec    10 sec    table 0 check    ${br_name1}    ${conn_id_1}
    ...    ${port1}
    ${metadatavalue2}    Wait Until Keyword Succeeds    30 sec    10 sec    table 0 check    ${br_name1}    ${conn_id_1}
    ...    ${port2}
    ${lower_mac1}    Convert To Lowercase    ${mac1}
    Log    >>>Create a list for table 17 for validation-vm1>>>
    @{array}    Create List    goto_table:45
    table check    ${conn_id_1}    ${br_name1}    table=17|grep ${metadatavalue1}    ${array}
    Log    >>>table 45 check-vm1>>>
    @{array}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[0]}1
    table check    ${conn_id_1}    ${br_name1}    table=45|grep actions=CONTROLLER:65535    ${array}
    Log    >>>table 50 check-vm1>>>
    @{array}    create list    dl_src=${lower_mac1}
    table check    ${conn_id_1}    ${br_name1}    table=50    ${array}
    Log    >>>table 51 check-vm1>>>
    @{array}    create list    dl_dst=${lower_mac1}
    table check    ${conn_id_1}    ${br_name1}    table=51    ${array}
    Log    >>>table 251 check for vm1>>>
    @{array}    Create List    table=252    ${ip_list1[0]}    ${ip_list1[1]}    ${linkaddr1}
    table check    ${conn_id_1}    ${br_name1}    table=251| grep ${lower_mac1}    ${array}
    ${lower_mac2}    Convert To Lowercase    ${mac2}
    Log    >>>Create a list for table 17 for validation-vm2>>>
    @{array}    Create List    goto_table:45
    table check    ${conn_id_1}    ${br_name1}    table=17|grep ${metadatavalue2}    ${array}
    Log    >>>table 45 check-vm2>>>
    @{array}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[0]}1
    table check    ${conn_id_1}    ${br_name1}    table=45|grep actions=CONTROLLER:65535    ${array}
    Log    >>>table 50 check-vm2>>>
    @{array}    create list    dl_src=${lower_mac2}
    table check    ${conn_id_1}    ${br_name1}    table=50    ${array}
    Log    >>>table 51 check-vm2>>>
    @{array}    create list    dl_dst=${lower_mac2}
    table check    ${conn_id_1}    ${br_name1}    table=51    ${array}
    Log    >>>table 251 check for vm2>>>
    @{array}    Create List    table=252    ${ip_list2[0]}    ${ip_list2[1]}    ${linkaddr2}
    table check    ${conn_id_1}    ${br_name1}    table=251| grep ${lower_mac2}    ${array}

IPV6_Single_DPN_Validate Ipv4 and IPv6 address assignment to Neutron VMs on same interface after booting up with IPv6 configuration mode as SLAAC
    [Documentation]    Validate Ipv4 and IPv6 address assignment to Neutron VMs on same interface after booting up with IPv6 configuration mode as SLAAC
    Create Network    ${Networks[1]}
    Create Subnet    ${Networks[1]}    ${Subnets[2]}    ${Prefixes[2]}/64    --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    Create Subnet    ${Networks[1]}    ${V4subnet_names[0]}    ${V4subnets[0]}/24    --enable-dhcp
    Add Router Interface    ${Routers[0]}    ${Subnets[2]}
    Remove All Elements If Exist    /restconf/config/dhcpservice-config:dhcpservice-config/
    Post Elements To URI From File    /restconf/config/    ${netvirt_config_dir}/enable_dhcp.json
    @{list}=    Create List    "controller-dhcp-enabled"    true
    Check For Elements At URI    /restconf/config/dhcpservice-config:dhcpservice-config/    ${list}
    Switch Connection    ${conn_id_1}
    spawn vm    ${Networks[1]}    ${VM_list[2]}    ${image_name[0]}    ${hostname1}    m1.tiny
    ${virshid3}    get Vm instance    ${VM_list[2]}
    Set Global Variable    ${virshid3}
    ${prefixstr1}    Remove String    ${Prefixes[2]}    ::
    ${v4prefix}    Get Substring    ${V4subnets[0]}    \    -1
    ${ip_list3}    Wait Until Keyword Succeeds    50 sec    10 sec    get ip list specific to prefixes    ${VM_list[2]}    ${Networks[1]}
    ...    ${prefixstr1}    ${v4prefix}
    Set Global Variable    ${ip_list3}
    ${output3}    Wait Until Keyword Succeeds    60 sec    20 sec    virsh_output    ${virshid3}    ifconfig eth0
    log    ${output3}
    ${linkaddr3}    extract linklocal addr    ${output3}
    Set Global Variable    ${linkaddr3}
    Should Contain    ${output3}    ${ip_list3[0]}
    Should Contain    ${output3}    ${ip_list3[1]}
    Set Global Variable    ${ip_list3[0]}
    Set Global Variable    ${ip_list3[1]}
    ${mac3}    extract mac    ${output3}
    ${port_id3}    get port id    ${mac3}    ${conn_id_1}
    ${port3}    get port number    ${br_name1}    ${port_id3}
    log    ${port3}
    Set Global Variable    ${mac3}
    Set Global Variable    ${port3}
    Log    >>>table 0 check>>>
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    table 0 check    ${br_name1}    ${conn_id_1}
    ...    ${port3}
    Log    >>>Create a list for table 17 for validation-vm3>>>
    @{araay}    Create List    goto_table:45    goto_table:60
    table check    ${conn_id_1}    ${br_name1}    table=17|grep ${metadatavalue3}    ${araay}
    Log    >>>table 45 check-vm3>>>
    @{araay}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1
    table check    ${conn_id_1}    ${br_name1}    table=45|grep actions=CONTROLLER:65535    ${araay}
    Log    >>>table 50 check-vm3>>>
    ${lower_mac3}    Convert To Lowercase    ${mac3}
    @{araay}    create list    dl_src=${lower_mac3}
    table check    ${conn_id_1}    ${br_name1}    table=50    ${araay}
    Log    >>>table 51 check-vm3>>>
    @{araay}    create list    dl_dst=${lower_mac3}
    table check    ${conn_id_1}    ${br_name1}    table=51    ${araay}
    Log    >>>table 60 check-vm3>>>
    @{araay}    create list    dl_src=${lower_mac3}
    table check    ${conn_id_1}    ${br_name1}    table=60    ${araay}

IPV6_Multiple_DPN_Validate ping6 between VMs in different compute
    [Documentation]    Validate ping6 between VMs in different compute
    Switch Connection    ${conn_id_1}
    spawn vm    ${Networks[1]}    ${VM_list[3]}    ${image_name[0]}    ${hostname2}    m1.tiny
    ${virshid4}    get Vm instance    ${VM_list[3]}
    Set Global Variable    ${virshid4}
    ${prefixstr1}    Remove String    ${Prefixes[2]}    ::
    ${v4prefix}    Get Substring    ${V4subnets[0]}    \    -1
    ${ip_list4}    Wait Until Keyword Succeeds    50 sec    10 sec    get ip list specific to prefixes    ${VM_list[3]}    ${Networks[1]}
    ...    ${prefixstr1}    ${v4prefix}
    Set Global Variable    ${ip_list4}
    Switch Connection    ${conn_id_2}
    ${output4}    virsh_output    ${virshid4}    ifconfig eth0
    log    ${output4}
    ${linkaddr4}    extract linklocal addr    ${output4}
    Set Global Variable    ${linkaddr4}
    Should Contain    ${output4}    ${ip_list4[0]}
    Should Contain    ${output4}    ${ip_list4[1]}
    Set Global Variable    ${ip_list4[0]}
    Set Global Variable    ${ip_list4[1]}
    ${mac4}    extract mac    ${output4}
    ${port_id4}    get port id    ${mac4}    ${conn_id_2}
    ${port4}    get port number    ${br_name1}    ${port_id4}
    log    ${port4}
    Set Global Variable    ${mac4}
    Set Global Variable    ${port4}
    Log    >>>table 0 check>>>
    Switch Connection    ${conn_id_2}
    ${metadatavalue4}    Wait Until Keyword Succeeds    50 sec    10 sec    table 0 check    ${br_name1}    ${conn_id_2}
    ...    ${port4}
    Log    >>>Create a list for table 17 for validation-vm4>>>
    @{araay}    Create List    goto_table:45    goto_table:60
    table check    ${conn_id_2}    ${br_name1}    table=17|grep ${metadatavalue4}    ${araay}
    Log    >>>table 45 check-vm4>>>
    @{araay}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1
    table check    ${conn_id_2}    ${br_name1}    table=45|grep actions=CONTROLLER:65535    ${araay}
    Log    >>>table 50 check-vm4>>>
    ${lower_mac4}    Convert To Lowercase    ${mac4}
    @{araay}    create list    dl_src=${lower_mac4}
    table check    ${conn_id_2}    ${br_name1}    table=50    ${araay}
    Log    >>>table 51 check-vm4>>>
    @{araay}    create list    dl_dst=${lower_mac4}
    table check    ${conn_id_2}    ${br_name1}    table=51    ${araay}
    Log    >>>table 60 check-vm4>>>
    @{araay}    create list    dl_src=${lower_mac4}
    table check    ${conn_id_2}    ${br_name1}    table=60    ${araay}
    ping from virsh console    ${virshid3}    ${ip_list4[0]}    ${conn_id_1}    , 0% packet loss
    ping from virsh console    ${virshid3}    ${ip_list4[1]}    ${conn_id_1}    , 0% packet loss
    [Teardown]    Cleanup_after_UC1_P1

*** Keywords ***
virsh login
    [Arguments]    ${virshid}    ${user}=cirros    ${pwd}=cubswin:)    ${vm_prompt}=$
    [Documentation]    Logging in to virsh console
    Write Commands Until Expected Prompt    virsh console ${virshid}    ^]    30
    Write Commands Until Expected Prompt    \r    login:    30
    Write Commands Until Expected Prompt    ${user}    Password:    30
    Write Commands Until Expected Prompt    ${pwd}    ${vm_prompt}    30

virsh exit
    [Documentation]    Virsh console exit
    Write Commands Until Expected Prompt    exit    login:    30
    ${ctrl_char}    Evaluate    chr(int(29))
    Write Bare    ${ctrl_char}

get Vm instance
    [Arguments]    ${vm_name}
    [Documentation]    Getting the vm instance id wrt the instance name
    ${instance_name}    Write Commands Until Expected Prompt    nova show ${vm_name} | grep OS-EXT-SRV-ATTR:instance_name | awk '{print$4}'    $    60
    log    ${instance_name}
    [Return]    ${instance_name}

spawn vm
    [Arguments]    ${net_name}    ${vm_name}    ${image_name}    ${host_name}    ${flavor_name}    ${additional_args}=${EMPTY}
    [Documentation]    Creating VM instance
    log    ${vm_name},${net_name}
    ${vm_spawn}    Write Commands Until Expected Prompt    nova boot --flavor ${flavor_name} --image ${image_name} ${vm_name} --availability-zone nova:${host_name} --nic net-name=${net_name} ${additional_args}    $    420
    log    ${vm_spawn}
    should contain    ${vm_spawn}    ${vm_name}
    Wait Until Keyword Succeeds    900 sec    10 sec    verify vm creation    ${vm_name}

get vm ipv6 addr
    [Arguments]    ${vm_name}    ${network_name}
    [Documentation]    Getting the ipv6 address from VM
    ${op}    Write Commands Until Expected Prompt    nova list | grep ${vm_name}    $    30
    log    ${op}
    ${m}=    Get Regexp Matches    ${op}    ${network_name}=(\.\*)    1
    log    ${m}
    ${elem1}    Get From List    ${m}    0
    log    ${elem1}
    ${ip1}    Get Substring    ${elem1}    \    -2
    log    ${ip1}
    ${ip}=    Strip String    ${ip1}
    log    ${ip}
    [Return]    ${ip}

virsh_output
    [Arguments]    ${virshid1}    ${cmd}    ${user}=cirros    ${pwd}=cubswin:)    ${vm_prompt}=$
    [Documentation]    Executing commands on virsh console and getting the return value
    Write Commands Until Expected Prompt    virsh console ${virshid1}    ^]    60
    Write Commands Until Expected Prompt    \r    login:    300
    Write Commands Until Expected Prompt    ${user}    Password:    300
    Write Commands Until Expected Prompt    ${pwd}    ${vm_prompt}    30
    ${output}    Write Commands Until Expected Prompt    ${cmd}    ${vm_prompt}    30
    log    ${output}
    Write Commands Until Expected Prompt    exit    login:    30
    ${ctrl_char}    Evaluate    chr(int(29))
    Write Bare    ${ctrl_char}
    ${pwd_output}    Write Commands Until Expected Prompt    pwd    $    30
    log    ${pwd_output}
    Close All Connections
    ${conn_id_1}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}
    Set Global Variable    ${conn_id_1}
    ${conn_id_2}    devstack login    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}
    Set Global Variable    ${conn_id_2}
    Switch Connection    ${conn_id_1}
    [Return]    ${output}

extract mac
    [Arguments]    ${op}    ${os}=cirros
    [Documentation]    Extracting the mac address
    ${pattern}    Set Variable if    '${os}'=='cirros'    HWaddr \[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]\    ether [0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]\
    ${m}    Get Regexp Matches    ${op}    ${pattern}
    log    ${m}
    ${x}    Get From List    ${m}    0
    log    ${x}
    ${mac}=    Get Substring    ${x}    -17
    log    ${mac}
    [Return]    ${mac}

table 0 check
    [Arguments]    ${br_name}    ${conn_id}    ${port}
    [Documentation]    Validating the flows in table=0
    Switch Connection    ${conn_id}
    ${cmd}=    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep table=0 | grep in_port=${port}
    log    ${cmd}
    Should Contain    ${cmd}    in_port=${port}
    ${metadatamatch}    Get Regexp Matches    ${cmd}    :0x(\.\*)/    1
    ${metavalue}    Get From List    ${metadatamatch}    0
    log    ${metavalue}
    [Return]    ${metavalue}

extract port
    [Arguments]    ${op}
    [Documentation]    Extracting the port identifier
    ${m}    Get Regexp Matches    ${op}    ([0-9]+)\.\*: addr    1
    log    ${m}
    ${port}    Get From List    ${m}    0
    log    ${port}
    [Return]    ${port}

reboot
    [Arguments]    ${virshid1}
    [Documentation]    Instance reboot
    Write Commands Until Expected Prompt    virsh console ${virshid1}    ^]    30
    Write Commands Until Expected Prompt    \r    login:    300
    Write Commands Until Expected Prompt    cirros    Password:    300
    Write Commands Until Expected Prompt    cubswin:)    $    30
    Write Commands Until Expected Prompt    virsh reboot ${virshid1}    $    30

invalid subnet
    [Arguments]    ${network}    ${invalid_subnet}
    [Documentation]    Checking \ Invalid subnet
    ${command}    Set Variable    neutron subnet-create ${network} 2001:db8:1234::/21 --name ${invalid_subnet} --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    ${subnet}=    Write Commands Until Expected Prompt    ${command}    $    30
    log    ${subnet}
    log    ${command}
    Should Contain    ${subnet}    Invalid input for operation: Invalid CIDR

dev_stack login
    [Arguments]    ${ip}    ${username}    ${password}    ${devstack_path}
    [Documentation]    Devstack Login
    ${dev_stack_conn_id}    Open Connection    ${ip}
    set suite variable    ${dev_stack_conn_id}
    Login    ${username}    ${password}
    ${cd}    Write Commands Until Expected Prompt    cd ${devstack_path}    $    30
    ${openrc}    Write Commands Until Expected Prompt    source openrc admin admin    $    30
    ${pwd}    Write Commands Until Expected Prompt    pwd    $    30
    log    ${pwd}
    [Return]    ${dev_stack_conn_id}

get both ip
    [Arguments]    ${vm_name}    ${network1}
    [Documentation]    Fetching the ip details from nova for both the subnets.
    ${ip1_temp}=    Write Commands Until Expected Prompt    nova show ${vm_name} | grep ${network1} | awk '{print$5}'    $    30
    log    ${ip1_temp}
    ${templ1}    Split To Lines    ${ip1_temp}
    ${str1}=    Get From List    ${templ1}    0
    ${str1}=    Remove String    ${str1}    ,
    ${ip1}=    Strip String    ${str1}
    log    ${ip1}
    ${ip2_temp}    Write Commands Until Expected Prompt    nova show ${vm_name} | grep ${network1} | awk '{print$6}'    $    30
    log    ${ip2_temp}
    ${templ2}    Split To Lines    ${ip2_temp}
    ${str2}=    Get From List    ${templ2}    0
    ${str2}=    Remove String    ${str2}    ,
    ${ip2}=    Strip String    ${str2}
    log    ${ip2}
    Should Not Contain    ${ip2}    |
    @{lst}    Create List    ${ip1}    ${ip2}
    [Return]    ${lst}

get port number
    [Arguments]    ${br_name}    ${pid}
    [Documentation]    Fetch the neutron port number.
    ${num}    Write Commands Until Expected Prompt    sudo ovs-ofctl -O OpenFlow13 show ${br_name} | grep ${pid} |awk '{print$1}'    $    30
    log    ${num}
    @{portNum}    Get Regexp Matches    ${num}    [0-9]+
    log    ${portNum}
    ${port_number}    Set Variable    ${portNum[0]}
    log    ${port_number}
    [Return]    ${port_number}

ping from virsh console
    [Arguments]    ${virshid}    ${dest_ip}    ${connection_id}    ${string_tobe_verified}    ${user}=cirros    ${pwd}=cubswin:)
    ...    ${vm_prompt}=$
    [Documentation]    Login to virsh console and ping the destination IP
    Switch Connection    ${connection_id}
    Write Commands Until Expected Prompt    virsh console ${virshid}    ^]    30
    Write Commands Until Expected Prompt    \r    login:    30
    Write Commands Until Expected Prompt    ${user}    Password:    30
    Write Commands Until Expected Prompt    ${pwd}    ${vm_prompt}    30
    ${output}=    Write Commands Until Expected Prompt    ping -c 5 ${dest_ip}    ${vm_prompt}
    Log    ${output}
    Write Commands Until Expected Prompt    exit    login:    30
    ${ctrl_char}    Evaluate    chr(int(29))
    Write Bare    ${ctrl_char}
    ${pwd_output}    Write Commands Until Expected Prompt    pwd    $    30
    log    ${pwd_output}
    Should Contain    ${output}    ${string_tobe_verified}

Create Topology
    [Arguments]    ${image}
    [Documentation]    Creating the Topology
    log    >>>creating ITM tunnel
    create ITM Tunnel
    Log    >>>> Creating Network <<<<
    Switch Connection    ${conn_id_1}
    Create Network    ${Networks[0]}
    Create Subnet    ${Networks[0]}    ${Subnets[0]}    ${Prefixes[0]}/64    --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    Create Subnet    ${Networks[0]}    ${Subnets[1]}    ${Prefixes[1]}/64    --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    Create Router    ${Routers[0]}
    Add Router Interface    ${Routers[0]}    ${Subnets[0]}
    @{prefixlist}    Create List    ${Prefixes[0]}
    sleep    30 sec
    Add Router Interface    ${Routers[0]}    ${Subnets[1]}
    @{prefixlist}    Create List    ${Prefixes[0]}    ${Prefixes[1]}
    sleep    30 sec
    ${hostname1}    get hostname    ${conn_id_1}
    Set Global Variable    ${hostname1}
    Switch Connection    ${conn_id_2}
    ${hostname2}    get hostname    ${conn_id_2}
    Set Global Variable    ${hostname2}
    Switch Connection    ${conn_id_1}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name1}
    log    ${flowdump}
    spawn vm    ${Networks[0]}    ${VM_list[0]}    ${image}    ${hostname1}    m1.tiny
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name1}
    log    ${flowdump}
    spawn vm    ${Networks[0]}    ${VM_list[1]}    ${image}    ${hostname1}    m1.tiny
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name1}
    log    ${flowdump}
    spawn vm    ${Networks[0]}    ${VM_list[4]}    ${image}    ${hostname2}    m1.tiny
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name1}
    log    ${flowdump}
    ${virshid1}    get Vm instance    ${VM_list[0]}
    ${virshid2}    get Vm instance    ${VM_list[1]}
    Set Global Variable    ${virshid1}
    Set Global Variable    ${virshid2}
    ${ip_list1}    Wait Until Keyword Succeeds    50 sec    10 sec    get both ip    ${VM_list[0]}    ${Networks[0]}
    ${ip_list2}    Wait Until Keyword Succeeds    50 sec    10 sec    get both ip    ${VM_list[1]}    ${Networks[0]}
    Set Global Variable    ${ip_list1}
    Set Global Variable    ${ip_list2}
    ${output1}    virsh_output    ${virshid1}    ifconfig eth0
    log    ${output1}
    ${linkaddr1}    extract linklocal addr    ${output1}
    Set Global Variable    ${linkaddr1}
    ${output2}    virsh_output    ${virshid2}    ifconfig eth0
    log    ${output2}
    ${linkaddr2}    extract linklocal addr    ${output2}
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
    ${mac1}    extract mac    ${output1}
    ${port_id1}    get port id    ${mac1}    ${conn_id_1}
    ${port1}    get port number    ${br_name1}    ${port_id1}
    Set Global Variable    ${mac1}
    log    ${port1}
    Set Global Variable    ${port1}
    ${mac2}    extract mac    ${output2}
    ${port_id2}    get port id    ${mac2}    ${conn_id_1}
    ${port2}    get port number    ${br_name1}    ${port_id2}
    Set Global Variable    ${mac2}
    log    ${port2}
    Set Global Variable    ${port2}
    ${virshid5}    get Vm instance    ${VM_list[4]}
    Set Global Variable    ${virshid5}
    ${ip_list5}    Wait Until Keyword Succeeds    2 min    10 sec    get both ip    ${VM_list[4]}    ${Networks[0]}
    Set Global Variable    ${ip_list5}
    Switch Connection    ${conn_id_2}
    ${output5}    virsh_output    ${virshid5}    ifconfig eth0
    log    ${output5}
    ${linkaddr5}    extract linklocal addr    ${output5}
    Set Global Variable    ${linkaddr5}
    Should Contain    ${output5}    ${ip_list5[0]}
    Should Contain    ${output5}    ${ip_list5[1]}
    ${mac5}    extract mac    ${output5}
    ${port_id5}    get port id    ${mac5}    ${conn_id_2}
    ${port5}    get port number    ${br_name1}    ${port_id5}
    Set Global Variable    ${mac5}
    log    ${port5}
    Set Global Variable    ${port5}
    Switch Connection    ${conn_id_1}

table 40 check
    [Arguments]    ${be_name}    ${conn_id}    ${ipv6_srcip1}    ${linkaddr}
    [Documentation]    Validating the flows in table=40
    Switch Connection    {conn_id}
    ${cmd}=    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep table=40 | grep ipv6_src
    log    ${cmd}
    Should Contain    ${cmd}    ${ipv6_srcip1}
    ${cmd}=    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep table=40
    Should Contain    ${cmd}=    ${linkaddr}
    Should Contain    ${cmd}=    goto_table

table 41 check
    [Arguments]    ${br_name}
    [Documentation]    Validating the flows in table=41
    ${cmd}=    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep table=41
    log    ${cmd}
    Should Contain    ${cmd}    table=41

table 251 check
    [Arguments]    ${br_name}    ${conn_id}    ${ipv6_dstip1}
    [Documentation]    Validating the flows in table=251
    ${cmd}=    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep table=251 | grep ipv6_dst
    log    ${cmd}
    Should Contain    ${cmd}    ${ipv6_dstip1}

extract linklocal addr
    [Arguments]    ${ifconfigoutput}    ${os}=cirros
    [Documentation]    Extracting link local address
    ${str}    Set Variable If    '${os}'=='cirros'    Scope:Link    <link>
    ${output1}    Get Lines Containing String    ${ifconfigoutput}    ${str}
    ${linklocaliplist}    Get Regexp Matches    ${output1}    [0-9a-f]+::[0-9a-f]+:[0-9a-f]+:[0-9a-f]+:[0-9a-f]+
    ${link_addr}    Get From List    ${linklocaliplist}    0
    [Return]    ${link_addr}

table 220 check
    [Arguments]    ${br_name}    ${conn_id}
    [Documentation]    Validating the flows in table=220
    Switch Connection    ${conn_id}
    ${cmd}=    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep table=220
    log    ${cmd}
    Should Contain    ${cmd}    goto_table:251

table check
    [Arguments]    ${connection_id}    ${br_name}    ${table_cmdSuffix}    ${validation_list}
    [Documentation]    Filtering the flows based on the \ argument and flowtable id.
    Switch Connection    ${connection_id}
    ${cmd}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table_cmdSuffix}
    Log    ${cmd}
    : FOR    ${elem}    IN    @{validation_list}
    \    Should Contain    ${cmd}    ${elem}

get hostname
    [Arguments]    ${conn_id}
    [Documentation]    Getting hostname of the VM
    Switch Connection    ${conn_id}
    ${hostname}    Write Commands Until Expected Prompt    hostname    $    30
    @{host}    Split String    ${hostname}    \r\n
    log    ${host}
    ${h}    get from list    ${host}    0
    [Return]    ${h}

get port id
    [Arguments]    ${mac}    ${conn_id}
    [Documentation]    Getting port id
    Switch Connection    ${conn_id}
    ${mac_lower}=    Convert To Lowercase    ${mac}
    ${port_id_command}    Write Commands Until Expected Prompt    neutron port-list | grep '${mac_lower}' | awk '{print$2}'    $    30
    @{port_array}    Split String    ${port_id_command}    -
    log    ${port_array}
    ${first_set}    get from list    ${port_array}    0
    ${second_set}    get from list    ${port_array}    1
    ${sub_str}    Get Substring    ${second_set}    0    2
    log    ${sub_str}
    ${id}    catenate    ${first_set}-${sub_str}
    log    ${id}
    [Return]    ${id}

get neutron port
    [Arguments]    ${mac}    ${conn_id}
    [Documentation]    Getting neutron port id
    Switch Connection    ${conn_id}
    ${mac_lower}=    Convert To Lowercase    ${mac}
    sleep    10
    ${op}    Write Commands Until Expected Prompt    neutron port-list | grep '${mac_lower}' | awk '{print$2}'    $    30
    log    ${op}
    ${templ1}    Split To Lines    ${op}
    ${str1}=    Get From List    ${templ1}    0
    ${id}=    Strip String    ${str1}
    [Return]    ${id}

Get Dpn Ids
    [Arguments]    ${connection_id}    ${br_name}
    [Documentation]    This keyword gets the DPN id of the switch after configuring bridges on it.It returns the captured DPN id.
    Switch connection    ${connection_id}
    ${output1}    Execute command    sudo ovs-ofctl show -O Openflow13 ${br_name} | head -1 | awk -F "dpid:" '{ print $2 }'
    log    ${output1}
    ${Dpn_id}    Execute command    echo \$\(\(16\#${output1}\)\)
    log    ${Dpn_id}
    [Return]    ${Dpn_id}

set json
    [Arguments]    ${ip1}    ${ip2}    ${vlan}    ${gateway-ip}    ${subnet}
    [Documentation]    Sets Json with the values passed for it.
    ${body}    OperatingSystem.Get File    ${netvirt_config_dir}/Itm_creation_no_vlan.json
    ${body}    replace string    ${body}    1.1.1.1    ${subnet}
    ${body}    replace string    ${body}    "dpn-id": 101    "dpn-id": ${Dpn_id_1}
    ${body}    replace string    ${body}    "dpn-id": 102    "dpn-id": ${Dpn_id_2}
    ${body}    replace string    ${body}    "ip-address": "2.2.2.2"    "ip-address": "${ip1}"
    ${body}    replace string    ${body}    "ip-address": "3.3.3.3"    "ip-address": "${ip2}"
    ${body}    replace string    ${body}    "vlan-id": 0    "vlan-id": ${vlan}
    ${body}    replace string    ${body}    "gateway-ip": "0.0.0.0"    "gateway-ip": "${gateway-ip}"
    Log    ${body}
    [Return]    ${body}    # returns complete json that has been updated

Create Vteps
    [Arguments]    ${ip1}    ${ip2}    ${vlan}    ${gateway-ip}
    [Documentation]    This keyword creates VTEPs between ${TOOLS_SYSTEM_IP} and ${TOOLS_SYSTEM_2_IP}
    Remove All Elements If Exist    /restconf/config/itm:transport-zones/transport-zone/${itm_created[0]}
    ${body}    OperatingSystem.Get File    ${netvirt_config_dir}/Itm_creation_no_vlan.json
    ${substr}    Should Match Regexp    ${ip1}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    Log    ${subnet}
    Set Global Variable    ${subnet}
    ${vlan}=    Set Variable    ${vlan}
    ${gateway-ip}=    Set Variable    ${gateway-ip}
    ${body}    set json    ${ip1}    ${ip2}    ${vlan}    ${gateway-ip}    ${subnet}
    ${resp}    RequestsLibrary.Post Request    session    ${CONFIG_API}/itm:transport-zones/    data=${body}
    Log    ${resp.content}
    Log    ${resp.status_code}
    should be equal as strings    ${resp.status_code}    204

Get ITM
    [Arguments]    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${ip1}    ${Dpn_id_2}
    ...    ${ip2}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    Log    ${itm_created[0]},${subnet}, ${vlan}, ${Dpn_id_1},${ip1}, ${Dpn_id_2}, ${ip2}
    @{Itm-no-vlan}    Create List    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${ip1}
    ...    ${Dpn_id_2}    ${ip2}
    Check For Elements At URI    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}    ${Itm-no-vlan}

create ITM Tunnel
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
    ${Dpn_id_1}    Get Dpn Ids    ${conn_id_1}    ${br_name1}
    ${Dpn_id_2}    Get Dpn Ids    ${conn_id_2}    ${br_name1}
    Set Global Variable    ${Dpn_id_1}
    Set Global Variable    ${Dpn_id_2}
    ${vlan}=    Set Variable    0
    ${gateway-ip}    Set Variable    0.0.0.0
    ${ip1}    Set Variable    ${dpip[0]}
    ${ip2}    Set Variable    ${dpip[1]}
    Create Vteps    ${ip1}    ${ip2}    ${vlan}    ${gateway-ip}
    Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${subnet}    ${vlan}
    ...    ${Dpn_id_1}    ${ip1}    ${Dpn_id_2}    ${ip2}

delete topology
    [Documentation]    Cleaning up the setup.
    Delete Vm Instance    ${VM_list[0]}
    Delete Vm Instance    ${VM_list[1]}
    Delete Vm Instance    ${VM_list[2]}
    Delete Vm Instance    ${VM_list[3]}
    Delete Vm Instance    ${VM_list[4]}
    Delete Vm Instance    ${VM_list[5]}
    Delete Vm Instance    ${VM_list[6]}
    sleep    40
    Switch Connection    ${conn_id_1}
    Write Commands Until Expected Prompt    neutron security-group-delete \ ${SG_name[0]}    $    40
    ${command}    Set Variable    neutron port-list | grep P31 | awk '{print $2}'
    ${output}    Write Commands Until Expected Prompt    ${command}    $    60
    ${port_list}    Split To Lines    ${output}
    ${port_list}    Get Slice From List    ${port_list}    \    -1
    : FOR    ${port}    IN    @{port_list}
    \    ${output}    Write Commands Until Expected Prompt    neutron port-delete ${port}    $    60
    sleep    10
    ${command}    Set Variable    neutron port-list | grep P32 | awk '{print $2}'
    ${output}    Write Commands Until Expected Prompt    ${command}    $    60
    ${port_list}    Split To Lines    ${output}
    ${port_list}    Get Slice From List    ${port_list}    \    -1
    : FOR    ${port}    IN    @{port_list}
    \    ${output}    Write Commands Until Expected Prompt    neutron port-delete ${port}    $    60
    sleep    10
    Remove Interface    ${Routers[0]}    ${Subnets[0]}
    Remove Interface    ${Routers[0]}    ${Subnets[1]}
    Delete Subnet    ${Subnets[0]}
    Delete Subnet    ${Subnets[1]}
    Delete Router    ${Routers[0]}
    Delete Network    ${Networks[0]}
    Remove Interface    ${Routers[1]}    ${Subnets[2]}
    Delete Subnet    ${Subnets[2]}
    Delete Router    ${Routers[1]}
    Delete Network    ${Networks[1]}
    Switch Connection    ${conn_id_1}
    Write Commands Until Expected Prompt    sudo ovs-vsctl del-br ${Bridge-1}    $    10
    Switch Connection    ${conn_id_2}
    Write Commands Until Expected Prompt    sudo ovs-vsctl del-br ${Bridge-2}    $    10

verify vm creation
    [Arguments]    ${vm_name}
    [Documentation]    Verify after VM creation.
    ${novaverify}    Write Commands Until Expected Prompt    nova list | grep ${vm_name}    $    60
    Should Contain    ${novaverify}    ACTIVE
    Should Contain    ${novaverify}    Running

get ip list specific to prefixes
    [Arguments]    ${vm_name}    ${network_name}    ${prefix1}    ${prefix2}
    [Documentation]    Getting the prefixes based on the ip list.
    ${op}    Write Commands Until Expected Prompt    nova list | grep ${vm_name}    $    20
    Should Contain    ${op}    ${prefix1}
    Should Contain    ${op}    ${prefix2}
    ${match}    Get Regexp Matches    ${op}    ${network_name}=(\.\*)    1
    log    ${match}
    @{temp_list}    Split String    ${match[0]}    ,
    log    ${temp_list}
    @{ip_list}    Create List
    : FOR    ${i}    IN    @{temp_list}
    \    log    ${i}
    \    ${check}    check substring    ${i}    ${prefix1}
    \    ${ip}    Remove String    ${i}    |
    \    ${ip}    Strip String    ${ip}
    \    Run Keyword If    '${check}'=='True'    Append To List    ${ip_list}    ${ip}
    \    log    ${ip_list}
    \    ${check}    check substring    ${i}    ${prefix2}
    \    ${ip}    Remove String    ${i}    |
    \    ${ip}    Strip String    ${ip}
    \    Run Keyword If    '${check}'=='True'    Append To List    ${ip_list}    ${ip}
    \    log    ${ip_list}
    log    ${ip_list}
    [Return]    ${ip_list}

check substring
    [Arguments]    ${s1}    ${s2}
    [Documentation]    Checking the substring
    log    ${s1}
    log    ${s2}
    ${match}    Get Regexp Matches    ${s1}    (${s2})    1
    log    ${match}
    ${len}    Get Length    ${match}
    ${return}    Set Variable If    ${len}>0    True    False
    [Return]    ${return}

get subnet specific ip
    [Arguments]    ${ip_list}    ${prefix}
    [Documentation]    Get subnet specific ip
    ${prefix}    Remove String    ${prefix}    ::/64
    ${check}    check substring    ${ip_list[0]}    ${prefix}
    ${ip}    Set Variable If    '${check}'=='True'    ${ip_list[0]}    ${ip_list[1]}
    [Return]    ${ip}

check data store router interface
    [Arguments]    ${prefix_list}
    [Documentation]    Check data store router interface
    ${json}    Get Data From URI    session    /restconf/config/l3vpn:vpn-interfaces/
    ${object}    Evaluate    json.loads('''${json}''')    json
    log    ${object}
    ${obj1}    Set Variable    ${object["vpn-interfaces"]["vpn-interface"]}
    log    ${obj1}
    ${var}    Set Variable    1
    : FOR    ${i}    IN    @{obj1}
    \    ${var}    Set Variable If    '${i["is-router-interface"]}'=='True'    ${i["odl-l3vpn:adjacency"]}    ${var}
    log    ${var}
    ${adj}    Evaluate    json.dumps(${var})    json
    log    ${adj}
    : FOR    ${prefix}    IN    @{prefix_list}
    \    Should Contain    ${adj}    ${prefix}

verify vm deletion
    [Arguments]    ${vm}    ${mac}    ${conn_id}
    [Documentation]    Verify after VM deletion.
    ${vm_list}    List Nova VMs
    Should Not Contain    ${vm_list}    ${vm}
    Switch Connection    ${conn_id}
    ${cmd}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name1} | grep table=40
    Log    ${cmd}
    ${lower_mac}    Convert To Lowercase    ${mac}
    Should Not Contain    ${cmd}    ${lower_mac}

fetch topology details
    [Documentation]    Fetching topology details.
    Log    >>>Adding part of create topology for the global variables, just for the debugging purpose>>>
    Switch Connection    ${conn_id_1}
    ${hostname1}    get hostname    ${conn_id_1}
    Set Global Variable    ${hostname1}
    Switch Connection    ${conn_id_2}
    ${hostname2}    get hostname    ${conn_id_2}
    Set Global Variable    ${hostname2}
    Switch Connection    ${conn_id_1}
    ${virshid1}    get Vm instance    ${VM_list[0]}
    ${virshid2}    get Vm instance    ${VM_list[1]}
    Set Global Variable    ${virshid1}
    Set Global Variable    ${virshid2}
    ${ip_list1}    Wait Until Keyword Succeeds    50 sec    10 sec    get both ip    ${VM_list[0]}    ${Networks[0]}
    ${ip_list2}    Wait Until Keyword Succeeds    50 sec    10 sec    get both ip    ${VM_list[1]}    ${Networks[0]}
    Set Global Variable    ${ip_list1}
    Set Global Variable    ${ip_list2}
    ${output1}    virsh_output    ${virshid1}    ifconfig eth0
    log    ${output1}
    ${linkaddr1}    extract linklocal addr    ${output1}
    Set Global Variable    ${linkaddr1}
    ${output2}    virsh_output    ${virshid2}    ifconfig eth0
    log    ${output2}
    ${linkaddr2}    extract linklocal addr    ${output2}
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
    ${mac1}    extract mac    ${output1}
    ${port_id1}    get port id    ${mac1}    ${conn_id_1}
    ${port1}    get port number    ${br_name1}    ${port_id1}
    Set Global Variable    ${mac1}
    log    ${port1}
    Set Global Variable    ${port1}
    ${mac2}    extract mac    ${output2}
    ${port_id2}    get port id    ${mac2}    ${conn_id_1}
    ${port2}    get port number    ${br_name1}    ${port_id2}
    Set Global Variable    ${mac2}
    log    ${port2}
    Set Global Variable    ${port2}
    ${virshid5}    get Vm instance    ${VM_list[4]}
    Set Global Variable    ${virshid5}
    ${ip_list5}    Wait Until Keyword Succeeds    5 min    10 sec    get both ip    ${VM_list[4]}    ${Networks[0]}
    Set Global Variable    ${ip_list5}
    Switch Connection    ${conn_id_2}
    ${output5}    virsh_output    ${virshid5}    ifconfig eth0
    log    ${output5}
    ${linkaddr5}    extract linklocal addr    ${output5}
    Set Global Variable    ${linkaddr5}
    Should Contain    ${output5}    ${ip_list5[0]}
    Should Contain    ${output5}    ${ip_list5[1]}
    ${mac5}    extract mac    ${output5}
    ${port_id5}    get port id    ${mac5}    ${conn_id_2}
    ${port5}    get port number    ${br_name1}    ${port_id5}
    Set Global Variable    ${mac5}
    log    ${port5}
    Set Global Variable    ${port5}
    Switch Connection    ${conn_id_1}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name1}
    log    ${flowdump}
    ${metadata1}    Wait Until Keyword Succeeds    30 sec    10 sec    table 0 check    ${br_name1}    ${conn_id_1}
    ...    ${port1}
    Set Global Variable    ${metadata1}
    ${metadata5}    Wait Until Keyword Succeeds    30 sec    10 sec    table 0 check    ${br_name1}    ${conn_id_2}
    ...    ${port5}
    Set Global Variable    ${metadata5}
    Switch Connection    ${conn_id_1}

verify ovs
    [Arguments]    ${conn_id}    ${remoteip_list}    ${pmt}=$
    [Documentation]    Verify ovs installation.
    Switch Connection    ${conn_id}
    ${output}    Write Commands Until Expected Prompt    sudo ovs-vsctl show    ${pmt}    30
    log    ${output}
    : FOR    ${elem}    IN    @{remoteip_list}
    \    Should Contain    ${output}    ${elem}

Cleanup_after_UC1_P1
    [Documentation]    Cleanup after UC1_P1
    Log    >>>Delete Vms with IPv4 address>>>
    Switch Connection    ${conn_id_1}
    Delete Vm Instance    ${VM_list[2]}
    Wait Until Keyword Succeeds    60 sec    10 sec    verify vm deletion    ${VM_list[2]}    ${mac3}    ${conn_id_1}
    Delete Vm Instance    ${VM_list[3]}
    Wait Until Keyword Succeeds    60 sec    10 sec    verify vm deletion    ${VM_list[3]}    ${mac4}    ${conn_id_2}
    Log    >>>Delete the Subnets and network>>>
    Delete SubNet    ${V4subnet_names[0]}
    Remove Interface    ${Routers[0]}    ${Subnets[2]}
    Delete SubNet    ${Subnets[2]}
    Delete Network    ${Networks[1]}

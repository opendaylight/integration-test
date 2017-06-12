*** Settings ***
Documentation     Test suite for IPV6 addr assignment and dual stack testing
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Test Setup
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           Collections
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/IPV6_Service.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/Genius.robot
Resource          ../../../libraries/OVSDB.robot

*** Variables ***
@{Networks}       mynet1    mynet2
@{Subnets}        ipv6s1    ipv6s2    ipv6s3    ipv6s4
@{VM_list}        vm1    vm2    vm3    vm4    vm5    vm6    vm7
@{Routers}        router1    router2
@{Prefixes}       2001:db8:1234::    2001:db8:5678::    2001:db8:4321::    2001:db8:6789::
@{V4subnets}      13.0.0.0    14.0.0.0
@{V4subnet_names}    subnet1v4    subnet2v4
${ipv6securitygroups_config_dir}    ${CURDIR}/../../variables/ipv6securitygroups
@{login_credentials}    stack    stack    root    password
@{SG_name}        SG1    SG2    SG3    SG4    default
@{rule_list}      tcp    udp    icmpv6    10000    10500    IPV6    # protocol1, protocol2, protocol3, port_min, port_max, ether_type
@{direction}      ingress    egress    both
@{Image_Name}     cirros-0.3.4-x86_64-uec    ubuntu-sg
@{protocols}      tcp6    udp6    icmp6
@{remote_group}    SG1    prefix    any
@{remote_prefix}    ::0/0    2001:db8:1234::/64    2001:db8:4321::/64
@{logical_addr}    2001:db8:1234:0:1111:2343:3333:4444    2001:db8:1234:0:1111:2343:3333:5555
${br_name}        br-int
${netvirt_config_dir}    ${CURDIR}/../../../variables/netvirt
@{itm_created}    TZA
${Bridge-1}       br0
${Bridge-2}       br0
@{dpip}           20.0.0.9    20.0.0.10
${Interface-1}    eth1
${Interface-2}    eth1
@{flavour_list}    m1.nano    m1.tiny
@{Tables}         table=0    table=17    table=40    table=41    table=45    table=50    table=51
...               table=60    table=220    table=251    table=252
${invalid_Subnet_Value}    2001:db8:1234::/21
${genius_config_dir}    ${CURDIR}/../../../variables/genius

*** Test Cases ***
IPV6_Validate the assignment of ipv6 addr for multiple VMs with different subnets .
    [Documentation]    Validate the assignment of ipv6 addr for multiple VMs with different subnets in two DPN.
    [Setup]    Create Topology
    Fetch Topology Details    ${conn_id_1}    ${conn_id_2}    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[4]}
    ${metadatavalue1}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_1}
    ...    ${port1}
    ${metadatavalue2}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_1}
    ...    ${port2}
    ${lower_mac1}    Convert To Lowercase    ${mac1}
    @{array17}    Create List    goto_table:45
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[0]}1
    @{array50}    create list    dl_src=${lower_mac1}
    @{array51}    create list    dl_dst=${lower_mac1}
    @{array251}    Create List    table=252    ${ip_list1[0]}    ${ip_list1[1]}    ${linkaddr1}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}    ${array251}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue1}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}    ${Tables[9]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_1}    ${Br_Name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1
    ${lower_mac2}    Convert To Lowercase    ${mac2}
    @{array17}    Create List    goto_table:45
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[0]}1
    @{array50}    create list    dl_src=${lower_mac2}
    @{array51}    create list    dl_dst=${lower_mac2}
    @{array251}    Create List    table=252    ${ip_list2[0]}    ${ip_list2[1]}    ${linkaddr2}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}    ${array251}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue2}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}    ${Tables[9]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_1}    ${Br_Name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1

IPV6_Validate the persistence of single and multiple IPv6 address after rebooting the VM .
    [Documentation]    Validate the persistence of single and multiple IPv6 address after rebooting the VM in single DPN.
    Fetch Topology Details    ${conn_id_1}    ${conn_id_2}    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[4]}
    Nova Reboot    ${VM_list[0]}
    ${output1}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid1}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    log    ${output1}
    Should Contain    ${output1}    ${ip_list1[0]}
    Should Contain    ${output1}    ${ip_list1[1]}
    ${mac1}    Extract_Mac_From_Ifconfig    ${output1}
    ${port_id1}    Get Port Id of instance    ${mac1}    ${conn_id_1}
    ${port1}    Get In Port Number For VM    ${Br_Name}    ${port_id1}
    Set Global Variable    ${mac1}
    log    ${port1}
    Set Global Variable    ${port1}
    ${metadatavalue1}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${br_name}    ${conn_id_1}
    ...    ${port1}
    ${lower_mac1}    Convert To Lowercase    ${mac1}
    @{array17}    Create List    goto_table:45
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[0]}1
    @{array50}    create list    dl_src=${lower_mac1}
    @{array51}    create list    dl_dst=${lower_mac1}
    @{array251}    Create List    table=252    ${ip_list1[0]}    ${ip_list1[1]}    ${linkaddr1}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}    ${array251}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue1}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}    ${Tables[9]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_1}    ${Br_Name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1

IPV6_Verifying the IPv6 addr assignment by configuring invalid ipv6 prefix.
    [Documentation]    Verifying the ipv6 \ addr assignment by configuring invalid ipv6 prefix.
    log    creating subnet with invalid prefix
    ${subnet_list}=    Write Commands Until Expected Prompt    neutron subnet-list    $    30
    log    ${subnet_list}
    ${invalid_subnet}    Set Variable    newsubnet
    Wait Until Keyword Succeeds    30 sec    10 sec    Create Invalid IPV6 Subnet    ${Networks[0]}    ${invalid_subnet}    ${invalid_Subnet_Value}

IPV6_Validating IPv6_RA_mode and IPv6_addr_mode after creating IPv6 subnet.
    [Documentation]    Validating IPv6_RA_mode and IPv6_addr_mode after creating IPv6 subnet and it should be SLACC mode.
    @{ipv6_mode_list}=    Create List    "ipv6_address_mode" : "slaac"    "ipv6_ra_mode" : "slaac"
    Check For Elements At URI    /controller/nb/v2/neutron/subnets    ${ipv6_mode_list}

IPV6_Validate after removing the ipv6 subnet and check the IPv6 address on interface of the VM.
    [Documentation]    Validate after removing the ipv6 subnet and check the IPv6 address on interface of the VM in single DPN.
    Remove Interface    ${Routers[0]}    ${Subnets[1]}
    Switch Connection    ${conn_id_1}
    nova reboot    ${VM_list[0]}
    ${output1}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid1}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    ${vm1ip_subnet2}    Get Subnet Specific Ipv6    ${ip_list1}    ${Prefixes[1]}
    Set Global Variable    ${vm1ip_subnet2}
    log    ${output1}
    ${mac1}    Extract_Mac_From_Ifconfig    ${output1}
    ${port_id1}    Get Port Id of instance    ${mac1}    ${conn_id_1}
    ${port1}    Get In Port Number For VM    ${br_name}    ${port_id1}
    Set Global Variable    ${mac1}
    log    ${port1}
    Set Global Variable    ${port1}
    Should Not Contain    ${output1}    ${vm1ip_subnet2}
    Log    >>>table 45 check-vm1>>>
    @{array}    create list    nd_target=${Prefixes[1]}1
    Comment    table check with negative scenario    ${conn_id_1}    ${Br_Name}    table=45|grep actions=CONTROLLER:65535    ${array}

*** Keywords ***
Create Topology
    [Documentation]    Creating the Topology
    log    >>>creating ITM tunnel
    Create ITM Tunnel
    Log    >>>> Creating Network <<<<
    Switch Connection    ${conn_id_1}
    Create Network    ${Networks[0]}
    Create Subnet    ${Networks[0]}    ${Subnets[0]}    ${Prefixes[0]}/64    --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    Create Subnet    ${Networks[0]}    ${Subnets[1]}    ${Prefixes[1]}/64    --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    Create Router    ${Routers[0]}
    Add Router Interface    ${Routers[0]}    ${Subnets[0]}
    @{prefixlist}    Create List    ${Prefixes[0]}
    Add Router Interface    ${Routers[0]}    ${Subnets[1]}
    @{prefixlist}    Create List    ${Prefixes[0]}    ${Prefixes[1]}
    ${hostname1}    Get Vm Hostname    ${conn_id_1}
    Set Global Variable    ${hostname1}
    Switch Connection    ${conn_id_2}
    ${hostname2}    Get Vm Hostname    ${conn_id_2}
    Set Global Variable    ${hostname2}
    Switch Connection    ${conn_id_1}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    Spawn Vm    ${Networks[0]}    ${VM_list[0]}    ${Image_Name[0]}    ${hostname1}    ${flavour_list[1]}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    Spawn Vm    ${Networks[0]}    ${VM_list[1]}    ${Image_Name[0]}    ${hostname1}    ${flavour_list[1]}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    Spawn Vm    ${Networks[0]}    ${VM_list[4]}    ${Image_Name[0]}    ${hostname2}    ${flavour_list[1]}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    ${virshid1}    Get Vm Instance    ${VM_list[0]}
    ${virshid2}    Get Vm Instance    ${VM_list[1]}
    Set Global Variable    ${virshid1}
    Set Global Variable    ${virshid2}
    ${ip_list1}    Wait Until Keyword Succeeds    50 sec    10 sec    Get VM Ip Addresses From Instance Details    ${VM_list[0]}    ${Networks[0]}
    ${ip_list2}    Wait Until Keyword Succeeds    50 sec    10 sec    Get VM Ip Addresses From Instance Details    ${VM_list[1]}    ${Networks[0]}
    Set Global Variable    ${ip_list1}
    Set Global Variable    ${ip_list2}
    ${output1}    Virsh Output    ${virshid1}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}
    ...    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)    $
    log    ${output1}
    ${linkaddr1}    Extract Linklocal Addr    ${output1}
    Set Global Variable    ${linkaddr1}
    ${output2}    Virsh Output    ${virshid2}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}
    ...    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)    $
    log    ${output2}
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
    ${port1}    Get In Port Number For VM    ${br_name}    ${port_id1}
    Set Global Variable    ${mac1}
    log    ${port1}
    Set Global Variable    ${port1}
    ${mac2}    Extract_Mac_From_Ifconfig    ${output2}
    ${port_id2}    Get Port Id of instance    ${mac2}    ${conn_id_1}
    ${port2}    Get In Port Number For VM    ${br_name}    ${port_id2}
    Set Global Variable    ${mac2}
    log    ${port2}
    Set Global Variable    ${port2}
    ${virshid5}    Get Vm Instance    ${VM_list[4]}
    Set Global Variable    ${virshid5}
    ${ip_list5}    Wait Until Keyword Succeeds    2 min    10 sec    Get VM Ip Addresses From Instance Details    ${VM_list[4]}    ${Networks[0]}
    Set Global Variable    ${ip_list5}
    Switch Connection    ${conn_id_2}
    ${output5}    Virsh Output    ${virshid5}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}
    ...    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)    $
    log    ${output5}
    ${linkaddr5}    Extract Linklocal Addr    ${output5}
    Set Global Variable    ${linkaddr5}
    Should Contain    ${output5}    ${ip_list5[0]}
    Should Contain    ${output5}    ${ip_list5[1]}
    ${mac5}    Extract_Mac_From_Ifconfig    ${output5}
    ${port_id5}    Get Port Id of instance    ${mac5}    ${conn_id_2}
    ${port5}    Get In Port Number For VM    ${br_name}    ${port_id5}
    Set Global Variable    ${mac5}
    log    ${port5}
    Set Global Variable    ${port5}
    Switch Connection    ${conn_id_1}

Get Security Group Id For Admin Default
    ${command}    Set Variable    neutron security-group-list | grep default | awk '{print$2}'
    ${templist}    Write Commands Until Expected Prompt    ${command}    $    60
    ${sg_id_list}    Split To Lines    ${templist}
    ${SGlist}    Get Slice From List    ${sg_id_list}    \    -1
    ${project_id_temp}    Write Commands Until Expected Prompt    openstack project list | grep '| admin' | awk '{print$2}'    $    60
    @{projectlist}    Split String    ${project_id_temp}    \r\n
    ${project_id}    Get From List    ${projectlist}    0
    : FOR    ${id}    IN    @{SGlist}
    \    ${tenant_id_temp}    Write Commands Until Expected Prompt    neutron security-group-show \ ${id} | grep '| tenant_id' | awk '{print$4}'    $    60
    \    @{tenantlist}    Split String    ${tenant_id_temp}    \r\n
    \    ${tenant_id}    Get From List    ${tenantlist}    0
    \    Run Keyword If    '${project_id}'=='${tenant_id}'    Return From Keyword    ${id}

get ipv6 address for new network
    [Arguments]    ${vm_name}    ${ipv6_existing}    ${network1}    ${prefix1}    ${prefix2}
    Wait Until Keyword Succeeds    1 min    10 sec    check ips on nova show    ${vm_name}    ${network1}    ${prefix1}
    ...    ${prefix2}
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
    ${ip2}=    Strip String    ${str2}
    log    ${ip2}
    ${ipv6_new}    Set Variable If    '${ip1}'=='${ipv6_existing}'    ${ip2}    ${ip1}
    log    ${ipv6_new}
    [Return]    ${ipv6_new}

Delete Topology
    [Documentation]    Cleaning up the setup.
    Comment    @{VM_list}    Create List    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[2]}    ${VM_list[3]}
    ...    ${VM_list[4]}
    Comment    @{mac_list}    Create List    ${mac1}    ${mac2}    ${mac3}    ${mac4}
    ...    ${mac5}
    : FOR    ${list}    IN RANGE    0    4
    \    Wait Until Keyword Succeeds    60 sec    10 Sec    Delete Vm Instance    ${VM_list[${list}]}
    \    ${macvalue}    Evaluate    ${list} + 1
    \    log    ${macvalue}
    \    log    ${mac${macvalue}}
    \    Wait Until Keyword Succeeds    60 sec    10 sec    Verify Vm Deletion    ${VM_list[${list}]}    ${mac${macvalue}}
    \    ...    ${conn_id_1}    ${br_name1}
    Switch Connection    ${conn_id_1}
    Write Commands Until Expected Prompt    neutron security-group-delete \ ${SG_name[0]}    $    40
    ${command}    Set Variable    neutron port-list | grep P31 | awk '{print $2}'
    ${output}    Write Commands Until Expected Prompt    ${command}    $    60
    ${port_list}    Split To Lines    ${output}
    ${port_list}    Get Slice From List    ${port_list}    \    -1
    : FOR    ${port}    IN    @{port_list}
    \    ${output}    Write Commands Until Expected Prompt    neutron port-delete ${port}    $    60
    ${command}    Set Variable    neutron port-list | grep P32 | awk '{print $2}'
    ${output}    Write Commands Until Expected Prompt    ${command}    $    60
    ${port_list}    Split To Lines    ${output}
    ${port_list}    Get Slice From List    ${port_list}    \    -1
    : FOR    ${port}    IN    @{port_list}
    \    ${output}    Write Commands Until Expected Prompt    neutron port-delete ${port}    $    60
    ${EMPTY}
    Remove Interface    ${Routers[0]}    ${Subnets[0]}
    Remove Interface    ${Routers[0]}    ${Subnets[1]}
    Delete Subnet    ${Subnets[0]}
    Delete Subnet    ${Subnets[1]}
    Delete Router    ${Routers[0]}
    Delete Network    ${Networks[0]}
    Switch Connection    ${conn_id_1}
    Write Commands Until Expected Prompt    sudo ovs-vsctl del-br ${Bridge-1}    $    10
    Switch Connection    ${conn_id_2}
    Write Commands Until Expected Prompt    sudo ovs-vsctl del-br ${Bridge-2}    $    10

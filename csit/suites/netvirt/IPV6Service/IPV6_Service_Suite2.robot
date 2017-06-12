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
@{Networks}       mynet1    mynet2    mynet3
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
    Comment    ${output1}    Wait Until Keyword Succeeds    120 sec    10 sec    check ip address in ifconfig output    ${virshid1}
    ...    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}
    ...    cirros    cubswin:)    $
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
    Log    ${vm1ip_subnet2}
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

IPV6_Validate after adding the subnet back and check the IPv6 address on interface of the VM.
    [Documentation]    Validate after adding the subnet back and check the IPv6 address on interface of the VM.
    Add Router Interface    ${Routers[0]}    ${Subnets[1]}
    Sleep    20 sec
    Switch Connection    ${conn_id_1}
    Wait Until Keyword Succeeds    300 sec    10 sec    check ip on vm    ${conn_id_1}    ${virshid1}    ifconfig eth0
    ...    ${vm1ip_subnet2}
    Log    >>>table 0 check>>>
    ${metadatavalue1}    Wait Until Keyword Succeeds    90 sec    10 sec    Table 0 Check For VM Creation    ${br_name}    ${conn_id_1}
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

IPV6_Validating dualstack address assignment to Neutron VMs on same interface after booting up
    [Documentation]    This test case validates dualstack address assignment to Neutron VMs on same interface after booting up with IPv6 configuration mode as SLAAC
    Create Network    ${Networks[1]}
    Create Subnet    ${Networks[1]}    ${Subnets[2]}    ${Prefixes[2]}/64    --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    Create Subnet    ${Networks[1]}    ${V4subnet_Names[0]}    ${V4subnets[0]}/24    --enable-dhcp
    Add Router Interface    ${Routers[0]}    ${Subnets[2]}
    sleep     20 sec
    Remove All Elements If Exist    ${CONFIG_API}/dhcpservice-config:dhcpservice-config/
    Post Elements To URI From File    ${CONFIG_API}/    ${netvirt_config_dir}/enable_dhcp.json
    @{list}=    Create List    "controller-dhcp-enabled"    true
    Check For Elements At URI    ${CONFIG_API}/dhcpservice-config:dhcpservice-config/    ${list}
    Switch Connection    ${conn_id_1}
    Spawn Vm    ${Networks[1]}    ${VM_List[2]}    ${Image_Name[0]}    ${hostname1}    ${flavour_list[1]}
    ${prefixstr1}    Remove String    ${Prefixes[2]}    ::
    ${v4prefix}    Get Substring    ${V4subnets[0]}    \    -1
    ${ip_list3}    Wait Until Keyword Succeeds    50 sec    10 sec    Get Ip List Specific To Prefixes    ${VM_List[2]}    ${Networks[1]}
    ...    ${prefixstr1}    ${v4prefix}
    Set Global Variable    ${ip_list3}
    ${vm3ip}    Get Subnet Specific Ipv6    ${ip_list3}    ${Prefixes[2]}
    Set Global Variable    ${vm3ip}
    ${vm3v4ip}    Set Variable If    '${vm3ip}'=='${ip_list3[0]}'    ${ip_list3[0]}    ${ip_list3[1]}
    Set Global Variable    ${vm3v4ip}
    ${virshid3}    Get Vm Instance    ${VM_list[2]}
    Set Global Variable    ${virshid3}
    ${output3}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid3}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    log    ${output3}
    ${linkaddr3}    extract linklocal addr    ${output3}
    Set Global Variable    ${linkaddr3}
    Should Contain    ${output3}    ${ip_list3[0]}
    Should Contain    ${output3}    ${ip_list3[1]}
    Set Global Variable    ${ip_list3[0]}
    Set Global Variable    ${ip_list3[1]}
    ${mac3}    Extract_Mac_From_Ifconfig    ${output3}
    ${port_id3}    Get Port Id of instance    ${mac3}    ${conn_id_1}
    ${port3}    Get In Port Number For VM    ${br_name}    ${port_id3}
    log    ${port3}
    Set Global Variable    ${mac3}
    Set Global Variable    ${port3}
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${br_name}    ${conn_id_1}
    ...    ${port3}
    ${lower_mac3}    Convert To Lowercase    ${mac3}
    @{array17}    Create List    goto_table:45    goto_table:60
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1
    @{array50}    create list    dl_src=${lower_mac3}
    @{array51}    create list    dl_dst=${lower_mac3}
    @{array60}    Create List    dl_src=${lower_mac3}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}    ${array60}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue3}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}    ${Tables[7]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_1}    ${br_name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1

IPV6_Validate persistence of dual stack addr of Neutron VMs after rebooting VM.
    [Documentation]    Validate persistence of dual stack addr of Neutron VMs \ after rebooting VM.
    nova reboot    ${VM_list[2]}
    ${output3}    Wait Until Keyword Succeeds    120 sec    10 sec    check ip address in ifconfig output    ${virshid3}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    Comment    ${output3}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid3}
    ...    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}
    ...    cirros    cubswin:)    $
    Should Contain    ${output3}    ${ip_list3[0]}
    Should Contain    ${output3}    ${ip_list3[1]}
    ${mac3}    Extract_Mac_From_Ifconfig    ${output3}
    ${port_id3}    Get Port Id of instance    ${mac3}    ${conn_id_1}
    ${port3}    Get In Port Number For VM    ${Br_Name}    ${port_id3}
    Set Global Variable    ${mac3}
    log    ${port3}
    Set Global Variable    ${port3}
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${br_name}    ${conn_id_1}
    ...    ${port3}
    ${lower_mac3}    Convert To Lowercase    ${mac3}
    @{array17}    Create List    goto_table:45    goto_table:60
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1
    @{array50}    create list    dl_src=${lower_mac3}
    @{array51}    create list    dl_dst=${lower_mac3}
    @{array60}    Create List    dl_src=${lower_mac3}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}    ${array60}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue3}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}    ${Tables[7]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_1}    ${br_name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1

IPV6_Validate after removing the one of Ipv6 subnet from network and it should be deleted from the same interface of VM.
    [Documentation]    Validate after removing the one of Ipv6 subnet from network and it should be deleted from the same interface of VM.
    Remove Interface    ${Routers[0]}    ${Subnets[2]}
    Switch Connection    ${conn_id_1}
    nova reboot    ${VM_list[2]}
    ${output3}    Wait Until Keyword Succeeds    120 sec    10 sec    check ip address in ifconfig output    ${virshid3}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    log    ${output3}
    Log    ${vm3ip}
    Should Not Contain    ${output3}    ${vm3ip}
    ${mac3}    Extract_Mac_From_Ifconfig    ${output3}
    ${port_id3}    Get Port Id of instance    ${mac3}    ${conn_id_1}
    ${port3}    Get In Port Number For VM    ${br_name}    ${port_id3}
    Set Global Variable    ${mac3}
    log    ${port3}
    Set Global Variable    ${port3}
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${br_name}    ${conn_id_1}
    ...    ${port3}
    ${lower_mac3}    Convert To Lowercase    ${mac3}
    @{array17}    Create List    goto_table:60
    @{array60}    Create List    dl_src=${lower_mac3}
    @{arraylist}    Create List    ${array17}    ${array60}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue3}    ${Tables[7]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_1}    ${br_name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1
    @{array45}    create list    nd_target=${Prefixes[2]}1
    Table Check With Negative Scenario    ${conn_id_1}    ${br_name}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${array45}

IPV6_Validate after adding IPv6 subnet on same virtual network and check the IPv6 address assignment to Neutron VMs on same interface.
    [Documentation]    Validate after adding IPv6 subnet on same virtual network and check the IPv6 address assignment to Neutron VMs on same interface.
    Add Router Interface    ${Routers[0]}    ${Subnets[2]}
    sleep    20 sec
    Switch Connection    ${conn_id_1}
    ${output3}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid3}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    Should Contain    ${output3}    ${ip_list3[0]}
    Should Contain    ${output3}    ${ip_list3[1]}
    ${mac3}    Extract_Mac_From_Ifconfig    ${output3}
    ${port_id3}    Get Port Id of instance    ${mac3}    ${conn_id_1}
    ${port3}    Get In Port Number For VM    ${Br_Name}    ${port_id3}
    Set Global Variable    ${mac3}
    log    ${port3}
    Set Global Variable    ${port3}
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${br_name}    ${conn_id_1}
    ...    ${port3}
    ${lower_mac3}    Convert To Lowercase    ${mac3}
    @{array17}    Create List    goto_table:45    goto_table:60
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1
    @{array50}    create list    dl_src=${lower_mac3}
    @{array51}    create list    dl_dst=${lower_mac3}
    @{array60}    Create List    dl_src=${lower_mac3}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}    ${array60}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue3}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}    ${Tables[7]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_1}    ${br_name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1

IPV6_Validate after removing the one of Ipv4 subnet from network and it should be deleted from the VM.
    [Documentation]    Validate after removing the one of Ipv4 subnet from network and it should be deleted from the VM.
    Delete Vm Instance    ${VM_List[2]}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_List[2]}    ${mac3}    ${conn_id_1}
    ...    ${br_name1}
    Delete SubNet    ${V4subnet_Names[0]}
    Switch Connection    ${conn_id_1}
    Spawn Vm    ${Networks[1]}    ${VM_List[2]}    ${Image_Name[0]}    ${hostname1}    ${flavour_list[1]}
    ${vm3ip}    Get Vm Ipv6 Addr    ${VM_List[2]}    ${Networks[1]}
    Set Global Variable    ${vm3ip}
    ${virshid3}    Get Vm Instance    ${VM_list[2]}
    Set Global Variable    ${virshid3}
    ${output3}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid3}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    Should Not Contain    ${output3}    ${vm3v4ip}
    ${mac3}    Extract_Mac_From_Ifconfig    ${output3}
    ${port_id3}    Get Port Id of instance    ${mac3}    ${conn_id_1}
    ${port3}    Get In Port Number For VM    ${Br_Name}    ${port_id3}
    log    ${port3}
    Set Global Variable    ${mac3}
    Set Global Variable    ${port3}
    Log    >>>table 0 check>>>
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_1}
    ...    ${port3}
    ${lower_mac3}    Convert To Lowercase    ${mac3}
    Log    >>>flow table validation for vm3>>>
    @{array17}    Create List    goto_table:45
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1
    @{array50}    create list    dl_src=${lower_mac3}
    @{array51}    create list    dl_dst=${lower_mac3}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue3}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_1}    ${Br_Name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1
    @{array60}    Create List    dl_src=${lower_mac3}
    Table Check With Negative Scenario    ${conn_id_1}    ${Br_Name}    ${Tables[7]}    ${array60}

IPV6_Validate after adding IPv4 subnet on same virtual network and check the IPv4 address assignment to Neutron VMs on same interface.
    [Documentation]    Validate after adding IPv4 subnet on same virtual network and check the IPv4 address assignment to Neutron VMs on same interface.
    Create Subnet    ${Networks[1]}    ${V4subnet_Names[0]}    ${V4subnets[0]}/24    --enable-dhcp
    Switch Connection    ${conn_id_1}
    ${ip_list3}    Wait Until Keyword Succeeds    90 sec    10 sec    Get VM Ip Addresses From Instance Details    ${VM_List[2]}    ${Networks[1]}
    Set Global Variable    ${ip_list3}
    ${vm3v4ip}    Set Variable If    '${vm3ip}'=='${ip_list3[0]}'    ${ip_list3[0]}    ${ip_list3[1]}
    Log    ${vm3v4ip}
    Set Global Variable    ${vm3v4ip}
    ${output3}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid3}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    Log    ${output3}
    Should Contain    ${output3}    ${vm3v4ip}
    Log    >>>table 0 check>>>
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_1}
    ...    ${port3}
    ${lower_mac3}    Convert To Lowercase    ${mac3}
    Log    >>>flow table validation for vm3>>>
    @{array17}    Create List    goto_table:45    goto_table:60
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1
    @{array50}    create list    dl_src=${lower_mac3}
    @{array51}    create list    dl_dst=${lower_mac3}
    @{array60}    Create List    dl_src=${lower_mac3}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}    ${array60}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue3}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}    ${Tables[7]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_1}    ${Br_Name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1

IPV6_Validate ping between VMs in single DPN.
    [Documentation]    Validate ping between VMs in single DPN.
    Delete Vm Instance    ${VM_List[2]}
    Switch Connection    ${conn_id_1}
    Spawn Vm    ${Networks[1]}    ${VM_List[2]}    ${Image_Name[0]}    ${hostname1}    ${flavour_list[1]}
    ${vm3ip}    Get Vm Ipv6 Addr    ${VM_List[2]}    ${Networks[1]}
    Set Global Variable    ${vm3ip}
    ${virshid3}    Get Vm Instance    ${VM_list[2]}
    Set Global Variable    ${virshid3}
    ${output3}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid3}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    Should Not Contain    ${output3}    ${vm3v4ip}
    ${mac3}    Extract_Mac_From_Ifconfig    ${output3}
    ${port_id3}    Get Port Id of instance    ${mac3}    ${conn_id_1}
    ${port3}    Get In Port Number For VM    ${Br_Name}    ${port_id3}
    log    ${port3}
    Set Global Variable    ${mac3}
    Set Global Variable    ${port3}
    ${linkaddr3}    extract linklocal addr    ${output3}
    Set Global Variable    ${linkaddr3}
    Spawn Vm    ${Networks[1]}    ${VM_List[5]}    ${Image_Name[0]}    ${hostname1}    ${flavour_list[1]}
    ${prefixstr1}    Remove String    ${Prefixes[2]}    ::
    ${v4prefix}    Get Substring    ${V4subnets[0]}    \    -1
    ${ip_list6}    Wait Until Keyword Succeeds    50 sec    10 sec    Get Ip List Specific To Prefixes    ${VM_List[5]}    ${Networks[1]}
    ...    ${prefixstr1}    ${v4prefix}
    Set Global Variable    ${ip_list6}
    ${vm6ip}    Get Subnet Specific Ipv6    ${ip_list6}    ${Prefixes[2]}
    Set Global Variable    ${vm6ip}
    ${vm6v4ip}    Set Variable If    '${vm6ip}'=='${ip_list6[0]}'    ${ip_list6[0]}    ${ip_list6[1]}
    Set Global Variable    ${vm6v4ip}
    ${virshid6}    Get Vm Instance    ${VM_List[5]}
    Set Global Variable    ${virshid6}
    ${output6}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid6}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    log    ${output6}
    ${linkaddr6}    extract linklocal addr    ${output6}
    Set Global Variable    ${linkaddr6}
    Should Contain    ${output6}    ${ip_list6[0]}
    Should Contain    ${output6}    ${ip_list6[1]}
    Set Global Variable    ${ip_list6}
    Set Global Variable    ${ip_list6}
    ${mac6}    Extract_Mac_From_Ifconfig    ${output6}
    ${port_id6}    Get Port Id of instance    ${mac6}    ${conn_id_1}
    ${port6}    Get In Port Number For VM    ${Br_Name}    ${port_id6}
    log    ${port6}
    Set Global Variable    ${mac6}
    Set Global Variable    ${port6}
    Log    >>>table 0 check>>>
    ${metadatavalue6}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_1}
    ...    ${port6}
    ${lower_mac6}    Convert To Lowercase    ${mac6}
    Log    >>>flow table validation for vm6>>>
    @{array17}    Create List    goto_table:45    goto_table:60
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1
    @{array50}    create list    dl_src=${lower_mac6}
    @{array51}    create list    dl_dst=${lower_mac6}
    @{array60}    Create List    dl_src=${lower_mac6}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}    ${array60}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue6}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}    ${Tables[7]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_1}    ${Br_Name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1
    Ping From Virsh Console    ${virshid3}    ${ip_list6[0]}    ${conn_id_1}    , 0% packet loss
    Ping From Virsh Console    ${virshid3}    ${ip_list6[1]}    ${conn_id_1}    , 0% packet loss

IPV6_Validates ping6 between VMs in two DPN.
    [Documentation]    Validates ping6 between VMs in two DPN.
    Switch Connection    ${conn_id_2}
    Spawn Vm    ${Networks[1]}    ${VM_List[3]}    ${Image_Name[0]}    ${hostname2}    ${flavour_list[1]}
    ${prefixstr1}    Remove String    ${Prefixes[2]}    ::
    ${v4prefix}    Get Substring    ${V4subnets[0]}    \    -1
    ${ip_list4}    Wait Until Keyword Succeeds    50 sec    10 sec    Get Ip List Specific To Prefixes    ${VM_List[3]}    ${Networks[1]}
    ...    ${prefixstr1}    ${v4prefix}
    Set Global Variable    ${ip_list4}
    Switch Connection    ${conn_id_1}
    ${vm4ip}    Get Subnet Specific Ipv6    ${ip_list4}    ${Prefixes[2]}
    ${virshid4}    Get Vm Instance    ${VM_list[3]}
    Set Global Variable    ${virshid4}
    ${output4}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid4}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    log    ${output4}
    ${linkaddr4}    extract linklocal addr    ${output4}
    Set Global Variable    ${linkaddr4}
    Should Contain    ${output4}    ${ip_list4[0]}
    Should Contain    ${output4}    ${ip_list4[1]}
    Set Global Variable    ${ip_list4[0]}
    Set Global Variable    ${ip_list4[1]}
    ${mac4}    Extract_Mac_From_Ifconfig    ${output4}
    ${port_id4}    Get Port Id of instance    ${mac4}    ${conn_id_2}
    ${port4}    Get In Port Number For VM    ${Br_Name}    ${port_id4}
    log    ${port4}
    Set Global Variable    ${mac4}
    Set Global Variable    ${port4}
    Log    >>>table 0 check>>>
    Switch Connection    ${conn_id_2}
    ${metadatavalue4}    Wait Until Keyword Succeeds    50 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_2}
    ...    ${port4}
    Log    >>>Create a list for table 17 for validation-vm4>>>
    ${lower_mac4}    Convert To Lowercase    ${mac4}
    @{array17}    Create List    goto_table:45
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1
    @{array50}    create list    dl_src=${lower_mac4}
    @{array51}    create list    dl_dst=${lower_mac4}
    @{array60}    Create List    dl_src=${lower_mac4}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}    ${array60}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue4}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}    ${Tables[7]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_2}    ${Br_Name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1
    Ping From Virsh Console    ${virshid3}    ${ip_list4[0]}    ${conn_id_1}    , 0% packet loss
    Ping From Virsh Console    ${virshid3}    ${ip_list4[1]}    ${conn_id_1}    , 0% packet loss
    ${pwd_output}    Write Commands Until Expected Prompt    pwd    $    30
    log    ${pwd_output}

IPV6_Validate ping after rebooting the Neutron VM in two DPN.
    [Documentation]    Validate ping after rebooting the Neutron VM in two DPN.
    nova reboot    ${VM_list[3]}
    ${output4}    Wait Until Keyword Succeeds    120 sec    10 sec    check ip address in ifconfig output    ${virshid4}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    log    ${output4}
    Should Contain    ${output4}    ${ip_list4[0]}
    Should Contain    ${output4}    ${ip_list4[1]}
    ${mac4}    Extract_Mac_From_Ifconfig    ${output4}
    ${port_id4}    Get Port Id of instance    ${mac4}    ${conn_id_2}
    ${port4}    Get In Port Number For VM    ${Br_Name}    ${port_id4}
    Set Global Variable    ${mac4}
    log    ${port4}
    Set Global Variable    ${port4}
    Log    >>>table 0 check>>>
    Switch Connection    ${conn_id_2}
    ${metadatavalue4}    Wait Until Keyword Succeeds    50 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_2}
    ...    ${port4}
    Log    >>>Create a list for table 17 for validation-vm4>>>
    ${lower_mac4}    Convert To Lowercase    ${mac4}
    @{array17}    Create List    goto_table:45
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1
    @{array50}    create list    dl_src=${lower_mac4}
    @{array51}    create list    dl_dst=${lower_mac4}
    @{array60}    Create List    dl_src=${lower_mac4}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}    ${array60}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue4}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}    ${Tables[7]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_2}    ${Br_Name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1
    Ping From Virsh Console    ${virshid3}    ${ip_list4[0]}    ${conn_id_1}    , 0% packet loss
    Ping From Virsh Console    ${virshid3}    ${ip_list4[1]}    ${conn_id_1}    , 0% packet loss

IPV6_Validate ipv6 addr assignment with two virtual network in single DPN.
    [Documentation]    Validate ipv6 addr assignment with two virtual network in single DPN.
    Create Network    ${Networks[2]}
    Create Subnet    ${Networks[2]}    ${Subnets[3]}    ${Prefixes[3]}/64    --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    Add Router Interface    ${Routers[0]}    ${Subnets[3]}
    sleep    20 sec
    Switch Connection    ${conn_id_1}
    Delete Vm Instance    ${VM_List[2]}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_List[2]}    ${mac3}    ${conn_id_1}
    ...    ${br_name1}
    Delete Vm Instance    ${VM_List[5]}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_List[5]}    ${mac6}    ${conn_id_1}
    ...    ${br_name1}
    Switch Connection    ${conn_id_1}
    Spawn Vm    ${Networks[1]}    ${VM_List[2]}    ${Image_Name[0]}    ${hostname1}    ${flavour_list[1]}    --nic net-name=${Networks[2]}
    Spawn Vm    ${Networks[1]}    ${VM_List[5]}    ${Image_Name[0]}    ${hostname1}    ${flavour_list[1]}    --nic net-name=${Networks[2]}
    ${virshid3}    Get Vm Instance    ${VM_list[2]}
    Set Global Variable    ${virshid3}
    ${virshid6}    Get Vm Instance    ${VM_List[5]}
    Set Global Variable    ${virshid6}
    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid3}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}
    ...    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)
    ...    $
    ${vm3_net2_ip1}    get network specific ip address    ${VM_List[2]}    ${Networks[2]}
    Set Global Variable    ${vm3_net2_ip1}
    sleep    30
    check ip on vm    ${conn_id_1}    ${virshid3}    ifconfig eth1    ${vm3_net2_ip1}
    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid6}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}
    ...    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)
    ...    $
    ${vm6_net2_ip1}    get network specific ip address    ${VM_List[5]}    ${Networks[2]}
    Set Global Variable    ${vm6_net2_ip1}
    sleep    30
    check ip on vm    ${conn_id_1}    ${virshid6}    ifconfig eth1    ${vm6_net2_ip1}
    Ping From Virsh Console    ${virshid3}    ${vm6_net2_ip1}    ${conn_id_1}    , 0% packet loss
    ${output3}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid3}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    ${output3_1}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid3}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    ${mac3}    Extract_Mac_From_Ifconfig    ${output3}
    ${port_id3}    Get Port Id of instance    ${mac3}    ${conn_id_1}
    ${port3}    Get In Port Number For VM    ${Br_Name}    ${port_id3}
    log    ${port3}
    Set Global Variable    ${mac3}
    Set Global Variable    ${port3}
    ${mac3_1}    Extract_Mac_From_Ifconfig    ${output3_1}
    ${port_id3_1}    Get Port Id of instance    ${mac3_1}    ${conn_id_1}
    ${port3_1}    Get In Port Number For VM    ${Br_Name}    ${port_id3_1}
    log    ${port3_1}
    Set Global Variable    ${mac3_1}
    Set Global Variable    ${port3_1}
    ${output6}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid6}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    ${output6_1}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid6}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    ${mac6}    Extract_Mac_From_Ifconfig    ${output6}
    ${port_id6}    Get Port Id of instance    ${mac6}    ${conn_id_1}
    ${port6}    Get In Port Number For VM    ${Br_Name}    ${port_id6}
    log    ${port6}
    Set Global Variable    ${mac6}
    Set Global Variable    ${port6}
    ${mac6_1}    Extract_Mac_From_Ifconfig    ${output6_1}
    ${port_id6_1}    Get Port Id of instance    ${mac6_1}    ${conn_id_1}
    ${port6_1}    Get In Port Number For VM    ${Br_Name}    ${port_id6_1}
    log    ${port6_1}
    Set Global Variable    ${mac6_1}
    Set Global Variable    ${port6_1}
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_1}
    ...    ${port3}
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_1}
    ...    ${port3_1}
    ${lower_mac3}    Convert To Lowercase    ${mac3}
    Log    >>>flow table validation for vm3>>>
    @{array17}    Create List    goto_table:45
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1    nd_target=${Prefixes[3]}1
    @{array50}    create list    dl_src=${lower_mac3}
    @{array51}    create list    dl_dst=${lower_mac3}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue3}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_1}    ${Br_Name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1
    Log    >>>table 0 check>>>
    ${metadatavalue6}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_1}
    ...    ${port6}
    ${metadatavalue6}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_1}
    ...    ${port6_1}
    ${lower_mac6}    Convert To Lowercase    ${mac6}
    Log    >>>flow table validation for vm6>>>
    @{array17}    Create List    goto_table:45
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1    nd_target=${Prefixes[3]}1
    @{array50}    create list    dl_src=${lower_mac6}
    @{array51}    create list    dl_dst=${lower_mac6}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue6}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_1}    ${Br_Name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1

IPV6_Validate ipv6 addr assignment with two virtual network in two DPN.
    [Documentation]    Validate ipv6 addr assignment with two virtual network in two DPN.
    Switch Connection    ${conn_id_1}
    Delete Vm Instance    ${VM_List[3]}
    Switch Connection    ${conn_id_1}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_List[3]}    ${mac4}    ${conn_id_2}
    ...    ${br_name1}
    Switch Connection    ${conn_id_1}
    Spawn Vm    ${Networks[1]}    ${VM_List[3]}    ${Image_Name[0]}    ${hostname2}    ${flavour_list[1]}    --nic net-name=${Networks[2]}
    ${virshid4}    Get Vm Instance    ${VM_List[3]}
    Set Global Variable    ${virshid4}
    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid4}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}
    ...    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)
    ...    $
    ${vm4_net2_ip1}    get network specific ip address    ${VM_List[3]}    ${Networks[2]}
    Set Global Variable    ${vm4_net2_ip1}
    check ip on vm    ${conn_id_2}    ${virshid4}    ifconfig eth1    ${vm4_net2_ip1}
    Ping From Virsh Console    ${virshid3}    ${vm4_net2_ip1}    ${conn_id_1}    , 0% packet loss
    ${output4}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid4}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    ${output4_1}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid4}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    ${mac4}    Extract_Mac_From_Ifconfig    ${output4}
    ${port_id4}    Get Port Id of instance    ${mac4}    ${conn_id_2}
    ${port4}    Get In Port Number For VM    ${Br_Name}    ${port_id4}
    log    ${port4}
    Set Global Variable    ${mac4}
    Set Global Variable    ${port4}
    ${mac4_1}    Extract_Mac_From_Ifconfig    ${output4_1}
    ${port_id4_1}    Get Port Id of instance    ${mac4_1}    ${conn_id_2}
    ${port4_1}    Get In Port Number For VM    ${Br_Name}    ${port_id4_1}
    log    ${port4_1}
    Set Global Variable    ${mac4_1}
    Set Global Variable    ${port4_1}
    Log    >>>table 0 check>>>
    Switch Connection    ${conn_id_2}
    ${metadatavalue4}    Wait Until Keyword Succeeds    50 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_2}
    ...    ${port4}
    ${metadatavalue4}    Wait Until Keyword Succeeds    50 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_2}
    ...    ${port4_1}
    Log    >>>Create a list for table 17 for validation-vm4>>>
    ${lower_mac4}    Convert To Lowercase    ${mac4}
    @{array17}    Create List    goto_table:45
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1    nd_target=${Prefixes[3]}1
    @{array50}    create list    dl_src=${lower_mac4}
    @{array51}    create list    dl_dst=${lower_mac4}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue4}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_2}    ${Br_Name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1

IPV6_Validate after adding IPv6 subnet on same virtual network and check the ping of IPv6 address of same network in single DPN.
    [Documentation]    Validate after adding IPv6 subnet on same virtual network and check the ping of IPv6 address of same network in single DPN.
    Switch Connection    ${conn_id_1}
    Create Subnet    ${Networks[2]}    ${Subnets[4]}    ${Prefixes[4]}/64    --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    Add Router Interface    ${Routers[0]}    ${Subnets[4]}
    sleep    4 minutes
    Switch Connection    ${conn_id_1}
    ${vm3_net2_ip2}    get ipv6 address for new network    ${VM_List[2]}    ${vm3_net2_ip1}    ${Networks[2]}    ${Prefixes[3]}    ${Prefixes[4]}
    Set Global Variable    ${vm3_net2_ip2}
    check ip on vm    ${conn_id_1}    ${virshid3}    ifconfig eth1    ${vm3_net2_ip2}
    ${vm6_net2_ip2}    get ipv6 address for new network    ${VM_List[5]}    ${vm6_net2_ip1}    ${Networks[2]}    ${Prefixes[3]}    ${Prefixes[4]}
    Set Global Variable    ${vm6_net2_ip2}
    check ip on vm    ${conn_id_1}    ${virshid6}    ifconfig eth1    ${vm6_net2_ip2}
    Ping From Virsh Console    ${virshid3}    ${vm6_net2_ip2}    ${conn_id_1}    , 0% packet loss
    Log    >>>table 0 check>>>
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_1}
    ...    ${port3}
    ${lower_mac3}    Convert To Lowercase    ${mac3}
    Log    >>>flow table validation for vm3>>>
    @{array17}    Create List    goto_table:45
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1    nd_target=${Prefixes[3]}1    nd_target=${Prefixes[4]}1
    @{array50}    create list    dl_src=${lower_mac3}
    @{array51}    create list    dl_dst=${lower_mac3}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue3}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_1}    ${Br_Name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1
    Log    >>>table 0 check>>>
    ${metadatavalue6}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_1}
    ...    ${port6}
    ${lower_mac6}    Convert To Lowercase    ${mac6}
    Log    >>>flow table validation for vm6>>>
    @{array17}    Create List    goto_table:45
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1    nd_target=${Prefixes[3]}1    nd_target=${Prefixes[4]}1
    @{array50}    create list    dl_src=${lower_mac6}
    @{array51}    create list    dl_dst=${lower_mac6}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue6}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_1}    ${Br_Name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1

IPV6_Validate after adding IPv6 subnet on same virtual network and check the ping of IPv6 address of same network in two DPN
    [Documentation]    Validate after adding IPv6 subnet on same virtual network and check the ping of IPv6 address of same network in two DPN
    ${vm4_net2_ip2}    get ipv6 address for new network    ${VM_List[3]}    ${vm4_net2_ip1}    ${Networks[2]}    ${Prefixes[3]}    ${Prefixes[4]}
    Set Global Variable    ${vm4_net2_ip2}
    check ip on vm    ${conn_id_2}    ${virshid4}    ifconfig eth1    ${vm4_net2_ip2}
    Ping From Virsh Console    ${virshid3}    ${vm4_net2_ip2}    ${conn_id_1}    , 0% packet loss
    Log    >>>table 0 check>>>
    Switch Connection    ${conn_id_2}
    ${metadatavalue4}    Wait Until Keyword Succeeds    50 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_2}
    ...    ${port4}
    Log    >>>Create a list for table 17 for validation-vm4>>>
    ${lower_mac4}    Convert To Lowercase    ${mac4}
    @{array17}    Create List    goto_table:45
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1    nd_target=${Prefixes[3]}1    nd_target=${Prefixes[4]}1
    @{array50}    create list    dl_src=${lower_mac4}
    @{array51}    create list    dl_dst=${lower_mac4}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue4}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_2}    ${Br_Name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1

IPV6_Validate after removing one of the IPv6 subnet and check the ping of IPv6 address of other subnet in single DPN.
    [Documentation]    Validate after removing one of the IPv6 subnet and check the ping of IPv6 address of other subnet in single DPN.
    Switch Connection    ${conn_id_1}
    Remove Interface    ${Routers[0]}    ${Subnets[4]}
    Switch Connection    ${conn_id_1}
    nova reboot    ${VM_List[2]}
    nova reboot    ${VM_List[5]}
    ${output3}    Wait Until Keyword Succeeds    120 sec    10 sec    check ip address in ifconfig output    ${virshid3}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    ${output5}    Wait Until Keyword Succeeds    120 sec    10 sec    check ip address in ifconfig output    ${virshid5}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    Should Contain    ${output3}    ${vm3_net2_ip1}
    Should Not Contain    ${output3}    ${vm3_net2_ip2}
    ${mac3}    Extract_Mac_From_Ifconfig    ${output3}
    ${port_id3}    Get Port Id of instance    ${mac3}    ${conn_id_1}
    ${port3}    Get In Port Number For VM    ${br_name}    ${port_id3}
    Set Global Variable    ${mac3}
    log    ${port3}
    Set Global Variable    ${port3}
    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid6}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}
    ...    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)
    ...    $
    ${output6}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid6}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    Should Contain    ${output6}    ${vm6_net2_ip1}
    Should Not Contain    ${output6}    ${vm6_net2_ip2}
    ${mac6}    Extract_Mac_From_Ifconfig    ${output6}
    ${port_id6}    Get Port Id of instance    ${mac6}    ${conn_id_1}
    ${port6}    Get In Port Number For VM    ${Br_Name}    ${port_id6}
    Set Global Variable    ${mac6}
    log    ${port6}
    Set Global Variable    ${port6}
    Ping From Virsh Console    ${virshid3}    ${vm6_net2_ip1}    ${conn_id_1}    , 0% packet loss
    Log    >>>table 0 check>>>
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_1}
    ...    ${port3}
    ${lower_mac3}    Convert To Lowercase    ${mac3}
    Log    >>>flow table validation for vm3>>>
    @{array17}    Create List    goto_table:45
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1    nd_target=${Prefixes[3]}1
    @{array50}    create list    dl_src=${lower_mac3}
    @{array51}    create list    dl_dst=${lower_mac3}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue3}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_1}    ${Br_Name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1
    Log    >>>table 0 check>>>
    ${metadatavalue6}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_1}
    ...    ${port6}
    ${lower_mac6}    Convert To Lowercase    ${mac6}
    Log    >>>flow table validation for vm6>>>
    @{array17}    Create List    goto_table:45
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1    nd_target=${Prefixes[3]}1
    @{array50}    create list    dl_src=${lower_mac6}
    @{array51}    create list    dl_dst=${lower_mac6}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue6}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_1}    ${Br_Name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1

IPV6_Validate after removing one of the IPv6 subnet and check the ping of IPv6 address of other subnet in two DPN.
    [Documentation]    Validate after removing one of the IPv6 subnet and check the ping of IPv6 address of other subnet in two DPN.
    Switch Connection    ${conn_id_1}
    nova reboot    ${VM_List[3]}
    ${output4}    Wait Until Keyword Succeeds    120 sec    10 sec    check ip address in ifconfig output    ${virshid4}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    Comment    ${output4}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid4}
    ...    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}
    ...    cirros    cubswin:)    $
    Should Contain    ${output4}    ${vm4_net2_ip1}
    Should Not Contain    ${output4}    ${vm4_net2_ip2}
    Ping From Virsh Console    ${virshid3}    ${vm4_net2_ip1}    ${conn_id_1}    , 0% packet loss
    ${mac4}    Extract_Mac_From_Ifconfig    ${output4}
    ${port_id4}    Get Port Id of instance    ${mac4}    ${conn_id_2}
    ${port4}    Get In Port Number For VM    ${Br_Name}    ${port_id4}
    Set Global Variable    ${mac4}
    log    ${port4}
    Set Global Variable    ${port4}
    Log    >>>table 0 check>>>
    Switch Connection    ${conn_id_2}
    ${metadatavalue4}    Wait Until Keyword Succeeds    50 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_2}
    ...    ${port4}
    Log    >>>Create a list for table 17 for validation-vm4>>>
    ${lower_mac4}    Convert To Lowercase    ${mac4}
    @{array17}    Create List    goto_table:45
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1    nd_target=${Prefixes[3]}1
    @{array50}    create list    dl_src=${lower_mac4}
    @{array51}    create list    dl_dst=${lower_mac4}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue4}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_2}    ${Br_Name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1

IPV6_Validate ping after rebooting the Neutron VM
    [Documentation]    Validate ping after rebooting the Neutron VM in single DPN.
    nova reboot    ${VM_list[2]}
    ${output3_1}    Wait Until Keyword Succeeds    120 sec    10 sec    check ip address in ifconfig output    ${virshid3}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    log    ${output3_1}
    ${ip_list3_1}    Wait Until Keyword Succeeds    90 sec    10 sec    Get VM Ip Addresses From Instance Details    ${VM_List[2]}    ${Networks[1]}
    Should Contain    ${output3_1}    ${ip_list3_1[0]}
    Should Contain    ${output3_1}    ${ip_list3_1[1]}
    ${mac3}    Extract_Mac_From_Ifconfig    ${output3_1}
    ${port_id3}    Get Port Id of instance    ${mac3}    ${conn_id_1}
    ${port3}    Get In Port Number For VM    ${Br_Name}    ${port_id3}
    Set Global Variable    ${mac3}
    log    ${port3}
    Set Global Variable    ${port3}
    Log    >>>table 0 check>>>
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_1}
    ...    ${port3}
    ${lower_mac3}    Convert To Lowercase    ${mac3}
    Log    >>>flow table validation for vm3>>>
    @{array17}    Create List    goto_table:45    goto_table:60
    @{array45}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1
    @{array50}    create list    dl_src=${lower_mac3}
    @{array51}    create list    dl_dst=${lower_mac3}
    @{array60}    Create List    dl_src=${lower_mac3}
    @{arraylist}    Create List    ${array17}    ${array45}    ${array50}    ${array51}    ${array60}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue3}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${Tables[5]}    ${Tables[6]}    ${Tables[7]}
    ${prefixstr1}    Remove String    ${Prefixes[2]}    ::
    ${v4prefix}    Get Substring    ${V4subnets[0]}    \    -1
    ${ip_list6}    Wait Until Keyword Succeeds    50 sec    10 sec    Get Ip List Specific To Prefixes    ${VM_List[5]}    ${Networks[1]}
    ...    ${prefixstr1}    ${v4prefix}
    Set Global Variable    ${ip_list6}
    ${vm6ip}    Get Subnet Specific Ipv6    ${ip_list6}    ${Prefixes[2]}
    Set Global Variable    ${vm6ip}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_1}    ${Br_Name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1
    Ping From Virsh Console    ${virshid3}    ${ip_list6[0]}    ${conn_id_1}    , 0% packet loss
    Ping From Virsh Console    ${virshid3}    ${ip_list6[1]}    ${conn_id_1}    , 0% packet loss

IPV6_Validate after deleting the VM and check the Open flow table should clear entry of corresponding VMs.
    [Documentation]    Validate after deleting the VM and check the Open flow table should clear entry of corresponding VMs.
    Switch Connection    ${conn_id_1}
    log    >>>deleting the vms>>>
    @{vm_list}    Create List    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[2]}    ${VM_list[3]}    ${VM_list[4]}
    ...    ${VM_list[5]}
    : FOR    ${vm}    IN    @{vm_list}
    \    Delete Vm Instance    ${vm}
    Switch Connection    ${conn_id_1}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_list[0]}    ${mac1}    ${conn_id_1}
    ...    ${br_name1}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_list[1]}    ${mac2}    ${conn_id_1}
    ...    ${br_name1}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_list[2]}    ${mac3}    ${conn_id_1}
    ...    ${br_name1}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_list[3]}    ${mac4}    ${conn_id_2}
    ...    ${br_name1}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_list[4]}    ${mac5}    ${conn_id_2}
    ...    ${br_name1}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_list[5]}    ${mac6}    ${conn_id_1}
    ...    ${br_name1}
    Switch Connection    ${conn_id_1}
    ${cmd}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${Br_Name} | grep table=0
    Should not Contain    ${cmd}    in_port=${port1}
    Should not Contain    ${cmd}    in_port=${port2}
    Should not Contain    ${cmd}    in_port=${port3}
    Should not Contain    ${cmd}    in_port=${port6}
    Switch Connection    ${conn_id_2}
    ${cmd}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${Br_Name} | grep table=0
    Should not Contain    ${cmd}    in_port=${port4}
    Should not Contain    ${cmd}    in_port=${port5}
    Remove Interface    ${Routers[0]}    ${Subnets[3]}
    Remove Interface    ${Routers[0]}    ${Subnets[2]}
    Remove Interface    ${Routers[0]}    ${Subnets[1]}
    Remove Interface    ${Routers[0]}    ${Subnets[0]}
    Delete SubNet    ${Subnets[4]}
    Delete SubNet    ${Subnets[3]}
    Delete SubNet    ${Subnets[2]}
    Delete SubNet    ${Subnets[1]}
    Delete SubNet    ${Subnets[0]}
    Delete SubNet    ${V4subnet_Names[0]}
    Delete Network    ${Networks[2]}
    Delete Network    ${Networks[1]}
    Delete Network    ${Networks[0]}
    Delete Router    ${Routers[0]}
    [Teardown]

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

check ip address in ifconfig output
    [Arguments]    ${virshid}    ${cmd}    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    ...    ${DEVSTACK_DEPLOY_PATH}    ${username}    ${pwd}    ${vmprompt}
    ${output}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    ${username}
    ...    ${pwd}    ${vmprompt}
    [Return]    ${output}

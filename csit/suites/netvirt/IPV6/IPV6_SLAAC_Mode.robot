*** Settings ***
Documentation     This test suite for \ IPV6 addr \ assignment in SLAAC mode.
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
@{Networks}       mynet1    mynet2    mynet3
@{Subnets}        ipv6s1    ipv6s2    ipv6s3    ipv6s4    ipv6s5
@{VM_List}        vm1    vm2    vm3    vm4    vm5    vm6    vm7
@{Routers}        router1    router2
@{Prefixes}       2001:db8:1234::    2001:db8:5678::    2001:db8:4321::    2001:db8:6789::    2001:db8:9999::
@{V4subnets}      13.0.0.0    14.0.0.0
@{V4subnet_Names}    subnet1v4    subnet2v4
${Br_Name}        br-int
@{Login_Credentials}    stack    stack    root    password
${Devstack_Path}    /opt/stack/devstack
@{Direction}      ingress    egress    both
@{Image_Name}     cirros-0.3.4-x86_64-uec    ubuntu-sg
${netvirt_config_dir}    ${CURDIR}/../../../variables/netvirt
@{dpip}           20.0.0.9    20.0.0.10
${Itm_Created}    TZA
${Bridge-1}       br0
${Bridge-2}       br0
${Interface-1}    eth1
${Interface-2}    eth1
${Flavor_Name}    m1.nano
@{Tables}         table=0    table=17    table=40    table=41    table=45    table=50    table=51
...               table=60    table=220    table=251    table=252

*** Test Cases ***
Validate multiple ipv6 addr assignment on single interface of VMs.
    [Documentation]    Validate multiple ipv6 addr assignment for VMs in two DPN.
    Create Topology    ${Image_Name[0]}
    Log    >>>table 0 check>>>
    ${metadatavalue1}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
    ...    ${port1}
    ${metadatavalue2}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
    ...    ${port2}
    ${lower_mac1}    Convert To Lowercase    ${mac1}
    Log    >>>flow table validation for vm1>>>
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
    Log    >>>flow table validation for vm2>>>
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

Validate the persistence of IPv6 address after rebooting the VM .
    [Documentation]    Validate the persistence of IPv6 address after rebooting the VM in single DPN.
    nova reboot    ${VM_list[0]}
    ${output1}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid1}
    ...    ifconfig eth0
    log    ${output1}
    Should Contain    ${output1}    ${ip_list1[0]}
    Should Contain    ${output1}    ${ip_list1[1]}
    ${mac1}    Extract Mac    ${output1}
    ${port_id1}    get port id    ${mac1}    ${conn_id_1}
    ${port1}    Get Port Number    ${Br_Name}    ${port_id1}
    Set Global Variable    ${mac1}
    log    ${port1}
    Set Global Variable    ${port1}
    Log    >>>table 0 check>>>
    ${metadatavalue1}    Wait Until Keyword Succeeds    30 sec    10 sec    table 0 check    ${Br_Name}    ${conn_id_1}
    ...    ${port1}
    ${lower_mac1}    Convert To Lowercase    ${mac1}
    Log    >>>flow table validation for vm1>>>
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

Verifying the IPv6 \ addr assignment by configuring invalid ipv6 prefix.
    [Documentation]    Verifying the ipv6 \ addr assignment by configuring invalid ipv6 prefix in single DPN.
    log    creating subnet with invalid prefix
    ${subnet_list}=    Write Commands Until Expected Prompt    neutron subnet-list    $    30
    log    ${subnet_list}
    ${invalid_subnet}    Set Variable    newsubnet
    Wait Until Keyword Succeeds    30 sec    10 sec    invalid subnet    ${Networks[0]}    ${invalid_subnet}

Validate IPv6 RA and ADDR mode through rest api \ after creating IPv6 subnet in SLACC mode
    [Documentation]    Validate IPv6 RA and ADDR mode through rest api \ after creating IPv6 subnet in SLACC mode in single DPN
    @{ipv6_mode_list}=    Create List    "ipv6_address_mode" : "slaac"    "ipv6_ra_mode" : "slaac"
    Check For Elements At URI    /controller/nb/v2/neutron/subnets    ${ipv6_mode_list}

Validate IPv6 addr on VM's interface after removing the ipv6 subnet
    [Documentation]    Validate IPv6 addr on VM's interface after removing the ipv6 subnet in single DPN.
    Remove Interface    ${Routers[0]}    ${Subnets[1]}
    Switch Connection    ${conn_id_1}
    nova reboot    ${VM_list[0]}
    ${output1}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid1}
    ...    ifconfig eth0
    ${vm1ip_subnet2}    get subnet specific ip    ${ip_list1}    ${Prefixes[1]}
    Set Global Variable    ${vm1ip_subnet2}
    log    ${output1}
    ${mac1}    Extract Mac    ${output1}
    ${port_id1}    get port id    ${mac1}    ${conn_id_1}
    ${port1}    Get Port Number    ${Br_Name}    ${port_id1}
    Set Global Variable    ${mac1}
    log    ${port1}
    Set Global Variable    ${port1}
    Should Not Contain    ${output1}    ${vm1ip_subnet2}
    Log    >>>table 45 check-vm1>>>
    @{array}    create list    nd_target=${Prefixes[1]}1
    table check with negative scenario    ${conn_id_1}    ${Br_Name}    table=45|grep actions=CONTROLLER:65535    ${array}

Verify the ipv6 addr on the VM's interface after adding the subnet.
    [Documentation]    Verify the ipv6 addr on the VM's interface after adding the subnet in single DPN.
    Add Router Interface    ${Routers[0]}    ${Subnets[1]}
    Wait Until Keyword Succeeds    300 sec    10 sec    check ip on vm    ${conn_id_1}    ${virshid1}    ifconfig eth0
    ...    ${vm1ip_subnet2}
    Log    >>>table 0 check>>>
    ${metadatavalue1}    Wait Until Keyword Succeeds    30 sec    10 sec    table 0 check    ${Br_Name}    ${conn_id_1}
    ...    ${port1}
    ${lower_mac1}    Convert To Lowercase    ${mac1}
    Log    >>>flow table validation for vm1>>>
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

Validating the dual stack addr assignment on VM with the ipv6 SLAAC mode configuration
    [Documentation]    Validating the dual stack addr assignment on VM with the ipv6 SLAAC mode configuration in single DPN.
    Create Network    ${Networks[1]}
    Create Subnet    ${Networks[1]}    ${Subnets[2]}    ${Prefixes[2]}/64    --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    Create Subnet    ${Networks[1]}    ${V4subnet_Names[0]}    ${V4subnets[0]}/24    --enable-dhcp
    Add Router Interface    ${Routers[0]}    ${Subnets[2]}
    Remove All Elements If Exist    ${CONFIG_API}/dhcpservice-config:dhcpservice-config/
    Post Elements To URI From File    ${CONFIG_API}/    ${netvirt_config_dir}/enable_dhcp.json
    @{list}=    Create List    "controller-dhcp-enabled"    true
    Check For Elements At URI    ${CONFIG_API}/dhcpservice-config:dhcpservice-config/    ${list}
    Switch Connection    ${conn_id_1}
    Spawn Vm    ${Networks[1]}    ${VM_List[2]}    ${Image_Name[0]}    ${hostname1}    ${Flavor_Name}
    ${prefixstr1}    Remove String    ${Prefixes[2]}    ::
    ${v4prefix}    Get Substring    ${V4subnets[0]}    \    -1
    ${ip_list3}    Wait Until Keyword Succeeds    50 sec    10 sec    Get Ip List Specific To Prefixes    ${VM_List[2]}    ${Networks[1]}
    ...    ${prefixstr1}    ${v4prefix}
    Set Global Variable    ${ip_list3}
    ${vm3ip}    Get Subnet Specific Ip    ${ip_list3}    ${Prefixes[2]}
    Set Global Variable    ${vm3ip}
    ${vm3v4ip}    Set Variable If    '${vm3ip}'=='${ip_list3[0]}'    ${ip_list3[0]}    ${ip_list3[1]}
    Set Global Variable    ${vm3v4ip}
    ${virshid3}    Get Vm Instance    ${VM_list[2]}
    Set Global Variable    ${virshid3}
    ${output3}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid3}
    ...    ifconfig eth0
    log    ${output3}
    ${linkaddr3}    extract linklocal addr    ${output3}
    Set Global Variable    ${linkaddr3}
    Should Contain    ${output3}    ${ip_list3[0]}
    Should Contain    ${output3}    ${ip_list3[1]}
    Set Global Variable    ${ip_list3[0]}
    Set Global Variable    ${ip_list3[1]}
    ${mac3}    Extract Mac    ${output3}
    ${port_id3}    get port id    ${mac3}    ${conn_id_1}
    ${port3}    Get Port Number    ${Br_Name}    ${port_id3}
    log    ${port3}
    Set Global Variable    ${mac3}
    Set Global Variable    ${port3}
    Log    >>>table 0 check>>>
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
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

Validate persistence of dual stack addr of Neutron VMs after rebooting VM.
    [Documentation]    Validate persistence of dual stack addr on \ Neutron VMs \ after rebooting VM in single DPN.
    nova reboot    ${VM_list[2]}
    ${output3}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid3}
    ...    ifconfig eth0
    Should Contain    ${output3}    ${ip_list3[0]}
    Should Contain    ${output3}    ${ip_list3[1]}
    ${mac3}    Extract Mac    ${output3}
    ${port_id3}    get port id    ${mac3}    ${conn_id_1}
    ${port3}    Get Port Number    ${Br_Name}    ${port_id3}
    Set Global Variable    ${mac3}
    log    ${port3}
    Set Global Variable    ${port3}
    Log    >>>table 0 check>>>
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
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

Validate after removing the one of Ipv6 subnet from network and it should be deleted from the VM's interface accordingly.
    [Documentation]    Validate after removing the one of Ipv6 subnet from network and it should be deleted from the VM's interface accordingly.
    Remove Interface    ${Routers[0]}    ${Subnets[2]}
    Switch Connection    ${conn_id_1}
    nova reboot    ${VM_list[2]}
    ${output3}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid3}
    ...    ifconfig eth0
    log    ${output3}
    Should Not Contain    ${output3}    ${vm3ip}
    ${mac3}    Extract Mac    ${output3}
    ${port_id3}    get port id    ${mac3}    ${conn_id_1}
    ${port3}    Get Port Number    ${Br_Name}    ${port_id3}
    Set Global Variable    ${mac3}
    log    ${port3}
    Set Global Variable    ${port3}
    Log    >>>table 0 check>>>
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
    ...    ${port3}
    ${lower_mac3}    Convert To Lowercase    ${mac3}
    Log    >>>flow table validation for vm3>>>
    @{array17}    Create List    goto_table:60
    @{array60}    Create List    dl_src=${lower_mac3}
    @{arraylist}    Create List    ${array17}    ${array60}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadatavalue3}    ${Tables[7]}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_1}    ${Br_Name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1
    @{array45}    create list    nd_target=${Prefixes[2]}1
    Table Check With Negative Scenario    ${conn_id_1}    ${Br_Name}    ${Tables[4]} | grep actions=CONTROLLER:65535    ${array45}

Validate ipv4 address on VM's interface after removing the ipv4 subnet from network.
    [Documentation]    Validate ipv6 addr assignment on VM's interface \ after adding subnet to virtual network in single DPN.
    Add Router Interface    ${Routers[0]}    ${Subnets[2]}
    ${output3}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid3}
    ...    ifconfig eth0
    Should Contain    ${output3}    ${ip_list3[0]}
    Should Contain    ${output3}    ${ip_list3[1]}
    Log    >>>table 0 check>>>
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
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

Validate after removing the one of Ipv4 subnet from network and it should be deleted from the VM.
    [Documentation]    Validate ipv4 address on VM's interface after removing the ipv4 subnet from network in single DPN.
    Delete Vm Instance    ${VM_List[2]}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_List[2]}    ${mac3}    ${conn_id_1}
    Delete SubNet    ${V4subnet_Names[0]}
    Switch Connection    ${conn_id_1}
    Spawn Vm    ${Networks[1]}    ${VM_List[2]}    ${Image_Name[0]}    ${hostname1}    ${Flavor_Name}
    ${vm3ip}    Get Vm Ipv6 Addr    ${VM_List[2]}    ${Networks[1]}
    Set Global Variable    ${vm3ip}
    ${virshid3}    Get Vm Instance    ${VM_list[2]}
    Set Global Variable    ${virshid3}
    ${output3}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid3}
    ...    ifconfig eth0
    Should Not Contain    ${output3}    ${vm3v4ip}
    ${mac3}    Extract Mac    ${output3}
    ${port_id3}    get port id    ${mac3}    ${conn_id_1}
    ${port3}    Get Port Number    ${Br_Name}    ${port_id3}
    log    ${port3}
    Set Global Variable    ${mac3}
    Set Global Variable    ${port3}
    Log    >>>table 0 check>>>
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
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

Validate ipv4 address on VM's interface after adding \ the ipv4 subnet from network
    [Documentation]    Validate ipv4 address on VM's interface after adding \ the ipv4 subnet from network in single DPN.
    Create Subnet    ${Networks[1]}    ${V4subnet_Names[0]}    ${V4subnets[0]}/24    --enable-dhcp
    Switch Connection    ${conn_id_1}
    ${ip_list3}    Wait Until Keyword Succeeds    90 sec    10 sec    get both ip    ${VM_List[2]}    ${Networks[1]}
    Set Global Variable    ${ip_list3}
    ${vm3v4ip}    Set Variable If    '${vm3ip}'=='${ip_list3[0]}'    ${ip_list3[0]}    ${ip_list3[1]}
    Set Global Variable    ${vm3v4ip}
    ${output3}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid3}
    ...    ifconfig eth0
    Should Contain    ${output3}    ${vm3v4ip}
    Log    >>>table 0 check>>>
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
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

Validate ping between VMs in single DPN.
    [Documentation]    Validate ping between VMs in single DPN.
    Delete Vm Instance    ${VM_List[2]}
    Switch Connection    ${conn_id_1}
    Spawn Vm    ${Networks[1]}    ${VM_List[2]}    ${Image_Name[0]}    ${hostname1}    ${Flavor_Name}
    ${vm3ip}    Get Vm Ipv6 Addr    ${VM_List[2]}    ${Networks[1]}
    Set Global Variable    ${vm3ip}
    ${virshid3}    Get Vm Instance    ${VM_list[2]}
    Set Global Variable    ${virshid3}
    ${output3}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid3}
    ...    ifconfig eth0
    Should Not Contain    ${output3}    ${vm3v4ip}
    ${mac3}    Extract Mac    ${output3}
    ${port_id3}    get port id    ${mac3}    ${conn_id_1}
    ${port3}    Get Port Number    ${Br_Name}    ${port_id3}
    log    ${port3}
    Set Global Variable    ${mac3}
    Set Global Variable    ${port3}
    ${linkaddr3}    extract linklocal addr    ${output3}
    Set Global Variable    ${linkaddr3}
    Spawn Vm    ${Networks[1]}    ${VM_List[5]}    ${Image_Name[0]}    ${hostname1}    ${Flavor_Name}
    ${prefixstr1}    Remove String    ${Prefixes[2]}    ::
    ${v4prefix}    Get Substring    ${V4subnets[0]}    \    -1
    ${ip_list6}    Wait Until Keyword Succeeds    50 sec    10 sec    Get Ip List Specific To Prefixes    ${VM_List[5]}    ${Networks[1]}
    ...    ${prefixstr1}    ${v4prefix}
    Set Global Variable    ${ip_list6}
    ${vm6ip}    Get Subnet Specific Ip    ${ip_list6}    ${Prefixes[2]}
    Set Global Variable    ${vm6ip}
    ${vm6v4ip}    Set Variable If    '${vm6ip}'=='${ip_list6[0]}'    ${ip_list6[0]}    ${ip_list6[1]}
    Set Global Variable    ${vm6v4ip}
    ${virshid6}    Get Vm Instance    ${VM_List[5]}
    Set Global Variable    ${virshid6}
    ${output6}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid6}
    ...    ifconfig eth0
    log    ${output6}
    ${linkaddr6}    extract linklocal addr    ${output6}
    Set Global Variable    ${linkaddr6}
    Should Contain    ${output6}    ${ip_list6[0]}
    Should Contain    ${output6}    ${ip_list6[1]}
    Set Global Variable    ${ip_list6}
    Set Global Variable    ${ip_list6}
    ${mac6}    Extract Mac    ${output6}
    ${port_id6}    get port id    ${mac6}    ${conn_id_1}
    ${port6}    Get Port Number    ${Br_Name}    ${port_id6}
    log    ${port6}
    Set Global Variable    ${mac6}
    Set Global Variable    ${port6}
    Log    >>>table 0 check>>>
    ${metadatavalue6}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
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

Validates ping6 between VMs in two DPN.
    [Documentation]    Validates ping6 between VMs in two DPN.
    Switch Connection    ${conn_id_2}
    Spawn Vm    ${Networks[1]}    ${VM_List[3]}    ${Image_Name[0]}    ${hostname2}    ${Flavor_Name}
    ${prefixstr1}    Remove String    ${Prefixes[2]}    ::
    ${v4prefix}    Get Substring    ${V4subnets[0]}    \    -1
    ${ip_list4}    Wait Until Keyword Succeeds    50 sec    10 sec    Get Ip List Specific To Prefixes    ${VM_List[3]}    ${Networks[1]}
    ...    ${prefixstr1}    ${v4prefix}
    Set Global Variable    ${ip_list4}
    Switch Connection    ${conn_id_1}
    ${vm4ip}    Get Subnet Specific Ip    ${ip_list4}    ${Prefixes[2]}
    ${virshid4}    Get Vm Instance    ${VM_list[3]}
    Set Global Variable    ${virshid4}
    ${output4}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_2}    ${virshid4}
    ...    ifconfig eth0
    log    ${output4}
    ${linkaddr4}    extract linklocal addr    ${output4}
    Set Global Variable    ${linkaddr4}
    Should Contain    ${output4}    ${ip_list4[0]}
    Should Contain    ${output4}    ${ip_list4[1]}
    Set Global Variable    ${ip_list4[0]}
    Set Global Variable    ${ip_list4[1]}
    ${mac4}    Extract Mac    ${output4}
    ${port_id4}    get port id    ${mac4}    ${conn_id_2}
    ${port4}    Get Port Number    ${Br_Name}    ${port_id4}
    log    ${port4}
    Set Global Variable    ${mac4}
    Set Global Variable    ${port4}
    Log    >>>table 0 check>>>
    Switch Connection    ${conn_id_2}
    ${metadatavalue4}    Wait Until Keyword Succeeds    50 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_2}
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

Validate ping after rebooting the Neutron VM in two DPN.
    [Documentation]    Validate ping after rebooting the Neutron VM in two DPN.
    nova reboot    ${VM_list[3]}
    ${output4}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_2}    ${virshid4}
    ...    ifconfig eth0
    log    ${output4}
    Should Contain    ${output4}    ${ip_list4[0]}
    Should Contain    ${output4}    ${ip_list4[1]}
    ${mac4}    Extract Mac    ${output4}
    ${port_id4}    get port id    ${mac4}    ${conn_id_2}
    ${port4}    Get Port Number    ${Br_Name}    ${port_id4}
    Set Global Variable    ${mac4}
    log    ${port4}
    Set Global Variable    ${port4}
    Log    >>>table 0 check>>>
    Switch Connection    ${conn_id_2}
    ${metadatavalue4}    Wait Until Keyword Succeeds    50 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_2}
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

Validate ipv6 addr assignment with two virtual network in single DPN.
    [Documentation]    Validate ipv6 addr assignment with two virtual network in single DPN.
    Create Network    ${Networks[2]}
    Create Subnet    ${Networks[2]}    ${Subnets[3]}    ${Prefixes[3]}/64    --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    Add Router Interface    ${Routers[0]}    ${Subnets[3]}
    Switch Connection    ${conn_id_1}
    Delete Vm Instance    ${VM_List[2]}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_List[2]}    ${mac3}    ${conn_id_1}
    Delete Vm Instance    ${VM_List[5]}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_List[5]}    ${mac6}    ${conn_id_1}
    Switch Connection    ${conn_id_1}
    Spawn Vm    ${Networks[1]}    ${VM_List[2]}    ${Image_Name[0]}    ${hostname1}    ${Flavor_Name}    --nic net-name=${Networks[2]}
    Spawn Vm    ${Networks[1]}    ${VM_List[5]}    ${Image_Name[0]}    ${hostname1}    ${Flavor_Name}    --nic net-name=${Networks[2]}
    ${virshid3}    Get Vm Instance    ${VM_list[2]}
    Set Global Variable    ${virshid3}
    ${virshid6}    Get Vm Instance    ${VM_List[5]}
    Set Global Variable    ${virshid6}
    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid3}    sudo ifconfig eth1 up
    ${vm3_net2_ip1}    get network specific ip address    ${VM_List[2]}    ${Networks[2]}
    Set Global Variable    ${vm3_net2_ip1}
    sleep    30
    check ip on vm    ${conn_id_1}    ${virshid3}    ifconfig eth1    ${vm3_net2_ip1}
    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid6}    sudo ifconfig eth1 up
    ${vm6_net2_ip1}    get network specific ip address    ${VM_List[5]}    ${Networks[2]}
    Set Global Variable    ${vm6_net2_ip1}
    sleep    30
    check ip on vm    ${conn_id_1}    ${virshid6}    ifconfig eth1    ${vm6_net2_ip1}
    Ping From Virsh Console    ${virshid3}    ${vm6_net2_ip1}    ${conn_id_1}    , 0% packet loss
    ${output3}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid3}
    ...    ifconfig eth0
    ${output3_1}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid3}
    ...    ifconfig eth1
    ${mac3}    Extract Mac    ${output3}
    ${port_id3}    get port id    ${mac3}    ${conn_id_1}
    ${port3}    Get Port Number    ${Br_Name}    ${port_id3}
    log    ${port3}
    Set Global Variable    ${mac3}
    Set Global Variable    ${port3}
    ${mac3_1}    Extract Mac    ${output3_1}
    ${port_id3_1}    get port id    ${mac3_1}    ${conn_id_1}
    ${port3_1}    Get Port Number    ${Br_Name}    ${port_id3_1}
    log    ${port3_1}
    Set Global Variable    ${mac3_1}
    Set Global Variable    ${port3_1}
    ${output6}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid6}
    ...    ifconfig eth0
    ${output6_1}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid6}
    ...    ifconfig eth1
    ${mac6}    Extract Mac    ${output6}
    ${port_id6}    get port id    ${mac6}    ${conn_id_1}
    ${port6}    Get Port Number    ${Br_Name}    ${port_id6}
    log    ${port6}
    Set Global Variable    ${mac6}
    Set Global Variable    ${port6}
    ${mac6_1}    Extract Mac    ${output6_1}
    ${port_id6_1}    get port id    ${mac6_1}    ${conn_id_1}
    ${port6_1}    Get Port Number    ${Br_Name}    ${port_id6_1}
    log    ${port6_1}
    Set Global Variable    ${mac6_1}
    Set Global Variable    ${port6_1}
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
    ...    ${port3}
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
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
    ${metadatavalue6}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
    ...    ${port6}
    ${metadatavalue6}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
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

Validate ipv6 addr assignment with two virtual network in two DPN.
    [Documentation]    Validate ipv6 addr assignment with two virtual network in two DPN.
    Switch Connection    ${conn_id_1}
    Delete Vm Instance    ${VM_List[3]}
    Switch Connection    ${conn_id_1}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_List[3]}    ${mac4}    ${conn_id_2}
    Switch Connection    ${conn_id_1}
    Spawn Vm    ${Networks[1]}    ${VM_List[3]}    ${Image_Name[0]}    ${hostname2}    ${Flavor_Name}    --nic net-name=${Networks[2]}
    ${virshid4}    Get Vm Instance    ${VM_List[3]}
    Set Global Variable    ${virshid4}
    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_2}    ${virshid4}    sudo ifconfig eth1 up
    ${vm4_net2_ip1}    get network specific ip address    ${VM_List[3]}    ${Networks[2]}
    Set Global Variable    ${vm4_net2_ip1}
    check ip on vm    ${conn_id_2}    ${virshid4}    ifconfig eth1    ${vm4_net2_ip1}
    Ping From Virsh Console    ${virshid3}    ${vm4_net2_ip1}    ${conn_id_1}    , 0% packet loss
    ${output4}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_2}    ${virshid4}
    ...    ifconfig eth0
    ${output4_1}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_2}    ${virshid4}
    ...    ifconfig eth1
    ${mac4}    Extract Mac    ${output4}
    ${port_id4}    get port id    ${mac4}    ${conn_id_2}
    ${port4}    Get Port Number    ${Br_Name}    ${port_id4}
    log    ${port4}
    Set Global Variable    ${mac4}
    Set Global Variable    ${port4}
    ${mac4_1}    Extract Mac    ${output4_1}
    ${port_id4_1}    get port id    ${mac4_1}    ${conn_id_2}
    ${port4_1}    Get Port Number    ${Br_Name}    ${port_id4_1}
    log    ${port4_1}
    Set Global Variable    ${mac4_1}
    Set Global Variable    ${port4_1}
    Log    >>>table 0 check>>>
    Switch Connection    ${conn_id_2}
    ${metadatavalue4}    Wait Until Keyword Succeeds    50 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_2}
    ...    ${port4}
    ${metadatavalue4}    Wait Until Keyword Succeeds    50 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_2}
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

Verifying ping6 on VMs with multiple virtual networks
    [Documentation]    Verifying ping6 on VMs with multiple virtual networks in single DPN.
    Switch Connection    ${conn_id_1}
    Create Subnet    ${Networks[2]}    ${Subnets[4]}    ${Prefixes[4]}/64    --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    Add Router Interface    ${Routers[0]}    ${Subnets[4]}
    sleep    4 minutes
    Switch Connection    ${conn_id_1}
    ${vm3_net2_ip2}    get ipv6 new    ${VM_List[2]}    ${vm3_net2_ip1}    ${Networks[2]}    ${Prefixes[3]}    ${Prefixes[4]}
    Set Global Variable    ${vm3_net2_ip2}
    check ip on vm    ${conn_id_1}    ${virshid3}    ifconfig eth1    ${vm3_net2_ip2}
    ${vm6_net2_ip2}    get ipv6 new    ${VM_List[5]}    ${vm6_net2_ip1}    ${Networks[2]}    ${Prefixes[3]}    ${Prefixes[4]}
    Set Global Variable    ${vm6_net2_ip2}
    check ip on vm    ${conn_id_1}    ${virshid6}    ifconfig eth1    ${vm6_net2_ip2}
    Ping From Virsh Console    ${virshid3}    ${vm6_net2_ip2}    ${conn_id_1}    , 0% packet loss
    Log    >>>table 0 check>>>
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
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
    ${metadatavalue6}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
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

Verifying ping6 after removing one of the ipv6 subnet from any virtual networks in single DPN.
    [Documentation]    Verifying ping6 on VMs with multiple virtual networks in two DPN.
    ${vm4_net2_ip2}    get ipv6 new    ${VM_List[3]}    ${vm4_net2_ip1}    ${Networks[2]}    ${Prefixes[3]}    ${Prefixes[4]}
    Set Global Variable    ${vm4_net2_ip2}
    check ip on vm    ${conn_id_2}    ${virshid4}    ifconfig eth1    ${vm4_net2_ip2}
    Ping From Virsh Console    ${virshid3}    ${vm4_net2_ip2}    ${conn_id_1}    , 0% packet loss
    Log    >>>table 0 check>>>
    Switch Connection    ${conn_id_2}
    ${metadatavalue4}    Wait Until Keyword Succeeds    50 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_2}
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

Validate after removing one of the IPv6 subnet and check the ping of IPv6 address of other subnet in single DPN.
    [Documentation]    Verifying ping6 after removing one of the ipv6 subnet from any virtual networks in single DPN.
    Switch Connection    ${conn_id_1}
    Remove Interface    ${Routers[0]}    ${Subnets[4]}
    Switch Connection    ${conn_id_1}
    nova reboot    ${VM_List[2]}
    nova reboot    ${VM_List[5]}
    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid3}    sudo ifconfig eth1 up
    ${output3}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid3}
    ...    ifconfig eth1
    Should Contain    ${output3}    ${vm3_net2_ip1}
    Should Not Contain    ${output3}    ${vm3_net2_ip2}
    ${mac3}    Extract Mac    ${output3}
    ${port_id3}    get port id    ${mac3}    ${conn_id_1}
    ${port3}    Get Port Number    ${Br_Name}    ${port_id3}
    Set Global Variable    ${mac3}
    log    ${port3}
    Set Global Variable    ${port3}
    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid6}    sudo ifconfig eth1 up
    ${output6}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid6}
    ...    ifconfig eth1
    Should Contain    ${output6}    ${vm6_net2_ip1}
    Should Not Contain    ${output6}    ${vm6_net2_ip2}
    ${mac6}    Extract Mac    ${output6}
    ${port_id6}    get port id    ${mac6}    ${conn_id_1}
    ${port6}    Get Port Number    ${Br_Name}    ${port_id6}
    Set Global Variable    ${mac6}
    log    ${port6}
    Set Global Variable    ${port6}
    Ping From Virsh Console    ${virshid3}    ${vm6_net2_ip1}    ${conn_id_1}    , 0% packet loss
    Log    >>>table 0 check>>>
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
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
    ${metadatavalue6}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
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

Verifying ping6 after removing one of the ipv6 subnet from any virtual networks
    [Documentation]    Verifying ping6 after removing one of the ipv6 subnet from any virtual networks in two DPN.
    Switch Connection    ${conn_id_1}
    nova reboot    ${VM_List[3]}
    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_2}    ${virshid4}    sudo ifconfig eth1 up
    ${output4}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_2}    ${virshid4}
    ...    ifconfig eth1
    Should Contain    ${output4}    ${vm4_net2_ip1}
    Should Not Contain    ${output4}    ${vm4_net2_ip2}
    Ping From Virsh Console    ${virshid3}    ${vm4_net2_ip1}    ${conn_id_1}    , 0% packet loss
    ${mac4}    Extract Mac    ${output4}
    ${port_id4}    get port id    ${mac4}    ${conn_id_2}
    ${port4}    Get Port Number    ${Br_Name}    ${port_id4}
    Set Global Variable    ${mac4}
    log    ${port4}
    Set Global Variable    ${port4}
    Log    >>>table 0 check>>>
    Switch Connection    ${conn_id_2}
    ${metadatavalue4}    Wait Until Keyword Succeeds    50 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_2}
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

Verify \ ping after rebooting the Neutron VM
    [Documentation]    Verify \ ping after rebooting the Neutron VM in single DPN.
    nova reboot    ${VM_list[2]}
    ${output3_1}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid3}
    ...    ifconfig eth0
    log    ${output3_1}
    ${ip_list3_1}    Wait Until Keyword Succeeds    90 sec    10 sec    get both ip    ${VM_List[2]}    ${Networks[1]}
    Should Contain    ${output3_1}    ${ip_list3_1[0]}
    Should Contain    ${output3_1}    ${ip_list3_1[1]}
    ${mac3}    Extract Mac    ${output3_1}
    ${port_id3}    get port id    ${mac3}    ${conn_id_1}
    ${port3}    Get Port Number    ${Br_Name}    ${port_id3}
    Set Global Variable    ${mac3}
    log    ${port3}
    Set Global Variable    ${port3}
    Log    >>>table 0 check>>>
    ${metadatavalue3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
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
    ${vm6ip}    Get Subnet Specific Ip    ${ip_list6}    ${Prefixes[2]}
    Set Global Variable    ${vm6ip}
    ${index}    Set Variable    int(0)
    : FOR    ${table}    IN    @{tablelist}
    \    table check    ${conn_id_1}    ${Br_Name}    ${table}    ${arraylist[${index}]}
    \    ${index}    Evaluate    ${index}+1
    Ping From Virsh Console    ${virshid3}    ${ip_list6[0]}    ${conn_id_1}    , 0% packet loss
    Ping From Virsh Console    ${virshid3}    ${ip_list6[1]}    ${conn_id_1}    , 0% packet loss

Validate the flows wrt VM in the flow table after the VMs
    [Documentation]    Validate the flows wrt VM in the flow table after the VMs in two DPN
    Switch Connection    ${conn_id_1}
    log    >>>deleting the vms>>>
    @{vm_list}    Create List    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[2]}    ${VM_list[3]}    ${VM_list[4]}
    ...    ${VM_list[5]}
    : FOR    ${vm}    IN    @{vm_list}
    \    Delete Vm Instance    ${vm}
    Switch Connection    ${conn_id_1}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_list[0]}    ${mac1}    ${conn_id_1}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_list[1]}    ${mac2}    ${conn_id_1}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_list[2]}    ${mac3}    ${conn_id_1}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_list[3]}    ${mac4}    ${conn_id_2}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_list[4]}    ${mac5}    ${conn_id_2}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_list[5]}    ${mac6}    ${conn_id_1}
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

*** Keywords ***
Virsh Output
    [Arguments]    ${conn_id}    ${virshid1}    ${cmd}    ${user}=cirros    ${pwd}=cubswin:)    ${vm_prompt}=$
    [Documentation]    This keyword Login to VM Instance and fetching the required output.
    Switch Connection    ${conn_id}
    Write Commands Until Expected Prompt    virsh console ${virshid1}    ^]    30
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

Virsh Login
    [Arguments]    ${virshid}    ${user}=cirros    ${pwd}=cubswin:)    ${vm_prompt}=$
    [Documentation]    This Keyword Login to virsh console.
    Write Commands Until Expected Prompt    virsh console ${virshid}    ^]    30
    Write Commands Until Expected Prompt    \r    login:    30
    Write Commands Until Expected Prompt    ${user}    Password:    30
    Write Commands Until Expected Prompt    ${pwd}    ${vm_prompt}    30

Virsh Exit
    [Documentation]    This keyword close \ the VM session.
    Write Commands Until Expected Prompt    exit    login:    30
    ${ctrl_char}    Evaluate    chr(int(29))
    Write Bare    ${ctrl_char}

Get Vm Instance
    [Arguments]    ${vm_name}
    [Documentation]    This Keyword Fetch the vm instance ID.
    ${instance_name}    Write Commands Until Expected Prompt    nova show ${vm_name} | grep OS-EXT-SRV-ATTR:instance_name | awk '{print$4}'    $    60
    log    ${instance_name}
    [Return]    ${instance_name}

Ping From Virsh Console
    [Arguments]    ${virshid}    ${dest_ip}    ${connection_id}    ${string_tobe_verified}    ${user}=cirros    ${pwd}=cubswin:)
    ...    ${vm_prompt}=$
    [Documentation]    This Keyword Ping from the virsh console.
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

Spawn Vm
    [Arguments]    ${net_name}    ${vm_name}    ${image_name}    ${host_name}    ${flavor_name}    ${additional_args}=${EMPTY}
    [Documentation]    This keyword spawns the vm on DPN.
    log    ${vm_name},${net_name}
    ${vm_spawn}    Write Commands Until Expected Prompt    nova boot --flavor ${flavor_name} --image ${image_name} --availability-zone nova:${host_name} --nic net-name=${net_name} ${vm_name} \ ${additional_args}    $    420
    log    ${vm_spawn}
    should contain    ${vm_spawn}    ${vm_name}
    Wait Until Keyword Succeeds    120 sec    10 sec    Verify Vm Creation    ${vm_name}

Get Vm Ipv6 Addr
    [Arguments]    ${vm_name}    ${network_name}
    [Documentation]    This Keyword gets the IPV6 address of the VM which is assigned to it dynamically when spawned.
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

Extract Mac
    [Arguments]    ${op}
    [Documentation]    This Keyword extracts the mac of the VM.
    ${m}    Get Regexp Matches    ${op}    HWaddr \[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]:[0-9a-zA-Z][0-9a-zA-Z]\
    log    ${m}
    ${x}    Get From List    ${m}    0
    log    ${x}
    ${mac}=    Get Substring    ${x}    -17
    log    ${mac}
    [Return]    ${mac}

Table 0 Check
    [Arguments]    ${br_name}    ${conn_id}    ${port}
    [Documentation]    This Keyword Checks the table 0 entry for every VM spawned.
    Switch Connection    ${conn_id}
    ${cmd}=    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep table=0 | grep in_port=${port}
    log    ${cmd}
    Should Contain    ${cmd}    in_port=${port}
    ${metadatamatch}    Get Regexp Matches    ${cmd}    :0x(\.\*)/    1
    ${metavalue}    Get From List    ${metadatamatch}    0
    log    ${metavalue}
    [Return]    ${metavalue}

Extract Port
    [Arguments]    ${op}
    [Documentation]    This Keyword extarcts the port numbers to which the VM is attached.
    ${m}    Get Regexp Matches    ${op}    ([0-9]+)\.\*: addr    1
    log    ${m}
    ${port}    Get From List    ${m}    0
    log    ${port}
    [Return]    ${port}

Create Invalid Subnet
    [Arguments]    ${network}    ${invalid_subnet}
    [Documentation]    This Keyword creates a invalid subnet to test the negative scenario.
    ${command}    Set Variable    neutron subnet-create ${network} 2001:db8:1234::/21 --name ${invalid_subnet} --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    ${subnet}=    Write Commands Until Expected Prompt    ${command}    $    30
    log    ${subnet}
    log    ${command}
    Should Contain    ${subnet}    Invalid input for operation: Invalid CIDR

Get New Ipv6 Addr
    [Arguments]    ${vm_name}    ${ipv6_existing}    ${network1}    ${prefix1}    ${prefix2}
    [Documentation]    This Keyword gets the new IPV6 address assigned to the VM with respect to the new subnet created.
    Wait Until Keyword Succeeds    2 min    10 sec    check ips on nova show    ${vm_name}    ${network1}    ${prefix1}
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

Devstack Login
    [Arguments]    ${ip}    ${username}    ${password}    ${devstack_path}
    [Documentation]    This Keyword logs into the devstack on different OVS.
    ${dev_stack_conn_id}    Open Connection    ${ip}
    set suite variable    ${dev_stack_conn_id}
    Login    ${username}    ${password}
    ${cd}    Write Commands Until Expected Prompt    cd ${devstack_path}    $    30
    ${openrc}    Write Commands Until Expected Prompt    source openrc admin admin    $    30
    ${pwd}    Write Commands Until Expected Prompt    pwd    $    30
    log    ${pwd}
    [Return]    ${dev_stack_conn_id}

Get IPV6 Ips
    [Arguments]    ${vm_name}    ${network1}
    [Documentation]    This Keyword extract all the IPV6 IPs assigned to the VM.
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

Get Port Number
    [Arguments]    ${br_name}    ${pid}
    [Documentation]    This Keyword gets the port number specific to the VM.
    ${num}    Write Commands Until Expected Prompt    sudo ovs-ofctl -O OpenFlow13 show ${br_name} | grep ${pid} |awk '{print$1}'    $    30
    log    ${num}
    @{portNum}    Get Regexp Matches    ${num}    [0-9]+
    log    ${portNum}
    ${port_number}    Set Variable    ${portNum[0]}
    log    ${port_number}
    [Return]    ${port_number}

Extract Linklocal Addr
    [Arguments]    ${ifconfigoutput}
    [Documentation]    This keyword extracts the Link local address of the VMs
    ${output1}    Get Lines Containing String    ${ifconfigoutput}    Scope:Link
    ${linklocaliplist}    Get Regexp Matches    ${output1}    [0-9a-f]+::[0-9a-f]+:[0-9a-f]+:[0-9a-f]+:[0-9a-f]+
    ${link_addr}    Get From List    ${linklocaliplist}    0
    [Return]    ${link_addr}

Table Check
    [Arguments]    ${connection_id}    ${br_name}    ${table_cmdSuffix}    ${validation_list}
    [Documentation]    This keyword checks the parameters of a specific table number passed as an input argument.
    Switch Connection    ${connection_id}
    ${cmd}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table_cmdSuffix}
    Log    ${cmd}
    : FOR    ${elem}    IN    @{validation_list}
    \    Should Contain    ${cmd}    ${elem}

Get Hostname
    [Arguments]    ${conn_id}
    [Documentation]    This keyword gets the hostname of a particular host it logs into.
    Switch Connection    ${conn_id}
    ${hostname}    Write Commands Until Expected Prompt    hostname    $    30
    @{host}    Split String    ${hostname}    \r\n
    log    ${host}
    ${h}    get from list    ${host}    0
    [Return]    ${h}

Table Check With Negative Scenario
    [Arguments]    ${connection_id}    ${br_name}    ${table_cmdSuffix}    ${validation_list}
    [Documentation]    This keyword validates the parameters which should not be there in a specific table.
    ${cmd}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table_cmdSuffix}
    Log    ${cmd}
    : FOR    ${elem}    IN    @{validation_list}
    \    Should Not Contain    ${cmd}    ${elem}

Get Security Group Id
    [Arguments]    ${sg}
    [Documentation]    This keyword gets the security group Id and returns the id.
    Log    >>>Extract the SG for admin project>>>
    ${cmd}    Write Commands Until Expected Prompt    neutron net-show ${networks[0]} | grep tenant_id | awk '{print$4}'    $    30
    log    ${cmd}
    ${templ1}    Split To Lines    ${cmd}
    ${str1}    Get From List    ${templ1}    0
    ${tenantid}    Strip String    ${str1}
    ${op}    Write Commands Until Expected Prompt    neutron security-group-list | grep ${sg} | awk '{print$2}'    $    30
    log    ${op}
    ${templ1}    Split To Lines    ${op}
    ${str1}    Get From List    ${templ1}    0
    ${id}    Strip String    ${str1}
    [Return]    ${id}

Get Port Id
    [Arguments]    ${mac}    ${conn_id}
    [Documentation]    This keyword returns the port id for the port passed as input.
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

Get Neutron Port
    [Arguments]    ${mac}    ${conn_id}
    [Documentation]    This keyword gets the neutron port specific to the vm.
    Switch Connection    ${conn_id}
    ${mac_lower}=    Convert To Lowercase    ${mac}
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

Set Json
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
    ${body}    OperatingSystem.Get File    ${netvirt_config_dir}/Itm_creation_no_vlan.json
    ${substr}    Should Match Regexp    ${ip1}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    Log    ${subnet}
    Set Global Variable    ${subnet}
    ${vlan}=    Set Variable    ${vlan}
    ${gateway-ip}=    Set Variable    ${gateway-ip}
    ${body}    Set Json    ${ip1}    ${ip2}    ${vlan}    ${gateway-ip}    ${subnet}
    log    ${body}
    ${resp}    RequestsLibrary.Post Request    session    ${CONFIG_API}/itm:transport-zones/    data=${body}
    Log    ${resp.content}
    Log    ${resp.status_code}
    should be equal as strings    ${resp.status_code}    204

Get ITM
    [Arguments]    ${Itm_Created}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${ip1}    ${Dpn_id_2}
    ...    ${ip2}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    Log    ${Itm_Created},${subnet}, ${vlan}, ${Dpn_id_1},${ip1}, ${Dpn_id_2}, ${ip2}
    @{Itm-no-vlan}    Create List    ${Itm_Created}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${ip1}
    ...    ${Dpn_id_2}    ${ip2}
    Check For Elements At URI    ${CONFIG_API}/itm:transport-zones/transport-zone/${Itm_Created}    ${Itm-no-vlan}

create ITM Tunnel
    [Documentation]    Creating ITM tunnel
    Remove All Elements If Exist    ${CONFIG_API}/itm:transport-zones/transport-zone/${Itm_Created}
    Switch Connection    ${conn_id_1}
    Write Commands Until Expected Prompt    sudo ovs-vsctl del-br ${Bridge-1}    $    10
    Write Commands Until Expected Prompt    sudo ovs-vsctl add-br ${Bridge-1}    $    10
    Write Commands Until Expected Prompt    sudo ovs-vsctl add-port ${Bridge-1} ${Interface-1}    $    10
    Write Commands Until Expected Prompt    sudo ifconfig ${Bridge-1} \ ${dpip[0]}/24 up    $    10
    Write Commands Until Expected Prompt    sudo ifconfig ${Interface-1} 0    $    10
    Switch Connection    ${conn_id_2}
    Write Commands Until Expected Prompt    sudo ovs-vsctl del-br ${Bridge-2}    $    10
    Write Commands Until Expected Prompt    sudo ovs-vsctl add-br ${Bridge-2}    $    10
    Write Commands Until Expected Prompt    sudo ovs-vsctl add-port ${Bridge-2} ${Interface-2}    $    10
    Write Commands Until Expected Prompt    sudo ifconfig ${Bridge-2} \ ${dpip[1]}/24 up    $    10
    Write Commands Until Expected Prompt    sudo ifconfig ${Interface-2} 0    $    10
    ${Dpn_id_1}    Get Dpn Ids    ${conn_id_1}    ${Br_Name}
    ${Dpn_id_2}    Get Dpn Ids    ${conn_id_2}    ${Br_Name}
    Set Global Variable    ${Dpn_id_1}
    Set Global Variable    ${Dpn_id_2}
    ${vlan}=    Set Variable    0
    ${gateway-ip}    Set Variable    0.0.0.0
    ${ip1}    Set Variable    ${dpip[0]}
    ${ip2}    Set Variable    ${dpip[1]}
    Create Vteps    ${ip1}    ${ip2}    ${vlan}    ${gateway-ip}
    Wait Until Keyword Succeeds    40    10    Get ITM    ${Itm_Created}    ${subnet}    ${vlan}
    ...    ${Dpn_id_1}    ${ip1}    ${Dpn_id_2}    ${ip2}

Delete Topology
    [Documentation]    This keyword deletes the basic topology created at the beginning of the suite.
    Delete Vm Instance    ${VM_list[0]}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_list[0]}    ${mac1}    ${conn_id_1}
    Delete Vm Instance    ${VM_list[1]}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_list[1]}    ${mac2}    ${conn_id_1}
    Delete Vm Instance    ${VM_list[4]}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_list[4]}    ${mac5}    ${conn_id_2}
    Remove Interface    ${Routers[0]}    ${Subnets[0]}
    Remove Interface    ${Routers[0]}    ${Subnets[1]}
    Delete Subnet    ${Subnets[0]}
    Delete Subnet    ${Subnets[1]}
    Delete Router    ${Routers[0]}
    Delete Network    ${Networks[0]}

Verify Vm Creation
    [Arguments]    ${vm_name}
    [Documentation]    This keyword verifies the VM creation.
    ${novaverify}    Write Commands Until Expected Prompt    nova list | grep ${vm_name}    $    60
    Should Contain    ${novaverify}    ACTIVE
    Should Contain    ${novaverify}    Running

Get Ip List Specific To Prefixes
    [Arguments]    ${vm_name}    ${network_name}    ${prefix1}    ${prefix2}
    [Documentation]    This keyword returns the list of IPs specific to the list of subnets passed.
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
    \    ${check}    Check Substring    ${i}    ${prefix1}
    \    ${ip}    Remove String    ${i}    |
    \    ${ip}    Strip String    ${ip}
    \    Run Keyword If    '${check}'=='True'    Append To List    ${ip_list}    ${ip}
    \    log    ${ip_list}
    \    ${check}    Check Substring    ${i}    ${prefix2}
    \    ${ip}    Remove String    ${i}    |
    \    ${ip}    Strip String    ${ip}
    \    Run Keyword If    '${check}'=='True'    Append To List    ${ip_list}    ${ip}
    \    log    ${ip_list}
    log    ${ip_list}
    [Return]    ${ip_list}

Check Substring
    [Arguments]    ${s1}    ${s2}
    [Documentation]    This keyword checks whether S2 is a substring of S1.
    log    ${s1}
    log    ${s2}
    ${match}    Get Regexp Matches    ${s1}    (${s2})    1
    log    ${match}
    ${len}    Get Length    ${match}
    ${return}    Set Variable If    ${len}>0    True    False
    [Return]    ${return}

Get Subnet Specific Ip
    [Arguments]    ${ip_list}    ${prefix}
    [Documentation]    This keyword returns an IP specific to a subnet passed.
    ${prefix}    Remove String    ${prefix}    ::
    ${check}    Check Substring    ${ip_list[0]}    ${prefix}
    ${ip}    Set Variable If    '${check}'=='True'    ${ip_list[0]}    ${ip_list[1]}
    [Return]    ${ip}

Validate Router Config Datastore
    [Arguments]    ${prefix_list}
    [Documentation]    This keyword validates prefix in the config datastore for the router interfaces.
    ${json}    Get Data From URI    session    ${CONFIG_API}/l3vpn:vpn-interfaces/
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

Verify Vm Deletion
    [Arguments]    ${vm}    ${mac}    ${conn_id}
    [Documentation]    This keyword checks whether the VM passed as an argument is deleted or not.
    ${vm_list}    List Nova VMs
    Should Not Contain    ${vm_list}    ${vm}
    Switch Connection    ${conn_id}
    ${cmd}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${Br_Name} | grep table=40
    Log    ${cmd}
    ${lower_mac}    Convert To Lowercase    ${mac}
    Should Not Contain    ${cmd}    ${lower_mac}

Fetch Topology Details
    [Documentation]    This keyword fetches the basic topology details.
    Log    >>>Just for the run purpose>>>
    ${ip_list1}    Wait Until Keyword Succeeds    50 sec    10 sec    Get IPV6 Ips    ${VM_list[0]}    ${Networks[0]}
    Set Global Variable    ${ip_list1}
    ${vm1ip}    Get Subnet Specific Ip    ${ip_list1}    ${Prefixes[0]}
    Set Global Variable    ${vm1ip}
    Wait Until Keyword Succeeds    300 sec    20 sec    Ping Check    ${vm1ip}    ${conn_id_1}    ${Networks[0]}
    ${output1}    Wait Until Keyword Succeeds    300 sec    20 sec    Execute Command On VM    ${conn_id_1}    ${Networks[0]}
    ...    ${vm1ip}    ifconfig eth0
    log    ${output1}
    ${linkaddr1}    extract linklocal addr    ${output1}
    Set Global Variable    ${linkaddr1}
    ${mac1}    Extract Mac    ${output1}
    ${port_id1}    get port id    ${mac1}    ${conn_id_1}
    ${port1}    Get Port Number    ${Br_Name}    ${port_id1}
    Set Global Variable    ${mac1}
    log    ${port1}
    Set Global Variable    ${port1}
    Log    >>>Details of vm2>>>
    ${ip_list2}    Wait Until Keyword Succeeds    50 sec    10 sec    Get IPV6 Ips    ${VM_list[1]}    ${Networks[0]}
    Set Global Variable    ${ip_list1}
    ${vm2ip}    Get Subnet Specific Ip    ${ip_list2}    ${Prefixes[0]}
    Set Global Variable    ${vm2ip}
    Wait Until Keyword Succeeds    300 sec    20 sec    Ping Check    ${vm2ip}    ${conn_id_1}    ${Networks[0]}
    ${output2}    Wait Until Keyword Succeeds    300 sec    20 sec    Execute Command On VM    ${conn_id_1}    ${Networks[0]}
    ...    ${vm2ip}    ifconfig eth0
    Set Global Variable    ${ip_list2}
    log    ${output2}
    ${linkaddr2}    extract linklocal addr    ${output2}
    Set Global Variable    ${linkaddr2}
    ${mac2}    Extract Mac    ${output2}
    ${port_id2}    get port id    ${mac2}    ${conn_id_1}
    ${port2}    Get Port Number    ${Br_Name}    ${port_id2}
    Set Global Variable    ${mac2}
    log    ${port2}
    Set Global Variable    ${port2}
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
    Log    >>>Details of VM5>>>
    ${ip_list5}    Wait Until Keyword Succeeds    50 sec    10 sec    Get IPV6 Ips    ${VM_list[4]}    ${Networks[0]}
    Set Global Variable    ${ip_list5}
    ${vm5ip}    Get Subnet Specific Ip    ${ip_list5}    ${Prefixes[0]}
    Set Global Variable    ${vm5ip}
    Wait Until Keyword Succeeds    300 sec    20 sec    Ping Check    ${vm5ip}    ${conn_id_1}    ${Networks[0]}
    ${output5}    Wait Until Keyword Succeeds    300 sec    20 sec    Execute Command On VM    ${conn_id_1}    ${Networks[0]}
    ...    ${vm5ip}    ifconfig eth0
    log    ${output5}
    ${linkaddr5}    extract linklocal addr    ${output5}
    Set Global Variable    ${linkaddr5}
    ${mac5}    Extract Mac    ${output5}
    ${port_id5}    get port id    ${mac5}    ${conn_id_1}
    ${port5}    Get Port Number    ${Br_Name}    ${port_id5}
    Set Global Variable    ${mac5}
    log    ${port5}
    Set Global Variable    ${port5}
    ${port_id5}    get port id    ${mac5}    ${conn_id_2}
    ${port5}    Get Port Number    ${Br_Name}    ${port_id5}
    Set Global Variable    ${mac5}
    log    ${port5}
    Set Global Variable    ${port5}
    Switch Connection    ${conn_id_1}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Br_Name}
    log    ${flowdump}
    ${metadata1}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
    ...    ${port1}
    Set Global Variable    ${metadata1}
    ${metadata5}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_2}
    ...    ${port5}
    Set Global Variable    ${metadata5}

fetch all info
    Log    >>>Adding part of create topology for the global variables, just for the debugging purpose>>>
    Switch Connection    ${conn_id_1}
    ${hostname1}    get hostname    ${conn_id_1}
    Set Global Variable    ${hostname1}
    Switch Connection    ${conn_id_2}
    ${hostname2}    get hostname    ${conn_id_2}
    Set Global Variable    ${hostname2}
    Switch Connection    ${conn_id_1}
    ${virshid1}    Get Vm Instance    ${VM_list[0]}
    ${virshid2}    Get Vm Instance    ${VM_list[1]}
    ${virshid3}    Get Vm Instance    ${VM_list[2]}
    Set Global Variable    ${virshid1}
    Set Global Variable    ${virshid2}
    Set Global Variable    ${virshid3}
    ${ip_list1}    Wait Until Keyword Succeeds    50 sec    10 sec    Get IPV6 Ips    ${VM_list[0]}    ${Networks[0]}
    ${ip_list2}    Wait Until Keyword Succeeds    50 sec    10 sec    Get IPV6 Ips    ${VM_list[1]}    ${Networks[0]}
    ${ip_list3}    Wait Until Keyword Succeeds    50 sec    10 sec    Get IPV6 Ips    ${VM_list[2]}    ${Networks[0]}
    Set Global Variable    ${ip_list1}
    Set Global Variable    ${ip_list2}
    Set Global Variable    ${ip_list3}
    ${output1}    Virsh Output    ${virshid1}    ifconfig eth0
    log    ${output1}
    ${linkaddr1}    extract linklocal addr    ${output1}
    Set Global Variable    ${linkaddr1}
    ${output2}    Virsh Output    ${virshid2}    ifconfig eth0
    log    ${output2}
    ${linkaddr2}    extract linklocal addr    ${output2}
    Set Global Variable    ${linkaddr2}
    ${output3}    Virsh Output    ${virshid3}    ifconfig eth0
    log    ${output3}
    ${linkaddr3}    extract linklocal addr    ${output3}
    Set Global Variable    ${linkaddr3}
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
    Should Contain    ${output3}    ${ip_list3[0]}
    Should Contain    ${output3}    ${ip_list3[1]}
    ${mac1}    Extract Mac    ${output1}
    ${port_id1}    get port id    ${mac1}    ${conn_id_1}
    ${port1}    Get Port Number    ${Br_Name}    ${port_id1}
    Set Global Variable    ${mac1}
    log    ${port1}
    Set Global Variable    ${port1}
    ${mac2}    Extract Mac    ${output2}
    ${port_id2}    get port id    ${mac2}    ${conn_id_1}
    ${port2}    Get Port Number    ${Br_Name}    ${port_id2}
    Set Global Variable    ${mac2}
    log    ${port2}
    Set Global Variable    ${port2}
    ${mac3}    Extract Mac    ${output3}
    ${port_id3}    get port id    ${mac3}    ${conn_id_1}
    ${port3}    Get Port Number    ${Br_Name}    ${port_id3}
    Set Global Variable    ${mac3}
    log    ${port3}
    Set Global Variable    ${port3}
    ${virshid5}    Get Vm Instance    ${VM_list[4]}
    Set Global Variable    ${virshid5}
    ${ip_list5}    Wait Until Keyword Succeeds    2 min    10 sec    Get IPV6 Ips    ${VM_list[4]}    ${Networks[0]}
    Set Global Variable    ${ip_list5}
    ${virshid4}    Get Vm Instance    ${VM_list[3]}
    Set Global Variable    ${virshid4}
    ${ip_list4}    Wait Until Keyword Succeeds    2 min    10 sec    Get IPV6 Ips    ${VM_list[3]}    ${Networks[0]}
    Set Global Variable    ${ip_list4}
    Switch Connection    ${conn_id_2}
    ${output5}    Virsh Output    ${virshid5}    ifconfig eth0
    log    ${output5}
    ${linkaddr5}    extract linklocal addr    ${output5}
    Set Global Variable    ${linkaddr5}
    Should Contain    ${output5}    ${ip_list5[0]}
    Should Contain    ${output5}    ${ip_list5[1]}
    ${mac5}    Extract Mac    ${output5}
    ${port_id5}    get port id    ${mac5}    ${conn_id_2}
    ${port5}    Get Port Number    ${Br_Name}    ${port_id5}
    Set Global Variable    ${mac5}
    log    ${port5}
    Set Global Variable    ${port5}
    ${output4}    Virsh Output    ${virshid4}    ifconfig eth0
    log    ${output4}
    ${linkaddr4}    extract linklocal addr    ${output4}
    Set Global Variable    ${linkaddr4}
    Should Contain    ${output4}    ${ip_list4[0]}
    Should Contain    ${output4}    ${ip_list4[1]}
    ${mac4}    Extract Mac    ${output4}
    ${port_id4}    get port id    ${mac4}    ${conn_id_2}
    ${port4}    Get Port Number    ${Br_Name}    ${port_id4}
    Set Global Variable    ${mac4}
    log    ${port4}
    Set Global Variable    ${port4}
    Switch Connection    ${conn_id_1}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Br_Name}
    log    ${flowdump}
    ${metadata1}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
    ...    ${port1}
    Set Global Variable    ${metadata1}
    ${metadata2}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
    ...    ${port2}
    Set Global Variable    ${metadata2}
    ${metadata3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_1}
    ...    ${port3}
    Set Global Variable    ${metadata3}
    ${metadata4}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_2}
    ...    ${port4}
    Set Global Variable    ${metadata4}
    ${metadata5}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check    ${Br_Name}    ${conn_id_2}
    ...    ${port5}
    Set Global Variable    ${metadata5}

Get Network Id
    [Arguments]    ${conn_id}    ${network}
    [Documentation]    This keyword returns the network id for a network name passed.
    Switch Connection    ${conn_id}
    ${op}    Write Commands Until Expected Prompt    neutron net-list | grep ${network} | awk '{print$2}'    $    30
    ${splitted_op}    Split To Lines    ${op}
    ${net_id}    Get From List    ${splitted_op}    0
    [Return]    ${net_id}

Create Topology
    [Arguments]    ${image}
    [Documentation]    Creates the required topology for the test cases to be run.
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
    sleep    30
    Add Router Interface    ${Routers[0]}    ${Subnets[1]}
    @{prefixlist}    Create List    ${Prefixes[0]}    ${Prefixes[1]}
    sleep    30
    ${hostname1}    get hostname    ${conn_id_1}
    Set Global Variable    ${hostname1}
    Switch Connection    ${conn_id_2}
    ${hostname2}    get hostname    ${conn_id_2}
    Set Global Variable    ${hostname2}
    Switch Connection    ${conn_id_1}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Br_Name}
    log    ${flowdump}
    Spawn Vm    ${Networks[0]}    ${VM_list[0]}    ${image}    ${hostname1}    ${Flavor_Name}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Br_Name}
    log    ${flowdump}
    Spawn Vm    ${Networks[0]}    ${VM_list[1]}    ${image}    ${hostname1}    ${Flavor_Name}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Br_Name}
    log    ${flowdump}
    Spawn Vm    ${Networks[0]}    ${VM_list[4]}    ${image}    ${hostname2}    ${Flavor_Name}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Br_Name}
    log    ${flowdump}
    ${ip_list1}    Wait Until Keyword Succeeds    50 sec    10 sec    Get IPV6 Ips    ${VM_list[0]}    ${Networks[0]}
    Set Global Variable    ${ip_list1}
    ${vm1ip}    Get Subnet Specific Ip    ${ip_list1}    ${Prefixes[0]}
    Set Global Variable    ${vm1ip}
    ${virshid1}    Get Vm Instance    ${VM_list[0]}
    Set Global Variable    ${virshid1}
    ${output1}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid1}
    ...    ifconfig eth0
    log    ${output1}
    ${linkaddr1}    extract linklocal addr    ${output1}
    Set Global Variable    ${linkaddr1}
    ${mac1}    Extract Mac    ${output1}
    ${port_id1}    get port id    ${mac1}    ${conn_id_1}
    ${port1}    Get Port Number    ${Br_Name}    ${port_id1}
    Set Global Variable    ${mac1}
    log    ${port1}
    Set Global Variable    ${port1}
    Log    >>>Details of vm2>>>
    ${ip_list2}    Wait Until Keyword Succeeds    50 sec    10 sec    Get IPV6 Ips    ${VM_list[1]}    ${Networks[0]}
    Set Global Variable    ${ip_list1}
    ${vm2ip}    Get Subnet Specific Ip    ${ip_list2}    ${Prefixes[0]}
    Set Global Variable    ${vm2ip}
    ${virshid2}    Get Vm Instance    ${VM_list[1]}
    Set Global Variable    ${virshid2}
    ${output2}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_1}    ${virshid2}
    ...    ifconfig eth0
    Set Global Variable    ${ip_list2}
    log    ${output2}
    ${linkaddr2}    extract linklocal addr    ${output2}
    Set Global Variable    ${linkaddr2}
    ${mac2}    Extract Mac    ${output2}
    ${port_id2}    get port id    ${mac2}    ${conn_id_1}
    ${port2}    Get Port Number    ${Br_Name}    ${port_id2}
    Set Global Variable    ${mac2}
    log    ${port2}
    Set Global Variable    ${port2}
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
    Log    >>>Details of VM5>>>
    ${ip_list5}    Wait Until Keyword Succeeds    50 sec    10 sec    Get IPV6 Ips    ${VM_list[4]}    ${Networks[0]}
    Set Global Variable    ${ip_list5}
    ${vm5ip}    Get Subnet Specific Ip    ${ip_list5}    ${Prefixes[0]}
    Set Global Variable    ${vm5ip}
    ${virshid5}    Get Vm Instance    ${VM_list[4]}
    Set Global Variable    ${virshid5}
    ${output5}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${conn_id_2}    ${virshid5}
    ...    ifconfig eth0
    log    ${output5}
    ${linkaddr5}    extract linklocal addr    ${output5}
    Set Global Variable    ${linkaddr5}
    ${mac5}    Extract Mac    ${output5}
    ${port_id5}    get port id    ${mac5}    ${conn_id_2}
    ${port5}    Get Port Number    ${Br_Name}    ${port_id5}
    Set Global Variable    ${mac5}
    log    ${port5}
    Set Global Variable    ${port5}

Execute Command On VM
    [Arguments]    ${conn_id}    ${net_name}    ${vm_ip}    ${cmd}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    This keyword executes the command passed to it on a VM.
    Switch Connection    ${conn_id}
    ${net_id}    get network id    ${conn_id}    ${net_name}
    Log    ${vm_ip}
    ${output}    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh ${user}@${vm_ip} -o ConnectTimeout=10 -o StrictHostKeyChecking=no \r    password:    90
    Log    ${output}
    ${output}    Write Commands Until Expected Prompt    ${password}    $    30
    Log    ${output}
    ${rcode}    Run Keyword And Return Status    Check If Console Is VmInstance
    ${output}    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ${cmd}    $
    Write Commands Until Expected Prompt    exit    $    10
    [Teardown]
    [Return]    ${output}

Ping Check
    [Arguments]    ${ip_address}    ${conn_id}    ${network}    ${address_family}=ipv6
    [Documentation]    This keyword does the ping check for a specific VM to know whether VM is up before logging into it.
    ${netid}    get network id    ${conn_id}    ${network}
    ${cmd}    Set Variable If    '${address_family}'=='ipv6'    sudo ip netns exec qdhcp-${netid} ping6 -c 3 ${ip_address}    sudo ip netns exec qdhcp-${netid} ping -c 3 ${ip_address}
    ${output}    Write Commands Until Expected Prompt    ${cmd}    $
    Should Contain    ${output}    64 bytes

Vm Login
    [Arguments]    ${conn_id}    ${net_name}    ${vm_ip}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    This keyword does the VM login using namespace.
    Switch Connection    ${conn_id}
    ${net_id}    get network id    ${conn_id}    ${net_name}
    Log    ${vm_ip}
    ${output}    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh ${user}@${vm_ip} -o ConnectTimeout=10 -o StrictHostKeyChecking=no \r    password:    90
    Log    ${output}
    ${output}    Write Commands Until Expected Prompt    ${password}    $    30
    Log    ${output}
    ${rcode}    Run Keyword And Return Status    Check If Console Is VmInstance
    [Return]    ${output}

Vm Exit
    [Arguments]    ${conn_id}
    [Documentation]    This keyword exits the VM console.
    Switch Connection    ${conn_id}
    Write Commands Until Expected Prompt    exit    $    10

nova reboot
    [Arguments]    ${vm_name}
    [Documentation]    This keyword will reboot the VM instance.
    ${output}    Write Commands Until Expected Prompt    nova reboot ${vm_name}    $    60
    Should Contain    ${output}    accepted
    Wait Until Keyword Succeeds    30 sec    10 sec    verify vm creation    ${vm_name}

check ip on vm
    [Arguments]    ${conn_id}    ${virshid}    ${cmd}    ${target_ip}
    [Documentation]    This Keyword gets ip on vm.
    ${output1}    Virsh Output    ${conn_id}    ${virshid}    ${cmd}
    log    ${output1}
    Should Contain    ${output1}    ${target_ip}

get both ip
    [Arguments]    ${vm_name}    ${network1}
    [Documentation]    This Keyword gets both the ip on interface (which is from different subnet).
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

attach network to vm
    [Arguments]    ${conn_id}    ${network_name}    ${vm_name}
    [Documentation]    This keyword will add a network to vm.
    Set Client Configuration    prompt=$
    ${netid}    get net id    ${network_name}    ${conn_id}
    Write Commands Until Expected Prompt    nova interface-attach --net-id \ \ ${netid} ${vm_name}    $    30

get network specific ip address
    [Arguments]    ${vm_name}    ${network}
    [Documentation]    This keyword get the network specific ip address.
    ${ip1_temp}=    Write Commands Until Expected Prompt    nova show ${vm_name} | grep ${network} | awk '{print$5}'    $    30
    log    ${ip1_temp}
    ${templ1}    Split To Lines    ${ip1_temp}
    ${str1}=    Get From List    ${templ1}    0
    ${ip1}=    Strip String    ${str1}
    log    ${ip1}
    [Return]    ${ip1}

get ipv6 new
    [Arguments]    ${vm_name}    ${ipv6_existing}    ${network1}    ${prefix1}    ${prefix2}
    [Documentation]    This keyword gets the ip from VM when new network added to the instance.
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

check ips on nova show
    [Arguments]    ${vm_name}    ${network1}    ${prefix1}    ${prefix2}
    [Documentation]    This keyword gets ip from "nova show" output.
    ${op}    Write Commands Until Expected Prompt    nova show ${vm_name} | grep ${network1}    $    30
    log    ${op}
    ${prefix1} =    Remove String    ${prefix1}    ::
    ${prefix2} =    Remove String    ${prefix2}    ::
    log    ${prefix1}
    log    ${prefix2}
    Should Contain    ${op}    ${prefix1}
    Should Contain    ${op}    ${prefix2}

invalid subnet
    [Arguments]    ${network}    ${invalid_subnet}
    [Documentation]    This keyword creates a subnet with invalid value.
    ${command}    Set Variable    neutron subnet-create ${network} 2001:db8:1234::/21 --name ${invalid_subnet} --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    ${subnet}=    Write Commands Until Expected Prompt    ${command}    $    30
    log    ${subnet}
    log    ${command}
    Should Contain    ${subnet}    Invalid input for operation: Invalid CIDR

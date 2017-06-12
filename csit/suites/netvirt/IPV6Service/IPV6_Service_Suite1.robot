*** Settings ***
Documentation     Test suite for IPV6 addr assignment, Security Groups and Allowed address pair.
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
@{login_credentials}    stack    stack    root    password
@{SG_name}        SG1    SG2    SG3    SG4    default
@{rule_list}      tcp    udp    icmpv6    10000    10500    IPV6    # protocol1, protocol2, protocol3, port_min, port_max, ether_type
@{direction}      ingress    egress    both
@{Image_Name}     cirros-0.3.4-x86_64-uec    ubuntu-sg
@{protocols}      tcp6    udp6    icmp6
@{remote_group}    SG1    prefix    any
@{remote_prefix}    ::0/0    2001:db8:1234::/64    2001:db8:4321::/64
@{logical_addr}    2001:db8:1234:0:1111:2343:3333:4444    2001:db8:1234:0:1111:2343:3333:5555
@{flavour_list}    m1.nano    m1.tiny
@{itm_created}    TZA
${br_name}        br-int
${netvirt_config_dir}    ${CURDIR}/../../../variables/netvirt
${Bridge-1}       br0
${Bridge-2}       br0
${genius_config_dir}    ${CURDIR}/../../../variables/genius
@{dpip}           20.0.0.9    20.0.0.10

*** Test Cases ***
IPV6_Validate multiple IPv6 address assignment to Neutron VMs in SLAAC Mode with 2 DPNs
    [Documentation]    Validate multiple IPv6 address assignment to Neutron VMs on same interface after booting up with IPv6 configuration mode as SLAAC
    [Setup]    Create Topology
    Switch Connection    ${conn_id_1}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    Fetch Topology Details    ${conn_id_1}    ${conn_id_2}    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[4]}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    ${metadatavalue1}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${br_name}    ${conn_id_1}
    ...    ${port1}
    ${metadatavalue2}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${br_name}    ${conn_id_1}
    ...    ${port2}
    ${lower_mac1}    Convert To Lowercase    ${mac1}
    @{array}    create list    goto_table:45
    Table Check    ${conn_id_1}    ${br_name}    table=17|grep ${metadatavalue1}    ${array}
    @{array}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[0]}1
    Table Check    ${conn_id_1}    ${br_name}    table=45|grep actions=CONTROLLER:65535    ${array}
    @{array}    Create List    dl_src=${lower_mac1}
    Table Check    ${conn_id_1}    ${br_name}    table=50    ${array}
    @{array}    Create List    dl_dst=${lower_mac1}
    Table Check    ${conn_id_1}    ${br_name}    table=51    ${array}
    @{array}    Create List    table=252    ${ip_list1[0]}    ${ip_list1[1]}    ${linkaddr1}
    Table Check    ${conn_id_1}    ${br_name}    table=251| grep ${lower_mac1}    ${array}
    ${lower_mac2}    Convert To Lowercase    ${mac2}
    @{array}    create list    goto_table:45
    Table Check    ${conn_id_1}    ${br_name}    table=17|grep ${metadatavalue2}    ${array}
    @{array}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[0]}1
    Table Check    ${conn_id_1}    ${br_name}    table=45|grep actions=CONTROLLER:65535    ${array}
    @{array}    create list    dl_src=${lower_mac2}
    Table Check    ${conn_id_1}    ${br_name}    table=50    ${array}
    @{array}    create list    dl_dst=${lower_mac2}
    Table Check    ${conn_id_1}    ${br_name}    table=51    ${array}
    @{array}    Create List    table=252    ${ip_list2[0]}    ${ip_list2[1]}    ${linkaddr2}
    Table Check    ${conn_id_1}    ${br_name}    table=251| grep ${lower_mac2}    ${array}

IPV6_Validate dual stack address assignment to Neutron VMs in SLAAC Mode in single DPN
    [Documentation]    Validate Ipv4 and IPv6 address assignment to Neutron VMs on same interface after booting up with IPv6 configuration mode as SLAAC
    Create Network    ${Networks[1]}
    Create Subnet    ${Networks[1]}    ${Subnets[2]}    ${Prefixes[2]}/64    --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac
    Create Subnet    ${Networks[1]}    ${V4subnet_names[0]}    ${V4subnets[0]}/24    --enable-dhcp
    Add Router Interface    ${Routers[0]}    ${Subnets[2]}
    Remove All Elements If Exist    ${CONFIG_DHCP}/
    Post Elements To URI From File    ${CONFIG_API}/    ${netvirt_config_dir}/enable_dhcp.json
    @{list}=    Create List    "controller-dhcp-enabled"    true
    Check For Elements At URI    ${CONFIG_DHCP}/    ${list}
    Switch Connection    ${conn_id_1}
    Spawn Vm    ${Networks[1]}    ${VM_list[2]}    ${image_name[0]}    ${hostname1}    ${flavour_list[1]}
    ${virshid3}    Get Vm Instance    ${VM_list[2]}
    Set Global Variable    ${virshid3}
    ${prefixstr1}    Remove String    ${Prefixes[2]}    ::
    ${v4prefix}    Get Substring    ${V4subnets[0]}    \    -1
    ${ip_list3}    Wait Until Keyword Succeeds    50 sec    10 sec    Get Ip List Specific To Prefixes    ${VM_list[2]}    ${Networks[1]}
    ...    ${prefixstr1}    ${v4prefix}
    Set Global Variable    ${ip_list3}
    ${output3}    Wait Until Keyword Succeeds    60 sec    20 sec    Virsh Output    ${virshid3}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    log    ${output3}
    ${linkaddr3}    Extract Linklocal Addr    ${output3}
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
    @{araay}    Create List    goto_table:45    goto_table:60
    Table Check    ${conn_id_1}    ${br_name}    table=17|grep ${metadatavalue3}    ${araay}
    @{araay}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1
    Table Check    ${conn_id_1}    ${br_name}    table=45|grep actions=CONTROLLER:65535    ${araay}
    ${lower_mac3}    Convert To Lowercase    ${mac3}
    @{araay}    create list    dl_src=${lower_mac3}
    Table Check    ${conn_id_1}    ${br_name}    table=50    ${araay}
    @{araay}    create list    dl_dst=${lower_mac3}
    Table Check    ${conn_id_1}    ${br_name}    table=51    ${araay}
    @{araay}    create list    dl_src=${lower_mac3}
    Table Check    ${conn_id_1}    ${br_name}    table=60    ${araay}

IPV6_Validate ping6 between VMs in Two DPNs
    [Documentation]    Validate ping6 between VMs in different compute
    Switch Connection    ${conn_id_1}
    Spawn Vm    ${Networks[1]}    ${VM_list[3]}    ${image_name[0]}    ${hostname2}    ${flavour_list[1]}
    ${virshid4}    Get Vm Instance    ${VM_list[3]}
    Set Global Variable    ${virshid4}
    ${prefixstr1}    Remove String    ${Prefixes[2]}    ::
    ${v4prefix}    Get Substring    ${V4subnets[0]}    \    -1
    ${ip_list4}    Wait Until Keyword Succeeds    50 sec    10 sec    Get Ip List Specific To Prefixes    ${VM_list[3]}    ${Networks[1]}
    ...    ${prefixstr1}    ${v4prefix}
    Set Global Variable    ${ip_list4}
    Switch Connection    ${conn_id_2}
    ${output4}    Virsh Output    ${virshid4}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}
    ...    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)    $
    log    ${output4}
    ${linkaddr4}    Extract Linklocal Addr    ${output4}
    Set Global Variable    ${linkaddr4}
    Should Contain    ${output4}    ${ip_list4[0]}
    Should Contain    ${output4}    ${ip_list4[1]}
    Set Global Variable    ${ip_list4[0]}
    Set Global Variable    ${ip_list4[1]}
    ${mac4}    Extract_Mac_From_Ifconfig    ${output4}
    ${port_id4}    Get Port Id of instance    ${mac4}    ${conn_id_2}
    ${port4}    Get In Port Number For VM    ${br_name}    ${port_id4}
    log    ${port4}
    Set Global Variable    ${mac4}
    Set Global Variable    ${port4}
    Switch Connection    ${conn_id_2}
    ${metadatavalue4}    Wait Until Keyword Succeeds    50 sec    10 sec    Table 0 Check For VM Creation    ${br_name}    ${conn_id_2}
    ...    ${port4}
    @{araay}    Create List    goto_table:45    goto_table:60
    Table Check    ${conn_id_2}    ${br_name}    table=17|grep ${metadatavalue4}    ${araay}
    @{araay}    create list    icmp_type=133    icmp_type=135    nd_target=${Prefixes[2]}1
    Table Check    ${conn_id_2}    ${br_name}    table=45|grep actions=CONTROLLER:65535    ${araay}
    ${lower_mac4}    Convert To Lowercase    ${mac4}
    @{araay}    create list    dl_src=${lower_mac4}
    Table Check    ${conn_id_2}    ${br_name}    table=50    ${araay}
    @{araay}    create list    dl_dst=${lower_mac4}
    Table Check    ${conn_id_2}    ${br_name}    table=51    ${araay}
    @{araay}    create list    dl_src=${lower_mac4}
    Table Check    ${conn_id_2}    ${br_name}    table=60    ${araay}
    Ping From Virsh Console    ${virshid3}    ${ip_list4[0]}    ${conn_id_1}    , 0% packet loss
    Ping From Virsh Console    ${virshid3}    ${ip_list4[1]}    ${conn_id_1}    , 0% packet loss
    [Teardown]

IPV6_Validate Ipv6 default security group and Rules in two Compute Nodes
    [Documentation]    Validate Ipv6 default security group contains all the default security group rules as expected in different compute nodes
    [Setup]
    Fetch Topology Details    ${conn_id_1}    ${conn_id_2}    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[4]}
    Switch Connection    ${conn_id_1}
    @{araay}    Create List    goto_table:40    ${metadata1}
    Table Check    ${conn_id_1}    ${br_name}    table=17|grep ${metadata1}    ${araay}
    @{araay}    Create List    actions=ct(table=41    ${ip_list1[0]}    ${ip_list1[1]}    ${linkaddr1}
    Table Check    ${conn_id_1}    ${br_name}    table=40| grep -i ${mac1}    ${araay}
    ${pkt_new_before_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +new+trk | grep ${metadata1} | grep ipv6
    ${pkt_est_before_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +est
    ${pkt_new_before_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +new+trk | grep ${metadata5} | grep ipv6
    ${pkt_est_before_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +est
    Wait Until Keyword Succeeds    60 sec    10 sec    Ping From Virsh Console    ${virshid1}    ${ip_list5[0]}    ${conn_id_1}
    ...    , 0% packet loss
    ${pkt_new_after_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +new+trk | grep ${metadata1} | grep ipv6
    ${pkt_est_after_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +est
    ${pkt_new_after_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +new+trk | grep ${metadata5} | grep ipv6
    ${pkt_est_after_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +est
    ${pkt_diff_new_41}    Evaluate    int(${pkt_new_after_tb41})-int(${pkt_new_before_tb41})
    Should Be True    ${pkt_diff_new_41} > 0
    ${pkt_diff_est_41}    Evaluate    int(${pkt_est_after_tb41})-int(${pkt_est_before_tb41})
    Should Be True    ${pkt_diff_est_41} > 0
    ${pkt_diff_new_252}    Evaluate    int(${pkt_new_after_tb252})-int(${pkt_new_before_tb252})
    ${pkt_diff_est_252}    Evaluate    int(${pkt_est_after_tb252})-int(${pkt_est_before_tb252})
    Should Be True    ${pkt_diff_est_252} > 0
    Ssh Connection Check    ${virshid1}    ${ip_list5[0]}    ${ip_list1[0]}    ${conn_id_1}    ${conn_id_2}    , 0% packet loss
    Send Traffic Using Netcat    ${virshid1}    ${virshid5}    ${ip_list1[0]}    ${ip_list5[0]}    ${conn_id_1}    ${conn_id_2}
    ...    10000    Hello
    @{araay}    Create List    actions=resubmit(,17)    ct_state=+new+trk
    Table Check    ${conn_id_1}    ${br_name}    table=41    ${araay}
    @{araay}    Create List    actions=resubmit(,17)    ct_state=-new+est-rel-inv+trk
    Table Check    ${conn_id_1}    ${br_name}    table=41    ${araay}
    Switch Connection    ${conn_id_2}
    @{araay}    Create List    goto_table:251
    Table Check    ${conn_id_2}    ${br_name}    table=220    ${araay}
    @{araay}    Create List    table=252    ${ip_list5[0]}    ${linkaddr5}
    Table Check    ${conn_id_2}    ${br_name}    table=251| grep -i ${mac5}    ${araay}
    @{araay}    Create List    resubmit(,220)    ct_state=+new+trk
    Table Check    ${conn_id_2}    ${br_name}    ", table=252" | grep ipv6, | grep ${metadata5}    ${araay}
    @{araay}    Create List    resubmit(,220)    ct_state=-new+est-rel-inv+trk
    Table Check    ${conn_id_2}    ${br_name}    ", table=252" | grep +est    ${araay}
    ${port_id1}    Get Neutron Port    ${mac1}    ${conn_id_1}
    ${port_id5}    Get Neutron Port    ${mac5}    ${conn_id_2}
    [Teardown]    Cleanup IPV6

IPV6_Validate after Modifying the Ipv6 default security groups rules
    [Documentation]    Validate Modify (add/delete/update) the Ipv6 default security groups rules and check that it takes effect in two DPNs.
    Fetch Topology Details    ${conn_id_1}    ${conn_id_2}    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[4]}
    Neutron Security Group Create    ${SG_name[0]}
    Switch Connection    ${conn_id_1}
    ${command}    Set Variable    neutron security-group-rule-list | grep ${SG_name[0]} | awk '{print $2}'
    ${SG_rulelist}    Write Commands Until Expected Prompt    ${command}    $    60
    ${SGlist}    Split To Lines    ${SG_rulelist}
    ${SGlist}    Get Slice From List    ${SGlist}    \    -1
    : FOR    ${rule}    IN    @{SGlist}
    \    ${output}    Write Commands Until Expected Prompt    neutron security-group-rule-delete ${rule}    $    60
    Create SG Rule IPV6    ${direction[0]}    ${rule_list[0]}    10000    10500    IPV6    ${SG_name[0]}
    ...    ${remote_prefix[1]}
    Create SG Rule IPV6    ${direction[1]}    ${rule_list[0]}    10000    10500    IPV6    ${SG_name[0]}
    ...    ${remote_prefix[1]}
    Create SG Rule IPV6    ${direction[0]}    ${rule_list[1]}    10000    10500    IPV6    ${SG_name[0]}
    ...    ${remote_prefix[1]}
    Create SG Rule IPV6    ${direction[1]}    ${rule_list[1]}    10000    10500    IPV6    ${SG_name[0]}
    ...    ${remote_prefix[1]}
    Create SG Rule IPV6    ${direction[0]}    ${rule_list[2]}    10    60    IPV6    ${SG_name[0]}
    ...    ${remote_prefix[1]}
    Create SG Rule IPV6    ${direction[1]}    ${rule_list[2]}    10    60    IPV6    ${SG_name[0]}
    ...    ${remote_prefix[1]}
    Spawn Vm    ${Networks[0]}    ${VM_list[2]}    ${image_name[0]}    ${hostname1}    ${flavour_list[1]}    --security-groups ${SG_name[0]}
    Spawn Vm    ${Networks[0]}    ${VM_list[3]}    ${image_name[0]}    ${hostname2}    ${flavour_list[1]}    --security-groups ${SG_name[0]}
    ${virshid3}    Get Vm Instance    ${VM_list[2]}
    Set Global Variable    ${virshid3}
    ${ip_list3}    Wait Until Keyword Succeeds    50 sec    10 sec    Get VM Ip Addresses From Instance Details    ${VM_list[2]}    ${Networks[0]}
    Set Global Variable    ${ip_list3}
    ${output3}    Virsh Output    ${virshid3}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}
    ...    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)    $
    log    ${output3}
    ${linkaddr3}    Extract Linklocal Addr    ${output3}
    Set Global Variable    ${linkaddr3}
    ${prefixstr1} =    Remove String    ${Prefixes[0]}    ::
    ${prefixstr2} =    Remove String    ${Prefixes[1]}    ::
    Should Contain    ${output3}    ${prefixstr1}
    Should Contain    ${output3}    ${prefixstr2}
    ${ip_list3[0]}    Get From List    ${ip_list3}    0
    ${ip_list3[1]}    Get From List    ${ip_list3}    1
    Should Contain    ${output3}    ${ip_list3[0]}
    Should Contain    ${output3}    ${ip_list3[1]}
    Set Global Variable    ${ip_list3[0]}
    Set Global Variable    ${ip_list3[1]}
    ${mac3}    Extract_Mac_From_Ifconfig    ${output3}
    ${port_id3}    Get Port Id of instance    ${mac3}    ${conn_id_1}
    ${port3}    Get In Port Number For VM    ${br_name}    ${port_id3}
    Set Global Variable    ${mac3}
    log    ${port3}
    Set Global Variable    ${port3}
    ${virshid4}    Get Vm Instance    ${VM_list[3]}
    Set Global Variable    ${virshid4}
    ${ip_list4}    Wait Until Keyword Succeeds    2 min    10 sec    Get VM Ip Addresses From Instance Details    ${VM_list[3]}    ${Networks[0]}
    Set Global Variable    ${ip_list4}
    Switch Connection    ${conn_id_2}
    ${output4}    Virsh Output    ${virshid4}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}
    ...    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)    $
    log    ${output4}
    ${linkaddr4}    Extract Linklocal Addr    ${output4}
    Set Global Variable    ${linkaddr4}
    ${prefixstr1} =    Remove String    ${Prefixes[0]}    ::
    ${prefixstr2} =    Remove String    ${Prefixes[1]}    ::
    Should Contain    ${output4}    ${prefixstr1}
    Should Contain    ${output4}    ${prefixstr2}
    ${ip_list4[0]}    Get From List    ${ip_list4}    0
    ${ip_list4[1]}    Get From List    ${ip_list4}    1
    Should Contain    ${output4}    ${ip_list4[0]}
    Should Contain    ${output4}    ${ip_list4[1]}
    Set Global Variable    ${ip_list4[0]}
    Set Global Variable    ${ip_list4[1]}
    ${mac4}    Extract_Mac_From_Ifconfig    ${output4}
    ${port_id4}    Get Port Id of instance    ${mac4}    ${conn_id_2}
    ${port4}    Get In Port Number For VM    ${br_name}    ${port_id4}
    Set Global Variable    ${mac4}
    log    ${port4}
    Set Global Variable    ${port4}
    Switch Connection    ${conn_id_1}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    ${metadata3}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${br_name}    ${conn_id_1}
    ...    ${port3}
    Set Global Variable    ${metadata3}
    ${metadata4}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${br_name}    ${conn_id_2}
    ...    ${port4}
    Set Global Variable    ${metadata4}
    ${vm3_ip}    Get Subnet Specific Ipv6    ${ip_list3}    ${remote_prefix[1]}
    Set Global Variable    ${vm3_ip}
    ${vm4_ip}    Get Subnet Specific Ipv6    ${ip_list4}    ${remote_prefix[1]}
    Set Global Variable    ${vm4_ip}
    ${pkt_new_before_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +new+trk | grep ${metadata3} | grep icmp6 |grep ipv6_dst=${remote_prefix[1]}
    ${pkt_est_before_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +est
    ${pkt_new_before_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +new+trk | grep ${metadata4} | grep icmp6 | grep ipv6_src=${remote_prefix[1]}
    ${pkt_est_before_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +est
    Ping From Virsh Console    ${virshid3}    ${vm4_ip}    ${conn_id_1}    , 0% packet loss
    ${pkt_new_after_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +new+trk | grep ${metadata3} | grep icmp6 | grep ipv6_dst=${remote_prefix[1]}
    ${pkt_est_after_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +est
    ${pkt_new_after_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +new+trk | grep ${metadata4} | grep icmp6 | \ grep ipv6_src=${remote_prefix[1]}
    ${pkt_est_after_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +est
    ${pkt_diff_new_41}    Evaluate    int(${pkt_new_after_tb41})-int(${pkt_new_before_tb41})
    Should Be Equal As Integers    ${pkt_diff_new_41}    1
    ${pkt_diff_est_41}    Evaluate    int(${pkt_est_after_tb41})-int(${pkt_est_before_tb41})
    Should Be True    ${pkt_diff_est_41} > 0
    ${pkt_diff_new_252}    Evaluate    int(${pkt_new_after_tb252})-int(${pkt_new_before_tb252})
    Should Be Equal As Integers    ${pkt_diff_new_252}    1
    ${pkt_diff_est_252}    Evaluate    int(${pkt_est_after_tb252})-int(${pkt_est_before_tb252})
    Should Be True    ${pkt_diff_est_252} > 0
    ${pkt_new_before_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +new+trk | grep ${metadata3} | grep tcp6 | grep 0xff00 | grep ipv6_dst=${remote_prefix[1]}
    ${pkt_est_before_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +est
    ${pkt_new_before_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +new+trk | grep ${metadata4} | grep tcp6 | grep 0xff00 | grep ipv6_src=${remote_prefix[1]}
    ${pkt_est_before_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +est
    Send Traffic Using Netcat    ${virshid4}    ${virshid3}    ${vm4_ip}    ${vm3_ip}    ${conn_id_2}    ${conn_id_1}
    ...    10250    Hello    tcp
    ${pkt_new_after_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +new+trk | grep ${metadata3} | grep tcp6 | grep 0xff00 | grep ipv6_dst=${remote_prefix[1]}
    ${pkt_est_after_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +est
    ${pkt_new_after_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +new+trk | grep ${metadata4} | grep tcp6 | grep 0xff00 | grep ipv6_src=${remote_prefix[1]}
    ${pkt_est_after_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +est
    ${pkt_diff_new_41}    Evaluate    int(${pkt_new_after_tb41})-int(${pkt_new_before_tb41})
    Should Be Equal As Integers    ${pkt_diff_new_41}    1
    ${pkt_diff_est_41}    Evaluate    int(${pkt_est_after_tb41})-int(${pkt_est_before_tb41})
    Should Be True    ${pkt_diff_est_41} > 0
    ${pkt_diff_new_252}    Evaluate    int(${pkt_new_after_tb252})-int(${pkt_new_before_tb252})
    Should Be Equal As Integers    ${pkt_diff_new_252}    1
    ${pkt_diff_est_252}    Evaluate    int(${pkt_est_after_tb252})-int(${pkt_est_before_tb252})
    Should Be True    ${pkt_diff_est_252} > 0
    Switch Connection    ${conn_id_1}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    Switch Connection    ${conn_id_2}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    ${pkt_new_before_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +new+trk | grep ${metadata3} | grep udp6 | grep 0xff00 | grep ipv6_dst=${remote_prefix[1]}
    ${pkt_est_before_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +est
    ${pkt_new_before_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +new+trk | grep ${metadata4} | grep udp6 | grep 0xff00 | grep ipv6_src=${remote_prefix[1]}
    ${pkt_est_before_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +est
    Send Traffic Using Netcat    ${virshid4}    ${virshid3}    ${vm4_ip}    ${vm3_ip}    ${conn_id_2}    ${conn_id_1}
    ...    10250    Hello
    ${pkt_new_after_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +new+trk | grep ${metadata3} | grep udp6 | grep 0xff00 | grep ipv6_dst=${remote_prefix[1]}
    ${pkt_est_after_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +est
    ${pkt_new_after_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +new+trk | grep ${metadata4} | grep udp6 | grep 0xff00 | grep ipv6_src=${remote_prefix[1]}
    ${pkt_est_after_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +est
    ${pkt_diff_new_41}    Evaluate    int(${pkt_new_after_tb41})-int(${pkt_new_before_tb41})
    ${pkt_diff_est_41}    Evaluate    int(${pkt_est_after_tb41})-int(${pkt_est_before_tb41})
    ${pkt_diff_new_252}    Evaluate    int(${pkt_new_after_tb252})-int(${pkt_new_before_tb252})
    ${pkt_diff_est_252}    Evaluate    int(${pkt_est_after_tb252})-int(${pkt_est_before_tb252})
    Switch Connection    ${conn_id_1}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    Switch Connection    ${conn_id_2}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    @{array}    Create List    goto_table:40    ${metadata3}
    Table Check    ${conn_id_1}    ${br_name}    table=17|grep ${metadata3}    ${array}
    @{array}    Create List    actions=ct(table=41    ${vm3_ip}    ${linkaddr3}
    Table Check    ${conn_id_1}    ${br_name}    table=40| grep -i ${mac3}    ${array}
    @{array}    Create List    actions=resubmit(,17)    ct_state=+new+trk
    Table Check    ${conn_id_1}    ${br_name}    table=41    ${array}
    @{array}    Create List    actions=resubmit(,17)    ct_state=-new+est-rel-inv+trk
    Table Check    ${conn_id_1}    ${br_name}    table=41    ${array}
    Switch Connection    ${conn_id_2}
    @{array}    Create List    goto_table:251
    Table Check    ${conn_id_2}    ${br_name}    table=220    ${array}
    @{array}    Create List    table=252    ${vm4_ip}    ${linkaddr4}
    Table Check    ${conn_id_2}    ${br_name}    table=251| grep -i ${mac4}    ${array}
    @{array}    Create List    resubmit(,220)    ct_state=+new+trk
    Table Check    ${conn_id_2}    ${br_name}    ", table=252" | grep ${protocols[0]} | grep ${metadata4}    ${array}
    @{array}    Create List    resubmit(,220)    ct_state=+new+trk
    Table Check    ${conn_id_2}    ${br_name}    ", table=252" | grep ${protocols[1]} | grep ${metadata4}    ${array}
    @{array}    Create List    resubmit(,220)    ct_state=+new+trk
    Table Check    ${conn_id_2}    ${br_name}    ", table=252" | grep ${protocols[2]} | grep ${metadata4}    ${array}
    @{araay}    Create List    resubmit(,220)    ct_state=-new+est-rel-inv+trk
    Table Check    ${conn_id_2}    ${br_name}    ", table=252" | grep +est    ${araay}
    Log    >>>data store validation>>>
    Switch Connection    ${conn_id_1}
    ${port_id3}    Get Neutron Port    ${mac3}    ${conn_id_1}
    Data Store Validation With Remote Prefix    ${port_id3}    ${remote_prefix[1]}
    ${port_id4}    Get Neutron Port    ${mac4}    ${conn_id_2}
    Data Store Validation With Remote Prefix    ${port_id4}    ${remote_prefix[1]}
    Log    >>>Remove the rules of SG1 >>>
    ${command}    Set Variable    neutron security-group-rule-list | grep ${SG_name[0]} | grep icmpv6 | awk '{print $2}'
    ${SG_rulelist}    Write Commands Until Expected Prompt    ${command}    $    60
    ${SGlist}    Split To Lines    ${SG_rulelist}
    ${SGlist}    Get Slice From List    ${SGlist}    \    -1
    : FOR    ${rule}    IN    @{SGlist}
    \    ${output}    Write Commands Until Expected Prompt    neutron security-group-rule-delete ${rule}    $    60
    Ping From Virsh Console    ${virshid3}    ${vm4_ip}    ${conn_id_1}    100% packet loss
    @{array}    Create List    ct_state=+new+trk
    Table Check With Negative Scenario    ${conn_id_2}    ${br_name}    table=252| grep ${protocols[2]}    ${araay}
    @{array}    Create List    resubmit(,17)
    Table Check With Negative Scenario    ${conn_id_1}    ${br_name}    table=41 | grep ${protocols[2]}    ${araay}

IPV6_Validate ipv6 security group rule with other protocol remote prefix in two DPN
    [Documentation]    Validate ipv6 security group rule with other protocol, remote prefix in two DPNs
    Fetch Topology Details    ${conn_id_1}    ${conn_id_2}    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[4]}
    ${command}    Set Variable    neutron security-group-rule-list | grep ${SG_name[0]}| awk '{print $2}'
    ${SG_rulelist}    Write Commands Until Expected Prompt    ${command}    $    60
    ${SGlist}    Split To Lines    ${SG_rulelist}
    ${SGlist}    Get Slice From List    ${SGlist}    \    -1
    : FOR    ${rule}    IN    @{SGlist}
    \    ${output}    Write Commands Until Expected Prompt    neutron security-group-rule-delete ${rule}    $    60
    Create SG Rule IPV6    ${direction[0]}    6    10000    10500    IPV6    ${SG_name[0]}
    ...    ${remote_prefix[1]}
    Create SG Rule IPV6    ${direction[1]}    6    10000    10500    IPV6    ${SG_name[0]}
    ...    ${remote_prefix[1]}
    Create SG Rule IPV6    ${direction[0]}    17    10000    10500    IPV6    ${SG_name[0]}
    ...    ${remote_prefix[1]}
    Create SG Rule IPV6    ${direction[1]}    17    10000    10500    IPV6    ${SG_name[0]}
    ...    ${remote_prefix[1]}
    ${pkt_new_before_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +new+trk | grep ${metadata3} | grep tcp6 | grep 0xff00 | grep ipv6_dst=${remote_prefix[1]}
    ${pkt_est_before_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +est
    ${pkt_new_before_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +new+trk | grep ${metadata4} | grep tcp6 | grep 0xff00 | grep \ ipv6_src=${remote_prefix[1]}
    ${pkt_est_before_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +est
    Send Traffic Using Netcat    ${virshid4}    ${virshid3}    ${vm4_ip}    ${vm3_ip}    ${conn_id_2}    ${conn_id_1}
    ...    10250    Hello    tcp
    ${pkt_new_after_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +new+trk | grep ${metadata3} | grep tcp6 | grep 0xff00 | grep ipv6_dst=${remote_prefix[1]}
    ${pkt_est_after_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +est
    ${pkt_new_after_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +new+trk | grep ${metadata4} | grep tcp6 | grep 0xff00 | grep \ ipv6_src=${remote_prefix[1]}
    ${pkt_est_after_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +est
    ${pkt_diff_new_41}    Evaluate    int(${pkt_new_after_tb41})-int(${pkt_new_before_tb41})
    Should Be Equal As Integers    ${pkt_diff_new_41}    1
    ${pkt_diff_est_41}    Evaluate    int(${pkt_est_after_tb41})-int(${pkt_est_before_tb41})
    Should Be True    ${pkt_diff_est_41} > 0
    ${pkt_diff_new_252}    Evaluate    int(${pkt_new_after_tb252})-int(${pkt_new_before_tb252})
    Should Be Equal As Integers    ${pkt_diff_new_252}    1
    ${pkt_diff_est_252}    Evaluate    int(${pkt_est_after_tb252})-int(${pkt_est_before_tb252})
    Should Be True    ${pkt_diff_est_252} > 0
    Switch Connection    ${conn_id_1}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    Switch Connection    ${conn_id_2}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    ${pkt_new_before_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +new+trk | grep ${metadata3} | grep udp6 | grep 0xff00 | grep ipv6_dst=${remote_prefix[1]}
    ${pkt_est_before_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +est
    ${pkt_new_before_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +new+trk | grep ${metadata4} | grep udp6 | grep 0xff00 | grep ipv6_src=${remote_prefix[1]}
    ${pkt_est_before_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +est
    Wait Until Keyword Succeeds    60 sec    10 sec    Send Traffic Using Netcat    ${virshid4}    ${virshid3}    ${vm4_ip}
    ...    ${vm3_ip}    ${conn_id_2}    ${conn_id_1}    10250    Hello
    ${pkt_new_after_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +new+trk | grep ${metadata3} | grep udp6 | grep 0xff00 | grep ipv6_dst=${remote_prefix[1]}
    ${pkt_est_after_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +est
    ${pkt_new_after_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +new+trk | grep ${metadata4} | grep udp6 | grep 0xff00 | grep ipv6_src=${remote_prefix[1]}
    ${pkt_est_after_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +est
    ${pkt_diff_new_41}    Evaluate    int(${pkt_new_after_tb41})-int(${pkt_new_before_tb41})
    ${pkt_diff_est_41}    Evaluate    int(${pkt_est_after_tb41})-int(${pkt_est_before_tb41})
    ${pkt_diff_new_252}    Evaluate    int(${pkt_new_after_tb252})-int(${pkt_new_before_tb252})
    ${pkt_diff_est_252}    Evaluate    int(${pkt_est_after_tb252})-int(${pkt_est_before_tb252})
    Switch Connection    ${conn_id_1}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    Switch Connection    ${conn_id_2}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    Log    >>>validation after updating the default SG>>>
    @{array}    Create List    goto_table:40    ${metadata3}
    Table Check    ${conn_id_1}    ${br_name}    table=17|grep ${metadata3}    ${array}
    @{array}    Create List    actions=ct(table=41    ${vm3_ip}    ${linkaddr3}
    Table Check    ${conn_id_1}    ${br_name}    table=40| grep -i ${mac3}    ${array}
    @{array}    Create List    actions=resubmit(,17)    ct_state=+new+trk
    Table Check    ${conn_id_1}    ${br_name}    table=41    ${array}
    @{array}    Create List    actions=resubmit(,17)    ct_state=-new+est-rel-inv+trk
    Table Check    ${conn_id_1}    ${br_name}    table=41    ${array}
    Switch Connection    ${conn_id_2}
    @{array}    Create List    goto_table:251
    Table Check    ${conn_id_2}    ${br_name}    table=220    ${array}
    @{array}    Create List    table=252    ${vm4_ip}    ${linkaddr4}
    Table Check    ${conn_id_2}    ${br_name}    table=251| grep -i ${mac4}    ${array}
    @{array}    Create List    resubmit(,220)    ct_state=+new+trk
    Table Check    ${conn_id_2}    ${br_name}    ", table=252" | grep ${protocols[0]} | grep ${metadata4}    ${array}
    @{array}    Create List    resubmit(,220)    ct_state=+new+trk
    Table Check    ${conn_id_2}    ${br_name}    ", table=252" | grep ${protocols[1]} | grep ${metadata4}    ${array}
    @{araay}    Create List    resubmit(,220)    ct_state=-new+est-rel-inv+trk
    Table Check    ${conn_id_2}    ${br_name}    ", table=252" | grep +est    ${araay}
    Log    >>>data store validation>>>
    Switch Connection    ${conn_id_1}
    ${port_id3}    Get Neutron Port    ${mac3}    ${conn_id_1}
    Data Store Validation With Remote Prefix    ${port_id3}    ${remote_prefix[1]}
    ${port_id4}    Get Neutron Port    ${mac4}    ${conn_id_2}
    Data Store Validation With Remote Prefix    ${port_id4}    ${remote_prefix[1]}

IPV6_Validation of user defined ipv6 security group rules with default security group rules in two DPNs.
    [Documentation]    Validation of user defined ipv6 security group rules with default security group rules in two DPNs.
    Fetch Topology Details    ${conn_id_1}    ${conn_id_2}    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[4]}
    ${command}    Set Variable    neutron security-group-rule-list | grep ${SG_name[0]}| awk '{print $2}'
    ${SG_rulelist}    Write Commands Until Expected Prompt    ${command}    $    60
    ${SGlist}    Split To Lines    ${SG_rulelist}
    ${SGlist}    Get Slice From List    ${SGlist}    \    -1
    : FOR    ${rule}    IN    @{SGlist}
    \    ${output}    Write Commands Until Expected Prompt    neutron security-group-rule-delete ${rule}    $    60
    ${id}    Get Security Group Id For Admin Default
    Log    >>>create rules under SG1>>>
    Create SG Rule IPV6    ${direction[0]}    ${rule_list[0]}    10000    10500    IPV6    ${SG_name[0]}
    ...    ${id}    SG
    Create SG Rule IPV6    ${direction[1]}    ${rule_list[0]}    10000    10500    IPV6    ${SG_name[0]}
    ...    ${id}    SG
    Create SG Rule IPV6    ${direction[0]}    ${rule_list[1]}    10000    10500    IPV6    ${SG_name[0]}
    ...    ${id}    SG
    Create SG Rule IPV6    ${direction[1]}    ${rule_list[1]}    10000    10500    IPV6    ${SG_name[0]}
    ...    ${id}    SG
    Create SG Rule IPV6    ${direction[0]}    ${rule_list[2]}    10    60    IPV6    ${SG_name[0]}
    ...    ${id}    SG
    Create SG Rule IPV6    ${direction[1]}    ${rule_list[2]}    10    60    IPV6    ${SG_name[0]}
    ...    ${id}    SG
    ${sg1id}    Get Security Group Id    ${SG_name[0]}    ${Networks[0]}
    Create SG Rule IPV6    ${direction[0]}    ${rule_list[0]}    10000    10500    IPV6    ${id}
    ...    ${sg1id}    SG
    Create SG Rule IPV6    ${direction[0]}    ${rule_list[1]}    10000    10500    IPV6    ${id}
    ...    ${sg1id}    SG
    Create SG Rule IPV6    ${direction[0]}    ${rule_list[2]}    10    60    IPV6    ${id}
    ...    ${sg1id}    SG
    ${vm3_ip}    Get Subnet Specific Ipv6    ${ip_list3}    ${remote_prefix[1]}
    Set Global Variable    ${vm3_ip}
    ${vm4_ip}    Get Subnet Specific Ipv6    ${ip_list4}    ${remote_prefix[1]}
    Set Global Variable    ${vm4_ip}
    ${vm5_ip}    Get Subnet Specific Ipv6    ${ip_list5}    ${remote_prefix[1]}
    Set Global Variable    ${vm5_ip}
    @{array}    Create List    ${vm5_ip}    ${metadata3}
    Wait Until Keyword Succeeds    180 sec    10 sec    Table Check    ${conn_id_1}    ${br_name}    table=41 |grep +new+trk | grep ${metadata3} | grep icmp6 | grep ipv6_dst=${vm5_ip}
    ...    ${array}
    ${pkt_new_before_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +new+trk | grep ${metadata3} | grep icmp6 | grep ipv6_dst=${vm5_ip}
    ${pkt_est_before_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +est
    @{array}    Create List    ${vm3_ip}    ${metadata5}
    Wait Until Keyword Succeeds    180 sec    10 sec    Table Check    ${conn_id_2}    ${br_name}    table=252 |grep +new+trk | grep ${metadata5} | grep icmp6 | grep ipv6_src=${vm3_ip}
    ...    ${array}
    ${pkt_new_before_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +new+trk | grep ${metadata5} | grep icmp6 | grep ipv6_src=${vm3_ip}
    ${pkt_est_before_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +est
    Wait Until Keyword Succeeds    60 sec    10 sec    Ping From Virsh Console    ${virshid3}    ${vm5_ip}    ${conn_id_1}
    ...    , 0% packet loss
    ${pkt_new_after_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +new+trk | grep ${metadata3} | grep icmp6 | grep ipv6_dst=${vm5_ip}
    ${pkt_est_after_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +est
    ${pkt_new_after_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +new+trk | grep ${metadata5} | grep icmp6 | grep ipv6_src=${vm3_ip}
    ${pkt_est_after_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +est
    ${pkt_diff_new_41}    Evaluate    int(${pkt_new_after_tb41})-int(${pkt_new_before_tb41})
    Should Be True    ${pkt_diff_new_41} > 0
    ${pkt_diff_est_41}    Evaluate    int(${pkt_est_after_tb41})-int(${pkt_est_before_tb41})
    Should Be True    ${pkt_diff_est_41} > 0
    ${pkt_diff_new_252}    Evaluate    int(${pkt_new_after_tb252})-int(${pkt_new_before_tb252})
    Should Be True    int(${pkt_new_after_tb252}) > 0
    ${pkt_diff_est_252}    Evaluate    int(${pkt_est_after_tb252})-int(${pkt_est_before_tb252})
    Should Be True    ${pkt_diff_est_252} > 0
    ${pkt_new_before_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +new+trk | grep ${metadata3} | grep tcp6 | grep 0xff00 | grep ipv6_dst=${vm5_ip}
    ${pkt_est_before_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +est
    ${pkt_new_before_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +new+trk | grep ${metadata5} | grep tcp6 | grep ipv6_src=${vm3_ip} | grep 0xff00
    ${pkt_est_before_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +est
    Wait Until Keyword Succeeds    60 sec    10 sec    Send Traffic Using Netcat    ${virshid5}    ${virshid3}    ${vm5_ip}
    ...    ${vm3_ip}    ${conn_id_2}    ${conn_id_1}    10250    Hello    tcp
    ${pkt_new_after_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +new+trk | grep ${metadata3} | grep tcp6 | grep 0xff00 | grep ipv6_dst=${vm5_ip}
    ${pkt_est_after_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +est
    ${pkt_new_after_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +new+trk | grep ${metadata5} | grep tcp6 | grep ipv6_src=${vm3_ip} | grep 0xff00
    ${pkt_est_after_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +est
    ${pkt_diff_new_41}    Evaluate    int(${pkt_new_after_tb41})-int(${pkt_new_before_tb41})
    Should Be True    ${pkt_diff_new_41} > 0
    ${pkt_diff_est_41}    Evaluate    int(${pkt_est_after_tb41})-int(${pkt_est_before_tb41})
    Should Be True    ${pkt_diff_est_41} > 0
    ${pkt_diff_new_252}    Evaluate    int(${pkt_new_after_tb252})-int(${pkt_new_before_tb252})
    Should Be True    int(${pkt_new_after_tb252}) > 0
    ${pkt_diff_est_252}    Evaluate    int(${pkt_est_after_tb252})-int(${pkt_est_before_tb252})
    Should Be True    ${pkt_diff_est_252} > 0
    Switch Connection    ${conn_id_1}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    Switch Connection    ${conn_id_2}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    ${pkt_new_before_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +new+trk | grep ${metadata3} | grep udp6 | grep 0xff00 | grep ipv6_dst=${vm5_ip}
    ${pkt_est_before_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +est
    ${pkt_new_before_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +new+trk | grep ${metadata5} | grep udp6 | grep ipv6_src=${vm3_ip} | grep 0xff00
    ${pkt_est_before_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +est
    Wait Until Keyword Succeeds    60 sec    10 sec    Send Traffic Using Netcat    ${virshid5}    ${virshid3}    ${vm5_ip}
    ...    ${vm3_ip}    ${conn_id_2}    ${conn_id_1}    10250    Hello
    ${pkt_new_after_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +new+trk | grep ${metadata3} | grep udp6 | grep 0xff00 | grep ipv6_dst=${vm5_ip}
    ${pkt_est_after_tb41}    Get Packetcount    ${br_name}    ${conn_id_1}    table=41    +est
    ${pkt_new_after_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +new+trk | grep ${metadata5} | grep udp6 | grep ipv6_src=${vm3_ip} | grep 0xff00
    ${pkt_est_after_tb252}    Get Packetcount    ${br_name}    ${conn_id_2}    table=252    +est
    ${pkt_diff_new_41}    Evaluate    int(${pkt_new_after_tb41})-int(${pkt_new_before_tb41})
    ${pkt_diff_est_41}    Evaluate    int(${pkt_est_after_tb41})-int(${pkt_est_before_tb41})
    ${pkt_diff_new_252}    Evaluate    int(${pkt_new_after_tb252})-int(${pkt_new_before_tb252})
    ${pkt_diff_est_252}    Evaluate    int(${pkt_est_after_tb252})-int(${pkt_est_before_tb252})
    Switch Connection    ${conn_id_1}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    Switch Connection    ${conn_id_2}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    @{array}    Create List    goto_table:40    ${metadata3}
    Table Check    ${conn_id_1}    ${br_name}    table=17|grep ${metadata3}    ${array}
    @{array}    Create List    actions=ct(table=41    ${vm3_ip}    ${linkaddr3}
    Table Check    ${conn_id_1}    ${br_name}    table=40| grep -i ${mac3}    ${array}
    @{array}    Create List    actions=resubmit(,17)    ct_state=+new+trk
    Table Check    ${conn_id_1}    ${br_name}    table=41    ${array}
    @{array}    Create List    actions=resubmit(,17)    ct_state=-new+est-rel-inv+trk
    Table Check    ${conn_id_1}    ${br_name}    table=41    ${array}
    Switch Connection    ${conn_id_2}
    @{array}    Create List    goto_table:251
    Table Check    ${conn_id_2}    ${br_name}    table=220    ${array}
    @{array}    Create List    table=252    ${vm5_ip}    ${linkaddr5}
    Table Check    ${conn_id_2}    ${br_name}    table=251| grep -i ${mac5}    ${array}
    @{array}    Create List    resubmit(,220)    ct_state=+new+trk
    Table Check    ${conn_id_2}    ${br_name}    ", table=252" | grep ipv6 | grep ${metadata5}    ${array}
    @{araay}    Create List    resubmit(,220)    ct_state=-new+est-rel-inv+trk
    Table Check    ${conn_id_2}    ${br_name}    ", table=252" | grep +est    ${araay}

IPV6_Validate Ipv6 port security with allowed address pair for ipv6/mac address in two DPNs.
    [Documentation]    Validate Ipv6 port security with allowed address pair for ipv6/mac address in two DPNs
    Switch Connection    ${conn_id_1}
    ${command}    Set Variable    neutron port-create ${Networks[0]} --name P31 --allowed-address-pairs type=dict list=true ip_address=${logical_addr[0]}/128
    ${output}    Write Commands Until Expected Prompt    ${command}    $    60
    Should Contain    ${output}    P31
    Delete Vm Instance    ${VM_list[2]}
    Wait Until Keyword Succeeds    60 sec    10 sec    Verify Vm Deletion    ${VM_list[2]}    ${mac3}    ${conn_id_1}
    ...    ${br_name}
    ${vm_spawn}    Write Commands Until Expected Prompt    nova boot --flavor ${flavour_list[1]} --image \ ${image_name[0]} --nic port-id=\$(neutron port-list | grep 'P31' | awk '{print $2}') \ ${VM_list[2]} --availability-zone nova:${hostname1}    $    420
    log    ${vm_spawn}
    should contain    ${vm_spawn}    ${VM_list[2]}
    Wait Until Keyword Succeeds    300 sec    10 sec    Verify Vm Creation    ${VM_list[2]}
    ${output}    Write Commands Until Expected Prompt    ${command}    $    60
    ${virshid3}    Get Vm Instance    ${VM_list[2]}
    Set Global Variable    ${virshid3}
    ${ip_list3}    Wait Until Keyword Succeeds    50 sec    10 sec    Get VM Ip Addresses From Instance Details    ${VM_list[2]}    ${Networks[0]}
    Set Global Variable    ${ip_list3}
    ${output3}    Virsh Output    ${virshid3}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}
    ...    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)    $
    log    ${output3}
    ${linkaddr3}    Extract Linklocal Addr    ${output3}
    Set Global Variable    ${linkaddr3}
    ${prefixstr1} =    Remove String    ${Prefixes[0]}    ::
    ${prefixstr2} =    Remove String    ${Prefixes[1]}    ::
    Should Contain    ${output3}    ${prefixstr1}
    Should Contain    ${output3}    ${prefixstr2}
    ${ip_list3[0]}    Get From List    ${ip_list3}    0
    ${ip_list3[1]}    Get From List    ${ip_list3}    0
    Should Contain    ${output3}    ${ip_list3[0]}
    Should Contain    ${output3}    ${ip_list3[1]}
    Set Global Variable    ${ip_list3[0]}
    Set Global Variable    ${ip_list3[1]}
    ${mac3}    Extract_Mac_From_Ifconfig    ${output3}
    ${port_id3}    Get Port Id of instance    ${mac3}    ${conn_id_1}
    ${port3}    Get In Port Number For VM    ${br_name}    ${port_id3}
    Set Global Variable    ${mac3}
    log    ${port3}
    Set Global Variable    ${port3}
    Virsh Login    ${virshid3}
    ${output}    Write Commands Until Expected Prompt    sudo ifconfig eth0 add ${logical_addr[0]}/64    $    60
    Virsh Exit
    Log    >>>log in to vm5 >>>
    Switch Connection    ${conn_id_2}
    Wait Until Keyword Succeeds    50 sec    10 sec    Ping From Virsh Console    ${virshid5}    ${logical_addr[0]}    ${conn_id_2}
    ...    , 0% packet loss
    Log    >>>Table check>>>
    @{araay}    Create List    goto_table:40    ${metadata5}
    Table Check    ${conn_id_2}    ${br_name}    table=17|grep ${metadata5}    ${araay}
    @{araay}    Create List    table=41    ${logical_addr[0]}    ${linkaddr3}
    Table Check    ${conn_id_1}    ${br_name}    table=40| grep -i ${mac3}    ${araay}
    @{araay}    Create List    actions=resubmit(,17)    ct_state=-new+est-rel-inv+trk    ipv6
    Table Check    ${conn_id_1}    ${br_name}    table=41    ${araay}
    Log    >>>the allowed-address pair on neutron port >>>
    Switch Connection    ${conn_id_1}
    ${port_id3}    Get Neutron Port    ${mac3}    ${conn_id_1}
    ${command}    Set Variable    neutron port-show ${port_id3} | grep allowed_address_pairs | grep -i ${mac3}
    ${output}    Write Commands Until Expected Prompt    ${command}    $    60
    Should Contain    ${output}    ${logical_addr[0]}
    Switch Connection    ${conn_id_1}

IPV6_Validate Ipv6 port security with multiple allowed address pair for ipv6/mac address in two DPNs
    [Documentation]    Validate Ipv6 port security with multiple allowed address pair for ipv6/mac address in two DPNs.
    Switch Connection    ${conn_id_1}
    ${command}    Set Variable    neutron port-create ${Networks[0]} --name P32 --allowed-address-pairs type=dict list=true ip_address=${logical_addr[0]}/64
    ${output}    Write Commands Until Expected Prompt    ${command}    $    30
    Should Contain    ${output}    P32
    Delete Vm Instance    ${VM_list[2]}
    Wait Until Keyword Succeeds    60 sec    10 sec    Verify Vm Deletion    ${VM_list[2]}    ${mac3}    ${conn_id_1}
    ...    ${br_name}
    ${vm_spawn}    Write Commands Until Expected Prompt    nova boot --flavor ${flavour_list[1]} --image \ ${image_name[0]} --nic port-id=\$(neutron port-list | grep 'P32' | awk '{print $2}') \ ${VM_list[2]} --availability-zone nova:${hostname1}    $    420
    log    ${vm_spawn}
    should contain    ${vm_spawn}    ${VM_list[2]}
    Wait Until Keyword Succeeds    300 sec    10 sec    Verify Vm Creation    ${VM_list[2]}
    ${output}    Write Commands Until Expected Prompt    ${command}    $    60
    ${virshid3}    Get Vm Instance    ${VM_list[2]}
    Set Global Variable    ${virshid3}
    ${ip_list3}    Wait Until Keyword Succeeds    50 sec    10 sec    Get VM Ip Addresses From Instance Details    ${VM_list[2]}    ${Networks[0]}
    Set Global Variable    ${ip_list3}
    ${output3}    Virsh Output    ${virshid3}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}
    ...    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)    $
    log    ${output3}
    ${linkaddr3}    Extract Linklocal Addr    ${output3}
    Set Global Variable    ${linkaddr3}
    ${prefixstr1} =    Remove String    ${Prefixes[0]}    ::
    ${prefixstr2} =    Remove String    ${Prefixes[1]}    ::
    Should Contain    ${output3}    ${prefixstr1}
    Should Contain    ${output3}    ${prefixstr2}
    ${ip_list3[0]}    Get From List    ${ip_list3}    0
    ${ip_list3[1]}    Get From List    ${ip_list3}    0
    Should Contain    ${output3}    ${ip_list3[0]}
    Should Contain    ${output3}    ${ip_list3[1]}
    Set Global Variable    ${ip_list3[0]}
    Set Global Variable    ${ip_list3[1]}
    ${mac3}    Extract_Mac_From_Ifconfig    ${output3}
    ${port_id3}    Get Port Id of instance    ${mac3}    ${conn_id_1}
    ${port3}    Get In Port Number For VM    ${br_name}    ${port_id3}
    Set Global Variable    ${mac3}
    log    ${port3}
    Set Global Variable    ${port3}
    Virsh Login    ${virshid3}
    ${output}    Write Commands Until Expected Prompt    sudo ifconfig eth0 add ${logical_addr[0]}/64    $    60
    ${output}    Write Commands Until Expected Prompt    sudo ifconfig eth0 add ${logical_addr[1]}/64    $    60
    Virsh Exit
    Switch Connection    ${conn_id_2}
    Wait Until Keyword Succeeds    60 sec    10 sec    Ping From Virsh Console    ${virshid5}    ${logical_addr[0]}    ${conn_id_2}
    ...    , 0% packet loss
    @{araay}    Create List    goto_table:40    ${metadata5}
    Table Check    ${conn_id_2}    ${br_name}    table=17|grep ${metadata5}    ${araay}
    @{araay}    Create List    table=41    ${prefixstr1}    ${linkaddr3}
    Table Check    ${conn_id_1}    ${br_name}    table=40| grep -i ${mac3}    ${araay}
    @{araay}    Create List    actions=resubmit(,17)    ct_state=-new+est-rel-inv+trk    ipv6
    Table Check    ${conn_id_1}    ${br_name}    table=41    ${araay}
    Log    >>>the allowed-address pair on neutron port >>>
    Switch Connection    ${conn_id_1}
    ${port_id3}    Get Neutron Port    ${mac3}    ${conn_id_1}
    ${command}    Set Variable    neutron port-show ${port_id3} | grep allowed_address_pairs | grep -i ${mac3}
    ${output}    Write Commands Until Expected Prompt    ${command}    $    60
    Should Contain    ${output}    ${logical_addr[0]}
    Wait Until Keyword Succeeds    60 sec    10 sec    Ping From Virsh Console    ${virshid5}    ${logical_addr[1]}    ${conn_id_2}
    ...    , 0% packet loss
    [Teardown]    Delete Topology

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
    Spawn Vm    ${Networks[0]}    ${VM_list[0]}    ${image_name[0]}    ${hostname1}    ${flavour_list[1]}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    Spawn Vm    ${Networks[0]}    ${VM_list[1]}    ${image_name[0]}    ${hostname1}    ${flavour_list[1]}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    log    ${flowdump}
    Spawn Vm    ${Networks[0]}    ${VM_list[4]}    ${image_name[0]}    ${hostname2}    ${flavour_list[1]}
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
    [Documentation]    THis keyword get the security group ID for the default SG for the admin project.
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

Cleanup IPV6
    [Documentation]    Cleanup after IPV6 assignment cases.
    Log    >>>Delete Vms with IPv4 address>>>
    Switch Connection    ${conn_id_1}
    Delete Vm Instance    ${VM_list[2]}
    Wait Until Keyword Succeeds    60 sec    10 sec    verify vm deletion    ${VM_list[2]}    ${mac3}    ${conn_id_1}
    ...    ${br_name}
    Delete Vm Instance    ${VM_list[3]}
    Wait Until Keyword Succeeds    60 sec    10 sec    verify vm deletion    ${VM_list[3]}    ${mac4}    ${conn_id_2}
    ...    ${br_name}
    Log    >>>Delete the Subnets and network>>>
    Delete SubNet    ${V4subnet_names[0]}
    Remove Interface    ${Routers[0]}    ${Subnets[2]}
    Delete SubNet    ${Subnets[2]}
    Delete Network    ${Networks[1]}

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

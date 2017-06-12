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
Resource          ../../../libraries/Genius.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../variables/IPV6Service_Variables.robot

*** Variables ***
${netvirt_config_dir}    ${CURDIR}/../../../variables/netvirt
${genius_config_dir}    ${CURDIR}/../../../variables/genius

*** Test Cases ***
7.6.1_Validate Ipv6 default security group contains all the default security group rules as expected
    [Documentation]    Validate Ipv6 default security group contains all the default security group rules as expected.
    [Setup]    Create Topology
    fetch topology details    ${conn_id_1}    ${conn_id_2}    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[4]}
    Switch Connection    ${conn_id_1}
    ${metadata1}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_1}
    ...    ${port1}
    Set Global Variable    ${metadata1}
    ${metadata2}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${Br_Name}    ${conn_id_1}
    ...    ${port2}
    Set Global Variable    ${metadata2}
    ${conn_id_1_1}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}
    Set Global Variable    ${conn_id_1_1}
    Switch Connection    ${conn_id_1_1}
    Ping From Virsh Console    ${virshid1}    ${ip_list2[0]}    ${conn_id_1}    , 0% packet loss
    send traffic using netcat    ${virshid1}    ${virshid2}    ${ip_list1[0]}    ${ip_list2[0]}    ${conn_id_1}    ${conn_id_1_1}
    ...    10000    Hello
    send traffic using netcat    ${virshid1}    ${virshid2}    ${ip_list1[0]}    ${ip_list2[0]}    ${conn_id_1}    ${conn_id_1_1}
    ...    10000    Hello    tcp
    Switch Connection    ${conn_id_1_1}
    Close Connection

7.6.2_Validate Ipv6 default security groups are associated with the VM’s even after the VM is rebooted
    [Documentation]    Validate Ipv6 default security groups are associated with the VM’s even after the VM is rebooted
    fetch topology details    ${conn_id_1}    ${conn_id_2}    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[4]}
    Reboot Nova VM    ${VM_List[0]}
    Reboot Nova VM    ${VM_List[1]}
    Switch Connection    ${conn_id_1}
    ${output1}    Wait Until Keyword Succeeds    120 sec    10 sec    Check Ip Address In Ifconfig Output    ${virshid1}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    Should Contain    ${output1}    ${ip_list1[0]}
    Should Contain    ${output1}    ${ip_list1[1]}
    ${output2}    Wait Until Keyword Succeeds    120 sec    10 sec    Check Ip Address In Ifconfig Output    ${virshid2}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros
    ...    cubswin:)    $
    Should Contain    ${output2}    ${ip_list2[0]}
    Should Contain    ${output2}    ${ip_list2[1]}
    ${port_id1}    Get Port Id of instance    ${mac1}    ${conn_id_1}
    ${port1}    Get In Port Number For VM    ${br_name}    ${port_id1}
    Set Global Variable    ${port1}
    ${metadata1}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${br_name}    ${conn_id_1}
    ...    ${port1}
    Set Global Variable    ${metadata1}
    ${port_id2}    Get Port Id of instance    ${mac2}    ${conn_id_1}
    ${port2}    Get In Port Number For VM    ${br_name}    ${port_id2}
    Set Global Variable    ${port2}
    ${metadata2}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${br_name}    ${conn_id_1}
    ...    ${port2}
    Set Global Variable    ${metadata2}
    ${conn_id_1_1}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}
    Set Global Variable    ${conn_id_1_1}
    Switch Connection    ${conn_id_1_1}
    Ping From Virsh Console    ${virshid1}    ${ip_list2[0]}    ${conn_id_1}    , 0% packet loss
    send traffic using netcat    ${virshid1}    ${virshid2}    ${ip_list1[0]}    ${ip_list2[0]}    ${conn_id_1}    ${conn_id_1_1}
    ...    10000    Hello
    send traffic using netcat    ${virshid1}    ${virshid2}    ${ip_list1[0]}    ${ip_list2[0]}    ${conn_id_1}    ${conn_id_1_1}
    ...    10000    Hello    tcp
    Switch Connection    ${conn_id_1_1}
    Close Connection

7.6.15_Validate ipv6 security group rule with custom icmp protocol, remote prefix, type and code
    [Documentation]    Validate ipv6 security group rule with custom icmp protocol, remote prefix, type and code \
    fetch topology details    ${conn_id_1}    ${conn_id_2}    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[4]}
    Delete Vm Instance    ${VM_List[0]}
    Verify Vm Deletion    ${VM_List[0]}    ${mac1}    ${conn_id_1}    ${br_name}
    Delete Vm Instance    ${VM_List[1]}
    Verify Vm Deletion    ${VM_List[1]}    ${mac2}    ${conn_id_1}    ${br_name}
    Neutron Security Group Create    ${SG_name[0]}
    Switch Connection    ${conn_id_1}
    ${command}    Set Variable    neutron security-group-rule-list | grep ${SG_Name[0]} | awk '{print $2}'
    ${SG_rulelist}    Write Commands Until Expected Prompt    ${command}    $    60
    ${SGlist}    Split To Lines    ${SG_rulelist}
    ${SGlist}    Get Slice From List    ${SGlist}    \    -1
    : FOR    ${rule}    IN    @{SGlist}
    \    ${output}    Write Commands Until Expected Prompt    neutron security-group-rule-delete ${rule}    $    60
    ${hostname1}    Get Vm Hostname    ${conn_id_1}
    Set Global Variable    ${hostname1}
    Spawn Vm    ${Networks[0]}    ${VM_List[0]}    ${image[0]}    ${hostname1}    ${flavour_list[1]}    --security-groups ${SG_name[0]}
    Spawn Vm    ${Networks[0]}    ${VM_List[1]}    ${image[0]}    ${hostname1}    ${flavour_list[1]}    --security-groups ${SG_name[0]}
    Wait Until Keyword Succeeds    30 sec    10 sec    verify vm creation    ${VM_List[0]}
    ${virshid1}    Get Vm Instance    ${VM_List[0]}
    Set Global Variable    ${virshid1}
    ${ip_list1}    Wait Until Keyword Succeeds    50 sec    10 sec    Get VM Ip Addresses From Instance Details    ${VM_List[0]}    ${Networks[0]}
    Set Global Variable    ${ip_list1}
    ${ip_list1[0]}    Get From List    ${ip_list1}    0
    ${ip_list1[1]}    Get From List    ${ip_list1}    1
    Set Global Variable    ${ip_list1[0]}
    Set Global Variable    ${ip_list1[1]}
    ${output1}    Virsh Output    ${virshid1}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}
    ...    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)    $
    ${linkaddr1}    Extract Linklocal Addr    ${output1}
    Set Global Variable    ${linkaddr1}
    ${prefixstr1} =    Remove String    ${Prefixes[0]}    ::
    ${prefixstr2} =    Remove String    ${Prefixes[1]}    ::
    Should Contain    ${output1}    ${prefixstr1}
    Should Contain    ${output1}    ${prefixstr2}
    Should Contain    ${output1}    ${ip_list1[0]}
    Should Contain    ${output1}    ${ip_list1[1]}
    ${mac1}    Extract_Mac_From_Ifconfig    ${output1}
    ${port_id1}    Get Port Id of instance    ${mac1}    ${conn_id_1}
    ${port1}    Get In Port Number For VM    ${br_name1}    ${port_id1}
    Set Global Variable    ${mac1}
    Set Global Variable    ${port1}
    Wait Until Keyword Succeeds    30 sec    10 sec    verify vm creation    ${VM_List[1]}
    ${virshid2}    Get Vm Instance    ${VM_List[1]}
    Set Global Variable    ${virshid2}
    ${ip_list2}    Wait Until Keyword Succeeds    50 sec    10 sec    Get VM Ip Addresses From Instance Details    ${VM_List[1]}    ${Networks[0]}
    Set Global Variable    ${ip_list2}
    ${ip_list2[0]}    Get From List    ${ip_list2}    0
    ${ip_list2[1]}    Get From List    ${ip_list2}    1
    Set Global Variable    ${ip_list2[0]}
    Set Global Variable    ${ip_list2[1]}
    ${output2}    Virsh Output    ${virshid2}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}
    ...    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)    $
    ${linkaddr2}    Extract Linklocal Addr    ${output2}
    Set Global Variable    ${linkaddr2}
    ${prefixstr1} =    Remove String    ${Prefixes[0]}    ::
    ${prefixstr2} =    Remove String    ${Prefixes[1]}    ::
    Should Contain    ${output2}    ${prefixstr1}
    Should Contain    ${output2}    ${prefixstr2}
    Should Contain    ${output2}    ${ip_list2[0]}
    Should Contain    ${output2}    ${ip_list2[1]}
    ${mac2}    Extract_Mac_From_Ifconfig    ${output2}
    ${port_id2}    Get Port Id of instance    ${mac2}    ${conn_id_1}
    ${port2}    Get In Port Number For VM    ${br_name}    ${port_id2}
    Set Global Variable    ${mac2}
    Set Global Variable    ${port2}
    Set Global Variable    ${port1}
    Create SG Rule IPV6    ${Direction[0]}    ${Rule_List[2]}    133    0    IPV6    ${SG_name[0]}
    ...    ${remote_prefix[1]}
    Create SG Rule IPV6    ${Direction[1]}    ${Rule_List[2]}    133    0    IPV6    ${SG_name[0]}
    ...    ${remote_prefix[1]}
    Create SG Rule IPV6    ${Direction[0]}    ${Rule_List[2]}    134    0    IPV6    ${SG_name[0]}
    ...    ${remote_prefix[1]}
    Create SG Rule IPV6    ${Direction[1]}    ${Rule_List[2]}    134    0    IPV6    ${SG_name[0]}
    ...    ${remote_prefix[1]}
    Create SG Rule IPV6    ${Direction[0]}    ${Rule_List[2]}    135    0    IPV6    ${SG_name[0]}
    ...    ${remote_prefix[1]}
    Create SG Rule IPV6    ${Direction[1]}    ${Rule_List[2]}    135    0    IPV6    ${SG_name[0]}
    ...    ${remote_prefix[1]}
    Create SG Rule IPV6    ${Direction[0]}    ${Rule_List[2]}    136    0    IPV6    ${SG_name[0]}
    ...    ${remote_prefix[1]}
    Create SG Rule IPV6    ${Direction[1]}    ${Rule_List[2]}    136    0    IPV6    ${SG_name[0]}
    ...    ${remote_prefix[1]}
    ping from virsh console    ${virshid1}    ${ip_list2[0]}    ${conn_id_1}    , 0% packet loss
    ${metadata1}    Wait Until Keyword Succeeds    30 sec    10 sec    Table 0 Check For VM Creation    ${br_name}    ${conn_id_1}
    ...    ${port1}
    ${lower_mac1}    Convert To Lowercase    ${mac1}
    @{array}    Create List    goto_table:40    ${metadata1}
    table check    ${conn_id_1}    ${br_name}    table=17|grep ${metadata1}    ${array}
    @{array}    Create List    actions=ct(table=41    ${vm1ip}    ${linkaddr1}
    table check    ${conn_id_1}    ${Br_Name}    table=40| grep -i ${mac1}    ${array}
    @{array}    Create List    actions=resubmit(,17)    ct_state=+new+trk    \    ${EMPTY}    ${EMPTY}
    ...    \    \    Hello
    table check    ${conn_id_1}    ${br_name}    table=41    ${array}
    @{array}    Create List    actions=resubmit(,17)    ct_state=-new+est-rel-inv+trk
    table check    ${conn_id_1}    ${br_name}    table=41    ${array}

7.6.20_Validate Multiple VMs associated to multiple SG
    Fetch Topology Details    ${conn_id_1}    ${conn_id_2}    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[4]}
    ${command}    Set Variable    neutron security-group-rule-list | grep ${SG_Name[0]} | awk '{print $2}'
    ${SG_rulelist}    Write Commands Until Expected Prompt    ${command}    $    60
    ${SGlist}    Split To Lines    ${SG_rulelist}
    ${SGlist}    Get Slice From List    ${SGlist}    \    -1
    : FOR    ${rule}    IN    @{SGlist}
    \    ${output}    Write Commands Until Expected Prompt    neutron security-group-rule-delete ${rule}    $    60
    Create SG Rule IPV6    ${Direction[0]}    ${Rule_List[0]}    2000    2010    IPV6    ${SG_Name[0]}
    ...    ${SG_Name[4]}
    Create SG Rule IPV6    ${Direction[1]}    ${Rule_List[0]}    2000    2010    IPV6    ${SG_Name[0]}
    ...    ${SG_Name[4]}
    Create SG Rule IPV6    ${Direction[0]}    ${Rule_List[1]}    2000    2010    IPV6    ${SG_Name[0]}
    ...    ${SG_Name[4]}
    Create SG Rule IPV6    ${Direction[1]}    ${Rule_List[1]}    2000    2010    IPV6    ${SG_Name[0]}
    ...    ${SG_Name[4]}
    Create SG Rule IPV6    ${Direction[0]}    ${Rule_List[2]}    2000    2010    IPV6    ${SG_Name[0]}
    ...    ${SG_Name[4]}
    Create SG Rule IPV6    ${Direction[1]}    ${Rule_List[2]}    2000    2010    IPV6    ${SG_Name[0]}
    ...    ${SG_Name[4]}
    ${command}    Set Variable    neutron security-group-rule-list | grep ${SG_Name[1]} | awk '{print $2}'
    ${SG_rulelist}    Write Commands Until Expected Prompt    ${command}    $    60
    ${SGlist}    Split To Lines    ${SG_rulelist}
    ${SGlist}    Get Slice From List    ${SGlist}    \    -1
    : FOR    ${rule}    IN    @{SGlist}
    \    ${output}    Write Commands Until Expected Prompt    neutron security-group-rule-delete ${rule}    $    60
    Create SG Rule IPV6    ${Direction[0]}    ${Rule_List[0]}    4000    4010    IPV6    ${SG_Name[0]}
    ...    ${SG_Name[4]}
    Create SG Rule IPV6    ${Direction[1]}    ${Rule_List[0]}    4000    4010    IPV6    ${SG_Name[0]}
    ...    ${SG_Name[4]}
    Create SG Rule IPV6    ${Direction[0]}    ${Rule_List[1]}    4000    4010    IPV6    ${SG_Name[0]}
    ...    ${SG_Name[4]}
    Create SG Rule IPV6    ${Direction[1]}    ${Rule_List[1]}    4000    4010    IPV6    ${SG_Name[0]}
    ...    ${SG_Name[4]}
    Create SG Rule IPV6    ${Direction[0]}    ${Rule_List[2]}    4000    4010    IPV6    ${SG_Name[0]}
    ...    ${SG_Name[4]}
    Create SG Rule IPV6    ${Direction[1]}    ${Rule_List[2]}    4000    4010    IPV6    ${SG_Name[0]}
    ...    ${SG_Name[4]}
    ${port_id2}    get neutron port    ${mac2}    ${conn_id_1}
    ${command}    Set Variable    neutron port-update --no-security-groups ${port_id2}
    ${output}    Write Commands Until Expected Prompt    ${command}    $    60
    ${command}    Set Variable    neutron port-update --security-group ${SG_Name[1]} ${port_id2}
    ${output}    Write Commands Until Expected Prompt    ${command}    $    60
    ping from virsh console    ${virshid1}    ${ip_list2[0]}    ${conn_id_1}    , 0% packet loss
    send traffic using netcat    ${virshid1}    ${virshid2}    ${ip_list1[0]}    ${ip_list2[0]}    ${conn_id_1}    ${conn_id_2}
    ...    10000    Hello    tcp
    send traffic using netcat    ${virshid1}    ${virshid2}    ${ip_list1[0]}    ${ip_list2[0]}    ${conn_id_1}    ${conn_id_2}
    ...    10000    Hello
    @{araay17}    Create List    goto_table:40    ${metadata1}
    @{araay40}    Create List    actions=ct(${Tables[3]}    ${ip_list1[0]}    ${ip_list1[1]}    ${linkaddr1}
    @{araay41}    Create List    actions=resubmit(,17)    +new+trk    +est
    @{araay220}    Create List    goto_table:251
    @{araay251}    Create List    ${Tables[10]}    ${ip_list2[0]}    ${ip_list2[1]}    ${linkaddr2}
    @{araay252}    Create List    resubmit(,220)    ipv6    ct_state=+new+trk    +est
    @{arraylist}    Create List    ${araay17}    ${araay40}    ${araay41}    ${araay220}    ${araay251}
    ...    ${araay252}
    @{tablelist}    Create List    ${Tables[1]}|grep ${metadata1}    ${Tables[2]}| grep -i ${mac1}    ${Tables[3]}    ${Tables[8]}    ${Tables[9]}| grep -i ${mac2}
    ...    ${Tables[10]}| grep ${metadata2}
    : FOR    ${table}    IN    @{tablelist}
    \    Table Check    ${conn_id_1}    ${Br_Name}    ${table}    ${arraylist[index]}
    \    ${index}    Evaluate    ${index}+1
    Delete Vm Instance    ${VM_list[0]}
    Delete Vm Instance    ${VM_list[1]}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_list[0]}    ${mac1}    ${conn_id_1}
    ...    ${br_name}
    Wait Until Keyword Succeeds    30 sec    10 sec    Verify Vm Deletion    ${VM_list[1]}    ${mac2}    ${conn_id_1}
    ...    ${br_name}

7.6.30_Validate ipv6 security group rule with remote SG, ether-type= IPv6 and port option in different compute nodes
    [Documentation]    Validate ipv6 security group rule with remote SG, ether-type= IPv6 \ and port option in different compute nodes
    ${command}    Set Variable    neutron security-group-rule-list | grep ${SG_Name[0]} | awk '{print $2}'
    ${SG_rulelist}    Write Commands Until Expected Prompt    ${command}    $    60
    ${SGlist}    Split To Lines    ${SG_rulelist}
    ${SGlist}    Get Slice From List    ${SGlist}    \    -1
    : FOR    ${rule}    IN    @{SGlist}
    \    ${output}    Write Commands Until Expected Prompt    neutron security-group-rule-delete ${rule}    $    60
    ${sgid}    Get Security Group Id    ${SG_name[0]}    ${Networks[0]}
    Create SG Rule IPV6    ${Direction[0]}    ${Rule_List[1]}    2001    2010    IPV6    ${SG_name[0]}
    ...    ${sgid}    SG
    Create SG Rule IPV6    ${Direction[1]}    ${Rule_List[1]}    2001    2010    IPV6    ${SG_name[0]}
    ...    ${sgid}    SG
    Switch Connection    ${conn_id_1}
    Neutron Security Group Create    ${SG_name[1]}
    ${sgid_1}    Get Security Group Id    ${SG_name[1]}    ${Networks[0]}
    Create SG Rule IPV6    ${Direction[0]}    ${Rule_List[1]}    3001    3010    IPV6    ${SG_name[1]}
    ...    ${sgid_1}    SG
    Create SG Rule IPV6    ${Direction[1]}    ${Rule_List[1]}    3001    3010    IPV6    ${SG_name[1]}
    ...    ${sgid_1}    SG
    Neutron Security Group Create    ${SG_Name[2]}
    Create SG Rule IPV6    ${Direction[0]}    ${Rule_List[0]}    3001    3010    IPV6    ${SG_name[2]}
    ...    ${SG_name[0]}
    Create SG Rule IPV6    ${Direction[1]}    ${Rule_List[0]}    3001    3010    IPV6    ${SG_name[2]}
    ...    ${SG_name[0]}
    Create SG Rule IPV6    ${Direction[0]}    ${Rule_List[1]}    3001    3010    IPV6    ${SG_name[2]}
    ...    ${SG_name[0]}
    Create SG Rule IPV6    ${Direction[1]}    ${Rule_List[1]}    3001    3010    IPV6    ${SG_name[2]}
    ...    ${SG_name[0]}
    Create SG Rule IPV6    ${Direction[0]}    ${Rule_List[2]}    3001    3010    IPV6    ${SG_name[2]}
    ...    ${SG_name[0]}
    Create SG Rule IPV6    ${Direction[1]}    ${Rule_List[2]}    3001    3010    IPV6    ${SG_name[2]}
    ...    ${SG_name[0]}
    Neutron Security Group Create    ${SG_Name[3]}
    Create SG Rule IPV6    ${Direction[0]}    ${Rule_List[2]}    3001    3010    IPV6    ${SG_name[3]}
    ...    ${SG_name[1]}
    Create SG Rule IPV6    ${Direction[1]}    ${Rule_List[2]}    3001    3010    IPV6    ${SG_name[3]}
    ...    ${SG_name[1]}
    Create SG Rule IPV6    ${Direction[2]}    ${Rule_List[2]}    ${Rule_List[3]}    ${Rule_List[4]}    ${Rule_List[5]}    ${SG_Name[3]}
    ...    ${SG_Name[1]}
    ${command}    Set Variable    neutron port-update --no-security-groups ${port_id3}
    ${output}    Write Commands Until Expected Prompt    ${command}    $    60
    ${command}    Set Variable    neutron port-update --security-group ${SG_Name[1]} ${port_id3}
    ${output}    Write Commands Until Expected Prompt    ${command}    $    60
    ${command}    Set Variable    neutron port-update --no-security-groups ${port_id4}
    ${output}    Write Commands Until Expected Prompt    ${command}    $    60
    ${command}    Set Variable    neutron port-update --security-group ${SG_Name[1]} ${port_id4}
    ${output}    Write Commands Until Expected Prompt    ${command}    $    60
    Spawn Vm    ${Networks[0]}    ${VM_List[0]}    ${image[0]}    ${hostname1}    ${flavour_list[1]}    --security-groups ${SG_name[1]}
    Spawn Vm    ${Networks[0]}    ${VM_List[1]}    ${image[0]}    ${hostname1}    ${flavour_list[1]}    --security-groups ${SG_name[1]}
    Wait Until Keyword Succeeds    30 sec    10 sec    verify vm creation    ${VM_List[0]}
    ${virshid1}    Get Vm Instance    ${VM_List[0]}
    ${ip_list1}    Wait Until Keyword Succeeds    50 sec    10 sec    Get VM Ip Addresses From Instance Details    ${VM_List[0]}    ${Networks[0]}
    ${ip_list1[0]}    Get From List    ${ip_list1}    0
    ${ip_list1[1]}    Get From List    ${ip_list1}    1
    ${output1}    Virsh Output    ${virshid1}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}
    ...    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)    $
    ${linkaddr1}    Extract Linklocal Addr    ${output1}
    ${prefixstr1} =    Remove String    ${Prefixes[0]}    ::
    ${prefixstr2} =    Remove String    ${Prefixes[1]}    ::
    Should Contain    ${output1}    ${prefixstr1}
    Should Contain    ${output1}    ${prefixstr2}
    Should Contain    ${output1}    ${ip_list1[0]}
    Should Contain    ${output1}    ${ip_list1[1]}
    ${mac1}    Extract_Mac_From_Ifconfig    ${output1}
    ${port_id1}    Get Port Id of instance    ${mac1}    ${conn_id_1}
    ${port1}    Get In Port Number For VM    ${br_name1}    ${port_id1}
    Set Global Variable    ${mac1}
    Set Global Variable    ${port1}
    Wait Until Keyword Succeeds    30 sec    10 sec    verify vm creation    ${VM_List[1]}
    ${virshid2}    Get Vm Instance    ${VM_List[1]}
    ${ip_list2}    Wait Until Keyword Succeeds    50 sec    10 sec    Get VM Ip Addresses From Instance Details    ${VM_List[1]}    ${Networks[0]}
    ${ip_list2[0]}    Get From List    ${ip_list2}    0
    ${ip_list2[1]}    Get From List    ${ip_list2}    1
    ${output2}    Virsh Output    ${virshid2}    ifconfig eth0    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}
    ...    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    cirros    cubswin:)    $
    ${linkaddr2}    Extract Linklocal Addr    ${output2}
    ${prefixstr1} =    Remove String    ${Prefixes[0]}    ::
    ${prefixstr2} =    Remove String    ${Prefixes[1]}    ::
    Should Contain    ${output2}    ${prefixstr1}
    Should Contain    ${output2}    ${prefixstr2}
    Should Contain    ${output2}    ${ip_list2[0]}
    Should Contain    ${output2}    ${ip_list2[1]}
    ${mac2}    Extract_Mac_From_Ifconfig    ${output2}
    ${port_id2}    Get Port Id of instance    ${mac2}    ${conn_id_1}
    ${port2}    Get In Port Number For VM    ${br_name}    ${port_id2}
    Fetch Topology Details    ${conn_id_1}    ${conn_id_2}    ${VM_list[0]}    ${VM_list[1]}    ${VM_list[4]}
    ping from virsh console    ${virshid3}    ${ip_list4[0]}    ${conn_id_1}    , 0% packet loss
    ping from virsh console    ${virshid1}    ${ip_list2[0]}    ${conn_id_1}    , 0% packet loss
    [Teardown]

*** Keywords ***
Create Topology
    [Documentation]    Creating the Topology
    Create ITM Tunnel
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
    Spawn Vm    ${Networks[0]}    ${VM_list[0]}    ${image[0]}    ${hostname1}    ${flavour_list[1]}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    Spawn Vm    ${Networks[0]}    ${VM_list[1]}    ${image[0]}    ${hostname1}    ${flavour_list[1]}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
    Spawn Vm    ${Networks[0]}    ${VM_list[4]}    ${image[0]}    ${hostname2}    ${flavour_list[1]}
    ${flowdump}    Execute Command    sudo ovs-ofctl -OOpenFlow13 dump-flows ${br_name}
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
    ${port1}    Get In Port Number For VM    ${br_name}    ${port_id1}
    Set Global Variable    ${mac1}
    Set Global Variable    ${port1}
    ${mac2}    Extract_Mac_From_Ifconfig    ${output2}
    ${port_id2}    Get Port Id of instance    ${mac2}    ${conn_id_1}
    ${port2}    Get In Port Number For VM    ${br_name}    ${port_id2}
    Set Global Variable    ${mac2}
    Set Global Variable    ${port2}
    ${virshid5}    Get Vm Instance    ${VM_list[4]}
    Set Global Variable    ${virshid5}
    ${ip_list5}    Wait Until Keyword Succeeds    2 min    10 sec    Get VM Ip Addresses From Instance Details    ${VM_list[4]}    ${Networks[0]}
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
    ${port5}    Get In Port Number For VM    ${br_name}    ${port_id5}
    Set Global Variable    ${mac5}
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

Get Ipv6 Address For New Network
    [Arguments]    ${vm_name}    ${ipv6_existing}    ${network1}    ${prefix1}    ${prefix2}
    Wait Until Keyword Succeeds    1 min    10 sec    check ips on nova show    ${vm_name}    ${network1}    ${prefix1}
    ...    ${prefix2}
    ${ip1_temp}=    Write Commands Until Expected Prompt    nova show ${vm_name} | grep ${network1} | awk '{print$5}'    $    30
    ${templ1}    Split To Lines    ${ip1_temp}
    ${str1}=    Get From List    ${templ1}    0
    ${str1}=    Remove String    ${str1}    ,
    ${ip1}=    Strip String    ${str1}
    ${ip2_temp}    Write Commands Until Expected Prompt    nova show ${vm_name} | grep ${network1} | awk '{print$6}'    $    30
    ${templ2}    Split To Lines    ${ip2_temp}
    ${str2}=    Get From List    ${templ2}    0
    ${ip2}=    Strip String    ${str2}
    ${ipv6_new}    Set Variable If    '${ip1}'=='${ipv6_existing}'    ${ip2}    ${ip1}
    [Return]    ${ipv6_new}

Delete Topology
    [Documentation]    Cleaning up the setup.
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

Check Ip Address In Ifconfig Output
    [Arguments]    ${virshid}    ${cmd}    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    ...    ${DEVSTACK_DEPLOY_PATH}    ${username}    ${pwd}    ${vmprompt}
    ${output}    Wait Until Keyword Succeeds    300 sec    20 sec    Virsh Output    ${virshid}    ifconfig eth0
    ...    ${TOOLS_SYSTEM_1_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}    ${username}
    ...    ${pwd}    ${vmprompt}
    [Return]    ${output}

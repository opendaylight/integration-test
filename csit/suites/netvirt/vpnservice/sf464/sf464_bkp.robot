*** Settings ***
Documentation     Test suite for ECMP when VM are non-collocated
Suite Setup       Start Suite
Suite Teardown    End Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
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

Resource          ../../variables/SF263/SF263_Variables.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/OpenStackOperations.robot
Resource          ../../libraries/BgpOperations.robot
Resource          ../../libraries/SwitchOperations.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/MultiPathKeywords.robot
Resource          ../../libraries/SetupUtils.robot
Resource          ../../libraries/GBP/OpenFlowUtils.robot
Library           DebugLibrary
Library           RequestsLibrary

*** Variables ***
${SUBNET_CIDR}    10.10.1.0/24
@{L3_GRE_PORT_NAME}    test_tap_l3gre_1    test_tap_l3gre_2    test_tap_l3gre_3
${PACKET_CAPTURE_FILE_NAME}    Compute_packet
@{Networks}       mynet1    mynet2
@{Subnets}        ipv6s1    ipv6s2    ipv6s3    ipv6s4
@{VM_list}        vm1    vm2    vm3    vm4    vm5    vm6    vm7
@{Routers}        router1    router2
@{Prefixes}       2001:db8:1234::    2001:db8:5678::    2001:db8:4321::    2001:db8:6789::
@{V4subnets}      13.0.0.0    14.0.0.0
@{V4subnet_names}    subnet1v4    subnet2v4
@{login_credentials}    stack    stack    root    password
@{SG_name}        SG1    SG2    SG3    SG4    default    SGCUSTOM
@{rule_list}      tcp    udp    icmpv6    10000    10500    IPV6    # protocol1, protocol2, protocol3, port_min, port_max, ether_type
@{direction}      ingress    egress    both
@{Image_Name}     cirros-0.3.4-x86_64-uec    ubuntu-sg
@{protocols}      tcp6    udp6    icmp6
@{remote_group}    SG1    prefix    any
@{remote_prefix}    ::0/0    2001:db8:1234::/64    2001:db8:4321::/64
@{logical_addr}    2001:db8:1234:0:1111:2343:3333:4444    2001:db8:1234:0:1111:2343:3333:5555
@{flavour_list}    m1.nano    myhuge
@{itm_created}    TZA
${br_name}        br-int
${netvirt_config_dir}    ${CURDIR}/../../../variables/netvirt
${Bridge-1}       br0
${Bridge-2}       br0
${genius_config_dir}    ${CURDIR}/../../../variables/genius
@{dpip}           192.168.113.10    192.168.113.11
${Interface-1}    eth1
${Interface-2}    eth1
@{flavour_list}    m1.nano    myhuge
@{Tables}         table=0    table=17    table=211    table=214    table=45    table=50    table=51
...               table=60    table=220    table=241    table=244
${invalid_Subnet_Value}    2001:db8:1234::/21
${genius_config_dir}    ${CURDIR}/../../../variables/genius
@{port_list}    port01    port02    port03    port04    port05    port06    port07    portnew03    portnew06    portnew04


*** Testcases ***
TC_01 Verify Traffic from DC-GW is successfully sent to both CSSs  
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on both CSSs hosting ECMP VMs
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Verify multipath is enabled in SER
    ${output}    Execute Command In ASR    ${DCGW_IP}    show bgp vrf ${VPN_NAMES[1]} ${ALLOWED_IP[0]}
    Should Match Regexp    ${output}    multipath
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    Log    Get the table20 Packet count before traffic is sprayed
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on both compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on both compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    Evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

    Log    Adding Ipv6 VMs onto the existing ipv4 vms.
    [Documentation]    Validate ping6 between VMs in different compute
    Switch Connection    ${conn_id_1}
    #Spawn Vm    ${Networks[1]}    ${VM_list[3]}    ${image_name[0]}    ${hostname2}    ${flavour_list[1]}
    Create Neutron Port With Additional Params    ${Networks[1]}    ${port_list[3]}    --security-group ${SG_name[5]}
    Create Vm Instance With Port On Compute Node    ${port_list[3]}    ${VM_list[3]}    ${TOOLS_SYSTEM_2_IP}    ${image_name[0]}    ${flavour_list[1]}

    ${virshid4}    IPV6_Service.Get Vm Instance    ${VM_list[3]}
    Set Global Variable    ${virshid4}
    ${prefixstr1}    Remove String    ${Prefixes[2]}    ::
    ${v4prefix}    Get Substring    ${V4subnets[0]}    \    -1
    ${ip_list4}    Wait Until Keyword Succeeds    50 sec    10 sec    Get Ip List Specific To Prefixes    ${VM_list[3]}    ${Networks[1]}
    ...    ${prefixstr1}    ${v4prefix}
    Set Global Variable    ${ip_list4}
    sleep    180
    Switch Connection    ${conn_id_2}
    ${output4}    Virsh Output    ${virshid4}    ifconfig eth0    ${TOOLS_SYSTEM_2_IP}    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}
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
    LOG  Verify the bfd neighborship and failover detection of dcgw.
     





TC_02 Verify Traffic when ECMP VM is deleted
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on CSS hosting ECMP VM ,when the other CSS ECMP candidate VMs are deleted.
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    Log    Start Packet Capture on compute node 1
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    Start Packet Capture On Compute Node    ${OS_COMPUTE_1_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[0]}    ${L3_GRE_PORT_NAME[0]}    ${ALLOWED_IP[0]}    ${MASK[0]}
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[3]}
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[2]}
    sleep    30
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    Stop Packet Capture on compute node 1
    Stop Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    Should be Equal As Integers    ${Packet_Count_Node_1}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Actual_Packet_Count}    Evaluate    ${Packet_Count_After_Traffic_1}-${Packet_Count_Before_Traffic_1}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}
    Log    Recreate the deleted VMs
    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_LIST[2]}    ${OS_COMPUTE_2_IP}    ${image}
    ...    ${flavor}    ${SGP}
    Set To Dictionary    ${VmIpDict}    ${VM_LIST[2]}=${VM_IP}
    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_LIST[3]}    ${OS_COMPUTE_2_IP}    ${image}
    ...    ${flavor}    ${SGP}
    Set To Dictionary    ${VmIpDict}    ${VM_LIST[3]}=${VM_IP}
    @{VM_LIST_1}    Create List    ${VM_LIST[0]}    ${VM_LIST[1]}    ${VM_LIST[2]}    ${VM_LIST[3]}
    Configure Next Hop on Router    ${ROUTER_NAME}    ${NO_OF_STATIC_IP}    ${VM_LIST_1}    ${ALLOWED_IP[0]}
    Log    Configure IP on Sub Interface and Verify the IP
    : FOR    ${VM_NAME}    IN    @{VM_LIST_1}
    \    Configure Ip on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}    ${MASK[1]}
    \    Wait Until Keyword Succeeds    30s    5s    Verify Ip Configured on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on both compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    Evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_03 Verify Traffic when ECMP VM is stopped
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on CSS hosting ECMP VM ,when the other CSS ECMP candidate VMs are stopped.
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on both compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Wait Until Keyword Succeeds    20s    2s    Stop Vm Instance    ${VM_LIST[3]}
    Wait Until Keyword Succeeds    20s    2s    Stop Vm Instance    ${VM_LIST[2]}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[2]}}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[3]}}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on both compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}
    Log    Start Packet Capture on both compute nodes after stop/start of VMs
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    : FOR    ${Index}    IN RANGE    2    4
    \    Wait Until Keyword Succeeds    20s    2s    Start VM Instance    ${VM_LIST[${Index}]}
    \    Sleep    30
    \    Configure Ip on Sub Interface    ${ALLOWED_IP[0]}    ${VM_LIST[${Index}]}    ${MASK[1]}
    \    Wait Until Keyword Succeeds    30s    5s    Verify Ip Configured on Sub Interface    ${ALLOWED_IP[0]}    ${VM_LIST[${Index}]}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[2]}}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[3]}}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on both compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Second_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Second_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Second_Traffic}    Evaluate    ${Packet_Count_After_Second_Traffic_1}+${Packet_Count_After_Second_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Second_Traffic}-${Total_Packet_Count_After_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_04 Verify Traffic when ECMP VM is rebooted
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on both CSSs when the ECMP candidate VM are rebooted on CSS2
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on both compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Wait Until Keyword Succeeds    20s    2s    Reboot NOVA VM    ${VM_LIST[3]}
    Wait Until Keyword Succeeds    20s    2s    Reboot NOVA VM    ${VM_LIST[2]}
    sleep    20
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[2]}}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[3]}}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Stop Packet Capture on both compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_05 Verify Traffic when ECMP VMs are added
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on both CSSs when the additional VMs are added on both Computes
    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[4]}    ${VM_LIST[4]}    ${OS_COMPUTE_1_IP}    ${image}
    ...    ${flavor}    ${SGP}
    Set To Dictionary    ${VmIpDict}    ${VM_LIST[4]}=${VM_IP}
    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[5]}    ${VM_LIST[5]}    ${OS_COMPUTE_2_IP}    ${image}
    ...    ${flavor}    ${SGP}
    Set To Dictionary    ${VmIpDict}    ${VM_LIST[5]}=${VM_IP}
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on both compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[4]}}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[5]}}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Stop Packet Capture on both compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_06 Verify Traffic from DC-GW is successfully sprayed on 3 CSS
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on 3 CSSs hosting ECMP VMs
    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[6]}    ${VM_LIST[6]}    ${OS_COMPUTE_3_IP}    ${image}
    ...    ${flavor}    ${SGP}
    Set To Dictionary    ${VmIpDict}    ${VM_LIST[6]}=${VM_IP}
    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[7]}    ${VM_LIST[7]}    ${OS_COMPUTE_3_IP}    ${image}
    ...    ${flavor}    ${SGP}
    Set To Dictionary    ${VmIpDict}    ${VM_LIST[7]}=${VM_IP}
    @{VM_LIST_1}    Create List    ${VM_LIST[0]}    ${VM_LIST[1]}    ${VM_LIST[2]}    ${VM_LIST[3]}    ${VM_LIST[6]}
    ...    ${VM_LIST[7]}
    Configure Next Hop on Router    ${ROUTER_NAME}    ${NO_OF_STATIC_IP}    ${VM_LIST_1}    ${ALLOWED_IP[0]}
    Log    Configure IP on Sub Interface and Verify the IP
    : FOR    ${VM_NAME}    IN    @{VM_LIST_1}
    \    Configure Ip on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}    ${MASK[1]}
    \    Wait Until Keyword Succeeds    30s    5s    Verify Ip Configured on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    : FOR    ${Index}    IN RANGE    3
    \    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[${Index}]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[4]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[4]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_3}    Verify flows in Compute Node    ${OS_COMPUTE_3_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[4]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_3}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_3}    Get table20 Packet Count    ${OS_COMPUTE_3_IP}    ${GROUP_ID_3}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}+${Packet_Count_Before_Traffic_3}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    3
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    4
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_3}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_3_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}+${Packet_Count_Node_3}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Packet_Count_After_Traffic_3}    Get table20 Packet Count    ${OS_COMPUTE_3_IP}    ${GROUP_ID_3}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}+${Packet_Count_After_Traffic_3}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_07 Verify Traffic from DC-GW is successfully sprayed when 3 CSS is deleted
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on 2 CSSs when the 3rd CSS is deleted(ECMP VM's are deleted on this CSS)
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[6]}
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[7]}
    sleep    10
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    : FOR    ${Index}    IN RANGE    2
    \    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[${Index}]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_08 Verify Traffic from DC-GW wrt switch stop/start
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed in below scenario - stop CSS2 and start CSS 2 (08 and 09)
    @{VM_LIST_1}    Create List    ${VM_LIST[0]}    ${VM_LIST[1]}    ${VM_LIST[2]}    ${VM_LIST[3]}
    Configure Next Hop on Router    ${ROUTER_NAME}    ${NO_OF_STATIC_IP}    ${VM_LIST_1}    ${ALLOWED_IP[0]}
    Log    Configure IP on Sub Interface and Verify the IP
    : FOR    ${VM_NAME}    IN    @{VM_LIST_1}
    \    Configure Ip on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}    ${MASK[1]}
    \    Wait Until Keyword Succeeds    30s    5s    Verify Ip Configured on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    : FOR    ${Index}    IN RANGE    2
    \    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[${Index}]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Stop CSS 2
    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo service openvswitch-switch stop
    # Wait For Flows On Switch    ${OS_COMPUTE_2_IP}
    Sleep    5
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    #    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Packet_Count_After_Traffic_1}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start CSS 2
    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo service openvswitch-switch start
    Wait For Flows On Switch    ${OS_COMPUTE_2_IP}
    sleep    5
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}

TC_09 Verify Traffic from DC-GW when CSS in standalone mode
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed when both CSS is in standalone mode.
    Log    Configuring Compute Node in Standalone Mode
    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-vsctl set-fail-mode br-int standalone
    Utils.Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-vsctl set-fail-mode br-int standalone
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    Log    Restart the controller and verify flows
    Wait Until Keyword Succeeds    50s    10s    Issue Command On Karaf Console    shutdown -f
    sleep    20
    Log    Verify that flows are removed from Switch
    : FOR    ${index}    IN RANGE    1    3
    \    ${OvsFlow}    Utils.Run Command On Remote System    ${OS_COMPUTE_${index}_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep table
    \    Run Keyword If    "${OvsFlow}" != "${EMPTY}"    FAIL
    Log    Start Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should Not be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    Log    Verify that the Controller is operational after Reboot
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${karafpath}/start    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${Karafinfo}    Run Command On Remote System    ${ODL_SYSTEM_IP}    ps -eaf | grep karaf    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${match}    Should Match Regexp    ${Karafinfo}    \\d+.*bin/java
    Sleep    30
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Log    ${CTRL_FIB}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}
    Log    Removing Standalone Mode
    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-vsctl del-fail-mode br-int
    Utils.Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-vsctl del-fail-mode br-int

TC_10 Verify Traffic from DC-GW when CSS in secure mode
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed when both CSS is in secure mode.
    Log    Configuring Compute Node in Secure Mode
    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-vsctl set-fail-mode br-int secure
    Utils.Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-vsctl set-fail-mode br-int secure
    Log    Restart the controller and verify flows
    Wait Until Keyword Succeeds    50s    10s    Issue Command On Karaf Console    shutdown -f
    sleep    20
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
	${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}
    Log    Verify that the Controller is operational after Reboot
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${karafpath}/start    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${Karafinfo}    Run Command On Remote System    ${ODL_SYSTEM_IP}    ps -eaf | grep karaf    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${match}    Should Match Regexp    ${Karafinfo}    \\d+.*bin/java
    Sleep    30
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Log    ${CTRL_FIB}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}
    Log    Removing Secure Mode
    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-vsctl del-fail-mode br-int
    Utils.Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-vsctl del-fail-mode br-int

TC_11 Verify Traffic during Controller restart (Non-CoLocated VMs)
    [Documentation]    VM are Non-collocated - Controller and CSS connectivity disconnected
    ...    VM deleted, Traffic impacted as controller is not up, Bring up controller,ECMP reconfigured by CSC and traffic resumed without drop
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    Log    Restart the controller and verify flows
    Wait Until Keyword Succeeds    50s    10s    Issue Command On Karaf Console    shutdown -f
    sleep    20
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[2]}
    sleep    30
    Comment    Log    Verify that flows are removed from Switch
    Comment    : FOR    ${index}    IN RANGE    1    3
    Comment    \    ${OvsFlow}    Utils.Run Command On Remote System    ${OS_COMPUTE_${index}_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep table
    Comment    \    Run Keyword If    "${OvsFlow}" != "${EMPTY}"    FAIL
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should Not be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    Log    Verify that the Controller is operational after Reboot
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${karafpath}/start    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${Karafinfo}    Run Command On Remote System    ${ODL_SYSTEM_IP}    ps -eaf | grep karaf    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${match}    Should Match Regexp    ${Karafinfo}    \\d+.*bin/java
    Sleep    30
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Log    ${CTRL_FIB}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_12 Verify Traffic during Controller restart (CoLocated VMs)
    [Documentation]    VM are collocated - Controller and CSS connectivity disconnected
    ...    VM deleted, Traffic impacted as controller is not up, Bring up controller,ECMP reconfigured by CSC and traffic resumed without drop
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    Log    Restart the controller and verify flows
    Wait Until Keyword Succeeds    50s    10s    Issue Command On Karaf Console    shutdown -f
    sleep    20
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[2]}
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[3]}
    sleep    30
    Comment    Log    Verify that flows are removed from Switch
    Comment    : FOR    ${index}    IN RANGE    1    3
    Comment    \    ${OvsFlow}    Utils.Run Command On Remote System    ${OS_COMPUTE_${index}_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep table
    Comment    \    Run Keyword If    "${OvsFlow}" != "${EMPTY}"    FAIL
    :FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    :FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should Not be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    Log    Verify that the Controller is operational after Reboot
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${karafpath}/start    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${Karafinfo}    Run Command On Remote System    ${ODL_SYSTEM_IP}    ps -eaf | grep karaf    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${match}    Should Match Regexp    ${Karafinfo}    \\d+.*bin/java
    Sleep    30
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Log    ${CTRL_FIB}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    :FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    :FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

*** Keywords ***
Start Suite
    [Documentation]    Run at start of the suite
    DevstackUtils.Devstack Suite Setup
    Create Setup

End Suite
    [Documentation]    Run at end of the suite
    Delete Setup
    Close All Connections

Create Setup
    [Documentation]    Create networks,subnets,ports and VMs,tep ports
    Log    Adding TEP ports
    Tep Port Operations    ${OPERATION[0]}    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}    ${OS_COMPUTE_3_IP}
    ${TepShow}    Issue Command On Karaf Console    ${TEP_SHOW}
    ${TunnelCount}    Get Regexp Matches    ${TepShow}    TZA\\s+VXLAN
    Length Should Be    ${TunnelCount}    ${3}
    Wait Until Keyword Succeeds    200s    20s    Verify Tunnel Status as UP
    Log    Configure BGP in controller
    Issue Command On Karaf Console    bgp-connect -h ${ODL_BGP_IP} -p 7644 add
    Issue Command On Karaf Console    bgp-rtr -r ${ODL_BGP_IP} -a ${AS_ID} add
    Issue Command On Karaf Console    bgp-nbr -a ${AS_ID} -i ${DCGW_IP} add
    Issue Command On Karaf Console    bgp-cache
    Utils.Post Elements To URI    ${AddGreUrl}    ${DCGW1_TUNNEL_CONFIG}
    Comment    "Creating customised security Group"
    ${OUTPUT}    ${SGP_ID}    OpenStackOperations.Neutron Security Group Create    ${SGP}
    Comment    "Creating the rules for ingress direction"
    ${OUTPUT1}    ${RULE_ID1}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=ingress    protocol=icmp
    ${OUTPUT2}    ${RULE_ID2}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=ingress    protocol=tcp
    ${OUTPUT3}    ${RULE_ID3}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=ingress    protocol=udp
    Comment    "Creating the rules for egress direction"
    ${OUTPUT4}    ${RULE_ID4}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=egress    protocol=icmp
    ${OUTPUT5}    ${RULE_ID5}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=egress    protocol=tcp
    ${OUTPUT6}    ${RULE_ID6}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=egress    protocol=udp
    Comment    "Create Neutron Network , Subnet and Ports"
    Wait Until Keyword Succeeds    30s    5s    Create Network    ${NETWORK_NAME}
    Wait Until Keyword Succeeds    30s    5s    Create SubNet    ${NETWORK_NAME}    ${SUBNET_NAME}    ${SUBNET_CIDR}
    #...    --enable-dhcp
    : FOR    ${PortName}    IN    @{PORT_LIST}
    \    MultiPathKeywords.Create Port    ${NETWORK_NAME}    ${PortName}    ${SGP}    ${ALLOWED_IP}
    &{VmIpDict}    Create Dictionary
    Set Global Variable    ${VmIpDict}
    Log To Console    "Creating VM's on Compute Node 1 and 2"
    : FOR    ${Index}    IN    0    1
    \    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${Index}]}    ${VM_LIST[${Index}]}    ${OS_COMPUTE_1_IP}
    \    ...    ${image}    ${flavor}    ${SGP}
    \    Set To Dictionary    ${VmIpDict}    ${VM_LIST[${Index}]}=${VM_IP}
    : FOR    ${Index}    IN    2    3
    \    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${Index}]}    ${VM_LIST[${Index}]}    ${OS_COMPUTE_2_IP}
    \    ...    ${image}    ${flavor}    ${SGP}
    \    Set To Dictionary    ${VmIpDict}    ${VM_LIST[${Index}]}=${VM_IP}
    Log    ${VmIpDict}
    Create Router    ${ROUTER_NAME}
    ${Additional_Args}    Set Variable    -- --route-distinguishers list=true 100:1 100:2 100:3 --route-targets 100:1 100:2 100:3
    ${vpnid}    Create Bgpvpn    ${VPN_NAMES[0]}    ${Additional_Args}
    Add Router Interface    ${ROUTER_NAME}    ${SUBNET_NAME}
    Bgpvpn Router Associate    ${ROUTER_NAME}    ${VPN_NAMES[0]}
    Sleep    30
    Log    Verify the VM route in fib
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    ${Temp_list}    Get Dictionary Values    ${VmIpDict}
    : FOR    ${VmIp}    IN    @{Temp_list}
    \    Should Contain    ${CTRL_FIB}    ${VmIp}
    @{VM_LIST_1}    Create List    ${VM_LIST[0]}    ${VM_LIST[1]}    ${VM_LIST[2]}    ${VM_LIST[3]}
    Configure Next Hop on Router    ${ROUTER_NAME}    ${NO_OF_STATIC_IP}    ${VM_LIST_1}    ${ALLOWED_IP[0]}
    Log    Configure IP on Sub Interface and Verify the IP
    : FOR    ${VM_NAME}    IN    @{VM_LIST_1}
    \    Configure Ip on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}    ${MASK[1]}
    \    Wait Until Keyword Succeeds    30s    5s    Verify Ip Configured on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}

Delete Setup
    [Documentation]    Clean the config created for ECMP TCs
    Log    Deleting all VMs and Ports
    : FOR    ${PortName}    ${VmName}    IN ZIP    ${PORT_LIST}    ${VM_LIST}
    \    Delete Vm Instance    ${VmName}
    \    Delete Port    ${PortName}
    ${VMs}    List VMs
    ${Ports}    List Ports
    : FOR    ${PortName}    ${VmName}    IN ZIP    ${PORT_LIST}    ${VM_LIST}
    \    Should Not Contain    ${VMs}    ${VmName}
    \    Should Not Contain    ${Ports}    ${PortName}
    Update Router    ${ROUTER_NAME}    --no-routes
    Remove Interface    ${ROUTER_NAME}    ${SUBNET_NAME}
    Delete Router    ${ROUTER_NAME}
    Delete Bgpvpn    ${VPN_NAMES[0]}
    Delete SubNet    ${SUBNET_NAME}
    Delete Network    ${NETWORK_NAME}
    Neutron Security Group Delete    ${SGP}
    Log    Configure BGP in controller
    Issue Command On Karaf Console    bgp-nbr -a ${AS_ID} -i ${DCGW_IP} del
    Issue Command On Karaf Console    bgp-rtr -r ${ODL_BGP_IP} -a ${AS_ID} del
    Issue Command On Karaf Console    bgp-connect -h ${ODL_BGP_IP} -p 7644 del
    Issue Command On Karaf Console    bgp-cache
    Utils.Post Elements To URI    ${DelGreUrl}    ${DCGW1_TUNNEL_CONFIG}
    Log    Deleting TEP ports
    Tep Port Operations    ${OPERATION[1]}    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}    ${OS_COMPUTE_3_IP}

Execute Command In Context Of SER
    [Arguments]    ${SER_IP}    ${ContextName}    ${cmd}    ${SER_UNAME}=redback    ${SER_PWD}=bete123
    [Documentation]    Execute set of command on SER
    ${conn_id}=    Open Connection    localhost
    Login    root    admin123
    Switch Connection    ${conn_id}
    ${output} =    Write    telnet ${SER_IP}
    ${output} =    Read Until    Username:
    ${output} =    Write    ${SER_UNAME}
    ${output} =    Read Until    Password:
    ${output} =    Write    ${SER_PWD}
    ${output} =    Read Until    \#
    ${output} =    Write    ${cmd}
    ${output} =    Read    delay=6s
    Write    exit
    Read Until    \#
    SSHLibrary.Close Connection
    [Return]    ${output}

Execute Command In vASR
    [Arguments]    ${vASR_VM_ID}    ${vASR_IP}    ${cmd}    ${vASR_UNAME}=cisco    ${vASR_PWD}=cisco
    [Documentation]    Execute set of command on vASR
    ${conn_id}    Open Connection    ${vASR_IP}
    Login    root    admin123
    Switch Connection    ${conn_id}
    ${output}    Execute Command On Server    ${vASR_VM_ID}    ${EMPTY}    ${vASR_IP}    ${cmd}    ${vASR_UNAME}
    ...    ${vASR_PWD}
    [Return]    ${output}

Execute Command In SER
    [Arguments]    ${SER_IP}    ${Command}    ${SER_UNAME}=cisco    ${SER_PWD}=cisco
    [Documentation]    Execute single command in configuration mode
    ${conn_id}=    Open Connection    localhost
    Login    root    admin123
    Switch Connection    ${conn_id}
    ${output} =    Write    telnet ${SER_IP}
    ${output} =    Read Until    Username:
    ${output} =    Write    ${SER_UNAME}
    ${output} =    Read Until    Password:
    ${output} =    Write    ${SER_PWD}
    ${output} =    Read Until    \#
    ${output} =    Write    terminal length 0
    ${output} =    Read Until    \#
    ${output} =    Write    ${Command}
    ${output} =    Read    delay=6s
    Write    exit
    Read Until    \#
    SSHLibrary.Close Connection
    Log    ${output}
    [Return]    ${output}

Start Non CBA Controller
    [Arguments]    ${CtrlIp}    ${KarafPath}
    SSHLibrary.Open Connection    ${CtrlIp}
    Set Client Configuration    prompt=#
    SSHLibrary.Login    root    admin123
    Write Commands Until Prompt    cd ${KarafPath}
    Write Commands Until Prompt    ./start
    Sleep    5
    SSHLibrary.Close Connection

Verify Controller Is Operational
    [Arguments]    ${CtrlIp}    ${CBA_PLAT}=False
    ${conn_handle}    Run Keyword If    ${CBA_PLAT}==True    Verify CBA Controller Is Operational    ${CtrlIp}
    ...    ELSE    Verify Non CBA Controller Is Operational    ${CtrlIp}

Verify CBA Controller Is Operational
    [Arguments]    ${NoOfNode}=3
    ${resp}    Issue Command On Karaf Console    showsvcstatus | grep OPERATIONAL | wc -l
    ${regex}    Evaluate    ${NoOfNode}*6
    ${match}    Should Match Regexp    ${resp}    ${regex}

Verify Non CBA Controller Is Operational
    [Arguments]    ${CtrlIp}
    SSHLibrary.Open Connection    ${CtrlIp}
    Set Client Configuration    prompt=#
    SSHLibrary.Login    root    admin123
    ${output} =    Write Commands Until Prompt    ps -ef | grep karaf
    ${match}    Should Match Regexp    ${output}    \\d+.*bin/java
    SSHLibrary.Close Connection

Verify Static Ip Configured In VM
    [Arguments]    ${VmName}    ${DpnIp}    ${StaticIp}
    ${resp}    Execute Command on server    sudo ifconfig eth0:0    ${VmName}    ${VMInstanceDict.${VmName}}    ${DpnIp}
    Should Contain    ${resp}    ${StaticIp}

Verify Tunnel State
    [Arguments]    ${TunnelCount}    ${Regex}
    ${TepState}    Issue Command On Karaf Console    tep:show-state
    ${ActiveTunnelCount}    Get Regexp Matches    ${TepState}    ${Regex}
    Length Should Be    ${ActiveTunnelCount}    ${TunnelCount}

Verify Flow Remove from Switch
    [Arguments]    ${DpnIp}
    ${OvsFlow}    Utils.Run Command On Remote System    ${DpnIp}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep table
    Run keyword if    "${OvsFlow}"    Fail

Start Packet Generation
    [Arguments]    ${Server_IP}    ${ScriptPath}    ${Script}    ${user}=root    ${password}=admin123
    SSHLibrary.Open Connection    ${Server_IP}
    Set Client Configuration    prompt=${ODL_SYSTEM_PROMPT}
    SSHLibrary.Login    ${user}    ${password}
    ${output}    Write Commands Until Prompt    rm -rf /tmp/dump.txt
    ${cmd}    Set Variable    python ${ScriptPath}/${Script} >> /tmp/dump.txt
    ${output}    Write Commands Until Prompt    python ${ScriptPath}/${Script} >> /tmp/dump.txt    60s
    sleep    5
    #    ${stdout}    ${stderr} =    SSHLibrary.Start Command    ${cmd}
    ${output}    Write Commands Until Prompt    sudo cat /tmp/dump.txt
    #    ${output}    SSHLibrary.Execute Command    sudo cat /tmp/dump.txt
    ${match}    ${Packet_Count}    Should Match Regexp    ${output}    Packets sent (\\d+)
    Log    ${Packet_Count}
    Log    ${output}
    Sleep    5
    SSHLibrary.Close Connection
    [Return]    ${Packet_Count}

Start Packet Capture On Compute Node
    [Arguments]    ${node_ip}    ${file_Name}    ${network_Adapter}    ${GRE_PORT_NAME}    ${IP}    ${MASK_VAL}
    ...    ${user}=root    ${password}=admin123    ${prompt}=${ODL_SYSTEM_PROMPT}    ${prompt_timeout}=${DEFAULT_TIMEOUT}
    [Documentation]    Connects to the remote machine and starts tcpdump
    ${current_ssh_connection}=    SSHLibrary.Get Connection
    ${conn_id}=    SSHLibrary.Open Connection    ${node_ip}    prompt=${prompt}    timeout=${prompt_timeout}
    Flexible SSH Login    ${user}    ${password}
    ${cmd_1}    Set Variable    ovs-vsctl add-port br-int ${GRE_PORT_NAME} -- --id=@mirror_from get port ${network_Adapter} -- --id=@mirror_to get port ${GRE_PORT_NAME} -- --id=@m create mirror name=test_mirror_gre select-dst-port=@mirror_from select-src-port=@mirror_from output-port=@mirror_to -- set bridge br-int mirrors=@m -- set interface ${GRE_PORT_NAME} type=internal
    ${output}    Execute Command    ${cmd_1}
    ${cmd_2}    Set Variable    ifconfig ${GRE_PORT_NAME} up
    ${output}    Execute Command    ${cmd_2}
    ${cmd} =    Set Variable    sudo /usr/sbin/tcpdump -vvv -ni ${GRE_PORT_NAME} -O -vv "mpls && dst net ${IP}/${MASK_VAL}" >> /tmp/${file_Name}.pcap
    ${stdout}    ${stderr} =    SSHLibrary.Start Command    ${cmd}
    #    SSHLibrary.Close Connection
    Log    ${stderr}
    Log    ${stdout}
    #    [Return]    ${conn_id}
    [Teardown]    SSHKeywords.Restore_Current_SSH_Connection_From_Index    ${current_ssh_connection.index}

Stop Packet Capture on Compute Node
    [Arguments]    ${node_ip}    ${user}=root    ${password}=admin123    ${prompt}=${ODL_SYSTEM_PROMPT}    ${prompt_timeout}=${DEFAULT_TIMEOUT}
    [Documentation]    This keyword will list the running processes looking for tcpdump and then kill the process with the name tcpdump
    ${conn_id}    Open Connection    ${node_ip}    prompt=${prompt}    timeout=${prompt_timeout}
    Login    ${user}    ${password}
    Switch Connection    ${conn_id}
    ${stdout} =    SSHLibrary.Execute Command    sudo ps -elf | grep tcpdump
    Log    ${stdout}
    ${stdout}    ${stderr} =    SSHLibrary.Execute Command    sudo pkill -f tcpdump    return_stderr=True
    Log    ${stdout}
    ${stdout}    ${stderr} =    SSHLibrary.Execute Command    sudo ls -lart /tmp    return_stderr=True
    Log    ${stdout}
    SSHLibrary. Close Connection

Get The Packet Capture on Compute Node
    [Arguments]    ${Compute_IP}    ${IP}    ${file_name}    ${user}=root    ${password}=admin123    ${prompt}=${ODL_SYSTEM_PROMPT}
    ...    ${prompt_timeout}=${DEFAULT_TIMEOUT}
    [Documentation]    Keyword to return the number of tcpdump packets captured on specified compute node
    ${conn_id}    Open Connection    ${Compute_IP}    prompt=${prompt}    timeout=${prompt_timeout}
    Login    ${user}    ${password}
    Switch Connection    ${conn_id}
    ${output}    SSHLibrary.Execute Command    sudo cat /tmp/${file_name}.pcap
    Should Match Regexp    ${output}    ${IP}
    ${output}    SSHLibrary.Execute Command    grep -w "${IP}" -c /tmp/${file_name}.pcap
    Log    ${output}
    ${stdout} =    SSHLibrary.Execute Command    rm -rf /tmp/*.pcap
    SSHLibrary. Close Connection
    [Return]    ${output}

Verify The Packet Capture
    [Arguments]    ${PACKET_CAPTURE_FILE_NAME}    ${EXPECTED_PACKET_COUNT}    ${IP}    ${OS_COMPUTE_3_IP}=${EMPTY}
    [Documentation]    Keyword to verify the Packets captured on compute node
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${IP}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${IP}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_3}    Run Keyword If    "${OS_COMPUTE_3_IP}" != "${EMPTY}"    Get The Packet Capture on Compute Node    ${OS_COMPUTE_3_IP}    ${IP}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count}    Set Variable If    "${OS_COMPUTE_3_IP}" != "${EMPTY}"    ${Packet_Count_Node_1}+${Packet_Count_Node_2}+${Packet_Count_Node_3}    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${EXPECTED_PACKET_COUNT}

Verify The Packet Count In Flows
    [Arguments]    ${GROUP_ID}    ${EXPECTED_PACKET_COUNT}    ${OS_COMPUTE_3_IP}=${EMPTY}
    [Documentation]    Keyword to verify the packet count in respective flow dumps
    ${Packet_Count_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID}
    ${Packet_Count_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID}
    ${Packet_Count_3}    Run Keyword If    "${OS_COMPUTE_3_IP}" != "${EMPTY}"    Get table20 Packet Count    ${OS_COMPUTE_3_IP}    ${GROUP_ID}
    ${Packet_Count}    Set Variable If    "${OS_COMPUTE_3_IP}" != "${EMPTY}"    ${Packet_Count_1}+${Packet_Count_2}+${Packet_Count_3}    ${Packet_Count_1}+${Packet_Count_2}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${EXPECTED_PACKET_COUNT}

Read Packet Capture on Compute Node
    [Arguments]    ${conn_id}
    [Documentation]    This keyword will list the running processes looking for tcpdump and then kill the process with the name tcpdump
    ${conn_id}    Open Connection    ${conn_id}
    Login    root    admin123
    Switch Connection    ${conn_id}
    ${stdout} =    SSHLibrary.Execute Command    sudo cat /tmp/*.pcap
    Log    ${stdout}
    SSHLibrary. Close Connection
    [Return]    ${stdout}

Count of Packet Captured on Node
    [Arguments]    ${conn_id}
    [Documentation]    This keyword will list the running processes looking for tcpdump and then kill the process with the name tcpdump
    ${conn_id}    Open Connection    ${conn_id}
    Login    root    admin123
    Switch Connection    ${conn_id}
    ${stdout} =    SSHLibrary.Execute Command    grep -w "100.100.100.100" -c /tmp/*.pcap
    Log    ${stdout}
    SSHLibrary. Close Connection
    [Return]    ${stdout}

Get table20 Packet Count
    [Arguments]    ${COMPUTE_IP}    ${GROUP_ID}
    [Documentation]    Get the packet count from table 20 for the specified group id
    ${OVS_FLOW}    Run Command On Remote System    ${COMPUTE_IP}    ${DUMP_FLOWS}
    ${MATCH}    ${PACKET_COUNT}    Should Match Regexp    ${OVS_FLOW}    table=20.*n_packets=(\\d+).*group:${GROUP_ID}.*
    Log    ${PACKET_COUNT}
    [Return]    ${PACKET_COUNT}

Get_GRE_Port_Name
    [Arguments]    ${session}=session
    [Documentation]    Get the Port Names of the GRE tunnel
    ${resp}    RequestsLibrary.Get Request    ${session}    ${GrePortList}
    Log    ${resp.content}
    Should be equal as strings    ${resp.status_code}    200
    ${match}    get regexp matches    ${resp.content}    "tun[a-z0-9]+"
    ${GRE_PORT_NAME_LIST}    Create List
    : FOR    ${val}    IN    @{match}
    \    ${port_name}    split string    ${val}    "
    \    Append TO List    ${GRE_PORT_NAME_LIST}    ${port_name[1]}
    \    log    ${port_name}
    [Return]    ${GRE_PORT_NAME_LIST}
*** Settings ***
Documentation     Test suite for ECMP when VM are non-collocated
Suite Setup       Start Suite
Suite Teardown    End Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Resource          ../../variables/SF263/SF263_Variables.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/OpenStackOperations.robot
Resource          ../../libraries/BgpOperations.robot
Resource          ../../libraries/SwitchOperations.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/MultiPathKeywords.robot
Resource          ../../libraries/SetupUtils.robot
Resource          ../../libraries/GBP/OpenFlowUtils.robot
Library           DebugLibrary
Library           RequestsLibrary

*** Variables ***
${SUBNET_CIDR}    10.10.1.0/24
@{L3_GRE_PORT_NAME}    test_tap_l3gre_1    test_tap_l3gre_2    test_tap_l3gre_3
${PACKET_CAPTURE_FILE_NAME}    Compute_packet

*** Testcases ***
TC_01 Verify Traffic from DC-GW is successfully sprayed on both CSSs
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on both CSSs hosting ECMP VMs
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Verify multipath is enabled in SER
    ${output}    Execute Command In SER    ${DCGW_IP}    show bgp vrf ${VPN_NAMES[1]} ${ALLOWED_IP[0]}
    Should Match Regexp    ${output}    multipath
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    Log    Get the table20 Packet count before traffic is sprayed
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on both compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on both compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    Evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_02 Verify Traffic when ECMP VM is deleted
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on CSS hosting ECMP VM ,when the other CSS ECMP candidate VMs are deleted.
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    Log    Start Packet Capture on compute node 1
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    Start Packet Capture On Compute Node    ${OS_COMPUTE_1_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[0]}    ${L3_GRE_PORT_NAME[0]}    ${ALLOWED_IP[0]}    ${MASK[0]}
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[3]}
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[2]}
    sleep    30
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    Stop Packet Capture on compute node 1
    Stop Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    Should be Equal As Integers    ${Packet_Count_Node_1}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Actual_Packet_Count}    Evaluate    ${Packet_Count_After_Traffic_1}-${Packet_Count_Before_Traffic_1}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}
    Log    Recreate the deleted VMs
    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_LIST[2]}    ${OS_COMPUTE_2_IP}    ${image}
    ...    ${flavor}    ${SGP}
    Set To Dictionary    ${VmIpDict}    ${VM_LIST[2]}=${VM_IP}
    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_LIST[3]}    ${OS_COMPUTE_2_IP}    ${image}
    ...    ${flavor}    ${SGP}
    Set To Dictionary    ${VmIpDict}    ${VM_LIST[3]}=${VM_IP}
    @{VM_LIST_1}    Create List    ${VM_LIST[0]}    ${VM_LIST[1]}    ${VM_LIST[2]}    ${VM_LIST[3]}
    Configure Next Hop on Router    ${ROUTER_NAME}    ${NO_OF_STATIC_IP}    ${VM_LIST_1}    ${ALLOWED_IP[0]}
    Log    Configure IP on Sub Interface and Verify the IP
    : FOR    ${VM_NAME}    IN    @{VM_LIST_1}
    \    Configure Ip on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}    ${MASK[1]}
    \    Wait Until Keyword Succeeds    30s    5s    Verify Ip Configured on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on both compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    Evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_03 Verify Traffic when ECMP VM is stopped
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on CSS hosting ECMP VM ,when the other CSS ECMP candidate VMs are stopped.
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on both compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Wait Until Keyword Succeeds    20s    2s    Stop Vm Instance    ${VM_LIST[3]}
    Wait Until Keyword Succeeds    20s    2s    Stop Vm Instance    ${VM_LIST[2]}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[2]}}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[3]}}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on both compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}
    Log    Start Packet Capture on both compute nodes after stop/start of VMs
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    : FOR    ${Index}    IN RANGE    2    4
    \    Wait Until Keyword Succeeds    20s    2s    Start VM Instance    ${VM_LIST[${Index}]}
    \    Sleep    30
    \    Configure Ip on Sub Interface    ${ALLOWED_IP[0]}    ${VM_LIST[${Index}]}    ${MASK[1]}
    \    Wait Until Keyword Succeeds    30s    5s    Verify Ip Configured on Sub Interface    ${ALLOWED_IP[0]}    ${VM_LIST[${Index}]}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[2]}}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[3]}}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on both compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Second_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Second_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Second_Traffic}    Evaluate    ${Packet_Count_After_Second_Traffic_1}+${Packet_Count_After_Second_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Second_Traffic}-${Total_Packet_Count_After_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_04 Verify Traffic when ECMP VM is rebooted
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on both CSSs when the ECMP candidate VM are rebooted on CSS2
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on both compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Wait Until Keyword Succeeds    20s    2s    Reboot NOVA VM    ${VM_LIST[3]}
    Wait Until Keyword Succeeds    20s    2s    Reboot NOVA VM    ${VM_LIST[2]}
    sleep    20
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[2]}}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[3]}}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Stop Packet Capture on both compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_05 Verify Traffic when ECMP VMs are added
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on both CSSs when the additional VMs are added on both Computes
    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[4]}    ${VM_LIST[4]}    ${OS_COMPUTE_1_IP}    ${image}
    ...    ${flavor}    ${SGP}
    Set To Dictionary    ${VmIpDict}    ${VM_LIST[4]}=${VM_IP}
    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[5]}    ${VM_LIST[5]}    ${OS_COMPUTE_2_IP}    ${image}
    ...    ${flavor}    ${SGP}
    Set To Dictionary    ${VmIpDict}    ${VM_LIST[5]}=${VM_IP}
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on both compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[4]}}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[5]}}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Stop Packet Capture on both compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_06 Verify Traffic from DC-GW is successfully sprayed on 3 CSS
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on 3 CSSs hosting ECMP VMs
    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[6]}    ${VM_LIST[6]}    ${OS_COMPUTE_3_IP}    ${image}
    ...    ${flavor}    ${SGP}
    Set To Dictionary    ${VmIpDict}    ${VM_LIST[6]}=${VM_IP}
    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[7]}    ${VM_LIST[7]}    ${OS_COMPUTE_3_IP}    ${image}
    ...    ${flavor}    ${SGP}
    Set To Dictionary    ${VmIpDict}    ${VM_LIST[7]}=${VM_IP}
    @{VM_LIST_1}    Create List    ${VM_LIST[0]}    ${VM_LIST[1]}    ${VM_LIST[2]}    ${VM_LIST[3]}    ${VM_LIST[6]}
    ...    ${VM_LIST[7]}
    Configure Next Hop on Router    ${ROUTER_NAME}    ${NO_OF_STATIC_IP}    ${VM_LIST_1}    ${ALLOWED_IP[0]}
    Log    Configure IP on Sub Interface and Verify the IP
    : FOR    ${VM_NAME}    IN    @{VM_LIST_1}
    \    Configure Ip on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}    ${MASK[1]}
    \    Wait Until Keyword Succeeds    30s    5s    Verify Ip Configured on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    : FOR    ${Index}    IN RANGE    3
    \    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[${Index}]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[4]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[4]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_3}    Verify flows in Compute Node    ${OS_COMPUTE_3_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[4]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_3}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_3}    Get table20 Packet Count    ${OS_COMPUTE_3_IP}    ${GROUP_ID_3}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}+${Packet_Count_Before_Traffic_3}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    3
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    4
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_3}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_3_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}+${Packet_Count_Node_3}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Packet_Count_After_Traffic_3}    Get table20 Packet Count    ${OS_COMPUTE_3_IP}    ${GROUP_ID_3}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}+${Packet_Count_After_Traffic_3}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_07 Verify Traffic from DC-GW is successfully sprayed when 3 CSS is deleted
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on 2 CSSs when the 3rd CSS is deleted(ECMP VM's are deleted on this CSS)
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[6]}
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[7]}
    sleep    10
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    : FOR    ${Index}    IN RANGE    2
    \    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[${Index}]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_08 Verify Traffic from DC-GW wrt switch stop/start
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed in below scenario - stop CSS2 and start CSS 2 (08 and 09)
    @{VM_LIST_1}    Create List    ${VM_LIST[0]}    ${VM_LIST[1]}    ${VM_LIST[2]}    ${VM_LIST[3]}
    Configure Next Hop on Router    ${ROUTER_NAME}    ${NO_OF_STATIC_IP}    ${VM_LIST_1}    ${ALLOWED_IP[0]}
    Log    Configure IP on Sub Interface and Verify the IP
    : FOR    ${VM_NAME}    IN    @{VM_LIST_1}
    \    Configure Ip on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}    ${MASK[1]}
    \    Wait Until Keyword Succeeds    30s    5s    Verify Ip Configured on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    : FOR    ${Index}    IN RANGE    2
    \    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[${Index}]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Stop CSS 2
    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo service openvswitch-switch stop
    # Wait For Flows On Switch    ${OS_COMPUTE_2_IP}
    Sleep    5
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    #    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Packet_Count_After_Traffic_1}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start CSS 2
    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo service openvswitch-switch start
    Wait For Flows On Switch    ${OS_COMPUTE_2_IP}
    sleep    5
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}

TC_09 Verify Traffic from DC-GW when CSS in standalone mode
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed when both CSS is in standalone mode.
    Log    Configuring Compute Node in Standalone Mode
    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-vsctl set-fail-mode br-int standalone
    Utils.Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-vsctl set-fail-mode br-int standalone
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    Log    Restart the controller and verify flows
    Wait Until Keyword Succeeds    50s    10s    Issue Command On Karaf Console    shutdown -f
    sleep    20
    Log    Verify that flows are removed from Switch
    : FOR    ${index}    IN RANGE    1    3
    \    ${OvsFlow}    Utils.Run Command On Remote System    ${OS_COMPUTE_${index}_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep table
    \    Run Keyword If    "${OvsFlow}" != "${EMPTY}"    FAIL
    Log    Start Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should Not be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    Log    Verify that the Controller is operational after Reboot
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${karafpath}/start    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${Karafinfo}    Run Command On Remote System    ${ODL_SYSTEM_IP}    ps -eaf | grep karaf    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${match}    Should Match Regexp    ${Karafinfo}    \\d+.*bin/java
    Sleep    30
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Log    ${CTRL_FIB}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}
    Log    Removing Standalone Mode
    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-vsctl del-fail-mode br-int
    Utils.Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-vsctl del-fail-mode br-int

TC_10 Verify Traffic from DC-GW when CSS in secure mode
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed when both CSS is in secure mode.
    Log    Configuring Compute Node in Secure Mode
    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-vsctl set-fail-mode br-int secure
    Utils.Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-vsctl set-fail-mode br-int secure
    Log    Restart the controller and verify flows
    Wait Until Keyword Succeeds    50s    10s    Issue Command On Karaf Console    shutdown -f
    sleep    20
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
	${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}
    Log    Verify that the Controller is operational after Reboot
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${karafpath}/start    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${Karafinfo}    Run Command On Remote System    ${ODL_SYSTEM_IP}    ps -eaf | grep karaf    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${match}    Should Match Regexp    ${Karafinfo}    \\d+.*bin/java
    Sleep    30
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Log    ${CTRL_FIB}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}
    Log    Removing Secure Mode
    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-vsctl del-fail-mode br-int
    Utils.Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-vsctl del-fail-mode br-int

TC_11 Verify Traffic during Controller restart (Non-CoLocated VMs)
    [Documentation]    VM are Non-collocated - Controller and CSS connectivity disconnected
    ...    VM deleted, Traffic impacted as controller is not up, Bring up controller,ECMP reconfigured by CSC and traffic resumed without drop
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    Log    Restart the controller and verify flows
    Wait Until Keyword Succeeds    50s    10s    Issue Command On Karaf Console    shutdown -f
    sleep    20
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[2]}
    sleep    30
    Comment    Log    Verify that flows are removed from Switch
    Comment    : FOR    ${index}    IN RANGE    1    3
    Comment    \    ${OvsFlow}    Utils.Run Command On Remote System    ${OS_COMPUTE_${index}_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep table
    Comment    \    Run Keyword If    "${OvsFlow}" != "${EMPTY}"    FAIL
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should Not be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    Log    Verify that the Controller is operational after Reboot
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${karafpath}/start    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${Karafinfo}    Run Command On Remote System    ${ODL_SYSTEM_IP}    ps -eaf | grep karaf    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${match}    Should Match Regexp    ${Karafinfo}    \\d+.*bin/java
    Sleep    30
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Log    ${CTRL_FIB}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_12 Verify Traffic during Controller restart (CoLocated VMs)
    [Documentation]    VM are collocated - Controller and CSS connectivity disconnected
    ...    VM deleted, Traffic impacted as controller is not up, Bring up controller,ECMP reconfigured by CSC and traffic resumed without drop
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    Log    Restart the controller and verify flows
    Wait Until Keyword Succeeds    50s    10s    Issue Command On Karaf Console    shutdown -f
    sleep    20
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[2]}
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[3]}
    sleep    30
    Comment    Log    Verify that flows are removed from Switch
    Comment    : FOR    ${index}    IN RANGE    1    3
    Comment    \    ${OvsFlow}    Utils.Run Command On Remote System    ${OS_COMPUTE_${index}_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep table
    Comment    \    Run Keyword If    "${OvsFlow}" != "${EMPTY}"    FAIL
    :FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    :FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should Not be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    Log    Verify that the Controller is operational after Reboot
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${karafpath}/start    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${Karafinfo}    Run Command On Remote System    ${ODL_SYSTEM_IP}    ps -eaf | grep karaf    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${match}    Should Match Regexp    ${Karafinfo}    \\d+.*bin/java
    Sleep    30
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Log    ${CTRL_FIB}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    :FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    :FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

*** Keywords ***
Start Suite
    [Documentation]    Run at start of the suite
    DevstackUtils.Devstack Suite Setup
    Create Setup

End Suite
    [Documentation]    Run at end of the suite
    Delete Setup
    Close All Connections

Create Setup
    [Documentation]    Create networks,subnets,ports and VMs,tep ports
    Log    Adding TEP ports
    Tep Port Operations    ${OPERATION[0]}    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}    ${OS_COMPUTE_3_IP}
    ${TepShow}    Issue Command On Karaf Console    ${TEP_SHOW}
    ${TunnelCount}    Get Regexp Matches    ${TepShow}    TZA\\s+VXLAN
    Length Should Be    ${TunnelCount}    ${3}
    Wait Until Keyword Succeeds    200s    20s    Verify Tunnel Status as UP
    Log    Configure BGP in controller
    Issue Command On Karaf Console    bgp-connect -h ${ODL_BGP_IP} -p 7644 add
    Issue Command On Karaf Console    bgp-rtr -r ${ODL_BGP_IP} -a ${AS_ID} add
    Issue Command On Karaf Console    bgp-nbr -a ${AS_ID} -i ${DCGW_IP} add
    Issue Command On Karaf Console    bgp-cache
    Utils.Post Elements To URI    ${AddGreUrl}    ${DCGW1_TUNNEL_CONFIG}
    Comment    "Creating customised security Group"
    ${OUTPUT}    ${SGP_ID}    OpenStackOperations.Neutron Security Group Create    ${SGP}
    Comment    "Creating the rules for ingress direction"
    ${OUTPUT1}    ${RULE_ID1}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=ingress    protocol=icmp
    ${OUTPUT2}    ${RULE_ID2}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=ingress    protocol=tcp
    ${OUTPUT3}    ${RULE_ID3}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=ingress    protocol=udp
    Comment    "Creating the rules for egress direction"
    ${OUTPUT4}    ${RULE_ID4}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=egress    protocol=icmp
    ${OUTPUT5}    ${RULE_ID5}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=egress    protocol=tcp
    ${OUTPUT6}    ${RULE_ID6}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=egress    protocol=udp
    Comment    "Create Neutron Network , Subnet and Ports"
    Wait Until Keyword Succeeds    30s    5s    Create Network    ${NETWORK_NAME}
    Wait Until Keyword Succeeds    30s    5s    Create SubNet    ${NETWORK_NAME}    ${SUBNET_NAME}    ${SUBNET_CIDR}
    #...    --enable-dhcp
    : FOR    ${PortName}    IN    @{PORT_LIST}
    \    MultiPathKeywords.Create Port    ${NETWORK_NAME}    ${PortName}    ${SGP}    ${ALLOWED_IP}
    &{VmIpDict}    Create Dictionary
    Set Global Variable    ${VmIpDict}
    Log To Console    "Creating VM's on Compute Node 1 and 2"
    : FOR    ${Index}    IN    0    1
    \    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${Index}]}    ${VM_LIST[${Index}]}    ${OS_COMPUTE_1_IP}
    \    ...    ${image}    ${flavor}    ${SGP}
    \    Set To Dictionary    ${VmIpDict}    ${VM_LIST[${Index}]}=${VM_IP}
    : FOR    ${Index}    IN    2    3
    \    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${Index}]}    ${VM_LIST[${Index}]}    ${OS_COMPUTE_2_IP}
    \    ...    ${image}    ${flavor}    ${SGP}
    \    Set To Dictionary    ${VmIpDict}    ${VM_LIST[${Index}]}=${VM_IP}
    Log    ${VmIpDict}
    Create Router    ${ROUTER_NAME}
    ${Additional_Args}    Set Variable    -- --route-distinguishers list=true 100:1 100:2 100:3 --route-targets 100:1 100:2 100:3
    ${vpnid}    Create Bgpvpn    ${VPN_NAMES[0]}    ${Additional_Args}
    Add Router Interface    ${ROUTER_NAME}    ${SUBNET_NAME}
    Bgpvpn Router Associate    ${ROUTER_NAME}    ${VPN_NAMES[0]}
    Sleep    30
    Log    Verify the VM route in fib
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    ${Temp_list}    Get Dictionary Values    ${VmIpDict}
    : FOR    ${VmIp}    IN    @{Temp_list}
    \    Should Contain    ${CTRL_FIB}    ${VmIp}
    @{VM_LIST_1}    Create List    ${VM_LIST[0]}    ${VM_LIST[1]}    ${VM_LIST[2]}    ${VM_LIST[3]}
    Configure Next Hop on Router    ${ROUTER_NAME}    ${NO_OF_STATIC_IP}    ${VM_LIST_1}    ${ALLOWED_IP[0]}
    Log    Configure IP on Sub Interface and Verify the IP
    : FOR    ${VM_NAME}    IN    @{VM_LIST_1}
    \    Configure Ip on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}    ${MASK[1]}
    \    Wait Until Keyword Succeeds    30s    5s    Verify Ip Configured on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}

Delete Setup
    [Documentation]    Clean the config created for ECMP TCs
    Log    Deleting all VMs and Ports
    : FOR    ${PortName}    ${VmName}    IN ZIP    ${PORT_LIST}    ${VM_LIST}
    \    Delete Vm Instance    ${VmName}
    \    Delete Port    ${PortName}
    ${VMs}    List VMs
    ${Ports}    List Ports
    : FOR    ${PortName}    ${VmName}    IN ZIP    ${PORT_LIST}    ${VM_LIST}
    \    Should Not Contain    ${VMs}    ${VmName}
    \    Should Not Contain    ${Ports}    ${PortName}
    Update Router    ${ROUTER_NAME}    --no-routes
    Remove Interface    ${ROUTER_NAME}    ${SUBNET_NAME}
    Delete Router    ${ROUTER_NAME}
    Delete Bgpvpn    ${VPN_NAMES[0]}
    Delete SubNet    ${SUBNET_NAME}
    Delete Network    ${NETWORK_NAME}
    Neutron Security Group Delete    ${SGP}
    Log    Configure BGP in controller
    Issue Command On Karaf Console    bgp-nbr -a ${AS_ID} -i ${DCGW_IP} del
    Issue Command On Karaf Console    bgp-rtr -r ${ODL_BGP_IP} -a ${AS_ID} del
    Issue Command On Karaf Console    bgp-connect -h ${ODL_BGP_IP} -p 7644 del
    Issue Command On Karaf Console    bgp-cache
    Utils.Post Elements To URI    ${DelGreUrl}    ${DCGW1_TUNNEL_CONFIG}
    Log    Deleting TEP ports
    Tep Port Operations    ${OPERATION[1]}    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}    ${OS_COMPUTE_3_IP}

Execute Command In Context Of SER
    [Arguments]    ${SER_IP}    ${ContextName}    ${cmd}    ${SER_UNAME}=redback    ${SER_PWD}=bete123
    [Documentation]    Execute set of command on SER
    ${conn_id}=    Open Connection    localhost
    Login    root    admin123
    Switch Connection    ${conn_id}
    ${output} =    Write    telnet ${SER_IP}
    ${output} =    Read Until    Username:
    ${output} =    Write    ${SER_UNAME}
    ${output} =    Read Until    Password:
    ${output} =    Write    ${SER_PWD}
    ${output} =    Read Until    \#
    ${output} =    Write    ${cmd}
    ${output} =    Read    delay=6s
    Write    exit
    Read Until    \#
    SSHLibrary.Close Connection
    [Return]    ${output}

Execute Command In vASR
    [Arguments]    ${vASR_VM_ID}    ${vASR_IP}    ${cmd}    ${vASR_UNAME}=cisco    ${vASR_PWD}=cisco
    [Documentation]    Execute set of command on vASR
    ${conn_id}    Open Connection    ${vASR_IP}
    Login    root    admin123
    Switch Connection    ${conn_id}
    ${output}    Execute Command On Server    ${vASR_VM_ID}    ${EMPTY}    ${vASR_IP}    ${cmd}    ${vASR_UNAME}
    ...    ${vASR_PWD}
    [Return]    ${output}

Execute Command In SER
    [Arguments]    ${SER_IP}    ${Command}    ${SER_UNAME}=cisco    ${SER_PWD}=cisco
    [Documentation]    Execute single command in configuration mode
    ${conn_id}=    Open Connection    localhost
    Login    root    admin123
    Switch Connection    ${conn_id}
    ${output} =    Write    telnet ${SER_IP}
    ${output} =    Read Until    Username:
    ${output} =    Write    ${SER_UNAME}
    ${output} =    Read Until    Password:
    ${output} =    Write    ${SER_PWD}
    ${output} =    Read Until    \#
    ${output} =    Write    terminal length 0
    ${output} =    Read Until    \#
    ${output} =    Write    ${Command}
    ${output} =    Read    delay=6s
    Write    exit
    Read Until    \#
    SSHLibrary.Close Connection
    Log    ${output}
    [Return]    ${output}

Start Non CBA Controller
    [Arguments]    ${CtrlIp}    ${KarafPath}
    SSHLibrary.Open Connection    ${CtrlIp}
    Set Client Configuration    prompt=#
    SSHLibrary.Login    root    admin123
    Write Commands Until Prompt    cd ${KarafPath}
    Write Commands Until Prompt    ./start
    Sleep    5
    SSHLibrary.Close Connection

Verify Controller Is Operational
    [Arguments]    ${CtrlIp}    ${CBA_PLAT}=False
    ${conn_handle}    Run Keyword If    ${CBA_PLAT}==True    Verify CBA Controller Is Operational    ${CtrlIp}
    ...    ELSE    Verify Non CBA Controller Is Operational    ${CtrlIp}

Verify CBA Controller Is Operational
    [Arguments]    ${NoOfNode}=3
    ${resp}    Issue Command On Karaf Console    showsvcstatus | grep OPERATIONAL | wc -l
    ${regex}    Evaluate    ${NoOfNode}*6
    ${match}    Should Match Regexp    ${resp}    ${regex}

Verify Non CBA Controller Is Operational
    [Arguments]    ${CtrlIp}
    SSHLibrary.Open Connection    ${CtrlIp}
    Set Client Configuration    prompt=#
    SSHLibrary.Login    root    admin123
    ${output} =    Write Commands Until Prompt    ps -ef | grep karaf
    ${match}    Should Match Regexp    ${output}    \\d+.*bin/java
    SSHLibrary.Close Connection

Verify Static Ip Configured In VM
    [Arguments]    ${VmName}    ${DpnIp}    ${StaticIp}
    ${resp}    Execute Command on server    sudo ifconfig eth0:0    ${VmName}    ${VMInstanceDict.${VmName}}    ${DpnIp}
    Should Contain    ${resp}    ${StaticIp}

Verify Tunnel State
    [Arguments]    ${TunnelCount}    ${Regex}
    ${TepState}    Issue Command On Karaf Console    tep:show-state
    ${ActiveTunnelCount}    Get Regexp Matches    ${TepState}    ${Regex}
    Length Should Be    ${ActiveTunnelCount}    ${TunnelCount}

Verify Flow Remove from Switch
    [Arguments]    ${DpnIp}
    ${OvsFlow}    Utils.Run Command On Remote System    ${DpnIp}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep table
    Run keyword if    "${OvsFlow}"    Fail

Start Packet Generation
    [Arguments]    ${Server_IP}    ${ScriptPath}    ${Script}    ${user}=root    ${password}=admin123
    SSHLibrary.Open Connection    ${Server_IP}
    Set Client Configuration    prompt=${ODL_SYSTEM_PROMPT}
    SSHLibrary.Login    ${user}    ${password}
    ${output}    Write Commands Until Prompt    rm -rf /tmp/dump.txt
    ${cmd}    Set Variable    python ${ScriptPath}/${Script} >> /tmp/dump.txt
    ${output}    Write Commands Until Prompt    python ${ScriptPath}/${Script} >> /tmp/dump.txt    60s
    sleep    5
    #    ${stdout}    ${stderr} =    SSHLibrary.Start Command    ${cmd}
    ${output}    Write Commands Until Prompt    sudo cat /tmp/dump.txt
    #    ${output}    SSHLibrary.Execute Command    sudo cat /tmp/dump.txt
    ${match}    ${Packet_Count}    Should Match Regexp    ${output}    Packets sent (\\d+)
    Log    ${Packet_Count}
    Log    ${output}
    Sleep    5
    SSHLibrary.Close Connection
    [Return]    ${Packet_Count}

Start Packet Capture On Compute Node
    [Arguments]    ${node_ip}    ${file_Name}    ${network_Adapter}    ${GRE_PORT_NAME}    ${IP}    ${MASK_VAL}
    ...    ${user}=root    ${password}=admin123    ${prompt}=${ODL_SYSTEM_PROMPT}    ${prompt_timeout}=${DEFAULT_TIMEOUT}
    [Documentation]    Connects to the remote machine and starts tcpdump
    ${current_ssh_connection}=    SSHLibrary.Get Connection
    ${conn_id}=    SSHLibrary.Open Connection    ${node_ip}    prompt=${prompt}    timeout=${prompt_timeout}
    Flexible SSH Login    ${user}    ${password}
    ${cmd_1}    Set Variable    ovs-vsctl add-port br-int ${GRE_PORT_NAME} -- --id=@mirror_from get port ${network_Adapter} -- --id=@mirror_to get port ${GRE_PORT_NAME} -- --id=@m create mirror name=test_mirror_gre select-dst-port=@mirror_from select-src-port=@mirror_from output-port=@mirror_to -- set bridge br-int mirrors=@m -- set interface ${GRE_PORT_NAME} type=internal
    ${output}    Execute Command    ${cmd_1}
    ${cmd_2}    Set Variable    ifconfig ${GRE_PORT_NAME} up
    ${output}    Execute Command    ${cmd_2}
    ${cmd} =    Set Variable    sudo /usr/sbin/tcpdump -vvv -ni ${GRE_PORT_NAME} -O -vv "mpls && dst net ${IP}/${MASK_VAL}" >> /tmp/${file_Name}.pcap
    ${stdout}    ${stderr} =    SSHLibrary.Start Command    ${cmd}
    #    SSHLibrary.Close Connection
    Log    ${stderr}
    Log    ${stdout}
    #    [Return]    ${conn_id}
    [Teardown]    SSHKeywords.Restore_Current_SSH_Connection_From_Index    ${current_ssh_connection.index}

Stop Packet Capture on Compute Node
    [Arguments]    ${node_ip}    ${user}=root    ${password}=admin123    ${prompt}=${ODL_SYSTEM_PROMPT}    ${prompt_timeout}=${DEFAULT_TIMEOUT}
    [Documentation]    This keyword will list the running processes looking for tcpdump and then kill the process with the name tcpdump
    ${conn_id}    Open Connection    ${node_ip}    prompt=${prompt}    timeout=${prompt_timeout}
    Login    ${user}    ${password}
    Switch Connection    ${conn_id}
    ${stdout} =    SSHLibrary.Execute Command    sudo ps -elf | grep tcpdump
    Log    ${stdout}
    ${stdout}    ${stderr} =    SSHLibrary.Execute Command    sudo pkill -f tcpdump    return_stderr=True
    Log    ${stdout}
    ${stdout}    ${stderr} =    SSHLibrary.Execute Command    sudo ls -lart /tmp    return_stderr=True
    Log    ${stdout}
    SSHLibrary. Close Connection

Get The Packet Capture on Compute Node
    [Arguments]    ${Compute_IP}    ${IP}    ${file_name}    ${user}=root    ${password}=admin123    ${prompt}=${ODL_SYSTEM_PROMPT}
    ...    ${prompt_timeout}=${DEFAULT_TIMEOUT}
    [Documentation]    Keyword to return the number of tcpdump packets captured on specified compute node
    ${conn_id}    Open Connection    ${Compute_IP}    prompt=${prompt}    timeout=${prompt_timeout}
    Login    ${user}    ${password}
    Switch Connection    ${conn_id}
    ${output}    SSHLibrary.Execute Command    sudo cat /tmp/${file_name}.pcap
    Should Match Regexp    ${output}    ${IP}
    ${output}    SSHLibrary.Execute Command    grep -w "${IP}" -c /tmp/${file_name}.pcap
    Log    ${output}
    ${stdout} =    SSHLibrary.Execute Command    rm -rf /tmp/*.pcap
    SSHLibrary. Close Connection
    [Return]    ${output}

Verify The Packet Capture
    [Arguments]    ${PACKET_CAPTURE_FILE_NAME}    ${EXPECTED_PACKET_COUNT}    ${IP}    ${OS_COMPUTE_3_IP}=${EMPTY}
    [Documentation]    Keyword to verify the Packets captured on compute node
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${IP}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${IP}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_3}    Run Keyword If    "${OS_COMPUTE_3_IP}" != "${EMPTY}"    Get The Packet Capture on Compute Node    ${OS_COMPUTE_3_IP}    ${IP}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count}    Set Variable If    "${OS_COMPUTE_3_IP}" != "${EMPTY}"    ${Packet_Count_Node_1}+${Packet_Count_Node_2}+${Packet_Count_Node_3}    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${EXPECTED_PACKET_COUNT}

Verify The Packet Count In Flows
    [Arguments]    ${GROUP_ID}    ${EXPECTED_PACKET_COUNT}    ${OS_COMPUTE_3_IP}=${EMPTY}
    [Documentation]    Keyword to verify the packet count in respective flow dumps
    ${Packet_Count_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID}
    ${Packet_Count_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID}
    ${Packet_Count_3}    Run Keyword If    "${OS_COMPUTE_3_IP}" != "${EMPTY}"    Get table20 Packet Count    ${OS_COMPUTE_3_IP}    ${GROUP_ID}
    ${Packet_Count}    Set Variable If    "${OS_COMPUTE_3_IP}" != "${EMPTY}"    ${Packet_Count_1}+${Packet_Count_2}+${Packet_Count_3}    ${Packet_Count_1}+${Packet_Count_2}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${EXPECTED_PACKET_COUNT}

Read Packet Capture on Compute Node
    [Arguments]    ${conn_id}
    [Documentation]    This keyword will list the running processes looking for tcpdump and then kill the process with the name tcpdump
    ${conn_id}    Open Connection    ${conn_id}
    Login    root    admin123
    Switch Connection    ${conn_id}
    ${stdout} =    SSHLibrary.Execute Command    sudo cat /tmp/*.pcap
    Log    ${stdout}
    SSHLibrary. Close Connection
    [Return]    ${stdout}

Count of Packet Captured on Node
    [Arguments]    ${conn_id}
    [Documentation]    This keyword will list the running processes looking for tcpdump and then kill the process with the name tcpdump
    ${conn_id}    Open Connection    ${conn_id}
    Login    root    admin123
    Switch Connection    ${conn_id}
    ${stdout} =    SSHLibrary.Execute Command    grep -w "100.100.100.100" -c /tmp/*.pcap
    Log    ${stdout}
    SSHLibrary. Close Connection
    [Return]    ${stdout}

Get table20 Packet Count
    [Arguments]    ${COMPUTE_IP}    ${GROUP_ID}
    [Documentation]    Get the packet count from table 20 for the specified group id
    ${OVS_FLOW}    Run Command On Remote System    ${COMPUTE_IP}    ${DUMP_FLOWS}
    ${MATCH}    ${PACKET_COUNT}    Should Match Regexp    ${OVS_FLOW}    table=20.*n_packets=(\\d+).*group:${GROUP_ID}.*
    Log    ${PACKET_COUNT}
    [Return]    ${PACKET_COUNT}

Get_GRE_Port_Name
    [Arguments]    ${session}=session
    [Documentation]    Get the Port Names of the GRE tunnel
    ${resp}    RequestsLibrary.Get Request    ${session}    ${GrePortList}
    Log    ${resp.content}
    Should be equal as strings    ${resp.status_code}    200
    ${match}    get regexp matches    ${resp.content}    "tun[a-z0-9]+"
    ${GRE_PORT_NAME_LIST}    Create List
    : FOR    ${val}    IN    @{match}
    \    ${port_name}    split string    ${val}    "
    \    Append TO List    ${GRE_PORT_NAME_LIST}    ${port_name[1]}
    \    log    ${port_name}
    [Return]    ${GRE_PORT_NAME_LIST}
*** Settings ***
Documentation     Test suite for ECMP when VM are non-collocated
Suite Setup       Start Suite
Suite Teardown    End Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Resource          ../../variables/SF263/SF263_Variables.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/OpenStackOperations.robot
Resource          ../../libraries/BgpOperations.robot
Resource          ../../libraries/SwitchOperations.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/MultiPathKeywords.robot
Resource          ../../libraries/SetupUtils.robot
Resource          ../../libraries/GBP/OpenFlowUtils.robot
Library           DebugLibrary
Library           RequestsLibrary

*** Variables ***
${SUBNET_CIDR}    10.10.1.0/24
@{L3_GRE_PORT_NAME}    test_tap_l3gre_1    test_tap_l3gre_2    test_tap_l3gre_3
${PACKET_CAPTURE_FILE_NAME}    Compute_packet

*** Testcases ***
TC_01 Verify Traffic from DC-GW is successfully sprayed on both CSSs
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on both CSSs hosting ECMP VMs
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Verify multipath is enabled in SER
    ${output}    Execute Command In SER    ${DCGW_IP}    show bgp vrf ${VPN_NAMES[1]} ${ALLOWED_IP[0]}
    Should Match Regexp    ${output}    multipath
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    Log    Get the table20 Packet count before traffic is sprayed
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on both compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on both compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    Evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_02 Verify Traffic when ECMP VM is deleted
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on CSS hosting ECMP VM ,when the other CSS ECMP candidate VMs are deleted.
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    Log    Start Packet Capture on compute node 1
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    Start Packet Capture On Compute Node    ${OS_COMPUTE_1_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[0]}    ${L3_GRE_PORT_NAME[0]}    ${ALLOWED_IP[0]}    ${MASK[0]}
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[3]}
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[2]}
    sleep    30
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    Stop Packet Capture on compute node 1
    Stop Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    Should be Equal As Integers    ${Packet_Count_Node_1}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Actual_Packet_Count}    Evaluate    ${Packet_Count_After_Traffic_1}-${Packet_Count_Before_Traffic_1}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}
    Log    Recreate the deleted VMs
    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_LIST[2]}    ${OS_COMPUTE_2_IP}    ${image}
    ...    ${flavor}    ${SGP}
    Set To Dictionary    ${VmIpDict}    ${VM_LIST[2]}=${VM_IP}
    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_LIST[3]}    ${OS_COMPUTE_2_IP}    ${image}
    ...    ${flavor}    ${SGP}
    Set To Dictionary    ${VmIpDict}    ${VM_LIST[3]}=${VM_IP}
    @{VM_LIST_1}    Create List    ${VM_LIST[0]}    ${VM_LIST[1]}    ${VM_LIST[2]}    ${VM_LIST[3]}
    Configure Next Hop on Router    ${ROUTER_NAME}    ${NO_OF_STATIC_IP}    ${VM_LIST_1}    ${ALLOWED_IP[0]}
    Log    Configure IP on Sub Interface and Verify the IP
    : FOR    ${VM_NAME}    IN    @{VM_LIST_1}
    \    Configure Ip on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}    ${MASK[1]}
    \    Wait Until Keyword Succeeds    30s    5s    Verify Ip Configured on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on both compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    Evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_03 Verify Traffic when ECMP VM is stopped
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on CSS hosting ECMP VM ,when the other CSS ECMP candidate VMs are stopped.
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on both compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Wait Until Keyword Succeeds    20s    2s    Stop Vm Instance    ${VM_LIST[3]}
    Wait Until Keyword Succeeds    20s    2s    Stop Vm Instance    ${VM_LIST[2]}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[2]}}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[3]}}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on both compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}
    Log    Start Packet Capture on both compute nodes after stop/start of VMs
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    : FOR    ${Index}    IN RANGE    2    4
    \    Wait Until Keyword Succeeds    20s    2s    Start VM Instance    ${VM_LIST[${Index}]}
    \    Sleep    30
    \    Configure Ip on Sub Interface    ${ALLOWED_IP[0]}    ${VM_LIST[${Index}]}    ${MASK[1]}
    \    Wait Until Keyword Succeeds    30s    5s    Verify Ip Configured on Sub Interface    ${ALLOWED_IP[0]}    ${VM_LIST[${Index}]}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[2]}}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[3]}}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on both compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Second_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Second_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Second_Traffic}    Evaluate    ${Packet_Count_After_Second_Traffic_1}+${Packet_Count_After_Second_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Second_Traffic}-${Total_Packet_Count_After_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_04 Verify Traffic when ECMP VM is rebooted
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on both CSSs when the ECMP candidate VM are rebooted on CSS2
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on both compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Wait Until Keyword Succeeds    20s    2s    Reboot NOVA VM    ${VM_LIST[3]}
    Wait Until Keyword Succeeds    20s    2s    Reboot NOVA VM    ${VM_LIST[2]}
    sleep    20
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[2]}}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[3]}}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Stop Packet Capture on both compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_05 Verify Traffic when ECMP VMs are added
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on both CSSs when the additional VMs are added on both Computes
    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[4]}    ${VM_LIST[4]}    ${OS_COMPUTE_1_IP}    ${image}
    ...    ${flavor}    ${SGP}
    Set To Dictionary    ${VmIpDict}    ${VM_LIST[4]}=${VM_IP}
    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[5]}    ${VM_LIST[5]}    ${OS_COMPUTE_2_IP}    ${image}
    ...    ${flavor}    ${SGP}
    Set To Dictionary    ${VmIpDict}    ${VM_LIST[5]}=${VM_IP}
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on both compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[4]}}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${VmIpDict.${VM_LIST[5]}}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Stop Packet Capture on both compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_06 Verify Traffic from DC-GW is successfully sprayed on 3 CSS
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on 3 CSSs hosting ECMP VMs
    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[6]}    ${VM_LIST[6]}    ${OS_COMPUTE_3_IP}    ${image}
    ...    ${flavor}    ${SGP}
    Set To Dictionary    ${VmIpDict}    ${VM_LIST[6]}=${VM_IP}
    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[7]}    ${VM_LIST[7]}    ${OS_COMPUTE_3_IP}    ${image}
    ...    ${flavor}    ${SGP}
    Set To Dictionary    ${VmIpDict}    ${VM_LIST[7]}=${VM_IP}
    @{VM_LIST_1}    Create List    ${VM_LIST[0]}    ${VM_LIST[1]}    ${VM_LIST[2]}    ${VM_LIST[3]}    ${VM_LIST[6]}
    ...    ${VM_LIST[7]}
    Configure Next Hop on Router    ${ROUTER_NAME}    ${NO_OF_STATIC_IP}    ${VM_LIST_1}    ${ALLOWED_IP[0]}
    Log    Configure IP on Sub Interface and Verify the IP
    : FOR    ${VM_NAME}    IN    @{VM_LIST_1}
    \    Configure Ip on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}    ${MASK[1]}
    \    Wait Until Keyword Succeeds    30s    5s    Verify Ip Configured on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    : FOR    ${Index}    IN RANGE    3
    \    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[${Index}]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[4]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[4]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_3}    Verify flows in Compute Node    ${OS_COMPUTE_3_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[4]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_3}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_3}    Get table20 Packet Count    ${OS_COMPUTE_3_IP}    ${GROUP_ID_3}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}+${Packet_Count_Before_Traffic_3}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    3
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    4
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_3}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_3_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}+${Packet_Count_Node_3}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Packet_Count_After_Traffic_3}    Get table20 Packet Count    ${OS_COMPUTE_3_IP}    ${GROUP_ID_3}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}+${Packet_Count_After_Traffic_3}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_07 Verify Traffic from DC-GW is successfully sprayed when 3 CSS is deleted
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed on 2 CSSs when the 3rd CSS is deleted(ECMP VM's are deleted on this CSS)
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[6]}
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[7]}
    sleep    10
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    : FOR    ${Index}    IN RANGE    2
    \    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[${Index}]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    Log    Verify that the traffic is sprayed across the Compute Nodes via Packet Capture and Flows
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_08 Verify Traffic from DC-GW wrt switch stop/start
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed in below scenario - stop CSS2 and start CSS 2 (08 and 09)
    @{VM_LIST_1}    Create List    ${VM_LIST[0]}    ${VM_LIST[1]}    ${VM_LIST[2]}    ${VM_LIST[3]}
    Configure Next Hop on Router    ${ROUTER_NAME}    ${NO_OF_STATIC_IP}    ${VM_LIST_1}    ${ALLOWED_IP[0]}
    Log    Configure IP on Sub Interface and Verify the IP
    : FOR    ${VM_NAME}    IN    @{VM_LIST_1}
    \    Configure Ip on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}    ${MASK[1]}
    \    Wait Until Keyword Succeeds    30s    5s    Verify Ip Configured on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    : FOR    ${Index}    IN RANGE    2
    \    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[${Index}]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Stop CSS 2
    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo service openvswitch-switch stop
    # Wait For Flows On Switch    ${OS_COMPUTE_2_IP}
    Sleep    5
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    #    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Packet_Count_After_Traffic_1}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start CSS 2
    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo service openvswitch-switch start
    Wait For Flows On Switch    ${OS_COMPUTE_2_IP}
    sleep    5
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}

TC_09 Verify Traffic from DC-GW when CSS in standalone mode
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed when both CSS is in standalone mode.
    Log    Configuring Compute Node in Standalone Mode
    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-vsctl set-fail-mode br-int standalone
    Utils.Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-vsctl set-fail-mode br-int standalone
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    Log    Restart the controller and verify flows
    Wait Until Keyword Succeeds    50s    10s    Issue Command On Karaf Console    shutdown -f
    sleep    20
    Log    Verify that flows are removed from Switch
    : FOR    ${index}    IN RANGE    1    3
    \    ${OvsFlow}    Utils.Run Command On Remote System    ${OS_COMPUTE_${index}_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep table
    \    Run Keyword If    "${OvsFlow}" != "${EMPTY}"    FAIL
    Log    Start Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should Not be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    Log    Verify that the Controller is operational after Reboot
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${karafpath}/start    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${Karafinfo}    Run Command On Remote System    ${ODL_SYSTEM_IP}    ps -eaf | grep karaf    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${match}    Should Match Regexp    ${Karafinfo}    \\d+.*bin/java
    Sleep    30
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Log    ${CTRL_FIB}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}
    Log    Removing Standalone Mode
    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-vsctl del-fail-mode br-int
    Utils.Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-vsctl del-fail-mode br-int

TC_10 Verify Traffic from DC-GW when CSS in secure mode
    [Documentation]    Verify Traffic from DC-GW is successfully sprayed when both CSS is in secure mode.
    Log    Configuring Compute Node in Secure Mode
    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-vsctl set-fail-mode br-int secure
    Utils.Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-vsctl set-fail-mode br-int secure
    Log    Restart the controller and verify flows
    Wait Until Keyword Succeeds    50s    10s    Issue Command On Karaf Console    shutdown -f
    sleep    20
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
	${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}
    Log    Verify that the Controller is operational after Reboot
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${karafpath}/start    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${Karafinfo}    Run Command On Remote System    ${ODL_SYSTEM_IP}    ps -eaf | grep karaf    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${match}    Should Match Regexp    ${Karafinfo}    \\d+.*bin/java
    Sleep    30
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Log    ${CTRL_FIB}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}
    Log    Removing Secure Mode
    Utils.Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-vsctl del-fail-mode br-int
    Utils.Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-vsctl del-fail-mode br-int

TC_11 Verify Traffic during Controller restart (Non-CoLocated VMs)
    [Documentation]    VM are Non-collocated - Controller and CSS connectivity disconnected
    ...    VM deleted, Traffic impacted as controller is not up, Bring up controller,ECMP reconfigured by CSC and traffic resumed without drop
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    Log    Restart the controller and verify flows
    Wait Until Keyword Succeeds    50s    10s    Issue Command On Karaf Console    shutdown -f
    sleep    20
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[2]}
    sleep    30
    Comment    Log    Verify that flows are removed from Switch
    Comment    : FOR    ${index}    IN RANGE    1    3
    Comment    \    ${OvsFlow}    Utils.Run Command On Remote System    ${OS_COMPUTE_${index}_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep table
    Comment    \    Run Keyword If    "${OvsFlow}" != "${EMPTY}"    FAIL
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should Not be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    Log    Verify that the Controller is operational after Reboot
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${karafpath}/start    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${Karafinfo}    Run Command On Remote System    ${ODL_SYSTEM_IP}    ps -eaf | grep karaf    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${match}    Should Match Regexp    ${Karafinfo}    \\d+.*bin/java
    Sleep    30
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Log    ${CTRL_FIB}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    : FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    : FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

TC_12 Verify Traffic during Controller restart (CoLocated VMs)
    [Documentation]    VM are collocated - Controller and CSS connectivity disconnected
    ...    VM deleted, Traffic impacted as controller is not up, Bring up controller,ECMP reconfigured by CSC and traffic resumed without drop
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    Log    Restart the controller and verify flows
    Wait Until Keyword Succeeds    50s    10s    Issue Command On Karaf Console    shutdown -f
    sleep    20
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[2]}
    Wait Until Keyword Succeeds    20s    2s    Delete Vm Instance    ${VM_LIST[3]}
    sleep    30
    Comment    Log    Verify that flows are removed from Switch
    Comment    : FOR    ${index}    IN RANGE    1    3
    Comment    \    ${OvsFlow}    Utils.Run Command On Remote System    ${OS_COMPUTE_${index}_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep table
    Comment    \    Run Keyword If    "${OvsFlow}" != "${EMPTY}"    FAIL
    :FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    Log    Start traffic generation using ostinato tool
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    :FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should Not be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    Log    Verify that the Controller is operational after Reboot
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${karafpath}/start    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${Karafinfo}    Run Command On Remote System    ${ODL_SYSTEM_IP}    ps -eaf | grep karaf    ${KARAF_USER}    ${KARAF_PASSWORD}    ${ODL_SYSTEM_PROMPT}
    ${match}    Should Match Regexp    ${Karafinfo}    \\d+.*bin/java
    Sleep    30
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Log    ${CTRL_FIB}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[0]}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${TunnelSourceIp[1]}
    Log    Verify the ECMP flow in all Compute Nodes
    ${GROUP_ID_1}    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${Packet_Count_Before_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_Before_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_Before_Traffic}    Evaluate    ${Packet_Count_Before_Traffic_1}+${Packet_Count_Before_Traffic_2}
    Log    Start Packet Capture on all compute nodes
    ${Gre_Port_Name_List}    Get_GRE_Port_Name
    :FOR    ${Index}    IN RANGE    2
    \    Start Packet Capture On Compute Node    ${OS_COMPUTE_${Index+1}_IP}    ${PACKET_CAPTURE_FILE_NAME}    ${Gre_Port_Name_List[${Index}]}    ${L3_GRE_PORT_NAME[${Index}]}    ${ALLOWED_IP[0]}
    \    ...    ${MASK[0]}
    ${Expected_Packet_Count}    Start Packet Generation    ${Ostinato_Server_Ip}    ${Ostinato_Script_Path}    ${Ostinato_Script_Name}
    Log    ${Expected_Packet_Count}
    Log    Stop Packet Capture on all compute nodes
    :FOR    ${Index}    IN RANGE    1    3
    \    Stop Packet Capture on Compute Node    ${OS_COMPUTE_${Index}_IP}
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${PACKET_CAPTURE_FILE_NAME}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${Expected_Packet_Count}
    ${Packet_Count_After_Traffic_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID_1}
    ${Packet_Count_After_Traffic_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID_2}
    ${Total_Packet_Count_After_Traffic}    Evaluate    ${Packet_Count_After_Traffic_1}+${Packet_Count_After_Traffic_2}
    ${Actual_Packet_Count}    Evaluate    ${Total_Packet_Count_After_Traffic}-${Total_Packet_Count_Before_Traffic}
    Should be Equal As Integers    ${Actual_Packet_Count}    ${Expected_Packet_Count}

*** Keywords ***
Start Suite
    [Documentation]    Run at start of the suite
    DevstackUtils.Devstack Suite Setup
    Create Setup

End Suite
    [Documentation]    Run at end of the suite
    Delete Setup
    Close All Connections

Create Setup
    [Documentation]    Create networks,subnets,ports and VMs,tep ports
    Log    Adding TEP ports
    Tep Port Operations    ${OPERATION[0]}    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}    ${OS_COMPUTE_3_IP}
    ${TepShow}    Issue Command On Karaf Console    ${TEP_SHOW}
    ${TunnelCount}    Get Regexp Matches    ${TepShow}    TZA\\s+VXLAN
    Length Should Be    ${TunnelCount}    ${3}
    Wait Until Keyword Succeeds    200s    20s    Verify Tunnel Status as UP
    Log    Configure BGP in controller
    Issue Command On Karaf Console    bgp-connect -h ${ODL_BGP_IP} -p 7644 add
    Issue Command On Karaf Console    bgp-rtr -r ${ODL_BGP_IP} -a ${AS_ID} add
    Issue Command On Karaf Console    bgp-nbr -a ${AS_ID} -i ${DCGW_IP} add
    Issue Command On Karaf Console    bgp-cache
    Utils.Post Elements To URI    ${AddGreUrl}    ${DCGW1_TUNNEL_CONFIG}
    Comment    "Creating customised security Group"
    ${OUTPUT}    ${SGP_ID}    OpenStackOperations.Neutron Security Group Create    ${SGP}
    Comment    "Creating the rules for ingress direction"
    ${OUTPUT1}    ${RULE_ID1}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=ingress    protocol=icmp
    ${OUTPUT2}    ${RULE_ID2}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=ingress    protocol=tcp
    ${OUTPUT3}    ${RULE_ID3}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=ingress    protocol=udp
    Comment    "Creating the rules for egress direction"
    ${OUTPUT4}    ${RULE_ID4}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=egress    protocol=icmp
    ${OUTPUT5}    ${RULE_ID5}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=egress    protocol=tcp
    ${OUTPUT6}    ${RULE_ID6}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=egress    protocol=udp
    Comment    "Create Neutron Network , Subnet and Ports"
    Wait Until Keyword Succeeds    30s    5s    Create Network    ${NETWORK_NAME}
    Wait Until Keyword Succeeds    30s    5s    Create SubNet    ${NETWORK_NAME}    ${SUBNET_NAME}    ${SUBNET_CIDR}
    #...    --enable-dhcp
    : FOR    ${PortName}    IN    @{PORT_LIST}
    \    MultiPathKeywords.Create Port    ${NETWORK_NAME}    ${PortName}    ${SGP}    ${ALLOWED_IP}
    &{VmIpDict}    Create Dictionary
    Set Global Variable    ${VmIpDict}
    Log To Console    "Creating VM's on Compute Node 1 and 2"
    : FOR    ${Index}    IN    0    1
    \    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${Index}]}    ${VM_LIST[${Index}]}    ${OS_COMPUTE_1_IP}
    \    ...    ${image}    ${flavor}    ${SGP}
    \    Set To Dictionary    ${VmIpDict}    ${VM_LIST[${Index}]}=${VM_IP}
    : FOR    ${Index}    IN    2    3
    \    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${Index}]}    ${VM_LIST[${Index}]}    ${OS_COMPUTE_2_IP}
    \    ...    ${image}    ${flavor}    ${SGP}
    \    Set To Dictionary    ${VmIpDict}    ${VM_LIST[${Index}]}=${VM_IP}
    Log    ${VmIpDict}
    Create Router    ${ROUTER_NAME}
    ${Additional_Args}    Set Variable    -- --route-distinguishers list=true 100:1 100:2 100:3 --route-targets 100:1 100:2 100:3
    ${vpnid}    Create Bgpvpn    ${VPN_NAMES[0]}    ${Additional_Args}
    Add Router Interface    ${ROUTER_NAME}    ${SUBNET_NAME}
    Bgpvpn Router Associate    ${ROUTER_NAME}    ${VPN_NAMES[0]}
    Sleep    30
    Log    Verify the VM route in fib
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    ${Temp_list}    Get Dictionary Values    ${VmIpDict}
    : FOR    ${VmIp}    IN    @{Temp_list}
    \    Should Contain    ${CTRL_FIB}    ${VmIp}
    @{VM_LIST_1}    Create List    ${VM_LIST[0]}    ${VM_LIST[1]}    ${VM_LIST[2]}    ${VM_LIST[3]}
    Configure Next Hop on Router    ${ROUTER_NAME}    ${NO_OF_STATIC_IP}    ${VM_LIST_1}    ${ALLOWED_IP[0]}
    Log    Configure IP on Sub Interface and Verify the IP
    : FOR    ${VM_NAME}    IN    @{VM_LIST_1}
    \    Configure Ip on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}    ${MASK[1]}
    \    Wait Until Keyword Succeeds    30s    5s    Verify Ip Configured on Sub Interface    ${ALLOWED_IP[0]}    ${VM_NAME}

Delete Setup
    [Documentation]    Clean the config created for ECMP TCs
    Log    Deleting all VMs and Ports
    : FOR    ${PortName}    ${VmName}    IN ZIP    ${PORT_LIST}    ${VM_LIST}
    \    Delete Vm Instance    ${VmName}
    \    Delete Port    ${PortName}
    ${VMs}    List VMs
    ${Ports}    List Ports
    : FOR    ${PortName}    ${VmName}    IN ZIP    ${PORT_LIST}    ${VM_LIST}
    \    Should Not Contain    ${VMs}    ${VmName}
    \    Should Not Contain    ${Ports}    ${PortName}
    Update Router    ${ROUTER_NAME}    --no-routes
    Remove Interface    ${ROUTER_NAME}    ${SUBNET_NAME}
    Delete Router    ${ROUTER_NAME}
    Delete Bgpvpn    ${VPN_NAMES[0]}
    Delete SubNet    ${SUBNET_NAME}
    Delete Network    ${NETWORK_NAME}
    Neutron Security Group Delete    ${SGP}
    Log    Configure BGP in controller
    Issue Command On Karaf Console    bgp-nbr -a ${AS_ID} -i ${DCGW_IP} del
    Issue Command On Karaf Console    bgp-rtr -r ${ODL_BGP_IP} -a ${AS_ID} del
    Issue Command On Karaf Console    bgp-connect -h ${ODL_BGP_IP} -p 7644 del
    Issue Command On Karaf Console    bgp-cache
    Utils.Post Elements To URI    ${DelGreUrl}    ${DCGW1_TUNNEL_CONFIG}
    Log    Deleting TEP ports
    Tep Port Operations    ${OPERATION[1]}    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}    ${OS_COMPUTE_3_IP}

Execute Command In Context Of SER
    [Arguments]    ${SER_IP}    ${ContextName}    ${cmd}    ${SER_UNAME}=redback    ${SER_PWD}=bete123
    [Documentation]    Execute set of command on SER
    ${conn_id}=    Open Connection    localhost
    Login    root    admin123
    Switch Connection    ${conn_id}
    ${output} =    Write    telnet ${SER_IP}
    ${output} =    Read Until    Username:
    ${output} =    Write    ${SER_UNAME}
    ${output} =    Read Until    Password:
    ${output} =    Write    ${SER_PWD}
    ${output} =    Read Until    \#
    ${output} =    Write    ${cmd}
    ${output} =    Read    delay=6s
    Write    exit
    Read Until    \#
    SSHLibrary.Close Connection
    [Return]    ${output}

Execute Command In vASR
    [Arguments]    ${vASR_VM_ID}    ${vASR_IP}    ${cmd}    ${vASR_UNAME}=cisco    ${vASR_PWD}=cisco
    [Documentation]    Execute set of command on vASR
    ${conn_id}    Open Connection    ${vASR_IP}
    Login    root    admin123
    Switch Connection    ${conn_id}
    ${output}    Execute Command On Server    ${vASR_VM_ID}    ${EMPTY}    ${vASR_IP}    ${cmd}    ${vASR_UNAME}
    ...    ${vASR_PWD}
    [Return]    ${output}

Execute Command In SER
    [Arguments]    ${SER_IP}    ${Command}    ${SER_UNAME}=cisco    ${SER_PWD}=cisco
    [Documentation]    Execute single command in configuration mode
    ${conn_id}=    Open Connection    localhost
    Login    root    admin123
    Switch Connection    ${conn_id}
    ${output} =    Write    telnet ${SER_IP}
    ${output} =    Read Until    Username:
    ${output} =    Write    ${SER_UNAME}
    ${output} =    Read Until    Password:
    ${output} =    Write    ${SER_PWD}
    ${output} =    Read Until    \#
    ${output} =    Write    terminal length 0
    ${output} =    Read Until    \#
    ${output} =    Write    ${Command}
    ${output} =    Read    delay=6s
    Write    exit
    Read Until    \#
    SSHLibrary.Close Connection
    Log    ${output}
    [Return]    ${output}

Start Non CBA Controller
    [Arguments]    ${CtrlIp}    ${KarafPath}
    SSHLibrary.Open Connection    ${CtrlIp}
    Set Client Configuration    prompt=#
    SSHLibrary.Login    root    admin123
    Write Commands Until Prompt    cd ${KarafPath}
    Write Commands Until Prompt    ./start
    Sleep    5
    SSHLibrary.Close Connection

Verify Controller Is Operational
    [Arguments]    ${CtrlIp}    ${CBA_PLAT}=False
    ${conn_handle}    Run Keyword If    ${CBA_PLAT}==True    Verify CBA Controller Is Operational    ${CtrlIp}
    ...    ELSE    Verify Non CBA Controller Is Operational    ${CtrlIp}

Verify CBA Controller Is Operational
    [Arguments]    ${NoOfNode}=3
    ${resp}    Issue Command On Karaf Console    showsvcstatus | grep OPERATIONAL | wc -l
    ${regex}    Evaluate    ${NoOfNode}*6
    ${match}    Should Match Regexp    ${resp}    ${regex}

Verify Non CBA Controller Is Operational
    [Arguments]    ${CtrlIp}
    SSHLibrary.Open Connection    ${CtrlIp}
    Set Client Configuration    prompt=#
    SSHLibrary.Login    root    admin123
    ${output} =    Write Commands Until Prompt    ps -ef | grep karaf
    ${match}    Should Match Regexp    ${output}    \\d+.*bin/java
    SSHLibrary.Close Connection

Verify Static Ip Configured In VM
    [Arguments]    ${VmName}    ${DpnIp}    ${StaticIp}
    ${resp}    Execute Command on server    sudo ifconfig eth0:0    ${VmName}    ${VMInstanceDict.${VmName}}    ${DpnIp}
    Should Contain    ${resp}    ${StaticIp}

Verify Tunnel State
    [Arguments]    ${TunnelCount}    ${Regex}
    ${TepState}    Issue Command On Karaf Console    tep:show-state
    ${ActiveTunnelCount}    Get Regexp Matches    ${TepState}    ${Regex}
    Length Should Be    ${ActiveTunnelCount}    ${TunnelCount}

Verify Flow Remove from Switch
    [Arguments]    ${DpnIp}
    ${OvsFlow}    Utils.Run Command On Remote System    ${DpnIp}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep table
    Run keyword if    "${OvsFlow}"    Fail

Start Packet Generation
    [Arguments]    ${Server_IP}    ${ScriptPath}    ${Script}    ${user}=root    ${password}=admin123
    SSHLibrary.Open Connection    ${Server_IP}
    Set Client Configuration    prompt=${ODL_SYSTEM_PROMPT}
    SSHLibrary.Login    ${user}    ${password}
    ${output}    Write Commands Until Prompt    rm -rf /tmp/dump.txt
    ${cmd}    Set Variable    python ${ScriptPath}/${Script} >> /tmp/dump.txt
    ${output}    Write Commands Until Prompt    python ${ScriptPath}/${Script} >> /tmp/dump.txt    60s
    sleep    5
    #    ${stdout}    ${stderr} =    SSHLibrary.Start Command    ${cmd}
    ${output}    Write Commands Until Prompt    sudo cat /tmp/dump.txt
    #    ${output}    SSHLibrary.Execute Command    sudo cat /tmp/dump.txt
    ${match}    ${Packet_Count}    Should Match Regexp    ${output}    Packets sent (\\d+)
    Log    ${Packet_Count}
    Log    ${output}
    Sleep    5
    SSHLibrary.Close Connection
    [Return]    ${Packet_Count}

Start Packet Capture On Compute Node
    [Arguments]    ${node_ip}    ${file_Name}    ${network_Adapter}    ${GRE_PORT_NAME}    ${IP}    ${MASK_VAL}
    ...    ${user}=root    ${password}=admin123    ${prompt}=${ODL_SYSTEM_PROMPT}    ${prompt_timeout}=${DEFAULT_TIMEOUT}
    [Documentation]    Connects to the remote machine and starts tcpdump
    ${current_ssh_connection}=    SSHLibrary.Get Connection
    ${conn_id}=    SSHLibrary.Open Connection    ${node_ip}    prompt=${prompt}    timeout=${prompt_timeout}
    Flexible SSH Login    ${user}    ${password}
    ${cmd_1}    Set Variable    ovs-vsctl add-port br-int ${GRE_PORT_NAME} -- --id=@mirror_from get port ${network_Adapter} -- --id=@mirror_to get port ${GRE_PORT_NAME} -- --id=@m create mirror name=test_mirror_gre select-dst-port=@mirror_from select-src-port=@mirror_from output-port=@mirror_to -- set bridge br-int mirrors=@m -- set interface ${GRE_PORT_NAME} type=internal
    ${output}    Execute Command    ${cmd_1}
    ${cmd_2}    Set Variable    ifconfig ${GRE_PORT_NAME} up
    ${output}    Execute Command    ${cmd_2}
    ${cmd} =    Set Variable    sudo /usr/sbin/tcpdump -vvv -ni ${GRE_PORT_NAME} -O -vv "mpls && dst net ${IP}/${MASK_VAL}" >> /tmp/${file_Name}.pcap
    ${stdout}    ${stderr} =    SSHLibrary.Start Command    ${cmd}
    #    SSHLibrary.Close Connection
    Log    ${stderr}
    Log    ${stdout}
    #    [Return]    ${conn_id}
    [Teardown]    SSHKeywords.Restore_Current_SSH_Connection_From_Index    ${current_ssh_connection.index}

Stop Packet Capture on Compute Node
    [Arguments]    ${node_ip}    ${user}=root    ${password}=admin123    ${prompt}=${ODL_SYSTEM_PROMPT}    ${prompt_timeout}=${DEFAULT_TIMEOUT}
    [Documentation]    This keyword will list the running processes looking for tcpdump and then kill the process with the name tcpdump
    ${conn_id}    Open Connection    ${node_ip}    prompt=${prompt}    timeout=${prompt_timeout}
    Login    ${user}    ${password}
    Switch Connection    ${conn_id}
    ${stdout} =    SSHLibrary.Execute Command    sudo ps -elf | grep tcpdump
    Log    ${stdout}
    ${stdout}    ${stderr} =    SSHLibrary.Execute Command    sudo pkill -f tcpdump    return_stderr=True
    Log    ${stdout}
    ${stdout}    ${stderr} =    SSHLibrary.Execute Command    sudo ls -lart /tmp    return_stderr=True
    Log    ${stdout}
    SSHLibrary. Close Connection

Get The Packet Capture on Compute Node
    [Arguments]    ${Compute_IP}    ${IP}    ${file_name}    ${user}=root    ${password}=admin123    ${prompt}=${ODL_SYSTEM_PROMPT}
    ...    ${prompt_timeout}=${DEFAULT_TIMEOUT}
    [Documentation]    Keyword to return the number of tcpdump packets captured on specified compute node
    ${conn_id}    Open Connection    ${Compute_IP}    prompt=${prompt}    timeout=${prompt_timeout}
    Login    ${user}    ${password}
    Switch Connection    ${conn_id}
    ${output}    SSHLibrary.Execute Command    sudo cat /tmp/${file_name}.pcap
    Should Match Regexp    ${output}    ${IP}
    ${output}    SSHLibrary.Execute Command    grep -w "${IP}" -c /tmp/${file_name}.pcap
    Log    ${output}
    ${stdout} =    SSHLibrary.Execute Command    rm -rf /tmp/*.pcap
    SSHLibrary. Close Connection
    [Return]    ${output}

Verify The Packet Capture
    [Arguments]    ${PACKET_CAPTURE_FILE_NAME}    ${EXPECTED_PACKET_COUNT}    ${IP}    ${OS_COMPUTE_3_IP}=${EMPTY}
    [Documentation]    Keyword to verify the Packets captured on compute node
    ${Packet_Count_Node_1}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_1_IP}    ${IP}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_2}    Get The Packet Capture on Compute Node    ${OS_COMPUTE_2_IP}    ${IP}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count_Node_3}    Run Keyword If    "${OS_COMPUTE_3_IP}" != "${EMPTY}"    Get The Packet Capture on Compute Node    ${OS_COMPUTE_3_IP}    ${IP}    ${PACKET_CAPTURE_FILE_NAME}
    ${Packet_Count}    Set Variable If    "${OS_COMPUTE_3_IP}" != "${EMPTY}"    ${Packet_Count_Node_1}+${Packet_Count_Node_2}+${Packet_Count_Node_3}    ${Packet_Count_Node_1}+${Packet_Count_Node_2}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${EXPECTED_PACKET_COUNT}

Verify The Packet Count In Flows
    [Arguments]    ${GROUP_ID}    ${EXPECTED_PACKET_COUNT}    ${OS_COMPUTE_3_IP}=${EMPTY}
    [Documentation]    Keyword to verify the packet count in respective flow dumps
    ${Packet_Count_1}    Get table20 Packet Count    ${OS_COMPUTE_1_IP}    ${GROUP_ID}
    ${Packet_Count_2}    Get table20 Packet Count    ${OS_COMPUTE_2_IP}    ${GROUP_ID}
    ${Packet_Count_3}    Run Keyword If    "${OS_COMPUTE_3_IP}" != "${EMPTY}"    Get table20 Packet Count    ${OS_COMPUTE_3_IP}    ${GROUP_ID}
    ${Packet_Count}    Set Variable If    "${OS_COMPUTE_3_IP}" != "${EMPTY}"    ${Packet_Count_1}+${Packet_Count_2}+${Packet_Count_3}    ${Packet_Count_1}+${Packet_Count_2}
    ${TOTAL_PACKET_COUNT}    evaluate    ${Packet_Count}
    Should be Equal As Integers    ${TOTAL_PACKET_COUNT}    ${EXPECTED_PACKET_COUNT}

Read Packet Capture on Compute Node
    [Arguments]    ${conn_id}
    [Documentation]    This keyword will list the running processes looking for tcpdump and then kill the process with the name tcpdump
    ${conn_id}    Open Connection    ${conn_id}
    Login    root    admin123
    Switch Connection    ${conn_id}
    ${stdout} =    SSHLibrary.Execute Command    sudo cat /tmp/*.pcap
    Log    ${stdout}
    SSHLibrary. Close Connection
    [Return]    ${stdout}

Count of Packet Captured on Node
    [Arguments]    ${conn_id}
    [Documentation]    This keyword will list the running processes looking for tcpdump and then kill the process with the name tcpdump
    ${conn_id}    Open Connection    ${conn_id}
    Login    root    admin123
    Switch Connection    ${conn_id}
    ${stdout} =    SSHLibrary.Execute Command    grep -w "100.100.100.100" -c /tmp/*.pcap
    Log    ${stdout}
    SSHLibrary. Close Connection
    [Return]    ${stdout}

Get table20 Packet Count
    [Arguments]    ${COMPUTE_IP}    ${GROUP_ID}
    [Documentation]    Get the packet count from table 20 for the specified group id
    ${OVS_FLOW}    Run Command On Remote System    ${COMPUTE_IP}    ${DUMP_FLOWS}
    ${MATCH}    ${PACKET_COUNT}    Should Match Regexp    ${OVS_FLOW}    table=20.*n_packets=(\\d+).*group:${GROUP_ID}.*
    Log    ${PACKET_COUNT}
    [Return]    ${PACKET_COUNT}

Get_GRE_Port_Name
    [Arguments]    ${session}=session
    [Documentation]    Get the Port Names of the GRE tunnel
    ${resp}    RequestsLibrary.Get Request    ${session}    ${GrePortList}
    Log    ${resp.content}
    Should be equal as strings    ${resp.status_code}    200
    ${match}    get regexp matches    ${resp.content}    "tun[a-z0-9]+"
    ${GRE_PORT_NAME_LIST}    Create List
    : FOR    ${val}    IN    @{match}
    \    ${port_name}    split string    ${val}    "
    \    Append TO List    ${GRE_PORT_NAME_LIST}    ${port_name[1]}
    \    log    ${port_name}
    [Return]    ${GRE_PORT_NAME_LIST}


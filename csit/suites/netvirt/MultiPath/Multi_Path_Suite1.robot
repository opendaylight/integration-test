*** Settings ***
Documentation     Test suite for MultiPath
Suite Setup       Start Suite
Suite Teardown    End Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/VpnOperations.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/DevstackUtils.robot
Resource          ${CURDIR}/../../../libraries/OpenStackOperations.robot
Resource          ${CURDIR}/../../../libraries/OVSDB.robot
Resource          ${CURDIR}/../../../libraries/L2GatewayOperations.robot
Resource          ${CURDIR}/../../../libraries/MultiPathKeywords.robot
Library           OperatingSystem    

*** Variables ***
@{Port_List}      Network1_Port1    Network1_Port2    Network1_Port3    Network1_Port4    Network1_Port5    Network1_Port6    Network1_Port7
...               Network1_Port8
@{VmList_1}       NOVA_VM11    NOVA_VM12    NOVA_VM13    
@{VmList_2}       NOVA_VM21    NOVA_VM22    
@{VmList_3}       NOVA_VM32
@{VmList_4}       NOVA_VM23    NOVA_VM31    NOVA_VM24    NOVA_VM25    
${Network_Name}    Network1
${Subnet_Name}    Subnet1
${Router_Name}    Router1
${SUBNET_CIDR}    10.10.1.0/24
${SECURITY_GROUP}    custom-sg
${StaticIp}       100.100.100.100
${StaticIp2}      110.110.110.110
@{allowed_ip}     ${StaticIp}    ${StaticIp2}
${mask}           32
${mask_2}         24
${NoOfStaticIp}    1
${NoOfPingPackets}    15
${AddOperation}    add
${DeleteOperation}    delete
@{BucketCounts}    1    2    3    4    5
#${resp}           0
#${PASS}           ${0}
#${ExpectedPacketCount}    ${20}
#${PING_REGEXP}    (\\d+)\\% packet loss

*** Testcases ***
TC01 Verify Distribution of traffic with 3 VM on CSS1 , 2 VM on CSS2
    [Documentation]    Verify The CSC should support MP traffic splitting on L3VPN within DC across VMs located on different CSSs

    Log    Update the Router with MultiPath Route
    @{VmIpList}    Create List    ${VmIpDict.${VmList_1[0]}}    ${VmIpDict.${VmList_1[1]}}    ${VmIpDict.${VmList_1[2]}}    ${VmIpDict.${VmList_2[0]}}    ${VmIpDict.${VmList_2[1]}}
    Configure Next Hop on Router    ${Router_Name}    ${NoOfStaticIp}    ${VmIpList}
    Log    Configure Ip on Sub Interface
    : FOR    ${VmIp}    IN    @{VmIpList}
    \    Configure Ip on Sub Interface    ${Network_Name}    ${StaticIp}    ${VmIp}    ${mask_2}
    Log    Verify Ip Configured on Sub Interface
    : FOR    ${VmIp}    IN    @{VmIpList}
    \    Verify Ip Configured on Sub Interface    ${Network_Name}    ${StaticIp}    ${VmIp}
    Log    Verify the Routes in controller
    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    Log    ${CtrlFib}
    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/${mask}\\s+${OS_COMPUTE_1_IP}
    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/${mask}\\s+${OS_COMPUTE_2_IP}
    Log    Verify the ECMP flow in all Compute Nodes
    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BucketCounts[2]}    ${BucketCounts[1]}    ${StaticIp}
    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BucketCounts[1]}     ${BucketCounts[2]}    ${StaticIp}
    ${LocalVmPortList}    Create List    ${Port_List[0]}    ${Port_List[1]}    ${Port_List[2]}
    ${RemoteVmPortList}    Create List    ${Port_List[3]}    ${Port_List[4]}
    Verify VM MAC in groups    ${OS_COMPUTE_1_IP}    ${StaticIp}    ${LocalVmPortList}    ${RemoteVmPortList}
    Verify VM MAC in groups    ${OS_COMPUTE_2_IP}    ${StaticIp}    ${RemoteVmPortList}    ${LocalVmPortList}

    Verify Ping and Packet Count    ${Network_Name}    ${StaticIp}    ${VmList_4[0]}

#    ${Compute1PacketCountBeforePing}    Get table21 Packet Count    ${OS_COMPUTE_1_IP}    ${StaticIp}
#    ${Compute2PacketCountBeforePing}    Get table21 Packet Count    ${OS_COMPUTE_2_IP}    ${StaticIp}
#    Verify Ping to Sub Interface    ${StaticIp}    ${VmIpDict.${VmList[5]}}
#    ${Compute1PacketCountAfterPing}    Get table21 Packet Count    ${OS_COMPUTE_1_IP}    ${StaticIp}
#    ${Compute2PacketCountAfterPing}    Get table21 Packet Count    ${OS_COMPUTE_2_IP}    ${StaticIp}
#    Log    Check via which Compute Packets are forwarded
#    Run Keyword If    ${Compute1PacketCountAfterPing}==${Compute1PacketCountBeforePing}+${NoOfPingPackets}    Run Keywords    Log    Packets forwarded via Compute 1
#    ...    AND    Verify Packet Count    ${OS_COMPUTE_1_IP}    ${StaticIp}
#    ...    ELSE IF    ${Compute2PacketCountAfterPing}==${Compute2PacketCountBeforePing}+${NoOfPingPackets}    Run Keywords    Log    Packets forwarded via Compute 2
#    ...    AND    Verify Packet Count    ${OS_COMPUTE_2_IP}    ${StaticIp}
#    ...    ELSE    Log    Packets are not forwarded by any of the Compute Nodes

TC02 Verify Distribution of traffic - 2 VM on CSS1 , 2 VM on CSS2
    [Documentation]    Verify The CSC should support MP traffic splitting on L3VPN within DC across VMs located on different CSSs

    Log    Update the Router with MultiPath Route
    @{VmIpList}    Create List    ${VmIpDict.${VmList_1[0]}}    ${VmIpDict.${VmList_1[1]}}    ${VmIpDict.${VmList_2[0]}}    ${VmIpDict.${VmList_2[1]}}
    Configure Next Hop on Router    ${Router_Name}    ${NoOfStaticIp}    ${VmIpList}
    Log    Configure Ip on Sub Interface
    : FOR    ${VmIp}    IN    @{VmIpList} 
    \    Configure Ip on Sub Interface    ${Network_Name}    ${StaticIp}    ${VmIp}    ${mask_2}
    Log    Verify Ip Configured on Sub Interface
    : FOR    ${VmIp}    IN    @{VmIpList}
    \    Verify Ip Configured on Sub Interface    ${Network_Name}    ${StaticIp}    ${VmIp}
    Log    Verify the Routes in controller
    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    Log    ${CtrlFib}
    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/${mask}\\s+${OS_COMPUTE_1_IP}
    Should Match Regexp    ${CtrlFib}    ${StaticIp}\/${mask}\\s+${OS_COMPUTE_2_IP}

    Wait Until Keyword Succeeds    100s    20s    Run Keyword    Execute Command on VM Instance    ${Network_Name}    ${VmIpDict.${VmList_1[2]}}sudo ifconfig eth0:0 ${StaticIp} netmask 255.255.255.0 down

    Log    Verify the ECMP flow in all Compute Nodes
    Verify flows in Compute Node    ${OS_COMPUTE_1_IP}    ${BucketCounts[1]}    ${BucketCounts[1]}    ${StaticIp}
    Verify flows in Compute Node    ${OS_COMPUTE_2_IP}    ${BucketCounts[1]}    ${BucketCounts[1]}    ${StaticIp}

    ${LocalVmPortList}    Create List    ${Port_List[0]}    ${Port_List[1]}
    ${RemoteVmPortList}    Create List    ${Port_List[3]}    ${Port_List[4]}
    Verify VM MAC in groups    ${OS_COMPUTE_1_IP}    ${StaticIp}    ${LocalVmPortList}    ${RemoteVmPortList}
    Verify VM MAC in groups    ${OS_COMPUTE_2_IP}    ${StaticIp}    ${RemoteVmPortList}    ${LocalVmPortList}

    Verify Ping and Packet Count    ${Network_Name}    ${StaticIp}    ${VmList_4[0]}

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
    Tep Port Operations    ${AddOperation}
 
#    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${OS_COMPUTE_1_IP}    .    2
#    ${subnet_1}=    Set Variable    ${first_two_octets}.0.0/16
#    Set Global Variable    ${subnet_1}
#    Comment    "Configure ITM tunnel between DPNs"
#    ${Dpn1Id}    Get DPID    ${OS_COMPUTE_1_IP}
#    ${Dpn2Id}    Get DPID    ${OS_COMPUTE_2_IP}
#    ${Dpn3Id}    Get DPID    ${OS_COMPUTE_3_IP}
#    ${node_1_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_1_IP}
#    ${node_2_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_2_IP}
#    ${node_3_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_3_IP}
#    Issue Command On Karaf Console    tep:add ${Dpn1Id} ${node_1_adapter} 0 ${OS_COMPUTE_1_IP} ${subnet_1} null TZA
#    Issue Command On Karaf Console    tep:add ${Dpn2Id} ${node_2_adapter} 0 ${OS_COMPUTE_2_IP} ${subnet_1} null TZA
#    Issue Command On Karaf Console    tep:add ${Dpn3Id} ${node_3_adapter} 0 ${OS_COMPUTE_3_IP} ${subnet_1} null TZA
#    Issue Command On Karaf Console    tep:commit
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Comment    "Creating customised security Group and Rules"
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Comment    "Create Neutron Network , Subnet and Ports"
    Create Network    ${Network_Name}
    Create SubNet    ${Network_Name}    ${Subnet_Name}    ${SUBNET_CIDR}
    ${ADD_ARG}    Catenate    --security-group    ${SECURITY_GROUP}
    : FOR    ${portname}    IN    @{Port_List}
    \    Create Port    ${Network_Name}    ${portname}    sg=${SECURITY_GROUP}    allowed_address_pairs=@{allowed_ip}
    Log To Console    "Creating VM on Compute 1"
    Create Vm Instance With Port On Compute Node    ${Port_List[0]}    ${VmList_1[0]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${Port_List[1]}    ${VmList_1[1]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${Port_List[2]}    ${VmList_1[2]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Log To Console    "Creating VM on Compute 2"
    Create Vm Instance With Port On Compute Node    ${Port_List[3]}    ${VmList_2[0]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${Port_List[4]}    ${VmList_2[1]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${Port_List[5]}    ${VmList_4[0]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Log to Console    "Creating VM on Compute 3"
#    Create Vm Instance With Port On Compute Node    ${Port_List[6]}    ${VmList[6]}    ${OS_COMPUTE_3_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${Port_List[7]}    ${VmList_3[0]}    ${OS_COMPUTE_3_IP}    sg=${SECURITY_GROUP}
    Create Router    ${Router_Name}
    Add Router Interface    ${Router_Name}    ${Subnet_Name}
    &{VmIpDict}    Create Dictionary
    : FOR    ${VmName}    IN    @{VmList_1}    @{VmList_2}    @{VmList_3}    ${VmList_4[0]}
    \    ${VmIp}    Wait Until Keyword Succeeds    30s    2s    Verify Nova VM IP    ${VmName}
    \    Set To Dictionary    ${VmIpDict}    ${VmName}=${VmIp[0]}
    Log    ${VmIpDict}
    Set Global Variable    ${VmIpDict}

    Comment    Verify the VM route in fib
    ${CtrlFib}    Issue Command On Karaf Console    fib-show
    Log    ${CtrlFib}
    :FOR    ${VmName}    IN    @{VmList_1}    @{VmList_2}    @{VmList_3}    ${VmList_4[0]}
    \    Should Contain    ${CtrlFib}     ${VmIpDict.${VmName}}

Delete Setup
    [Documentation]    Clean the config created
    #Append To List    ${VmList}    NOVA_VM24    NOVA_VM25
    : FOR    ${VmName}    IN    @{VmList_1}    @{VmList_2}    @{VmList_3}    @{VmList_4}
    \    Run Keyword And Ignore Error    Delete Vm Instance    ${VmName}
    : FOR    ${portname}    IN    @{Port_List}
    \    Run Keyword And Ignore Error    Delete Port    ${portname}
    Run Keyword And Ignore Error    Update Router    ${Router_Name}    --no-routes
    Run Keyword And Ignore Error    Remove Interface    ${Router_Name}    ${Subnet_Name}
    Run Keyword And Ignore Error    Delete Router    ${Router_Name}
    Run Keyword And Ignore Error    Delete SubNet    ${Subnet_Name}
    Run Keyword And Ignore Error    Delete Network    ${Network_Name}
    Tep Port Operations    ${DeleteOperation}
#    ${Dpn1Id}    Get DPID    ${OS_COMPUTE_1_IP}
#    ${Dpn2Id}    Get DPID    ${OS_COMPUTE_2_IP}
#    ${Dpn3Id}    Get DPID    ${OS_COMPUTE_3_IP}
#    ${node_1_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_1_IP}
#    ${node_2_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_2_IP}
#    ${node_3_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_3_IP}
#    Issue Command On Karaf Console    tep:delete ${Dpn1Id} ${node_1_adapter} 0 ${OS_COMPUTE_1_IP} ${subnet_1} null TZA
#    Issue Command On Karaf Console    tep:delete ${Dpn2Id} ${node_2_adapter} 0 ${OS_COMPUTE_2_IP} ${subnet_2} null TZA
#    Issue Command On Karaf Console    tep:delete ${Dpn3Id} ${node_3_adapter} 0 ${OS_COMPUTE_3_IP} ${subnet_2} null TZA
#    Issue Command On Karaf Console    tep:commit


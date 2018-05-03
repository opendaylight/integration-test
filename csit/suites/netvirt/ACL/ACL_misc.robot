*** Settings ***
Documentation    Test Suite for Security_groups_96.2_Port_Security_groups Misc
Suite Setup    Start Suite
Suite Teardown    Stop Suite
Library    String
Library    RequestsLibrary
Library    SSHLibrary
Library    Collections
Library    BuiltIn
Resource    ../../../libraries/Utils.robot
Resource    ../../../libraries/OpenStackOperations.robot
Resource    ../../../libraries/DevstackUtils.robot
Resource    ../../../libraries/SetupUtils.robot
Resource    ../../../variables/Variables.robot

*** Variables ***

@{SECURITY_GROUP}    sg1    default
@{NETWORKS}    net_1    net_2
@{SUBNETS}    sub_1    sub_2
${ROUTER}    Router1
@{NET_1_VMS}    N1VM1
@{NET_2_VMS}    N2VM1
@{SUBNET_CIDRS}    10.0.0.0/24    20.0.0.0/24
${br_name}    br-int

*** Test Cases ***

VM1 with default Security group and VM2 having Security Group with allow all rules.Verify the ICMP traffic from VM1 to VM2 in Different subnet
    [Documentation]    This testcase verify ICMP traffic from VM1 to VM2 in Different subnet with Security groups and verify ACL flow 
    ${VM1_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}      @{NET_1_VMS}[0]
    ${VM2_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP2_CONN_ID}      @{NET_2_VMS}[0] 
    ${abc}     Wait Until Keyword Succeeds    240 sec    60 sec    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_IP}    ping -c 3 ${VM2_IP}
    Should Not Contain    ${abc}    100% packet loss
    Log    ICMP traffic successful

VM1 with default Security group and VM2 having Security Group with allow all rules.Verify the TCP/UDP packet from VM1 to VM2 in Different subnet
    [Documentation]    This testcase verify TCP/UDP traffic from VM1 to VM2 in Different subnet with Security groups and verify ACL flow
    ${VM1_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}      @{NET_1_VMS}[0]
    ${VM2_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP2_CONN_ID}      @{NET_2_VMS}[0]
    Wait Until Keyword Succeeds    240 sec    60 sec    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_IP}    nc -l -p 12345 > abc &
    Wait Until Keyword Succeeds    240 sec    60 sec    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    ${VM2_IP}    echo Opendaylight|nc ${VM1_IP} 12345 &
    ${abc}    Wait Until Keyword Succeeds    240 sec    60 sec    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_IP}    cat abc
    Should Contain    ${abc}    Opendaylight
    Log    TCP/UDP traffic successful

Verify the ACL table flow entries by deleting VM's
    ${VM1_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}      @{NET_1_VMS}[0]
    ${VM2_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP2_CONN_ID}      @{NET_2_VMS}[0]
    : FOR    ${VM1}    IN    @{NET_1_VMS}
    \    BuiltIn.Run Keyword And Ignore Error    OpenStackOperations.Delete Vm Instance    ${VM1}
    : FOR    ${VM2}    IN    @{NET_2_VMS}
    \    BuiltIn.Run Keyword And Ignore Error    OpenStackOperations.Delete Vm Instance    ${VM2}
    ${abc}    OpenStack CLI    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep table=210     
    Wait Until Keyword Succeeds    240 sec    60 sec    Should Not Contain     ${abc}    ${VM1_IP}

*** Keywords ***

Start Suite
    [Documentation]    Test Suite for SG_156
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DevstackUtils.Devstack Suite Setup
    Create Setup

Create Setup
    [Documentation]    This function is used to create required topology and configuration for testing default security groups
    OpenStackOperations.Create Nano Flavor
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create Network    @{NETWORKS}[1]
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS}[1]    @{SUBNET_CIDRS}[1]
    OpenStackOperations.Security Group Create Without Default Security Rules    @{SECURITY_GROUP}[0]
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=tcp     remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    protocol=tcp     remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=udp     remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    protocol=udp     remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=tcp    port_range_max=65535    port_range_min=1    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    protocol=tcp    port_range_max=65535    port_range_min=1    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Create Router       ${ROUTER}
    : FOR    ${interface}    IN    @{SUBNETS}
    \    OpenStackOperations.Add Router Interface    ${ROUTER}    ${interface}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=@{SECURITY_GROUP}[1] 
    ${VM1_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}      @{NET_1_VMS}[0]
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[1]    @{NET_2_VMS}[0]    ${OS_CMP2_HOSTNAME}    sg=@{SECURITY_GROUP}[0]
    ${VM2_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP2_CONN_ID}      @{NET_2_VMS}[0]

Get VM IP Address
    [Arguments]    ${conn_id}    ${vm_name}
    [Documentation]    Show information of a given VM and grep for ip address. VM name should be sent as arguments.
    SSHLibrary.Switch Connection    ${conn_id}
    ${cmd}    Set Variable    openstack server show ${vm_name} | grep "addresses" | awk '{print $4}'
    ${output} =    OpenStack CLI     ${cmd}
    @{z}    Split String    ${output}    =
    [Return]    ${z[1]}

Get Metadata1
    [Arguments]
    [Documentation]    Returns Metadata
    ${VM1_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}      @{NET_1_VMS}[0]
    ${VM2_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP2_CONN_ID}      @{NET_2_VMS}[0]
    ${grep_metadata}    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name}| grep table=210 | grep nw_src=${VM1_IP}    $    30s
    @{metadata}    Split string    ${grep_metadata}    ,
    ${index1}    get from list    ${metadata}    7
    @{complete_meta}    Split string    ${index1}    =
    ${m_data}    get from list    ${complete_meta}    1
    log    ${m_data}
    @{split_meta}    Split string    ${m_data}    /
    ${only_meta}    get from list    ${split_meta}    0
    log    ${only_meta}
    [Return]    ${only_meta}


Stop suite
   [Documentation]
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    : FOR    ${VM1}    IN    @{NET_1_VMS}
    \    BuiltIn.Run Keyword And Ignore Error    OpenStackOperations.Delete Vm Instance    ${VM1}
    : FOR    ${VM2}    IN    @{NET_2_VMS}
    \    BuiltIn.Run Keyword And Ignore Error    OpenStackOperations.Delete Vm Instance    ${VM2}
    BuiltIn.Run Keyword And Ignore Error    OpenStack CLI    openstack router remove subnet ${ROUTER} @{SUBNETS}[0]
    BuiltIn.Run Keyword And Ignore Error    OpenStack CLI    openstack router remove subnet ${ROUTER} @{SUBNETS}[1]
    BuiltIn.Run Keyword And Ignore Error    OpenStack CLI    openstack router delete ${ROUTER}
    #: FOR    ${sg}    IN    @{SECURITY_GROUP}
    BuiltIn.Run Keyword And Ignore Error    OpenStackOperations.Delete SecurityGroup    @{SECURITY_GROUP}[0]
    : FOR    ${net}    IN    @{NETWORKS}
    \    BuiltIn.Run Keyword And Ignore Error    OpenStackOperations.Delete Network    ${net}


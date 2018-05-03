*** Settings ***
Documentation    Test Suite for Security_groups_96.2_Port_Security_groups reboot
Suite Setup      Start Suite
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
Resource    ../../../libraries/OVSDB.robot

*** Variables ***

@{SECURITY_GROUP}    sg1    sg2
@{NETWORKS}    net_1    net_2
@{SUBNETS}    sub_1    sub_2
${ROUTER}    Router1
@{NET_1_VMS}    N1VM1
@{NET_2_VMS}    N2VM1
@{SUBNET_CIDRS}    10.0.0.0/24    20.0.0.0/24
${br_name}    br-int

*** Test Cases ***
Verify ICMP traffic with between two VMs with Security Group after restarting the OVSDB in Multi-DPN 
    [Documentation]    This testcase verify ICMP traffic between two VM's with security groups after restarting OVSDB
    ${VM1_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}      @{NET_1_VMS}[0]
    ${VM2_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP2_CONN_ID}      @{NET_2_VMS}[0]
    ${abc}     Wait Until Keyword Succeeds    240 sec    60 sec    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_IP}    ping -c 3 ${VM2_IP}
    Should Contain    ${abc}    0% packet loss
    Log    ICMP traffic successful now Restarting OVSDB 
    Wait Until Keyword Succeeds    240 sec    60 sec    OpenStack CLI    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    Wait Until Keyword Succeeds    240 sec    60 sec    OpenStack CLI    sudo /usr/share/openvswitch/scripts/ovs-ctl start
    Log    OVSDB successfuly restarted now checking ICMP traffic between two VM's with securiyt group after restarting OVSDB 
    ${def}     Wait Until Keyword Succeeds    240 sec    60 sec    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_IP}    ping -c 3 ${VM2_IP}
    Should Contain    ${def}    0% packet loss
    ${ijk}    OpenStack CLI    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep table=210
    Should Contain    ${ijk}    nw_src=${VM1_IP}
    Log    VM1 IP is reflecting with ACL Flow 

Verify TCP/UDP traffic with between two VMs with Security Group after restarting the OVSDB in Multi-DPN
    [Documentation]    This testcase verify TCP/UDP traffic with between two VMs with Security Group after restarting the OVSDB in Multi-DPN
    ${VM1_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}      @{NET_1_VMS}[0]
    ${VM2_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP2_CONN_ID}      @{NET_2_VMS}[0]
    Wait Until Keyword Succeeds    240 sec    60 sec    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_IP}    nc -l -p 12345 > abc &
    Wait Until Keyword Succeeds    240 sec    60 sec    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    ${VM2_IP}    echo Opendaylight|nc ${VM1_IP} 12345 &
    ${abc}    Wait Until Keyword Succeeds    240 sec    60 sec    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_IP}    cat abc
    Should Contain    ${abc}    Opendaylight
    Log    TCP/UDP traffic successful now Restarting OVSDB
    OpenStack CLI    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    OpenStack CLI    sudo /usr/share/openvswitch/scripts/ovs-ctl start
    Log    OVSDB successfuly restarted now checking TCP/UDP traffic between two VM's with securiyt group after restarting OVSDB
    Wait Until Keyword Succeeds    240 sec    60 sec    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_IP}    nc -l -p 12346 > xyz &
    Wait Until Keyword Succeeds    240 sec    60 sec    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    ${VM2_IP}    echo Opendaylight|nc ${VM1_IP} 12346 &
    ${def}    Wait Until Keyword Succeeds    240 sec    60 sec    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_IP}    cat xyz
    Should Contain    ${def}    Opendaylight
    ${ijk}    OpenStack CLI    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep table=210
    Should Contain    ${ijk}    nw_src=${VM1_IP}
    Log    VM1 IP is reflecting with ACL Flow

*** Keywords ***
Start Suite
    [Documentation]    Test Suite for SG_156
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DevstackUtils.Devstack Suite Setup
    Create Setup

Create Setup
    [Documentation]    This function is used to create required topology and configuration
    BuiltIn.Run Keyword And Ignore Error    OpenStackOperations.Create Nano Flavor 
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create Network    @{NETWORKS}[1]
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS}[1]    @{SUBNET_CIDRS}[1]
    OpenStackOperations.Security Group Create Without Default Security Rules    @{SECURITY_GROUP}[0]
    OpenStackOperations.Security Group Create Without Default Security Rules    @{SECURITY_GROUP}[1]
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=tcp    port_range_max=65535    port_range_min=1    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    protocol=tcp    port_range_max=65535    port_range_min=1    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=udp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    protocol=udp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Create Router       ${ROUTER}
    : FOR    ${interface}    IN    @{SUBNETS}
    \    OpenStackOperations.Add Router Interface    ${ROUTER}    ${interface}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=@{SECURITY_GROUP}[0] 
    ${VM1_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}      @{NET_1_VMS}[0]
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[1]    @{NET_2_VMS}[0]    ${OS_CMP2_HOSTNAME}    sg=@{SECURITY_GROUP}[0]
    ${VM2_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP2_CONN_ID}      @{NET_2_VMS}[0]

Get VM IP Address
    [Documentation]    Show information of a given VM and grep for ip address. VM name should be sent as arguments.
    [Arguments]    ${conn_id}    ${vm_name}
    SSHLibrary.Switch Connection    ${conn_id}
    ${cmd}    Set Variable    openstack server show ${vm_name} | grep "addresses" | awk '{print $4}'
    ${output} =    OpenStack CLI     ${cmd}
    @{z}    Split String    ${output}    =
    [Return]    ${z[1]}

Stop suite
   [Documentation]    This will tear down topolgy used for this suite testing 
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    : FOR    ${VM1}    IN    @{NET_1_VMS}
    \    BuiltIn.Run Keyword And Ignore Error    OpenStackOperations.Delete Vm Instance    ${VM1}
    : FOR    ${VM2}    IN    @{NET_2_VMS}
    \    BuiltIn.Run Keyword And Ignore Error    OpenStackOperations.Delete Vm Instance    ${VM2}
    BuiltIn.Run Keyword And Ignore Error    OpenStack CLI    openstack router remove subnet ${ROUTER} @{SUBNETS}[0]
    BuiltIn.Run Keyword And Ignore Error    OpenStack CLI    openstack router remove subnet ${ROUTER} @{SUBNETS}[1]
    BuiltIn.Run Keyword And Ignore Error    OpenStack CLI    openstack router delete ${ROUTER}
    : FOR    ${sg}    IN    @{SECURITY_GROUP}
    \    BuiltIn.Run Keyword And Ignore Error    OpenStackOperations.Delete SecurityGroup    ${sg}
    : FOR    ${net}    IN    @{NETWORKS}
    \    BuiltIn.Run Keyword And Ignore Error    OpenStackOperations.Delete Network    ${net}


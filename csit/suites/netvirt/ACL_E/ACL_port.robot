*** Settings ***
Documentation    Test Suite for Security_groups_96.2_Port_Security_Groups Port Related testcases 
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

@{NETWORKS}    net_1    net_2
@{PORT_NAME}    PORT1    PORT2    PORT3
@{SECURITY_GROUP}    sg1    sg2
@{NET_VMS}    VM1
@{SUBNETS}    sub1    sub2
@{SUBNET_CIDRS}    10.1.1.1/24    20.1.1.1/24
${cmd}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep table=210 || grep table=240
${cmd1}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep table=210
${cmd2}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep table=240
    
*** Test Cases ***

Verify port security is enabled by default (port_security_enabled = True) when user creates neutron port with security group
    [Documentation]    This tescase verify port security is enabled by default (port_security_enabled = True) when user creates neutron port with security group
    OpenStack CLI    openstack port show @{PORT_NAME}[1]
    ${abc}=    OpenStack CLI    openstack port show @{PORT_NAME}[1] |grep port_security_enable |awk '{print $4}'
    Log    ${abc}
    Should Contain    ${abc}    True

Verify port by disabling port_security (port_security_enabled =False) on neutron port with security group[Negative]
    [Documentation]    This tescase verify port by disabling port_security (port_security_enabled =False) on neutron port with security group[Negative]
    OpenStack CLI    openstack port create @{PORT_NAME}[2] --network @{NETWORKS}[0] --disable-port-security
    ${abc}    Run Keyword And Ignore Error    OpenStack CLI    openstack port set @{PORT_NAME}[2] --security-group sg2
    Should Contain    ${abc}    FAIL

Verify the port by Enabling the port security on neutron port with invalid security group[Negative]
    [Documentation]    This tescase verify port by Enabling the port security on neutron port with invalid security group[Negative]
    ${abc}=    Run Keyword And Ignore Error    OpenStack CLI    openstack port create @{PORT_NAME}[2] --network @{NETWORKS}[0] --security-group SG1
    Should Contain    ${abc}    FAIL

Verify port security is Enabled by default (port_security_enabled = True) at network level
    [Documentation]    This tescase verify port security is Enabled by default (port_security_enabled = True) at network level
    Show Network    @{NETWORKS}[0]
    ${abc}=    OpenStack CLI    openstack network show @{NETWORKS}[0] |grep port_security_enable |awk '{print $4}'
    Log    ${abc}
    Should Contain    ${abc}    True

Create neutron network with port "port_security_enabled=True" set to True and check for ACL flow tables 
    [Documentation]    This testcase checks ACL Flow table 210 240 when VM is spawn with Security Groups enabled
    ${abc}=     OpenStack CLI    openstack server show @{NET_VMS}[0]
    Log    ${abc}
    Should Contain    ${abc}    VM1
    ${VM1_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}      @{NET_VMS}[0]
    ${efg}=    Run Command On Remote System    ${OS_CMP1_CONN_ID}    ${cmd1}
    Should Contain    ${efg}    nw_src=${VM1_IP}
    ${xyz}=    Run Command On Remote System    ${OS_CMP1_CONN_ID}    ${cmd2} 
    Should Contain    ${xyz}    nw_dst=${VM1_IP}

Delete security group with "port_security_enabled=False" and Check ACL flows are removed for given VM’s IP
    [Documentation]    This testcase checks ACL flows are removed for given VM’s IP after removing Security group 
    OpenStackOperations.Update Port    @{PORT_NAME}[0]    --no-security-group
    OpenStackOperations.Update Port    @{PORT_NAME}[0]    --disable-port-security
    OpenStack CLI    openstack port show @{PORT_NAME}[0]
    ${abc}=    OpenStack CLI    openstack port show @{PORT_NAME}[0] |grep port_security_enable |awk '{print $4}'
    Log    ${abc}
    Should Contain    ${abc}    False
    ${VM1_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}      @{NET_VMS}[0]
    ${efg}=    Run Command On Remote System    ${OS_CMP1_CONN_ID}    ${cmd}
    Should Not Contain    ${efg}    ${VM1_IP}


*** Keywords ***
Start Suite
    [Documentation]    Test Suite for Security_groups_96.2_Port_Security_Basic
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DevstackUtils.Devstack Suite Setup
    Create Setup
    Port Security 

Create Setup
    [Documentation]    This keyword is used to create initial topology for ACL testing 
    BuiltIn.Run Keyword And Ignore Error    OpenStackOperations.Create Nano Flavor
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create SubNet     @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]
    OpenStackOperations.Security Group Create Without Default Security Rules    @{SECURITY_GROUP}[0]
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress     protocol=icmp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORT_NAME}[0]    @{SECURITY_GROUP}[0]
    OpenStackOperations.Create Vm Instance With Port    @{PORT_NAME}[0]    @{NET_VMS}[0]    sg=@{SECURITY_GROUP}[0]
    ${VM1_IP}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}      @{NET_VMS}[0]
    Log    ${VM1_IP}

Port Security
    [Documentation]    This keyword is used to create initial topology for ACL testing
    OpenStackOperations.Create Network    @{NETWORKS}[1]
    OpenStackOperations.Create SubNet     @{NETWORKS}[1]    @{SUBNETS}[1]    @{SUBNET_CIDRS}[1]
    OpenStackOperations.Security Group Create Without Default Security Rules    @{SECURITY_GROUP}[1]
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress     protocol=icmp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{PORT_NAME}[1]    @{SECURITY_GROUP}[1]
    
Get VM IP Address
    [Arguments]    ${conn_id}    ${vm_name}
    [Documentation]    Show information of a given VM and grep for ip address. VM name should be sent as arguments.
    SSHLibrary.Switch Connection    ${conn_id}
    ${cmd}    Set Variable    openstack server show ${vm_name} | grep "addresses" | awk '{print $4}'
    ${output} =    OpenStack CLI     ${cmd}
    @{z}    Split String    ${output}    =
    [Return]    ${z[1]}

Stop Suite
    [Documentation]    Delete the created VMs, ports, subnet and networks
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    BuiltIn.Run Keyword And Ignore Error     OpenStackOperations.Delete Vm Instance    @{NET_VMS}[0]
    : FOR    ${port}    IN    @{PORT_NAME}
    \    BuiltIn.Run Keyword And Ignore Error    OpenStackOperations.Delete Port    ${port}
    : FOR    ${sg}    IN    @{SECURITY_GROUP}
    \    BuiltIn.Run Keyword And Ignore Error    OpenStackOperations.Delete SecurityGroup    ${sg}
    : FOR    ${net}    IN    @{NETWORKS}
    \    BuiltIn.Run Keyword And Ignore Error    OpenStackOperations.Delete Network    ${net}


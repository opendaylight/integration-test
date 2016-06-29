*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
Suite Setup       Devstack Suite Setup Tests
Suite Teardown    Close All Connections
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot

*** Variables ***
@{NETWORKS_NAME}    network_1
@{SUBNETS_NAME}    subnet_1
@{NET_1_VM_INSTANCES}    MyFirstInstance_1    MySecondInstance_1
@{NET_1_VM_IPS}    30.0.0.3    30.0.0.4
@{GATEWAY_IPS}    30.0.0.1
@{DHCP_IPS}       30.0.0.2
@{SUBNETS_RANGE}    30.0.0.0/24
@{SECURITY_GROUPS}    SG1    SG2
@{sg_list}
@{ETHER_TYPE}    IPv4    IPv6

*** Test Cases ***
Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Create Network    ${NetworkElement}

Create Subnets For network_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    network_1    subnet_1    @{SUBNETS_RANGE}[0]

Add Ssh Allow Rule
    [Documentation]    Allow all TCP packets for testing
    Create Security Group      csit    "CSIT SSH Allow"
    Create Security Rule     ingress      tcp     1     65535     0.0.0.0/0      csit
    Create Security Rule     egress       tcp     1     65535     0.0.0.0/0      csit

Create Vm Instances For network_1
    [Documentation]    Create X Vm instances using flavor and image names for a network.
    Create Vm Instances    network_1    ${NET_1_VM_INSTANCES}     sg=csit

Ping Vm Instance1 In network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    Ping Vm From DHCP Namespace    network_1    @{NET_1_VM_IPS}[0]

Ping Vm Instance2 In network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    Ping Vm From DHCP Namespace    network_1    @{NET_1_VM_IPS}[1]

Connectivity Tests From Vm Instance1 In network_1
    [Documentation]    Logging to the vm instance1
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[1]    @{DHCP_IPS}[0]
    Log    ${dst_ip_list}
    Get OvsDebugInfo
    Test Operations From Vm Instance    network_1    @{NET_1_VM_IPS}[0]    ${dst_ip_list}

Connectivity Tests From Vm Instance2 In network_1
    [Documentation]    Logging to the vm instance2
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[0]    @{DHCP_IPS}[0]
    Log    ${dst_ip_list}
    Get OvsDebugInfo
    Test Operations From Vm Instance    network_1    @{NET_1_VM_IPS}[1]    ${dst_ip_list}

Delete Vm Instances In network_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete Default Security Group Rules
    [Documentation]    Delete the existing default security group rules before creating networks.
    ${devstack_conn_id}=       Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron security-group-rule-list
    Log    ${output}
    Delete Default Ingress SG Rule    ${ETHER_TYPE}
    Delete Default Egress SG Rule    ${ETHER_TYPE}
    ${devstack_conn_id}=       Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron security-group-rule-list
    Log    ${output}
    Get OvsDebugInfo
    Close Connection

Create Vm Instances Without Default SG in network_1
    [Documentation]    Create X Vm instances using flavor and image names for a network.
    Create Vm Instances    network_1    ${NET_1_VM_INSTANCES}
    [Teardown]    Show Debugs    ${NET_1_VM_INSTANCES}    sg=${EMPTY}

Ping Vm Instance1 Without Default SG In network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping From DHCP Should Not Succeed    network_1    @{NET_1_VM_IPS}[0]
    [Teardown]    Report_Failure_Due_To_Bug    6089

Ping Vm Instance2 Without Default SG In network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping From DHCP Should Not Succeed    network_1    @{NET_1_VM_IPS}[1]
    [Teardown]    Report_Failure_Due_To_Bug    6089

Connectivity Tests From Vm Instance1 Without Default SG In network_1
    [Documentation]    Logging to the vm instance1
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[1]    @{DHCP_IPS}[0]
    Log    ${dst_ip_list}
    Get OvsDebugInfo
    Test Operations From Vm Instance    network_1    @{NET_1_VM_IPS}[0]    ${dst_ip_list}    false
    [Teardown]    Report_Failure_Due_To_Bug    6089

Connectivity Tests From Vm Instance2 Without Default SG In network_1
    [Documentation]    Logging to the vm instance2
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[0]    @{DHCP_IPS}[0]
    Log    ${dst_ip_list}
    Get OvsDebugInfo
    Test Operations From Vm Instance    network_1    @{NET_1_VM_IPS}[1]    ${dst_ip_list}    false
    [Teardown]    Report_Failure_Due_To_Bug    6089

Delete Vm Instances Without Default SG In network_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Add Icmp Allow Rule
    [Documentation]    Allow all Icmp packets for testing
    Create Security Group      csit    "CSIT Icmp Allow"
    Create Security Rule     ingress      icmp     1     65535     0.0.0.0/0      csit_icmp
    Create Security Rule     egress       icmp     1     65535     0.0.0.0/0      csit_icmp

Create Vm Instances With Icmp SG in network_1
    [Documentation]    Create X Vm instances using flavor and image names for a network.
    Create Vm Instances    network_1    ${NET_1_VM_INSTANCES}
    [Teardown]    Show Debugs    ${NET_1_VM_INSTANCES}    sg=csit_icmp

Ping Vm Instance1 With Icmp SG In network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping From DHCP Should Not Succeed    network_1    @{NET_1_VM_IPS}[0]
    
Ping Vm Instance2 With Icmp SG In network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping From DHCP Should Not Succeed    network_1    @{NET_1_VM_IPS}[1]

Connectivity Tests From Vm Instance1 With Icmp SG In network_1
    [Documentation]    Logging to the vm instance1
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[1]    @{DHCP_IPS}[0]
    Log    ${dst_ip_list}
    Get OvsDebugInfo
    Test Operations From Vm Instance    network_1    @{NET_1_VM_IPS}[0]    ${dst_ip_list}

Connectivity Tests From Vm Instance2 With Icmp SG In network_1
    [Documentation]    Logging to the vm instance2
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[0]    @{DHCP_IPS}[0]
    Log    ${dst_ip_list}
    Get OvsDebugInfo
    Test Operations From Vm Instance    network_1    @{NET_1_VM_IPS}[1]    ${dst_ip_list}

Delete Vm Instances With Icmp SG In network_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete Sub Networks In network_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    subnet_1

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}

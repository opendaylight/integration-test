*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot

*** Variables ***
@{NETWORKS_NAME}    l2_network_1    l2_network_2
@{SUBNETS_NAME}    l2_subnet_1    l2_subnet_2
@{NET_1_VM_INSTANCES}    MyFirstInstance_1    MySecondInstance_1    MyThirdInstance_1
@{NET_2_VM_INSTANCES}    MyFirstInstance_2    MySecondInstance_2    MyThirdInstance_2
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24
${netvirt}        1

*** Test Cases ***
Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Create Network    ${NetworkElement}

Create Subnets For l2_network_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    l2_network_1    l2_subnet_1    @{SUBNETS_RANGE}[0]

Create Subnets For l2_network_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    l2_network_2    l2_subnet_2    @{SUBNETS_RANGE}[1]

Add Ssh Allow Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    Neutron Security Group Create    csit
    Neutron Security Group Rule Create    csit    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    csit    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    csit    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    csit    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    csit    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    csit    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0

Create Vm Instances For l2_network_1
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instances    l2_network_1    ${NET_1_VM_INSTANCES}    sg=csit

Create Vm Instances For l2_network_2
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instances    l2_network_2    ${NET_2_VM_INSTANCES}    sg=csit

Check Vm Instances Have Ip Address
    [Documentation]    Test case to verify that all created VMs are ready and have received their ip addresses.
    ...    We are polling first and longest on the last VM created assuming that if it's received it's address
    ...    already the other instances should have theirs already or at least shortly thereafter.
    # first, ensure all VMs are in ACTIVE state.    if not, we can just fail the test case and not waste time polling
    # for dhcp addresses
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}
    \    Wait Until Keyword Succeeds    15s    5s    Verify VM Is ACTIVE    ${vm}
    : FOR    ${index}    IN RANGE    1    5
    \    # creating 50s pool at 5s interval
    \    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Verify VMs Received DHCP Lease    @{NET_1_VM_INSTANCES}
    \    ${NET2_VM_IPS}    ${NET2_DHCP_IP}    Verify VMs Received DHCP Lease    @{NET_2_VM_INSTANCES}
    \    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}    ${NET2_VM_IPS}
    \    ${status}    ${message}    Run Keyword And Ignore Error    List Should Not Contain Value    ${VM_IPS}    None
    \    Exit For Loop If    '${status}' == 'PASS'
    \    BuiltIn.Sleep    5s
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}
    \    Write Commands Until Prompt    nova console-log ${vm}    30s
    Append To List    ${NET1_VM_IPS}    ${NET1_DHCP_IP}
    Set Suite Variable    ${NET1_VM_IPS}
    Append To List    ${NET2_VM_IPS}    ${NET2_DHCP_IP}
    Set Suite Variable    ${NET2_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET2_VM_IPS}    None
    [Teardown]    Run Keywords    Show Debugs    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}
    ...    AND    Get Test Teardown Debugs

Reading Tap Interfaces From OVS Nodes
    [Documentation]    read tap interfaces from control and computes and saves each node to a file
    ${cmd}=    Set Variable    sudo ovs-vsctl show | grep "Interface \\"tap" | awk -F "\\"" '{print$2}'
    Log    ${cmd}
    ${control_conn_id}=    Get ControlNode Connection
    Switch Connection    ${control_conn_id}
    ${OUTPUT}=    Run Command On Remote System    ${OS_CONTROL_NODE_IP}    ${cmd}
    Create File    tap_interfaces_${OS_CONTROL_NODE_IP}    ${OUTPUT}
    ${compute1_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute1_conn_id}
    ${OUTPUT}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${cmd}
    Create File    tap_interfaces_${OS_COMPUTE_1_IP}    ${OUTPUT}
    ${compute2_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute2_conn_id}
    ${OUTPUT}=    Run Command On Remote System    ${OS_COMPUTE_2_IP}    ${cmd}
    Create File    tap_interfaces_${OS_COMPUTE_2_IP}    ${OUTPUT}

Stop Odl And Delete DB
    [Documentation]    Stop ODL running
    ${odl_conn_id}=    Get OdlNode Connection
    Switch Connection    ${odl_conn_id}
    ${OUTPUT}=    Write Commands Until Prompt    ${KARAF_HOME}/bin/stop    1s
    Log    ${OUTPUT}
    ${cmd}=    Set Variable    rm -rf ${KARAF_HOME}/{data,journal,snapshots}
    Log    ${cmd}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    1s
    Log    ${OUTPUT}
    [Teardown]

Delete OF Rules
    [Documentation]    Delete Open Flow rules from os-control and computes
    ${cmd}=    Set Variable    sudo ovs-vsctl del-br br-int
    ${control_conn_id}=    Get ControlNode Connection
    Switch Connection    ${control_conn_id}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    1s
    Log    ${OUTPUT}
    ${compute1_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute1_conn_id}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    1s
    Log    ${OUTPUT}
    ${compute2_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute2_conn_id}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    1s
    Log    ${OUTPUT}
    [Teardown]

Start Odl
    [Documentation]    Start running ODL
    ${odl_conn_id}=    Get OdlNode Connection
    Switch Connection    ${odl_conn_id}
    ${OUTPUT}=    Write Commands Until Prompt    ${KARAF_HOME}/bin/start    1s
    Log    ${OUTPUT}
    Wait Until Keyword Succeeds    300s    4s    Check For Elements At URI    ${OPERATIONAL_NODES_NETVIRT}    ${netvirt}

Reconnect Ports
    [Documentation]    Re-connect tap ports
    ${cmd}=    Set Variable    sudo ovs-vsctl show
    ${control_conn_id}=    Get ControlNode Connection
    Switch Connection    ${control_conn_id}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    1s
    Log    ${OUTPUT}
    ${CONTROL_INTERFACES}=    OperatingSystem.Get File    tap_interfaces_${OS_CONTROL_NODE_IP}
    @{CONTROL_LINES}=    Split to lines    ${CONTROL_INTERFACES}
    : FOR    ${interface}    IN    @{CONTROL_LINES}
    \    Write Commands Until Prompt    sudo ovs-vsctl add-port br-int ${interface}    5s
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    1s
    Log    ${OUTPUT}
    ${compute1_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_1_IP}
    Switch Connection    ${compute1_conn_id}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    1s
    Log    ${OUTPUT}
    ${COMPUTE1_INTERFACES}=    OperatingSystem.Get File    tap_interfaces_${OS_COMPUTE_1_IP}
    @{COMPUTE1_LINES}=    Split to lines    ${COMPUTE1_INTERFACES}
    : FOR    ${interface}    IN    @{COMPUTE1_LINES}
    \    Write Commands Until Prompt    sudo ovs-vsctl add-port br-int ${interface}    5s
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    1s
    Log    ${OUTPUT}
    ${compute2_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute2_conn_id}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    1s
    Log    ${OUTPUT}
    ${COMPUTE2_INTERFACES}=    OperatingSystem.Get File    tap_interfaces_${OS_COMPUTE_2_IP}
    @{COMPUTE2_LINES}=    Split to lines    ${COMPUTE2_INTERFACES}
    : FOR    ${interface}    IN    @{COMPUTE2_LINES}
    \    Write Commands Until Prompt    sudo ovs-vsctl add-port br-int ${interface}    5s
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    1s
    Log    ${OUTPUT}

Ping Vm Instance1 In l2_network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_network_1    @{NET1_VM_IPS}[0]

Ping Vm Instance2 In l2_network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_network_1    @{NET1_VM_IPS}[1]

Ping Vm Instance3 In l2_network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_network_1    @{NET1_VM_IPS}[2]

Ping Vm Instance1 In l2_network_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_network_2    @{NET2_VM_IPS}[0]

Ping Vm Instance2 In l2_network_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_network_2    @{NET2_VM_IPS}[1]

Ping Vm Instance3 In l2_network_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_network_2    @{NET2_VM_IPS}[2]

Connectivity Tests From Vm Instance1 In l2_network_1
    [Documentation]    Login to the vm instance and test some operations
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}

Connectivity Tests From Vm Instance2 In l2_network_1
    [Documentation]    Login to the vm instance and test operations
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[1]    ${NET1_VM_IPS}

Connectivity Tests From Vm Instance3 In l2_network_1
    [Documentation]    Login to the vm instance and test operations
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[2]    ${NET1_VM_IPS}

Connectivity Tests From Vm Instance1 In l2_network_2
    [Documentation]    Login to the vm instance and test operations
    Test Operations From Vm Instance    l2_network_2    @{NET2_VM_IPS}[0]    ${NET2_VM_IPS}

Connectivity Tests From Vm Instance2 In l2_network_2
    [Documentation]    Logging to the vm instance using generated key pair.
    Test Operations From Vm Instance    l2_network_2    @{NET2_VM_IPS}[1]    ${NET2_VM_IPS}

Connectivity Tests From Vm Instance3 In l2_network_2
    [Documentation]    Login to the vm instance using generated key pair.
    Test Operations From Vm Instance    l2_network_2    @{NET2_VM_IPS}[2]    ${NET2_VM_IPS}

Delete A Vm Instance
    [Documentation]    Delete Vm instances using instance names.
    Delete Vm Instance    MyFirstInstance_1

No Ping For Deleted Vm
    [Documentation]    Check non reachability of deleted vm instances by pinging to them.
    ${output}=    Ping From DHCP Should Not Succeed    l2_network_1    @{NET_1_VM_IPS}[0]

Delete Vm Instances In l2_network_1
    [Documentation]    Delete Vm instances using instance names in l2_network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete Vm Instances In l2_network_2
    [Documentation]    Delete Vm instances using instance names in l2_network_2.
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    [Teardown]    Run Keywords    Show Debugs    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}
    ...    AND    Get Test Teardown Debugs

Delete Sub Networks In l2_network_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    l2_subnet_1

Delete Sub Networks In l2_network_2
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    l2_subnet_2

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}

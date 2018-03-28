*** Settings ***
Documentation     Test suite to verify various Ethernet Packets behaviour in Security Group, including negative tests.
...               These test cases are not so relevant for transparent mode, so each test case will be tagged with
...               "skip_if_transparent" to allow any underlying keywords to return with a PASS without risking
...               a false failure. The real value of this suite will be in stateful mode.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Force Tags        skip_if_${SECURITY_GROUP_MODE}
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../../libraries/DevstackUtils.robot
Resource          ../../../../libraries/OpenStackOperations.robot
Resource          ../../../../libraries/OpenStackOperations_legacy.robot
Resource          ../../../../libraries/SetupUtils.robot
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/KarafKeywords.robot

*** Variables ***
@{SECURITY_GROUP}    sg-remote    sg_1    sg_2
@{NETWORKS_NAME}    network_1    network_2
@{SUBNETS_NAME}    l2_subnet_1    l2_subnet_2
@{NET_1_VM_INSTANCES}    MyFirstInstance_1    MySecondInstance_1
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24
${password}       cubswin:)
${user}           fedora

*** test cases ***
Create Zone
    [Documentation]    Create Availabilityzone create for test suite
    ${zone1}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    zone_name=compute1    aggregate_name=Host1
    ${zone2}=    Create Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    zone_name=compute2    aggregate_name=Host2
    Set Suite Variable    ${zone1}
    Set Suite Variable    ${zone2}
    Should Not Contain    ${zone1}    None
    Should Not Contain    ${zone2}    None

Create Instance
    [Documentation]    Create VM instance with openstack key pair python installled
    Create Network    @{NETWORKS_NAME}[0]
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    Neutron Security Group Create    @{SECURITY_GROUP}[1]
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    ${VM1}=    Create List    @{NET_1_VM_INSTANCES}[0]
    ${VM2}=    Create List    @{NET_1_VM_INSTANCES}[1]
    Create Vm Instances    network_1    ${VM1}    image=fedora    flavor=fedora    sg=@{SECURITY_GROUP}[1]    additional_args=--availability-zone ${zone2} --key-name vm_keys
    Create Vm Instances    network_1    ${VM2}    image=cirros    flavor=cirros    sg=@{SECURITY_GROUP}[1]    additional_args=--availability-zone ${zone1}
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM Is ACTIVE    ${vm}
    ${First_VM}    Collect IP    @{NET_1_VM_INSTANCES}[0]
    ${Second_VM}    Collect IP    @{NET_1_VM_INSTANCES}[1]
    Set Suite Variable    ${First_VM}
    Should Not Contain    ${First_VM}    None
    : FOR    ${vm}    IN    @{VM1}
    \    Poll VM UP Boot Status    ${vm}

install scapy
    [Documentation]    Copy Scapy tool to execute the script
    ${First_VM}    Collect IP    @{NET_1_VM_INSTANCES}[0]
    Set Suite Variable    ${First_VM}
    Should Not Contain    ${First_VM}    None
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} scp -i ~/vm_key -r /tmp/scapy-master ${user}@@{First_VM}[0]:/home/fedora    (yes/no)?
    ${output}=    Write Commands Until Expected Prompt    yes    known hosts.
    Sleep    20s
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    cd scapy-master/    $
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 setup.py install    $    60s
    Log    ${output}
    Write    exit

TCP Ingress/Egress Ethertype 0x8847
    [Documentation]    create Tcp Ingress/Egress rules and test 0x8847 type packets are blocked
    ${First_VM}    Collect IP    @{NET_1_VM_INSTANCES}[0]
    ${Second_VM}    Collect IP    @{NET_1_VM_INSTANCES}[1]
    Set Suite Variable    ${First_VM}
    Set Suite Variable    ${Second_VM}
    Should Not Contain    ${First_VM}    None
    Should Not Contain    ${Second_VM}    None
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${output}=    Write Commands Until Expected Prompt    cat <<EOF >ether_0x8847.py    >
    ${output}=    Write Commands Until Expected Prompt    import sys    >
    ${output}=    Write Commands Until Expected Prompt    from scapy.all import *    >
    ${output}=    Write Commands Until Expected Prompt    from scapy.all import srp,Ether,ARP,conf\n    >
    ${output}=    Write Commands Until Expected Prompt    sendp(Ether(type=0x8847)/IP(dst="@{Second_VM}[0]",ttl=(1,4)), iface="eth0")    >
    ${output}=    Write Commands Until Expected Prompt    EOF    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x8847.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

ICMP Ingress/Egress Ethertype 0x8847
    [Documentation]    create ICMP Ingress/Egress rules and test 0x8847 type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=icmp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=icmp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x8847.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

UDP Ingress/Egress Ethertype 0x8847
    [Documentation]    create UDP Ingress/Egress rules and test 0x8847 type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x8847.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

ANY Ingress/Egress Ethertype 0x8847
    [Documentation]    create ANY Ingress/Egress rules and test 0x8847 type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x8847.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

TCP Ingress/Egress Ethertype 0x8848
    [Documentation]    create Tcp Ingress/Egress rules and test 0x8848 type packets are blocked
    ${First_VM}    Collect IP    @{NET_1_VM_INSTANCES}[0]
    ${Second_VM}    Collect IP    @{NET_1_VM_INSTANCES}[1]
    Set Suite Variable    ${First_VM}
    Set Suite Variable    ${Second_VM}
    Should Not Contain    ${First_VM}    None
    Should Not Contain    ${Second_VM}    None
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${output}=    Write Commands Until Expected Prompt    cat <<EOF >ether_0x8848.py    >
    ${output}=    Write Commands Until Expected Prompt    import sys    >
    ${output}=    Write Commands Until Expected Prompt    from scapy.all import *    >
    ${output}=    Write Commands Until Expected Prompt    from scapy.all import srp,Ether,ARP,conf\n    >
    ${output}=    Write Commands Until Expected Prompt    sendp(Ether(type=0x8848)/IP(dst="@{Second_VM}[0]",ttl=(1,4)), iface="eth0")    >
    ${output}=    Write Commands Until Expected Prompt    EOF    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x8848.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

ICMP Ingress/Egress Ethertype 0x8848
    [Documentation]    create ICMP Ingress/Egress rules and test 0x8848 type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=icmp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=icmp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x8848.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

UDP Ingress/Egress Ethertype 0x8848
    [Documentation]    create UDP Ingress/Egress rules and test 0x8848 type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x8848.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

ANY Ingress/Egress Ethertype 0x8848
    [Documentation]    create UDP Ingress/Egress rules and test 0x8848 type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x8848.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

TCP Ingress/Egress Ethertype 0x88cc
    [Documentation]    create Tcp Ingress/Egress rules and test 0x88cc type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${output}=    Write Commands Until Expected Prompt    cat <<EOF >ether_0x88cc.py    >
    ${output}=    Write Commands Until Expected Prompt    import sys    >
    ${output}=    Write Commands Until Expected Prompt    from scapy.all import *    >
    ${output}=    Write Commands Until Expected Prompt    from scapy.all import srp,Ether,ARP,conf\n    >
    ${output}=    Write Commands Until Expected Prompt    sendp(Ether(type=0x88cc)/IP(src="@{First_VM}[0]",dst="@{Second_VM}[0]",ttl=(1,4)), iface="eth0")    >
    ${output}=    Write Commands Until Expected Prompt    EOF    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x88cc.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

ICMP Ingress/Egress Ethertype 0x88cc
    [Documentation]    create ICMP Ingress/Egress rules and test 0x88cc type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=icmp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=icmp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x88cc.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

UDP Ingress/Egress Ethertype 0x88cc
    [Documentation]    create UDP Ingress/Egress rules and test 0x88cc type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x88cc.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

ANY Ingress/Egress Ethertype 0x88cc
    [Documentation]    create ANY Ingress/Egress rules and test 0x88cc type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x88cc.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

TCP Ingress/Egress Ethertype 0x8100
    [Documentation]    create Tcp Ingress/Egress rules and test 0x8100 type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${output}=    Write Commands Until Expected Prompt    cat <<EOF >ether_0x8100.py    >
    ${output}=    Write Commands Until Expected Prompt    import sys    >
    ${output}=    Write Commands Until Expected Prompt    from scapy.all import *    >
    ${output}=    Write Commands Until Expected Prompt    from scapy.all import srp,Ether,ARP,conf\n    >
    ${output}=    Write Commands Until Expected Prompt    sendp(Ether(type=0x8100)/IP(src="@{First_VM}[0]",dst="@{Second_VM}[0]",ttl=(1,4)), iface="eth0")    >
    ${output}=    Write Commands Until Expected Prompt    EOF    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x8100.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

ICMP Ingress/Egress Ethertype 0x8100
    [Documentation]    create ICMP Ingress/Egress rules and test 0x8100 type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=icmp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=icmp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x8100.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

UDP Ingress/Egress Ethertype 0x8100
    [Documentation]    create UDP Ingress/Egress rules and test 0x8100 type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x8100.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

ANY Ingress/Egress Ethertype 0x8100
    [Documentation]    create ANY Ingress/Egress rules and test 0x8100 type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x8100.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

TCP Ingress/Egress Ethertype 0x0806
    [Documentation]    create Tcp Ingress/Egress rules and test 0x0806 type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${output}=    Write Commands Until Expected Prompt    cat <<EOF >ether_0x0806.py    >
    ${output}=    Write Commands Until Expected Prompt    import sys    >
    ${output}=    Write Commands Until Expected Prompt    from scapy.all import *    >
    ${output}=    Write Commands Until Expected Prompt    from scapy.all import srp,Ether,ARP,conf\n    >
    ${output}=    Write Commands Until Expected Prompt    result = sr1(ARP(op=ARP.who_has, psrc='@{First_VM}[0]', pdst='@{Second_VM}[0]'))    >
    ${output}=    Write Commands Until Expected Prompt    EOF    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep arp | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x0806.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep arp | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

ICMP Ingress/Egress Ethertype 0x0806
    [Documentation]    create ICMP Ingress/Egress rules and test 0x0806 type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=icmp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=icmp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep arp | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x0806.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep arp | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

UDP Ingress/Egress Ethertype 0x0806
    [Documentation]    create UDP Ingress/Egress rules and test 0x0806 type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep arp | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x0806.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep arp | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

ANY Ingress/Egress Ethertype 0x0806
    [Documentation]    create ANY Ingress/Egress rules and test 0x0806 type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep arp | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x0806.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep arp | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

TCP Ingress/Egress Ethertype 0x814c
    [Documentation]    create Tcp Ingress/Egress rules and test 0x814c type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${output}=    Write Commands Until Expected Prompt    cat <<EOF >ether_0x814c.py    >
    ${output}=    Write Commands Until Expected Prompt    import sys    >
    ${output}=    Write Commands Until Expected Prompt    from scapy.all import *    >
    ${output}=    Write Commands Until Expected Prompt    from scapy.all import srp,Ether,ARP,conf\n    >
    ${output}=    Write Commands Until Expected Prompt    sendp(Ether(type=0x814c)/IP(src="@{First_VM}[0]",dst="@{Second_VM}[0]",ttl=(1,4)), iface="eth0")    >
    ${output}=    Write Commands Until Expected Prompt    EOF    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x814c.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

ICMP Ingress/Egress Ethertype 0x814c
    [Documentation]    create ICMP Ingress/Egress rules and test 0x814c type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=icmp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=icmp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x814c.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

UDP Ingress/Egress Ethertype 0x814c
    [Documentation]    create UDP Ingress/Egress rules and test 0x814c type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x814c.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

ANY Ingress/Egress Ethertype 0x814c
    [Documentation]    create ANY Ingress/Egress rules and test 0x814c type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x814c.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

TCP Ingress/Egress Ethertype 0x8181
    [Documentation]    create Tcp Ingress/Egress rules and test 0x8181 type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${output}=    Write Commands Until Expected Prompt    cat <<EOF >ether_0x8181.py    >
    ${output}=    Write Commands Until Expected Prompt    import sys    >
    ${output}=    Write Commands Until Expected Prompt    from scapy.all import *    >
    ${output}=    Write Commands Until Expected Prompt    from scapy.all import srp,Ether,ARP,conf\n    >
    ${output}=    Write Commands Until Expected Prompt    sendp(Ether(type=0x8181)/IP(src="@{First_VM}[0]",dst="@{Second_VM}[0]",ttl=(1,4)), iface="eth0")    >
    ${output}=    Write Commands Until Expected Prompt    EOF    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x8181.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

ICMP Ingress/Egress Ethertype 0x8181
    [Documentation]    create ICMP Ingress/Egress rules and test 0x8181 type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=icmp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=icmp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x8181.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

UDP Ingress/Egress Ethertype 0x8181
    [Documentation]    create UDP Ingress/Egress rules and test 0x8181 type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x8181.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

ANY Ingress/Egress Ethertype 0x8181
    [Documentation]    create ANY Ingress/Egress rules and test 0x8181 type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x8181.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

TCP Ingress/Egress Ethertype 0x880b
    [Documentation]    create Tcp Ingress/Egress rules and test 0x880b type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${output}=    Write Commands Until Expected Prompt    cat <<EOF >ether_0x880b.py    >
    ${output}=    Write Commands Until Expected Prompt    import sys    >
    ${output}=    Write Commands Until Expected Prompt    from scapy.all import *    >
    ${output}=    Write Commands Until Expected Prompt    from scapy.all import srp,Ether,ARP,conf\n    >
    ${output}=    Write Commands Until Expected Prompt    sendp(Ether(type=0x880b)/IP(src="@{First_VM}[0]",dst="@{Second_VM}[0]",ttl=(1,4)), iface="eth0")    >
    ${output}=    Write Commands Until Expected Prompt    EOF    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x880b.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

ICMP Ingress/Egress Ethertype 0x880b
    [Documentation]    create ICMP Ingress/Egress rules and test 0x880b type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=icmp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=icmp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x880b.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

UDP Ingress/Egress Ethertype 0x880b
    [Documentation]    create UDP Ingress/Egress rules and test 0x880b type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x880b.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}

ANY Ingress/Egress Ethertype 0x880b
    [Documentation]    create ANY Ingress/Egress rules and test 0x880b type packets are blocked
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    network_1
    Log    ${net_id}
    Delete All Security Group Rules    @{SECURITY_GROUP}[1]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[1]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    ingress
    Create ANY SecurityGroup Rule    @{SECURITY_GROUP}[1]    egress
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -i ~/vm_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@@{First_VM}[0] -o UserKnownHostsFile=/dev/null    $
    ${compute_conn_id}=    Get ComputeNode Connection    ${OS_COMPUTE_2_IP}
    Switch Connection    ${compute_conn_id}
    ${stdout}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${stdout}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo python3 ether_0x880b.py    $    timeout=90s
    Switch Connection    ${compute_conn_id}
    ${flows}=    Execute Command    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep drop | awk '{print $4}'
    Log    ${flows}
    Should Not Be Equal    ${stdout}    ${flows}
    [Teardown]    Run Keywords    Get Test Teardown Debugs
    ...    AND    Clear L2_Network

Destroy Zone
    [Documentation]    Delete the Availabilityzone create for test suite
    Delete Availabilityzone    hypervisor_ip=${OS_COMPUTE_1_IP}    aggregate_name=Host1
    Delete Availabilityzone    hypervisor_ip=${OS_COMPUTE_2_IP}    aggregate_name=Host2

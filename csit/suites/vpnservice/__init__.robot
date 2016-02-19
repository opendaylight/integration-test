*** Settings ***
Documentation     Test suite for Inventory Scalability
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary
Library           ../../libraries/Common.py
Variables         ../../variables/Variables.py
Resource          ../../libraries/Utils.robot
Variables         ../../variables/vpnservice/neutron_service.py


*** Keywords ***
Start Suite
    [Documentation]    Test suit for vpn service using mininet OF13 and OVS 2.3.1
    Log    Start the tests
    ${mininet1_conn_id_1}=    Open Connection    ${MININET}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Global Variable    ${mininet1_conn_id_1}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    #SSHLibrary.Login    ${MININET_USER}    ${MININET_PASSWORD}
    Execute Command    sudo ovs-vsctl del-br BR1
    Execute Command    sudo ovs-vsctl add-br BR1
    Execute Command    sudo ovs-vsctl set bridge BR1 protocols=OpenFlow13
    ${swcmd1}=    Catenate    SEPARATOR=    sudo ovs-vsctl set-controller BR1 tcp:    ${CONTROLLER}    :6633
    Execute Command    ${swcmd1}
    ${output}    Execute Command    sudo ifconfig BR1 up
    ${swcmd1}=    Catenate    SEPARATOR=    sudo ovs-vsctl set-manager tcp:    ${CONTROLLER}    :6640
    Execute Command    ${swcmd1}

    ${output}    Execute Command    sudo ip netns add ns1
    Log    ${output}
    ${resp}    Sleep    3
    Execute Command    sudo ip link add tap-port-1 type veth peer name tap79ad0001-19
    Execute Command    sudo ovs-vsctl add-port BR1 tap79ad0001-19
    Execute Command    sudo ip link set tap-port-1 netns ns1
    Execute Command    sudo ip netns exec ns1 ip link set dev tap-port-1 up
    Execute Command    sudo ip link set dev tap79ad0001-19 up
    Execute Command    sudo ip netns exec ns1 ifconfig tap-port-1 20.1.1.2 netmask 255.255.255.0
    Execute Command    sudo ip netns exec ns1 ifconfig tap-port-1 hw ether 00:16:3E:19:F7:8B
    Execute Command    sudo ip netns exec ns1 ip link set dev lo up
    Execute Command    sudo ip netns exec ns1 ip route add default via 20.1.1.1
    Execute Command    sudo ip netns add ns2
    Execute Command    sudo ip link add tap-port-2 type veth peer name tap79ad0002-19
    Execute Command    sudo ovs-vsctl add-port BR1 tap79ad0002-19
    Execute Command    sudo ip link set tap-port-2 netns ns2
    Execute Command    sudo ip netns exec ns2 ip link set dev tap-port-2 up
    Execute Command    sudo ip link set dev tap79ad0002-19 up
    Execute Command    sudo ip netns exec ns2 ifconfig tap-port-2 20.1.1.3 netmask 255.255.255.0
    Execute Command    sudo ip netns exec ns2 ifconfig tap-port-2 hw ether 00:16:3E:BB:9B:0F
    Execute Command    sudo ip netns exec ns2 ip link set dev lo up
    Execute Command    sudo ip netns exec ns2 ip route add default via 20.1.1.1

    #${output}    Execute Command    ${create_ns_setup_dpn_1}
    #Log    ${output}
    #${resp}    Sleep    3
    ${output}    Execute Command    sudo ovs-vsctl show
    #${output}=    SSHLibrary.Read Until Prompt
    Log    ${output}
    ${resp}    Sleep    3
    ${output}    Execute Command    sudo ip netns list
    ${resp}    Sleep    3
    Log    ${output}
    ${mininet2_conn_id_1}=    Open Connection    ${MININET1}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Global Variable    ${mininet2_conn_id_1}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Execute Command    sudo ovs-vsctl del-manager
    Execute Command    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    Execute Command    sudo rm -rf /etc/openvswitch/conf.db
    Execute Command    sudo /usr/share/openvswitch/scripts/ovs-ctl start
    ${resp}    Sleep    30
    Execute Command    sudo ovs-vsctl del-br BR2
    Execute Command    sudo ovs-vsctl add-br BR2
    Execute Command    sudo ovs-vsctl set bridge BR2 protocols=OpenFlow13
    ${swcmd1}=    Catenate    SEPARATOR=    sudo ovs-vsctl set-controller BR2 tcp:    ${CONTROLLER}    :6633
    Execute Command    ${swcmd1}
    ${output}    Execute Command    sudo ifconfig BR2 up
    ${swcmd1}=    Catenate    SEPARATOR=    sudo ovs-vsctl set-manager tcp:    ${CONTROLLER}    :6640
    Execute Command    ${swcmd1}

    Execute Command    sudo ip netns add ns3
    Execute Command    sudo ip link add tap-port-3 type veth peer name tap79ad0003-19
    Execute Command    sudo ovs-vsctl add-port BR2 tap79ad0003-19
    Execute Command    sudo ip link set tap-port-3 netns ns3
    Execute Command    sudo ip netns exec ns3 ip link set dev tap-port-3 up
    Execute Command    sudo ip link set dev tap79ad0003-19 up
    Execute Command    sudo ip netns exec ns3 ifconfig tap-port-3 30.1.1.4 netmask 255.255.255.0
    Execute Command    sudo ip netns exec ns3 ifconfig tap-port-3 hw ether 00:16:3E:92:F5:F8
    Execute Command    sudo ip netns exec ns3 ip link set dev lo up
    Execute Command    sudo ip netns exec ns3 ip route add default via 30.1.1.1
    Execute Command    sudo ip netns add ns4
    Execute Command    sudo ip link add tap-port-4 type veth peer name tap79ad0004-19
    Execute Command    sudo ovs-vsctl add-port BR2 tap79ad0004-19
    Execute Command    sudo ip link set tap-port-4 netns ns4
    Execute Command    sudo ip netns exec ns4 ip link set dev tap-port-4 up
    Execute Command    sudo ip link set dev tap79ad0004-19 up
    Execute Command    sudo ip netns exec ns4 ifconfig tap-port-4 30.1.1.5 netmask 255.255.255.0
    Execute Command    sudo ip netns exec ns4 ifconfig tap-port-4 hw ether 00:16:3E:19:57:58
    Execute Command    sudo ip netns exec ns4 ip link set dev lo up
    Execute Command    sudo ip netns exec ns4 ip route add default via 30.1.1.1

    #${output}    Execute Command    ${create_ns_setup_dpn_2}
    #Log    ${output}
    #${resp}    Sleep    3
    ${output}    Execute Command    sudo ovs-vsctl show
    ${resp}    Sleep    3
    Log    ${output}
    ${output}    Execute Command    ip netns list
    ${resp}    Sleep    3
    Log    ${output}

Stop Suite
    Log    Stop the tests
    Switch Connection    ${mininet2_conn_id_1}
    Log    ${mininet2_conn_id_1}
    Execute Command    sudo ovs-vsctl del-br BR2

    Execute Command    sudo ip netns delete ns1
    Execute Command    sudo ip netns delete ns2

    #Execute Command    ${delete_ns_setup_dpn_1}
    # Write    exit
    Close Connection
    Switch Connection    ${mininet1_conn_id_1}
    Log    ${mininet1_conn_id_1}
    Execute Command    sudo ovs-vsctl del-br BR1

    Execute Command    sudo ip netns delete ns3
    Execute Command    sudo ip netns delete ns4

    #Execut Command    ${delete_ns_setup_dpn_2}
    # Write    exit
    Close Connection
    Log    StopNameSpace




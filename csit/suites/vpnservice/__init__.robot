*** Settings ***
Documentation     Test suite for Inventory Scalability
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary
Library           ../../libraries/Common.py
Variables         ../../variables/Variables.py
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/OVSDB.robot
Variables         ../../variables/vpnservice/neutron_service.py

*** Keywords ***
Start Suite
    [Documentation]    Test suit for vpn service using OVS 2.3.1
    Log    Start the tests
    ${tool_system1_conn_id_1}=    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Global Variable    ${tool_system1_conn_id_1}
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Execute Command    sudo ovs-vsctl del-br BR1
    Execute Command    sudo ovs-vsctl add-br BR1
    Execute Command    sudo ovs-vsctl set bridge BR1 protocols=OpenFlow13
    ${swcmd1}=    Catenate    SEPARATOR=    sudo ovs-vsctl set-controller BR1 tcp:    ${CONTROLLER}    :6633
    Execute Command    ${swcmd1}
    ${output}    Execute Command    sudo ifconfig BR1 up
    ${swcmd1}=    Catenate    SEPARATOR=    sudo ovs-vsctl set-manager tcp:    ${CONTROLLER}    :6640
    Execute Command    ${swcmd1}

    ${output}    Execute Command    ${create_ns_setup_dpn_1}
    Log    ${output}
    ${output}    Execute Command    sudo ovs-vsctl show
    #${output}=    SSHLibrary.Read Until Prompt
    Log    ${output}
    ${output}    Execute Command    sudo /sbin/ip netns list
    Log    ${output}
    ${output}    Execute Command    sudo /sbin/ifconfig
    Log    ${output}

    ${tool_system2_conn_id_1}=    Open Connection    ${TOOLS_SYSTEM_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Global Variable    ${tool_system2_conn_id_1}
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    Execute Command    sudo ovs-vsctl add-br BR2
    Execute Command    sudo ovs-vsctl set bridge BR2 protocols=OpenFlow13
    ${swcmd1}=    Catenate    SEPARATOR=    sudo ovs-vsctl set-controller BR2 tcp:    ${CONTROLLER}    :6633
    Execute Command    ${swcmd1}
    ${output}    Execute Command    sudo ifconfig BR2 up
    ${swcmd1}=    Catenate    SEPARATOR=    sudo ovs-vsctl set-manager tcp:    ${CONTROLLER}    :6640
    Execute Command    ${swcmd1}

    ${output}    Execute Command    ${create_ns_setup_dpn_2}
    Log    ${output}
    ${output}    Execute Command    sudo ovs-vsctl show
    Log    ${output}
    ${output}    Execute Command    sudo /sbin/ip netns list
    Log    ${output}
    ${output}    Execute Command    sudo /sbin/ifconfig
    Log    ${output}

Stop Suite
    Log    Stop the tests
    Switch Connection    ${tool_system2_conn_id_1}
    Log    ${tool_system2_conn_id_1}

    ${output}    Execute Command    sudo ovs-vsctl show
    ${output}    Execute Command    sudo /sbin/ip netns list
    Log    ${output}
    ${output}    Execute Command    sudo /sbin/ifconfig
    Log    ${output}
    ${output}    Execute Command    sudo /sbin/ip netns exec ns3 /sbin/ifconfig
    Log    ${output}
    ${output}    Execute Command    sudo /sbin/ip netns exec ns4 /sbin/ifconfig
    Log    ${output}

    Execute Command    sudo ovs-vsctl del-br BR2
    Execute Command    ${delete_ns_setup_dpn_1}
    ${output}    Execute Command    sudo /sbin/ip netns list
    Log    ${output}
    Close Connection

    Switch Connection    ${tool_system1_conn_id_1}
    Log    ${tool_system1_conn_id_1}
    ${output}    Execute Command    sudo ovs-vsctl show
    Log    ${output}
    ${output}    Execute Command    sudo /sbin/ip netns list
    Log    ${output}
    ${output}    Execute Command    sudo /sbin/ifconfig
    Log    ${output}

    Execute Command    sudo ovs-vsctl del-br BR1

    Execute Command    ${delete_ns_setup_dpn_2}
    ${output}    Execute Command    sudo /sbin/ip netns list
    Log    ${output}
    Close Connection
    Log    StopNameSpace

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
    ${output}    Execute Command    ${create_ns_setup_dpn_1}
    Log    ${output}
    ${resp}    Sleep    3
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
    ${output}    Execute Command    ${create_ns_setup_dpn_2}
    Log    ${output}
    ${resp}    Sleep    3
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
    Execute Command    ${delete_ns_setup_dpn_1}
    # Write    exit
    Close Connection
    Switch Connection    ${mininet1_conn_id_1}
    Log    ${mininet1_conn_id_1}
    Execute Command    sudo ovs-vsctl del-br BR1
    Execute Command    ${delete_ns_setup_dpn_2}
    # Write    exit
    Close Connection
    Log    StopNameSpace




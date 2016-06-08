*** Settings ***
Documentation     Test suite for Inventory Scalability
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary
Variables         ../../variables/Variables.py
Resource          ../../libraries/Utils.robot
Library           re
Library           Collections
Library           string
Resource          ../../libraries/KarafKeywords.robot

*** Variables ***

*** Keywords ***
Start Suite
    [Documentation]    Test suit for vpn service using mininet OF13 and OVS 2.3.1
    ${mininet1_conn_id_1}=    Open Connection    ${MININET}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Global Variable    ${mininet1_conn_id_1}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Log    ${mininet1_conn_id_1}
    Execute Command    sudo ovs-vsctl add-br BR1
    Execute Command    sudo ovs-vsctl set bridge BR1 protocols=OpenFlow13
    Execute Command    sudo ovs-vsctl set-controller BR1 tcp:${CONTROLLER}:6633
    Execute Command    sudo ifconfig BR1 up
    Execute Command    sudo ovs-vsctl set-manager tcp:${CONTROLLER}:6640
    Execute Command    sudo ovs-vsctl add-port BR1 tapab123 -- set Interface tapab123 type=tap
    ${output_1}    Execute Command    sudo ovs-vsctl show
    Log    ${output_1}
    Log    >>>>>Switch 2 configuration <<<<<
    ${mininet2_conn_id_1}=    Open Connection    ${MININET1}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Global Variable    ${mininet2_conn_id_1}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Log    ${mininet2_conn_id_1}
    Execute Command    sudo ovs-vsctl add-br BR2
    Execute Command    sudo ovs-vsctl set bridge BR2 protocols=OpenFlow13
    Execute Command    sudo ovs-vsctl set-controller BR2 tcp:${CONTROLLER}:6633
    Execute Command    sudo ifconfig BR2 up
    Execute Command    sudo ovs-vsctl set-manager tcp:${CONTROLLER}:6640
    ${output_2}    Execute Command    sudo ovs-vsctl show
    Log    ${output_2}

Stop Suite
    Log    Stop the tests
    Switch Connection    ${mininet1_conn_id_1}
    Log    ${mininet1_conn_id_1}
    Execute Command    sudo ovs-vsctl del-br BR1
    Execute Command    sudo ovs-vsctl del-manager
    Write    exit
    Switch Connection    ${mininet2_conn_id_1}
    Log    ${mininet2_conn_id_1}
    Execute Command    sudo ovs-vsctl del-br BR2
    Execute Command    sudo ovs-vsctl del-manager
    Write    exit

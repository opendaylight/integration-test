*** Settings ***
Documentation     Test suite for Inventory Scalability
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot
Variables         ../../../variables/vpnservice/neutron_service.py

*** Keywords ***
Start Suite
    [Documentation]    Test suit for vpn service using OVS 2.3.1
    Log    Start the tests
    ${tool_system1_conn_id_1}=    Open Connection    ${OS_COMPUTE_1_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Global Variable    ${tool_system1_conn_id_1}
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Execute Command    sudo ovs-vsctl add-br br-int
    Execute Command    sudo ovs-vsctl set bridge br-int protocols=OpenFlow13
    ${swcmd1}=    Catenate    SEPARATOR=    sudo ovs-vsctl set-controller br-int tcp:    ${CONTROLLER}    :6633
    Execute Command    ${swcmd1}
    ${output}    Execute Command    sudo ifconfig br-int up
    ${swcmd1}=    Catenate    SEPARATOR=    sudo ovs-vsctl set-manager tcp:    ${CONTROLLER}    :6640
    Execute Command    ${swcmd1}

    ${tool_system2_conn_id_1}=    Open Connection    ${OS_COMPUTE_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Global Variable    ${tool_system2_conn_id_1}
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Clean OVSDB Test Environment    ${OS_COMPUTE_1_IP}
    Execute Command    sudo ovs-vsctl add-br br-int
    Execute Command    sudo ovs-vsctl set bridge br-int protocols=OpenFlow13
    ${swcmd1}=    Catenate    SEPARATOR=    sudo ovs-vsctl set-controller br-int tcp:    ${CONTROLLER}    :6633
    Execute Command    ${swcmd1}
    ${output}    Execute Command    sudo ifconfig br-int up
    ${swcmd1}=    Catenate    SEPARATOR=    sudo ovs-vsctl set-manager tcp:    ${CONTROLLER}    :6640
    Execute Command    ${swcmd1}

Stop Suite
    Log    Stop the tests
    Switch Connection    ${tool_system2_conn_id_1}
    Log    ${tool_system2_conn_id_1}
    Execute Command    sudo ovs-vsctl del-br br-int 
    Execute Command    sudo ovs-vsctl del-manager 
    Close Connection

    Switch Connection    ${tool_system1_conn_id_1}
    Log    ${tool_system1_conn_id_1}
    Execute Command    sudo ovs-vsctl del-br br-int 
    Execute Command    sudo ovs-vsctl del-manager 
    Close Connection

*** Settings ***
Documentation     Test suite for Genius Modules
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           Collections
Library           SSHLibrary
Library           re
Library           string
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/Utils.robot
Resource          ../../variables/Variables.robot

*** Variables ***

*** Keywords ***
Start Suite
    [Documentation]    Test suit for vpn service using mininet OF13 and OVS 2.3.1
    Log    Start the tests
    ${conn_id_1}=    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Global Variable    ${conn_id_1}
    KarafKeywords.Setup_Karaf_Keywords
    ${karaf_debug_enabled}    BuiltIn.Get_Variable_Value    ${KARAF_DEBUG}    ${False}
    BuiltIn.run_keyword_if    ${karaf_debug_enabled}    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set DEBUG org.opendaylight.genius
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Log    ${conn_id_1}
    Execute Command    sudo ovs-vsctl add-br BR1
    Execute Command    sudo ovs-vsctl set bridge BR1 protocols=OpenFlow13
    Execute Command    sudo ovs-vsctl set-controller BR1 tcp:${ODL_SYSTEM_IP}:6633
    Execute Command    sudo ifconfig BR1 up
    Execute Command    sudo ovs-vsctl add-port BR1 tap8ed70586-6c -- set Interface tap8ed70586-6c type=tap
    Execute Command    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    ${output_1}    Execute Command    sudo ovs-vsctl show
    Log    ${output_1}
    ${check}    Wait Until Keyword Succeeds    30    10    check establishment    ${conn_id_1}    6633
    log    ${check}
    ${check_2}    Wait Until Keyword Succeeds    30    10    check establishment    ${conn_id_1}    6640
    log    ${check_2}
    Log    >>>>>Switch 2 configuration <<<<<
    ${conn_id_2}=    Open Connection    ${TOOLS_SYSTEM_2_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Global Variable    ${conn_id_2}
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Log    ${conn_id_2}
    Execute Command    sudo ovs-vsctl add-br BR2
    Execute Command    sudo ovs-vsctl set bridge BR2 protocols=OpenFlow13
    Execute Command    sudo ovs-vsctl set-controller BR2 tcp:${ODL_SYSTEM_IP}:6633
    Execute Command    sudo ifconfig BR2 up
    Execute Command    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    ${output_2}    Execute Command    sudo ovs-vsctl show
    Log    ${output_2}

Stop Suite
    Log    Stop the tests
    Switch Connection    ${conn_id_1}
    Log    ${conn_id_1}
    Execute Command    sudo ovs-vsctl del-br BR1
    Execute Command    sudo ovs-vsctl del-manager
    Write    exit
    close connection
    Switch Connection    ${conn_id_2}
    Log    ${conn_id_2}
    Execute Command    sudo ovs-vsctl del-br BR2
    Execute Command    sudo ovs-vsctl del-manager
    Write    exit
    close connection

check establishment
    [Arguments]    ${conn_id}    ${port}
    Switch Connection    ${conn_id}
    ${check_establishment}    Execute Command    netstat -anp | grep ${port}
    Should contain    ${check_establishment}    ESTABLISHED
    [Return]    ${check_establishment}

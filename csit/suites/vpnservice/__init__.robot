*** Settings ***
Documentation     Test suite for Inventory Scalability
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary
Library           ../../libraries/Common.py
Variables         ../../variables/Variables.py
Library           ../../libraries/Openstack.py    ${CONTROLLER}    WITH NAME    ops1
Resource          ../../libraries/Utils.robot
Variables         ../../variables/vpnservice/neutron_service.py

*** Variables ***
${START_NS_SCRIPT}    ns_setup.sh
${STOP_NS_SCRIPT}    stop_ns.sh

*** Keywords ***
Start Suite
    [Documentation]    Test suit for vpn service using mininet OF13 and OVS 2.3.1
    Log    Start the tests
    ${mininet1_conn_id_1}=    Open Connection    ${MININET}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Global Variable    ${mininet1_conn_id_1}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Execute Command    sudo ovs-vsctl del-br BR1
    Execute Command    sudo ovs-vsctl add-br BR1
    Execute Command    sudo ovs-vsctl set bridge BR1 protocols=OpenFlow13
    ${swcmd1}=    Catenate    SEPARATOR=    sudo ovs-vsctl set-controller BR1 tcp:    ${CONTROLLER}    :6633
    Execute Command    ${swcmd1}
    ${output}    Execute Command    sudo ifconfig BR1 up
    ${swcmd1}=    Catenate    SEPARATOR=    sudo ovs-vsctl set-manager tcp:    ${CONTROLLER}    :6640
    Execute Command    ${swcmd1}
    ${output}    Execute Command    sudo ovs-vsctl show
    #    Read Until    \\\>
    #${output}=    SSHLibrary.Read Until Prompt
    Log    ${output}
    ${resp}    Sleep    3
    ${mininet2_conn_id_1}=    Open Connection    ${MININET1}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Global Variable    ${mininet2_conn_id_1}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Execute Command    sudo ovs-vsctl del-br BR2
    Execute Command    sudo ovs-vsctl add-br BR2
    Execute Command    sudo ovs-vsctl set bridge BR2 protocols=OpenFlow13
    ${swcmd1}=    Catenate    SEPARATOR=    sudo ovs-vsctl set-controller BR2 tcp:    ${CONTROLLER}    :6633
    Execute Command    ${swcmd1}
    ${output}    Execute Command    sudo ifconfig BR2 up
    ${swcmd1}=    Catenate    SEPARATOR=    sudo ovs-vsctl set-manager tcp:    ${CONTROLLER}    :6640
    Execute Command    ${swcmd1}
    ${output}    Execute Command    sudo ovs-vsctl show
    ${resp}    Sleep    3
    #    Read Until    \\\>
    Log    ${output}
    ${resp}    Open Connection And Log In Server And Run Script    ${OVS_HOST1}    ${OVS_HOST1_USER}    ${OVS_HOST1_PWD}    ${START_NS_SCRIPT}
    ${resp}    Open Connection And Log In Server And Run Script    ${OVS_HOST2}    ${OVS_HOST2_USER}    ${OVS_HOST2_PWD}    ${START_NS_SCRIPT}
    ${resp}    ops1.Delete All Net
    Log    ${resp}

Stop Suite
    Log    Stop the tests
    Switch Connection    ${mininet2_conn_id_1}
    Log    ${mininet2_conn_id_1}
    Execute Command    sudo ovs-vsctl del-br BR2
    Write    exit
    Switch Connection    ${mininet1_conn_id_1}
    Log    ${mininet1_conn_id_1}
    Execute Command    sudo ovs-vsctl del-br BR1
    Write    exit
    Log    StopNameSpace
    ${resp}    Open Connection And Log In Server And Run Script    ${OVS_HOST1}    ${OVS_HOST1_USER}    ${OVS_HOST1_PWD}    ${STOP_NS_SCRIPT}
    ${resp}    Open Connection And Log In Server And Run Script    ${OVS_HOST2}    ${OVS_HOST2_USER}    ${OVS_HOST2_PWD}    ${STOP_NS_SCRIPT}


Open Connection And Log In Server And Run Script
    [Arguments]    ${HOST}    ${USERNAME}    ${PASSWORD}    ${scriptname}
    ${connection_handle}=    SSHLibrary.Open Connection    ${HOST}    timeout=30s
    Set Client Configuration    prompt=>
    SSHLibrary.Login    ${USERNAME}    ${PASSWORD}
    ${scriptcmd}=    Catenate    SEPARATOR=    ${USER_HOME}    ${NS_SCRIPT_PATH}    ${scriptname}
    SSHLibrary.Write    ${scriptcmd}
    Set Client Configuration    prompt=>
    Log To Console    ${scriptcmd}
    ${output}=    SSHLibrary.Read Until Prompt
    Close Connection
    [Return]    ${output}

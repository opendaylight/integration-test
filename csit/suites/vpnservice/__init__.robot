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
${START_NS_SCRIPT1}    ns_setup_1.sh
${NS_SCRIPT_PATH}    ${CURDIR}/../../scripts/

*** Keywords ***
Start Suite
    [Documentation]    Test suit for vpn service using mininet OF13 and OVS 2.3.1
    Log    Start the tests
    ${ns_script_start_vm1}=    Catenate    SEPARATOR=    ${NS_SCRIPT_PATH}    ${START_NS_SCRIPT}
    ${ns_script_start_vm2}=    Catenate    SEPARATOR=    ${NS_SCRIPT_PATH}    ${START_NS_SCRIPT1}
    ${ns_script_stop}=    Catenate    SEPARATOR=    ${NS_SCRIPT_PATH}    ${STOP_NS_SCRIPT}
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
    ${output}    Execute Command    sudo ovs-vsctl show
    #    Read Until    \\\>
    #${output}=    SSHLibrary.Read Until Prompt
    Log    ${output}
    ${resp}    Sleep    3
    ${mininet2_conn_id_1}=    Open Connection    ${MININET1}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Global Variable    ${mininet2_conn_id_1}
    #SSHLibrary.Login    ${MININET_USER}    ${MININET_PASSWORD}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    SSHLibrary.Put File    ${ns_script_start_vm2}    mode=0777
    SSHLibrary.Put File    ${ns_script_stop}    mode=0777
    #Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
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
    ${output}    Execute Command    sudo ovs-vsctl show
    ${resp}    Sleep    3
    #    Read Until    \\\>
    Log    ${output}
    ${resp}    Open Connection And Log In Server And Run Script    ${MININET}    ${MININET_USER}    ${MININET_PASSWORD}    ${ns_script_start_vm1}
    ${remote_ns_start}    Catenate    SEPARATOR=    ./    ${START_NS_SCRIPT1}
    ${resp}    Open Connection And Log In Server And Run Script    ${MININET1}    ${MININET_USER}    ${MININET_PASSWORD}    ${remote_ns_start}
    ${resp}    ops1.Delete All Net
    Log    ${resp}

Stop Suite
    Log    Stop the tests
    ${ns_script_stop}=    Catenate    SEPARATOR=    ${NS_SCRIPT_PATH}    ${STOP_NS_SCRIPT}
    Switch Connection    ${mininet2_conn_id_1}
    Log    ${mininet2_conn_id_1}
    Execute Command    sudo ovs-vsctl del-br BR2
    # Write    exit
    Close Connection
    Switch Connection    ${mininet1_conn_id_1}
    Log    ${mininet1_conn_id_1}
    Execute Command    sudo ovs-vsctl del-br BR1
    # Write    exit
    Close Connection
    Log    StopNameSpace
    ${resp}    Open Connection And Log In Server And Run Script    ${MININET}    ${MININET_USER}    ${MININET_PASSWORD}    ${ns_script_stop}
    ${remote_ns_stop}    Catenate    SEPARATOR=    ./    ${STOP_NS_SCRIPT}
    ${resp}    Open Connection And Log In Server And Run Script    ${MININET1}    ${MININET_USER}    ${MININET_PASSWORD}    ${remote_ns_stop}


Open Connection And Log In Server And Run Script
    [Arguments]    ${HOST}    ${USERNAME}    ${PASSWORD}    ${scriptname}
    ${connection_handle}=    SSHLibrary.Open Connection    ${HOST}    timeout=30s
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    SSHLibrary.Set_Default_Configuration    prompt=${ODL_SYSTEM_PROMPT}
    #SSHLibrary.Login    ${USERNAME}    ${PASSWORD}
    ${ipnetcmd}=    Catenate    sudo    ${scriptname}
    ${output}    Execute Command    ${ipnetcmd}
    ${ipnetcmd1}=    Catenate    ip netns list
    ${output}    Execute Command    ${ipnetcmd1}
    #${output}=    SSHLibrary.Read Until Prompt
    Log to Console    ${output}
    Close Connection
    [Return]    ${output}

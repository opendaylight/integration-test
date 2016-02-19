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
Resource          ../../libraries/MininetKeywords.robot

*** Variables ***
${START_NS_SCRIPT}    sudo sh ns_setup.sh
${STOP_NS_SCRIPT}    sudo sh stop_ns.sh
${START_NS_SCRIPT1}    sudo sh ns_setup_1.sh
${NSSCRIPT_PATH}    ${CURDIR}/../../scripts

*** Keywords ***
Start Suite
    [Documentation]    Test suit for vpn service using mininet OF13 and OVS 2.3.1
    Log    Start the tests
    Clean Mininet System    ${MININET}
    Clean Mininet System    ${MININET1}
    ${mininet1_conn_id_1}=    Open Connection    ${MININET}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Global Variable    ${mininet1_conn_id_1}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    #SSHLibrary.Login    ${MININET_USER}    ${MININET_PASSWORD}
    Put File    ${NSSCRIPT_PATH}/stop_ns.sh    mode=0755
    Put File    ${NSSCRIPT_PATH}/ns_setup.sh    mode=0755
    Write    ${STOP_NS_SCRIPT}
    ${output}=    Read Until    ${DEFAULT_LINUX_PROMPT}
    Log    ${output}
    Write    ${START_NS_SCRIPT}
    ${output}=    Read Until    ${DEFAULT_LINUX_PROMPT}
    Log    ${output}
    ${res}    Sleep    5
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
    #SSHLibrary.Login    ${MININET_USER}    ${MININET_PASSWORD}
    Put File    ${NSSCRIPT_PATH}/stop_ns.sh    mode=0755
    Put File    ${NSSCRIPT_PATH}/ns_setup_1.sh    mode=0755
    Execute Command    sudo ovs-vsctl del-manager
    Execute Command    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    Execute Command    sudo rm -rf /etc/openvswitch/conf.db
    Execute Command    sudo /usr/share/openvswitch/scripts/ovs-ctl start
    ${resp}    Sleep    30
    Write    ${STOP_NS_SCRIPT}
    ${output}=    Read Until    ${DEFAULT_LINUX_PROMPT}
    Log    ${output}
    Write    ${START_NS_SCRIPT1}
    ${output}=    Read Until    ${DEFAULT_LINUX_PROMPT}
    Log    ${output}
    ${res}    Sleep    5
    #Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
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
    ${resp}    ops1.Delete All Net
    Log    ${resp}

Stop Suite
    Log    Stop the tests
    Switch Connection    ${mininet2_conn_id_1}
    Write    ${STOP_NS_SCRIPT}
    Log    ${mininet2_conn_id_1}
    Execute Command    sudo ovs-vsctl del-br BR2
    Write    exit
    Switch Connection    ${mininet1_conn_id_1}
    Log    ${mininet1_conn_id_1}
    Write    ${STOP_NS_SCRIPT}
    Execute Command    sudo ovs-vsctl del-br BR1
    Write    exit
    Log    StopNameSpace




*** Settings ***
Documentation       Test suite for MD-SAL LACP mininet OF13

Library             SSHLibrary
Variables           ../../../variables/Variables.py

Suite Setup         Start Suite
Suite Teardown      Stop Suite


*** Variables ***
${start}    sudo mn --custom LACP_custom1.py --switch ovsk,protocols=OpenFlow13
${bond}     "/etc/modprobe.d/bonding.conf"


*** Keywords ***
Start Suite
    Log    Start mininet
    ${mininet_session_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Suite Variable    ${mininet_session_id}
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Execute Command    sudo ovs-vsctl set-manager ptcp:6633
    Execute Command    sudo rm -rf ${bond}
    Put File    ${CURDIR}/LACP_custom1.py
    Put File    ${CURDIR}/h1-bond0.sh
    Put File    ${CURDIR}/h2-bond0.sh
    Put File    ${CURDIR}/m
    Put File    ${CURDIR}/bonding.conf
    Execute Command    sudo cp bonding.conf ${bond}
    Execute Command    sed -i -- 's/CONTROLLER/${ODL_SYSTEM_IP}/g' LACP_custom1.py
    Write    ${start}
    Read Until    mininet>

Stop Suite
    Log    Stop mininet
    Switch Connection    ${mininet_session_id}
    Read
    Write    exit
    Execute Command    sed -i -- 's/${ODL_SYSTEM_IP}/CONTROLLER/g' LACP_custom1.py
    Execute Command    sudo rm -rf ${bond}
    Close Connection

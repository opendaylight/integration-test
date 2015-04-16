*** Settings ***
Documentation     Test suite for MD-SAL LACP  mininet OF13
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary
Variables         ../../../variables/Variables.py

*** Variables ***
${start}=   sudo mn --custom LACP_custom1.py --switch ovsk,protocols=OpenFlow13
${bond}=     "/etc/modprobe.d/bonding.conf"

*** Keywords ***
Start Suite
    Log    Start mininet
    Open Connection   ${MININET}     prompt=${PROMPT}
    Login With Public Key    ${MININET_USER}   ${USER_HOME}/.ssh/id_rsa   any
    Write    sudo ovs-vsctl set-manager ptcp:6633
    Write    sudo mn -c
    Read Until    ${PROMPT}
    Write    sudo rm -rf ${bond}
    Put File    ${CURDIR}/LACP_custom1.py
    Put File    ${CURDIR}/h1-bond0.sh
    Put File    ${CURDIR}/h2-bond0.sh
    Put File    ${CURDIR}/m
    Put File    ${CURDIR}/bonding.conf
    Write    sudo cp bonding.conf ${bond}
    Write    sed -i -- 's/CONTROLLER/${CONTROLLER}/g' LACP_custom1.py
    Write    ${start}
    Read Until     mininet>

Stop Suite
    Log    Stop mininet
    Read
    Write    exit
    Read Until    ${PROMPT}
    Write    sed -i -- 's/${CONTROLLER}/CONTROLLER/g' LACP_custom1.py
    Write    sudo rm -rf ${bond}
    Read Until    ${PROMPT}
    Close Connection

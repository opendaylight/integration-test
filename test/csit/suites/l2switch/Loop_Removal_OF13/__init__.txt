*** Settings ***
Documentation     Test suite for L2switch's LoopRemoval using mininet OF13
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library     SSHLibrary
Library     OperatingSystem

*** Variables ***
${start}=  sudo mn --controller=remote,ip=${CONTROLLER} --custom customtopo.py --topo ring --switch ovsk,protocols=OpenFlow13

** Keywords ***
Start Suite
    Log    Start mininet
    Open Connection   ${MININET}     prompt=>	timeout=30
    Login With Public Key    ${MININET_USER}   ${USER_HOME}/.ssh/id_rsa   any
    Write    sudo ovs-vsctl set-manager ptcp:6644
    Read Until    >
    Write    sudo mn -c
    Read Until    >
    Read Until    >
    Read Until    >
    Put File    ${CURDIR}/../topologies/customtopo.py
    Write    ${start}
    Read Until    mininet>
    Sleep 	10
Stop Suite
    Log    Stop mininet
    Read
    Write    exit
    Read Until    >
    Read
    Close Connection

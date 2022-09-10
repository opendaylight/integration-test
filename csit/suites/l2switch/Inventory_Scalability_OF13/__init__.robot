*** Settings ***
Documentation       Test suite for Inventory Scalability

Library             SSHLibrary
Library             ../../../libraries/Common.py
Variables           ../../../variables/Variables.py

Suite Setup         Start Suite
Suite Teardown      Stop Suite


*** Variables ***
${start}
...         sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo tree,${TOPO_TREE_DEPTH},${TOPO_TREE_FANOUT} --switch ovsk,protocols=OpenFlow13


*** Keywords ***
Start Suite
    Log    Start mininet
    ${TOPO_TREE_DEPTH}    Convert To Integer    ${TOPO_TREE_DEPTH}
    ${TOPO_TREE_FANOUT}    Convert To Integer    ${TOPO_TREE_FANOUT}
    ${numnodes}    Num Of Nodes    ${TOPO_TREE_DEPTH}    ${TOPO_TREE_FANOUT}
    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${numnodes*3}
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    Execute Command    sudo mn -c
    Write    ${start}
    Read Until    mininet>

Stop Suite
    Log    Stop mininet
    Read
    Write    exit
    Read Until    >
    Close Connection

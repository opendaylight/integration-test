*** Settings ***
Documentation     Test suite for Inventory Scalability
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py

*** Variables ***
${start}          sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo tree,${TOPO_TREE_DEPTH},${TOPO_TREE_FANOUT} --switch ovsk,protocols=OpenFlow13

*** Keywords ***
Start Suite
    Log    Start mininet
    ${TOPO_TREE_DEPTH}    Convert To Integer    ${TOPO_TREE_DEPTH}
    ${TOPO_TREE_FANOUT}    Convert To Integer    ${TOPO_TREE_FANOUT}
    ${numnodes}    Num Of Nodes    ${TOPO_TREE_DEPTH}    ${TOPO_TREE_FANOUT}
    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${numnodes*3}
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Write    sudo ovs-vsctl set-manager ptcp:6644
    Read Until    ${DEFAULT_LINUX_PROMPT}
    Write    sudo mn -c
    Read Until    ${DEFAULT_LINUX_PROMPT}
    Read Until    ${DEFAULT_LINUX_PROMPT}
    Read Until    ${DEFAULT_LINUX_PROMPT}
    Write    ${start}
    Read Until    mininet>

Stop Suite
    Log    Stop mininet
    Read
    Write    exit
    Read Until    ${DEFAULT_LINUX_PROMPT}
    Close Connection

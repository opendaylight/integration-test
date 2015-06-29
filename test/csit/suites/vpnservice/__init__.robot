*** Settings ***
Documentation     Test suite for Inventory Scalability
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary
Library           ../../libraries/Common.py
Variables         ../../variables/Variables.py
Resource          ../../libraries/Utils.txt

*** Variables ***
${start1}         sudo mn \ --controller=remote,ip=${CONTROLLER} --custom custom.py --topo Switch1 --switch ovsk,protocols=OpenFlow13
${start2}         sudo mn \ --controller=remote,ip=${CONTROLLER} --custom custom.py --topo Switch2 --switch ovsk,protocols=OpenFlow13

*** Keywords ***
Start Suite
    [Documentation]    Test suit for vpn service using mininet OF13 and OVS 2.3.1
    Log    Start the tests
    Clean Mininet System
    ${mininet1_conn_id_1}=    Open Connection    ${MININET}    prompt=${LINUX_PROMPT}    timeout=30s
    Set Global Variable    ${mininet1_conn_id_1}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/id_rsa    any
    Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    Put File    ${CURDIR}/custom.py
    Write    ${start1}
    Read Until    mininet>
    ${mininet1_conn_id_2}=    Open Connection    ${MININET}    prompt=${LINUX_PROMPT}    timeout= 30s
    Set Global Variable    ${mininet1_conn_id_2}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/id_rsa    any
    Execute Command    sudo ovs-vsctl add-port s1 s1-gre1 -- set interface s1-gre1 type=gre options:remote_ip=${MININET1} options:local_ip=${MININET}
    ${output}    Execute Command    sudo ovs-vsctl show
    Log    ${output}
    Execute Command    sudo ovs-ofctl add-flow s1 -O OpenFlow13 arp,actions=FLOOD
    ${mininet2_conn_id_1}=    Open Connection    ${MININET1}    prompt=${LINUX_PROMPT}    timeout=30s
    Set Global Variable    ${mininet2_conn_id_1}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/id_rsa    any
    Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    Put File    ${CURDIR}/custom.py
    Write    ${start2}
    Read Until    mininet>
    ${mininet2_conn_id_2}=    Open Connection    ${MININET1}    prompt=${LINUX_PROMPT}    timeout= 30s
    Set Global Variable    ${mininet2_conn_id_2}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/id_rsa    any
    Execute Command    sudo ovs-vsctl add-port s2 s2-gre1 -- set interface s2-gre1 type=gre options:remote_ip=${MININET} options:local_ip=${MININET1}
    ${output}    Execute Command    sudo ovs-vsctl show
    Log    ${output}
    Execute Command    sudo ovs-ofctl add-flow s2 -O OpenFlow13 arp,actions=FLOOD

Stop Suite
    Log    Stop the tests
    Switch Connection    ${mininet1_conn_id_1}
    Read
    Write    exit
    Read Until    ${LINUX_PROMPT}
    Close Connection
    Switch Connection    ${mininet1_conn_id_2}
    Close Connection
    Switch Connection    ${mininet2_conn_id_1}
    Read
    Write    exit
    Read Until    ${LINUX_PROMPT}
    Close Connection
    Switch Connection    ${mininet2_conn_id_2}
    Close Connection

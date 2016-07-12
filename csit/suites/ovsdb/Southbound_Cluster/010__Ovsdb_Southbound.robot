*** Settings ***
Documentation     Test suite for Ovsdb Southbound Cluster - Owner failover and recover
Suite Setup       Create Controller Sessions
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../libraries/ClusterOvsdb.robot
Resource          ../../../libraries/ClusterKeywords.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${BRIDGE1}    br1
${BRIDGE2}    br2
${BRIDGE3}    br3

*** Test Cases ***
Connecting an OVS instance to the controller
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    Wait Until Keyword Succeeds    5s    1s    Verify OVS Reports Connected

Create bridge1 manually
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-br ${BRIDGE1}

Create bridge2 manually
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-br ${BRIDGE2}

Create bridge3 manually
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-br ${BRIDGE3}

Reboot an OVS instance to the controller
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    reboot

Connecting an OVS instance to the controller
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    Wait Until Keyword Succeeds    5s    1s    Verify OVS Reports Connected

Delete bridge1 manually
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-br ${BRIDGE1}

Delete bridge2 manually
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-br ${BRIDGE2}

Delete bridge3 manually
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-br ${BRIDGE3}

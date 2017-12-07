*** Settings ***
Documentation     Test suite for ODL Upgrade. It is assumed that OLD + OpenStack
...               integrated environment is deployed and ready.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           SSHLibrary
Library           DiffLibrary
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          UpgradeUtils.robot

*** Variables ***
${before_restart}    /tmp/before_restart.txt
${after_restart}    /tmp/after_restart.txt
${ODL_STOP}       sudo service opendaylight stop
${ODL_START}      sudo service opendaylight start
# ${TOOLS_SYSTEM_IP} = IP address of primary system hosting testing tools.

*** Test Cases ***
Create setup
    [Documentation]    Create 2 VXLAN networks, subnets with 2 VMs each and a router. Ping all 4 VMs.
    Create resources and check connectivity

Dump br-int flows
    [Documentation]    Dump br-int flows and log them to log file ${before_start}
    Get flows from br-int    ${OS_CONTROL_NODE_IP}    ${before_restart}
    Run Keyword If    1 < ${NUM_OS_SYSTEM}    Get flows from br-int    ${OS_COMPUTE_1_IP}    ${before_restart}
    Run Keyword If    2 < ${NUM_OS_SYSTEM}    Get flows from br-int    ${OS_COMPUTE_2_IP}    ${before_restart}

Stop ODL
    [Documentation]    Stop ODL
    ${output}    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${ODL_STOP}
    Log    ${output}

Disconnect OVS
    [Documentation]    Delete OVS manager, controller and groups and tun ports
    Delete OVS manager    ${OS_CONTROL_NODE_IP}
    Run Keyword If    1 < ${NUM_OS_SYSTEM}    Delete OVS manager    ${OS_COMPUTE_1_IP}
    Run Keyword If    2 < ${NUM_OS_SYSTEM}    Delete OVS manager    ${OS_COMPUTE_1_IP}
    Delete OVS controller    ${OS_CONTROL_NODE_IP}
    Run Keyword If    1 < ${NUM_OS_SYSTEM}    Delete OVS controller    ${OS_COMPUTE_1_IP}
    Run Keyword If    2 < ${NUM_OS_SYSTEM}    Delete OVS controller    ${OS_COMPUTE_2_IP}
    Delete gropus    ${OS_CONTROL_NODE_IP}
    Run Keyword If    1 < ${NUM_OS_SYSTEM}    Delete groups    ${OS_COMPUTE_1_IP}
    Run Keyword If    2 < ${NUM_OS_SYSTEM}    Delete groups    ${OS_COMPUTE_2_IP}
    Delete tun ports    ${OS_CONTROL_NODE_IP}
    Run Keyword If    1 < ${NUM_OS_SYSTEM}    tun ports    ${OS_COMPUTE_1_IP}
    Run Keyword If    2 < ${NUM_OS_SYSTEM}    tun ports    ${OS_COMPUTE_2_IP}

Delete setup
    [Documentation]    Delete resources created in above step
    Delete resources

Wipe cache
    [Documentation]    Delete journal/, snapshots
    ${journal}=    OperatingSystem.Remove Directory    ${CONTROLLER} /opt/opendaylight/journal
    Log    ${journal}
    ${snapshot}=    OperatingSystem.Remove Directory    ${CONTROLLER} /opt/opendaylight/snapshot
    Log    ${snapshot}

Block ports
    [Documentation]    Block OVS and OVSDB ports untill full sync
    Modify Iptables On Remote System    ${ODL_SYSTEM_IP}    -A INPUT -p tcp --destination-port 6640 -j DROP
    Modify Iptables On Remote System    ${ODL_SYSTEM_IP}    -A INPUT -p tcp --destination-port 6653 -j DROP
    Modify Iptables On Remote System    ${ODL_SYSTEM_IP}    -A INPUT -p tcp --destination-port 6633 -j DROP

Start ODL
    [Documentation]    Start ODL
    ${output}    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    ${ODL_START}
    Log    ${output}

Unblock ports
    [Documentation]    Unblock openflow related ports
    ## TODO -    how to do?

Trigger Full sync
    [Documentation]    Trigger full sync from networking-odl
    ## TODO -    how to do?

Create setup
    [Documentation]    Create 2 VXLAN networks, subnotes with 2 VMs each and a router. Ping all 4 VMs.
    Create resources and check connectivity

Dump br-int flows
    [Documentation]    Dump br-int flows and log them to log file ${after_start}
    Get flows from br-int    ${OS_CONTROL_NODE_IP}    ${after_restart}
    Run Keyword If    1 < ${NUM_OS_SYSTEM}    Get flows from br-int    ${OS_COMPUTE_1_IP}    ${after_restart}
    Run Keyword If    2 < ${NUM_OS_SYSTEM}    Get flows from br-int    ${OS_COMPUTE_2_IP}    ${after_restart}

Compare flows before and after result
    Diff Files    ${before_restart}    {after_restart}

*** Settings ***
Documentation     Library containing Keywords used for SXP cluster testing
Library           RequestsLibrary
Library           ./Sxp.py
Resource          ./SxpLib.robot
Resource          ./ClusterManagement.robot
Resource          ./SetupUtils.robot
Resource          ../variables/Variables.robot

*** Variables ***
@{SHARD_OPER_LIST}    inventory    topology    default    entity-ownership
@{SHARD_CONF_LIST}    inventory    topology    default
${DEVICE_SESSION}    device_1
${DEVICE_NODE_ID}    1.1.1.1
${CLUSTER_NODE_ID}    2.2.2.2
${SXP_LOG_LEVEL}    INFO
@{SXP_PACKAGE}    org.opendaylight.sxp

*** Keywords ***
Setup SXP Cluster Session
    [Documentation]    Create sessions asociated with SXP cluster setup
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    BuiltIn.Wait Until Keyword Succeeds    120    10    SxpLib.Prepare SSH Keys On Karaf    ${ODL_SYSTEM_${i+1}_IP}
    \    SxpLib.Setup SXP Session    controller${i+1}    ${ODL_SYSTEM_${i+1}_IP}
    ClusterManagement.ClusterManagement_Setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SetupUtils.Setup_Logging_For_Debug_Purposes_On_List_Or_All    ${SXP_LOG_LEVEL}    ${SXP_PACKAGE}

Clean SXP Cluster Session
    [Documentation]    Clean sessions asociated with SXP cluster setup
    ClusterManagement.Flush_Iptables_From_List_Or_All
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    BuiltIn.Wait Until Keyword Succeeds    240    1    ClusterManagement.Sync_Status_Should_Be_True    ${i+1}
    SxpLib.Clean SXP Session
    SetupUtils.Setup_Logging_For_Debug_Purposes_On_List_Or_All    INFO    ${SXP_PACKAGE}

Check Shards Status
    [Documentation]    Check Status for all shards in SXP application.
    ClusterManagement.Check_Cluster_Is_In_Sync
    ClusterManagement.Verify_Leader_Exists_For_Each_Shard    shard_name_list=${SHARD_OPER_LIST}    shard_type=operational
    ClusterManagement.Verify_Leader_Exists_For_Each_Shard    shard_name_list=${SHARD_CONF_LIST}    shard_type=config

Setup SXP Cluster
    [Arguments]    ${peer_mode}=listener
    [Documentation]    Setup and connect SXP cluster topology
    SxpLib.Add Node    ${DEVICE_NODE_ID}    ip=0.0.0.0    session=${DEVICE_SESSION}
    BuiltIn.Wait Until Keyword Succeeds    20    1    SxpLib.Check Node Started    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}    system=${TOOLS_SYSTEM_IP}
    ...    ip=${EMPTY}
    ${cluster_mode} =    Sxp.Get Opposing Mode    ${peer_mode}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    SxpLib.Add Connection    version4    ${peer_mode}    ${ODL_SYSTEM_${i+1}_IP}    64999    ${DEVICE_NODE_ID}
    \    ...    session=${DEVICE_SESSION}
    ${controller_id} =    Get Any Controller
    SxpLib.Add Node    ${CLUSTER_NODE_ID}    ip=0.0.0.0    session=controller${controller_id}
    BuiltIn.Wait Until Keyword Succeeds    20    1    Check Cluster Node started    ${CLUSTER_NODE_ID}
    SxpLib.Add Connection    version4    ${cluster_mode}    ${TOOLS_SYSTEM_IP}    64999    ${CLUSTER_NODE_ID}    session=controller${controller_id}
    BuiltIn.Wait Until Keyword Succeeds    120    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}

Clean SXP Cluster
    [Documentation]    Disconnect SXP cluster topology
    ClusterManagement.Flush_Iptables_From_List_Or_All
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    BuiltIn.Wait Until Keyword Succeeds    240    1    ClusterManagement.Sync_Status_Should_Be_True    ${i+1}
    ${controller_index} =    Get Active Controller
    SxpLib.Delete Node    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    SxpLib.Delete Node    ${CLUSTER_NODE_ID}    session=controller${controller_index}

Check Cluster Node started
    [Arguments]    ${node}    ${port}=64999    ${ip}=${EMPTY}
    [Documentation]    Verify that SxpNode has data written to Operational datastore and Node is running on one of cluster nodes
    ${started} =    BuiltIn.Set Variable    ${False}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${rc} =    Utils.Run Command On Remote System    ${ODL_SYSTEM_${i+1}_IP}    netstat -tln | grep -q ${ip}:${port} && echo 0 || echo 1    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}
    \    ...    prompt=${ODL_SYSTEM_PROMPT}
    \    ${started} =    BuiltIn.Set Variable If    '${rc}' == '0'    ${True}    ${started}
    BuiltIn.Should Be True    ${started}

Check Device is Connected
    [Arguments]    ${node}    ${version}=version4    ${port}=64999    ${session}=session
    [Documentation]    Checks if SXP device is connected to at least one cluster node
    ${is_connected} =    BuiltIn.Set Variable    ${False}
    ${resp} =    SxpLib.Get Connections    node=${node}    session=${session}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${follower} =    Sxp.Find Connection    ${resp}    ${version}    any    ${ODL_SYSTEM_${i+1}_IP}
    \    ...    ${port}    on
    \    ${is_connected} =    BuiltIn.Run Keyword If    ${follower}    BuiltIn.Set Variable    ${True}
    \    ...    ELSE    BuiltIn.Set Variable    ${is_connected}
    BuiltIn.Should Be True    ${is_connected}

Check Cluster is Connected
    [Arguments]    ${node}    ${version}=version4    ${port}=64999    ${mode}=speaker    ${session}=session
    [Documentation]    Checks if SXP device is connected to at least one cluster node
    ${resp} =    SxpLib.Get Connections    node=${node}    session=${session}
    SxpLib.Should Contain Connection    ${resp}    ${TOOLS_SYSTEM_IP}    ${port}    ${mode}    ${version}

Get Active Controller
    [Documentation]    Find cluster controller that is marked as leader for SXP service in cluster
    @{votes} =    BuiltIn.Create List
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${resp} =    RequestsLibrary.Get Request    controller${i+1}    /restconf/operational/entity-owners:entity-owners
    \    BuiltIn.Continue For Loop If    ${resp.status_code} != 200
    \    ${controller} =    Sxp.Get Active Controller From Json    ${resp.content}    SxpControllerInstance
    \    Collections.Append To List    ${votes}    ${controller}
    ${length} =    BuiltIn.Get Length    ${votes}
    BuiltIn.Should Not Be Equal As Integers    ${length}    0
    ${active_controller} =    BuiltIn.Evaluate    collections.Counter(${votes}).most_common(1)[0][0]    collections
    [Return]    ${active_controller}

Get Inactive Controller
    [Documentation]    Find cluster controller that is not marked as leader for SXP service in cluster
    ${active_controller} =    Get Active Controller
    ${controller} =    BuiltIn.Evaluate    random.choice( filter( lambda i: i!=${active_controller}, range(1, ${NUM_ODL_SYSTEM} + 1)))    random
    [Return]    ${controller}

Get Any Controller
    [Documentation]    Get any controller from cluster range
    ${follower} =    BuiltIn.Evaluate    random.choice( range(1, ${NUM_ODL_SYSTEM} + 1))    random
    [Return]    ${follower}

Map Followers To Mac Addresses
    [Documentation]    Creates Map containing ODL_SYSTEM_IP to corresponding MAC-ADDRESS
    ${mac_addresses} =    BuiltIn.Create dictionary
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${mac_address}    Find Mac Address Of Ip Address    ${ODL_SYSTEM_${i+1}_IP}
    \    Collections.Set To Dictionary    ${mac_addresses}    ${ODL_SYSTEM_${i+1}_IP}    ${mac_address}
    BuiltIn.Log    ${mac_addresses}
    [Return]    ${mac_addresses}

Find Mac Address Of Ip Address
    [Arguments]    ${ip}
    [Documentation]    Finds out MAC-ADDRESS of specified IP by pinging it from TOOLS_SYSTEM machine
    ${mac_address} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    ping -c 1 -W 1 ${ip} >/dev/null && arp -n | grep ${ip} | awk '{print $3}'    ${TOOLS_SYSTEM_USER}    ${TOOLS_SYSTEM_PASSWORD}
    [Return]    ${mac_address}

Ip Addres Should Not Be Routed To Follower
    [Arguments]    ${mac_addresses}    ${ip_address}    ${follower_index}
    [Documentation]    Verify that IP-ADDRESS is not routed to follower specified by ID
    ${mac_address_assigned} =    Collections.Get From Dictionary    ${mac_addresses}    ${ODL_SYSTEM_${follower_index}_IP}
    ${mac_address_resolved} =    Find Mac Address Of Ip Address    ${ip_address}
    BuiltIn.Should Not Be Equal As Strings    ${mac_address_assigned}    ${mac_address_resolved}

Ip Addres Should Be Routed To Follower
    [Arguments]    ${mac_addresses}    ${ip_address}    ${follower_index}
    [Documentation]    Verify that IP-ADDRESS is routed to follower specified by ID
    ${mac_address_assigned} =    Collections.Get From Dictionary    ${mac_addresses}    ${ODL_SYSTEM_${follower_index}_IP}
    ${mac_address_resolved} =    Find Mac Address Of Ip Address    ${ip_address}
    BuiltIn.Should Not Be Empty    ${mac_address_resolved}
    BuiltIn.Should Be Equal As Strings    ${mac_address_assigned}    ${mac_address_resolved}

Shutdown Tools Node
    [Arguments]    ${ip_address}=${TOOLS_SYSTEM_2_IP}    ${user}=${TOOLS_SYSTEM_USER}    ${passwd}=${TOOLS_SYSTEM_PASSWORD}
    [Documentation]    Shutdown Tools node to avoid conflict in resolving virtual ip that is overlaping that node.
    ${rc} =    OperatingSystem.Run And Return Rc    ping -q -c 3 ${ip_address}
    ${stdout} =    BuiltIn.Run Keyword And Return If    ${rc} == 0    Utils.Run Command On Remote System    ${ip_address}    sudo shutdown -P 0    ${user}
    ...    ${passwd}
    BuiltIn.Log    ${stdout}

Create Virtual Interface Eth0
    [Documentation]    Create virtual interface on all of the cluster nodes
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Utils.Run Command On Remote System    ${ODL_SYSTEM_${i+1}_IP}    sudo modprobe dummy    ${ODL_SYSTEM_USER}
${ODL_SYSTEM_PASSWORD}
    \    Utils.Run Command On Remote System    ${ODL_SYSTEM_${i+1}_IP}    sudo ip link set name eth0 dev dummy0    ${ODL_SYSTEM_USER}
${ODL_SYSTEM_PASSWORD}
    \    Utils.Run Command On Remote System And Log    ${ODL_SYSTEM_${i+1}_IP}    sudo ip link show    ${ODL_SYSTEM_USER}
${ODL_SYSTEM_PASSWORD}

Delete Virtual Interface Eth0
    [Documentation]    Create virtual interface on all of the cluster nodes
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Utils.Run Command On Remote System    ${ODL_SYSTEM_${i+1}_IP}    sudo ip link delete eth0 type dummy    ${ODL_SYSTEM_USER}
${ODL_SYSTEM_PASSWORD}
    \    Utils.Run Command On Remote System    ${ODL_SYSTEM_${i+1}_IP}    sudo rmmod dummy    ${ODL_SYSTEM_USER}
${ODL_SYSTEM_PASSWORD}
    \    Utils.Run Command On Remote System And Log    ${ODL_SYSTEM_${i+1}_IP}    sudo ip link show    ${ODL_SYSTEM_USER}
${ODL_SYSTEM_PASSWORD}

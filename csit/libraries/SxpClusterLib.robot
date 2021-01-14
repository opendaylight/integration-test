*** Settings ***
Documentation     Library containing Keywords used for SXP cluster testing
Library           RequestsLibrary
Resource          ./ClusterManagement.robot
Resource          ./SetupUtils.robot
Resource          ./SxpLib.robot

*** Variables ***
@{SHARD_OPER_LIST}    inventory    topology    default    entity-ownership
@{SHARD_CONF_LIST}    inventory    topology    default
@{SXP_PACKAGE}    org.opendaylight.sxp
${DEVICE_SESSION}    device_1
${CONTROLLER_SESSION}    ClusterManagement__session_1
${VIRTUAL_IP}     ${TOOLS_SYSTEM_2_IP}
${VIRTUAL_IP_MASK}    255.255.255.0
${VIRTUAL_INTERFACE}    dummy0
${MAC_ADDRESS_TABLE}    &{EMPTY}
${DEVICE_NODE_ID}    ${TOOLS_SYSTEM_IP}
${CLUSTER_NODE_ID}    ${TOOLS_SYSTEM_2_IP}
${INADDR_ANY}     0.0.0.0

*** Keywords ***
Setup SXP Cluster Session
    [Documentation]    Create sessions asociated with SXP cluster setup
    ClusterManagement.ClusterManagement_Setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SetupUtils.Setup_Logging_For_Debug_Purposes_On_List_Or_All    DEBUG    ${SXP_PACKAGE}

Setup Device Session
    [Documentation]    Create session on the SXP device
    RequestsLibrary.Create Session    ${DEVICE_SESSION}    url=http://${DEVICE_NODE_ID}:${RESTCONFPORT}    auth=${AUTH}    timeout=${DEFAULT_TIMEOUT_HTTP}    max_retries=0

Setup SXP Cluster Session With Device
    [Documentation]    Create sessions asociated with SXP cluster setup and one SXP device
    Setup SXP Cluster Session
    Setup Device Session

Clean SXP Cluster Session
    [Documentation]    Clean sessions asociated with SXP cluster setup
    ClusterManagement.Flush_Iptables_From_List_Or_All
    BuiltIn.Wait Until Keyword Succeeds    60x    1s    ClusterManagement.Verify_Members_Are_Ready    member_index_list=${EMPTY}    verify_cluster_sync=True    verify_restconf=True
    ...    verify_system_status=False    service_list=@{EMPTY}
    RequestsLibrary.Delete All Sessions
    SetupUtils.Setup_Logging_For_Debug_Purposes_On_List_Or_All    INFO    ${SXP_PACKAGE}

Check Shards Status
    [Documentation]    Check Status for all shards in SXP application.
    ClusterManagement.Check_Cluster_Is_In_Sync
    ClusterManagement.Verify_Leader_Exists_For_Each_Shard    shard_name_list=${SHARD_OPER_LIST}    shard_type=operational
    ClusterManagement.Verify_Leader_Exists_For_Each_Shard    shard_name_list=${SHARD_CONF_LIST}    shard_type=config

Setup SXP Cluster
    [Arguments]    ${peer_mode}=listener
    [Documentation]    Setup and connect SXP cluster topology
    SxpLib.Add Node    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    SxpLib.Check Node Started    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
        SxpLib.Add Connection    version4    ${peer_mode}    ${ODL_SYSTEM_${i+1}_IP}    64999    node=${DEVICE_NODE_ID}
        ...    session=${DEVICE_SESSION}
    END
    ${cluster_mode} =    Sxp.Get Opposing Mode    ${peer_mode}
    SxpLib.Add Node    ${INADDR_ANY}    session=${CONTROLLER_SESSION}
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    Check Cluster Node Started    ${INADDR_ANY}    ip=${EMPTY}
    SxpLib.Add Connection    version4    ${cluster_mode}    ${DEVICE_NODE_ID}    64999    ${INADDR_ANY}    session=${CONTROLLER_SESSION}
    BuiltIn.Wait Until Keyword Succeeds    480x    1s    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}

Clean SXP Cluster
    [Documentation]    Disconnect SXP cluster topology
    SxpLib.Delete Node    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    SxpLib.Check Node Stopped    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    BuiltIn.Wait Until Keyword Succeeds    60x    1s    SxpLib.Delete Node    ${INADDR_ANY}    session=${CONTROLLER_SESSION}
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    SxpClusterLib.Check Cluster Node Stopped    ${INADDR_ANY}    ip=${EMPTY}

Check Cluster Node Started
    [Arguments]    ${node}    ${port}=64999    ${ip}=${node}
    [Documentation]    Verify that SxpNode has data written to Operational datastore and Node is running on one of cluster nodes
    ${resp} =    RequestsLibrary.GET On Session    ${CONTROLLER_SESSION}    /restconf/operational/network-topology:network-topology/topology/sxp/node/${node}/
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    ${started} =    BuiltIn.Set Variable    ${False}
    FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
        ${rc} =    Utils.Run Command On Remote System    ${ODL_SYSTEM_${i+1}_IP}    netstat -tln | grep -q ${ip}:${port} && echo 0 || echo 1    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}
        ...    prompt=${ODL_SYSTEM_PROMPT}
        ${started} =    BuiltIn.Set Variable If    '${rc}' == '0'    ${True}    ${started}
    END
    BuiltIn.Should Be True    ${started}

Check Cluster Node Stopped
    [Arguments]    ${node}    ${port}=64999    ${ip}=${node}
    [Documentation]    Verify that SxpNode has data removed from Operational datastore and Node is stopped
    ${resp} =    RequestsLibrary.GET On Session    ${CONTROLLER_SESSION}    /restconf/operational/network-topology:network-topology/topology/sxp/node/${node}/
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    404
    ${stopped} =    BuiltIn.Set Variable    ${False}
    FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
        ${rc} =    Utils.Run Command On Remote System    ${ODL_SYSTEM_${i+1}_IP}    netstat -tln | grep -q ${ip}:${port} && echo 0 || echo 1    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}
        ...    prompt=${ODL_SYSTEM_PROMPT}
        ${stopped} =    BuiltIn.Set Variable If    '${rc}' == '1'    ${True}    ${stopped}
    END
    BuiltIn.Should Be True    ${stopped}

Check Device is Connected
    [Arguments]    ${node}    ${version}=version4    ${port}=64999    ${session}=session
    [Documentation]    Checks if SXP device is connected to the cluster. It means it has connection in state "on" with one of the cluster members.
    ${resp} =    SxpLib.Get Connections    node=${node}    session=${session}
    ${is_connected} =    BuiltIn.Set Variable    ${False}
    FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
        ${is_connected} =    Sxp.Find Connection    ${resp}    ${version}    any    ${ODL_SYSTEM_${i+1}_IP}
        ...    ${port}    on
        BuiltIn.Exit For Loop If    ${is_connected}
    END
    BuiltIn.Should Be True    ${is_connected}

Check Cluster is Connected
    [Arguments]    ${node}    ${version}=version4    ${port}=64999    ${mode}=speaker    ${session}=session
    [Documentation]    Get SXP connections of cluster ${node} and verify that they contain a connection to the device ${DEVICE_NODE_ID} in state "on"
    ${resp} =    SxpLib.Get Connections    node=${node}    session=${session}
    SxpLib.Should Contain Connection    ${resp}    ${DEVICE_NODE_ID}    ${port}    ${mode}    ${version}    on

Get Owner Controller
    [Arguments]    ${running_member}=1
    [Documentation]    Find cluster controller that is marked as cluster owner by requesting ownership data from ${running_member} node of the cluster
    ${owner}    ${candidates} =    BuiltIn.Wait Until Keyword Succeeds    60x    1s    ClusterManagement.Get_Owner_And_Successors_For_Device    org.opendaylight.sxp.controller.boot.SxpControllerInstance
    ...    Sxp    ${running_member}
    [Return]    ${owner}

Get Not Owner Controller
    [Documentation]    Find cluster controller that is not marked as owner for SXP service in cluster
    ${owner_controller} =    Get Owner Controller
    ${controller} =    BuiltIn.Evaluate    random.choice( filter( lambda i: i!=${owner_controller}, range(1, ${NUM_ODL_SYSTEM} + 1)))    random
    [Return]    ${controller}

Get Any Controller
    [Documentation]    Get any controller from cluster range
    ${follower} =    BuiltIn.Evaluate    random.choice( range(1, ${NUM_ODL_SYSTEM} + 1))    random
    [Return]    ${follower}

Map Followers To Mac Addresses
    [Documentation]    Creates Map containing ODL_SYSTEM_IP to corresponding MAC-ADDRESS
    ${mac_addresses} =    BuiltIn.Create dictionary
    FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
        ${mac_address}    Find Mac Address Of Ip Address    ${ODL_SYSTEM_${i+1}_IP}
        Collections.Set To Dictionary    ${mac_addresses}    ${ODL_SYSTEM_${i+1}_IP}    ${mac_address}
    END
    BuiltIn.Log    ${mac_addresses}
    [Return]    ${mac_addresses}

Find Mac Address Of Ip Address
    [Arguments]    ${ip}
    [Documentation]    Finds out MAC-ADDRESS of specified IP by pinging it from TOOLS_SYSTEM machine
    ${mac_address} =    Utils.Run Command On Remote System And Log    ${TOOLS_SYSTEM_IP}    ping -c 10 -W 10 ${ip} >/dev/null && sudo ip neighbor show ${ip} | awk '{print $5}'    ${TOOLS_SYSTEM_USER}    ${TOOLS_SYSTEM_PASSWORD}
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

Create Virtual Interface
    [Documentation]    Create virtual interface on all of the cluster nodes
    FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
        Utils.Run Command On Remote System    ${ODL_SYSTEM_${i+1}_IP}    sudo modprobe dummy    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}
        Utils.Run Command On Remote System And Log    ${ODL_SYSTEM_${i+1}_IP}    sudo ip link show    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}
    END

Delete Virtual Interface
    [Documentation]    Create virtual interface on all of the cluster nodes
    FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
        Utils.Run Command On Remote System    ${ODL_SYSTEM_${i+1}_IP}    sudo ip link delete ${VIRTUAL_INTERFACE} type dummy    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}
        Utils.Run Command On Remote System    ${ODL_SYSTEM_${i+1}_IP}    sudo rmmod dummy    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}
        Utils.Run Command On Remote System And Log    ${ODL_SYSTEM_${i+1}_IP}    sudo ip link show    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}
    END

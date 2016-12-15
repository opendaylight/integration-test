*** Settings ***
Documentation     Library containing Keywords used for SXP cluster testing
Library           RequestsLibrary
Library           ./Sxp.py
Resource          ./SxpLib.robot
Resource          ./ClusterManagement.robot
Variables         ../variables/Variables.py

*** Variables ***
${DEVICE_SESSION}    device_1
${DEVICE_NODE_ID}    1.1.1.1
${CLUSTER_NODE_ID}    2.2.2.2

*** Keywords ***
Setup SXP Cluster Session
    [Documentation]    Create sessions asociated with SXP cluster setup
    Setup SXP Session    ${DEVICE_SESSION}    ${TOOLS_SYSTEM_IP}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Setup SXP Session    controller${i+1}    ${ODL_SYSTEM_${i+1}_IP}
    \    ${stdout}    Run Command On Remote System    ${ODL_SYSTEM_${i+1}_IP}    yum -y install net-tools
    \    Log    ${stdout}
    ClusterManagement_Setup

Clean SXP Cluster Session
    [Documentation]    Clean sessions asociated with SXP cluster setup
    Flush_Iptables_From_List_Or_All
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Wait Until Keyword Succeeds    240    1    Sync_Status_Should_Be_True    ${i+1}
    Clean SXP Session

Setup SXP Cluster
    [Arguments]    ${peer_mode}=listener
    [Documentation]    Setup and connect SXP cluster topology
    Add Node    ${DEVICE_NODE_ID}    ip=0.0.0.0    session=${DEVICE_SESSION}
    Wait Until Keyword Succeeds    20    1    Check Node Started    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}    system=${TOOLS_SYSTEM_IP}
    ...    ip=${EMPTY}
    ${cluster_mode}    Get Opposing Mode    ${peer_mode}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Add Connection    version4    ${peer_mode}    ${ODL_SYSTEM_${i+1}_IP}    64999    ${DEVICE_NODE_ID}
    \    ...    session=${DEVICE_SESSION}
    ${controller_id}    Get Any Controller
    Add Node    ${CLUSTER_NODE_ID}    ip=0.0.0.0    session=controller${controller_id}
    Wait Until Keyword Succeeds    20    1    Check Cluster Node started    ${CLUSTER_NODE_ID}
    Add Connection    version4    ${cluster_mode}    ${TOOLS_SYSTEM_IP}    64999    ${CLUSTER_NODE_ID}    session=controller${controller_id}
    Wait Until Keyword Succeeds    120    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}

Clean SXP Cluster
    [Documentation]    Disconnect SXP cluster topology
    Flush_Iptables_From_List_Or_All
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Wait Until Keyword Succeeds    240    1    Sync_Status_Should_Be_True    ${i+1}
    ${controller_index}    Get Active Controller
    Delete Node    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    Delete Node    ${CLUSTER_NODE_ID}    session=controller${controller_index}

Check Cluster Node started
    [Arguments]    ${node}    ${port}=64999    ${ip}=${EMPTY}
    [Documentation]    Verify that SxpNode has data written to Operational datastore and Node is running on one of cluster nodes
    ${started}    Set Variable    ${False}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${rc}    Run Command On Remote System    ${ODL_SYSTEM_${i+1}_IP}    netstat -tln | grep -q ${ip}:${port} && echo 0 || echo 1    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}
    \    ...    prompt=${ODL_SYSTEM_PROMPT}
    \    ${started}    Set Variable If    '${rc}' == '0'    ${True}    ${started}
    Should Be True    ${started}

Check Device is Connected
    [Arguments]    ${node}    ${version}=version4    ${port}=64999    ${session}=session
    [Documentation]    Checks if SXP device is connected to at least one cluster node
    ${is_connected}    Set Variable    ${False}
    ${resp}    Get Connections    node=${node}    session=${session}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${follower}    Find Connection    ${resp}    ${version}    any    ${ODL_SYSTEM_${i+1}_IP}
    \    ...    ${port}    on
    \    ${is_connected}    Run Keyword If    ${follower}    Set Variable    ${True}
    \    ...    ELSE    Set Variable    ${is_connected}
    Should Be True    ${is_connected}

Check Cluster is Connected
    [Arguments]    ${node}    ${version}=version4    ${port}=64999    ${mode}=speaker    ${session}=session
    [Documentation]    Checks if SXP device is connected to at least one cluster node
    ${resp}    Get Connections    node=${node}    session=${session}
    Should Contain Connection    ${resp}    ${TOOLS_SYSTEM_IP}    ${port}    ${mode}    ${version}

Get Active Controller
    [Documentation]    Find cluster controller that is marked as leader for SXP service in cluster
    @{VOTES}    Create List
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${resp}    RequestsLibrary.Get Request    controller${i+1}    /restconf/operational/entity-owners:entity-owners
    \    Continue For Loop If    ${resp.status_code} != 200
    \    ${controller}    Get Active Controller From Json    ${resp.content}    SxpControllerInstance
    \    Append To List    ${VOTES}    ${controller}
    ${length}    Get Length    ${VOTES}
    Should Not Be Equal As Integers    ${length}    0
    ${active_controller}    Evaluate    collections.Counter(${VOTES}).most_common(1)[0][0]    collections
    [Return]    ${active_controller}

Get Inactive Controller
    [Documentation]    Find cluster controller that is not marked as leader for SXP service in cluster
    ${active_controller}    Get Active Controller
    ${controller}    Evaluate    random.choice( filter( lambda i: i!=${active_controller}, range(1, ${NUM_ODL_SYSTEM} + 1)))    random
    [Return]    ${controller}

Get Any Controller
    [Documentation]    Get any controller from cluster range
    ${follower}    Evaluate    random.choice( range(1, ${NUM_ODL_SYSTEM} + 1))    random
    [Return]    ${follower}

Map Followers To Mac Addresses
    [Documentation]    Creates Map containing ODL_SYSTEM_IP to corresponding MAC-ADDRESS
    ${mac_addresses}    create dictionary
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${mac_address}    Find Mac Address Of Ip Address    ${ODL_SYSTEM_${i+1}_IP}
    \    Set To Dictionary    ${mac_addresses}    ${ODL_SYSTEM_${i+1}_IP}    ${mac_address}
    Log    ${mac_addresses}
    [Return]    ${mac_addresses}

Find Mac Address Of Ip Address
    [Arguments]    ${ip}
    [Documentation]    Finds out MAC-ADDRESS of specified IP by pinging it from TOOLS_SYSTEM machine
    ${mac_address}    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    ping -c 1 -W 1 ${ip} >/dev/null && arp -n | grep ${ip} | awk '{print $3}'    ${TOOLS_SYSTEM_USER}    ${TOOLS_SYSTEM_PASSWORD}
    [Return]    ${mac_address}

Ip Addres Should Not Be Routed To Follower
    [Arguments]    ${mac_addresses}    ${ip_address}    ${follower_index}
    [Documentation]    Verify that IP-ADDRESS is not routed to follower specified by ID
    ${mac_address_assigned}    Get From Dictionary    ${mac_addresses}    ${ODL_SYSTEM_${follower_index}_IP}
    ${mac_address_resolved}    Find Mac Address Of Ip Address    ${ip_address}
    Should Not Be Equal As Strings    ${mac_address_assigned}    ${mac_address_resolved}

Ip Addres Should Be Routed To Follower
    [Arguments]    ${mac_addresses}    ${ip_address}    ${follower_index}
    [Documentation]    Verify that IP-ADDRESS is routed to follower specified by ID
    ${mac_address_assigned}    Get From Dictionary    ${mac_addresses}    ${ODL_SYSTEM_${follower_index}_IP}
    ${mac_address_resolved}    Find Mac Address Of Ip Address    ${ip_address}
    Should Not Be Empty    ${mac_address_resolved}
    Should Be Equal As Strings    ${mac_address_assigned}    ${mac_address_resolved}

Generate Virtual Interface
    [Arguments]    ${ip_address}    ${ODL_SYSTEM_INDEX}    ${interface_start}=${EMPTY}
    [Documentation]    TODO
    ${ip_address}    Evaluate    "${ip_address}"[:"${ip_address}".rfind(".")] + ".0"
    ${interface}    Run Command On Remote System    ${ODL_SYSTEM_${ODL_SYSTEM_INDEX}_IP}    route | grep ${ip_address} | awk '{print $8}'    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}
    ${virtual_interface}    Set Variable    ${EMPTY}
    ${interface_start}    Run Keyword If    "${interface_start}" == "${EMPTY}"    Set Variable    0
    ...    ELSE    Evaluate    int("${interface_start}"["${interface_start}".find(":") + 1:]) + 1
    : FOR    ${i}    IN RANGE    ${interface_start}    255
    \    ${interface_exist}    Run Command On Remote System    ${ODL_SYSTEM_${ODL_SYSTEM_INDEX}_IP}    ifconfig | grep -q "${interface}:${i}" && echo 1 || echo 0    ${ODL_SYSTEM_USER}    ${ODL_SYSTEM_PASSWORD}
    \    ${virtual_interface}    Set Variable If    ${interface_exist} == 0    ${interface}:${i}    ${EMPTY}
    \    Exit For Loop If    ${interface_exist} == 0
    [Return]    ${virtual_interface}

Generate Virtual Ip
    [Arguments]    ${ip_start}=192.168.50.11
    [Documentation]    TODO
    ${ip_end}    Evaluate    "${ip_start}"[:"${ip_start}".rfind(".")] + ".255"
    ${ip_start}    Evaluate    int(netaddr.IPAddress("${ip_start}")) + 1    netaddr
    ${ip_end}    Evaluate    int(netaddr.IPAddress("${ip_end}"))    netaddr
    ${virtual_ip}    Set Variable    ${EMPTY}
    : FOR    ${i}    IN RANGE    ${ip_start}    ${ip_end}
    \    ${ip}    Get Ip From Number    ${i}    0
    \    ${active_ip}    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    ping -W 1 -c 2 ${ip} >/dev/null && echo 1 || echo 0    ${TOOLS_SYSTEM_USER}    ${TOOLS_SYSTEM_PASSWORD}
    \    ${virtual_ip}    Set Variable If    ${active_ip} == 0    ${IP}    ${EMPTY}
    \    Exit For Loop If    ${active_ip} == 0
    [Return]    ${virtual_ip}

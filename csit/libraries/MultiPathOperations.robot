*** Settings ***
Documentation     This library is useful to check flows for a given IP, get VM MAC, \ verify the group stats packet count and add/delete Tep Ports
Library           SSHLibrary
Resource          DevstackUtils.robot
Resource          OpenStackOperations.robot
Resource          OVSDB.robot
Resource          Utils.robot
Resource          ../variables/netvirt/Variables.robot

*** Variables ***
${TABLE_21}       table=21

*** Keywords ***
Verify_Flows_In_Compute_Node
    [Arguments]    ${COMPUTE_IP}    ${EXPECTED_LOCAL_BUCKET_ENTRY}    ${EXPECTED_REMOTE_BUCKET_ENTRY}    ${STATIC_IP}
    [Documentation]    Verify flows w.r.t a particular IP and the corresponding bucket entry
    ${OVS_FLOW}    Run Command On Remote System    ${COMPUTE_IP}    ${DUMP_FLOWS} | grep ${TABLE_21}
    ${OVS_GROUP}    Run Command On Remote System    ${COMPUTE_IP}    ${DUMP_GROUPS}
    ${MATCH}    ${GROUP_ID}    Should Match Regexp    ${OVS_FLOW}    ${TABLE_21}.*nw_dst=${STATIC_IP}.*group:(\\d+)
    ${MULTI_PATH_GROUP_ID}    Should Match Regexp    ${OVS_GROUP}    group_id=${GROUP_ID},type=select.*
    ${ACTUAL_LOCAL_BUCKET_ENTRY}    Get Regexp Matches    ${MULTI_PATH_GROUP_ID}    bucket=actions=group:(\\d+)
    Length Should Be    ${ACTUAL_LOCAL_BUCKET_ENTRY}    ${EXPECTED_LOCAL_BUCKET_ENTRY}
    ${ACTUAL_REMOTE_BUCKET_ENTRY}    Get Regexp Matches    ${MULTI_PATH_GROUP_ID}    resubmit
    Length Should Be    ${ACTUAL_REMOTE_BUCKET_ENTRY}    ${EXPECTED_REMOTE_BUCKET_ENTRY}
    [Return]    ${GROUP_ID}

Verify_Group_Stats_Packet_Count
    [Arguments]    ${COMPUTE_IP}    ${STATIC_IP}    ${GROUP_ID}
    [Documentation]    Verify packet count after ping
    ${OVS_GROUP_STAT}    Run Command On Remote System    ${COMPUTE_IP}    ${DUMP_GROUP_STATS}
    ${MULTI_PATH_GROUP_STAT}    ${MULTI_PATH_GROUP_PACKET_COUNT}    Should Match Regexp    ${OVS_GROUP_STAT}    group_id=${GROUP_ID}.*,packet_count=(\\d+).*
    ${BUCKET_PACKET_COUNT}    Get Regexp Matches    ${MULTI_PATH_GROUP_STAT}    :packet_count=(..)    1
    ${TOTAL_OF_BUCKET_PACKET_COUNT}    Set Variable    ${0}
    : FOR    ${COUNT}    IN    @{BUCKET_PACKET_COUNT}
    \    ${TOTAL_OF_BUCKET_PACKET_COUNT}    Evaluate    ${TOTAL_OF_BUCKET_PACKET_COUNT}+int(${COUNT})
    Should Be Equal As Strings    ${MULTI_PATH_GROUP_PACKET_COUNT}    ${TOTAL_OF_BUCKET_PACKET_COUNT}

Generate_Next_Hops
    [Arguments]    ${IP}    ${MASK}    @{VM_IP_LIST}
    [Documentation]    Keyword for generating next hop entries
    @{NEXT_HOP_LIST}    Create List
    : FOR    ${VM_IP}    IN    @{VM_IP_LIST}
    \    Append To List    ${NEXT_HOP_LIST}    --route destination=${IP}/${MASK},gateway=${VM_IP}
    [Return]    @{NEXT_HOP_LIST}

Configure_Next_Hops_On_Router
    [Arguments]    ${ROUTER_NAME}    ${NO_OF_STATIC_IP}    ${VM_LIST_1}    ${STATIC_IP_1}    ${VM_LIST_2}={EMPTY}    ${STATIC_IP_2}=${EMPTY}
    ...    ${MASK}=32
    [Documentation]    Keyword for configuring Next Hop Routes on Router
    @{NEXT_HOP_LIST_1}    Generate_Next_Hops    ${STATIC_IP_1}    ${MASK}    @{VM_LIST_1}
    @{NEXT_HOP_LIST_2}    Run Keyword if    ${NO_OF_STATIC_IP}==${2}    Generate_Next_Hops    ${STATIC_IP2}    ${MASK}    @{VM_LIST_2}
    ${ROUTES_1}    catenate    @{NEXT_HOP_LIST_1}
    ${ROUTES_2}    catenate    @{NEXT_HOP_LIST_2}
    ${FINAL_ROUTE}    Set Variable If    ${NO_OF_STATIC_IP}==${2}    ${ROUTES_1} ${ROUTES_2}    ${ROUTES_1}
    Log    ${FINAL_ROUTE}
    Update Router    ${ROUTER_NAME}    ${FINAL_ROUTE}
    Show Router    ${ROUTER_NAME}    -D

Tep_Port_Operations
    [Arguments]    ${OPERATION}    ${COMPUTE_1_IP}    ${COMPUTE_2_IP}=${EMPTY}    ${COMPUTE_3_IP}=${EMPTY}
    [Documentation]    Keyword to add/delete TEP Port for specified compute nodes with default one compute node
    ${FIRST_TWO_OCTETS}    ${THIRD_OCTET}    ${LAST_OCTET}=    Split String From Right    ${COMPUTE_1_IP}    .    2
    ${SUBNET_1}=    Set Variable    ${FIRST_TWO_OCTETS}.0.0/16
    ${COMPUTE_NODE_1_ID}    Get DPID    ${COMPUTE_1_IP}
    ${COMPUTE_NODE_2_ID}    Run Keyword If    "${COMPUTE_2_IP}" != "${EMPTY}"    Get DPID    ${COMPUTE_2_IP}
    ${COMPUTE_NODE_3_ID}    Run Keyword If    "${COMPUTE_3_IP}" != "${EMPTY}"    Get DPID    ${COMPUTE_3_IP}
    ${NODE_ADAPTER}=    Get Ethernet Adapter    ${COMPUTE_1_IP}
    Issue Command On Karaf Console    tep:${OPERATION} ${COMPUTE_NODE_1_ID} ${NODE_ADAPTER} 0 ${COMPUTE_1_IP} ${SUBNET_1} null TZA
    Run Keyword If    "${COMPUTE_2_IP}" != "${EMPTY}"    Issue Command On Karaf Console    tep:${OPERATION} ${COMPUTE_NODE_2_ID} ${NODE_ADAPTER} 0 ${COMPUTE_2_IP} ${SUBNET_1} null TZA
    Run Keyword If    "${COMPUTE_3_IP}" != "${EMPTY}"    Issue Command On Karaf Console    tep:${OPERATION} ${COMPUTE_NODE_3_ID} ${NODE_ADAPTER} 0 ${COMPUTE_3_IP} ${SUBNET_1} null TZA
    Issue Command On Karaf Console    tep:commit

Verify_VM_Mac
    [Arguments]    ${COMPUTE_IP}    ${STATIC_IP}    ${LOCAL_VM_PORT_LIST}    ${REMOTE_VM_PORT_LIST}    ${GROUP_ID}
    [Documentation]    Keyword to verify VM MAC in respective compute node groups
    ${LOCAL_VM_MAC_LIST}    Wait Until Keyword Succeeds    30s    10s    Get_VM_Mac    ${LOCAL_VM_PORT_LIST}
    ${REMOTE_VM_MAC_LIST}    Wait Until Keyword Succeeds    30s    10s    Get_VM_Mac    ${REMOTE_VM_PORT_LIST}
    ${OVS_GROUP}    Run Command On Remote System    ${COMPUTE_IP}    ${DUMP_GROUPS}
    ${MULTI_PATH_GROUP_ID}    Should Match Regexp    ${OVS_GROUP}    group_id=${GROUP_ID}.*
    : FOR    ${VM_MAC}    IN    @{REMOTE_VM_MAC_LIST}
    \    Should Contain    ${MULTI_PATH_GROUP_ID}    ${VM_MAC}
    ${LOCAL_GROUPS}    Get Regexp Matches    ${MULTI_PATH_GROUP_ID}    :15(\\d+)
    : FOR    ${VM_MAC}    ${LOCAL_GROUP_ID}    IN ZIP    ${LOCAL_VM_MAC_LIST}    ${LOCAL_GROUPS}
    \    ${VAL_1}    ${GROUP_NUM}    Split String    ${LOCAL_GROUP_ID}    :
    \    ${MATCH}    Should Match Regexp    ${OVS_GROUP}    group_id=${GROUP_NUM}.*bucket=actions.*
    \    Run Keyword and Ignore Error    Should Contain    ${MATCH}    ${VM_MAC}

Get_VM_Mac
    [Arguments]    ${VM_PORT_NAME_LIST}    ${conn_id}=${devstack_conn_id}
    [Documentation]    Keyword to return the VM MAC ID
    ${MAC_ADDR_LIST}    Create List
    : FOR    ${PORT_NAME}    IN    @{VM_PORT_NAME_LIST}
    \    ${rc}    ${output}=    Run And Return Rc And Output    openstack port list | grep ${PORT_NAME} | awk '{print $6}'
    \    Log    ${output}
    \    Append To List    ${MAC_ADDR_LIST}    ${output}
    \    Should Not Be True    ${rc}
    [Return]    ${MAC_ADDR_LIST}

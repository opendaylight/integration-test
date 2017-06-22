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
    ${OVS_FLOW}    Utils.Run Command On Remote System    ${COMPUTE_IP}    ${DUMP_FLOWS} | grep ${TABLE_21}
    ${OVS_GROUP}    Utils.Run Command On Remote System    ${COMPUTE_IP}    ${DUMP_GROUPS}
    ${MATCH}    ${GROUP_ID}    BuiltIn.Should Match Regexp    ${OVS_FLOW}    ${TABLE_21}.*nw_dst=${STATIC_IP}.*group:(\\d+)
    ${MULTI_PATH_GROUP_ID}    BuiltIn.Should Match Regexp    ${OVS_GROUP}    group_id=${GROUP_ID},type=select.*
    ${ACTUAL_LOCAL_BUCKET_ENTRY}    String.Get Regexp Matches    ${MULTI_PATH_GROUP_ID}    bucket=actions=group:(\\d+)
    BuiltIn.Length Should Be    ${ACTUAL_LOCAL_BUCKET_ENTRY}    ${EXPECTED_LOCAL_BUCKET_ENTRY}
    ${ACTUAL_REMOTE_BUCKET_ENTRY}    String.Get Regexp Matches    ${MULTI_PATH_GROUP_ID}    resubmit
    BuiltIn.Length Should Be    ${ACTUAL_REMOTE_BUCKET_ENTRY}    ${EXPECTED_REMOTE_BUCKET_ENTRY}
    [Return]    ${GROUP_ID}

Verify_Group_Stats_Packet_Count
    [Arguments]    ${COMPUTE_IP}    ${STATIC_IP}    ${GROUP_ID}
    [Documentation]    Verify packet count after ping
    ${OVS_GROUP_STAT}    Utils.Run Command On Remote System    ${COMPUTE_IP}    ${DUMP_GROUP_STATS}
    ${MULTI_PATH_GROUP_STAT}    ${MULTI_PATH_GROUP_PACKET_COUNT}    BuiltIn.Should Match Regexp    ${OVS_GROUP_STAT}    group_id=${GROUP_ID}.*,packet_count=(\\d+).*
    ${BUCKET_PACKET_COUNT}    String.Get Regexp Matches    ${MULTI_PATH_GROUP_STAT}    :packet_count=(..)    1
    ${TOTAL_OF_BUCKET_PACKET_COUNT}    BuiltIn.Set Variable    ${0}
    : FOR    ${COUNT}    IN    @{BUCKET_PACKET_COUNT}
    \    ${TOTAL_OF_BUCKET_PACKET_COUNT}    BuiltIn.Evaluate    ${TOTAL_OF_BUCKET_PACKET_COUNT}+int(${COUNT})
    BuiltIn.Should Be Equal As Strings    ${MULTI_PATH_GROUP_PACKET_COUNT}    ${TOTAL_OF_BUCKET_PACKET_COUNT}

Generate_Next_Hops
    [Arguments]    ${IP}    ${MASK}    @{VM_IP_LIST}
    [Documentation]    Keyword for generating next hop entries
    @{NEXT_HOP_LIST}    BuiltIn.Create List
    : FOR    ${VM_IP}    IN    @{VM_IP_LIST}
    \    Collections.Append To List    ${NEXT_HOP_LIST}    --route destination=${IP}/${MASK},gateway=${VM_IP}
    [Return]    @{NEXT_HOP_LIST}

Configure_Next_Hops_On_Router
    [Arguments]    ${ROUTER_NAME}    ${NO_OF_STATIC_IP}    ${VM_LIST_1}    ${STATIC_IP_1}    ${VM_LIST_2}={EMPTY}    ${STATIC_IP_2}=${EMPTY}
    ...    ${MASK}=32
    [Documentation]    Keyword for configuring Next Hop Routes on Router
    @{NEXT_HOP_LIST_1}    MultiPathOperations.Generate_Next_Hops    ${STATIC_IP_1}    ${MASK}    @{VM_LIST_1}
    @{NEXT_HOP_LIST_2}    BuiltIn.Run Keyword If    ${NO_OF_STATIC_IP}==${2}    MultiPathOperations.Generate_Next_Hops    ${STATIC_IP2}    ${MASK}    @{VM_LIST_2}
    ${ROUTES_1}    BuiltIn.Catenate    @{NEXT_HOP_LIST_1}
    ${ROUTES_2}    BuiltIn.Catenate    @{NEXT_HOP_LIST_2}
    ${FINAL_ROUTE}    BuiltIn.Set Variable If    ${NO_OF_STATIC_IP}==${2}    ${ROUTES_1} ${ROUTES_2}    ${ROUTES_1}
    BuiltIn.Log    ${FINAL_ROUTE}
    OpenStackOperations.Update Router    ${ROUTER_NAME}    ${FINAL_ROUTE}
    OpenStackOperations.Show Router    ${ROUTER_NAME}    -D

Tep_Port_Operations
    [Arguments]    ${OPERATION}    ${NO_OF_COMPUTE}
    [Documentation]    Keyword to add/delete TEP Port for specified number of compute nodes
    ${FIRST_TWO_OCTETS}    ${THIRD_OCTET}    ${LAST_OCTET}=    String.Split String From Right    ${COMPUTE_1_IP}    .    2
    ${SUBNET_1}=    BuiltIn.Set Variable    ${FIRST_TWO_OCTETS}.0.0/16
    : FOR    ${VAL}    IN RANGE    {NO_OF_COMPUTE}
    \    ${COMPUTE_NODE_ID}    OVSDB.Get DPID    ${OS_COMPUTE_${VAL+1}_IP}
    \    ${NODE_ADAPTER}=    OVSDB.Get Ethernet Adapter    ${OS_COMPUTE_${VAL+1}_IP}
    \    KarafKeywords.Issue_Command_On_Karaf_Console    tep:${OPERATION} ${COMPUTE_NODE_ID} ${NODE_ADAPTER} 0 ${OS_COMPUTE_${VAL+1}_IP} ${SUBNET_1} null TZA
    KarafKeywords.Issue_Command_On_Karaf_Console    tep:commit

Verify_VM_Mac
    [Arguments]    ${COMPUTE_IP}    ${STATIC_IP}    ${LOCAL_VM_PORT_LIST}    ${REMOTE_VM_PORT_LIST}    ${GROUP_ID}
    [Documentation]    Keyword to verify VM MAC in respective compute node groups
    ${LOCAL_VM_MAC_LIST}    BuiltIn.Wait Until Keyword Succeeds    30s    10s    MultiPathOperations.Get_VM_Mac    ${LOCAL_VM_PORT_LIST}
    ${REMOTE_VM_MAC_LIST}    BuiltIn.Wait Until Keyword Succeeds    30s    10s    MultiPathOperations.Get_VM_Mac    ${REMOTE_VM_PORT_LIST}
    ${OVS_GROUP}    Utils.Run Command On Remote System    ${COMPUTE_IP}    ${DUMP_GROUPS}
    ${MULTI_PATH_GROUP_ID}    BuiltIn.Should Match Regexp    ${OVS_GROUP}    group_id=${GROUP_ID}.*
    : FOR    ${VM_MAC}    IN    @{REMOTE_VM_MAC_LIST}
    \    BuiltIn.Should Contain    ${MULTI_PATH_GROUP_ID}    ${VM_MAC}
    ${LOCAL_GROUPS}    String.Get Regexp Matches    ${MULTI_PATH_GROUP_ID}    :15(\\d+)
    : FOR    ${VM_MAC}    ${LOCAL_GROUP_ID}    IN ZIP    ${LOCAL_VM_MAC_LIST}    ${LOCAL_GROUPS}
    \    ${VAL_1}    ${GROUP_NUM}    String.Split String    ${LOCAL_GROUP_ID}    :
    \    ${MATCH}    BuiltIn.Should Match Regexp    ${OVS_GROUP}    group_id=${GROUP_NUM}.*bucket=actions.*
    \    BuiltIn.Run Keyword and Ignore Error    BuiltIn.Should Contain    ${MATCH}    ${VM_MAC}

Get_VM_Mac
    [Arguments]    ${VM_PORT_NAME_LIST}    ${conn_id}=${devstack_conn_id}
    [Documentation]    Keyword to return the VM MAC ID
    ${MAC_ADDR_LIST}    BuiltIn.Create List
    : FOR    ${PORT_NAME}    IN    @{VM_PORT_NAME_LIST}
    \    ${rc}    ${output}=    OperatingSystem.Run And Return Rc And Output    openstack port list | grep ${PORT_NAME} | awk '{print $6}'
    \    BuiltIn.Log    ${output}
    \    Collections.Append To List    ${MAC_ADDR_LIST}    ${output}
    \    BuiltIn.Should Not Be True    ${rc}
    [Return]    ${MAC_ADDR_LIST}

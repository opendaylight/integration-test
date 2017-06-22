*** Settings ***
Documentation     Multi path library.
Library           SSHLibrary
Resource          Utils.robot
Resource          OVSDB.robot
Resource          OpenStackOperations.robot

*** Variables ***
${PING_RESP}      0
${PING_PASS}      ${0}
${EXPECTED_PACKET_COUNT}    20
${PING_REGEXP}    (\\d+)\\% packet loss
${NO_OF_PING_PACKETS}    15
${DUMP_FLOWS}     sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
${DUMP_GROUPS}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
${DUMP_GROUP_STATS}    sudo ovs-ofctl -O OpenFlow13 dump-group-stats br-int

*** Keywords ***
Verify_Flows_In_Compute_Node
    [Arguments]    ${COMPUTE_IP}    ${EXPECTED_LOCAL_BUCKET_ENTRY}    ${EXPECTED_REMOTE_BUCKET_ENTRY}    ${STATIC_IP}
    [Documentation]    Verify flows w.r.t a particular IP and the corresponding bucket entry
    ${OVS_FLOW}    Run Command On Remote System    ${COMPUTE_IP}    ${DUMP_FLOWS}
    ${OVS_GROUP}    Run Command On Remote System    ${COMPUTE_IP}    ${DUMP_GROUPS}
    ${MATCH}    ${GROUP_ID}    Should Match Regexp    ${OVS_FLOW}    table=21.*nw_dst=${STATIC_IP}.*group:(\\d+)
    ${MULTI_PATH_GROUP_ID}    Should Match Regexp    ${OVS_GROUP}    group_id=${GROUP_ID},type=select.*
    ${ACTUAL_LOCAL_BUCKET_ENTRY}    Get Regexp Matches    ${MULTI_PATH_GROUP_ID}    bucket=actions=group:(\\d+)
    Length Should Be    ${ACTUAL_LOCAL_BUCKET_ENTRY}    ${EXPECTED_LOCAL_BUCKET_ENTRY}
    ${ACTUAL_REMOTE_BUCKET_ENTRY}    Get Regexp Matches    ${MULTI_PATH_GROUP_ID}    resubmit
    Length Should Be    ${ACTUAL_REMOTE_BUCKET_ENTRY}    ${EXPECTED_REMOTE_BUCKET_ENTRY}

Verify_Packet_Count
    [Arguments]    ${COMPUTE_IP}    ${STATIC_IP}
    [Documentation]    Verify flows w.r.t a particular IP and packet count after ping
    ${OVS_FLOW}    Run Command On Remote System    ${COMPUTE_IP}    ${DUMP_FLOWS}
    ${OVS_GROUP_STAT}    Run Command On Remote System    ${COMPUTE_IP}    ${DUMP_GROUP_STATS}
    ${MATCH}    ${TOTAL_PACKET_COUNT}    ${GROUP_ID}    Should Match Regexp    ${OVS_FLOW}    table=21.*n_packets=(\\d+).*nw_dst=${STATIC_IP}.*group:(\\d+)
    ${MULTI_PATH_GROUP_STAT}    ${MULTI_PATH_GROUP_PACKET_COUNT}    Should Match Regexp    ${OVS_GROUP_STAT}    group_id=${GROUP_ID}.*,packet_count=(\\d+).*
    ${BUCKET_PACKET_COUNT}    Get Regexp Matches    ${MULTI_PATH_GROUP_STAT}    :packet_count=(..)    1
    ${TOTAL_PACKET_COUNT}    ConvertToInteger    ${MULTI_PATH_GROUP_PACKET_COUNT}
    ${TOTAL_OF_BUCKET_PACKET_COUNT}    Set Variable    ${0}
    : FOR    ${COUNT}    IN    @{BUCKET_PACKET_COUNT}
    \    ${TOTAL_OF_BUCKET_PACKET_COUNT}    Evaluate    ${TOTAL_OF_BUCKET_PACKET_COUNT}+int(${COUNT})
    Should Be Equal    ${TOTAL_PACKET_COUNT}    ${TOTAL_OF_BUCKET_PACKET_COUNT}

Get_Table21_Packet_Count
    [Arguments]    ${COMPUTE_IP}    ${STATIC_IP}
    [Documentation]    Get the packet count from table 21 for the specified IP
    ${OVS_FLOW}    Run Command On Remote System    ${COMPUTE_IP}    ${DUMP_FLOWS}
    ${MATCH}    ${PACKET_COUNT}    Should Match Regexp    ${OVS_FLOW}    table=21.*n_packets=(\\d+).*nw_dst=${STATIC_IP}.*
    Log    ${PACKET_COUNT}
    [Return]    ${PACKET_COUNT}

Generate_Next_Hop
    [Arguments]    ${IP}    ${MASK}    @{VM_IP_LIST}
    [Documentation]    Key word for generating next hop entries
    @{NEXT_HOP_LIST}    Create List
    : FOR    ${VM_IP}    IN    @{VM_IP_LIST}
    \    Append To List    ${NEXT_HOP_LIST}    --route destination=${IP}/${MASK},gateway=${VM_IP}
    [Return]    @{NEXT_HOP_LIST}

Configure_Next_Hop_on_Router
    [Arguments]    ${ROUTER_NAME}    ${NO_OF_STATIC_IP}    ${VM_LIST_1}    ${STATIC_IP_1}    ${VM_LIST_2}={EMPTY}    ${STATIC_IP_2}=${EMPTY}
    ...    ${MASK}=32
    [Documentation]    Key word for updating Next Hop Routes
    @{NEXT_HOP_LIST_1}    Generate_Next_Hop    ${STATIC_IP_1}    ${MASK}    @{VM_LIST_1}
    @{NEXT_HOP_LIST_2}    Run Keyword if    ${NO_OF_STATIC_IP}==${2}    Generate_Next_Hop    ${STATIC_IP2}    ${MASK}    @{VM_LIST_2}
    ${ROUTES_1}    catenate    @{NEXT_HOP_LIST_1}
    ${ROUTES_2}    catenate    @{NEXT_HOP_LIST_2}
    ${FINAL_ROUTE}    Set Variable If    ${NO_OF_STATIC_IP}==${2}    ${ROUTES_1} ${ROUTES_2}    ${ROUTES_1}
    Log    ${FINAL_ROUTE}
    Update Router    ${ROUTER_NAME}    ${FINAL_ROUTE}
    Show Router    ${ROUTER_NAME}    -D

Configure_IP_on_Sub_Interface
    [Arguments]    ${NETWORK_NAME}    ${IP}    ${VM_IP}    ${MASK}    ${SUB_INTERFACE_NUMBER}=0
    [Documentation]    Key word for configuring IP on sub interface
    Wait Until keyword succeeds    100s    20s    Run Keyword    Execute Command on VM Instance    ${NETWORK_NAME}    ${VM_IP}
    ...    sudo ifconfig eth0:${SUB_INTERFACE_NUMBER} ${IP} netmask 255.255.255.0 up

Verify_IP_Configured_on_Sub_Interface
    [Arguments]    ${NETWORK_NAME}    ${IP}    ${VM_IP}    ${SUB_INTERFACE_NUMBER}=0
    [Documentation]    Key word for verifying IP configured on sub interface
    ${RESP}    Execute Command on VM Instance    ${NETWORK_NAME}    ${VM_IP}    sudo ifconfig eth0:${SUB_INTERFACE_NUMBER}
    Should Contain    ${RESP}    ${IP}

Verify_Ping_to_Sub_Interface
    [Arguments]    ${NETWORK_NAME}    ${IP}    ${VM_IP}
    [Documentation]    Keyword to ping sub interface
    ${PING_RESP}    Execute Command on VM Instance    ${NETWORK_NAME}    ${VM_IP}    ping ${IP} -c ${NO_OF_PING_PACKETS}
    ${MATCH}    ${PACKET_COUNT}    Should Match Regexp    ${PING_RESP}    ${PING_REGEXP}
    ${PING_RESP}    Run Keyword If    ${PACKET_COUNT}<=${20}    Evaluate    ${PING_RESP}+0
    ...    ELSE    Evaluate    ${PING_RESP}+1
    Should Be Equal    ${PING_RESP}    ${PING_PASS}

Tep_Port_Operations
    [Arguments]    ${OPERATION}    ${COMPUTE_1_IP}    ${COMPUTE_2_IP}=${EMPTY}    ${COMPUTE_3_IP}=${EMPTY}
    [Documentation]    Keyword to add/delete tep port
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

Verify_Ping_and_Packet_Count
    [Arguments]    ${NETWORK_NAME}    ${IP}    ${VM_NAME}
    [Documentation]    Keyword to Verify Ping and Packet count
    ${COMPUTE_1_PACKET_COUNT_BEFORE_PING}    Get_Table21_Packet_Count    ${OS_COMPUTE_1_IP}    ${IP}
    ${COMPUTE_2_PACKET_COUNT_BEFORE_PING}    Get_Table21_Packet_Count    ${OS_COMPUTE_2_IP}    ${IP}
    ${COMPUTE_3_PACKET_COUNT_BEFORE_PING}    Get_Table21_Packet_Count    ${OS_COMPUTE_3_IP}    ${IP}
    Verify_Ping_to_Sub_Interface    ${NETWORK_NAME}    ${IP}    ${VM_NAME}
    ${COMPUTE_1_PACKET_COUNT_AFTER_PING}    Get_Table21_Packet_Count    ${OS_COMPUTE_1_IP}    ${IP}
    ${COMPUTE_2_PACKET_COUNT_AFTER_PING}    Get_Table21_Packet_Count    ${OS_COMPUTE_2_IP}    ${IP}
    ${COMPUTE_3_PACKET_COUNT_AFTER_PING}    Get_Table21_Packet_Count    ${OS_COMPUTE_3_IP}    ${IP}
    Log    Check via which Compute Node Packets are forwarded
    Run Keyword If    ${COMPUTE_1_PACKET_COUNT_AFTER_PING}==${COMPUTE_1_PACKET_COUNT_BEFORE_PING}+${NO_OF_PING_PACKETS}    Run Keywords    Log    Packets forwarded via Compute Node 1
    ...    AND    Verify_Packet_Count    ${OS_COMPUTE_1_IP}    ${IP}
    ...    ELSE IF    ${COMPUTE_2_PACKET_COUNT_AFTER_PING}==${COMPUTE_2_PACKET_COUNT_BEFORE_PING}+${NO_OF_PING_PACKETS}    Run Keywords    Log    Packets forwarded via Compute Node 2
    ...    AND    Verify_Packet_Count    ${OS_COMPUTE_2_IP}    ${IP}
    ...    ELSE IF    ${COMPUTE_3_PACKET_COUNT_AFTER_PING}==${COMPUTE_3_PACKET_COUNT_BEFORE_PING}+${NO_OF_PING_PACKETS}    Run Keywords    Log    Packets forwarded via Compute Node 3
    ...    AND    Verify_Packet_Count    ${OS_COMPUTE_3_IP}    ${IP}
    ...    ELSE    Log    Packets are not forwarded by any of the Compute Nodes

Verify_VM_MAC_in_groups
    [Arguments]    ${COMPUTE_IP}    ${STATIC_IP}    ${LOCAL_VM_PORT_LIST}    ${REMOTE_VM_PORT_LIST}
    [Documentation]    Keyword to verify vm mac in PING_RESPective compute node groups
    ${LOCAL_VM_MAC_LIST}    Get Ports MacAddr    ${LOCAL_VM_PORT_LIST}
    ${REMOTE_VM_MAC_LIST}    Get Ports MacAddr    ${REMOTE_VM_PORT_LIST}
    ${OVS_FLOW}    Run Command On Remote System    ${COMPUTE_IP}    ${DUMP_FLOWS}
    ${MATCH}    ${GROUP_ID}    Should Match Regexp    ${OVS_FLOW}    table=21.*nw_dst=${STATIC_IP}.*group:(\\d+)
    ${OVS_GROUP}    Run Command On Remote System    ${COMPUTE_IP}    ${DUMP_GROUPS}
    ${MULTI_PATH_GROUP_ID}    Should Match Regexp    ${OVS_GROUP}    group_id=${GROUP_ID}.*
    : FOR    ${VM_MAC}    IN    @{REMOTE_VM_MAC_LIST}
    \    Should Contain    ${MULTI_PATH_GROUP_ID}    ${VM_MAC}
    ${LOCAL_GROUPS}    Get Regexp Matches    ${MULTI_PATH_GROUP_ID}    :15(\\d+)
    : FOR    ${VM_MAC}    ${GROUP_ID}    IN ZIP    ${LOCAL_VM_MAC_LIST}    ${LOCAL_GROUPS}
    \    ${VAL_1}    ${GROUP_NUM}    Split String    ${GROUP_ID}    :
    \    ${MATCH}    Should Match Regexp    ${OVS_GROUP}    group_id=${GROUP_NUM}.*bucket=actions.*
    \    Run Keyword and Ignore Error    Should Contain    ${MATCH}    ${VM_MAC}

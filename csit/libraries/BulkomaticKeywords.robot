*** Settings ***
Documentation     Bulkomatic Keyword library contains keywords for performing bulkomatic operations
...               with a single bulkomatic API we can trigger bulk flows in config datastore which eventually populates switches and operational datastore
...               So far this library is only to be used by MD-SAL clustering and OpenFlowplugin clustering test as it is very specific for these tests
Library           RequestsLibrary
Library           Collections
Library           ./HsfJson/hsf_json.py
Resource          ${CURDIR}/ClusterKeywords.robot
Resource          ${CURDIR}/ClusterOpenFlow.robot
Resource          ${CURDIR}/MininetKeywords.robot
Resource          ${CURDIR}/Utils.robot
Variables         ../variables/Variables.py

*** Variables ***
${ADD_BULK_CONFIG_NODES_API}    restconf/operations/sal-bulk-flow:flow-test
${GET_BULK_CONFIG_NODES_API}    restconf/operations/sal-bulk-flow:read-flow-test
${INVENTORY_SHARD}    shard-inventory-config
${add_small_config}    sal_add_bulk_flow_small_config.json
${get_small_config}    sal_get_bulk_flow_small_config.json
${del_small_config}    sal_del_bulk_flow_small_config.json
${jolokia_write_op_status}    /jolokia/read/org.opendaylight.openflowplugin.applications.bulk.o.matic:type=FlowCounter/WriteOpStatus
${jolokia_read_op_status}    /jolokia/read/org.opendaylight.openflowplugin.applications.bulk.o.matic:type=FlowCounter/ReadOpStatus
${jolokia_flow_count_status}    /jolokia/read/org.opendaylight.openflowplugin.applications.bulk.o.matic:type=FlowCounter/FlowCount

*** Keywords ***
Operation Status Check
    [Arguments]    ${controller_ip}    ${op_status_uri}
    [Documentation]    Checks to see if read or write operation is successfull in controller node
    Create_Session    session    http://${controller_ip}:${RESTCONFPORT}    headers=${HEADERS}    auth=${AUTH}
    ${data}=    Utils.Get Data From URI    session    ${op_status_uri}
    Log    ${data}
    ${json}=    To Json    ${data}
    ${value}=    Get From Dictionary    ${json}    value
    ${value}=    Convert to String    ${value}
    ${two}=    Convert to String    2
    Should Start With    ${value}    ${two}

Get Write Op Status
    [Arguments]    ${controller_index_list}    ${jolokia_write_op_status}    ${timeout}
    [Documentation]    Checks Write operation status from ${controller_index_list}.
    : FOR    ${i}    IN    @{controller_index_list}
    \    Wait Until Keyword Succeeds    ${timeout}    25s    BulkomaticKeywords.Operation Status Check    ${ODL_SYSTEM_${i}_IP}    ${jolokia_write_op_status}

Get Read Op Status
    [Arguments]    ${controller_index_list}    ${jolokia_read_op_status}    ${timeout}
    [Documentation]    Checks Read operation status from ${controller_index_list}.
    : FOR    ${i}    IN    @{controller_index_list}
    \    ${data}    Wait Until Keyword Succeeds    ${timeout}    25s    BulkomaticKeywords.Operation Status Check    ${ODL_SYSTEM_${i}_IP}
    \    ...    ${jolokia_read_op_status}

Get Flow Count Status
    [Arguments]    ${controller_index_list}    ${jolokia_flow_cout_api}    ${jolokia_flow_cout}
    [Documentation]    Read flow count from ${controller_index_list}.
    : FOR    ${i}    IN    @{controller_index_list}
    \    Create_Session    session    http://${ODL_SYSTEM_${i}_IP}:${RESTCONFPORT}    headers=${HEADERS}    auth=${AUTH}
    \    ${data}=    Utils.Get Data From URI    session    ${jolokia_flow_cout_api}
    \    Log    ${data}
    \    ${json}=    To Json    ${data}
    \    ${value}=    Get From Dictionary    ${json}    value
    \    Should Be Equal As Strings    ${value}    ${jolokia_flow_cout}

Verify Bulk Flow In Node
    [Arguments]    ${session}    ${get_uri}    ${get_body}    ${headers}
    [Documentation]    Initiate Verify Bulk Flows at each node
    ${response}    RequestsLibrary.Post Request    session    ${get_uri}    ${get_body}    ${headers}
    Should Be Equal As Strings    ${response.status_code}    200

Verify Bulk Flow In Cluster Nodes
    [Arguments]    ${controller_index_list}    ${timeout}    ${get_uri}    ${get_body}    ${headers}=${HEADERS_YANG_JSON}
    [Documentation]    Verify Bulk Flows installed in Cluster Nodes
    : FOR    ${i}    IN    @{controller_index_list}
    \    Create_Session    session    http://${ODL_SYSTEM_${i}_IP}:${RESTCONFPORT}    ${headers}    auth=${AUTH}
    \    Wait Until Keyword Succeeds    ${timeout}    5s    BulkomaticKeywords.Verify Bulk Flow In Node    session    ${get_uri}
    \    ...    ${get_body}    ${headers}

Add Bulk Flow
    [Arguments]    ${controller_index_list}    ${add_bulk_json_file}
    [Documentation]    Add bulk flow in ${controller_index}
    ${add_body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/${add_bulk_json_file}
    ${resp}    RequestsLibrary.Post Request    ${controller_index_list}    ${ADD_BULK_CONFIG_NODES_API}    ${add_body}    headers=${HEADERS_YANG_JSON}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Delete Bulk Flow
    [Arguments]    ${controller_index_list}    ${del_bulk_json_file}
    [Documentation]    Delete sample flow in ${controller_index}
    ${del_body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/${del_bulk_json_file}
    ${resp}    RequestsLibrary.Post Request    ${controller_index_list}    ${ADD_BULK_CONFIG_NODES_API}    ${del_body}    headers=${HEADERS_YANG_JSON}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify Bulk Flow
    [Arguments]    ${controller_index_list}    ${get_bulk_json_file}    ${timeout}
    [Documentation]    Verify Bulk flows get replicated in all instances in ${controller_index_list}
    ${get_body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/${get_bulk_json_file}
    BulkomaticKeywords.Verify Bulk Flow In Cluster Nodes    ${controller_index_list}    ${timeout}    ${GET_BULK_CONFIG_NODES_API}    ${get_body}    headers=${HEADERS_YANG_JSON}


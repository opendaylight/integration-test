*** Settings ***
Documentation     Bulkomatic Keyword library contains keywords for performing bulkomatic operations
...               with a single bulkomatic API we can trigger bulk flows in config datastore which eventually populates switches and operational datastore
...               So far this library is only to be used by MD-SAL clustering and OpenFlowplugin clustering test as it is very specific for these tests
Resource          Utils.robot
Variables         ../variables/Variables.py

*** Variables ***
${ADD_BULK_CONFIG_NODES_API}    /restconf/operations/sal-bulk-flow:flow-test
${GET_BULK_CONFIG_NODES_API}    /restconf/operations/sal-bulk-flow:read-flow-test
${jolokia_write_op_status}    /jolokia/read/org.opendaylight.openflowplugin.applications.bulk.o.matic:type=FlowCounter/WriteOpStatus
${jolokia_read_op_status}    /jolokia/read/org.opendaylight.openflowplugin.applications.bulk.o.matic:type=FlowCounter/ReadOpStatus
${jolokia_flow_count_status}    /jolokia/read/org.opendaylight.openflowplugin.applications.bulk.o.matic:type=FlowCounter/FlowCount

*** Keywords ***
Operation Status Check
    [Arguments]    ${controller_index}    ${op_status_uri}
    [Documentation]    Checks to see if read or write operation is successfull in controller node.
    ${data}=    Utils.Get Data From URI    controller${controller_index}    ${op_status_uri}
    Log    ${data}
    ${json}=    To Json    ${data}
    ${value}=    Get From Dictionary    ${json}    value
    ${value}=    Convert to String    ${value}
    ${two}=    Convert to String    2
    Should Start With    ${value}    ${two}

Wait Until Write Finishes
    [Arguments]    ${controller_index}    ${timeout}
    [Documentation]    Wait Until Write operation status is OK in ${controller_index}.
    Wait Until Keyword Succeeds    ${timeout}    1s    BulkomaticKeywords.Operation Status Check    ${controller_index}    ${jolokia_write_op_status}

Wait Until Read Finishes
    [Arguments]    ${controller_index}    ${timeout}
    [Documentation]    Wait Until Read operation status is OK in ${controller_index}.
    Wait Until Keyword Succeeds    ${timeout}    1s    BulkomaticKeywords.Operation Status Check    ${controller_index}    ${jolokia_read_op_status}

Add Bulk Flow
    [Arguments]    ${controller_index}    ${add_bulk_json_file}
    [Documentation]    Add Bulk Flow in ${controller_index} according to ${add_bulk_json_file}.
    ${add_body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/${add_bulk_json_file}
    ${resp}    Utils.Post Elements To URI    ${ADD_BULK_CONFIG_NODES_API}    ${add_body}    headers=${HEADERS_YANG_JSON}    session=controller${controller_index}

Delete Bulk Flow
    [Arguments]    ${controller_index}    ${del_bulk_json_file}
    [Documentation]    Delete Bulk Flow in ${controller_index} according to ${del_bulk_json_file}.
    ${del_body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/${del_bulk_json_file}
    ${resp}    Utils.Post Elements To URI    ${ADD_BULK_CONFIG_NODES_API}    ${del_body}    headers=${HEADERS_YANG_JSON}    session=controller${controller_index}

Get Bulk Flow
    [Arguments]    ${controller_index}    ${get_bulk_json_file}
    [Documentation]    Get Bulk Flow in ${controller_index} according to ${get_bulk_json_file}.
    ${get_body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/${get_bulk_json_file}
    ${resp}    Utils.Post Elements To URI    ${GET_BULK_CONFIG_NODES_API}    ${get_body}    headers=${HEADERS_YANG_JSON}    session=controller${controller_index}

Get Bulk Flow Count
    [Arguments]    ${controller_index}
    [Documentation]    Get Flow count in ${controller_index}. New Flow Count is available after Get Bulk Flow operation.
    ${data}=    Utils.Get Data From URI    controller${controller_index}    ${jolokia_flow_count_status}
    Log    ${data}
    [Return]    ${data}

Verify Flow Count
    [Arguments]    ${controller_index}    ${flow_count}
    [Documentation]    Verify Flow Count in ${controller_index} matches ${flow_count}.
    ${data}=    Get Bulk Flow Count    ${controller_index}
    Log    ${data}
    ${json}=    To Json    ${data}
    ${value}=    Get From Dictionary    ${json}    value
    Should Be Equal As Strings    ${value}    ${flow_count}

Add Bulk Flow In Node
    [Arguments]    ${controller_index}    ${add_bulk_json_file}    ${timeout}
    [Documentation]    Add Bulk Flow in ${controller_index} and wait until operation is completed.
    Add Bulk Flow    ${controller_index}    ${add_bulk_json_file}
    Wait Until Write Finishes    ${controller_index}    ${timeout}

Delete Bulk Flow In Node
    [Arguments]    ${controller_index}    ${delete_bulk_json_file}    ${timeout}
    [Documentation]    Delete Bulk Flow in ${controller_index} and wait until operation is completed.
    Delete Bulk Flow    ${controller_index}    ${delete_bulk_json_file}
    Wait Until Write Finishes    ${controller_index}    ${timeout}

Get Bulk Flow And Verify Count In Cluster
    [Arguments]    ${controller_index_list}    ${get_bulk_json_file}    ${timeout}    ${flow_count}
    [Documentation]    Get Bulk Flow and Verify Flow Count in ${controller_index_list} matches ${flow_count}.
    : FOR    ${index}    IN    @{controller_index_list}
    \    Get Bulk Flow    ${index}    ${get_bulk_json_file}
    : FOR    ${index}    IN    @{controller_index_list}
    \    Wait Until Read Finishes    ${index}    ${timeout}
    : FOR    ${index}    IN    @{controller_index_list}
    \    Verify Flow Count    ${index}    ${flow_count}

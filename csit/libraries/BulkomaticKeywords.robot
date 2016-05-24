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
    [Documentation]    Checks to see if read or write operation is successfull in controller node
    ${data}=    Utils.Get Data From URI    controller${controller_index}    ${op_status_uri}
    Log    ${data}
    ${json}=    To Json    ${data}
    ${value}=    Get From Dictionary    ${json}    value
    ${value}=    Convert to String    ${value}
    ${two}=    Convert to String    2
    Should Start With    ${value}    ${two}

Wait Until Write Finishes
    [Arguments]    ${controller_index}    ${timeout}
    [Documentation]    Checks Write operation status from ${controller_index}.
    Wait Until Keyword Succeeds    ${timeout}    1s    BulkomaticKeywords.Operation Status Check    ${controller_index}    ${jolokia_write_op_status}

Wait Until Read Finishes
    [Arguments]    ${controller_index}    ${timeout}
    [Documentation]    Checks Read operation status from ${controller_index}.
    Wait Until Keyword Succeeds    ${timeout}    1s    BulkomaticKeywords.Operation Status Check    ${controller_index}    ${jolokia_read_op_status}

Add Bulk Flow
    [Arguments]    ${controller_index}    ${add_bulk_json_file}=${add_small_config}
    [Documentation]    Add bulk flow in ${controller_index}
    ${add_body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/${add_bulk_json_file}
    ${resp}    Utils.Post Elements To URI    ${ADD_BULK_CONFIG_NODES_API}    ${add_body}    headers=${HEADERS_YANG_JSON}    session=controller${controller_index}

Delete Bulk Flow
    [Arguments]    ${controller_index}    ${del_bulk_json_file}=${del_small_config}
    [Documentation]    Delete sample flow in ${controller_index}
    ${del_body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/${del_bulk_json_file}
    ${resp}    Utils.Post Elements To URI    ${ADD_BULK_CONFIG_NODES_API}    ${del_body}    headers=${HEADERS_YANG_JSON}    session=controller${controller_index}

Get Bulk Flow
    [Arguments]    ${controller_index}    ${get_bulk_json_file}=${get_small_config}
    [Documentation]    Get Bulk Flow in ${controller_index}
    ${get_body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/${get_bulk_json_file}
    ${resp}    Utils.Post Elements To URI    ${GET_BULK_CONFIG_NODES_API}    ${get_body}    headers=${HEADERS_YANG_JSON}    session=controller${controller_index}

Get Bulk Flow Count
    [Arguments]    ${controller_index}
    [Documentation]    Get Flow count in ${controller_index}
    ${data}=    Utils.Get Data From URI    controller${controller_index}    ${jolokia_flow_count_status}
    Log    ${data}
    [Return]    ${data}

Verify Flow Count
    [Arguments]    ${controller_index}    ${jolokia_flow_cout}
    [Documentation]    Verify Flow Count in ${controller_index}.
    ${data}=    Get Bulk Flow Count    ${controller_index}
    Log    ${data}
    ${json}=    To Json    ${data}
    ${value}=    Get From Dictionary    ${json}    value
    Should Be Equal As Strings    ${value}    ${jolokia_flow_cout}

Add Bulk Flow In Node
    [Arguments]    ${controller_index}    ${add_bulk_json_file}    ${timeout}
    [Documentation]    Add Small Config Bulk Flow in ${controller_index}
    Add Bulk Flow    ${controller_index}    ${add_bulk_json_file}
    Wait Until Write Finishes    ${controller_index}    ${timeout}

Delete Bulk Flow In Node
    [Arguments]    ${controller_index}    ${delete_bulk_json_file}    ${timeout}
    [Documentation]    Delete Small Config Bulk Flow in ${controller_index}
    Delete Bulk Flow    ${controller_index}    ${delete_bulk_json_file}
    Wait Until Write Finishes    ${controller_index}    ${timeout}

Get Bulk Flow And Verify Count In Cluster
    [Arguments]    ${controller_index_list}    ${get_bulk_json_file}    ${timeout}    ${flow_count}
    [Documentation]    Get Config Bulk Flow and Verify Flow Count in ${controller_index_list}
    : FOR    ${index}    IN    @{controller_index_list}
    \    Get Bulk Flow    ${index}    ${get_bulk_json_file}
    : FOR    ${index}    IN    @{controller_index_list}
    \    Wait Until Read Finishes    ${index}    ${timeout}
    : FOR    ${index}    IN    @{controller_index_list}
    \    Verify Flow Count    ${index}    ${flow_count}

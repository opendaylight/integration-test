*** Settings ***
Documentation       Bulkomatic Keyword library contains keywords for performing bulkomatic operations
...                 with a single bulkomatic API we can trigger bulk flows in config datastore which eventually populates switches and operational datastore
...                 So far this library is only to be used by MD-SAL clustering and OpenFlowplugin clustering test as it is very specific for these tests

Resource            Utils.robot
Variables           ../variables/Variables.py


*** Variables ***
${ADD_BULK_CONFIG_NODES_API}    /rests/operations/sal-bulk-flow:flow-test
${GET_BULK_CONFIG_NODES_API}    /rests/operations/sal-bulk-flow:read-flow-test
${ADD_TABLE_NODEs_API}          /rests/operations/sal-bulk-flow:table-test
${jolokia_write_op_status}
...                             /jolokia/read/org.opendaylight.openflowplugin.applications.bulk.o.matic:type=FlowCounter/WriteOpStatus
${jolokia_read_op_status}
...                             /jolokia/read/org.opendaylight.openflowplugin.applications.bulk.o.matic:type=FlowCounter/ReadOpStatus
${jolokia_flow_count_status}
...                             /jolokia/read/org.opendaylight.openflowplugin.applications.bulk.o.matic:type=FlowCounter/FlowCount


*** Keywords ***
Operation Status Check
    [Documentation]    Checks to see if read or write operation is successfull in controller node.
    [Arguments]    ${op_status_uri}    ${controller_index}
    ${data}=    ClusterManagement.Get From Member    ${op_status_uri}    ${controller_index}
    ${json}=    To Json    ${data}
    ${value}=    Get From Dictionary    ${json}    value
    ${value}=    Convert to String    ${value}
    ${two}=    Convert to String    2
    Should Start With    ${value}    ${two}

Wait Until Write Finishes
    [Documentation]    Wait Until Write operation status is OK in member ${controller_index}.
    [Arguments]    ${controller_index}    ${timeout}
    Wait Until Keyword Succeeds
    ...    ${timeout}
    ...    1s
    ...    BulkomaticKeywords.Operation Status Check
    ...    ${jolokia_write_op_status}
    ...    ${controller_index}

Wait Until Read Finishes
    [Documentation]    Wait Until Read operation status is OK in member ${controller_index}.
    [Arguments]    ${controller_index}    ${timeout}
    Wait Until Keyword Succeeds
    ...    ${timeout}
    ...    1s
    ...    BulkomaticKeywords.Operation Status Check
    ...    ${jolokia_read_op_status}
    ...    ${controller_index}

Add Bulk Flow
    [Documentation]    Add Bulk Flow in member ${controller_index} according to \${json_body_add}.
    [Arguments]    ${json_body_add}    ${controller_index}
    ${resp}=    ClusterManagement.Post As Json To Member
    ...    ${ADD_BULK_CONFIG_NODES_API}
    ...    ${json_body_add}
    ...    ${controller_index}

Add Table Flow
    [Documentation]    Add Table in member ${controller_index} according to \${json_body_add}.
    [Arguments]    ${json_body_add}    ${controller_index}
    ${resp}=    ClusterManagement.Post As Json To Member
    ...    ${ADD_TABLE_NODEs_API}
    ...    ${json_body_add}
    ...    ${controller_index}

Delete Bulk Flow
    [Documentation]    Delete Bulk Flow in member ${controller_index} according to \${json_body_del}.
    [Arguments]    ${json_body_del}    ${controller_index}
    ${resp}=    ClusterManagement.Post As Json To Member
    ...    ${ADD_BULK_CONFIG_NODES_API}
    ...    ${json_body_del}
    ...    ${controller_index}

Get Bulk Flow
    [Documentation]    Get Bulk Flow in member ${controller_index} according to \${json_body_get}.
    [Arguments]    ${json_body_get}    ${controller_index}
    ${resp}=    ClusterManagement.Post As Json To Member
    ...    ${GET_BULK_CONFIG_NODES_API}
    ...    ${json_body_get}
    ...    ${controller_index}

Get Bulk Flow Count
    [Documentation]    Get Flow count in member ${controller_index}. New Flow Count is available after Get Bulk Flow operation.
    [Arguments]    ${controller_index}
    ${data}=    ClusterManagement.Get From Member    ${jolokia_flow_count_status}    ${controller_index}
    RETURN    ${data}

Verify Flow Count
    [Documentation]    Verify Flow Count in member ${controller_index} matches ${flow_count}.
    [Arguments]    ${flow_count}    ${controller_index}
    ${data}=    Get Bulk Flow Count    ${controller_index}
    ${json}=    To Json    ${data}
    ${value}=    Get From Dictionary    ${json}    value
    Should Be Equal As Strings    ${value}    ${flow_count}

Add Bulk Flow In Node
    [Documentation]    Add Bulk Flow in member ${controller_index} and wait until operation is completed.
    [Arguments]    ${json_body_add}    ${controller_index}    ${timeout}
    Add Bulk Flow    ${json_body_add}    ${controller_index}
    Wait Until Write Finishes    ${controller_index}    ${timeout}

Add Table In Node
    [Documentation]    Add Table Flow in member ${controller_index} and wait until operation is completed.
    [Arguments]    ${json_body_add}    ${controller_index}    ${timeout}
    Add Table Flow    ${json_body_add}    ${controller_index}
    Wait Until Write Finishes    ${controller_index}    ${timeout}

Delete Bulk Flow In Node
    [Documentation]    Delete Bulk Flow in member ${controller_index} and wait until operation is completed.
    [Arguments]    ${json_body_del}    ${controller_index}    ${timeout}
    Delete Bulk Flow    ${json_body_del}    ${controller_index}
    Wait Until Write Finishes    ${controller_index}    ${timeout}

Get Bulk Flow And Verify Count In Cluster
    [Documentation]    Get Bulk Flow and Verify Flow Count in ${controller_index_list} matches ${flow_count}.
    [Arguments]    ${json_body_get}    ${timeout}    ${flow_count}    ${controller_index_list}=${EMPTY}
    ${index_list}=    ClusterManagement.List Indices Or All    given_list=${controller_index_list}
    FOR    ${index}    IN    @{index_list}
        Get Bulk Flow    ${json_body_get}    ${index}
    END
    FOR    ${index}    IN    @{index_list}
        Wait Until Read Finishes    ${index}    ${timeout}
    END
    FOR    ${index}    IN    @{index_list}
        Verify Flow Count    ${flow_count}    ${index}
    END

Set DPN And Flow Count In Json Add
    [Documentation]    Set new DPN count and flows count per DPN in the Bulkomatic Add json file.
    [Arguments]    ${json_config}    ${dpn_count}    ${flows_count}
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/${json_config}
    ${get_string}=    Set Variable    "sal-bulk-flow:dpn-count" : "1"
    ${put_string}=    Set Variable    "sal-bulk-flow:dpn-count" : "${dpn_count}"
    ${str}=    Replace String Using Regexp    ${body}    ${get_string}    ${put_string}
    ${get_string}=    Set Variable    "sal-bulk-flow:flows-per-dpn" : "1000"
    ${put_string}=    Set Variable    "sal-bulk-flow:flows-per-dpn" : "${flows_count}"
    ${json_body_add}=    Replace String Using Regexp    ${str}    ${get_string}    ${put_string}
    ${get_string}=    Set Variable    "sal-bulk-flow:batch-size" : "1"
    ${put_string}=    Set Variable    "sal-bulk-flow:batch-size" : "${flows_count}"
    ${json_body_add}=    Replace String Using Regexp    ${json_body_add}    ${get_string}    ${put_string}
    Log    ${json_body_add}
    RETURN    ${json_body_add}

Set DPN And Flow Count In Json Get
    [Documentation]    Set new DPN count and flows count per DPN in the Bulkomatic Get json file.
    [Arguments]    ${json_config}    ${dpn_count}    ${flows_count}
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/${json_config}
    ${get_string}=    Set Variable    "sal-bulk-flow:dpn-count" : "1"
    ${put_string}=    Set Variable    "sal-bulk-flow:dpn-count" : "${dpn_count}"
    ${str}=    Replace String Using Regexp    ${body}    ${get_string}    ${put_string}
    ${get_string}=    Set Variable    "sal-bulk-flow:flows-per-dpn" : "1000"
    ${put_string}=    Set Variable    "sal-bulk-flow:flows-per-dpn" : "${flows_count}"
    ${json_body_get}=    Replace String Using Regexp    ${str}    ${get_string}    ${put_string}
    Log    ${json_body_get}
    RETURN    ${json_body_get}

Set DPN And Flow Count In Json Del
    [Documentation]    Set new DPN count and flows count per DPN in the Bulkomatic Del json file.
    [Arguments]    ${json_config}    ${dpn_count}    ${flows_count}
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/${json_config}
    ${get_string}=    Set Variable    "sal-bulk-flow:dpn-count" : "1"
    ${put_string}=    Set Variable    "sal-bulk-flow:dpn-count" : "${dpn_count}"
    ${str}=    Replace String Using Regexp    ${body}    ${get_string}    ${put_string}
    ${get_string}=    Set Variable    "sal-bulk-flow:flows-per-dpn" : "1000"
    ${put_string}=    Set Variable    "sal-bulk-flow:flows-per-dpn" : "${flows_count}"
    ${json_body_del}=    Replace String Using Regexp    ${str}    ${get_string}    ${put_string}
    ${get_string}=    Set Variable    "sal-bulk-flow:batch-size" : "1"
    ${put_string}=    Set Variable    "sal-bulk-flow:batch-size" : "${flows_count}"
    ${json_body_del}=    Replace String Using Regexp    ${json_body_del}    ${get_string}    ${put_string}
    Log    ${json_body_del}
    RETURN    ${json_body_del}

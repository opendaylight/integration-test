*** Settings ***
Library           Collections
Library           RequestsLibrary
Variables         ../variables/Variables.py

*** Keywords ***
Create Records
    [Arguments]    ${controller_ip}    ${node}    ${first}    ${last}    ${prefix}    ${field bases}    ${postfix}
    [Documentation]    POSTs records to a controller's data store. First and last index numbers are specified
    ...    as is a dictionary called field_bases containing the base name for the field contents
    ...    onto which will be appended the index number. Prefix and postfix are used to complete
    ...    the JSON payload. The keyword passes if return code is correct.
    ${last}    Convert to Integer    ${last}
    : FOR    ${INDEX}    IN RANGE    ${first}    ${last+1}
    \    ${payload}=    Assemble Payload    ${INDEX}    ${prefix}    ${field bases}    ${postfix}
    \    Log    ${payload}
    \    Create_Session    session    http://${controller_ip}:${RESTCONFPORT}${CONFIG_API}    headers=${HEADERS}    auth=${AUTH}
    \    ${resp}    RequestsLibrary.Post    session    ${node}    ${payload}
    \    Log    ${resp}
    \    Should Be Equal As Strings    ${resp}    <Response [204]>

Read Records
    [Arguments]    ${controller_ip}    ${node}
    [Documentation]    GETs records from a shard on a controller's data store.
    Create_Session    session    http://${controller_ip}:${RESTCONFPORT}${CONFIG_API}    headers=${HEADERS}    auth=${AUTH}
    ${resp}=    RequestsLibrary.Get    session    ${node}
    [Return]    ${resp.json()}

Update Records
    [Arguments]    ${controller_ip}    ${node}    ${first}    ${last}    ${prefix}    ${field bases}    ${postfix}
    [Documentation]    PUTs records to shard on a controller's data store. First and last index numbers are specified
    ...    as is a dictionary called field_bases containing the base name for the field contents
    ...    onto which will be appended the index number. Prefix and postfix are used to complete
    ...    the JSON payload. The keyword passes if return code is correct.
    ${last}    Convert to Integer    ${last}
    : FOR    ${INDEX}    IN RANGE    ${first}    ${last+1}
    \    ${payload}=    Assemble Payload    ${INDEX}    ${prefix}    ${field bases}    ${postfix}
    \    Log    ${payload}
    \    Create_Session    session    http://${controller_ip}:${RESTCONFPORT}${CONFIG_API}    headers=${HEADERS}    auth=${AUTH}
    \    ${resp}=    RequestsLibrary.Put    session    ${node}/${INDEX}    ${payload}
    \    Log    ${resp}
    \    Should Be Equal As Strings    ${resp}    <Response [200]>

Delete Records
    [Arguments]    ${controller_ip}    ${node}    ${first}    ${last}
    [Documentation]    DELETEs specified range of records from a shard on a contrsoller's data store.
    ${last}    Convert to Integer    ${last}
    : FOR    ${INDEX}    IN RANGE    ${first}    ${last+1}
    \    Create_Session    session    http://${controller_ip}:${RESTCONFPORT}${CONFIG_API}    headers=${HEADERS}    auth=${AUTH}
    \    ${resp}=    RequestsLibrary.Delete    session    ${node}/${INDEX}
    \    Should Be Equal As Strings    ${resp}    <Response [200]>

Delete All Records
    [Arguments]    ${controller_ip}    ${node}
    [Documentation]    DELETEs all records from a shard on a controller's data store.
    Create_Session    session    http://${controller_ip}:${RESTCONFPORT}${CONFIG_API}    headers=${HEADERS}    auth=${AUTH}
    ${resp}=    RequestsLibrary.Delete    session    ${node}
    Should Be Equal As Strings    ${resp}    <Response [200]>

Assemble Payload
    [Arguments]    ${id}    ${prefix}    ${field bases}    ${postfix}
    [Documentation]    Populates a payload for creating or updating a shard record.
    ...    id: The record number and is also appended onto each field to uniquely identify it.
    ...    prefix: The portion of the json payload before the records.
    ...    field bases: A dictionary of records onto which the id is appended.
    ...    prefix: The portion of the json payload after the records.
    ${length}=    Get Length    ${field bases}
    ${keys}=    Get Dictionary Keys    ${field bases}
    ${payload}=    Set Variable    ${prefix}
    : FOR    ${key string}    IN    @{keys}
    \    ${value string}=    Get From Dictionary    ${field bases}    ${key string}
    \    ${payload}=    Catenate    ${payload}    "${key string}": "${value string}${id}",
    ${payload}=    Get Substring    ${payload}    ${EMPTY}    -1
    ${payload}=    Catenate    ${payload}    ${postfix}
    [Return]    ${payload}

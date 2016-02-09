*** Settings ***
Library           SSHLibrary
Library           String
Library           DateTime
Library           Collections
Library           json
Library           RequestsLibrary
Variables         ../variables/Variables.py
Resource          ./Utils.robot
Resource          Scalability.robot

*** Variables ***
${switches}       2
${REST_CONTEXT_INTENT}    restconf/config/intent:intents/intent
${INTENTS}        restconf/config/intent:intents
${VTN_INVENTORY}    restconf/operational/vtn-inventory:vtn-nodes
${INTENT_ID}      b9a13232-525e-4d8c-be21-cd65e3436033
${SERVICE_FUNCTIONS_URI}    /restconf/config/service-function:service-functions/
${SERVICE_FUNCTIONS_FILE}    ${CURDIR}/../variables/redirect/service-functions.json
${SERVICE_FORWARDERS_URI}    /restconf/config/service-function-forwarder:service-function-forwarders/
${SERVICE_FORWARDERS_FILE}    ${CURDIR}/../variables/redirect/service-function-forwarders.json

*** Keywords ***
Start NIC VTN Renderer Suite
    [Documentation]    Start Nic VTN Renderer Init Test Suite
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    BuiltIn.Wait_Until_Keyword_Succeeds    30    3    Fetch Intent List

Stop NIC VTN Renderer Suite
    [Documentation]    Stop Nic VTN Renderer Test Suite
    Delete All Sessions

Start NIC VTN Rest Test Suite
    [Documentation]    Start Nic VTN Renderer Rest Test Suite
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Clean Mininet System
    Start Mininet Linear    ${switches}

Stop NIC VTN Rest Test Suite
    [Documentation]    Stop Nic VTN Renderer Test Suite
    Stop Mininet    ${mininet_conn_id}

Fetch Intent List
    [Documentation]    Check if VTN Renderer feature is installed.
    ${resp}=    RequestsLibrary.Get Request    session    ${INTENTS}
    Should Be Equal As Strings    ${resp.status_code}    200

Add Intent Using RestConf
    [Arguments]    ${intent_id}    ${intent_data}
    [Documentation]    Create a intent with specified parameters.
    ${resp}=    RequestsLibrary.put Request    session    ${REST_CONTEXT_INTENT}/${intent_id}    data=${intent_data}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify Intent Using RestConf
    [Arguments]    ${intent_id}
    [Documentation]    Verify If intent is created.
    ${resp}=    RequestsLibrary.Get Request    session    ${REST_CONTEXT_INTENT}/${intent_id}
    Should Be Equal As Strings    ${resp.status_code}    200

Update Intent Using RestConf
    [Arguments]    ${intent_id}    ${intent_data}
    [Documentation]    Update a intent with specified parameters.
    ${resp}=    RequestsLibrary.put Request    session    ${REST_CONTEXT_INTENT}/${intent_id}    data=${intent_data}
    Should Be Equal As Strings    ${resp.status_code}    200

Delete Intent Using RestConf
    [Arguments]    ${intent_id}
    [Documentation]    Delete a intent with specified parameters.
    ${resp}=    RequestsLibrary.Delete Request    session    ${REST_CONTEXT_INTENT}/${intent_id}
    Should Be Equal As Strings    ${resp.status_code}    200

Add Intent From Karaf Console
    [Arguments]    ${intent_from}    ${intent_to}    ${intent_permission}
    [Documentation]    Adds an intent to the controller, and returns the id of the intent created.
    ${output}=    Issue Command On Karaf Console    intent:add -f ${intent_from} -t ${intent_to} -a ${intent_permission}
    Should Contain    ${output}    Intent created
    ${output}=    Fetch From Left    ${output}    )
    ${output_split}=    Split String    ${output}    ${SPACE}
    ${id}=    Get From List    ${output_split}    3
    [Return]    ${id}

Remove Intent From Karaf Console
    [Arguments]    ${id}
    [Documentation]    Removes an intent from the controller via the provided intent id.
    ${output}=    Issue Command On Karaf Console    intent:remove ${id}
    Should Contain    ${output}    Intent successfully removed
    ${output}=    Issue Command On Karaf Console    log:display |grep "Removed VTN configuration associated with the deleted Intent: "
    Should Contain    ${output}    Removed VTN configuration associated with the deleted Intent    ${id}

Mininet Ping Should Succeed
    [Arguments]    ${host1}    ${host2}
    [Timeout]    2 minute
    Write    ${host1} ping -c 10 ${host2}
    ${result}    Read Until    mininet>
    Should Contain    ${result}    64 bytes

Mininet Ping Should Not Succeed
    [Arguments]    ${host1}    ${host2}
    [Timeout]    2 minute
    Write    ${host1} ping -c 10 ${host2}
    ${result}    Read Until    mininet>
    Should Not Contain    ${result}    64 bytes

Start NIC Redirect Test Suite
    [Documentation]    Start Nic Redirect Rest Test Suite
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Stop NIC Redirect Test Suite
    [Documentation]    Stop Nic Redirect Test Suite
    Delete All Sessions

Add Service Functions Using RestConf
    [Documentation]    Create a Service Function.
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTIONS_FILE}
    ${jsonbody}    To Json    ${body}
    ${resp}=    RequestsLibrary.put    session    ${SERVICE_FUNCTIONS_URI}    data=${jsonbody}
    Should Be Equal As Strings    ${resp.status_code}    200

Add Service Function Forwarders Using RestConf
    [Documentation]    Create Service Function Forwarders.
    ${body}    OperatingSystem.Get File    ${SERVICE_FORWARDERS_FILE}
    ${jsonbody}    To Json    ${body}
    ${resp}=    RequestsLibrary.put    session    ${SERVICE_FORWARDERS_URI}    data=${jsonbody}
    Should Be Equal As Strings    ${resp.status_code}    200

Create Intent From Karaf Console For Redirect
    [Arguments]    ${from}    ${to}    ${action}    ${service_name}
    [Documentation]    Creates an intent to the controller, and returns the id of the intent created.
    Issue Command On Karaf Console    log:clear
    ${output}=    Issue Command On Karaf Console    intent:add -f ${from} -t ${to} -a ${action} -f ${service_name}
    Should Contain    ${output}    Intent created
    ${output}=    Fetch From Left    ${output}    )
    ${output_split}=    Split String    ${output}    ${SPACE}
    ${id}=    Get From List    ${output_split}    3
    [Return]    ${id}

Delete Intent From Karaf Console For Redirect
    [Arguments]    ${id}
    [Documentation]    Removes an intent from the controller via the provided intent id.
    ${output}=    Issue Command On Karaf Console    intent:remove ${id}
    Should Contain    ${output}    Intent successfully removed
    ${output}=    Wait Until Keyword Succeeds    300s    2s    Issue Command On Karaf Console    log:display |grep "initIntentsConfiguration: config populated: Intents"
    Should Contain    ${output}    ${id}


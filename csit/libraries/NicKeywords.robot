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

${DUMPFLOWS_OF10}    dpctl dump-flows -O OpenFlow13
${dscp_flow}    mod_nw_tos
${normal_flow}    NORMAL


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
    ${output}=    Issue Command On Karaf Console    log:display | grep "Removed VTN configuration associated with the deleted Intent: "
    # The below log statements has changed an info to trace mode in Beryllium, and in future release will roll back the same.
    #Should Contain    ${output}    Removed VTN configuration associated with the deleted Intent    ${id}

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


Start NIC OF Renderer Suite
    [Documentation]    Start Nic OF Renderer Init Test Suite
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Start Suite

Stop NIC OF Rest Test Suite
    [Documentation]    Stop Nic OF Renderer Test Suite
    Stop Mininet    ${mininet_conn_id}

Stop NIC OF Renderer Suite
    [Documentation]    Stop Nic OF Renderer Test Suite
    Delete All Sessions

Add Qos Configuration
    [Arguments]    ${name}    ${dscp}
    [Documentation]    Creates a QoS configuration and add an intent from the controller.
    ${output}=    Issue Command On Karaf Console    intent:qosConfig -p ${name} -d ${dscp}
    Should Contain    ${output}    QoS profile is configured
    ${output}=    Fetch From Left    ${output}    )
    ${output_split}=    Split String    ${output}    ${SPACE}
    ${id}=    Get From List    ${output_split}    5
    [Return]    ${id}

Invalid Qos Configuration
    [Arguments]    ${name}    ${dscp}
    [Documentation]    Add an intent from the controller.
    ${output}=    Issue Command On Karaf Console    intent:qosConfi -p ${name} -d ${dscp}
    Should Contain    ${output}    Command not found

Invalid Dscp
    [Arguments]    ${name}    ${dscp}
    [Documentation]    Add an intent from the controller.
    ${output}=    Issue Command On Karaf Console    intent:qosConfig -p ${name} -d ${dscp}
    Should Contain    ${output}    Error executing command: Invalid range

Add Qos From Karaf Console
    [Arguments]    ${intent_from}    ${intent_to}    ${action}    ${constraint}    ${profile_name}
    [Documentation]    Adds an QOS to the controller, and returns the id of the intent created.
    ${output}=    Issue Command On Karaf Console    intent:add -f ${intent_from} -t ${intent_to} -a ${action} -q ${constraint} -p ${profile_name}
    Should Contain    ${output}    Intent created
    ${output}=    Fetch From Left    ${output}    )
    ${output_split}=    Split String    ${output}    ${SPACE}
    ${id}=    Get From List    ${output_split}    3
    [Return]    ${id}

Verify TOS Actions
    [Arguments]    ${actions}    ${DUMPFLOWS}
    [Documentation]    Verify the QoS actions after ping in the dumpflows
    write    ${DUMPFLOWS}
    ${result}    Read Until    mininet>
    Should Contain    ${result}    ${actions}

Verify OFBundle
    ${output}=    Issue Command On Karaf Console    bundle:list | grep of-renderer
    Should Contain    ${output}    Active

Setup NIC Console Environment
    [Documentation]    Installing NIC Console related features (install odl-nic-core-mdsal odl-nic-console odl-nic-listeners)
    Verify Feature Is Installed    odl-nic-core-mdsal
    Verify Feature Is Installed    odl-nic-console
    Verify Feature Is Installed    odl-nic-renderer-of
    Verify Feature Is Installed    odl-nic-pipeline-manager
    Verify Feature Is Installed    odl-nic-listeners

Start Mininet Linear Topology
    [Arguments]    ${switches}
    [Documentation]    Start mininet linear topology with ${switches} nodes
    Log To Console    Starting mininet linear ${switches}
    ${mininet_conn_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${switches*3}
    Set Suite Variable    ${mininet_conn_id}
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Write    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo linear,${switches} --switch ovsk,protocols=OpenFlow13
    Read Until    mininet>
    Sleep    6

Get DynamicMacAddress
    [Arguments]    ${h}
    [Documentation]    Get Dynamic mac address of Host
    write    ${h} ifconfig -a | grep HWaddr
    ${source}    Read Until    mininet>
    ${HWaddress}=    Split String    ${source}    ${SPACE}
    ${sourceHWaddr}=    Get from List    ${HWaddress}    7
    ${sourceHWaddress}=    Convert To Lowercase    ${sourceHWaddr}
    Return From Keyword    ${sourceHWaddress}    # Also [Return] would work here.

Get Intent List
    [Documentation]    Check list of intents
    ${resp}=    RequestsLibrary.Get Request    session    ${INTENTS}
    Should Contain    ${resp.content}    intents

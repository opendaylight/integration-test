*** Settings ***
Documentation     Keywords for DIDM suites
Library           SSHLibrary
Library           Collections
Library           RequestsLibrary
Variables         ../variables/Variables.py
Resource          ./Utils.robot

*** Keywords ***
Wait For Karaf Log
    [Arguments]    ${message}    ${timeout}=180
    [Documentation]    Read Karaf log until message appear
    Log    Waiting for ${message} in Karaf log
    Open Connection    ${CONTROLLER}    port=${KARAF_SHELL_PORT}    prompt=${KARAF_PROMPT}    timeout=${timeout}
    Flexible SSH Login    ${KARAF_USER}    ${KARAF_PASSWORD}
    Write    log:tail
    Read Until    ${message}
    Close Connection

Check DIDM Registered With Device
    [Documentation]    Check for DIDM registered with the device
    ${resp}=    RequestsLibrary.Get    session    ${OPERATIONAL_NODES_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    Should Contain    ${resp.content}    didm

Find Device Data
    [Documentation]    Extract DIDM identification information
    ...    This keyword performs the following:
    ...    1. Sends a RestConf request to fetch for the operational inventory of all nodes
    ...    2. Confirms the device's IP and return the response with the device's info
    ${resp}=    RequestsLibrary.Get    session    ${OPERATIONAL_NODES_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    ${json_resp}=    RequestsLibrary.To_Json    ${resp.content}
    ${nodes_resp}=    Get From Dictionary    ${json_resp}    nodes
    ${node_resp}=    Get From Dictionary    ${nodes_resp}    node
    ${node_data}=    Get From List    ${node_resp}    0
    Log    ${node_data}
    #    Set Suite Variable    ${node_data}
    [Return]    ${node_data}

Check Device IP
    [Documentation]    Check for the device IP address
    ${dev_ip}=    Set Variable    flow-node-inventory:ip-address
    ${node_data}=    Find Device Data
    ${device_keys}=    Get Dictionary Keys    ${node_data}
    Log    ${device_keys}
    ${length}=    Get Length    ${device_keys}
    : FOR    ${index}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_keys}    ${index}
    \    Run Keyword And Return If    '${dev_ip}' == '${line}'    Get From Dictionary    ${node_data}    ${dev_ip}

Find Device Type
    ${device_type}=    Set Variable    didm-identification:device-type
    ${node_data}=    Find Device Data
    ${device_keys}=    Get Dictionary Keys    ${node_data}
    Log    ${device_keys}
    ${device_ip}=    Check Device IP
    Should Match    ${DEVICE_IP}    ${device_ip}
    ${length}=    Get Length    ${device_keys}
    : FOR    ${index}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_keys}    ${index}
    \    Run Keyword And Return If    '${device_type}' == '${line}'    Get From Dictionary    ${node_data}    ${device_type}

Find Device Hardware
    ${device_hw}=    Set Variable    flow-node-inventory:hardware
    ${node_data}=    Find Device Data
    ${device_keys}=    Get Dictionary Keys    ${node_data}
    Log    ${device_keys}
    ${length}=    Get Length    ${device_keys}
    : FOR    ${index}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_keys}    ${index}
    \    Run Keyword And Return If    '${device_hw}' == '${line}'    Get From Dictionary    ${node_data}    ${device_hw}

Find Device Software
    ${device_sw}=    Set Variable    flow-node-inventory:software
    ${node_data}=    Find Device Data
    ${device_keys}=    Get Dictionary Keys    ${node_data}
    Log    ${device_keys}
    ${length}=    Get Length    ${device_keys}
    : FOR    ${index}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_keys}    ${index}
    \    Run Keyword And Return If    '${device_sw}' == '${line}'    Get From Dictionary    ${node_data}    ${device_sw}

Find Device Manufacturer
    ${manufacture}=    Set Variable    flow-node-inventory:manufacturer
    ${node_data}=    Find Device Data
    ${device_keys}=    Get Dictionary Keys    ${node_data}
    Log    ${device_keys}
    ${length}=    Get Length    ${device_keys}
    : FOR    ${index}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_keys}    ${index}
    \    Run Keyword And Return If    '${manufacture}' == '${line}'    Get From Dictionary    ${node_data}    ${manufacture}

Find Serial Number
    ${serial_number}=    Set Variable    flow-node-inventory:serial-number
    ${node_data}=    Find Device Data
    ${device_keys}=    Get Dictionary Keys    ${node_data}
    Log    ${device_keys}
    ${length}=    Get Length    ${device_keys}
    : FOR    ${index}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_keys}    ${index}
    \    Run Keyword And Return If    '${serial_number}' == '${line}'    Get From Dictionary    ${node_data}    ${serial_number}

Find Device Description
    ${description}=    Set Variable    flow-node-inventory:description
    ${node_data}=    Find Device Data
    ${device_keys}=    Get Dictionary Keys    ${node_data}
    Log    ${device_keys}
    ${length}=    Get Length    ${device_keys}
    : FOR    ${index}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_keys}    ${index}
    \    Run Keyword And Return If    '${description}' == '${line}'    Get From Dictionary    ${node_data}    ${description}

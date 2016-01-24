*** Settings ***
Documentation     Keywords for DIDM suites
Library           SSHLibrary
Library           Collections
Library           RequestsLibrary
Variables         ../variables/Variables.py
Resource          ./Utils.robot

*** Keywords ***
Check DIDM Registered With Device
    [Documentation]    Check for DIDM registered with the device
    ${resp}=    RequestsLibrary.Get Request    session    ${OPERATIONAL_NODES_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    Should Contain    ${resp.content}    didm
    [Return]    ${resp.content}

Find Device Data
    [Documentation]    Extract device information
    ${resp.content}=    Check DIDM Registered With Device
    ${json_resp}=    RequestsLibrary.To_Json    ${resp.content}
    ${nodes_resp}=    Get From Dictionary    ${json_resp}    nodes
    ${node_resp}=    Get From Dictionary    ${nodes_resp}    node
    ${node_data}=    Get From List    ${node_resp}    0
    Log    ${node_data}
    Set Suite Variable    ${node_data}
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
    [Return]    ${dev_ip}

Find Device Type
    [Documentation]    Look for the device type
    ${device_type}=    Set Variable    didm-identification:device-type
    ${device_ip}=    Check Device IP
    Should Match    ${DEVICE_IP}    ${device_ip}
    ${device_keys}=    Get Dictionary Keys    ${node_data}
    Log    ${device_keys}
    ${length}=    Get Length    ${device_keys}
    : FOR    ${index}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_keys}    ${index}
    \    Run Keyword And Return If    '${device_type}' == '${line}'    Get From Dictionary    ${node_data}    ${device_type}
    [Return]    ${device_type}

Find Device Hardware
    [Documentation]    Look for the device hardware information
    ${device_hw}=    Set Variable    flow-node-inventory:hardware
    ${device_keys}=    Get Dictionary Keys    ${node_data}
    Log    ${device_keys}
    ${length}=    Get Length    ${device_keys}
    : FOR    ${index}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_keys}    ${index}
    \    Run Keyword And Return If    '${device_hw}' == '${line}'    Get From Dictionary    ${node_data}    ${device_hw}
    [Return]    ${device_hw}

Find Device Software
    [Documentation]    Look for the device software information
    ${device_sw}=    Set Variable    flow-node-inventory:software
    ${device_keys}=    Get Dictionary Keys    ${node_data}
    Log    ${device_keys}
    ${length}=    Get Length    ${device_keys}
    : FOR    ${index}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_keys}    ${index}
    \    Run Keyword And Return If    '${device_sw}' == '${line}'    Get From Dictionary    ${node_data}    ${device_sw}
    [Return]    ${device_sw}

Find Device Manufacturer
    [Documentation]    Look for the device manufacture
    ${manufacture}=    Set Variable    flow-node-inventory:manufacturer
    ${device_keys}=    Get Dictionary Keys    ${node_data}
    Log    ${device_keys}
    ${length}=    Get Length    ${device_keys}
    : FOR    ${index}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_keys}    ${index}
    \    Run Keyword And Return If    '${manufacture}' == '${line}'    Get From Dictionary    ${node_data}    ${manufacture}
    [Return]    ${manufacture}

Find Serial Number
    [Documentation]    Look for the device serial number
    ${serial_number}=    Set Variable    flow-node-inventory:serial-number
    ${device_keys}=    Get Dictionary Keys    ${node_data}
    Log    ${device_keys}
    ${length}=    Get Length    ${device_keys}
    : FOR    ${index}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_keys}    ${index}
    \    Run Keyword And Return If    '${serial_number}' == '${line}'    Get From Dictionary    ${node_data}    ${serial_number}
    [Return]    ${serial_number}

Find Device Description
    [Documentation]    Look for the device description
    ${description}=    Set Variable    flow-node-inventory:description
    ${device_keys}=    Get Dictionary Keys    ${node_data}
    Log    ${device_keys}
    ${length}=    Get Length    ${device_keys}
    : FOR    ${index}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${device_keys}    ${index}
    \    Run Keyword And Return If    '${description}' == '${line}'    Get From Dictionary    ${node_data}    ${description}
    [Return]    ${description}

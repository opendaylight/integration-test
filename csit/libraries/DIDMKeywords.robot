*** Settings ***
Documentation     Keywords for DIDM suites 
...    

Library           SSHLibrary
Library           Collections
Library           RequestsLibrary
Variables         ../variables/Variables.py
Resource          ./Utils.robot

*** Keywords ***
Find Device IP Address 
    [Documentation]    Find device's IP address from operational node inventory 
    ...    This keyword performs the following:
    ...    1. Sends a restconf curl command to fetch for the operational node inventory of the device
    ...    2. Finds the device's IP from the restconf response and return the device's IP address 
    ${resp}=    RequestsLibrary.Get    session    ${OPERATIONAL_NODES_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${DEVICE_IP}
    [Return]    ${DEVICE_IP}

Find Device Identification Information
    [Documentation]    Extract DIDM identification information
    ...    This keyword performs the following:
    ...    1. Sends a restconf curl command to fetch for the operational nodes inventory of the device
    ...    2. Confirms the device's IP and return the response with the device's info
    ${resp}=    RequestsLibrary.Get    session    ${OPERATIONAL_NODES_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    ${device_ip_addr}=    Find Device IP Address
    ${flow_node_inventory_ip}=    Set Variable    flow-node-inventory:ip-address":"
    ${flow_node_inventory_ip}=    Catenate    SEPARATOR=    ${flow_node_inventory_ip}    ${device_ip_addr}
    Should Contain    ${resp.content}    ${flow_node_inventory_ip}
    ${response}=    Split String    ${resp.content}    ","
    ${hardware}=    Set Variable    flow-node-inventory:hardware":
    ${device_type}=    Set Variable    didm-identification:device-type":
    ${manufacturer}=    Set Variable    flow-node-inventory:manufacturer":
    ${serial_number}=    Set Variable    flow-node-inventory:serial-number":
    ${software}=    Set Variable    flow-node-inventory:software":
    ${description}=    Set Variable    flow-node-inventory:description":
    ${length}=    Get Length    ${response}
    @{device_list}=    Create List
    : FOR    ${index}    IN RANGE    0    ${length}
    \    ${line}=    Get From List    ${response}    ${index}
    \    Run Keyword If    '${manufacturer}' in '${line}'    Append To List    ${device_list}    ${line}
    \    Run Keyword If    '${serial_number}' in '${line}'    Append To List    ${device_list}    ${line}
    \    Run Keyword If    '${hardware}' in '${line}'    Append To List    ${device_list}    ${line}
    \    Run Keyword If    '${software}' in '${line}'    Append To List    ${device_list}    ${line}
    \    Run Keyword If    '${description}' in '${line}'    Append To List    ${device_list}    ${line}
    \    Run Keyword If    '${device_type}' in '${line}'    Append To List    ${device_list}    ${line}
    Log    ${device_list}
    [Return]    ${device_list}


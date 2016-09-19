*** Settings ***
Library           SSHLibrary
Resource          ../Utils.robot

*** Variables ***

*** Keywords ***
Get Network From CIDR
    [Arguments]    ${cidr}
    [Documentation]    Returns the subnetwork part from a given subnet in CIDR format,
    ...    like 192.168.1.0/24. Returning 192.168.1.0.
    ${splitted_cidr}=    Split String    ${cidr}    /
    ${network}=    Get From List    ${splitted_cidr}    0
    [Return]    ${network}

Get Mask From CIDR
    [Arguments]    ${cidr}
    [Documentation]    Returns a subnet mask from a given subnet in CIDR format,
    ...    like 192.168.1.0/24. Returning 255.255.255.0.
    ${splitted_cidr}=    Split String    ${cidr}    /
    ${mask_cidr}=    Get From List    ${splitted_cidr}    1
    @{binary_mask}=    Create List
    : FOR    ${i}    IN RANGE    0    ${mask_cidr}
    \    Append To List    ${binary_mask}    1
    ${remaining}=    Evaluate    32-${mask_cidr}
    : FOR    ${j}    IN RANGE    0    ${remaining}
    \    Append To List    ${binary_mask}    0
    ${slice1}=    Get Slice From List    ${binary_mask}    0    8
    ${slice2}=    Get Slice From List    ${binary_mask}    8    16
    ${slice3}=    Get Slice From List    ${binary_mask}    16    24
    ${slice4}=    Get Slice From List    ${binary_mask}    24    32
    ${bin1}=    Catenate    SEPARATOR=${EMPTY}    @{slice1}
    ${bin2}=    Catenate    SEPARATOR=${EMPTY}    @{slice2}
    ${bin3}=    Catenate    SEPARATOR=${EMPTY}    @{slice3}
    ${bin4}=    Catenate    SEPARATOR=${EMPTY}    @{slice4}
    ${dec1}=    Convert To Integer    ${bin1}    2
    ${dec2}=    Convert To Integer    ${bin2}    2
    ${dec3}=    Convert To Integer    ${bin3}    2
    ${dec4}=    Convert To Integer    ${bin4}    2
    ${mask}=    Catenate    SEPARATOR=.    ${dec1}    ${dec2}    ${dec3}    ${dec4}
    [Return]    ${mask}

Get Ip Address First Octets
    [Arguments]    ${ip}    ${num_octets}
    [Documentation]    Given an IP address, this function returns the number
    ...    of octets determined as argument. If 4 are specified, then the output
    ...    is the whole IP.
    ${splitted_ip}=    Split String    ${ip}    .
    ${ip_octets}=    Get Slice From List    ${splitted_ip}    0    ${num_octets}

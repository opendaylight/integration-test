*** Settings ***
Documentation     Keywords specific for IoTDM test suites.
Library           ./criotdm.py
Library           OperatingSystem
Library           iotdm_comm.py

*** Variables ***

*** Keywords ***
IOTDM Basic Suite Setup
    [Arguments]    ${odl_ip_address}    ${odl_user_name}    ${odl_password}
    [Documentation]    Set up basic test suite
    ${iserver} =    Connect To Iotdm    ${odl_ip_address}    ${odl_user_name}    ${odl_password}    http
    Set Suite Variable    ${iserver}

Resolve Local Ip Address
    ${ip_list}    OperatingSystem.Run    hostname -I
    Log    iotdm_ip: ${ODL_SYSTEM_1_IP}
    Log    hostname -I: ${ip_list}
    ${local_ip} =    Get Local Ip From List    ${ODL_SYSTEM_1_IP}    ${ip_list}
    Set Global Variable    ${local_ip}
    Log    local_ip: ${local_ip}

Connect And Provision cseBase
    [Documentation]    Connects to IoTDM RESTCONF interface and provisions cseBase resource InCSE1
    Connect To Iotdm    ${ODL_SYSTEM_1_IP}    ${ODL_RESTCONF_USER}    ${ODL_RESTCONF_PASSWORD}

Clear The Resource Tree
    [Documentation]    Connects to IoTDM RESTCONF interface and clears whole resource tree
    Kill The Tree    ${ODL_SYSTEM_1_IP}    InCSE1    ${ODL_RESTCONF_USER}    ${ODL_RESTCONF_PASSWORD}

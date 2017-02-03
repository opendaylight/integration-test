*** Settings ***
Documentation     Keywords specific for IoTDM test suites.
Library           ./criotdm.py

*** Variables ***

*** Keywords ***
IOTDM Basic Suite Setup
    [Arguments]    ${odl_ip_address}    ${odl_user_name}    ${odl_password}
    [Documentation]    Set up basic test suite
    ${iserver} =    Connect To Iotdm    ${odl_ip_address}    ${odl_user_name}    ${odl_password}    http
    Set Suite Variable    ${iserver}

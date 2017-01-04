*** Settings ***
Documentation     Utility resource for IoTDM file

*** Keywords ***
Should Contain All Sub Strings
    [Arguments]    ${attr}    @{checked}
    [Documentation]    checks wether checked are part of attr
    : FOR    ${item}    IN    @{checked}
    \    Should Contain    ${attr}    ${item}

Should Not Contain Any Sub Strings
    [Arguments]    ${attr}    @{checked}
    [Documentation]    checks wether checked are not part of attr
    : FOR    ${item}    IN    @{checked}
    \    Should Not Contain    ${attr}    ${item}

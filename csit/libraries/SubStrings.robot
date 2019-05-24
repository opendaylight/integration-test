*** Settings ***
Documentation     Utility keywords for verification of substring occurrence

*** Keywords ***
Should Contain All Sub Strings
    [Arguments]    ${attr}    @{checked}
    [Documentation]    Passes if ${attr} includes all substrings from @{checked}, fails otherwise
    FOR    ${item}    IN    @{checked}
        Should Contain    ${attr}    ${item}
    END

Should Not Contain Any Sub Strings
    [Arguments]    ${attr}    @{checked}
    [Documentation]    Fails if ${attr} includes at least one substring from @{checked}, passes otherwise
    FOR    ${item}    IN    @{checked}
        Should Not Contain    ${attr}    ${item}
    END

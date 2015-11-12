*** Settings ***
Documentation     A resource file containing all global
...               elements (Variables, keywords) to help
...               DLUX.
Library           Selenium2Library
Library           ../../libraries/Common.py
Variables         ../../variables/Variables.py

*** Variables ***
${BROWSER}        chrome
${BASE URL}       http://${ODL_SYSTEM_IP}:${RESTCONFPORT}/index.html
${LOGIN URL}      ${BASE_URL}#/login

*** keywords ***
Lauch DLUX
    [Documentation]    Will lauch with a delay to let the page to load
    Open Browser    ${LOGIN URL}    ${BROWSER}
    Wait Until Page Contains Element    css=div.container

Log In To DLUX
    [Arguments]    ${username}=${USER}    ${password}=${PWD}
    [Documentation]    Try the given credential to pass the login page.
    Input Text    name=username    ${username}
    Input Password    name=password    ${password}
    Click Button    tag=button    # Only one button in the login page so it is not so bad

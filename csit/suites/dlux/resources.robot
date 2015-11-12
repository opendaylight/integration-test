*** Settings ***
Documentation     A resource file containing all global
...               elements (Variables, keywords) to help
...               DLUX unit testing.
Library           OperatingSystem
Library           Process
Library           ../../libraries/Common.py
Variables         ../../variables/Variables.py

*** Variables ***
${BROWSER}        firefox
${BASE URL}       http://${ODL_SYSTEM_IP}:${RESTCONFPORT}/index.html
${LOGIN URL}      ${BASE_URL}#/login
${XVFB_PORT}      99

*** keywords ***
Open Virtual Display
    [Documentation]    Start xvfb, a kind-ish x-server on RAM
    Start Process    Xvfb    :${XVFB_PORT}    -ac    alias=xvfb
    ${display}    Get Environment Variable    DISPLAY    :
    Run Keyword Unless    '${display}' == ':${XVFB_PORT}'    Set Display Port

Set Display Port
    [Arguments]    ${port}=${XVFB_PORT}
    [Documentation]    Set the environment variable used by xvfb and the browser
    Set Environment Variable    DISPLAY    :${port}

Close Virtual Display
    Close Browser
    Terminate Process    xvfb

Launch DLUX
    [Documentation]    Will launch with a delay to let the page to load
    Open Browser    ${LOGIN URL}    ${BROWSER}
    Wait Until Page Contains Element    css=div.container

Log In To DLUX
    [Arguments]    ${username}=${USER}    ${password}=${PWD}
    [Documentation]    Try the given credential to pass the login page.
    Input Text    name=username    ${username}
    Input Password    name=password    ${password}
    Click Button    tag=button    # Only one button in the login page so it is not so bad

*** Settings ***
Documentation     A resource file containing all global
...               elements (Variables, keywords) to help
...               DLUX unit testing.
Library           OperatingSystem
Library           Process
Library           ../../libraries/Common.py
Variables         ../../variables/Variables.py

*** Variables ***
${BROWSER}        Firefox
${BASE URL}       http://${ODL_SYSTEM_IP}:${RESTCONFPORT}/index.html
${LOGIN URL}      ${BASE_URL}#/login
${XVFB PORT}      99

# Failback variables
${USE XVFB}       True
${BROWSER NAME}   phantomjs-1.9.8-linux-x86_64
${BROWSER EXT}    tar.bz2
${BROWSER FNAME}  ${BROWSER NAME}.${BROWSER EXT}
${BROWSER URL}    https://bitbucket.org/ariya/phantomjs/downloads/${BROWSER FNAME}
${BROWSER PATH}   ${BROWSER NAME}/bin/phantomjs

*** keywords ***
Check If Phantom Is Downloaded
    [Documentation]    Check if a folder named 'phantomjs' is found in the robot script directory
    ${installed}=    Run    ls | grep -m 1 phantomjs
    [Return]    ${installed}

Download PhantomJS
    [Documentation]    Download and uncompress the headless browser PhantomJS
    Run Process    wget    ${BROWSER URL}
    Run Process    tar    -jxf    ${BROWSER FNAME}

Get Headless Browser Path
    [Documentation]    Return the path of the executable headless browser
    ${is_downloaded}=    Check If Phantom Is Downloaded
    Run Keyword If    '${is_downloaded}' == '${EMPTY}'    Download PhantomJS
    ${path}=    Set Variable    ${EXECDIR}/${BROWSER PATH}
    [Return]    ${path}

Open Headless Browser
    [Arguments]    ${url}
    Log    \n Using failback browser    console=yes
    Set Global Variable    ${USE XVFB}   False
    ${executable_path}=    Get Headless Browser Path
    Create Webdriver    PhantomJS    executable_path=${executable_path}
    Go To    ${url}

Open Virtual Display
    [Documentation]    Start xvfb, a kind-ish x-server on RAM
    Start Process    Xvfb    :${XVFB PORT}    -ac    alias=xvfb
    ${display}    Get Environment Variable    DISPLAY    ${EMPTY}
    Run Keyword Unless    '${display}' == ':${XVFB PORT}'    Set Display Port

Set Display Port
    [Arguments]    ${port}=${XVFB PORT}
    [Documentation]    Set the environment variable used by xvfb and the browser
    Set Environment Variable    DISPLAY    :${port}

Close DLUX
    Close Browser
    Run Keyword If    ${USE XVFB}    Terminate Process    xvfb

Launch DLUX
    [Documentation]    Will launch with a delay to let the page to load
    ${status}=    Run Keyword And Return Status    Run Keywords
    ...           Open Virtual Display    AND    Open Browser    ${LOGIN URL}    ${BROWSER}
    Run Keyword Unless    ${status}    Open Headless Browser    ${LOGIN URL}
    Wait Until Page Contains Element    css=div.container

Log In To DLUX
    [Arguments]    ${username}=${USER}    ${password}=${PWD}
    [Documentation]    Try the given credential to pass the login page.
    Input Text    name=username    ${username}
    Input Password    name=password    ${password}
    Click Button    tag=button    # Only one button in the login page so it is not so bad

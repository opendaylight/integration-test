*** Settings ***
Documentation     A resource file containing all global
...               elements (Variables, keywords) to help
...               DLUX unit testing.
Library           OperatingSystem
Library           Process
Library           Common.py
Variables         ../variables/Variables.py

*** Variables ***
${BROWSER}        Firefox
${BASE URL}       http://${ODL_SYSTEM_IP}:${RESTCONFPORT}/index.html
${LOGIN URL}      ${BASE_URL}#/login
${XVFB PORT}      99

# Failback variables
${USE XVFB}       True
${BROWSER NAME}   phantomjs-1.9.8-linux-x86_64
${BROWSER EXT}    tar.bz2
${BROWSER FNAME}  ${BROWSER NAME}.${BROWSER EXT}    # full file name
${BROWSER URL}    https://bitbucket.org/ariya/phantomjs/downloads/${BROWSER FNAME}
${BROWSER PATH}   ${BROWSER NAME}/bin/phantomjs    # executable path

*** keywords ***

# Looking if PhantomJS already been downloaded. This check is done by
# listing the directory and see if there is one containing the word 'phantomjs'
Check If Phantom Is Downloaded
    [Documentation]    Check if a folder named 'phantomjs' is found in the robot script directory
    ${installed}=    Run    ls -d */ | grep -m 1 phantomjs
    [Return]    ${installed}

# The PhantomJS compressed file is downloaded and uncompressed locally related
# to the path of the running script.
Download PhantomJS
    [Documentation]    Download and uncompress the headless browser PhantomJS
    Run Process    wget    ${BROWSER URL}
    Run Process    tar    -jxf    ${BROWSER FNAME}

# Return the absolute path of the executable file pantomjs.
# If not found, PhantomJS is dowloaded.
Get Headless Browser Path
    [Documentation]    Return the path of the executable headless browser
    ${is_downloaded}=    Check If Phantom Is Downloaded
    Run Keyword If    '${is_downloaded}' == '${EMPTY}'    Download PhantomJS
    ${path}=    Set Variable    ${EXECDIR}/${BROWSER PATH}
    [Return]    ${path}

# PhantomJS is a WebKit headless browser. It is a minimalist
# browser (around ~20 MB). The Open Browser keyword consider that
# all browser are located in the PATH environment variable. To override
# this behavior, we have to create a new instance of the PhantomJS webdriver
# and give it the executable path
Open Headless Browser
    [Arguments]    ${url}
    [Documentation]    Failback browser, download and use the WebKit headless
    ...    browser PhantomJS
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
    [Documentation]    Close all browser instances and close
    ...    Xvfb if the process is running
    Close All Browsers
    Run Keyword If    ${USE XVFB}    Terminate Process    xvfb

# Step of Launch DLUX
#  1. Trying to start Xvfb and load the browser defined by the variable ${BROWSER}
#  2. If failed to start one of those task:
#   2.1 Download and extract PhantomJS if not already done
#   2.2 Create a custom PhantomJS webdriver based on the downloaded one
#  3. Wait until the HTML page contain a specific element created by AngularJS
Launch DLUX
    [Documentation]    Will launch with a delay to let the page to load
    ...    If it cannot run the default browser, it will download one
    ...    and use it instead.
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

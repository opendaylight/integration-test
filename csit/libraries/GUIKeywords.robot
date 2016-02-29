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
${LOGGED URL}       ${BASE_URL}#/topology


==============
# Login page
==============
${OPENDAYLIGHT_IMAGE}            //img[@alt='OpenDayLight']
${LOGIN_USERNAME_INPUT_FIELD}    //form/fieldset/div/input[@name='username']
${LOGIN_PASSWORD_INPUT_FIELD}    //form/fieldset/div[2]/input[@name='password']
${REMEMBER_ME_CHECKBOX}          //div[@class="checkbox"]
${LOGIN_BUTTON}                  //fieldset/button
${PleaseSignIn_PANEL}            //div/h3[contains(text(), "${PleaseSignIn_MSG}")]
${PleaseSignIn_MSG}              Please Sign In
${LOGIN_ERROR_MSG}               Unable to login


=================
# DLUX Home page
=================
${Topology_SUBMENU}    //a[@href='#/topology']
${Nodes_SUBMENU}       //a[contains(@href,'#/node/index')]
${Yang_UI_SUBMENU}     //a[@href='#/yangui/index']
${Yang_Visualizer_SUBMENU}    //a[@href='#/yangvisualizer/index']


==================
# Topology Submenu
=================
${Topology_Submenu_URL}    ${BASE_URL}#/topology
${Reload_BUTTON}           //button[@ng-click='createTopology()']
${Controls_TEXT}           //div[@class="col-md-2"]/h3


================
# Nodes Submenu
================
${Nodes_Submenu_URL}    ${BASE_URL}#/node/index


==================
# Yang UI Submenu
==================
${Yang_UI_Submenu_URL}    ${BASE_URL}#/yangui/index


===========================
# Yang Visualizer Submenu
==========================
${Yang_Visualizer_Submenu_URL}    ${BASE_URL}#/yangvisualizer/index


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
    Start Process    Xvfb    :${XVFB PORT}    -ac    -screen    0    1280x1024x24    alias=xvfb
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

Open DLUX Login Page
    [Arguments]    ${LOGIN URL}
    [Documentation]    Will load DELUX login page.
    Open Browser    ${LOGIN URL}    ${BROWSER} 
    Maximize Browser Window
    Wait Until Page Contains Element    ${PleaseSignIn_PANEL}
    
Verify Elements Of DLUX Login Page
    [Documentation]    Will verify elements of DLUX login page.
    Page Should Contain Image    ${OPENDAYLIGHT_IMAGE}
    Page Should Contain Element    ${LOGIN_USERNAME_INPUT_FIELD}
    Page Should Contain Element    ${LOGIN_PASSWORD_INPUT_FIELD}
    Page Should Contain Element    ${REMEMBER_ME_CHECKBOX}    
    Page Should Contain Element    ${LOGIN_BUTTON}

Login DLUX
    [Arguments]   ${LOGIN_USERNAME}    ${LOGIN_PASSWORD}     
    [Documentation]    Will insert username and password and login DLUX.
    Focus    ${LOGIN_USERNAME_INPUT_FIELD}
    Input Text    ${LOGIN_USERNAME_INPUT_FIELD}    ${LOGIN_USERNAME}
    Sleep    1
    Focus    ${LOGIN_PASSWORD_INPUT_FIELD}
    Input Text    ${LOGIN_PASSWORD_INPUT_FIELD}    ${LOGIN_PASSWORD}
    Sleep    1
    Click Element    ${LOGIN_BUTTON}
    
Verify Elements of DLUX Home Page
    [Documentation]    Will verify elements of DLUX Home page.
    Wait Until Page Contains Element    ${Controls_TEXT}
    Location Should Be    ${LOGGED URL}
    Page Should Contain Button    ${Reload_BUTTON}
    Wait Until Page Contains Element     ${Topology_SUBMENU}
    #Wait Until Page Contains Element    ${Nodes_SUBMENU}
    #Wait Until Page Contains Element    ${Yang_UI_SUBMENU}
    #Wait Until Page Contains Element    ${Yang_Visualizer_SUBMENU}

Login DLUX With Invalid Credentials
    [Arguments]    ${LOGIN_USERNAME}    ${LOGIN_PASSWORD}    ${LOGIN_ERROR_MSG}
    ...            ${LOGGED URL}
    [Documentation]    Will insert invalid login credentials and verify occurence
    ...                of an error message.
    Focus    ${LOGIN_USERNAME_INPUT_FIELD}    
    Input Text    ${LOGIN_USERNAME_INPUT_FIELD}    ${LOGIN_USERNAME}
    Sleep    1
    Focus    ${LOGIN_PASSWORD_INPUT_FIELD}    
    Input Text    ${LOGIN_PASSWORD_INPUT_FIELD}    ${LOGIN_PASSWORD}
    Sleep    1
    Click Element    ${LOGIN_BUTTON}
    Sleep    1
    Location Should Be    ${LOGIN URL}
    ${status}=    Run Keyword And Return Status    Wait Until Page Contains    ${LOGIN_ERROR_MSG}
    Run Keyword If    "${status}"=="False"    Close Browser            
    
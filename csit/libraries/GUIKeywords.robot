*** Settings ***
Documentation     A resource file containing all global
...               elements (Variables, keywords) to help
...               DLUX csit testing.
Library           OperatingSystem
Library           Process
Library           Common.py
Library           Selenium2Library    timeout=15    implicit_wait=15    run_on_failure=Selenium2Library.Capture Page Screenshot
Variables         ../variables/Variables.py
Resource          Utils.robot

*** Variables ***
${BROWSER}        firefox
${BASE URL}       http://${ODL_SYSTEM_IP}:${RESTCONFPORT}/index.html
${LOGIN URL}      ${BASE_URL}#/login
${XVFB PORT}      99
${LOGGED URL}     ${BASE_URL}#/topology
${LOGIN_USERNAME}    admin
${LOGIN_PASSWORD}    admin
${INVALID_USER}    invaliduser
${INVALID_PWD}    invalidpwd
# Login page
${OPENDAYLIGHT_IMAGE}    //img[@alt='OpenDayLight']
${LOGIN_USERNAME_INPUT_FIELD}    //form/fieldset/div/input[@name='username']
${LOGIN_PASSWORD_INPUT_FIELD}    //form/fieldset/div[2]/input[@name='password']
${REMEMBER_ME_CHECKBOX}    //div[@class="checkbox"]
${LOGIN_BUTTON}    //fieldset/button
${PleaseSignIn_PANEL}    //div/h3[contains(text(), "${PleaseSignIn_MSG}")]
${PleaseSignIn_MSG}    Please Sign In
${LOGIN_ERROR_MSG}    Unable to login
# DLUX Home page
${Topology_SUBMENU}    //a[@href='#/topology']
${Nodes_SUBMENU}    //a[@href='#/node/index')]
${Yang_UI_SUBMENU}    //a[@href='#/yangui/index']
${Yang_Visualizer_SUBMENU}    //a[@href='#/yangvisualizer/index']
${Yangman_SUBMENU}    //a[@href='#/yangman/index']
# Topology Submenu
${Topology_Submenu_URL}    ${BASE_URL}#/topology
${Reload_BUTTON}    //button[@ng-click='createTopology()']
${Controls_TEXT}    //div[@class="col-md-2"]/h3
# Nodes Submenu
${Nodes_Submenu_URL}    ${BASE_URL}#/node/index
# Yang UI Submenu
${Yang_UI_Submenu_URL}    ${BASE_URL}#/yangui/index
# Yang Visualizer Submenu
${Yang_Visualizer_Submenu_URL}    ${BASE_URL}#/yangvisualizer/index
# Yangman Submenu
${Yangman_Submenu_URL}    ${BASE_URL}#/yangman/index
# Failback variables
${USE XVFB}       True
${BROWSER NAME}    phantomjs-1.9.8-linux-x86_64
${BROWSER EXT}    tar.bz2
${BROWSER FNAME}    ${BROWSER NAME}.${BROWSER EXT}    # full file name
${BROWSER URL}    https://bitbucket.org/ariya/phantomjs/downloads/${BROWSER FNAME}
${BROWSER PATH}    ${BROWSER NAME}/bin/phantomjs    # executable path

*** Keywords ***
Check If Phantom Is Downloaded
    [Documentation]    Check if a folder named 'phantomjs' is found in the robot script directory
    # Looking if PhantomJS already been downloaded. This check is done by
    # listing the directory and see if there is one containing the word 'phantomjs'
    ${installed}=    Run    ls -d */ | grep -m 1 phantomjs
    # The PhantomJS compressed file is downloaded and uncompressed locally related
    # to the path of the running script.
    [Return]    ${installed}

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
    # PhantomJS is a WebKit headless browser. It is a minimalist
    # browser (around ~20 MB). The Open Browser keyword consider that
    # all browser are located in the PATH environment variable. To override
    # this behavior, we have to create a new instance of the PhantomJS webdriver
    # and give it the executable path
    [Return]    ${path}

Open Headless Browser
    [Arguments]    ${url}
    [Documentation]    Failback browser, download and use the WebKit headless
    ...    browser PhantomJS
    Log    \n Using failback browser    console=yes
    Set Global Variable    ${USE XVFB}    False
    ${executable_path}=    Get Headless Browser Path
    Create Webdriver    PhantomJS    executable_path=${executable_path}
    Go To    ${url}

Open Virtual Display
    [Documentation]    Start xvfb, a kind-ish x-server on RAM
    Start Process    Xvfb    :${XVFB PORT}    -ac    -screen    0    1280x1024x16
    ...    alias=xvfb
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
    #    1. Trying to start Xvfb and load the browser defined by the variable ${BROWSER}
    #    2. If failed to start one of those task:
    #    2.1 Download and extract PhantomJS if not already done
    #    2.2 Create a custom PhantomJS webdriver based on the downloaded one
    #    3. Wait until the HTML page contain a specific element created by AngularJS

Launch DLUX
    [Documentation]    Will launch with a delay to let the page to load
    ...    If it cannot run the default browser, it will download one
    ...    and use it instead.
    ${status}=    Run Keyword And Return Status    Run Keywords    Open Virtual Display
    ...    AND    Open Browser    ${LOGIN URL}    ${BROWSER}
    Run Keyword Unless    ${status}    Open Headless Browser    ${LOGIN URL}
    Wait Until Page Contains Element    css=div.container

Log In To DLUX
    [Arguments]    ${username}=${USER}    ${password}=${PWD}
    [Documentation]    Try the given credential to pass the login page.
    Input Text    name=username    ${username}
    Input Password    name=password    ${password}
    Click Button    tag=button

Open DLUX Login Page
    [Arguments]    ${LOGIN URL}
    [Documentation]    Will load DLUX login page.
    Selenium2Library.Open Browser    ${LOGIN URL}    ${BROWSER}
    Selenium2Library.Maximize Browser Window
    Wait Until Page Contains Element    ${PleaseSignIn_PANEL}

Verify Elements Of DLUX Login Page
    [Documentation]    Will verify elements of DLUX login page.
    Page Should Contain Image    ${OPENDAYLIGHT_IMAGE}
    Page Should Contain Element    ${LOGIN_USERNAME_INPUT_FIELD}
    Page Should Contain Element    ${LOGIN_PASSWORD_INPUT_FIELD}
    Page Should Contain Element    ${REMEMBER_ME_CHECKBOX}
    Page Should Contain Element    ${LOGIN_BUTTON}

Login DLUX
    [Arguments]    ${LOGIN_USERNAME}    ${LOGIN_PASSWORD}
    [Documentation]    Will insert username and password and login DLUX.
    Focus    ${LOGIN_USERNAME_INPUT_FIELD}
    Input Text    ${LOGIN_USERNAME_INPUT_FIELD}    ${LOGIN_USERNAME}
    Sleep    1
    Focus    ${LOGIN_PASSWORD_INPUT_FIELD}
    Input Text    ${LOGIN_PASSWORD_INPUT_FIELD}    ${LOGIN_PASSWORD}
    Sleep    1
    Click Element    ${LOGIN_BUTTON}

Login DLUX With Invalid Credentials
    [Arguments]    ${LOGIN_USERNAME}    ${LOGIN_PASSWORD}    ${LOGIN_ERROR_MSG}    ${LOGGED URL}
    [Documentation]    Will insert invalid login credentials and verify occurence
    ...    of an error message.
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
    Run Keyword If    "${status}"=="False"    Selenium2Library.Close Browser

Launch Or Open DLUX
    ${status}=    BuiltIn.Run Keyword And Return Status    Open DLUX Login Page    ${LOGIN URL}
    BuiltIn.Run Keyword If    "${status}"=="False"    BuiltIn.Run Keyword    Launch DLUX
    Verify Elements Of DLUX Login Page

Launch Or Open DLUX Page And Login DLUX
    Launch Or Open DLUX
    Login DLUX    ${LOGIN_USERNAME}    ${LOGIN_PASSWORD}

Navigate To URL
    [Arguments]    ${url}
    ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Location Should Be    ${url}
    BuiltIn.Run Keyword Unless    ${status}    Selenium2Library.Go To    ${url}

Page Should Contain Element With Wait
    [Arguments]    ${element}
    BuiltIn.Wait Until Keyword Succeeds    30 sec    5 sec    Selenium2Library.Page Should Contain Element    ${element}

Page Should Not Contain Element With Wait
    [Arguments]    ${element}
    BuiltIn.Wait Until Keyword Succeeds    30 sec    5 sec    Selenium2Library.Page Should Not Contain Element    ${element}

Focus And Click Element
    [Arguments]    ${element}
    Page Should Contain Element With Wait    ${element}
    Selenium2Library.Focus    ${element}
    Selenium2Library.Mouse Over    ${element}
    Selenium2Library.Click Element    ${element}

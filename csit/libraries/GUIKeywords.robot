*** Settings ***
Documentation     A resource file containing all global
...               elements (Variables, keywords) to help
...               DLUX csit testing.
Library           OperatingSystem
Library           Process
Library           Selenium2Library    timeout=20    implicit_wait=20    run_on_failure=Selenium2Library.Capture Page Screenshot
Library           CustomSeleniumKeywords.py
Resource          ../variables/Variables.robot
Resource          Utils.robot

*** Variables ***
${BROWSER}        phantomjs
${BASE_URL}       http://${ODL_SYSTEM_IP}:${RESTCONFPORT}/index.html
${LOGIN_URL}      ${BASE_URL}#/login
${XVFB_PORT}      99
${LOGGED_URL}     ${BASE_URL}#/topology
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
${PLEASE_SIGN_IN_PANEL}    //div/h3[contains(text(),"${PLEASE_SIGN_IN_MSG}")]
${PLEASE_SIGN_IN_MSG}    Please Sign In
${LOGIN_ERROR_MSG}    Unable to login
# DLUX Home page
${TOPOLOGY_SUBMENU}    //a[@href='#/topology']
${NODES_SUBMENU}    //a[@href='#/node/index')]
${YANG_UI_SUBMENU}    //a[@href='#/yangui/index']
${YANG_VISUALIZER_SUBMENU}    //a[@href='#/yangvisualizer/index']
${YANGMAN_SUBMENU}    //a[@href='#/yangman/index']
# Topology Submenu
${TOPOLOGY_SUBMENU_URL}    ${BASE_URL}#/topology
${RELOAD_BUTTON}    //button[@ng-click='createTopology()']
${CONTROLS_TEXT}    //div[@class="col-md-2"]/h3
# Nodes Submenu
${NODES_SUBMENU_URL}    ${BASE_URL}#/node/index
# Yang UI Submenu
${YANG_UI_SUBMENU_URL}    ${BASE_URL}#/yangui/index
# Yang Visualizer Submenu
${YANG_VISUALIZER_SUBMENU_URL}    ${BASE_URL}#/yangvisualizer/index
# Yangman Submenu
${YANGMAN_SUBMENU_URL}    ${BASE_URL}#/yangman/index
# Failback variables
${USE_XVFB}       True
${BROWSER_NAME}    phantomjs-1.9.8-linux-x86_64
${BROWSER_EXT}    tar.bz2
${BROWSER_FILE_NAME}    ${BROWSER_NAME}.${BROWSER_EXT}
${BROWSER_URL}    https://bitbucket.org/ariya/phantomjs/downloads/${BROWSER_FILE_NAME}
${BROWSER_PATH_EXECUTABLE}    ${BROWSER_NAME}/bin/phantomjs

*** Keywords ***
Check If Phantom Is Downloaded
    [Documentation]    Checks if a folder named 'phantomjs' is found in the robot script directory.
    ...    Checks if PhantomJS already been downloaded. This check is done by listing the directory and
    ...    verification if there is one containing the word 'phantomjs'. Result is that the PhantomJS
    ...    compressed file is downloaded and uncompressed locally related to the path of the running script.
    ${installed}=    OperatingSystem.Run    ls -d */ | grep -m 1 phantomjs
    [Return]    ${installed}

Download PhantomJS
    [Documentation]    Downloads and uncompress the headless browser PhantomJS.
    Process.Run Process    wget    ${BROWSER_URL}
    Process.Run Process    tar    -jxf    ${BROWSER_FILE_NAME}

Get Headless Browser Path
    [Documentation]    Returns the path of the executable headless browser.
    ${is_downloaded}=    Check If Phantom Is Downloaded
    BuiltIn.Run Keyword If    "${is_downloaded}"=="${EMPTY}"    Download PhantomJS
    ${path}=    BuiltIn.Set Variable    ${EXECDIR}/${BROWSER_PATH_EXECUTABLE}
    [Return]    ${path}

Open Headless Browser
    [Arguments]    ${url}
    [Documentation]    Failback browser, download and use the WebKit headless browser PhantomJS.
    BuiltIn.Log    \n Using failback browser    console=yes
    BuiltIn.Set Global Variable    ${USE_XVFB}    False
    ${executable_path}=    Get Headless Browser Path
    Selenium2Library.Create Webdriver    PhantomJS    executable_path=${executable_path}
    Selenium2Library.Go To    ${url}

Set Display Port
    [Arguments]    ${port}=${XVFB_PORT}
    [Documentation]    Sets the environment variable used by xvfb and the browser.
    OperatingSystem.Set Environment Variable    DISPLAY    :${port}

Open Virtual Display
    [Documentation]    Starts xvfb, a kind-ish x-server on RAM.
    Process.Start Process    Xvfb    :${XVFB_PORT}    -ac    -screen    0    1280x1024x16
    ...    alias=xvfb
    ${display}=    OperatingSystem.Get Environment Variable    DISPLAY    ${EMPTY}
    BuiltIn.Run Keyword Unless    "${display}"==":${XVFB_PORT}"    Set Display Port

Close DLUX And Terminate XVFB Process If Running
    [Documentation]    Closes all browser instances and terminates Xvfb if the process is running.
    Selenium2Library.Close All Browsers
    BuiltIn.Run Keyword If    ${USE_XVFB}    Terminate Process    xvfb

Launch DLUX
    [Documentation]    Launches with a delay to let the page load. If it cannot run the default browser, it will download
    ...    PhantomJS and use it instead. Steps of Launch DLUX are the following:
    ...    1. Trying to start Xvfb and load the browser defined by the variable ${BROWSER}.
    ...    2. If failed to start one of those task:
    ...    2.1 Download and extract PhantomJS if not already done
    ...    2.2 Create a custom PhantomJS webdriver based on the downloaded one
    ...    3. Go to DLUX login URL and wait until the HTML page contains a specific element.
    ${status}=    BuiltIn.Run Keyword And Return Status    Run Keywords    Open Virtual Display
    ...    AND    Selenium2Library.Open Browser    ${LOGIN_URL}    ${BROWSER}
    BuiltIn.Run Keyword Unless    ${status}    Open Headless Browser    ${LOGIN_URL}

Open DLUX Login Page
    [Arguments]    ${LOGIN URL}
    [Documentation]    Loads DLUX login page.
    Selenium2Library.Open Browser    ${LOGIN_URL}    ${BROWSER}
    Selenium2Library.Maximize Browser Window

Open Or Launch DLUX
    [Documentation]    Tries to open Dlux login page. If it fails, then launches Dlux using xvfb or headless browser.
    ${status}=    BuiltIn.Run Keyword And Return Status    Open DLUX Login Page    ${LOGIN_URL}
    BuiltIn.Run Keyword If    "${status}"=="False"    Launch DLUX

Verify Elements Of DLUX Login Page
    [Documentation]    Verifies elements presence in DLUX login page.
    Selenium2Library.Page Should Contain Image    ${OPENDAYLIGHT_IMAGE}
    Selenium2Library.Page Should Contain Element    ${LOGIN_USERNAME_INPUT_FIELD}
    Selenium2Library.Page Should Contain Element    ${LOGIN_PASSWORD_INPUT_FIELD}
    Selenium2Library.Page Should Contain Element    ${REMEMBER_ME_CHECKBOX}
    Selenium2Library.Page Should Contain Element    ${LOGIN_BUTTON}

Log In To DLUX With Valid Credentials
    [Documentation]    Inserts valid username and password and logs in DLUX.
    Selenium2Library.Wait Until Page Contains Element    ${LOGIN_USERNAME_INPUT_FIELD}
    Selenium2Library.Focus    ${LOGIN_USERNAME_INPUT_FIELD}
    Selenium2Library.Input Text    ${LOGIN_USERNAME_INPUT_FIELD}    ${LOGIN_USERNAME}
    Selenium2Library.Focus    ${LOGIN_PASSWORD_INPUT_FIELD}
    Selenium2Library.Input Text    ${LOGIN_PASSWORD_INPUT_FIELD}    ${LOGIN_PASSWORD}
    Focus And Click Element    ${LOGIN_BUTTON}

Log In To DLUX With Invalid Credentials
    [Arguments]    ${username}    ${password}
    [Documentation]    Tries to log in to DLUX with invalid credentials and verifies occurence of the error message.
    Selenium2Library.Focus    ${LOGIN_USERNAME_INPUT_FIELD}
    Selenium2Library.Input Text    ${LOGIN_USERNAME_INPUT_FIELD}    ${username}
    Selenium2Library.Focus    ${LOGIN_PASSWORD_INPUT_FIELD}
    Selenium2Library.Input Text    ${LOGIN_PASSWORD_INPUT_FIELD}    ${password}
    Focus And Click Element    ${LOGIN_BUTTON}
    Selenium2Library.Location Should Be    ${LOGIN_URL}
    Selenium2Library.Wait Until Page Contains    ${LOGIN_ERROR_MSG}

Open Or Launch DLUX Page And Log In To DLUX
    [Documentation]    Opens or launches Dlux and then logs in to Dlux.
    Open Or Launch DLUX
    Verify Elements Of DLUX Login Page
    Log In To DLUX With Valid Credentials

Return Webdriver Instance
    [Documentation]    Returns webdriver instance of current browser.
    ${webdriver}=    CustomSeleniumKeywords.Get Webdriver Instance
    [Return]    ${webdriver}

Return Webdriver Instance And Set It As Suite Variable
    [Documentation]    Returns webdriver instance of current browser and sets it as suite variable.
    ${webdriver}=    CustomSeleniumKeywords.Get Webdriver Instance
    BuiltIn.Set Suite Variable    ${webdriver}

Log Browser Console Content
    [Arguments]    ${webdriver}
    [Documentation]    Logs console content of webdriver instance to output test files.
    ${console_content}=    CustomSeleniumKeywords.Get Browser Console Content    ${webdriver}
    BuiltIn.Log    ${console_content}

Return Webdriver Instance And Log Browser Console Content
    [Documentation]    Returns webdriver instance of current browser under test and logs console content of the webdriver instance to output test files.
    ${webdriver}=    Return Webdriver Instance
    Log Browser Console Content    ${webdriver}

Navigate To URL
    [Arguments]    ${url}
    [Documentation]    Goes to the defined URL provided in an argument.
    ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Location Should Be    ${url}
    BuiltIn.Run Keyword Unless    ${status}    Selenium2Library.Go To    ${url}

Focus And Click Element
    [Arguments]    ${element}
    [Documentation]    Clicks the element with previous element visibility check and element focus.
    Selenium2Library.Wait Until Page Contains Element    ${element}
    Selenium2Library.Focus    ${element}
    Selenium2Library.Mouse Over    ${element}
    Selenium2Library.Click Element    ${element}

Mouse Down And Mouse Up Click Element
    [Arguments]    ${element}
    [Documentation]    Clicks the element by imitating mouse left button click down and click up.
    Selenium2Library.Wait Until Page Contains Element    ${element}
    Selenium2Library.Focus    ${element}
    Selenium2Library.Mouse Over    ${element}
    Selenium2Library.Mouse Down    ${element}
    Selenium2Library.Mouse Up    ${element}

Page Should Contain Element With Wait
    [Arguments]    ${element}
    [Documentation]    Similar to Selenium2Library.Wait Until Page Contains Element but returns web page source code when fails.
    BuiltIn.Wait Until Keyword Succeeds    2 min    5 sec    Selenium2Library.Page Should Contain Element    ${element}

Press Enter Key Click Element
    [Arguments]    ${element}
    [Documentation]    Simulates pressing the enter key on the web element the xpath of which is provided as an argument.
    Selenium2Library.Wait Until Page Contains Element    ${element}
    Selenium2Library.Focus    ${element}
    Selenium2Library.Press Key    ${element}    \\13

Helper Click
    [Arguments]    ${element_to_be_clicked}    ${element_to_be_checked}
    [Documentation]    Clicks the ${element_to_be_clicked} and verifies that page contains ${element_to_be_checked}.
    Selenium2Library.Focus    ${element_to_be_clicked}
    Selenium2Library.Click Element    ${element_to_be_clicked}
    Selenium2Library.Wait Until Page Contains Element    ${element_to_be_checked}

Helper Click With Wait Until Page Does Not Contain Element Check
    [Arguments]    ${element_to_be_clicked}    ${element_to_be_checked}
    [Documentation]    Clicks the ${element_to_be_clicked} and verifies that page does not contain ${element_to_be_checked}.
    Selenium2Library.Wait Until Element Is Visible    ${element_to_be_clicked}
    Selenium2Library.Focus    ${element_to_be_clicked}
    Selenium2Library.Click Element    ${element_to_be_clicked}
    ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Wait Until Page Does Not Contain Element    ${element_to_be_checked}
    BuiltIn.Should Be True    ${status}==True

Helper Click With Wait Until Element Is Not Visible Check
    [Arguments]    ${element_to_be_clicked}    ${element_to_be_checked}
    [Documentation]    Clicks the ${element_to_be_clicked} and verifies that page does not contain ${element_to_be_checked}.
    Selenium2Library.Wait Until Element Is Visible    ${element_to_be_clicked}
    Selenium2Library.Focus    ${element_to_be_clicked}
    Selenium2Library.Click Element    ${element_to_be_clicked}
    ${status}=    BuiltIn.Run Keyword And Return Status    Selenium2Library.Wait Until Element Is Not Visible    ${element_to_be_checked}
    BuiltIn.Should Be True    ${status}==True

Patient Click
    [Arguments]    ${element_to_be_clicked}    ${element_to_be_checked}
    [Documentation]    Combines clicking ${element_to_be_clicked} and checking that ${element_to_be_checked} is visible with
    ...    BuiltIn.Wait Until Keyword Succeeds keyword in order to secure reliable execution of Selenium2Library.Click Element
    ...    keyword in AngularJS webapp.
    BuiltIn.Wait Until Keyword Succeeds    2 min    5 sec    Helper Click    ${element_to_be_clicked}    ${element_to_be_checked}

Patient Click With Wait Until Page Does Not Contain Element Check
    [Arguments]    ${element_to_be_clicked}    ${element_to_be_checked}
    [Documentation]    Combines clicking ${element_to_be_clicked} and waiting until page does not contain ${element_to_be_checked}
    ...    in order to secure reliable execution of Selenium2Library.Click Element keyword in AngularJS webapp.
    BuiltIn.Wait Until Keyword Succeeds    2 min    5 sec    Helper Click With Wait Until Page Does Not Contain Element Check    ${element_to_be_clicked}    ${element_to_be_checked}

Patient Click With Wait Until Element Is Not Visible Check
    [Arguments]    ${element_to_be_clicked}    ${element_to_be_checked}
    [Documentation]    Combines clicking ${element_to_be_clicked} and waiting until ${element_to_be_checked} is not visible
    ...    in order to secure reliable execution of Selenium2Library.Click Element keyword in AngularJS webapp.
    BuiltIn.Wait Until Keyword Succeeds    2 min    5 sec    Helper Click With Wait Until Element Is Not Visible Check    ${element_to_be_clicked}    ${element_to_be_checked}

Return Reversed List
    [Arguments]    ${list}
    [Documentation]    Returns reversed list.
    ${list_to_reverse}=    Collections.Copy List    ${list}
    Collections.Reverse List    ${list_to_reverse}
    [Return]    ${list_to_reverse}

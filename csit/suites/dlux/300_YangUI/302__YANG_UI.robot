*** Settings ***
Documentation     Verification that Yang UI contains API, HISTORY, COLLECTION
...               and PARAMETERS tabs.
Suite Teardown    Close Browser
Library           Selenium2Library    timeout=10    implicit_wait=10    
#Library    Selenium2Library    timeout=10    implicit_wait=10    run_on_failure=Log Source
Resource          ../../../libraries/GUIKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/YangUIKeywords.robot

*** Variables ***
${LOGIN_USERNAME}    admin
${LOGIN_PASSWORD}    admin

*** Test Cases ***
Step_01
    [Documentation]    Open OpenDayLight page.
    ...    Result
    ...    Page http://127.0.0.1:8181/index.html#/login opened.
    ...    Login formular present on the page.
    Step_01_run

Step_02
    [Documentation]    Insert valid credentials and hit "Login" button.
    ...    Result
    ...    Location is http://127.0.0.1:8181/index.html#/topology.
    ...    Verification that the page contains "Controls" and button "Reload",
    ...    and Yang UI Submenu.
    Step_02_run

Step_03
    [Documentation]    Navigate to Yang UI. Verify, that Yang UI contains API, HISTORY, COLLECTION
    ...    and PARAMETERS tabs.
    ...    Result
    ...    Location should be http://127.0.0.1:8181/index.html#/yangui/index.
    Step_03_run

Step_04
    [Documentation]    Close Dlux.
    Step_04_run    

*** Keywords ***
Step_01_run
    Launch DLUX
    #Open DLUX Login Page    ${LOGIN URL}
    Verify Elements Of DLUX Login Page

Step_02_run
    Login DLUX    ${LOGIN_USERNAME}    ${LOGIN_PASSWORD}
    Verify Elements of DLUX Home Page
    Page Should Contain Element    ${Yang_UI_SUBMENU}

Step_03_run
    Click Element    ${Yang_UI_SUBMENU}
    Wait Until Page Contains Element    ${Loading_completed_successfully_ALERT}
    Page Should Contain Element    ${API_TAB}
    Page Should Contain Element    ${HISTORY_TAB}
    Page Should Contain Element    ${COLLECTION_TAB}
    Page Should Contain Element    ${PARAMETERS_TAB}
  
Step_04_run
    Close DLUX

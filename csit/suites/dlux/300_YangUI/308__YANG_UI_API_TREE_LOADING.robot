*** Settings ***
Documentation     Verification that root list contains 12 and more APIs.
...    (In our case 12 is a minimum number of loaded APIs.)
#Library           Selenium2Library    timeout=10    implicit_wait=10     run_on_failure=Log Source
Library           Selenium2Library    timeout=10    implicit_wait=10
Resource          ../../../libraries/GUIKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/YangUIKeywords.robot
#Suite Teardown    Close Browser

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
    [Documentation]    Navigate to Yang UI.
    ...    Result
    ...    Location should be http://127.0.0.1:8181/index.html#/yangui/index.
    Step_03_run

Step_04
    [Documentation]    Verify that the root list contains
    ...    at least 12 loaded APIs. 
    ...    (In our case 12 is a minimum number of loaded APIs.)
    ...    Result
    ...    The root list should contain >= 12 APIs loaded.
    Step_04_run
    
Step_05
    [Documentation]    Close Dlux.
    Step_05_run

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
    Location Should Be    ${Yang_UI_Submenu_URL}

Step_04_run
    Wait Until Page Contains Element    ${Loading_completed_successfully_ALERT}
    Page Should Contain Element    ${ROOT_TEXT}
    ${temp}=    Get Matching Xpath Count    ${API_Tree_ROW_1st_Level_XPATH}
    ${minimum_loaded_APIs_integer}=    Convert to Integer    ${Minimum_Loaded_Root_APIs_NUMBER}
    
    ${status}=    Run Keyword     Evaluate    ${temp}>=${minimum_loaded_APIs_integer}         
    Should Be Equal    "${status}"    "True"
  
    ${status}=    Run Keyword     Evaluate    ${temp}<${minimum_loaded_APIs_integer}         
    Should Be Equal    "${status}"    "False"
    
Step_05_run
    Close DLUX
        
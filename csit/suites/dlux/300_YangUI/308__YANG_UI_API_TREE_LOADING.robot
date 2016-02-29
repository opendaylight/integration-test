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


*** Test Cases ***
Step_01
    [Documentation]    Open OpenDayLight page.
    ...    Result
    ...    Page http://127.0.0.1:8181/index.html#/login opened.
    ...    Login formular present on the page.
    Step_01_run

Step_02
    [Documentation]    Insert valid credentials and hit "Login" button. Navigate to Yang UI.
    ...    Result
    ...    Location is http://127.0.0.1:8181/index.html#/topology.
    ...    Verification that the page contains "Controls" and button "Reload",
    ...    and Yang UI Submenu. Location should be http://127.0.0.1:8181/index.html#/yangui/index.
    Step_02_run

Step_03
    [Documentation]    Verify that the root list contains
    ...    at least 12 loaded APIs. 
    ...    (In our case 12 is a minimum number of loaded APIs.)
    ...    Result
    ...    The root list should contain >= 12 APIs loaded.
    Step_03_run
    
Step_04
    [Documentation]    Close Dlux.
    Step_04_run

*** Keywords ***
Step_01_run
    Launch Or Open DLUX Page And Login DLUX


Step_02_run
    Navigate To Yang UI Submenu


Step_03_run
    Page Should Contain Element    ${ROOT_TEXT}
    ${temp}=    Get Matching Xpath Count    ${API_Tree_ROW_1st_Level_XPATH}
    ${minimum_loaded_APIs_integer}=    Convert to Integer    ${Minimum_Loaded_Root_APIs_NUMBER}
    
    ${status}=    Run Keyword     Evaluate    ${temp}>=${minimum_loaded_APIs_integer}         
    Should Be Equal    "${status}"    "True"
  
    ${status}=    Run Keyword     Evaluate    ${temp}<${minimum_loaded_APIs_integer}         
    Should Be Equal    "${status}"    "False"
    
Step_04_run
    Close DLUX
        
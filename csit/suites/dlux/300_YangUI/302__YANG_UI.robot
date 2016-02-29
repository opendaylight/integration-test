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
    ...    Navigate to Yang UI. Verify, that Yang UI contains API, HISTORY, COLLECTION
    ...    and PARAMETERS tabs.
    ...    Result
    ...    Location should be http://127.0.0.1:8181/index.html#/yangui/index.
    Step_02_run

Step_03
    [Documentation]    Close Dlux.
    Step_03_run    

*** Keywords ***
Step_01_run
    Launch Or Open DLUX Page And Login DLUX


Step_02_run
    Navigate To Yang UI Submenu
    Page Should Contain Element    ${API_TAB}
    Page Should Contain Element    ${HISTORY_TAB}
    Page Should Contain Element    ${COLLECTION_TAB}
    Page Should Contain Element    ${PARAMETERS_TAB}
  
  
Step_03_run
    Close DLUX

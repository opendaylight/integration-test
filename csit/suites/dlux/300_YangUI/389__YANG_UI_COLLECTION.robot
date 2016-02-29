*** Settings ***
Documentation     Verification that HISTORY tab contains the elements it should contain.
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
    ...    and Yang UI Submenu.
    ...    Location should be http://127.0.0.1:8181/index.html#/yangui/index.
    Step_02_run

Step_03
    [Documentation]    Click COLLLECTION tab. If the page contains any request in 
    ...    history list, click Clear history data
    ...    Result
    ...    The page contains: - METHOD column header, - NAME column header, - URL column header, 
    ...    - STATUS column header, - ACTION column header, - Clear collection data button,
    ...    - Import collection section, -Import collection input, - Export collection button.
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
    Click Element    ${COLLECTION_TAB}
    Wait Until Page Contains Element    ${Collection_Table_Method_HEADER}
    Page Should Contain Element    ${Collection_Table_Name_HEADER}
    Page Should Contain Element    ${Collection_Table_Url_HEADER}
    Page Should Contain Element    ${Collection_Table_Status_HEADER}
    Page Should Contain Element    ${Collection_Table_Action_HEADER}
    Page Should Contain Element    ${Clear_Collection_Data_BUTTON}
    Page Should Contain Element    ${Import_Collection_SECTION}
    Page Should Contain Element    ${Import_Collections_INPUT}
    Page Should Contain Element    ${Export_Collection_BUTTON}


Step_04_run
    Close DLUX

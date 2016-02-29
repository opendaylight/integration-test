*** Settings ***
Documentation     Verification that API tab contains Expand all button,
...               Collapse others button, Custom API request button.
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
    [Documentation]    Click PARAMETERS tab. Verify that the page contains 
    ...    elements stated in result.
    ...    Result
    ...    The page contains:- NAME column header, - VALUE column header, 
    ...    - ACTION column header, - Add new parameter button, - Clear parameters button,
    ...    - Import parameters section, - Upload parameters input, - Export parameters button,
    ...    - Custom API request button.
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
    Click Element    ${PARAMETERS_TAB}
    Wait Until Page Contains Element    ${Parameters_Table_Name_HEADER}
    Page Should Contain Element    ${Parameters_Table_Value_HEADER}
    Page Should Contain Element    ${Parameters_Table_Action_HEADER}
    Page Should Contain Element    ${Add_New_Parameter_BUTTON}
    Page Should Contain Element    ${Clear_Parameters_BUTTON}
    Page Should Contain Element    ${Import_Parameters_SECTION}
    Page Should Contain Element    ${Import_Parameters_INPUT}
    Page Should Contain Element    ${Export_Parameters_BUTTON}


Step_04_run
    Close DLUX

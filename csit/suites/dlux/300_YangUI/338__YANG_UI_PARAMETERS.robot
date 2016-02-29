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
    [Documentation]    Click PARAMETERS tab. Verify that the page contains 
    ...    elements stated in result.
    ...    Result
    ...    The page contains:- NAME column header, - VALUE column header, 
    ...    - ACTION column header, - Add new parameter button, - Clear parameters button,
    ...    - Import parameters section, - Upload parameters input, - Export parameters button,
    ...    - Custom API request button.
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
    Wait Until Page Contains Element    ${Loading_completed_successfully_ALERT}
    
Step_04_run
    Click Element    ${PARAMETERS_TAB}
    Wait Until PAge Contains Element    ${Parameters_Table_Name_HEADER}
    Page Should Contain Element    ${Parameters_Table_Value_HEADER}
    Page Should Contain Element    ${Parameters_Table_Action_HEADER}
    Page Should Contain Element    ${Add_New_Parameter_BUTTON}
    Page Should Contain Element    ${Clear_Parameters_BUTTON}
    Page Should Contain Element    ${Import_Parameters_SECTION}
    Page Should Contain Element    ${Import_Parameters_INPUT}
    Page Should Contain Element    ${Export_Parameters_BUTTON}

Step_05_run
    Close DLUX

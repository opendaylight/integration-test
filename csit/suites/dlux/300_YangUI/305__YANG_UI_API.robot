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
    [Documentation]    Verify that the API tab contains Expand all button,
    ...    Collapse others button, Custom API request button.
    ...    Result
    ...    The page should contain buttons Expand all, Collapse others
    ...    and Custom API Request.
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
    Page Should Contain Button    ${Expand_all_BUTTON}
    Page Should Contain Element    ${Collapse_others_BUTTON}
    Page Should Contain Element    ${Custom_API_request_BUTTON}

Step_04_run
    Close DLUX

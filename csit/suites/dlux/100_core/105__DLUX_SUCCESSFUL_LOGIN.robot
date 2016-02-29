*** Settings ***
Documentation     Insert valid credentials and log in DLUX.
#Library           Selenium2Library    timeout=10    implicit_wait=10     run_on_failure=Log Source
Library           Selenium2Library    timeout=10    implicit_wait=10 
Resource          ../../../libraries/GUIKeywords.robot
Resource          ../../../libraries/Utils.robot

*** Variables ***
${LOGIN_USERNAME}    admin
${LOGIN_PASSWORD}    admin

*** Test Cases ***
Step_01
    [Documentation]    Open OpenDayLight page. Insert valid credentials and hit "Login" button.
    ...    Result
    ...    Page http://127.0.0.1:8181/index.html#/login opened.
    ...    Login formular present on the page.
    ...    Location is http://127.0.0.1:8181/index.html#/topology.
    ...    Verification that the page contains "Controls" and button "Reload",
    ...    and submenu YangUI.
    Step_01_run

Step_02
    [Documentation]    Close Dlux.
    Step_02_run

*** Keywords ***
Step_01_run
    Launch Or Open DLUX Page And Login DLUX

Step_02_run
    Close DLUX

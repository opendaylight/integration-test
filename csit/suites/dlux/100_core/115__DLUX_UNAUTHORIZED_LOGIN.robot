*** Settings ***
Documentation     Try whether it is possible to access pages available
...               only after logging in without being logged in.
Suite Teardown    Close Browser
#Library           Selenium2Library    timeout=10    implicit_wait=10     run_on_failure=Log Source
Library           Selenium2Library    timeout=10    implicit_wait=10 
Resource          ../../../libraries/GUIKeywords.robot
Resource          ../../../libraries/Utils.robot

*** Variables ***


*** Test Cases ***
Step_01
    [Documentation]    Open DLUX login page. Insert valid credentials and hit "Login" button.
    ...    Result
    ...    Page http://127.0.0.1:8181/index.html#/login opened.
    ...    Login formular present on the page.
    ...    Location is http://127.0.0.1:8181/index.html#/topology. Verification 
    ...    that the page contains "Controls" and button "Reload", and submenu Topolgy.
    Step_01_run

Step_02
    [Documentation]    Copy url of current location and close the browser. Open
    ...    browser and go to the URL you have copied, that is
    ...    http://127.0.0.1:8181/index.html#/topology.
    ...    Result
    ...    Login page http://127.0.0.1:8181/index.html#/login is opened. Login
    ...    formular is present on the page. Page contains "Please sign in".
    Step_02_run

Step_03
    [Documentation]    Close Dlux 
    Step_03_run


*** Keywords ***
Step_01_run
    Launch Or Open DLUX Page And Login DLUX

Step_02_run
    ${current_location}=    Get Location
    Should Be Equal    ${current_location}    ${LOGGED URL}
    Close Browser
    Sleep    5
    Launch Or Open DLUX
    Go To    ${current_location}
    Sleep    5
    Location Should Be    ${LOGIN URL}


Step_03_run
    Close Dlux


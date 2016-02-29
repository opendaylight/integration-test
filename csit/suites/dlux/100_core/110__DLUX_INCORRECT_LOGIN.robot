*** Settings ***
Documentation     Insert invalid credentials and try logging in DLUX.
#Library           Selenium2Library    timeout=10    implicit_wait=10     run_on_failure=Log Source
Library           Selenium2Library    timeout=10    implicit_wait=10 
Resource          ../../../libraries/GUIKeywords.robot
Resource          ../../../libraries/Utils.robot

*** Variables ***
${LOGIN_USERNAME}    admin    
${LOGIN_PASSWORD}    admin
${INVALID_USER}      invaliduser
${INVALID_PWD}       invalidpwd


*** Test Cases ***
Step_01
    [Documentation]    Open OpenDayLight page.
    ...    Result
    ...    Page http://127.0.0.1:8181/index.html#/login opened.
    ...    Login formular present on the page.
    Launch DLUX
    #Open DLUX Login Page    ${LOGIN URL}
    Verify Elements Of DLUX Login Page


Step_02
    [Documentation]    Insert invalid credentials and hit "Login" button.
    ...    Result
    ...    Location is http://127.0.0.1:8181/index.html#/login.
    ...    The application displays the error message "Unable to login".
    [Template]    Login DLUX With Invalid Credentials
    ${EMPTY}             ${EMPTY}             ${LOGIN_ERROR_MSG}    ${LOGGED URL}
    #${EMPTY}             ${INVALID_PWD}       ${LOGIN_ERROR_MSG}    ${LOGGED URL}
    #${EMPTY}             ${LOGIN_PASSWORD}    ${LOGIN_ERROR_MSG}    ${LOGGED URL}
    #${INVALID_USER}      ${EMPTY}             ${LOGIN_ERROR_MSG}    ${LOGGED URL}
    #${INVALID_USER}      ${INVALID_PWD}       ${LOGIN_ERROR_MSG}    ${LOGGED URL}
    #${INVALID_USER}      ${LOGIN_PASSWORD}    ${LOGIN_ERROR_MSG}    ${LOGGED URL}
    #${LOGIN_USERNAME}    ${EMPTY}             ${LOGIN_ERROR_MSG}    ${LOGGED URL}
    #${LOGIN_USERNAME}    ${INVALID_PWD}       ${LOGIN_ERROR_MSG}    ${LOGGED URL}

    [Teardown]    Report_Failure_Due_To_Bug     4631            

Step_03
    [Documentation]    Close Dlux.
    Close DLUX

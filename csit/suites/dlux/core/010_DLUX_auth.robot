*** Settings ***
Documentation     Test suite to verify authentication behavior of dlux-core.
Test Setup        Launch DLUX
Library           Selenium2Library
Resource          ../../../libraries/GUIKeywords.robot
Resource          ../../../libraries/Utils.robot

*** Variables ***
${LOGGED URL}     ${BASE_URL}#/topology
${BAD USER}       lorem
${BAD PWD}        ipsum
${ERROR MSG}      Unable to login

*** Test Cases ***
Check Redirection If Not Loggeg In
    [Documentation]    By default, DLUX redirect all unlogged user to the login page.
    Location Should Be    ${LOGIN URL}
    [Teardown]    Close DLUX

Check Loggin Succeeded
    [Documentation]    With good credential, the user should be redirect on the topology page.
    Log In To DLUX
    Wait Until Keyword Succeeds    2s     1s
    ...                            Location Should Be    ${LOGGED URL}
    [Teardown]    Close DLUX

# Will fail, dialog from HTTP Auth Basic take over the focus (Bug 4631)
Check Wrong Credential
    [Documentation]    With invalid credential, DLUX will display an error message on the login page.
    Log In To DLUX    ${BAD USER}    ${BAD PWD}
    Location Should Be    ${LOGIN URL}
    ${msg}    Get Text    dom=$('div.panel-heading').next()   # Enhancement Bug 4739
    Should Be Equal    ${msg}    ${ERROR MSG}
    [Teardown]    Run Keywords     Report_Failure_Due_To_Bug    4631
    ...           AND    Close DLUX

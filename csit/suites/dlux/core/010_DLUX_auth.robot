*** Settings ***
Documentation     Test suite to verify authentication behavior of dlux-core.
Resource          ../resources.robot

*** Variables ***
${LOGGEG URL}     ${BASE_URL}#/topology
${BAD USER}       lorem
${BAD PWD}        ipsum
${ERROR MSG}      Unable to login

*** Test Cases ***
Check Redirection If Not Loggeg In
    [Documentation]    By default, DLUX redirect all unlogged user to the login page.
    Lauch DLUX
    Location Should Be    ${LOGIN URL}
    [Teardown]    Close Browser

Check Loggin Succeeded
    [Documentation]    With good credential, the user should be redirect on the topology page.
    Lauch DLUX
    Log In To DLUX
    Sleep    1    # Robot is too fast. Url does not has time to change
    Location Should Be    ${LOGGEG URL}
    [Teardown]    Close Browser

# Will fail, dialog from HTTP Auth Basic take over the focus (Bug 4631 )
Check Wrong Credential
    [Documentation]    With invalid credential, DLUX will display an error message on the login page.
    Lauch DLUX
    Log In To DLUX    ${BAD USER}    ${BAD PWD}
    Location Should Be    ${LOGIN URL}
    ${msg}    Get Text    dom=$('div.panel-heading').next() # The error message does not have an identificator, we need to search it in the DOM.
    Should Be Equal    ${msg}    ${ERROR MSG}
    [Teardown]    Close Browser

ettings ***
Documentation     Test suite for natapp
Suite Setup       Start Suite
Suite Teardown    RequestsLibrary.Delete_All_Sessions
Variables         ${CURDIR}/../../../variables/Variables.py
Library           RequestsLibrary

*** Keywords ***
Start Suite
    [Documentation]    Test suit for natapp
    Log to Console    Start the tests
    ${AUTH} =    Set Variable  ${ODL_RESTCONF_USER}  ${ODL_RESTCONF_PASSWORD}
    RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}

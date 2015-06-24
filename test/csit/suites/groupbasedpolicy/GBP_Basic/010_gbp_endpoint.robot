*** Settings ***
Documentation     Test suite for Group Based Policy, Operates functions from Restconf APIs.
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.txt

*** Variables ***
${REGISTER_ENDPOINT_FILE}  ../../../variables/gbp/register-endpoint.json
${UNREGISTER_ENDPOINT_FILE}  ../../../variables/gbp/unregister-endpoint.json

*** Test Cases ***
Register and Unregister Endpoint
    [Documentation]    Register and Unregister Endpoint from JSON file
    Post Elements To URI From File    ${GBP_REGEP_API}  ${REGISTER_ENDPOINT_FILE}
    Post Elements To URI From File  ${GBP_UNREGEP_API}  ${UNREGISTER_ENDPOINT_FILE}

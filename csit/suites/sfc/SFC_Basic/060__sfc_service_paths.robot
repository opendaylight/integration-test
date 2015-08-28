*** Settings ***
Documentation     Test suite for SFC Service Function Paths, Operates paths from Restconf APIs.
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${SERVICE_FUNCTION_PATHS_URI}    /restconf/config/service-function-path:service-function-paths/
${SERVICE_FUNCTION_PATHS_FILE}    ../../../variables/sfc/service-function-paths.json
${SERVICE_FUNCTION_PATH400_URI}    /restconf/config/service-function-path:service-function-paths/service-function-path/SFC1-400
${SERVICE_FUNCTION_PATH400_FILE}    ../../../variables/sfc/sfp_sfc1_path400.json

*** Test Cases ***
Add Service Function Paths
    [Documentation]    Add Service Function Paths from JSON file
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTION_PATHS_FILE}
    ${jsonbody}    To Json    ${body}
    ${paths}    Get From Dictionary    ${jsonbody}    service-function-paths
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FUNCTION_PATHS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${path}    Get From Dictionary    ${result}    service-function-paths
    Lists Should be Equal    ${path}    ${paths}

Delete All Service Function Paths
    [Documentation]    Delete all Service Function Paths
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FUNCTION_PATHS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Remove All Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FUNCTION_PATHS_URI}
    Should Be Equal As Strings    ${resp.status_code}    404

Get one Service Function Path
    [Documentation]    Get one Service Function Path
    Remove All Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}
    ${elements}=    Create List    SFC1-100    "service-chain-name":"SFC1"
    Check For Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}service-function-path/SFC1-100    ${elements}

Get A Non-existing Service Function Path
    [Documentation]    Get A Non-existing Service Function Path
    Remove All Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FUNCTION_PATHS_URI}service-function-path/non-existing-sfp
    Should Be Equal As Strings    ${resp.status_code}    404

Delete A Service Function Path
    [Documentation]    Delete A Service Function Path
    Remove All Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FUNCTION_PATHS_URI}service-function-path/SFC1-100
    Should Be Equal As Strings    ${resp.status_code}    200
    Remove All Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}service-function-path/SFC1-100
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FUNCTION_PATHS_URI}service-function-path/SFC1-100
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FUNCTION_PATHS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Contain    ${resp.content}    SFC1-100

Delete A Non-existing Empty Service Function Path
    [Documentation]    Delete A Non existing Service Function Path
    Remove All Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTION_PATHS_FILE}
    ${jsonbody}    To Json    ${body}
    ${paths}    Get From Dictionary    ${jsonbody}    service-function-paths
    Remove All Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}service-function-path/non-existing-sfp
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FUNCTION_PATHS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${path}    Get From Dictionary    ${result}    service-function-paths
    Lists Should be Equal    ${path}    ${paths}

Put one Service Function
    [Documentation]    Put one Service Function
    Remove All Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATH400_URI}    ${SERVICE_FUNCTION_PATH400_FILE}
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FUNCTION_PATH400_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    SFC1-400
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_FUNCTION_PATHS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    SFC1-400

Clean All Service Function Paths After Tests
    [Documentation]    Delete all Service Function Paths From Datastore After Tests
    Remove All Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}

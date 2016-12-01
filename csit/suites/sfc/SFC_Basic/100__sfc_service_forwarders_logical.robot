*** Settings ***
Documentation     Test suite for SFC Service Function Forwarders, Operates SFFs from Restconf APIs. Logical SFF
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Test Setup        Remove All Elements If Exist    ${SERVICE_FORWARDERS_URI}
Test Teardown     Remove All Elements If Exist    ${SERVICE_FORWARDERS_URI}
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot

*** Variables ***
${VERSION_DIR}    master
${SERVICE_FORWARDERS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-forwarders-logicallsff.json
${SFF_SFFLOG_URI}    ${SERVICE_FORWARDER_URI}sfflogical1/
${SFF_SFFLOG_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-forwarder-logicallsff1.json

*** Test Cases ***
Put Service Function Forwarders
    [Documentation]    Add Service Function Forwarders from JSON file. Logical SFF
    [Tags]    include
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FORWARDERS_FILE}
    ${jsonbody}    To Json    ${body}
    ${forwarders}    Get From Dictionary    ${jsonbody}    service-function-forwarders
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FORWARDERS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${result}    To JSON    ${resp.content}
    ${forwarder}    Get From Dictionary    ${result}    service-function-forwarders
    Lists Should be Equal    ${forwarder}    ${forwarders}

Delete All Service Function Forwarders
    [Documentation]    Delete all Service Function Forwarders. Logical SFF
    [Tags]    include
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FORWARDERS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FORWARDERS_URI}
    Should Be Equal As Strings    ${resp.status_code}    404

Get one Service Function Forwarder
    [Documentation]    Get one Service Function Forwarder. Logical SFF
    [Tags]    include
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${elements}=    Create List    sfflogical1
    Check For Elements At URI    ${SERVICE_FORWARDER_URI}sfflogical1    ${elements}

Delete A Service Function Forwarder
    [Documentation]    Delete A Service Function Forwarder. Logical SFF
    [Tags]    include
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FORWARDER_URI}sfflogical1
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SERVICE_FORWARDER_URI}sfflogical1
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FORWARDER_URI}sfflogical1
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FORWARDERS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Contain    ${resp.content}    SF1

Put one Service Function Forwarder
    [Documentation]    Put one Service Function Forwarder. Logical SFF
    [Tags]    include
    Add Elements To URI From File    ${SFF_SFFLOG_URI}    ${SFF_SFFLOG_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SFF_SFFLOG_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${elements}=    Create List    sfflogical1
    Check For Elements At URI    ${SFF_SFFLOG_URI}    ${elements}
    Check For Elements At URI    ${SERVICE_FORWARDERS_URI}    ${elements}

*** keywords ***
Init Suite
    [Documentation]    Initialize session and ODL version specific variable. Logical SFFs
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}


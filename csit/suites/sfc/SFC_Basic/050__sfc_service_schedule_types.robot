*** Settings ***
Documentation     Test suite for SFC Function Schedule Algorithm Types, Operates types from Restconf APIs.
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${SERVICE_SCHED_TYPES_URI}    /restconf/config/service-function-scheduler-type:service-function-scheduler-types/
${SERVICE_SCHED_TYPES_FILE}    ../../../variables/sfc/service-schedule-types.json
${SERVICE_WSP_SCHED_TYPE_URI}    /restconf/config/service-function-scheduler-type:service-function-scheduler-types/service-function-scheduler-type/service-function-scheduler-type:weighted-shortest-path
${SERVICE_WSP_SCHED_TYPE_FILE}    ../../../variables/sfc/service-wsp-schedule-type.json

*** Test Cases ***
Add Service Function Schedule Algorithm Types
    [Documentation]    Add Service Function Schedule Algorithm Types from JSON file
    Add Elements To URI From File    ${SERVICE_SCHED_TYPES_URI}    ${SERVICE_SCHED_TYPES_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_SCHED_TYPES_FILE}
    ${jsonbody}    To Json    ${body}
    ${types}    Get From Dictionary    ${jsonbody}    service-function-scheduler-types
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_SCHED_TYPES_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${type}    Get From Dictionary    ${result}    service-function-scheduler-types
    Lists Should be Equal    ${type}    ${types}

Delete All Service Function Schedule Algorithm Types
    [Documentation]    Delete Service Function Schedule Algorithm Types
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_SCHED_TYPES_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_SCHED_TYPES_URI}
    Should Be Equal As Strings    ${resp.status_code}    404

Get Ramdom Schedule Algorithm Type
    [Documentation]    Get Ramdom Schedule Algorithm Type
    Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}
    Add Elements To URI From File    ${SERVICE_SCHED_TYPES_URI}    ${SERVICE_SCHED_TYPES_FILE}
    ${elements}=    Create List    random    "enabled":false    service-function-scheduler-type:random
    Check For Elements At URI    ${SERVICE_SCHED_TYPES_URI}service-function-scheduler-type/service-function-scheduler-type:random    ${elements}
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_SCHED_TYPES_URI}service-function-scheduler-type/service-function-scheduler-type:random

Get A Non-existing Service Function Schedule Algorithm Type
    [Documentation]    Get A Non-existing Service Function Schedule Algorithm Type
    Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}
    Add Elements To URI From File    ${SERVICE_SCHED_TYPES_URI}    ${SERVICE_SCHED_TYPES_FILE}
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_SCHED_TYPES_URI}service-function-scheduler-type/service-function-scheduler-type:user-defined
    Should Be Equal As Strings    ${resp.status_code}    404

Delete Ramdom Schedule Algorithm Type
    [Documentation]    Delete Ramdom Schedule Algorithm Type
    Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}
    Add Elements To URI From File    ${SERVICE_SCHED_TYPES_URI}    ${SERVICE_SCHED_TYPES_FILE}
    Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}service-function-scheduler-type/service-function-scheduler-type:random
    ${elements}=    Create List    random    service-function-scheduler-type:random
    Check For Elements Not At URI    ${SERVICE_SCHED_TYPES_URI}    ${elements}

Delete A Non-existing Service Function Schedule Algorithm Type
    [Documentation]    Delete A Non existing Service Function Schedule Algorithm Type
    Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}
    Add Elements To URI From File    ${SERVICE_SCHED_TYPES_URI}    ${SERVICE_SCHED_TYPES_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_SCHED_TYPES_FILE}
    ${jsonbody}    To Json    ${body}
    ${types}    Get From Dictionary    ${jsonbody}    service-function-scheduler-types
    Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}service-function-scheduler-type/service-function-scheduler-type:user-defined
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_SCHED_TYPES_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${type}    Get From Dictionary    ${result}    service-function-scheduler-types
    Lists Should be Equal    ${type}    ${types}

Put one Service Function Schedule Algorithm Type
    [Documentation]    Put one Service Function Schedule Algorithm Type
    Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}
    Add Elements To URI From File    ${SERVICE_WSP_SCHED_TYPE_URI}    ${SERVICE_WSP_SCHED_TYPE_FILE}
    ${elements}=    Create List    weighted-shortest-path    service-function-scheduler-type:weighted-shortest-path
    Check For Elements At URI    ${SERVICE_WSP_SCHED_TYPE_URI}    ${elements}
    Check For Elements At URI    ${SERVICE_SCHED_TYPES_URI}    ${elements}

Clean Datastore After Tests
    [Documentation]    Delete All Service Function Schedule Algorithm Types From Datastore After Tests
    Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}

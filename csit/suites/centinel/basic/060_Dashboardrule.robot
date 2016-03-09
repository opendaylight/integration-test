*** Settings ***
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           RequestsLibrary
Library           OperatingSystem
Library           requests
Library           json
Library           HttpLibrary.HTTP
Variables         ../../../variables/Variables.py

*** Variables ***
${GET_DASHBOARDRECORD}    restconf/operational/dashboardrule:dashboardRecord/
${SET_DASHBOARD_JSON}    ${CURDIR}/../../../variables/centinel/set_dashboard.json
${SET_DASHBOARDRECORD}    restconf/operations/dashboardrule:set-dashboard
${DELETE_DASHBOARDRECORD}    restconf/operations/dashboardrule:delete-dashboard

*** Test Cases ***
Set DashboardRecord
    ${body}    OperatingSystem.Get File    ${SET_DASHBOARD_JSON}
    ${resp}    RequestsLibrary.Post    session    ${SET_DASHBOARDRECORD}    ${body}
    Should Be Equal As Strings    ${resp.status_code}    200

Get DashboardRecord
    ${resp}    RequestsLibrary.Get    session    ${GET_DASHBOARDRECORD}
    Should Be Equal As Strings    ${resp.status_code}    200

Delete DashboardRecord
    ${resp}    RequestsLibrary.Get    session    ${GET_DASHBOARDRECORD}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${dashboardRecord}    Get From Dictionary    ${result}    dashboardRecord
    ${dashboardList}    Get From Dictionary    ${dashboardRecord}    dashboardList
    ${dashboard}    Get From List    ${dashboardList}    0
    ${dashboardID}    Get From Dictionary    ${dashboard}    dashboardID
    Set Suite Variable    ${dashboardJson}    {"input":{"dashboardID":"${dashboardID}"}}
    ${delresp}    RequestsLibrary.Post    session    ${DELETE_DASHBOARDRECORD}    ${dashboardJson}
    Should Be Equal As Strings    ${delresp.status_code}    200

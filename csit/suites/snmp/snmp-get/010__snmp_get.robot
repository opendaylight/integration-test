*** Settings ***
Documentation     Test suite for SNMP
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Library           ../../../libraries/Topology.py
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${REST_CONTEXT_SNMP_SET}    /restconf/operations/snmp:snmp-get
${DEVICE_IP}      10.86.3.13

*** Test Cases ***
List connections
    [Documentation]    SNMP get
    [Tags]    SNMP get
    ${resp}    Post    session    ${REST_CONTEXT_SNMP_SET}    data={"input": {"ip-address": "${DEVICE_IP}","oid" : "1.3.6.1.2.1.1.1.0","get-type" : "GET-BULK","community" : "private" } }
    Should Be Equal As Strings    ${resp.status_code}    200
    [Teardown]    Report_Failure_Due_To_Bug    5360

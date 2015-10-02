*** Settings ***
Documentation     Test suite for SNMP
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Library           ../../../libraries/Topology.py
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

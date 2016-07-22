*** Settings ***
Documentation     Test suite for RPC
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py



*** Variables ***
${REST_CON}           /restconf/operations/usecpluginaaa:attemptFromIP
${REST_CON1}          /restconf/operations/usecpluginaaa:attemptOnDateTime
${FILE}               ${CURDIR}/../../../variables/xmls/set_src_ip.json
${FILE1}              ${CURDIR}/../../../variables/xmls/set_datetime.json

*** Test Cases ***
Set SrcIp
    [Documentation]    Post a value through REST-API
    [Tags]    Post
    ${body}    OperatingSystem.Get File    ${FILE}
    Set Suite Variable    ${body}
    ${resp}    RequestsLibrary.Post Request    session   ${REST_CON}      headers=${HEADERS}   data= ${body} 
    Should Be Equal As Strings    ${resp.status_code}    200
      
  
Set dateTime
    [Documentation]    Post a value through REST-API
    [Tags]    Post
    ${body}    OperatingSystem.Get File    ${FILE1}
    Set Suite Variable    ${body}
    ${resp}    RequestsLibrary.Post Request    session   ${REST_CON1}      headers=${HEADERS}   data=${body}
    Should Be Equal As Strings    ${resp.status_code}    200


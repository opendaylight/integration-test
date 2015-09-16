*** Settings ***
Documentation     Test suite to determine the southbound Map-Request serving rate
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           Collections
Library           OperatingSystem
Library           Process
Library           RequestsLibrary
Library           String
Variables         ../../../variables/Variables.py

*** Variables ***
${MAPPINGS}=          10000
${MAPPING_BLASTER}    ${CURDIR}/../../../../tools/odl-lispflowmapping-performance-tests/mapping_blaster.py
${GET_STATS_URL}      /restconf/operations/lisp-sb:get-stats
${RST_STATS_URL}      /restconf/operations/lisp-sb:reset-stats
${REPLAY_PPS}         100000
${REPLAY_CNT}         1000
${REPLAY_FILE}        ${CURDIR}/../../../../tools/odl-lispflowmapping-performance-tests/encapsulated-map-requests-random.pcap
${RESULTS_FILE}       pps.csv

*** Test Cases ***
Add Simple IPv4 Mappings
    ${result}=    Run Process    ${MAPPING_BLASTER}  --host  ${CONTROLLER}  --mappings  ${MAPPINGS}
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0

Generate Test Traffic
    Reset Stats
    ${result}=    Run Process    /usr/local/bin/udpreplay  --pps  ${REPLAY_PPS}  --repeat  ${REPLAY_CNT}  --port  4342  ${REPLAY_FILE}
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0
    ${partial}=    Fetch From Left    ${result.stdout}    s =
    Log    ${partial}
    ${seconds}=    Fetch From Right    ${partial}    ${SPACE}
    ${seconds}=    Convert To Number    ${seconds}
    Log    ${seconds}
    Set Suite Variable    ${seconds}

Compute And Export MapReply Rate
    ${txmrep}=    Get Transmitted Map-Requests Stats
    ${pps}=    Evaluate    ${txmrep}/${seconds}
    Log    ${pps}
    Create File    ${RESULTS_FILE}    replies/s\n
    Append To File    ${RESULTS_FILE}    ${pps}\n

*** Keywords ***
Reset Stats
    ${resp}=    RequestsLibrary.Post    session    ${RST_STATS_URL}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Transmitted Map-Requests Stats
    ${resp}=    RequestsLibrary.Post    session    ${GET_STATS_URL}
    Log    ${resp.content}
    ${output}=     Get From Dictionary    ${resp.json()}    output
    ${stats}=      Get From Dictionary    ${output}         control-message-stats
    ${ctrlmsg}=    Get From Dictionary    ${stats}          control-message
    ${replies}=    Get From List          ${ctrlmsg}        2
    ${txmrep}=     Get From Dictionary    ${replies}        tx-count
    ${txmrep}=     Convert To Integer     ${txmrep}
    Log    ${txmrep}
    [Return]    ${txmrep}

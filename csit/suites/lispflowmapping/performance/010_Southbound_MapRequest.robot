*** Settings ***
Documentation     LISP southbound performance tests
Suite Setup       Prepare Environment
Suite Teardown    Destroy Environment
Library           Collections
Library           DateTime
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${MAPPINGS}       10000
${LISP_SCAPY}     https://raw.githubusercontent.com/intouch/py-lispnetworking/master/lisp.py
${TOOLS_DIR}      ${CURDIR}/../../../../tools/odl-lispflowmapping-performance-tests/
${PCAP_CREATOR}    ${TOOLS_DIR}/create_lisp_control_plane_pcap.py
${MAPPING_BLASTER}    ${TOOLS_DIR}/mapping_blaster.py
${REPLAY_PPS}     100000
${REPLAY_CNT}     1000
${REPLAY_FILE_MREQ}    encapsulated-map-requests-sequential.pcap
${REPLAY_FILE_MREG}    map-registers-sequential.pcap
${RPCS_RESULTS_FILE}    rpcs.csv
${PPS_RESULTS_FILE}    pps.csv

*** Test Cases ***
Add Simple IPv4 Mappings
    ${start_date}=    Get Current Date
    Run Process With Logging And Status Check    ${MAPPING_BLASTER}    --host    ${ODL_SYSTEM_IP}    --mappings    ${MAPPINGS}
    ${end_date}=    Get Current Date
    ${add_seconds}=    Subtract Date From Date    ${end_date}    ${start_date}
    Log    ${add_seconds}
    Set Suite Variable    ${add_seconds}

Generate Map-Request Test Traffic
    Reset Stats
    ${result}=    Run Process With Logging And Status Check    /usr/local/bin/udpreplay    --pps    ${REPLAY_PPS}    --repeat    ${REPLAY_CNT}
    ...    --host    ${ODL_SYSTEM_IP}    --port    4342    ${REPLAY_FILE_MREQ}
    ${partial}=    Fetch From Left    ${result.stdout}    s =
    Log    ${partial}
    ${get_seconds_mreq}=    Fetch From Right    ${partial}    ${SPACE}
    ${get_seconds_mreq}=    Convert To Number    ${get_seconds_mreq}
    Log    ${get_seconds_mreq}
    Set Suite Variable    ${get_seconds_mreq}

Generate Map-Register Test Traffic
    ${result}=    Run Process With Logging And Status Check    /usr/local/bin/udpreplay    --pps    ${REPLAY_PPS}    --repeat    ${REPLAY_CNT}
    ...    --host    ${ODL_SYSTEM_IP}    --port    4342    ${REPLAY_FILE_MREG}
    ${partial}=    Fetch From Left    ${result.stdout}    s =
    Log    ${partial}
    ${get_seconds_mreg}=    Fetch From Right    ${partial}    ${SPACE}
    ${get_seconds_mreg}=    Convert To Number    ${get_seconds_mreg}
    Log    ${get_seconds_mreg}
    Set Suite Variable    ${get_seconds_mreg}

Compute And Export Results
    ${rpcs}=    Evaluate    ${MAPPINGS}/${add_seconds}
    Log    ${rpcs}
    Create File    ${RPCS_RESULTS_FILE}    store/s\n
    Append To File    ${RPCS_RESULTS_FILE}    ${rpcs}\n
    ${tx_mrep}=    Get Transmitted Map-Requests Stats
    ${pps_mrep}=    Evaluate    ${tx_mrep}/${get_seconds_mreq}
    Log    ${pps_mrep}
    Create File    ${PPS_RESULTS_FILE}    replies/s,notifies/s\n
    ${tx_mnot}=    Get Transmitted Map-Notifies Stats
    ${pps_mnot}=    Evaluate    ${tx_mnot}/${get_seconds_mreg}
    Log    ${pps_mnot}
    Append To File    ${PPS_RESULTS_FILE}    ${pps_mrep},${pps_mnot}\n

*** Keywords ***
Reset Stats
    ${resp}=    RequestsLibrary.Post Request    session    ${LFM_SB_RPC_API}:reset-stats
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Transmitted Map-Requests Stats
    ${resp}=    RequestsLibrary.Post Request    session    ${LFM_SB_RPC_API}:get-stats
    Log    ${resp.content}
    ${output}=    Get From Dictionary    ${resp.json()}    output
    ${stats}=    Get From Dictionary    ${output}    control-message-stats
    ${ctrlmsg}=    Get From Dictionary    ${stats}    control-message
    ${replies}=    Get From List    ${ctrlmsg}    2
    ${tx_mrep}=    Get From Dictionary    ${replies}    tx-count
    ${tx_mrep}=    Convert To Integer    ${tx_mrep}
    Log    ${tx_mrep}
    [Return]    ${tx_mrep}

Get Transmitted Map-Notifies Stats
    ${resp}=    RequestsLibrary.Post Request    session    ${LFM_SB_RPC_API}:get-stats
    Log    ${resp.content}
    ${output}=    Get From Dictionary    ${resp.json()}    output
    ${stats}=    Get From Dictionary    ${output}    control-message-stats
    ${ctrlmsg}=    Get From Dictionary    ${stats}    control-message
    ${notifies}=    Get From List    ${ctrlmsg}    4
    ${tx_mnot}=    Get From Dictionary    ${notifies}    tx-count
    ${tx_mnot}=    Convert To Integer    ${tx_mnot}
    Log    ${tx_mnot}
    [Return]    ${tx_mnot}

Prepare Environment
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Run Process With Logging And Status Check    wget    -P    ${TOOLS_DIR}    ${LISP_SCAPY}
    Run Process With Logging And Status Check    ${PCAP_CREATOR}    --requests    ${MAPPINGS}

Destroy Environment
    Delete All Sessions
    Remove File    ${TOOLS_DIR}/lisp.py*
    Remove File    ${REPLAY_FILE_MREQ}
    Remove File    ${REPLAY_FILE_MREG}

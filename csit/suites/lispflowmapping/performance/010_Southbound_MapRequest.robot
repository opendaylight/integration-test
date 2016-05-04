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
Resource          ../../../libraries/LISPFlowMapping.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${MAPPINGS}       10000
${LISP_SCAPY}     https://raw.githubusercontent.com/ljakab/py-lispnetworking/opendaylight/lisp.py
${TOOLS_DIR}      ${CURDIR}/../../../../tools/odl-lispflowmapping-performance-tests/
${PCAP_CREATOR}    ${TOOLS_DIR}/create_lisp_control_plane_pcap.py
${MAPPING_BLASTER}    ${TOOLS_DIR}/mapping_blaster.py
${REPLAY_PPS}     100000
${REPLAY_CNT}     1000
${REPLAY_FILE_MREQ}    encapsulated-map-requests-sequential.pcap
${REPLAY_FILE_MREG}    map-registers-sequential-no-auth.pcap
${REPLAY_FILE_MRGA}    map-registers-sequential-sha1-auth.pcap
${RPCS_RESULTS_FILE}    rpcs.csv
${PPS_RESULTS_FILE}    pps.csv

*** Test Cases ***
Add Simple IPv4 Mappings
    ${start_date}=    Get Current Date
    Run Process With Logging And Status Check    ${MAPPING_BLASTER}    --host    ${ODL_SYSTEM_IP}    --mappings    ${MAPPINGS}
    ${end_date}=    Get Current Date
    ${add_seconds}=    Subtract Date From Date    ${end_date}    ${start_date}
    Log    ${add_seconds}
    ${rpcs}=    Evaluate    int(${MAPPINGS}/${add_seconds})
    Log    ${rpcs}
    Append To File    ${RPCS_RESULTS_FILE}    ${rpcs}\n

Generate Map-Request Test Traffic
    ${pps_mrep}=    Lossy Test    2    ${REPLAY_FILE_MREQ}
    Set Suite Variable    ${pps_mrep}

Generate Map-Register Test Traffic
    Allow Unauthenticated Map-Registers
    ${pps_mnot}=    Lossy Test    4    ${REPLAY_FILE_MREG}
    Set Suite Variable    ${pps_mnot}

Generate Authenticated Map-Register Test Traffic
    Allow Authenticated Map-Registers
    ${pps_mnot_auth}=    Lossy Test    4    ${REPLAY_FILE_MRGA}
    Set Suite Variable    ${pps_mnot_auth}

*** Keywords ***
Clean Up
    Clear Config Datastore
    Clear Operational Datastore
    Sleep    500ms

Clear Config Datastore
    ${resp}=    RequestsLibrary.Delete Request    session    /restconf/config/odl-mappingservice:mapping-database
    Log    ${resp.content}

Clear Operational Datastore
    ${resp}=    RequestsLibrary.Delete Request    session    /restconf/operational/odl-mappingservice:mapping-database
    Log    ${resp.content}

Lossy Test
    [Arguments]    ${lisp_type}    ${replay_file}
    [Documentation]    This test will send traffic at a rate that is known to be
    ...    higher than the capacity of the LISP Flow Mapping service and count
    ...    the reply messages. Using the test's time duration, it computes the
    ...    average reply packet rate in packets per second
    ${elapsed_time}=    Generate Test Traffic    ${REPLAY_PPS}    ${REPLAY_CNT}    ${replay_file}
    ${odl_tx_count}=    Get Control Message Stats    ${lisp_type}    tx-count
    ${pps}=    Evaluate    int(${odl_tx_count}/${elapsed_time})
    Log    ${pps}
    Clean Up
    [Return]    ${pps}

Generate Test Traffic
    [Arguments]    ${replay_pps}    ${replay_cnt}    ${replay_file}
    Reset Stats
    ${result}=    Run Process With Logging And Status Check    /usr/local/bin/udpreplay    --pps    ${replay_pps}    --repeat    ${replay_cnt}
    ...    --host    ${ODL_SYSTEM_IP}    --port    4342    ${replay_file}
    ${partial}=    Fetch From Left    ${result.stdout}    s =
    Log    ${partial}
    ${time}=    Fetch From Right    ${partial}    ${SPACE}
    ${time}=    Convert To Number    ${time}
    Log    ${time}
    [Return]    ${time}

Reset Stats
    ${resp}=    RequestsLibrary.Post Request    session    ${LFM_SB_RPC_API}:reset-stats
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Allow Unauthenticated Map-Registers
    ${add_key}=    OperatingSystem.Get File    ${JSON_DIR}/rpc_add-key_default_no-auth.json
    Post Log Check    ${LFM_RPC_API}:add-key    ${add_key}

Allow Authenticated Map-Registers
    ${add_key}=    OperatingSystem.Get File    ${JSON_DIR}/rpc_add-key_default.json
    Post Log Check    ${LFM_RPC_API}:add-key    ${add_key}

Get Control Message Stats
    [Arguments]    ${lisp_type}    ${stat_type}
    ${resp}=    RequestsLibrary.Post Request    session    ${LFM_SB_RPC_API}:get-stats
    Log    ${resp.content}
    ${output}=    Get From Dictionary    ${resp.json()}    output
    ${stats}=    Get From Dictionary    ${output}    control-message-stats
    ${ctrlmsg}=    Get From Dictionary    ${stats}    control-message
    ${ctrlmsg_type}=    Get From List    ${ctrlmsg}    ${lisp_type}
    ${msg_cnt}=    Get From Dictionary    ${ctrlmsg_type}    ${stat_type}
    ${msg_cnt}=    Convert To Integer    ${msg_cnt}
    Log    ${msg_cnt}
    [Return]    ${msg_cnt}

Prepare Environment
    Create File    ${RPCS_RESULTS_FILE}    store/s\n
    Create File    ${PPS_RESULTS_FILE}    replies/s,notifies/s,auth_notifies/s\n
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Run Process With Logging And Status Check    wget    -P    ${TOOLS_DIR}    ${LISP_SCAPY}
    Run Process With Logging And Status Check    ${PCAP_CREATOR}    --requests    ${MAPPINGS}

Destroy Environment
    Append To File    ${PPS_RESULTS_FILE}    ${pps_mrep},${pps_mnot},${pps_mnot_auth}\n
    Delete All Sessions
    Remove File    ${TOOLS_DIR}/lisp.py*
    Remove File    ${REPLAY_FILE_MREQ}
    Remove File    ${REPLAY_FILE_MREG}
    Remove File    ${REPLAY_FILE_MRGA}

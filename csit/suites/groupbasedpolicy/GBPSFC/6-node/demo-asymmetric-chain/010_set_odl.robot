*** Settings ***
Documentation     Test suite for setting up infrastructure for demo-asymmetric-chain
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           OperatingSystem
Variables         ../../../../../variables/Variables.py
Resource          ../../../../../libraries/Utils.robot
Resource          ../Variables.robot
Resource          ../../../../../libraries/GBP/OpenFlowUtils.robot

*** Test Cases ***
Put Service Functions
    [Documentation]    Register Service Functions to ODL
    ${json_to_edit}    OperatingSystem.Get File    ${SF_FILE}
    ${edited_json}     Replace String    ${json_to_edit}    _SF1    ${GBPSFC3}
    ${edited_json}     Replace String    ${edited_json}    _SF2    ${GBPSFC5}
    ${resp}    RequestsLibrary.Put    session    ${SF_PATH}    ${edited_json}    ${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200

Put Service Function Forwarders
    [Documentation]    Register Service Function Forwarders to ODL
    ${json_to_edit}    OperatingSystem.Get File    ${SFF_FILE}
    ${edited_json}     Replace String    ${json_to_edit}    _SFF1    ${GBPSFC2}
    ${edited_json}     Replace String    ${edited_json}    _SFF2    ${GBPSFC4}
    ${resp}    RequestsLibrary.Put    session    ${SFF_PATH}    ${edited_json}    ${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200

Wait For Manager and Switch Connected on GBPSFC2
    [Documentation]    Making sure that manager is connected for further processing.
    SSHLibrary.Open Connection    ${GBPSFC2}
    Utils.Flexible Mininet Login
    Wait Until Keyword Succeeds  2min  3s  Manager and Switch Connected  sw_name=sw2
    SSHLibrary.Close Connection

Wait For Manager and Switch Connected on GBPSFC4
    [Documentation]    Making sure that manager is connected for further processing.
    SSHLibrary.Open Connection    ${GBPSFC4}
    Utils.Flexible Mininet Login
    Wait Until Keyword Succeeds  2min  3s  Manager and Switch Connected  sw_name=sw4
    SSHLibrary.Close Connection

Put Service Function Chains
    [Documentation]    Register Service Function Chains to ODL
    Add Elements To URI From File    ${SFC_PATH}    ${SFC_ASYMM_FILE}

Put Service Function Paths
    [Documentation]    Register Service Function Paths to ODL
    Add Elements To URI From File    ${SFP_PATH}    ${SFP_ASYMM_FILE}

Put Tunnels
    [Documentation]    Send tunnel augmentation to ODL
    ${json_to_edit}    OperatingSystem.Get File    ${TUNNELS_FILE}
    ${edited_json}     Replace String    ${json_to_edit}    _CLASSIFIER1    ${GBPSFC1}
    ${edited_json}     Replace String    ${edited_json}    _CLASSIFIER2    ${GBPSFC6}
    ${resp}    RequestsLibrary.Put    session    ${TUNNELS_PATH}    ${edited_json}    ${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200

Put Tenant
    [Documentation]    Send Tenant Data to ODL
    Add Elements To URI From File    ${TENANT_PATH}    ${TENANT_ASYMM_FILE}

Register Endpoints
    [Documentation]    Endpoints registration
    @{endpoint_files} =  OperatingSystem.List Files In Directory    ${ENDPOINTS_ASYMM_DIR}    vethl*.*json    absolute
    :FOR    ${endpoint_file}    IN    @{endpoint_files}
    \    Post Elements To URI From File    ${ENDPOINT_REG_PATH}    ${endpoint_file}


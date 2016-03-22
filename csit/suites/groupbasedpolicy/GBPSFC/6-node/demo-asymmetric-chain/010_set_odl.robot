*** Settings ***
Documentation     Test suite for setting up infrastructure for demo-asymmetric-chain
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_YANG_JSON}
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
    ${edited_json}    Replace String    ${json_to_edit}    _SF1    ${GBPSFC3}
    ${edited_json}    Replace String    ${edited_json}    _SF2    ${GBPSFC5}
    Add Elements To URI And Verify    ${SF_PATH}    ${edited_json}    ${HEADERS_YANG_JSON}

Put Service Function Forwarders
    [Documentation]    Register Service Function Forwarders to ODL
    ${json_to_edit}    OperatingSystem.Get File    ${SFF_FILE}
    ${edited_json}    Replace String    ${json_to_edit}    _SFF1    ${GBPSFC2}
    ${edited_json}    Replace String    ${edited_json}    _SFF2    ${GBPSFC4}
    Add Elements To URI And Verify    ${SFF_PATH}    ${edited_json}    ${HEADERS_YANG_JSON}

Wait For Manager and Switch Connected on GBPSFC2
    [Documentation]    Making sure that manager is connected for further processing.
    SSHLibrary.Open Connection    ${GBPSFC2}
    Utils.Flexible Mininet Login
    Wait Until Keyword Succeeds    2min    3s    Manager and Switch Connected    sw_name=sw2
    SSHLibrary.Close Connection

Wait For Manager and Switch Connected on GBPSFC4
    [Documentation]    Making sure that manager is connected for further processing.
    SSHLibrary.Open Connection    ${GBPSFC4}
    Utils.Flexible Mininet Login
    Wait Until Keyword Succeeds    2min    3s    Manager and Switch Connected    sw_name=sw4
    SSHLibrary.Close Connection

Put Service Function Chains
    [Documentation]    Register Service Function Chains to ODL
    Add Elements To URI From File And Verify    ${SFC_PATH}    ${SFC_ASYMM_FILE}    ${HEADERS_YANG_JSON}

Put Service Function Paths
    [Documentation]    Register Service Function Paths to ODL
    Add Elements To URI From File And Verify    ${SFP_PATH}    ${SFP_ASYMM_FILE}    ${HEADERS_YANG_JSON}

Put Tunnels
    [Documentation]    Send tunnel augmentation to ODL
    ${json_to_edit}    OperatingSystem.Get File    ${TUNNELS_FILE}
    ${edited_json}    Replace String    ${json_to_edit}    _CLASSIFIER1    ${GBPSFC1}
    ${edited_json}    Replace String    ${edited_json}    _CLASSIFIER2    ${GBPSFC6}
    Add Elements To URI And Verify    ${TUNNELS_PATH}    ${edited_json}    ${HEADERS_YANG_JSON}

Put Tenant
    [Documentation]    Send Tenant Data to ODL
    Add Elements To URI From File And Verify    ${TENANT_PATH}    ${TENANT_ASYMM_FILE}    ${HEADERS_YANG_JSON}

Register Endpoints
    [Documentation]    Endpoints registration
    @{endpoint_files} =    OperatingSystem.List Files In Directory    ${ENDPOINTS_ASYMM_DIR}    vethl*.*json    absolute
    : FOR    ${endpoint_file}    IN    @{endpoint_files}
    \    Post Elements To URI From File    ${ENDPOINT_REG_PATH}    ${endpoint_file}    ${HEADERS_YANG_JSON}
    ${resp}    RequestsLibrary.Get Request    session    ${ENDPOINTS_OPER_PATH}
    Log    ${resp.content}

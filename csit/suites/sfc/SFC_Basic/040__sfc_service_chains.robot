*** Settings ***
Documentation     Test suite for SFC Service Function Chains, Operates Chains from Restconf APIs.
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Test Setup        Remove All Elements If Exist    ${SERVICE_CHAINS_URI}
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot

*** Test Cases ***
Put Service Function Chains
    [Documentation]    Add Service Function Chains from JSON file
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_CHAINS_FILE}
    ${jsonbody}    To Json    ${body}
    ${chains}    Get From Dictionary    ${jsonbody}    service-function-chains
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CHAINS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${result}    To JSON    ${resp.content}
    ${chain}    Get From Dictionary    ${result}    service-function-chains
    Lists Should be Equal    ${chain}    ${chains}

Delete All Service Function Chains
    [Documentation]    Delete all Service Function Chains
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CHAINS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CHAINS_URI}
    Should Be Equal As Strings    ${resp.status_code}    404

Get one Service Function Chain
    [Documentation]    Get one Service Function Chain
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    ${elements}=    Create List    SFC1    dpi-abstract1    napt44-abstract1    firewall-abstract1
    Check For Elements At URI    ${SERVICE_CHAIN_URI}/SFC1    ${elements}

Get A Non-existing Service Function Chain
    [Documentation]    Get A Non-existing Service Function Chain
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CHAIN_URI}/non-existing-sfc
    Should Be Equal As Strings    ${resp.status_code}    404

Delete A Service Function Chain
    [Documentation]    Delete A Service Function Chain
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CHAIN_URI}/SFC1
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SERVICE_CHAIN_URI}/SFC1
    ${elements}=    Create List    SFC1    dpi-abstract1    napt44-abstract1    firewall-abstract1
    Check For Elements Not At URI    ${SERVICE_CHAINS_URI}    ${elements}

Delete A Non-existing Service Function Chain
    [Documentation]    Delete A Non existing Service Function Chain
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_CHAINS_FILE}
    ${jsonbody}    To Json    ${body}
    ${chains}    Get From Dictionary    ${jsonbody}    service-function-chains
    ${resp}    RequestsLibrary.Delete Request    session    ${SERVICE_CHAIN_URI}/non-existing-sfc
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CHAINS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${result}    To JSON    ${resp.content}
    ${chain}    Get From Dictionary    ${result}    service-function-chains
    Lists Should be Equal    ${chain}    ${chains}

Put one Service Function Chain
    [Documentation]    Put one Service Function Chain
    Add Elements To URI From File    ${SERVICE_CHAIN100_URI}    ${SERVICE_CHAIN100_FILE}
    ${elements}=    Create List    SFC100    dpi-abstract100    napt44-abstract100    firewall-abstract100
    Check For Elements At URI    ${SERVICE_CHAIN100_URI}    ${elements}
    Check For Elements At URI    ${SERVICE_CHAINS_URI}    ${elements}

Get one Service Function From Chain
    [Documentation]    Get one Service Function From Chain
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    ${elements}=    Create List    dpi-abstract1    "order":0    "type":"dpi"
    Check For Elements At URI    ${SERVICE_CHAIN_URI}/SFC1/sfc-service-function/dpi-abstract1    ${elements}

Get A Non-existing Service Function From Chain
    [Documentation]    Get A Non-existing Service Function From Chain
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CHAIN_URI}/SFC1/sfc-service-function/non-existing-sft
    Should Be Equal As Strings    ${resp.status_code}    404

Delete A Service Function From Chain
    [Documentation]    Delete A Service Function From Chain
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    Remove All Elements At URI    ${SERVICE_CHAIN_URI}/SFC1/sfc-service-function/dpi-abstract1
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CHAINS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Contain    ${resp.content}    SFC1
    ${elements}=    Create List    dpi-abstract1    service-function-type:dpi
    Check For Elements Not At URI    ${SERVICE_CHAIN_URI}/SFC1    ${elements}

Delete A Non-existing Service Function From Chain
    [Documentation]    Delete A Non existing Service Function From Chain
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    ${resp}    RequestsLibrary.Delete Request    session    ${SERVICE_CHAIN_URI}/SFC1/sfc-service-function/non-existing-sft
    Should Be Equal As Strings    ${resp.status_code}    404
    ${elements}=    Create List    dpi-abstract1    napt44-abstract1    firewall-abstract1
    Check For Elements At URI    ${SERVICE_CHAIN_URI}/SFC1    ${elements}
    Check For Elements At URI    ${SERVICE_CHAINS_URI}    ${elements}

Put one Service Function into Chain
    [Documentation]    Put one Service Function Chain
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    Add Elements To URI From File    ${SERVICE_CHAIN100_SFIDS_URI}    ${SERVICE_CHAIN100_SFIDS_FILE}
    ${elements}=    Create List    ids-abstract100    "order":3    "type":"ids"
    Check For Elements At URI    ${SERVICE_CHAIN100_SFIDS_URI}    ${elements}
    Check For Elements At URI    ${SERVICE_CHAIN100_URI}    ${elements}
    Check For Elements At URI    ${SERVICE_CHAINS_URI}    ${elements}

*** Keywords ***
Init Suite
    [Documentation]    Initialize session and ODL version specific variables
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}
    Set Suite Variable    ${VERSION_DIR}    master
    Set Suite Variable    ${TEST_DIR}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}
    Set Suite Variable    ${SERVICE_CHAINS_FILE}    ${TEST_DIR}/service-function-chains.json
    Set Suite Variable    ${SERVICE_CHAIN100_URI}    ${SERVICE_CHAIN_URI}/SFC100
    Set Suite Variable    ${SERVICE_CHAIN100_FILE}    ${TEST_DIR}/sfc_chain_100.json
    Set Suite Variable    ${SERVICE_CHAIN100_SFIDS_URI}    ${SERVICE_CHAIN100_URI}/sfc-service-function/ids-abstract100
    Set Suite Variable    ${SERVICE_CHAIN100_SFIDS_FILE}    ${TEST_DIR}/sfc_chain_100_sfids.json

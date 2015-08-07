*** Settings ***
Documentation     Test suite for SFC Service Function Chains, Operates Chains from Restconf APIs.
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${SERVICE_CHAINS_URI}    /restconf/config/service-function-chain:service-function-chains/
${SERVICE_CHAINS_FILE}    ../../../variables/sfc/service-function-chains.json
${SERVICE_CHAIN100_URI}    /restconf/config/service-function-chain:service-function-chains/service-function-chain/SFC100
${SERVICE_CHAIN100_FILE}    ../../../variables/sfc/sfc_chain_100.json
${SERVICE_CHAIN100_SFIDS_URI}    /restconf/config/service-function-chain:service-function-chains/service-function-chain/SFC100/sfc-service-function/ids-abstract100
${SERVICE_CHAIN100_SFIDS_FILE}    ../../../variables/sfc/sfc_chain_100_sfids.json

*** Test Cases ***
Put Service Function Chains
    [Documentation]    Add Service Function Chains from JSON file
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_CHAINS_FILE}
    ${jsonbody}    To Json    ${body}
    ${chains}    Get From Dictionary    ${jsonbody}    service-function-chains
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_CHAINS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${chain}    Get From Dictionary    ${result}    service-function-chains
    Lists Should be Equal    ${chain}    ${chains}

Delete All Service Function Chains
    [Documentation]    Delete all Service Function Chains
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_CHAINS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_CHAINS_URI}
    Should Be Equal As Strings    ${resp.status_code}    404

Get one Service Function Chain
    [Documentation]    Get one Service Function Chain
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    ${elements}=    Create List    SFC1    dpi-abstract1    napt44-abstract1    firewall-abstract1
    Check For Elements At URI    ${SERVICE_CHAINS_URI}service-function-chain/SFC1    ${elements}

Get A Non-existing Service Function Chain
    [Documentation]    Get A Non-existing Service Function Chain
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_CHAINS_URI}service-function-chain/non-existing-sfc
    Should Be Equal As Strings    ${resp.status_code}    404

Delete A Service Function Chain
    [Documentation]    Delete A Service Function Chain
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_CHAINS_URI}service-function-chain/SFC1
    Should Be Equal As Strings    ${resp.status_code}    200
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}service-function-chain/SFC1
    ${elements}=    Create List    SFC1    dpi-abstract1    napt44-abstract1    firewall-abstract1
    Check For Elements Not At URI    ${SERVICE_CHAINS_URI}    ${elements}

Delete A Non-existing Service Function Chain
    [Documentation]    Delete A Non existing Service Function Chain
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_CHAINS_FILE}
    ${jsonbody}    To Json    ${body}
    ${chains}    Get From Dictionary    ${jsonbody}    service-function-chains
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}service-function-chain/non-existing-sfc
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_CHAINS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${chain}    Get From Dictionary    ${result}    service-function-chains
    Lists Should be Equal    ${chain}    ${chains}

Put one Service Function Chain
    [Documentation]    Put one Service Function Chain
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Add Elements To URI From File    ${SERVICE_CHAIN100_URI}    ${SERVICE_CHAIN100_FILE}
    ${elements}=    Create List    SFC100    dpi-abstract100    napt44-abstract100    firewall-abstract100
    Check For Elements At URI    ${SERVICE_CHAIN100_URI}    ${elements}
    Check For Elements At URI    ${SERVICE_CHAINS_URI}    ${elements}

Get one Service Function From Chain
    [Documentation]    Get one Service Function From Chain
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    ${elements}=    Create List    dpi-abstract1    "order":0    service-function-type:dpi
    Check For Elements At URI    ${SERVICE_CHAINS_URI}service-function-chain/SFC1/sfc-service-function/dpi-abstract1    ${elements}

Get A Non-existing Service Function From Chain
    [Documentation]    Get A Non-existing Service Function From Chain
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_CHAINS_URI}service-function-chain/SFC1/sfc-service-function/non-existing-sft
    Should Be Equal As Strings    ${resp.status_code}    404

Delete A Service Function From Chain
    [Documentation]    Delete A Service Function From Chain
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}service-function-chain/SFC1/sfc-service-function/dpi-abstract1
    ${resp}    RequestsLibrary.Get    session    ${SERVICE_CHAINS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    SFC1
    ${elements}=    Create List    dpi-abstract1    service-function-type:dpi
    Check For Elements Not At URI    ${SERVICE_CHAINS_URI}service-function-chain/SFC1/    ${elements}

Delete A Non-existing Service Function From Chain
    [Documentation]    Delete A Non existing Service Function From Chain
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}service-function-chain/SFC1/sfc-service-function/non-existing-sft
    ${elements}=    Create List    dpi-abstract1    napt44-abstract1    firewall-abstract1
    Check For Elements At URI    ${SERVICE_CHAINS_URI}service-function-chain/SFC1    ${elements}
    Check For Elements At URI    ${SERVICE_CHAINS_URI}    ${elements}

Put one Service Function into Chain
    [Documentation]    Put one Service Function Chain
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    Add Elements To URI From File    ${SERVICE_CHAIN100_SFIDS_URI}    ${SERVICE_CHAIN100_SFIDS_FILE}
    ${elements}=    Create List    ids-abstract100    "order":3    service-function-type:ids
    Check For Elements At URI    ${SERVICE_CHAIN100_SFIDS_URI}    ${elements}
    Check For Elements At URI    ${SERVICE_CHAIN100_URI}    ${elements}
    Check For Elements At URI    ${SERVICE_CHAINS_URI}    ${elements}

Clean All Service Function Chains After Tests
    [Documentation]    Delete all Service Function Chains From Datastore After Tests
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}

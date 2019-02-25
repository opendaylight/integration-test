*** Settings ***
Documentation     Test Suite for IdManager
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}    timeout=5
Suite Teardown    Delete All Sessions
Test Setup        Genius Test Setup
Test Teardown     Get Model Dump    ${ODL_SYSTEM_IP}    ${idmanager_data_models}
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           Collections
Library           re
Variables         ../../variables/genius/Modules.py
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/Genius.robot
Resource          ../../variables/Variables.robot

*** Variables ***
${genius_config_dir}    ${CURDIR}/../../variables/genius
${pool-name}      test-pool
@{test_keys}      test-key1    test-key2    test-key3
${create_json}    createIdpool.json
${allocaterange_json}    allocateIdRange.json
${OPERATIONS_API}    /restconf/operations

*** Test Cases ***
Create ID pool in range 10:20
    [Documentation]    This testcase creates Id pool in range 10 to 20.
    Utils.Post Elements To URI From File    ${OPERATIONS_API}/id-manager:createIdPool    ${genius_config_dir}/${create_json}
    @{poolrange} =    BuiltIn.Create list    ${pool-name}    10    20
    Utils.Check For Elements At URI    ${CONFIG_API}/id-manager:id-pools/id-pool/${pool-name}/    ${poolrange}
    @{availiable_pool} =    BuiltIn.Create list    10    20    10
    Utils.Check For Elements At URI    ${CONFIG_API}/id-manager:id-pools/id-pool/${pool-name}/available-ids-holder/    ${availiable_pool}

Allocate Ids from pool created within size as 5
    [Documentation]    This testcase allocated IDs of specified size for the pool created in 1st testcase.
    ${body} =    OperatingSystem.Get File    ${genius_config_dir}/${allocaterange_json}
    ${body} =    String.Replace string    ${body}    test-key    ${test_keys[0]}
    BuiltIn.Log    ${body}
    Utils.Post Elements To URI    ${OPERATIONS_API}/id-manager:allocateIdRange    ${body}
    get Id pool

Neg_Allocate ids of size 10 from the same pool
    [Documentation]    This is a Negative testcase where when trying to allocate Id range out of the availiable IDs we have, the IDs are not allocated.
    ${pool-name} =    BuiltIn.Set Variable    test-pool
    ${body} =    OperatingSystem.Get File    ${genius_config_dir}/${allocaterange_json}
    ${body} =    String.Replace String    ${body}    5    6
    ${body} =    String.Replace String    ${body}    test-key    ${test_keys[1]}
    BuiltIn.Log    ${body}
    ${resp} =    RequestsLibrary.Post Request    session    ${OPERATIONS_API}/id-manager:allocateIdRange    data=${body}
    BuiltIn.Log Variables    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    500

Allocate IDs of size 3 from the pool
    [Documentation]    This testcase allocates 3 Ids from the created pool in test case 1
    ${body}=    OperatingSystem.Get File    ${genius_config_dir}/${allocaterange_json}
    ${body} =    String.Replace string    ${body}    test-key    ${test_keys[2]}
    ${body} =    String.Replace string    ${body}    5    3
    BuiltIn.Log    ${body}
    Utils.Post Elements To URI    ${OPERATIONS_API}/id-manager:allocateIdRange    ${body}
    ${get_resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/id-manager:id-pools/id-pool/${pool-name}/available-ids-holder/
    ${respjson} =    RequestsLibrary.To Json    ${get_resp.content}    pretty_print=True
    BuiltIn.Log    ${respjson}
    BuiltIn.Should Contain    ${get_resp.content}    17
    BuiltIn.Should Be Equal As Strings    ${get_resp.status_code}    200

Release a block of IDs allocated using releaseIds RPC
    [Documentation]    This testcase Releases the block of Ids by using the key which is sent in json.
    ${body} =    OperatingSystem.Get File    ${genius_config_dir}/releaseIds.json
    BuiltIn.Log    ${body}
    ${body} =    String.Replace String    ${body}    test-key    ${test_keys[2]}
    Utils.Post Elements To URI    ${OPERATIONS_API}/id-manager:releaseId    ${body}
    ${get_resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/id-manager:id-pools/id-pool/${pool-name}/
    ${respjson} =    RequestsLibrary.To Json    ${get_resp.content}    pretty_print=True
    BuiltIn.Log    ${respjson}
    BuiltIn.Should Be Equal As Strings    ${get_resp.status_code}    200
    ${child-pool-name} =    BuiltIn.Should Match Regexp    ${get_resp.content}    ${pool-name}\.[-]?[0-9]+
    BuiltIn.Log    ${child-pool-name}
    ${get_releasedIds} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/id-manager:id-pools/id-pool/${child-pool-name}/released-ids-holder/
    ${respjson} =    RequestsLibrary.To Json    ${get_releasedIds.content}    pretty_print=True
    BuiltIn.Log    ${respjson}
    Should Be Equal As Strings    ${get_releasedIds.status_code}    200
    @{released_ids} =    re.Findall    <id>[0-9]+    ${get_releasedIds.content}
    BuiltIn.Log    ${released_ids}

Delete the ID Pool using deleteIdPool RPC
    [Documentation]    This testcase deletes the ID pool craeted in the 1st testcase.
    ${body} =    OperatingSystem.Get File    ${genius_config_dir}/deleteIdPool.json
    ${body} =    String.Replace String    ${body}    poolname    ${pool-name}
    BuiltIn.Log    ${body}
    Utils.Post Elements To URI    ${OPERATIONS_API}/id-manager:deleteIdPool    ${body}
    Utils.No Content From URI    session    ${CONFIG_API}/id-manager:id-pools/id-pool/${pool-name}/

*** Keywords ***
get Id pool
    [Documentation]    This keyword checks the created ID pool by doing GET.
    ${get_resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/id-manager:id-pools/id-pool/${pool-name}/available-ids-holder/
    ${respjson} =    RequestsLibrary.To Json    ${get_resp.content}    pretty_print=True
    BuiltIn.Log    ${respjson}
    BuiltIn.Should Contain    ${get_resp.content}    14
    BuiltIn.Should Be Equal As Strings    ${get_resp.status_code}    200

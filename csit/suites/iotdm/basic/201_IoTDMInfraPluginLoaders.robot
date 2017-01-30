*** Settings ***
Documentation     Test suite testing plugin loaders implemented in IoTDM.
...               Test cases are testing the BundleLoader and KarafFeatureLoader RPCs.
Suite Setup       Start
Suite Teardown    Finish
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Library           ../../../libraries/criotdm.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/SubStrings.robot

*** Variables ***
${VAR_BASE}       ${CURDIR}/../../../variables/IoTDM/

*** Test Cases ***
1.00 Bundle loader instance has no bundles loaded
    [Documentation]    Check weather there are any BundleLoader instance
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/runningConfig/empty    mapping={'WORKSPACE': '${WORKSPACE}'}    verify=True
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/startupConfig/empty    mapping={'WORKSPACE': '${WORKSPACE}'}    verify=True

1.01 Load new bundle using bundle loader
    [Documentation]    Load bundle using bundle loader and verify it is loaded
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/load_plugin1    mapping={'WORKSPACE': '${WORKSPACE}'}
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/runningConfig/one_plugin
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/runningConfig/one_plugin    mapping={'WORKSPACE': '${WORKSPACE}'}    verify=True
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/startupConfig/one_plugin    mapping={'WORKSPACE': '${WORKSPACE}'}    verify=True

1.02 Fail to load same bundle using new feature name
    [Documentation]    Load same bundle using bundle loader using new feature name should fail with bundle already exist
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/load_plugin2/post_data.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    default    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Bundle already loaded!

1.03 Update feature with different plugin
    [Documentation]    Load new bundle using bundle loader on same feature-name, verify it is updated and old one is
    ...    not uploaded any more
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/update_plugin1    mapping={'WORKSPACE': '${WORKSPACE}'}
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/runningConfig/one_plugin/updated
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/runningConfig/one_plugin/updated    mapping={'WORKSPACE': '${WORKSPACE}'}    verify=True
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/startupConfig/one_plugin/updated    mapping={'WORKSPACE': '${WORKSPACE}'}    verify=True

1.04 Load second bundle using bundle loader
    [Documentation]    Load second bundle using bundle loader and verify it is loaded
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/load_plugin2    mapping={'WORKSPACE': '${WORKSPACE}'}
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/runningConfig/two_plugin
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/runningConfig/two_plugin    mapping={'WORKSPACE': '${WORKSPACE}'}    verify=True
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/startupConfig/two_plugin    mapping={'WORKSPACE': '${WORKSPACE}'}    verify=True

1.05 Try to update feature to already existing plugin
    [Documentation]    Updating feature to already loaded plugins should fail with bundle already exist
    #${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/load_plugin1/post_data.json
    #${body} =    Replace Variables    ${body}
    #${response} =    RequestsLibrary.Post Request    default    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    #${status_code} =    Status Code    ${response}
    #Should Be Equal As Integers    ${status_code}    500
    #Should Contain    ${response.content}    Bundle already loaded!
    #todo test is fine but IoTDM is not. This will cause that NewFeature1 will dissapear of running config
    TODO

2.00 Reload
    [Documentation]    Reload all plugins and verify they are still there
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/reload/one    mapping={'WORKSPACE': '${WORKSPACE}'}
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/runningConfig/two_plugin    backward
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/runningConfig/two_plugin    mapping={'WORKSPACE': '${WORKSPACE}'}    verify=True
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/startupConfig/two_plugin    mapping={'WORKSPACE': '${WORKSPACE}'}    verify=True
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/reload/two    mapping={'WORKSPACE': '${WORKSPACE}'}
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/runningConfig/two_plugin
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/runningConfig/two_plugin    mapping={'WORKSPACE': '${WORKSPACE}'}    verify=True
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/startupConfig/two_plugin    mapping={'WORKSPACE': '${WORKSPACE}'}    verify=True

3.00 Remove single plugin
    [Documentation]    Remove single feature and verify it is gone
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/remove    mapping={'WORKSPACE': '${WORKSPACE}'}
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/runningConfig/one_plugin/updated    backward
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/runningConfig/one_plugin/updated    mapping={'WORKSPACE': '${WORKSPACE}'}    verify=True
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/startupConfig/one_plugin/updated    mapping={'WORKSPACE': '${WORKSPACE}'}    verify=True

3.01 Clear all plugins loaded using specific instance
    [Documentation]    Load back removed feature verify and try to remove plugins on the specific instance and verify
    ...    they are all gone
    #TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/load_plugin2
    #todo uncomment. Test is fine IoTDM is not. Bug https://bugs.opendaylight.org/show_bug.cgi?id=7709
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/clean    mapping={'WORKSPACE': '${WORKSPACE}'}
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/runningConfig/empty    mapping={'WORKSPACE': '${WORKSPACE}'}    verify=True
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/pluginLoader/startupConfig/empty    mapping={'WORKSPACE': '${WORKSPACE}'}    verify=True

4.00 Test multiple cases of missing configuration loading new plugin
    [Documentation]    Try to load plugin using data that are missing some of the configuration
    #${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/missing_data/create/feature_name.json
    #${response} =    RequestsLibrary.Post Request    default    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    #${status_code} =    Status Code    ${response}
    #Should Be Equal As Integers    ${status_code}    500
    #Should Contain    ${response.content}    smthg
    #todo uncomment. Test is fine IoTDM is not. Bug https://bugs.opendaylight.org/show_bug.cgi?id=7711
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/missing_data/create/bundle_instance.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    default    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader instance name not specified.
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/missing_data/create/bundles_load.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    default    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Failed to load bundle: null

4.01 Test multiple cases of invalid values loading new plugin
    [Documentation]    Try to load plugin using data that not valid and therefore request shoud fail
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/invalid_data/create/bundle_instance.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    default    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader does not exist.
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/invalid_data/create/jar_location.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    default    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Error converting plugin
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/invalid_data/create/priority.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    default    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    400
    Should Contain    ${response.content}    Incorrect lexical representation of integer value
    #${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/invalid_data/create/riority_same.json
    #${response} =    RequestsLibrary.Post Request    default    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    #${status_code} =    Status Code    ${response}
    #Should Be Equal As Integers    ${status_code}    500
    #Should Contain    ${response.content}    smthg
    #todo uncomment. Test is fine IoTDM is not. Bug https://bugs.opendaylight.org/show_bug.cgi?id=7713

4.02 Test removing feature wit missing data
    [Documentation]    Try to remove plugin using data that are missing some of the configuration
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/missing_data/remove/bundle_instance.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    default    restconf/operations/iotdmbundleloader:feature-remove/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader instance name not specified.
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/missing_data/remove/feature_name.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    default    restconf/operations/iotdmbundleloader:feature-remove/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Feature: null not found

4.03 Test removing feature using invalid value
    [Documentation]    Try to remove plugin using data that not valid and therefore request shoud fail
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/invalid_data/remove/bundle_instance.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    default    restconf/operations/iotdmbundleloader:feature-remove/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader: BundleLoader does not exist.
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/invalid_data/remove/feature_name.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    default    restconf/operations/iotdmbundleloader:feature-remove/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Feature: NewFeature5 not found

4.04 Test removing all feature with missing bundle loader instance
    [Documentation]    Try to remove all plugins using data that are missing some of the configuration
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/missing_data/clean/bundle_instance.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    default    restconf/operations/iotdmbundleloader:clean/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader instance name not specified.

4.05 Test removing all feature using invalid bundle loader instance
    [Documentation]    Try to remove all plugins using data that not valid and therefore request shoud fail
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/invalid_data/clean/bundle_instance.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    default    restconf/operations/iotdmbundleloader:clean/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader: BundleLoader does not exist.

4.06 Test reloading feature with missing data
    [Documentation]    Try to reload plugin using data that are missing some of the configuration
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/missing_data/remove/bundle_instance.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    default    restconf/operations/iotdmbundleloader:feature-reload/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader instance name not specified.
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/missing_data/remove/feature_name.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    default    restconf/operations/iotdmbundleloader:feature-reload/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader: BundleLoaderInstanceDefault Feature null is not loaded

4.07 Test reloading feature using invalid value
    [Documentation]    Try to reload plugin using data that not valid and therefore request shoud fail
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/invalid_data/remove/bundle_instance.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    default    restconf/operations/iotdmbundleloader:feature-reload/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader: BundleLoader does not exist.
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/invalid_data/remove/feature_name.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    default    restconf/operations/iotdmbundleloader:feature-reload/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader: BundleLoaderInstanceDefault Feature NewFeature5 is not loaded

*** Keywords ***
TODO
    Fail    "Not implemented"

Start
    Create Session    default    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    ${headers} =    Create Dictionary    Content-Type=application/json    Authorization=Basic YWRtaW46YWRtaW4=
    Set Suite Variable    ${headers}
    @{files} =    OperatingSystem.List Files In Directory    ${VAR_BASE}/pluginLoader    *.json
    : FOR    ${file}    IN    @{files}
    \    Log    ${file}

Finish
    Delete All Sessions
    OperatingSystem.Remove File    ${VAR_BASE}/pluginLoader/runningConfig/one_plugin/response.json
    OperatingSystem.Remove File    ${VAR_BASE}/pluginLoader/runningConfig/two_plugin/response.json
    OperatingSystem.Remove File    ${VAR_BASE}/pluginLoader/runningConfig/one_plugin/updated/response.json

Set Variables Reload One
    [Arguments]    ${id}    ${path}
   ${hh} =    Set Variable    one
    Log    ${hh}
    ${ID1} =    Set Variable    ${id-2}
    ${ID2} =    Set Variable    ${id-3}
    ${ID3} =    Set Variable    ${id}
    ${ID4} =    Set Variable    ${id-1}
    ${text} =    OperatingSystem.Get File    ${path}/response_template.json
    ${text} =    Replace Variables    ${text}
    OperatingSystem.Create File    ${path}/response.json    ${text}

Set Variables Default
    [Arguments]    ${id}    ${path}
    ${hh} =    Set Variable    default
    Log    ${hh}
    ${ID1} =    Set Variable    ${id}
    ${ID2} =    Set Variable    ${id-1}
    ${ID3} =    Set Variable    ${id-2}
    ${ID4} =    Set Variable    ${id-3}
    ${text} =    OperatingSystem.Get File    ${path}/response_template.json
    ${text} =    Replace Variables    ${text}
    OperatingSystem.Create File    ${path}/response.json    ${text}

Get Plugin Id And Create Response
    [Arguments]    ${path}    ${reload}=${EMPTY}
    [Documentation]    Get plugin id out of karaf.log file and create response out of response_template
    ${output}=    Run Command On Controller    ${ODL_SYSTEM_IP}    grep 'bundleId' ${WORKSPACE}/${BUNDLEFOLDER}/data/log/karaf.log | tail -1   user=${ODL_SYSTEM_USER}    password=${ODL_SYSTEM_PASSWORD}    prompt=${ODL_SYSTEM_PROMPT}
    ${id} =    Get Id    ${output}
    ${id_integer} =    Convert To Integer    ${id}
    Run Keyword If    '${reload}'=='backward'    Set Variables Reload One    ${id_integer}    ${path}
    ...    ELSE    Set Variables Default    ${id_integer}    ${path}

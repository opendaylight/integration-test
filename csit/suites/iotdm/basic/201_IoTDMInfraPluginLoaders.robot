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
Resource          ../../../libraries/KarafKeywords.robot

*** Variables ***
${VAR_BASE}       ${CURDIR}/../../../variables/IoTDM/

*** Test Cases ***
1.00 Bundle loader instance has no features loaded
    [Documentation]    Check weather there are any BundleLoader instance
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/runningConfig/empty    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1    True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/startupConfig/empty    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1    True

1.01 Bundle loader loads new feature
    [Documentation]    Load bundle using bundle loader and verify it is loaded
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/load_plugin1    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/jar/runningConfig/one_plugin
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/runningConfig/one_plugin    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1    True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/startupConfig/one_plugin    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1    True

1.02 Bundle loader fails to load same feature using new feature name
    [Documentation]    Load same bundle using bundle loader using new feature name should fail with bundle already exist
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/load_plugin2/post_data.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Bundle already loaded!

1.03 Bundle loader updates feature with different feature
    [Documentation]    Load new bundle using bundle loader on same feature-name, verify it is updated and old one is
    ...    not uploaded any more
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/update_plugin1    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/jar/runningConfig/one_plugin/updated
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/runningConfig/one_plugin/updated    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1    True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/startupConfig/one_plugin/updated    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1    True

1.04 Bundle loader loads second feature
    [Documentation]    Load second bundle using bundle loader and verify it is loaded
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/load_plugin2    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/jar/runningConfig/two_plugin    test
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/runningConfig/two_plugin    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1    True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/startupConfig/two_plugin    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1    True

1.05 Bundle loader tries to update feature to already existing feature
    [Documentation]    Updating feature to already loaded plugins should fail with bundle already exist
    #${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/load_plugin1/post_data.json
    #${body} =    Replace Variables    ${body}
    #${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    #${status_code} =    Status Code    ${response}
    #Should Be Equal As Integers    ${status_code}    500
    #Should Contain    ${response.content}    Bundle already loaded!
    #todo test is fine but IoTDM is not. This will cause that NewFeature1 will dissapear of running config
    TODO

2.00 Bundle loader reloads both features
    [Documentation]    Reload all plugins, verify they are still there and check if ids of bundles are changed
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/reload/one    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/jar/runningConfig/two_plugin    newTest
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/runningConfig/two_plugin    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1    True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/startupConfig/two_plugin    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1    True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/reload/two    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/jar/runningConfig/two_plugin    test
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/runningConfig/two_plugin    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1    True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/startupConfig/two_plugin    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1    True

3.00 Bundle loader removes single feature
    [Documentation]    Remove single feature and verify it is gone
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/remove    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/jar/runningConfig/one_plugin/updated    test
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/runningConfig/one_plugin/updated    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1    True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/startupConfig/one_plugin/updated    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1    True

3.01 Bundle loader clears all features loaded using specific instance
    [Documentation]    Load back removed feature verify and try to remove plugins on the specific instance and verify
    ...    they are all gone
    #TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/load_plugin2
    #todo uncomment. Test is fine IoTDM is not. Bug https://bugs.opendaylight.org/show_bug.cgi?id=7709
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/clean    {'WORKSPACE': '${WORKSPACE}'}    session=ClusterManagement__session_1
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/runningConfig/empty    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1    True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/startupConfig/empty    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1    True

4.00 Bundle loader tests multiple cases of missing configuration loading new feature
    [Documentation]    Try to load plugin using data that are missing some of the configuration
    #${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/missing_data/create/feature_name.json
    #${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    #${status_code} =    Status Code    ${response}
    #Should Be Equal As Integers    ${status_code}    500
    #Should Contain    ${response.content}    smthg
    #todo uncomment. Test is fine IoTDM is not. Bug https://bugs.opendaylight.org/show_bug.cgi?id=7711
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/missing_data/create/bundle_instance.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader instance name not specified.
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/missing_data/create/bundles_load.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Failed to load bundle: null

4.01 Bundle loader tests multiple cases of invalid values loading new feature
    [Documentation]    Try to load plugin using data that not valid and therefore request shoud fail
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/invalid_data/create/bundle_instance.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader does not exist.
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/invalid_data/create/jar_location.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Error converting plugin
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/invalid_data/create/priority.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    400
    Should Contain    ${response.content}    Incorrect lexical representation of integer value
    #${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/invalid_data/create/riority_same.json
    #${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    #${status_code} =    Status Code    ${response}
    #Should Be Equal As Integers    ${status_code}    500
    #Should Contain    ${response.content}    smthg
    #todo uncomment. Test is fine IoTDM is not. Bug https://bugs.opendaylight.org/show_bug.cgi?id=7713

4.02 Bundle loader tests removing feature wit missing data
    [Documentation]    Try to remove plugin using data that are missing some of the configuration
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/missing_data/remove/bundle_instance.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-remove/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader instance name not specified.
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/missing_data/remove/feature_name.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-remove/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Feature: null not found

4.03 Bundle loader tests removing feature using invalid value
    [Documentation]    Try to remove plugin using data that not valid and therefore request shoud fail
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/invalid_data/remove/bundle_instance.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-remove/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader: BundleLoader does not exist.
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/invalid_data/remove/feature_name.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-remove/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Feature: NewFeature5 not found

4.04 Bundle loader test removing all features without bundle loader instance name specified
    [Documentation]    Try to remove all plugins using data that are missing some of the configuration
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/missing_data/clean/bundle_instance.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:clean/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader instance name not specified.

4.05 Bundle loader test removing all features without bundle loader instance name specified
    [Documentation]    Try to remove all plugins using data that not valid and therefore request shoud fail
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/invalid_data/clean/bundle_instance.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:clean/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader: BundleLoader does not exist.

4.06 Bundle loader tests reloading feature with missing data
    [Documentation]    Try to reload plugin using data that are missing some of the configuration
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/missing_data/remove/bundle_instance.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-reload/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader instance name not specified.
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/missing_data/remove/feature_name.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-reload/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader: BundleLoaderInstanceDefault Feature null is not loaded

4.07 Bundle loader tests reloading feature using invalid value
    [Documentation]    Try to reload plugin using data that not valid and therefore request shoud fail
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/invalid_data/remove/bundle_instance.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-reload/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader: BundleLoader does not exist.
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/invalid_data/remove/feature_name.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-reload/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader: BundleLoaderInstanceDefault Feature NewFeature5 is not loaded

4.08 Bundle loader tests loading a feature with missing function
    [Documentation]    Tries to load feature with missing function from Onem2mPluginManager class. It is expecting to
    ...    have doSomething function
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/put_invalid/post_data.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain All Sub Strings    ${response.content}    Caused by: java.lang.NoSuchMethodError: org.opendaylight.iotdm.onem2m.plugins.Onem2mPluginManager.doSomehting()    Installation of feature: NewFeature1 failed with error:

5.00 Bundle loader instance has no features loaded
    [Documentation]    Check weather there are any BundleLoader instance
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/runningConfig/empty    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1    True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/startupConfig/empty    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1    True

6.00 Karaf loader instance has no features loaded
    [Documentation]    Check weather there are any BundleLoader instance
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/list/empty    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1    True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/list_startup/empty    {'WORKSPACE': '${WORKSPACE}'}    ClusterManagement__session_1    True

*** Keywords ***
TODO
    Fail    "Not implemented"

Start
    KarafKeywords.Setup Karaf Keywords
    Create Session    ClusterManagement__session_1    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    ${headers} =    Create Dictionary    Content-Type=application/json    Authorization=Basic YWRtaW46YWRtaW4=
    Set Suite Variable    ${headers}
    ${ID1_OLD} =    Set Variable    0
    ${ID2_OLD} =    Set Variable    0
    ${ID3_OLD} =    Set Variable    0
    ${ID4_OLD} =    Set Variable    0
    Set Suite Variable    ${ID1_OLD}
    Set Suite Variable    ${ID2_OLD}
    Set Suite Variable    ${ID3_OLD}
    Set Suite Variable    ${ID4_OLD}

Finish
    Delete All Sessions
    OperatingSystem.Remove File    ${VAR_BASE}/pluginLoader/jar/runningConfig/one_plugin/response.json
    OperatingSystem.Remove File    ${VAR_BASE}/pluginLoader/jar/runningConfig/two_plugin/response.json
    OperatingSystem.Remove File    ${VAR_BASE}/pluginLoader/jar/runningConfig/one_plugin/updated/response.json

Check And Set Test
    [Arguments]    ${ID1}    ${ID2}
    Should Not Be Equal    ${ID1}    ${ID1_OLD}
    Should Not Be Equal    ${ID2}    ${ID2_OLD}
    Set Suite Variable    ${ID1_OLD}    ${ID1}
    Set Suite Variable    ${ID2_OLD}    ${ID2}

Check And Set Newtest
    [Arguments]    ${ID3}    ${ID4}
    Should Not Be Equal    ${ID3}    ${ID3_OLD}
    Should Not Be Equal    ${ID4}    ${ID4_OLD}
    Set Suite Variable    ${ID3_OLD}    ${ID3}
    Set Suite Variable    ${ID4_OLD}    ${ID4}

Get Plugin Id And Create Response
    [Arguments]    ${path}    ${bundle}=${EMPTY}
    [Documentation]    Get plugin id out of karaf.log file and create response out of response_template
    ${ID1} =    KarafKeywords.Execute Controller Karaf Command On Background    bundle:list |grep "onem2mitplugin1-impl"
    ${ID2} =    KarafKeywords.Execute Controller Karaf Command On Background    bundle:list |grep "onem2mitplugin1-api"
    ${ID3} =    KarafKeywords.Execute Controller Karaf Command On Background    bundle:list |grep "onem2mitplugin2-impl"
    ${ID4} =    KarafKeywords.Execute Controller Karaf Command On Background    bundle:list |grep "onem2mitplugin2-api"
    ${ID1} =    Get Id    ${ID1}
    ${ID2} =    Get Id    ${ID2}
    ${ID3} =    Get Id    ${ID3}
    ${ID4} =    Get Id    ${ID4}
    ${text} =    OperatingSystem.Get File    ${path}/response_template.json
    ${text} =    Replace Variables    ${text}
    OperatingSystem.Create File    ${path}/response.json    ${text}
    Run Keyword If    '${bundle}'=='test'    Check And Set Test    ${ID1}    ${ID2}
    ...    ELSE IF    '${bundle}'=='newTest'    Check And Set Newtest    ${ID3}    ${ID4}
    ...    ELSE    Run Keywords    Check And Set Test    ${ID1}    ${ID2}
    ...    AND    Check And Set Newtest    ${ID3}    ${ID4}

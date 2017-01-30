*** Settings ***
Documentation     Test suite testing plugin loaders implemented in IoTDM.
...               Test cases are testing the BundleLoader and KarafFeatureLoader RPCs.
Suite Setup       Start
Suite Teardown    Finish
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Common.py
Library           ../../../libraries/criotdm.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/SubStrings.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/NexusKeywords.robot

*** Variables ***
${VAR_BASE}       ${CURDIR}/../../../variables/IoTDM/

*** Test Cases ***
1.00 Bundle loader instance has no features loaded
    [Documentation]    Check weather there are any BundleLoader instances
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/runningConfig/empty    session=ClusterManagement__session_1    verify=True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/startupConfig/empty    session=ClusterManagement__session_1    verify=True

1.01 Bundle loader loads new feature
    [Documentation]    Load bundle using bundle loader and verify it is loaded
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/load_plugin    {'FEATURE': 'NewFeature1', 'PWD': '${PWD}', 'FILENAMEIMPL': '${filename_impl}', 'FILENAMEAPI': '${filename_api}'}    ClusterManagement__session_1
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/jar/runningConfig/one_plugin
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/runningConfig/one_plugin    session=ClusterManagement__session_1    verify=True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/startupConfig/one_plugin    {'FEATURE': 'NewFeature1', 'PWD': '${PWD}', 'FILENAMEIMPL': '${filename_impl}', 'FILENAMEAPI': '${filename_api}'}    ClusterManagement__session_1    True

1.02 Bundle loader fails to load same feature using new feature name
    [Documentation]    Load same bundle using bundle loader using new feature name should fail with bundle already exist
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/load_plugin/post_data.json
    Set Local Variables Bundle    NewFeature2    ${filename_api}    ${filename_impl}
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Bundle already loaded!

1.03 Bundle loader update feature should fail
    [Documentation]    Load new bundle using bundle loader on same feature-name, and verify weather it failed
    TODO
    #todo delete TODO after fix. It will update and it should not. It will mess up other tests.
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/load_plugin/post_data.json
    Set Local Variables Bundle    NewFeature1    ${filename_api2}    ${filename_impl2}
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Feature NewFeature is already available. Cannot continue with installation

1.04 Bundle loader loads second feature
    [Documentation]    Load second bundle using bundle loader and verify it is loaded
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/load_plugin    {'FEATURE': 'NewFeature2', 'PWD': '${PWD}', 'FILENAMEIMPL': '${filename_impl2}', 'FILENAMEAPI': '${filename_api2}'}    ClusterManagement__session_1
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/jar/runningConfig/two_plugin    Itplugin2
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/runningConfig/two_plugin    session=ClusterManagement__session_1    verify=True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/startupConfig/two_plugin    {'FEATURE': 'NewFeature1', 'FEATURE2': 'NewFeature2', 'PWD': '${PWD}', 'FILENAMEIMPL': '${filename_impl}', 'FILENAMEAPI': '${filename_api}', 'FILENAMEIMPL2': '${filename_impl2}', 'FILENAMEAPI2': '${filename_api2}'}    ClusterManagement__session_1    True

1.05 Bundle loader tries to update feature to already existing feature
    [Documentation]    Updating feature to already loaded plugins should fail with bundle already exist
    TODO
    #todo test is fine but IoTDM is not. This will cause that NewFeature1 will dissapear of running config
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/load_plugin/post_data.json
    Set Local Variables Bundle    NewFeature1    ${filename_api2}    ${filename_impl2}
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Bundle already loaded!

2.00 Bundle loader reloads both features
    [Documentation]    Reload all plugins, verify they are still there and check if ids of bundles are changed
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/reload    {'FEATURE': 'NewFeature1'}    ClusterManagement__session_1
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/jar/runningConfig/two_plugin    Itplugin1
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/runningConfig/two_plugin    session=ClusterManagement__session_1    verify=True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/startupConfig/two_plugin    {'FEATURE': 'NewFeature1', 'FEATURE2': 'NewFeature2', 'PWD': '${PWD}', 'FILENAMEIMPL': '${filename_impl}', 'FILENAMEAPI': '${filename_api}', 'FILENAMEIMPL2': '${filename_impl2}', 'FILENAMEAPI2': '${filename_api2}'}    ClusterManagement__session_1    True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/reload    {'FEATURE': 'NewFeature2'}    ClusterManagement__session_1
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/jar/runningConfig/two_plugin    Itplugin2
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/runningConfig/two_plugin    session=ClusterManagement__session_1    verify=True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/startupConfig/two_plugin    {'FEATURE': 'NewFeature1', 'FEATURE2': 'NewFeature2', 'PWD': '${PWD}', 'FILENAMEIMPL': '${filename_impl}', 'FILENAMEAPI': '${filename_api}', 'FILENAMEIMPL2': '${filename_impl2}', 'FILENAMEAPI2': '${filename_api2}'}    ClusterManagement__session_1    True

3.00 Bundle loader removes single feature
    [Documentation]    Remove single feature and verify it is gone
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/remove    session=ClusterManagement__session_1
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/jar/runningConfig/one_plugin    Itplugin2
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/runningConfig/one_plugin    session=ClusterManagement__session_1    verify=True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/startupConfig/one_plugin    {'FEATURE': 'NewFeature1', 'PWD': '${PWD}', 'FILENAMEIMPL': '${filename_impl}', 'FILENAMEAPI': '${filename_api}'}    ClusterManagement__session_1    True

3.02 Bundle loader clears all features loaded using specific instance
    [Documentation]    Load back removed feature verify and try to remove plugins on the specific instance and verify
    ...    they are all gone
    #TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/load_plugin    {'FEATURE': 'NewFeature2', 'PWD': '${PWD}', 'FILENAMEIMPL': '${filename_impl2}', 'FILENAMEAPI': '${filename_api2}'}
    #...    ClusterManagement__session_1
    #todo uncomment. Test is fine IoTDM is not. Bug https://bugs.opendaylight.org/show_bug.cgi?id=7709
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/clean    session=ClusterManagement__session_1
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/runningConfig/empty    session=ClusterManagement__session_1    verify=True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/startupConfig/empty    session=ClusterManagement__session_1    verify=True

4.00 Bundle loader tests multiple cases of missing configuration loading new feature
    [Documentation]    Try to load plugin using data that are missing some of the configuration
    Set Local Variables Bundle    filename_api=${filename_api}    filename_impl=${filename_impl}
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
    Set Local Variables Bundle    filename_api=${filename_api}    filename_impl=${filename_impl}
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
    Should Contain    ${response.content}    Failed to load bundle: file://${PWD}/Fail
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
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/missing_data/remove_reload/bundle_instance.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-remove/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader instance name not specified.
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/missing_data/remove_reload/feature_name.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-remove/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Feature: null not found

4.03 Bundle loader tests removing feature using invalid value
    [Documentation]    Try to remove plugin using data that not valid and therefore request shoud fail
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/invalid_data/remove_reload/bundle_instance.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-remove/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader: BundleLoader does not exist.
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/invalid_data/remove_reload/feature_name.json
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
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/missing_data/remove_reload/bundle_instance.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-reload/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader instance name not specified.
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/missing_data/remove_reload/feature_name.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-reload/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader: BundleLoaderInstanceDefault Feature null is not loaded

4.07 Bundle loader tests reloading feature using invalid value
    [Documentation]    Try to reload plugin using data that not valid and therefore request shoud fail
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/invalid_data/remove_reload/bundle_instance.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-reload/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader: BundleLoader does not exist.
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/invalid_data/remove_reload/feature_name.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-reload/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    BundleLoader: BundleLoaderInstanceDefault Feature NewFeature5 is not loaded

4.08 Bundle loader tests loading a feature with missing function
    [Documentation]    Tries to load feature with missing function from Onem2mPluginManager class. It is expecting to
    ...    have doSomething function
    Set Local Variables Bundle    NewFeature1    ${filename_impl_invalid}    ${filename_api_invalid}
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/jar/load_plugin/post_data.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    restconf/operations/iotdmbundleloader:feature-put/    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain All Sub Strings    ${response.content}    ErrorMessage: BundleLoader: BundleLoaderInstanceDefault, Feature: NewFeature1, Failed to start bundle:    RuntimeException: Exception throws for purposes of testing of negative scenarios

5.00 Bundle loader loads feature, and verify weather it is registered using registerPluginHttp
    [Documentation]    Load second bundle using bundle loader and verify it is loaded. Also is should third. Verify plugin
    ...    manager registration and communications channels
    TODO
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/load_plugin    {'FEATURE': 'NewFeature3', 'PWD': '${PWD}', 'FILENAMEIMPL': 'itiotdmplugin-impl-0.1.0-SNAPSHOT.jar', 'FILENAMEAPI': 'itiotdmplugin-api-0.1.0-SNAPSHOT.jar'}    ClusterManagement__session_1
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/registrations    session=ClusterManagement__session_1    verify=True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/http    session=ClusterManagement__session_1    verify=True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/clean    session=ClusterManagement__session_1

6.00 Bundle loader instance has no features loaded
    [Documentation]    Check weather there are any BundleLoader instance
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/runningConfig/empty    session=ClusterManagement__session_1    verify=True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/jar/startupConfig/empty    session=ClusterManagement__session_1    verify=True

7.00 Karaf loader instance has no features loaded
    [Documentation]    Check weather there are any KarafLoader instances
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/list/empty    session=ClusterManagement__session_1    verify=True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/list_startup/empty/init_empty    session=ClusterManagement__session_1    verify=True
    Karaf Feature And Repository Should Not Exist    odl-itplugin1    odl-itplugin2    odl-itplugininvalid1

7.01 Karaf loader loads new feature
    [Documentation]    Load feature using karaf loader and verify it is loaded
    Set Local Variables Kar    kar=${kar_filename}
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/install    {'PWD': '${PWD}', 'FEATURE': 'odl-itplugin1', 'KAR':'${kar_filename}'}    ClusterManagement__session_1
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/kar/list/one_feature    Itplugin1
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/list/one_feature    {'PWD': '${PWD}', 'FEATURE': 'odl-itplugin1', 'KAR':'${kar_filename}'}    ClusterManagement__session_1    True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/list_startup/one_feature    {'PWD': '${PWD}', 'FEATURE': 'odl-itplugin1', 'KAR':'${kar_filename}'}    ClusterManagement__session_1    True
    Karaf Feature And Repository Should Not Exist    odl-itplugin2    odl-itplugininvalid1
    Karaf Feature And Repository Should Exist    odl-itplugin1

7.02 Karaf loader fails to load same feature using new feature name
    [Documentation]    Load same feature using karaf loader using new feature name should fail with bundle already exist
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/kar/install/post_data.json
    ${FEATURE} =    Set Variable    odl-itplugin2
    ${KAR} =    Set Variable    itplugin1-features-0.1.0-SNAPSHOT.kar
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    /restconf/operations/iotdmkaraffeatureloader:archive-install    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Archive with name itplugin1-features-0.1.0-SNAPSHOT already installed
    Karaf Feature And Repository Should Not Exist    odl-itplugin2    odl-itplugininvalid1
    Karaf Feature And Repository Should Exist    odl-itplugin1

7.03 Karaf loader fails to update feature with different feature
    [Documentation]    Load new feature using karaf loader on same feature-name, and fail
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/kar/install/post_data.json
    ${FEATURE} =    Set Variable    odl-itplugin1
    ${KAR} =    Set Variable    itplugin2-features-0.1.0-SNAPSHOT.kar
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    /restconf/operations/iotdmkaraffeatureloader:archive-install    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Feature odl-itplugin1 is already available. Cannot continue with installation
    Karaf Feature And Repository Should Not Exist    odl-itplugin2    odl-itplugininvalid1
    Karaf Feature And Repository Should Exist    odl-itplugin1

7.04 Bundle loader loads second feature
    [Documentation]    Load second feature using karaf loader and verify it is loaded
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/install    {'PWD': '${PWD}', 'FEATURE': 'odl-itplugin2', 'KAR':'${kar_filename2}'}    ClusterManagement__session_1
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/kar/list/two_features    Itplugin2
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/list/two_features    {'PWD': '${PWD}', 'FEATURE': 'odl-itplugin1', 'KAR':'${kar_filename}'}    ClusterManagement__session_1    True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/list_startup/two_features    {'PWD': '${PWD}', 'FEATURE': 'odl-itplugin1', 'KAR':'${kar_filename}'}    ClusterManagement__session_1    True
    Karaf Feature And Repository Should Not Exist    odl-itplugininvalid1
    Karaf Feature And Repository Should Exist    odl-itplugin1    odl-itplugin2

8.00 Karaf loader reloads both features
    [Documentation]    Reload all features, verify they are still there and check if ids of features are changed
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/reload    {'FEATURE': '${kar_filename[:-4]}'}    ClusterManagement__session_1
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/reload    {'FEATURE': '${kar_filename2[:-4]}'}    ClusterManagement__session_1
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/kar/list/two_features
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/list/two_features    {'PWD': '${PWD}', 'FEATURE': 'odl-itplugin1'}    ClusterManagement__session_1    True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/list_startup/two_features    {'PWD': '${PWD}', 'FEATURE': 'odl-itplugin1'}    ClusterManagement__session_1    True
    Karaf Feature And Repository Should Not Exist    odl-itplugininvalid1
    Karaf Feature And Repository Should Exist    odl-itplugin1    odl-itplugin2

9.00 Karaf loader removes single feature
    [Documentation]    Remove single feature and verify it is gone
    Set Local Variables Kar    kar=${kar_filename}
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/remove    session=ClusterManagement__session_1
    Get Plugin Id And Create Response    ${VAR_BASE}/pluginLoader/kar/list/one_feature    Itplugin2
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/list/one_feature    session=ClusterManagement__session_1    verify=True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/list_startup/one_feature    {'PWD': '${PWD}', 'FEATURE': 'odl-itplugin1', 'KAR':'${kar_filename}'}    ClusterManagement__session_1    True
    Karaf Feature And Repository Should Not Exist    odl-itplugininvalid1    odl-itplugin2
    Karaf Feature And Repository Should Exist    odl-itplugin1

9.01 Karaf loader clears all features loaded using specific instance
    [Documentation]    Load back removed feature verify and try to remove features on the specific instance and verify
    ...    they are all gone
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/install    {'PWD': '${PWD}', 'FEATURE': 'odl-itplugin2', 'KAR':'${kar_filename2}'}    ClusterManagement__session_1
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/clean    session=ClusterManagement__session_1
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/list/empty    session=ClusterManagement__session_1    verify=True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/list_startup/empty    session=ClusterManagement__session_1    verify=True
    Karaf Feature And Repository Should Not Exist    odl-itplugininvalid1    odl-itplugin2    odl-itplugin1

10.00 Karaf loader tests multiple cases of missing configuration loading new feature
    [Documentation]    Try to load plugin using data that are missing some of the configuration
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/kar/missing_data/create/bundles_load.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    /restconf/operations/iotdmkaraffeatureloader:archive-install    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Mandatory input not provided
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/kar/missing_data/create/loader_name.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    /restconf/operations/iotdmkaraffeatureloader:archive-install    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Smtg
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/kar/missing_data/create/url.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    /restconf/operations/iotdmkaraffeatureloader:archive-install    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Smtg
    Karaf Feature And Repository Should Not Exist    odl-itplugininvalid1    odl-itplugin2    odl-itplugin1

10.01 Karaf loader tests multiple cases of invalid values loading new feature
    [Documentation]    Try to load plugin using data that are not valid and therefore request shoud fail
    Set Local Variables Kar    odl-itplugin2    ${kar_filename2}
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/kar/invalid_data/create/loader_name.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    /restconf/operations/iotdmkaraffeatureloader:archive-install    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    KarafFeatureLoader: KarafFeatureLoader does not exist.
    Set Local Variables Kar    odl-itplugin1    Fail
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/kar/invalid_data/create/kar_location.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    /restconf/operations/iotdmkaraffeatureloader:archive-install    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    archive must end with .kar suffix
    Set Local Variables Kar    odl-itplugin1    Fail.kar
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/kar/invalid_data/create/kar_location.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    /restconf/operations/iotdmkaraffeatureloader:archive-install    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    (No such file or directory)
    Set Local Variables Kar    odl-itplugin1    ${kar_filename2}
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/kar/invalid_data/create/kar_location.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    /restconf/operations/iotdmkaraffeatureloader:archive-install    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    itplugin2-features-0.1.0-SNAPSHOT.kar does not provide feature odl-itplugin1
    Karaf Feature And Repository Should Not Exist    odl-itplugininvalid1    odl-itplugin2    odl-itplugin1

10.02 Karaf loader tests removing feature wit missing data
    [Documentation]    Try to remove plugin using data that are missing some of the configuration
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/kar/missing_data/remove_reload/loader_name.json
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    /restconf/operations/iotdmkaraffeatureloader:archive-uninstall    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Smtg
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/kar/missing_data/remove_reload/feature_name.json
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    /restconf/operations/iotdmkaraffeatureloader:archive-uninstall    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Smtg
    Karaf Feature And Repository Should Not Exist    odl-itplugininvalid1    odl-itplugin2    odl-itplugin1

10.03 Karaf loader tests removing feature using invalid value
    [Documentation]    Try to remove plugin using data that not valid and therefore request shoud fail
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/kar/invalid_data/remove_reload/loader_name.json
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    /restconf/operations/iotdmkaraffeatureloader:archive-uninstall    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    KarafFeatureLoader: KarafFeatureLoader does not exist.
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/kar/invalid_data/remove_reload/feature_name.json
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    /restconf/operations/iotdmkaraffeatureloader:archive-uninstall    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Archive itplugin1-features-0.1.0-SNAPSHOT does not exist
    Karaf Feature And Repository Should Not Exist    odl-itplugininvalid1    odl-itplugin2    odl-itplugin1

10.04 Karaf loader test removing all features without karaf feature loader name specified
    [Documentation]    Try to remove all plugins using data that are missing some of the configuration
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/kar/missing_data/clean/loader_name.json
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    /restconf/operations/iotdmkaraffeatureloader:clean    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Smtg
    Karaf Feature And Repository Should Not Exist    odl-itplugininvalid1    odl-itplugin2    odl-itplugin1

10.05 Karaf loader test removing all features without karaf feature loader name specified
    [Documentation]    Try to remove all plugins using data that not valid and therefore request shoud fail
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/kar/invalid_data/clean/loader_name.json
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    /restconf/operations/iotdmkaraffeatureloader:clean    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    KarafFeatureLoader: KarafFeatureLoader does not exist.
    Karaf Feature And Repository Should Not Exist    odl-itplugininvalid1    odl-itplugin2    odl-itplugin1

10.06 Karaf loader tests reloading feature with missing data
    [Documentation]    Try to reload plugin using data that are missing some of the configuration
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/kar/missing_data/remove_reload/loader_name.json
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    /restconf/operations/iotdmkaraffeatureloader:archive-reload    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Smtg
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/kar/missing_data/remove_reload/feature_name.json
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    /restconf/operations/iotdmkaraffeatureloader:archive-reload    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Smtg
    Karaf Feature And Repository Should Not Exist    odl-itplugininvalid1    odl-itplugin2    odl-itplugin1

10.07 Karaf loader tests reloading feature using invalid value
    [Documentation]    Try to reload plugin using data that not valid and therefore request shoud fail
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/kar/invalid_data/remove_reload/loader_name.json
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    /restconf/operations/iotdmkaraffeatureloader:archive-reload    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    KarafFeatureLoader: KarafFeatureLoader does not exist.
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/kar/invalid_data/remove_reload/feature_name.json
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    /restconf/operations/iotdmkaraffeatureloader:archive-reload    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${response.content}    Archive itplugin1-features-0.1.0-SNAPSHOT does not exist
    Karaf Feature And Repository Should Not Exist    odl-itplugininvalid1    odl-itplugin2    odl-itplugin1

10.08 Bundle loader tests loading a feature with missing function
    [Documentation]    Tries to load feature with missing function from Onem2mPluginManager class. It is expecting to
    ...    have doSomething function
    Set Local Variables Kar    odl-itplugininvalid1    ${kar_filename_invalid}
    ${body} =    OperatingSystem.Get File    ${VAR_BASE}/pluginLoader/kar/install/post_data.json
    ${body} =    Replace Variables    ${body}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    /restconf/operations/iotdmkaraffeatureloader:archive-install    data=${body}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain All Sub Strings    ${response.content}    ErrorMessage: BundleLoader: BundleLoaderInstanceDefault, Feature: odl-itplugininvalid1, Failed to start bundle:    RuntimeException: Exception throws for purposes of testing of negative scenarios
    Karaf Feature And Repository Should Not Exist    odl-itplugininvalid1    odl-itplugin2    odl-itplugin1

11.00 Karaf loader instance has no features loaded
    [Documentation]    Check weather there are any KarafLoader instances
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/list/empty    session=ClusterManagement__session_1    verify=True
    TemplatedRequests.Post_As_Json_Templated    ${VAR_BASE}/pluginLoader/kar/list_startup/empty    session=ClusterManagement__session_1    verify=True
    Karaf Feature And Repository Should Not Exist    odl-itplugininvalid1    odl-itplugin2    odl-itplugin1

*** Keywords ***
TODO
    Fail    "Not implemented"

Start
    KarafKeywords.Setup Karaf Keywords
    Create Session    ClusterManagement__session_1    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    ${headers} =    Create Dictionary    Content-Type=application/json    Authorization=Basic YWRtaW46YWRtaW4=
    Set Suite Variable    ${headers}
    Set Suite Variable    ${ID1_OLD}    0
    Set Suite Variable    ${ID2_OLD}    0
    Set Suite Variable    ${ID3_OLD}    0
    Set Suite Variable    ${ID4_OLD}    0
    SSHKeywords.Open_Connection_To_ODL_System
    ${PWD} =    SSHLibrary.Execute_Command    pwd
    #${file_name} =    NexusKeywords.Deploy_Test_Tool    itplugin1    onem2m-core    -> should download from nexus needed jar or kar file which will
    #be situated in ${PWD}/${file_name}.    NexusKeywords.Deploy_Test_Tool return name of the file.
    Set Suite Variable    ${PWD}
    Set Suite Variable    ${kar_filename}    itplugin1-features-0.1.0-SNAPSHOT.kar
    Set Suite Variable    ${kar_filename2}    itplugin2-features-0.1.0-SNAPSHOT.kar
    Set Suite Variable    ${kar_filename_invalid}    itplugininvalid1-features-0.1.0-SNAPSHOT.kar
    Set Suite Variable    ${filename_impl}    itplugin1-impl-0.1.0-SNAPSHOT.jar
    Set Suite Variable    ${filename_api}    itplugin1-api-0.1.0-SNAPSHOT.jar
    Set Suite Variable    ${filename_impl2}    itplugin2-impl-0.1.0-SNAPSHOT.jar
    Set Suite Variable    ${filename_api2}    itplugin2-api-0.1.0-SNAPSHOT.jar
    Set Suite Variable    ${filename_impl_invalid}    itplugininvalid1-impl-0.1.0-SNAPSHOT.jar
    Set Suite Variable    ${filename_api_invalid}    itplugininvalid1-api-0.1.0-SNAPSHOT.jar

Finish
    Delete All Sessions
    OperatingSystem.Remove File    ${VAR_BASE}/pluginLoader/jar/runningConfig/one_plugin/response.json
    OperatingSystem.Remove File    ${VAR_BASE}/pluginLoader/jar/runningConfig/two_plugin/response.json
    OperatingSystem.Remove File    ${VAR_BASE}/pluginLoader/kar/list/one_feature/response.json
    OperatingSystem.Remove File    ${VAR_BASE}/pluginLoader/kar/list/two_features/response.json

Set Local Variables Bundle
    [Arguments]    ${feature}=${EMPTY}    ${filename_api}=${EMPTY}    ${filename_impl}=${EMPTY}
    ${FEATURE} =    Set Test Variable    ${feature}
    ${FILENAMEAPI} =    Set Test Variable    ${filename_api}
    ${FILENAMEIMPL} =    Set Test Variable    ${filename_impl}

Set Local Variables Kar
    [Arguments]    ${feature}=${EMPTY}    ${kar}=${EMPTY}
    ${FEATURE} =    Set Test Variable    ${feature}
    ${KAR} =    Set Test Variable    ${kar}

Check And Set Itplugin1
    [Arguments]    ${ID1}    ${ID2}
    Should Not Be Equal    ${ID1}    ${ID1_OLD}
    Should Not Be Equal    ${ID2}    ${ID2_OLD}
    Set Suite Variable    ${ID1_OLD}    ${ID1}
    Set Suite Variable    ${ID2_OLD}    ${ID2}

Check And Set Itplugin2
    [Arguments]    ${ID3}    ${ID4}
    Should Not Be Equal    ${ID3}    ${ID3_OLD}
    Should Not Be Equal    ${ID4}    ${ID4_OLD}
    Set Suite Variable    ${ID3_OLD}    ${ID3}
    Set Suite Variable    ${ID4_OLD}    ${ID4}

Get Plugin Id And Create Response
    [Arguments]    ${path}    ${bundle}=${EMPTY}
    [Documentation]    Get plugin id out of karaf.log file and create response out of response_template
    ${ID1} =    KarafKeywords.Execute Controller Karaf Command On Background    bundle:list | grep "itplugin1-impl"
    ${ID2} =    KarafKeywords.Execute Controller Karaf Command On Background    bundle:list | grep "itplugin1-api"
    ${ID3} =    KarafKeywords.Execute Controller Karaf Command On Background    bundle:list | grep "itplugin2-impl"
    ${ID4} =    KarafKeywords.Execute Controller Karaf Command On Background    bundle:list | grep "itplugin2-api"
    ${ID1} =    Get Id    ${ID1}
    ${ID2} =    Get Id    ${ID2}
    ${ID3} =    Get Id    ${ID3}
    ${ID4} =    Get Id    ${ID4}
    ${text} =    OperatingSystem.Get File    ${path}/response_template.json
    ${text} =    Replace Variables    ${text}
    Log    ${text}
    OperatingSystem.Create File    ${path}/response.json    ${text}
    Run Keyword If    '${bundle}'=='Itplugin1'    Check And Set Itplugin1    ${ID1}    ${ID2}
    ...    ELSE IF    '${bundle}'=='Itplugin2'    Check And Set Itplugin2    ${ID3}    ${ID4}
    ...    ELSE    Run Keywords    Check And Set Itplugin1    ${ID1}    ${ID2}
    ...    AND    Check And Set Itplugin2    ${ID3}    ${ID4}

Karaf Feature And Repository Should Exist
    [Arguments]    @{repos_features}
    [Documentation]    Checks weather @{repos_features} are existing in karaf repo-list and feature-list
    : FOR    ${repo}    IN    @{repos_features}
    \    ${return} =    KarafKeywords.Execute Controller Karaf Command On Background    repo-list | grep "${repo}"
    \    Log    ${return}
    \    Should Contain    ${return}    ${repo}
    : FOR    ${feature}    IN    @{repos_features}
    \    ${return} =    KarafKeywords.Execute Controller Karaf Command On Background    feature:list | grep "${feature}"
    \    Log    ${return}
    \    Should Contain    ${return}    ${feature}

Karaf Feature And Repository Should Not Exist
    [Arguments]    @{repos_features}
    [Documentation]    Checks weather @{repos_features} are not existing in karaf repo-list and feature-list
    : FOR    ${repo}    IN    @{repos_features}
    \    ${return} =    KarafKeywords.Execute Controller Karaf Command On Background    repo-list | grep "${repo}"
    \    Log    ${return}
    \    Should Not Contain    ${return}    ${repo}
    : FOR    ${feature}    IN    @{repos_features}
    \    ${return} =    KarafKeywords.Execute Controller Karaf Command On Background    feature:list | grep "${feature}"
    \    Log    ${return}
    \    Should Not Contain    ${return}    ${feature}

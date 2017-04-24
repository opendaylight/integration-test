*** Settings ***
Documentation     Test suite testing plugin loaders implemented in IoTDM.
...               Test cases are testing the BundleLoader and KarafFeatureLoader RPCs.
...               Suite uses valid and invalid testing plugins from IoTDM repository from iotdm/itcsitdist/iotdmitresources
...               Invalid plugin means that there is some intentional issue in the implementation of the plugin which
...               causes failure during plugin loading process and it should be catched by BundleLoader or KarafFeatureLoader
...               and such plugin must not be loaded to system as well as nothing from its dependencies.
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Common.py
Library           ../../../libraries/IoTDM/criotdm.py
Variables         ../../../variables/Variables.py

*** Test Cases ***
1.00 Bundle loader instance has no features loaded
    [Documentation]    Check weather there are any BundleLoader instances
    [Tags]    not-implemented    exclude
    TODO

1.01 Bundle loader loads new feature
    [Documentation]    Load bundle using bundle loader and verify it is loaded
    [Tags]    not-implemented    exclude
    TODO

1.02 Bundle loader fails to load same feature using new feature name
    [Documentation]    Load same bundle using bundle loader using new feature name should fail with bundle already exist
    [Tags]    not-implemented    exclude
    TODO

1.03 Bundle loader update feature should fail
    [Documentation]    Load new bundle using bundle loader on same feature-name, and verify weather it failed
    [Tags]    not-implemented    exclude
    TODO

1.04 Bundle loader loads second feature
    [Documentation]    Load second bundle using bundle loader and verify it is loaded
    [Tags]    not-implemented    exclude
    TODO

1.05 Bundle loader tries to update feature to already existing feature
    [Documentation]    Updating feature to already loaded plugins should fail with bundle already exist
    [Tags]    not-implemented    exclude
    TODO

2.00 Bundle loader reloads both features
    [Documentation]    Reload all plugins, verify they are still there and check if ids of bundles are changed
    [Tags]    not-implemented    exclude
    TODO

3.00 Bundle loader removes single feature
    [Documentation]    Remove single feature and verify it is gone
    [Tags]    not-implemented    exclude
    TODO

3.02 Bundle loader clears all features loaded using specific instance
    [Documentation]    Load back removed feature verify and try to remove plugins on the specific instance and verify
    ...    they are all gone
    [Tags]    not-implemented    exclude
    TODO

4.00 Bundle loader tests multiple cases of missing configuration loading new feature
    [Documentation]    Try to load plugin using data that are missing some of the configuration
    [Tags]    not-implemented    exclude
    TODO

4.01 Bundle loader tests multiple cases of invalid values loading new feature
    [Documentation]    Try to load plugin using data that not valid and therefore request shoud fail
    [Tags]    not-implemented    exclude
    TODO

4.02 Bundle loader tests removing feature wit missing data
    [Documentation]    Try to remove plugin using data that are missing some of the configuration
    [Tags]    not-implemented    exclude
    TODO

4.03 Bundle loader tests removing feature using invalid value
    [Documentation]    Try to remove plugin using data that not valid and therefore request shoud fail
    [Tags]    not-implemented    exclude
    TODO

4.04 Bundle loader test removing all features without bundle loader instance name specified
    [Documentation]    Try to remove all plugins using data that are missing some of the configuration
    [Tags]    not-implemented    exclude
    TODO

4.05 Bundle loader test removing all features without bundle loader instance name specified
    [Documentation]    Try to remove all plugins using data that not valid and therefore request shoud fail
    [Tags]    not-implemented    exclude
    TODO

4.06 Bundle loader tests reloading feature with missing data
    [Documentation]    Try to reload plugin using data that are missing some of the configuration
    [Tags]    not-implemented    exclude
    TODO

4.07 Bundle loader tests reloading feature using invalid value
    [Documentation]    Try to reload plugin using data that not valid and therefore request shoud fail
    [Tags]    not-implemented    exclude
    TODO

4.08 Bundle loader tests loading a feature with missing function
    [Documentation]    Tries to load feature with missing function from Onem2mPluginManager class. It is expecting to
    ...    have doSomething function
    [Tags]    not-implemented    exclude
    TODO

5.00 Bundle loader loads feature, and verify weather it is registered using registerPluginHttp
    [Documentation]    Load second bundle using bundle loader and verify it is loaded. Also is should third. Verify plugin
    ...    manager registration and communications channels
    [Tags]    not-implemented    exclude
    TODO

6.00 Bundle loader instance has no features loaded
    [Documentation]    Check weather there are any BundleLoader instance
    [Tags]    not-implemented    exclude
    TODO

7.00 Karaf loader instance has no features loaded
    [Documentation]    Check weather there are any KarafLoader instances
    [Tags]    not-implemented    exclude
    TODO

7.01 Karaf loader loads new feature
    [Documentation]    Load feature using karaf loader and verify it is loaded
    [Tags]    not-implemented    exclude
    TODO

7.02 Karaf loader fails to load same feature using new feature name
    [Documentation]    Load same feature using karaf loader using new feature name should fail with bundle already exist
    [Tags]    not-implemented    exclude
    TODO

7.03 Karaf loader fails to update feature with different feature
    [Documentation]    Load new feature using karaf loader on same feature-name, and fail
    [Tags]    not-implemented    exclude
    TODO

7.04 Bundle loader loads second feature
    [Documentation]    Load second feature using karaf loader and verify it is loaded
    [Tags]    not-implemented    exclude
    TODO

8.00 Karaf loader reloads both features
    [Documentation]    Reload all features, verify they are still there and check if ids of features are changed
    [Tags]    not-implemented    exclude
    TODO

9.00 Karaf loader removes single feature
    [Documentation]    Remove single feature and verify it is gone
    [Tags]    not-implemented    exclude
    TODO

9.01 Karaf loader clears all features loaded using specific instance
    [Documentation]    Load back removed feature verify and try to remove features on the specific instance and verify
    ...    they are all gone
    [Tags]    not-implemented    exclude
    TODO

10.00 Karaf loader tests multiple cases of missing configuration loading new feature
    [Documentation]    Try to load plugin using data that are missing some of the configuration
    [Tags]    not-implemented    exclude
    TODO

10.01 Karaf loader tests multiple cases of invalid values loading new feature
    [Documentation]    Try to load plugin using data that are not valid and therefore request shoud fail
    [Tags]    not-implemented    exclude
    TODO

10.02 Karaf loader tests removing feature wit missing data
    [Documentation]    Try to remove plugin using data that are missing some of the configuration
    [Tags]    not-implemented    exclude
    TODO

10.03 Karaf loader tests removing feature using invalid value
    [Documentation]    Try to remove plugin using data that not valid and therefore request shoud fail
    [Tags]    not-implemented    exclude
    TODO

10.04 Karaf loader test removing all features without karaf feature loader name specified
    [Documentation]    Try to remove all plugins using data that are missing some of the configuration
    [Tags]    not-implemented    exclude
    TODO

10.05 Karaf loader test removing all features without karaf feature loader name specified
    [Documentation]    Try to remove all plugins using data that not valid and therefore request shoud fail
    [Tags]    not-implemented    exclude
    TODO

10.06 Karaf loader tests reloading feature with missing data
    [Documentation]    Try to reload plugin using data that are missing some of the configuration
    [Tags]    not-implemented    exclude
    TODO

10.07 Karaf loader tests reloading feature using invalid value
    [Documentation]    Try to reload plugin using data that not valid and therefore request shoud fail
    [Tags]    not-implemented    exclude
    TODO

10.08 Bundle loader tests loading a feature with missing function
    [Documentation]    Tries to load feature with missing function from Onem2mPluginManager class. It is expecting to
    ...    have doSomething function
    [Tags]    not-implemented    exclude
    TODO

11.00 Karaf loader instance has no features loaded
    [Documentation]    Check weather there are any KarafLoader instances
    [Tags]    not-implemented    exclude
    TODO

*** Keywords ***
TODO
    Fail    "Not implemented"

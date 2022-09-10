*** Settings ***
Documentation       Test suite testing IoTDM PluginManager RPC calls registrations of default plugins and
...                 communication channels and re-configuration of port of registered plugins

Resource            ../../../variables/Variables.robot
Resource            ../../../libraries/ClusterManagement.robot
Resource            ../../../libraries/TemplatedRequests.robot

Suite Setup         Setup Suite
Suite Teardown      Teardown Suite


*** Variables ***
${VAR_BASE}             ${CURDIR}/../../../variables/IoTDM/
# TODO 500 seems to be a bug in ODL, remove when solved
@{NEGATIVE_RESULTS}     ${500}    ${400}


*** Test Cases ***
1.00 Default result of onem2m-plugin-manager-plugin-data RPC
    [Documentation]    Verifies the result of RPC and looks for data items related to:
    ...    HTTP, CoAP, MQTT, WS and Onem2mExample
    BuiltIn.Wait_Until_Keyword_Succeeds    15 sec    1 sec    Verify Default PluginData Output

1.01 Plugin data of HTTP - filtered
    [Documentation]    Verifies all plugin data about HTTP provider module plugin
    Verify RPC Plugin Data    http/filtered

1.02 Plugin data of CoAP - filtered
    [Documentation]    Verifies all plugin data about CoAP provider module plugin
    Verify RPC Plugin Data    coap/filtered

1.03 Plugin data of MQTT - filtered
    [Documentation]    Verifies all plugin data about MQTT provider module plugin
    Verify RPC Plugin Data    mqtt/filtered

1.04 Plugin data of WS - filtered
    [Documentation]    Verifies all plugin data about WS provider module plugin
    Verify RPC Plugin Data    ws/filtered

1.05 Plugin data of Onem2mExample - filtered
    [Documentation]    Verifies all plugin data about Onem2mExample provider module plugin
    Verify RPC Plugin Data    onem2m_example/filtered

1.06 Plugin data of TSDR - filtered
    [Documentation]    Verifies all plugin data about Onem2mExample provider module plugin
    Verify RPC Plugin Data    tsdr/filtered

1.07 Plugin data of SimpleAdapter - filtered
    [Documentation]    Verifies all plugin data about Onem2mExample provider module plugin
    Verify RPC Plugin Data    simple_adapter/filtered

2.00.01 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC - HTTP
    [Documentation]    Verifies if the result of the RPC contains correct data about HTTP
    Verify RPC Plugin Registrations    http/default

2.00.02 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC - CoAP
    [Documentation]    Verifies if the result of the RPC contains correct data about CoAP
    Verify RPC Plugin Registrations    coap/default

2.00.03 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC - MQTT
    [Documentation]    Verifies if the result of the RPC contains correct data about MQTT
    Verify RPC Plugin Registrations    mqtt/default

2.00.04 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC - WS
    [Documentation]    Verifies if the result of the RPC contains correct data about ws
    Verify RPC Plugin Registrations    ws/default

2.00.05 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC - Onem2mExample
    [Documentation]    Verifies if the result of the RPC contains correct data about Onem2mExample
    Verify RPC Plugin Registrations    onem2m_example/default

2.01.01 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC filtered - HTTP
    [Documentation]    Verifies if the result of the RPC with input filter contains correct data about HTTP only
    Verify RPC Plugin Registrations    http/filtered

2.01.02 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC filtered - CoAP
    [Documentation]    Verifies if the result of the RPC with input filter contains correct data about CoAP only
    Verify RPC Plugin Registrations    coap/filtered

2.01.03 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC filtered - MQTT
    [Documentation]    Verifies if the result of the RPC with input filter contains correct data about MQTT only
    Verify RPC Plugin Registrations    mqtt/filtered

2.01.04 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC filtered - WS
    [Documentation]    Verifies if the result of the RPC with input filter contains correct data about WS only
    Verify RPC Plugin Registrations    ws/filtered

2.01.05 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC filtered - Onem2mExample
    [Documentation]    Verifies if the result of the RPC with input filter contains correct data about Onem2mExample only
    Verify RPC Plugin Registrations    onem2m_example/filtered

3.00.01 Default result of onem2m-plugin-manager-db-api-client-registrations RPC - Onem2mExample
    [Documentation]    Verifies the result of RPC and looks for Onem2mExample registration
    Verify RPC Db Registrations    onem2m_example/filtered

3.00.02 Default result of onem2m-plugin-manager-db-api-client-registrations RPC - TSDR
    [Documentation]    Verifies the result of RPC and looks for TSDR registration
    Verify RPC Db Registrations    tsdr/default

3.00.03 Default result of onem2m-plugin-manager-db-api-client-registrations RPC - SimpleAdapter
    [Documentation]    Verifies the result of RPC and looks for SimpleAdapter registration
    Verify RPC Db Registrations    simple_adapter/default

3.01.00 Default result of onem2m-plugin-manager-db-api-client-registrations RPC - filtered Onem2mExample
    [Documentation]    Verifies result of RPC with input filter for Onem2mExample
    Verify RPC Db Registrations    onem2m_example/filtered

3.01.01 Default result of onem2m-plugin-manager-db-api-client-registrations RPC - filtered TSDR
    [Documentation]    Verifies result of RPC with input filter for TSDR
    Verify RPC Db Registrations    tsdr/filtered

3.01.02 Default result of onem2m-plugin-manager-db-api-client-registrations RPC - filtered SimpleAdapter
    [Documentation]    Verifies result of RPC with input filter for SimpleAdapter
    Verify RPC Db Registrations    simple_adapter/filtered

4.00.01 Default result of onem2m-plugin-manager-simple-config-client-registrations RPC - Onem2mExample
    [Documentation]    Verifies the result of RPC and looks for Onem2mExample registration
    Verify RPC Positive    simple_config_registrations/default

4.00.02 Default result of onem2m-plugin-manager-simple-config-client-registrations RPC - filtered Onem2mExample
    [Documentation]    Verifies the result of RPC with input filter and looks for Onem2mExample registration only
    Verify RPC Positive    simple_config_registrations/filtered

5.00.01 Default Communication channel for HTTP plugin
    [Documentation]    Verifies the default instance of HTTP communication channel for HTTP provider
    Verify RPC Comm Channels    http/default

5.00.02 Default Communication channel for CoAP plugin
    [Documentation]    Verifies the default instance of CoAP communication channel for CoAP provider
    Verify RPC Comm Channels    coap/default

5.00.03 Default Communication channel for MQTT plugin
    [Documentation]    Verifies the default instance of MQTT communication channel for MQTT provider
    Verify RPC Comm Channels    mqtt/default

5.00.04 Default Communication channel for WS plugin
    [Documentation]    Verifies the default instance of WS communication channel for WS provider
    Verify RPC Comm Channels    ws/default

5.00.05 Default Communication channel for Onem2mExample plugin
    [Documentation]    Verifies the default instance of HTTP communication channel for Onem2mExample plugin
    Verify RPC Comm Channels    onem2m_example/default

5.01.01 Default Communication channel for HTTP plugin - filtered
    [Documentation]    Verifies the default instances of HTTP communication channel for HTTP provider using RPC with input filter
    Verify RPC Comm Channels    http/filtered

5.01.02 Default Communication channel for CoAP plugin - filtered
    [Documentation]    Verifies the default instance of CoAP communication channel for CoAP provider using RPC with input filter
    Verify RPC Comm Channels    coap/filtered

5.01.03 Default Communication channel for MQTT plugin - filtered
    [Documentation]    Verifies the default instance of MQTT communication channel for MQTT provider using RPC with input filter
    Verify RPC Comm Channels    mqtt/filtered

5.01.04 Default Communication channel for WS plugin - filtered
    [Documentation]    Verifies the default instance of WS communication channel for WS provider using RPC with input filter
    Verify RPC Comm Channels    ws/filtered

5.01.05 Default Communication channel for Onem2mExample plugin - filtered
    [Documentation]    Verifies the default instance of HTTP communication channel for Onem2mExample plugin using RPC with input filter
    Verify RPC Comm Channels    onem2m_example/filtered

6.00.01 Change port number of HTTP provider plugin
    [Documentation]    Configures new port number for HTTP provider module and verifies
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/put_http/change_port    verify=True
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_BASE}/get_http    verify=True
    Verify PluginData After Reconfiguration of HTTP

6.00.02 Check HTTP communication using new port
    [Documentation]    Sends GET request to the new port and verifies if it is possible to use the new configured port
    ...    for HTTP communication and verifies also if the old port is not opened for HTTP communication.
    [Tags]    not-implemented    exclude
    TODO

6.01.01 Change port number of CoAP provider plugin
    [Documentation]    Configures new port number for CoAP provider module and verifies
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/put_coap/change_port    verify=True
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_BASE}/get_coap    verify=True
    Verify PluginData After Reconfiguration of CoAP

6.01.02 Check CoAP communication using new port
    [Documentation]    Sends GET request to the new port and verifies if it is possible to use the new configured port
    ...    for CoAP communication and verifies also if the old port is not opened for CoAP communication.
    [Tags]    not-implemented    exclude
    TODO

6.02.00 Setup MQTT communication
    [Documentation]    MQTT communication is not configured by default. This TC turns it ON and verifies.
    [Tags]    not-implemented    exclude
    #TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/put_mqtt    verify=True
    #TODO: this will not work because we need to have MQTT broker provisioned in cluster
    #TODO: this needs to be solved with releng team
    TODO

6.02.01 Change port number of MQTT provider plugin
    [Documentation]    Configures new port number for MQTT provider module and verifies
    [Tags]    not-implemented    exclude
    #TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/put_mqtt/change_port    verify=True
    #TemplatedRequests.Get_As_Json_Templated    folder=${VAR_BASE}/get_mqtt    verify=True
    #Verify PluginData After Reconfiguration of MQTT
    #TODO: this will not work because we need to have MQTT broker provisioned in cluster
    #TODO: this needs to be solved with releng team
    TODO

6.02.02 Check MQTT communication using new port
    [Documentation]    Sends GET request to the new port and verifies if it is possible to use the new configured port
    ...    for MQTT communication and verifies also if the old port is not opened for MQTT communication.
    [Tags]    not-implemented    exclude
    #TODO: this will not work because we need to have MQTT broker provisioned in cluster
    #TODO: this needs to be solved with releng team
    TODO

6.03.01 Change port number of WS provider plugin
    [Documentation]    Configures new port number for WS provider module and verifies
    [Tags]    not-implemented    exclude
    #todo check current configuration of ws if the feature is added to IoTDM project as in 6.01
    TODO

6.03.02 Check WS communication using new port
    [Documentation]    Sends GET request to the new port and verifies if it is possible to use the new configured port
    ...    for WS communication and verifies also if the old port is not opened for WS communication.
    [Tags]    not-implemented    exclude
    TODO

6.04 Change port number of Onem2mExample provider plugin
    [Documentation]    Configures new port number for Onem2mExample module using SimpleConfig and verifies
    Verify RPC Positive    put_onem2m_example/change_port
    Verify RPC Positive    get_onem2m_example
    Verify PluginData After Reconfiguration of Onem2mExample

6.05 Restart IoTDM and verify configuration of all plugins
    [Documentation]    Restarts IoTDM and verifies if the modules still uses new configuration
    [Tags]    persistence
    Restart Cluster
    BuiltIn.Wait_Until_Keyword_Succeeds    60 sec    1 sec    Verify PluginData After Reconfiguration of All Modules
    #todo change for ws port in ${VAR_BASE}/plugin_data/changed_data when feature is added to IoTDM project

6.06 Revert Configurations of all plugins
    [Documentation]    Reverts configuration of all re-configured plugins back to default state
    TemplatedRequests.Delete_Templated    folder=${VAR_BASE}/put_http/change_port
    TemplatedRequests.Delete_Templated    folder=${VAR_BASE}/put_coap/change_port
    #TODO revert also MQTT when issues solved
    #    TemplatedRequests.Delete_Templated    folder=${VAR_BASE}/put_mqtt/change_port
    #TODO revert for ws when feature is added to IoTDM project
    #    TemplatedRequests.Delete_Templated    folder=${VAR_BASE}/put_ws/change_port
    # Calls RPC for configuration delete
    Verify RPC Positive    put_onem2m_example

7.00 Test missing configuration of HTTP provider module
    [Documentation]    Tests multiple cases of missing mandatory configuration items of HTTP provider module
    Verify RPC Negative TC    http_cfg/missing_sec_level
    Verify RPC Negative TC    http_cfg/missing_sec_conn
    Verify RPC Negative TC    http_cfg/missing_server_port

7.01 Test invalid values in configuration of HTTP provider module
    [Documentation]    Tests multiple cases of invalid values set in configuration of HTTP provider module
    Verify RPC Negative TC    http_cfg/invalid_server_port
    Verify RPC Negative TC    http_cfg/invalid_sec_level
    Verify RPC Negative TC    http_cfg/invalid_sec_conn

7.02 Test missing configuration of CoAP provider module
    [Documentation]    Tests multiple cases of missing mandatory configuration items of CoAP provider module
    Verify RPC Negative TC    coap_cfg/missing_sec_level
    Verify RPC Negative TC    coap_cfg/missing_sec_conn
    Verify RPC Negative TC    coap_cfg/missing_server_port

7.03 Test invalid values in configuration of CoAP provider module
    [Documentation]    Tests multiple cases of invalid values set in configuration of CoAP provider module
    Verify RPC Negative TC    coap_cfg/invalid_server_port
    Verify RPC Negative TC    coap_cfg/invalid_sec_level
    Verify RPC Negative TC    coap_cfg/invalid_sec_conn

7.04 Test missing configuration of MQTT provider module
    [Documentation]    Tests multiple cases of missing mandatory configuration items of MQTT provider module
    Verify RPC Negative TC    mqtt_cfg/missing_mqtt_broker_ip
    Verify RPC Negative TC    mqtt_cfg/missing_mqtt_broker_port
    Verify RPC Negative TC    mqtt_cfg/missing_sec_level

7.05 Test invalid values in configuration of MQTT provider module
    [Documentation]    Tests multiple cases of invalid values set in configuration of MQTT provider module
    Verify RPC Negative TC    mqtt_cfg/invalid_mqtt_broker_ip
    Verify RPC Negative TC    mqtt_cfg/invalid_sec_level
    Verify RPC Negative TC    mqtt_cfg/invalid_mqtt_broker_port

7.06 Test missing configuration of WS provider module
    [Documentation]    Tests multiple cases of missing mandatory configuration items of WS provider module
    [Tags]    not-implemented    exclude
    #todo check missing configuration of ws if the feature is added to IoTDM project as in 7.00
    TODO

7.07 Test invalid values in configuration of WS provider module
    [Documentation]    Tests multiple cases of invalid values set in configuration of WS provider module
    [Tags]    not-implemented    exclude
    #todo check invalid configuration of ws if the feature is added to IoTDM project as in 7.01
    TODO

7.08 Test conflicting configuration handling for HTTP
    [Documentation]    Tests configuration of TCP port number for HTTP provider module.
    ...    The new configuration conflicts with configurtion of Onem2mExample plugin module.
    [Tags]    not-implemented    exclude
    #NOTE: the conflicting configuration results with 200 all the times beacuse the init() method of the module
    # is called asynchronously later and if it fails it's just logged and bundle init has failed...
    # so we can check registration in plugin manager
    # TODO: But it just says that there is not expected registration so we need to implement some registry of
    # TODO: registration failures and provide RPCs to list registration errors and clear registration errors
    # TODO: Improvement task opened: Bug 7771 - Implementation of registry of errors and related RPCs for PluginManager
    TODO

7.09 Test conflicting configuration handling for MQTT
    [Documentation]    Tests configuration of TCP port number for MQTT provider module.
    [Tags]    not-implemented    exclude
    # TODO: Improvement task opened: Bug 7771
    TODO

7.10 Test conflicting configuration handling for WS
    [Documentation]    Tests configuration of TCP port number for WS provider module.
    [Tags]    not-implemented    exclude
    # TODO: Improvement task opened: Bug 7771
    TODO

7.11 Test conflicting configuration handling for Onem2mExample
    [Documentation]    Tests configuration of TCP port number for Onem2mExample provider module.
    [Tags]    not-implemented    exclude
    # TODO: Improvement task opened: Bug 7771
    TODO

7.12 Test conflicting configuration handling for Coap
    [Documentation]    Tests configuration of TCP port number for Coap provider module.
    [Tags]    not-implemented    exclude
    # TODO: Improvement task opened: Bug 7771
    TODO

8.00 Test default configuration in onem2m-core
    [Documentation]    Tests usage of default configuration for IoTDM plugins
    [Tags]    not-implemented    exclude
    TODO

9.00 Test onem2m-simple-config:iplugin-cfg-get doesn`t contain anything in key-val-list
    [Documentation]    Verify if key-val-list doesn`t exist
    Verify RPC Simple Config    get_default

9.01 Test onem2m-simple-config:iplugin-cfg-put to add values to IoTDM SimpleConfig
    [Documentation]    Adds multiple values to Simple config
    Verify RPC Simple Config    put

9.02 Test onem2m-simple-config:iplugin-cfg-get contains values that were set
    [Documentation]    Tests if SimpleConfig contains added values
    Verify RPC Simple Config    get

9.03 Test onem2m-simple-config:iplugin-cfg-key-get receives single data
    [Documentation]    Tests if SimpleConfig receive correct value
    Verify RPC Simple Config Key    get0
    Verify RPC Simple Config Key    get1

9.04 Test onem2m-simple-config:iplugin-cfg-key-put set single data
    [Documentation]    Adds value to SimpleConfig using key and verify that it exists
    Verify RPC Simple Config Key    put
    Verify RPC Simple Config Key    put/check

9.05 Test onem2m-simple-config:iplugin-cfg-key-get-startup data
    [Documentation]    Tests if key startup recieves correct data
    Verify RPC Simple Config Key    startup

9.06 Test onem2m-simple-config:iplugin-cfg-key-del deletes single data
    [Documentation]    Deletes previously added value from SimpleConfig and verify it doesn`t exist anymore
    Verify RPC Simple Config    delete_key
    Verify RPC Negative Simple Config    negative/get_key

9.07 Test onem2m-simple-config:iplugin-cfg-key-get-startup data does not exist
    [Documentation]    Calls the startup rpc on key that does not exit and checks error
    Verify RPC Negative Simple Config    negative/get_startup_key

9.08 Test onem2m-simple-config:iplugin-cfg-key-del delete not existing single data
    [Documentation]    Try to delete not existing data and check fail
    Verify RPC Negative Simple Config    negative/delete_key

9.09 Test onem2m-simple-config:iplugin-cfg-put to add wrong values and expect error
    [Documentation]    Tests if SimpleConfig doesn`t allow to add values to SimpleConfig
    Verify RPC Negative TC    simple_config/iplugin_cfg_put/non_reg_plugin    verify=${true}
    Verify RPC Negative TC    simple_config/iplugin_cfg_put/non_reg_instance    verify=${true}

9.10 Test onem2m-simple-config:iplugin-cfg-get-startup contains expected data
    [Documentation]    Check if startup content contains only expected data
    Verify RPC Simple Config    get_startup

9.11 Test iplugin-cfg-get-startup-config and iplugin-cfg-get-running-config should equal
    [Documentation]    Tests if StartupConfig and running config are the same in content
    ${resp1} =    TemplatedRequests.Post_As_Json_Templated
    ...    folder=${VAR_BASE}/simple_config/get_startup/config
    ...    verify=True
    ${resp2} =    TemplatedRequests.Post_As_Json_Templated
    ...    folder=${VAR_BASE}/simple_config/get_running_config
    ...    verify=True
    Should Be Equal    ${resp1}    ${resp2}

9.12 Test onem2m-simple-config:iplugin-cfg-del to delete all the values
    [Documentation]    Deletes previously added values from Onem2mExample plugin and verify that they are gone
    Verify RPC Simple Config    delete_config
    Verify RPC Simple Config    get_startup/config/default

9.13 Test IoTDM BUG 7593
    [Documentation]    Multiple times try to delete configuration which doesn't exist.
    ...    https://bugs.opendaylight.org/show_bug.cgi?id=7593
    Verify RPC Negative TC    simple_config/multi_delete    verify=${true}
    Verify RPC Negative TC    simple_config/multi_delete    verify=${true}
    Verify RPC Negative TC    simple_config/multi_delete    verify=${true}

9.14 Test onem2m-simple-config:iplugin-cfg-del to delete empty config
    [Documentation]    Delete of empty configuration passes without error
    Verify RPC Simple Config    delete_config

10.01 Test input filters of onem2m-plugin-manager:onem2m-plugin-manager-iotdm-plugin-registrations
    [Documentation]    Use all filtering inputs and all combinations of them.
    ...    Verify that the output includes onlyt expected items or is empty because there is not such plugin in
    ...    the system.
    [Tags]    not-implemented    exclude
    TODO

10.02 Test input filters of onem2m-plugin-manager:onem2m-plugin-manager-communication-channels
    [Documentation]    Use all filtering inputs and all combinations of them.
    ...    Verify that the output includes onlyt expected items or is empty because there is not such plugin
    ...    or channel in the system.
    [Tags]    not-implemented    exclude
    TODO

10.03 Test input filters of onem2m-plugin-manager:onem2m-plugin-manager-db-api-client-registrations
    [Documentation]    Use all filtering inputs and all combinations of them.
    ...    Verify that the output includes onlyt expected items or is empty because there is not such plugin in
    ...    the system.
    [Tags]    not-implemented    exclude
    TODO

10.04 Test input filters of onem2m-plugin-manager:onem2m-plugin-manager-simple-config-client-registrations
    [Documentation]    Use all filtering inputs and all combinations of them.
    ...    Verify that the output includes onlyt expected items or is empty because there is not such plugin in
    ...    the system.
    [Tags]    not-implemented    exclude
    TODO

10.05 Test input filters of onem2m-plugin-manager:onem2m-plugin-manager-plugin-data
    [Documentation]    Use all filtering inputs and all combinations of them.
    ...    Verify that the output includes onlyt expected items or is empty because there is not such plugin in
    ...    the system.
    [Tags]    not-implemented    exclude
    TODO


*** Keywords ***
TODO
    Fail    "Not implemented"

Setup Suite
    [Documentation]    Prepares suite keywords and initialize mqtt and coap
    TemplatedRequests.Create_Default_Session
    ClusterManagement.ClusterManagement_Setup

Teardown Suite
    Delete all sessions

Restart Cluster
    [Documentation]    Restart IoTDM running on remote machine
    Log    Restarting cluster of IoTDM instances
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All

Verify Default PluginData Output
    [Documentation]    Verifies output of RPC call onem2m-plugin-manager:onem2m-plugin-manager-plugin-data
    ...    whether contains data about all default modules registering as plugins.
    Verify RPC Plugin Data    http/default
    Verify RPC Plugin Data    coap/default
    Verify RPC Plugin Data    mqtt/default
    Verify RPC Plugin Data    ws/default
    Verify RPC Plugin Data    onem2m_example/default
    Verify RPC Plugin Data    tsdr/default
    Verify RPC Plugin Data    simple_adapter/default

Verify PluginData After Reconfiguration of HTTP
    [Documentation]    Verifies plugin registration change after re-configuration of the plugin. Re-registration
    ...    should be done in 15 seconds and is checked in one second interval
    BuiltIn.Wait_Until_Keyword_Succeeds    15 sec    1 sec    Verify RPC Plugin Data    http/changed_port

Verify PluginData After Reconfiguration of CoAP
    [Documentation]    Verifies plugin registration change after re-configuration of the plugin. Re-registration
    ...    should be done in 15 seconds and is checked in one second interval
    BuiltIn.Wait_Until_Keyword_Succeeds    15 sec    1 sec    Verify RPC Plugin Data    coap/changed_port

Verify PluginData After Reconfiguration of MQTT
    [Documentation]    Verifies plugin registration change after re-configuration of the plugin. Re-registration
    ...    should be done in 15 seconds and is checked in one second interval
    #BuiltIn.Wait_Until_Keyword_Succeeds    15 sec    1 sec    Verify RPC Plugin Data    mqtt/changed_port
    TODO

Verify PluginData After Reconfiguration of Onem2mExample
    [Documentation]    Verifies plugin registration change after re-configuration of the plugin. Re-registration
    ...    should be done immediatelly because Onem2mExample plugin uses SimpleConfig for its configuration.
    Verify RPC Plugin Data    onem2m_example/changed_port

Verify PluginData After Reconfiguration of All Modules
    [Documentation]    Verifies registrations of all default plugins after re-configuration.
    Verify PluginData After Reconfiguration of HTTP
    Verify PluginData After Reconfiguration of CoAP
    # TODO verify also MQTT when imlemented
    #Verify PluginData After Reconfiguration of MQTT
    Verify PluginData After Reconfiguration of Onem2mExample

Verify RPC Positive
    [Documentation]    Verifies positive RPC scenario
    [Arguments]    ${variables_folder}
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/${variables_folder}    verify=True

Verify RPC Negative
    [Documentation]    Verifies negative RPC scenario
    [Arguments]    ${variables_folder}    ${verify}=${false}
    TemplatedRequests.Post_As_Json_Templated
    ...    folder=${VAR_BASE}/${variables_folder}
    ...    verify=${verify}
    ...    explicit_status_codes=${NEGATIVE_RESULTS}

Verify RPC Plugin Data
    [Documentation]    Verifies positive PluginData RPC scenarios described in plugin_data variables directory
    [Arguments]    ${plugin_data_folder}
    Verify RPC Positive    plugin_data/${plugin_data_folder}

Verify RPC Plugin Registrations
    [Documentation]    Verifies positive IoTDMPluginRegistrations RPC scenarios described in iotdm_plugin_registrations variables directory
    [Arguments]    ${plugin_reg_folder}
    Verify RPC Positive    iotdm_plugin_registrations/${plugin_reg_folder}

Verify RPC Db Registrations
    [Documentation]    Verifies positive DbRegistrations RPC scenarios described in db_registrations variables directory
    [Arguments]    ${db_reg_folder}
    Verify RPC Positive    db_registrations/${db_reg_folder}

Verify RPC Comm Channels
    [Documentation]    Verifies positive CommunicationChannels RPC scenarios described in communication_channels variables directory
    [Arguments]    ${comm_channel_folder}
    Verify RPC Positive    communication_channels/${comm_channel_folder}

Verify RPC Negative TC
    [Documentation]    Verifies negative re-configuration TCs described in negative_tcs variables directory
    [Arguments]    ${negative_tc_folder}    ${verify}=${false}
    Verify RPC Negative    negative_tcs/${negative_tc_folder}    verify=${verify}

Verify RPC Simple Config
    [Documentation]    Verifies positive SimpleConfig RPC scenarios described in simple_config variables directory
    [Arguments]    ${simple_config_folder}
    Verify RPC Positive    simple_config/${simple_config_folder}

Verify RPC Negative Simple Config
    [Documentation]    Verifies negative SimpleConfig RPC scenarios described in simple_config variables directory
    [Arguments]    ${negative_tc_folder}    ${verify}=${false}
    Verify RPC Negative    simple_config/${negative_tc_folder}    verify=${verify}

Verify RPC Simple Config Key
    [Documentation]    Verifies positive SimpleConfig Key RPC scenarios described in simple_config_key variables directory
    [Arguments]    ${simple_config_key_folder}
    Verify RPC Positive    simple_config_key/${simple_config_key_folder}

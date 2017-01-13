*** Settings ***
Documentation     Test suite testing IoTDM PluginManager RPC calls registrations of default plugins and
...               communication channels and re-configuration of port of registered plugins
Suite Setup       Start
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Library           ../../../libraries/criotdm.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/SubStrings.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/TemplatedRequests.robot

*** Variables ***
${VAR_BASE}       ${CURDIR}/../../../variables/IoTDM/
${REST_CONTEXT}    /restconf/operations
${PLUGIN_CONTEXT}    ${REST_CONTEXT}/onem2m-plugin-manager
${output}         'output'
${table}          'registered-iotdm-plugins-table'
${instances}      'registered-iotdm-plugin-instances'
${common_data}    'iotdm-common-plugin-data'
${plugin_class}    'plugin-class'
${registrations}    'iotdm-plugin-registrations'
${registrations_data}    'registration-data'

*** Test Cases ***
Set Suite Variable
    [Documentation]    set a suite variable
    ${headers} =    Create Dictionary    Content-Type=application/json    Authorization=Basic YWRtaW46YWRtaW4=
    Set Suite Variable    ${headers}

Configure Mqtt
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/put_mqtt    session=ClusterManagement__session_1

1.00 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC
    [Documentation]    Verifies if the RPC call result has set valid result code and
    ...    if it includes items of all default plugins: (HTTP, CoAP, MQTT, WS, Onem2mExample)
    # todo sleep should be deleted and test should pass. It is added because of race condition - mqtt is not configured if we don`t wait
    sleep    1s
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/registrations    session=ClusterManagement__session_1    verify=True

2.00 Default result of onem2m-plugin-manager-db-api-client-registrations RPC
    [Documentation]    Verifies the result of RPC and looks for Onem2mExample registration
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-db-api-client-registrations    headers=${headers}
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/db_registrations    session=ClusterManagement__session_1    verify=True

3.00 Default result of onem2m-plugin-manager-simple-config-client-registrations RPC
    [Documentation]    Verifies the result of RPC and looks for Onem2mExample registration
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig_registrations    session=ClusterManagement__session_1    verify=True

4.00 Default result of onem2m-plugin-manager-plugin-data RPC
    [Documentation]    Verifies the result of RPC and looks for data items related to:
    ...    HTTP, CoAP, MQTT, WS and Onem2mExample
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data    session=ClusterManagement__session_1    verify=True

4.01 Plugin data of HTTP
    [Documentation]    Verifies all plugin data about HTTP provider module plugin
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/http    session=ClusterManagement__session_1    verify=True

4.02 Plugin data of CoAP
    [Documentation]    Verifies all plugin data about CoAP provider module plugin
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/coap    session=ClusterManagement__session_1    verify=True

4.03 Plugin data of MQTT
    [Documentation]    Verifies all plugin data about MQTT provider module plugin
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/mqtt    session=ClusterManagement__session_1    verify=True

4.04 Plugin data of WS
    [Documentation]    Verifies all plugin data about WS provider module plugin
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/ws    session=ClusterManagement__session_1    verify=True

4.05 Plugin data of Onem2mExample
    [Documentation]    Verifies all plugin data about Onem2mExample provider module plugin
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/onem2mexample    session=ClusterManagement__session_1    verify=True

5.00 Default result of onem2m-plugin-manager-communication-channels RPC
    [Documentation]    Verifyies if the default communication channels exist
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/communication_channels    session=ClusterManagement__session_1    verify=True

5.01 Communication channel for HTTP plugins
    [Documentation]    Verifies the default instances of HTTP communication channel for HTTP provider and Onem2mExample
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/communication_channels/http    session=ClusterManagement__session_1    verify=True

5.02 Communication channel for CoAP plugins
    [Documentation]    Verifies the default instance of CoAP communication channel for CoAP provider
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/communication_channels/coap    session=ClusterManagement__session_1    verify=True

5.03 Communication channel for MQTT plugins
    [Documentation]    Verifies the default instance of MQTT communication channel for MQTT provider
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/communication_channels/mqtt    session=ClusterManagement__session_1    verify=True

5.04 Communication channel for WS plugins
    [Documentation]    Verifies the default instance of WS communication channel for WS provider
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/communication_channels/ws    session=ClusterManagement__session_1    verify=True

6.00 Change port number of HTTP provider plugin
    [Documentation]    Configures new port number for HTTP provider module and verifies
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/put_http/change_port    session=ClusterManagement__session_1
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_BASE}/get_http    session=ClusterManagement__session_1    verify=True
    # todo sleep should be deleted and test should pass. It is added because of race condition - http is not configured if we don`t wait
    sleep    1s
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/http/changed_port    session=ClusterManagement__session_1    verify=True

6.01 Change port number of CoAP provider plugin
    [Documentation]    Configures new port number for CoAP provider module and verifies
    #todo check current configuration of coap if the feature is added to IoTDM project as in 6.01
    TODO

6.02 Change port number of MQTT provider plugin
    [Documentation]    Configures new port number for MQTT provider module and verifies
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/put_mqtt/change_port    session=ClusterManagement__session_1
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_BASE}/get_mqtt    session=ClusterManagement__session_1    verify=True
    # todo sleep should be deleted and test should pass. It is added because of race condition - http is not configured if we don`t wait
    sleep    1s
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/mqtt/changed_port    session=ClusterManagement__session_1    verify=True

6.03 Change port number of WS provider plugin
    [Documentation]    Configures new port number for WS provider module and verifies
    #todo check current configuration of ws if the feature is added to IoTDM project as in 6.01
    TODO

6.04 Change port number of Onem2mExample provider plugin
    [Documentation]    Configures new port number for Onem2mExample module using SimpleConfig and verifies
    ${payload} =    Set Variable    {"input": {"plugin-name": "Onem2mExample","instance-name": "default","plugin-simple-config" :{"key-val-list" : [{"cfg-key": "port","cfg-val": "7779"}]}}}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-put    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    200
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/onem2mexample/changed_port    session=ClusterManagement__session_1    verify=True

6.05 Restart IoTDM and verify configuration of all plugins
    [Documentation]    Restarts IoTDM and verifies if the modules still uses new configuration
    ClusterManagement.Kill_Members_From_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/changed_data    session=ClusterManagement__session_1    verify=True
    #todo change for ws and coap port in ${VAR_BASE}/plugin_data/changed_data when feature is added to IoTDM project

6.06 Revert Configurations of all plugins
    [Documentation]    Reverts configuration of all re-configured plugins back to default state
    ${response} =    RequestsLibrary.Delete Request    ClusterManagement__session_1    restconf/config/onem2m-protocol-http:onem2m-protocol-http-providers/HttpProviderDefault    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    200
    ${payload} =    Set Variable    {"input": {"plugin-name": "Onem2mExample","instance-name": "default"}}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-del    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    200
    ${response} =    RequestsLibrary.Delete Request    ClusterManagement__session_1    restconf/config/onem2m-protocol-mqtt:onem2m-protocol-mqtt-providers/MqttProviderDefault    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    200
    #todo revert for ws and coap when feature is added to IoTDM project

7.00 Test missing configuration of HTTP provider module
    [Documentation]    Tests multiple cases of missing mandatory configuration items of HTTP provider module
    ${payload} =    Set Variable    {"onem2m-protocol-http-providers" : [{"http-provider-instance-name": "HttpProviderDefault","router-plugin-config": {"secure-connection": false},"server-config": {"secure-connection": false,"server-port": 7777},"notifier-plugin-config": {"secure-connection": false}}]}
    ${response} =    RequestsLibrary.Put Request    ClusterManagement__session_1    restconf/config/onem2m-protocol-http:onem2m-protocol-http-providers/HttpProviderDefault    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500

7.01 Test invalid values in configuration of HTTP provider module
    [Documentation]    Tests multiple cases of invalid values set in configuration of HTTP provider module
    #${payload} =    Set Variable    {"onem2m-protocol-http-providers" : [{"http-provider-instance-name": "HttpProviderDefault","router-plugin-config": {"secure-connection": false},"server-config": {"secure-connection": false,"server-security-level": "l0","server-port": 82828},"notifier-plugin-config": {"secure-connection": false}}]}
    #${response} =    RequestsLibrary.Put Request    ClusterManagement__session_1    restconf/config/onem2m-protocol-http:onem2m-protocol-http-providers/HttpProviderDefault    data=${payload}    headers=${headers}
    #${status_code} =    Status Code    ${response}
    #Should Be Equal As Integers    ${status_code}    400
    #todo uncomment after fix - test is ok IOTDM is not and it will mess up other tests
    ${payload} =    Set Variable    {"onem2m-protocol-http-providers" : [{"http-provider-instance-name": "HttpProviderDefault","router-plugin-config": {"secure-connection": false},"server-config": {"secure-connection": false,"server-security-level": "l4","server-port": 8282},"notifier-plugin-config": {"secure-connection": false}}]}
    ${response} =    RequestsLibrary.Put Request    ClusterManagement__session_1    restconf/config/onem2m-protocol-http:onem2m-protocol-http-providers/HttpProviderDefault    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    400
    ${payload} =    Set Variable    {"onem2m-protocol-http-providers" : [{"http-provider-instance-name": "HttpProviderDefault","router-plugin-config": {"secure-connection": false},"server-config": {"secure-connection": "asds","server-security-level": "l0","server-port": 8282},"notifier-plugin-config": {"secure-connection": false}}]}
    ${response} =    RequestsLibrary.Put Request    ClusterManagement__session_1    restconf/config/onem2m-protocol-http:onem2m-protocol-http-providers/HttpProviderDefault    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    400

7.02 Test missing configuration of CoAP provider module
    [Documentation]    Tests multiple cases of missing mandatory configuration items of CoAP provider module
    #todo check missing configuration of coap if the feature is added to IoTDM project as in 7.00
    TODO

7.03 Test invalid values in configuration of CoAP provider module
    [Documentation]    Tests multiple cases of invalid values set in configuration of CoAP provider module
    #todo check invalid configuration of coap if the feature is added to IoTDM project as in 7.01
    TODO

7.04 Test missing configuration of MQTT provider module
    [Documentation]    Tests multiple cases of missing mandatory configuration items of MQTT provider module
    ${payload} =    Set Variable    {"onem2m-protocol-mqtt-providers" : [{"mqtt-provider-instance-name": "MqttProviderDefault","mqtt-client-config": {"mqtt-broker-port" : 1883,"security-level" : "l0"}}]}
    ${response} =    RequestsLibrary.Put Request    ClusterManagement__session_1    restconf/config/onem2m-protocol-mqtt:onem2m-protocol-mqtt-providers/MqttProviderDefault    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500

7.05 Test invalid values in configuration of MQTT provider module
    [Documentation]    Tests multiple cases of invalid values set in configuration of MQTT provider module
    #${payload} =    Set Variable    {"onem2m-protocol-mqtt-providers" : [{"mqtt-provider-instance-name": "MqttProviderDefault","mqtt-client-config": {"mqtt-broker-port" : 1883,"mqtt-broker-ip" : "12777777","security-level" : "l0"}}]}
    #${response} =    RequestsLibrary.Put Request    ClusterManagement__session_1    restconf/config/onem2m-protocol-mqtt:onem2m-protocol-mqtt-providers/MqttProviderDefault    data=${payload}    headers=${headers}
    #${status_code} =    Status Code    ${response}
    #Should Be Equal As Integers    ${status_code}    400
    #todo uncomment after fix - test is ok IOTDM is not and it will mess up other tests
    ${payload} =    Set Variable    {"onem2m-protocol-mqtt-providers" : [{"mqtt-provider-instance-name": "MqttProviderDefault","mqtt-client-config": {"mqtt-broker-port" : 1883,"mqtt-broker-ip" : "127.0.0.1","security-level" : "l4"}}]}
    ${response} =    RequestsLibrary.Put Request    ClusterManagement__session_1    restconf/config/onem2m-protocol-mqtt:onem2m-protocol-mqtt-providers/MqttProviderDefault    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    400
    ${payload} =    Set Variable    {"onem2m-protocol-mqtt-providers" : [{"mqtt-provider-instance-name": "MqttProviderDefault","mqtt-client-config": {"mqtt-broker-port" : 188387,"mqtt-broker-ip" : "127.0.0.1","security-level" : "l0"}}]}
    ${response} =    RequestsLibrary.Put Request    ClusterManagement__session_1    restconf/config/onem2m-protocol-mqtt:onem2m-protocol-mqtt-providers/MqttProviderDefault    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    400

7.06 Test missing configuration of WS provider module
    [Documentation]    Tests multiple cases of missing mandatory configuration items of WS provider module
    #todo check missing configuration of ws if the feature is added to IoTDM project as in 7.00
    TODO

7.07 Test invalid values in configuration of WS provider module
    [Documentation]    Tests multiple cases of invalid values set in configuration of WS provider module
    #todo check invalid configuration of coap if the feature is added to IoTDM project as in 7.01
    TODO

7.08 Test conflicting configuration handling for HTTP
    [Documentation]    Tests configuration of TCP port number for HTTP provider module.
    ...    The new configuration conflicts with configurtion of Onem2mExample plugin module.
    #${payload} =    Set Variable    {"onem2m-protocol-http-providers" : [{"http-provider-instance-name": "HttpProviderDefault","router-plugin-config": {"secure-connection": false},"server-config": {"secure-connection": false,"server-security-level": "l0","server-port": 8888},"notifier-plugin-config": {"secure-connection": false}}]}
    #${response} =    RequestsLibrary.Put Request    ClusterManagement__session_1    restconf/config/onem2m-protocol-http:onem2m-protocol-http-providers/HttpProviderDefault    data=${payload}    headers=${headers}
    #${status_code} =    Status Code    ${response}
    #Should Be Equal As Integers    ${status_code}    400
    #todo uncomment after fix - test is ok IOTDM is not and it will mess up other tests
    TODO

7.09 Test conflicting configuration handling for MQTT
    [Documentation]    Tests configuration of TCP port number for MQTT provider module.
    #${payload} =    Set Variable    {"onem2m-protocol-mqtt-providers" : [{"mqtt-provider-instance-name": "MqttProviderDefault","mqtt-client-config": {"mqtt-broker-port" : 8888,"mqtt-broker-ip" : "127.0.0.1","security-level" : "l0"}}]}
    #${response} =    RequestsLibrary.Put Request    ClusterManagement__session_1    restconf/config/onem2m-protocol-mqtt:onem2m-protocol-mqtt-providers/MqttProviderDefault    data=${payload}    headers=${headers}
    #${status_code} =    Status Code    ${response}
    #Should Be Equal As Integers    ${status_code}    400
    #todo uncomment after fix - test is ok IOTDM is not and it will mess up other tests
    TODO

7.10 Test conflicting configuration handling for WS
    [Documentation]    Tests configuration of TCP port number for WS provider module.
    TODO

7.11 Test conflicting configuration handling for Onem2mExample
    [Documentation]    Tests configuration of TCP port number for Onem2mExample provider module.
    TODO

7.12 Test conflicting configuration handling for Coap
    [Documentation]    Tests configuration of TCP port number for Coap provider module.
    TODO

8.00 Test default configuration for plugins
    [Documentation]    Tests usage of default configuration for IoTDM plugins
    TODO

9.00 Test onem2m-simple-config:iplugin-cfg-get doesn`t contain anything in key-val-list
    [Documentation]    Verify if key-val-list doesn`t exist
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig/get_default    session=ClusterManagement__session_1    verify=True

9.01 Test onem2m-simple-config:iplugin-cfg-put to add values to IoTDM SimpleConfig
    [Documentation]    Adds multiple values to Simple config
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig/put    session=ClusterManagement__session_1    verify=True

9.02 Test onem2m-simple-config:iplugin-cfg-get contains values that were set
    [Documentation]    Tests if SimpleConfig contains added values
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig/get    session=ClusterManagement__session_1    verify=True

9.03 Test onem2m-simple-config:iplugin-cfg-key-get receives single data
    [Documentation]    Tests if SimpleConfig receive correct value
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig_key/get0    session=ClusterManagement__session_1    verify=True
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig_key/get1    session=ClusterManagement__session_1    verify=True

9.04 Test onem2m-simple-config:iplugin-cfg-key-put set single data
    [Documentation]    Adds value to SimpleConfig using key and verify that it exists
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig_key/put    session=ClusterManagement__session_1    verify=True
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig_key/put/check    session=ClusterManagement__session_1    verify=True

9.5 Test onem2m-simple-config:iplugin-cfg-key-get-startup data
    [Documentation]    Tests if key startup recieves correct data
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig_key/startup    session=ClusterManagement__session_1    verify=True

9.06 Test onem2m-simple-config:iplugin-cfg-key-del deletes single data
    [Documentation]    Deletes previously added value from SimpleConfig and verify it doesn`t exist anymore
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default", "cfg-key":"testKey2"}}
    ${resp} =    RequestsLibrary.Post Request    ClusterManagement__session_1    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-key-del    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default", "cfg-key":"testKey2"}}
    ${resp} =    RequestsLibrary.Post Request    ClusterManagement__session_1    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-key-get    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    404

9.07 Test onem2m-simple-config:iplugin-cfg-key-get-startup data does not exist
    [Documentation]    Calls the startup rpc on key that does not exit and checks error
    ${payload} =    Set Variable    {"input": {"plugin-name": "Onem2mExample","instance-name": "default","cfg-key": "testKey2"}}
    ${resp} =    RequestsLibrary.Post Request    ClusterManagement__session_1    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-key-get-startup    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    500

9.08 Test onem2m-simple-config:iplugin-cfg-key-del delete not existing single data
    [Documentation]    Try to delete not existing data and check fail
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default", "cfg-key":"testKey2"}}
    ${resp} =    RequestsLibrary.Post Request    ClusterManagement__session_1    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-key-del    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    404

9.09 Test onem2m-simple-config:iplugin-cfg-put to add wrong values and epect error
    [Documentation]    Tests if SimpleConfig doesn`t allow to add values to SimpleConfig
    ${payload} =    Set Variable    {"input": {"plugin-name":"aaa", "instance-name":"default", "plugin-simple-config" : {"key-val-list" : [{"cfg-key":"000000","cfg-val":"testVal"},{"cfg-key":"11111","cfg-val":"Val1"}]}}}
    ${resp} =    RequestsLibrary.Post Request    ClusterManagement__session_1    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-put    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${resp.content}    Failed to write new startup config of non-registered plugin
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"aaa","plugin-simple-config" : {"key-val-list" : [{"cfg-key":"000000","cfg-val":"testVal"},{"cfg-key":"11111","cfg-val":"Val1"}]}}}
    ${resp} =    RequestsLibrary.Post Request    ClusterManagement__session_1    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-put    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    500
    Should Contain    ${resp.content}    Failed to write new startup config of non-registered plugin

9.10 Test onem2m-simple-config:iplugin-cfg-get-startup contains expected data
    [Documentation]    Check if startup content contains only expected data
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig/get_startup    session=ClusterManagement__session_1    verify=True

9.11 Test iplugin-cfg-get-startup-config and iplugin-cfg-get-running-config should equal
    [Documentation]    Tests if StartupConfig and running config are the same in content
    ${resp1} =    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig/get_startup/config    session=ClusterManagement__session_1    verify=True
    ${resp2} =    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig/get_running_config    session=ClusterManagement__session_1    verify=True
    should be equal    ${resp1.content}    ${resp2.content}

9.12 Test IoTDM BUG 7593
    [Documentation]    https://bugs.opendaylight.org/show_bug.cgi?id=7593
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default", "cfg-key":"testKey10"}}
    ${resp} =    RequestsLibrary.Post Request    ClusterManagement__session_1    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-key-del    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    500
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default", "cfg-key":"testKey10"}}
    ${resp} =    RequestsLibrary.Post Request    ClusterManagement__session_1    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-key-del    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    500
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig_registrations    session=ClusterManagement__session_1    verify=True

9.13 Test onem2m-simple-config:iplugin-cfg-del to delete all the values
    [Documentation]    Deletes previously added values from Onem2mExample plugin and verify that they are gone
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default"}}
    ${resp} =    RequestsLibrary.Post Request    ClusterManagement__session_1    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-del    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig/get_startup/config/default    session=ClusterManagement__session_1    verify=True

9.14 Test onem2m-simple-config:iplugin-cfg-del to delete all the values and check error
    [Documentation]    Deletes now not existing data and checks error
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default"}}
    ${resp} =    RequestsLibrary.Post Request    ClusterManagement__session_1    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-del    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    500

*** Keywords ***
TODO
    Fail    "Not implemented"

Start
    [Documentation]    Prepares suite keywords
    ClusterManagement.ClusterManagement_Setup

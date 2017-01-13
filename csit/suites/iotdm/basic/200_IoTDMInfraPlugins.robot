*** Settings ***
Documentation     Test suite testing IoTDM PluginManager RPC calls registrations of default plugins and
...               communication channels and re-configuration of port of registered plugins
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Library           ../../../libraries/criotdm.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/SubStrings.robot

*** Variables ***
${REST_CONTEXT}    /restconf/operations
${PLUGIN_CONTEXT}    ${REST_CONTEXT}/onem2m-plugin-manager
${output}         'output'
${table}          'registered-iotdm-plugins-table'
${instances}      'registered-iotdm-plugin-instances'
${common-data}    'iotdm-common-plugin-data'
${class}          'plugin-class'
${registrations}    'iotdm-plugin-registrations'
${registrations_data}    'registration-data'

*** Test Cases ***
Set Suite Variable
    [Documentation]    set a suite variable
    ${list} =    Create List    http(s)-base    ws    mqtt    Onem2mExample    coap(s)
    Set Suite Variable    ${list}
    ${headers} =    Create Dictionary    Content-Type=application/json    Authorization=Basic YWRtaW46YWRtaW4=
    Set Suite Variable    ${headers}

1.00 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC
    [Documentation]    Verifies if the RPC call result has set valid result code and
    ...    if it includes items of all default plugins: (HTTP, CoAP, MQTT, WS, Onem2mExample)
    ${response} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-iotdm-plugin-registrations    headers=${headers}
    Set Suite Variable    ${response}
    Check Response Succesfull With Correct Data    ${response}    @{list}
    Check IoTDM Plugin Common Data    ${response}    ${table}    [${instances}][0]    onem2m-plugin-manager-iotdm-plugin-registrations

1.01 Registration parameters of HTTP IoTDM plugin
    [Documentation]    Verifies the default registration of HTTP provider module as IoTDM plugin
    ${json_value}    Find Json Children By Value    Onem2mHttpBaseIotdmPlugin    ${response.json()[${output}][${table}]}
    ${class} =    Set Variable    ${json_value[${instances}][0][${common-data}][${class}]}
    ${regs} =    convert to string    ${json_value[${instances}][0][${registrations}][0][${registrations_data}]}
    Should Contain    ${class}    Onem2mHttpBaseIotdmPlugin
    Should Contain All Sub Strings    ${regs}    TCP    http    8282    0.0.0.0

1.02 Registration parameters of CoAP IoTDM plugin
    [Documentation]    Verifies the default registration of CoAP provider module as IoTDM plugin
    ${json_value}    Find Json Children By Value    Onem2mCoapBaseIotdmPlugin    ${response.json()[${output}][${table}]}
    ${class} =    Set Variable    ${json_value[${instances}][0][${common-data}][${class}]}
    ${regs} =    convert to string    ${json_value[${instances}][0][${registrations}][0][${registrations_data}]}
    Should Contain    ${class}    Onem2mCoapBaseIotdmPlugin
    Should Contain All Sub Strings    ${regs}    UDP    coap    5683    0.0.0.0

1.03 Registration parameters of MQTT IoTDM plugin
    [Documentation]    Verifies the default registration of MQTT provider module as IoTDM plugin
    ${json_value}    Find Json Children By Value    Onem2mMqttIotdmPlugin    ${response.json()[${output}][${table}]}
    ${class} =    Set Variable    ${json_value[${instances}][0][${common-data}][${class}]}
    ${regs} =    convert to string    ${json_value[${instances}][0][${registrations}][0][${registrations_data}]}
    Should Contain    ${class}    Onem2mMqttIotdmPlugin
    Should Contain All Sub Strings    ${regs}    TCP    mqtt    1883    127.0.0.1

1.04 Registration parameters of WS IoTDM plugin
    [Documentation]    Verifies the default registration of WS provider module as IoTDM plugin
    ${json_value}    Find Json Children By Value    Onem2mWebsocketIotdmPlugin    ${response.json()[${output}][${table}]}
    ${class} =    Set Variable    ${json_value[${instances}][0][${common-data}][${class}]}
    ${regs} =    convert to string    ${json_value[${instances}][0][${registrations}][0][${registrations_data}]}
    Should Contain    ${class}    Onem2mWebsocketIotdmPlugin
    Should Contain All Sub Strings    ${regs}    TCP    websocket    8888    0.0.0.0

1.05 Registration parameters of Onem2mExample IoTDM plugin
    [Documentation]    Verifies the default registration of Onem2mExample as IoTDM plugin
    ${json_value}    Find Json Children By Value    Onem2mExampleCustomProtocol    ${response.json()[${output}][${table}]}
    ${class} =    Set Variable    ${json_value[${instances}][0][${common-data}][${class}]}
    ${regs} =    convert to string    ${json_value[${instances}][0][${registrations}][0][${registrations_data}]}
    Should Contain    ${class}    Onem2mExampleCustomProtocol
    Should Contain All Sub Strings    ${regs}    TCP    http    8283    0.0.0.0

2.00 Default result of onem2m-plugin-manager-db-api-client-registrations RPC
    [Documentation]    Verifies the result of RPC and looks for Onem2mExample registration
    ${response} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-db-api-client-registrations    headers=${headers}
    Set Suite Variable    ${response}    ${response}
    Check Response Succesfull With Correct Data    ${response}    Onem2mExample
    Check IoTDM Plugin Common Data    ${response}    'registered-db-api-client-plugins-table'    ['registered-db-api-client-plugin-instances'][0]['db-api-client-plugin-data']    onem2m-plugin-manager-db-api-client-registrations

2.01 Registration of Onem2mExample as IotdmPluginDbClient
    [Documentation]    Verifies the state of the registration of Onem2mExample plugin
    ${db_table} =    Set Variable    'registered-db-api-client-plugins-table'
    ${data} =    Set Variable    'db-api-client-plugin-data'
    ${client_state} =    Set Variable    'db-api-client-state'
    ${instances} =    Set Variable    'registered-db-api-client-plugin-instances'
    ${json_value}    Find Json Children By Value    Onem2mExample    ${response.json()[${output}][${db_table}]}
    ${clinet_state} =    convert to string    ${json_value[${instances}][0][${data}][${client_state}]}
    ${plugin_name} =    Set Variable    ${json_value['plugin-name']}
    Should Contain    ${plugin_name}    Onem2mExample
    Should Contain    ${clinet_state}    STARTED

3.00 Default result of onem2m-plugin-manager-simple-config-client-registrations RPC
    [Documentation]    Verifies the result of RPC and looks for Onem2mExample registration
    ${response} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-simple-config-client-registrations    headers=${headers}
    Set Suite Variable    ${response}    ${response}
    Check Response Succesfull With Correct Data    ${response}    Onem2mExample
    Check IoTDM Plugin Common Data    ${response}    'registered-simple-config-client-plugins-table'    ['registered-simple-config-client-plugin-instances'][0]    onem2m-plugin-manager-simple-config-client-registrations

4.00 Default result of onem2m-plugin-manager-plugin-data RPC
    [Documentation]    Verifies the result of RPC and looks for data items related to:
    ...    HTTP, CoAP, MQTT, WS and Onem2mExample
    ${response} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-plugin-data    headers=${headers}
    Check Response Succesfull With Correct Data    ${response}    @{list}
    Check IoTDM Plugin Common Data    ${response}    'onem2m-plugin-manager-plugins-table'    ['onem2m-plugin-manager-plugin-instances'][0]    onem2m-plugin-manager-plugin-data

4.01 Plugin data of HTTP
    [Documentation]    Verifies all plugin data about HTTP provider module plugin
    ${payload} =    Set Variable    {"input": {"plugin-name": "http(s)-base"}}
    ${response} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-plugin-data    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${response}    default    http(s)-base    IotdmPlugin    TCP    Exclusive
    ...    8282    "0.0.0.0"    "http"    Onem2mHttpBaseIotdmPlugin    *    "server-security-level":"l0"
    ...    "server-port":8282
    Should Contain X Times    ${response.content}    "secure-connection":false    3

4.02 Plugin data of CoAP
    [Documentation]    Verifies all plugin data about CoAP provider module plugin
    ${payload} =    Set Variable    {"input": {"plugin-name": "coap(s)"}}
    ${response} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-plugin-data    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${response}    default    coap(s)    IotdmPlugin    UDP    Exclusive
    ...    5683    "0.0.0.0"    "coap"    Onem2mCoapBaseIotdmPlugin    *

4.03 Plugin data of MQTT
    [Documentation]    Verifies all plugin data about MQTT provider module plugin
    ${payload} =    Set Variable    {"input": {"plugin-name": "mqtt"}}
    ${response} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-plugin-data    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${response}    default    mqtt    IotdmPlugin    TCP    Exclusive
    ...    1883    "127.0.0.1"    Onem2mMqttIotdmPlugin    *

4.04 Plugin data of WS
    [Documentation]    Verifies all plugin data about WS provider module plugin
    ${payload} =    Set Variable    {"input": {"plugin-name": "ws"}}
    ${response} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-plugin-data    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${response}    default    ws    websocket    IotdmPlugin    TCP
    ...    Exclusive    8888    "0.0.0.0"    Onem2mWebsocketIotdmPlugin    *

4.05 Plugin data of Onem2mExample
    [Documentation]    Verifies all plugin data about Onem2mExample provider module plugin
    ${payload} =    Set Variable    {"input": {"plugin-name": "Onem2mExample"}}
    ${response} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-plugin-data    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${response}    IotdmPluginSimpleConfigClient    IotdmPluginDbClient    IotdmPlugin    IotdmPluginConfigurable    STARTED
    ...    default    http    Onem2mExample    IotdmPlugin    TCP    Exclusive
    ...    8283    "0.0.0.0"    Onem2mExampleCustomProtocol    *

5.00 Default result of onem2m-plugin-manager-communication-channels RPC
    [Documentation]    Verifyies if the default communication channels exist
    ${response} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-communication-channels    headers=${headers}
    Check Response Succesfull With Correct Data    ${response}    @{list}

5.01 Communication channel for HTTP plugins
    [Documentation]    Verifies the default instances of HTTP communication channel for HTTP provider and Onem2mExample
    ${payload} =    Set Variable    {"input": {"protocol-name": "http"}}
    ${response} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-communication-channels    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${response}    http(s)-base    "http"    0.0.0.0    8282    8283
    ...    Onem2mExample    TCP    RUNNING    SERVER    default

5.02 Communication channel for CoAP plugins
    [Documentation]    Verifies the default instance of CoAP communication channel for CoAP provider
    ${payload} =    Set Variable    {"input": {"protocol-name": "coap"}}
    ${response} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-communication-channels    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${response}    coap(s)    "coap"    0.0.0.0    5683    UDP
    ...    RUNNING    SERVER    default

5.03 Communication channel for MQTT plugins
    [Documentation]    Verifies the default instance of MQTT communication channel for MQTT provider
    ${payload} =    Set Variable    {"input": {"protocol-name": "mqtt"}}
    ${response} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-communication-channels    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${response}    mqtt    127.0.0.1    1883    TCP    RUNNING
    ...    CLIENT    default

5.04 Communication channel for WS plugins
    [Documentation]    Verifies the default instance of WS communication channel for WS provider
    ${payload} =    Set Variable    {"input": {"protocol-name": "websocket"}}
    ${response} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-communication-channels    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${response}    websocket    "ws"    0.0.0.0    8888    TCP
    ...    INIT    SERVER    default

6.00 Store current outputs of PluginManager RPC calls
    [Documentation]    Stores current PluginManager data which will be used in next test cases
    ${response_suite} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-plugin-data    headers=${headers}
    Set Suite Variable    ${response_suite}
    Check Response Succesfull With Correct Data    ${response_suite}    @{list}

6.01 Change port number of HTTP provider plugin
    [Documentation]    Configures new port number for HTTP provider module and verifies
    ${payload} =    Set Variable    {"onem2m-protocol-http-providers" : [{"http-provider-instance-name": "HttpProviderDefault","router-plugin-config": {"secure-connection": false},"server-config": {"secure-connection": false,"server-security-level": "l0","server-port": 7777},"notifier-plugin-config": {"secure-connection": false}}]}
    ${response} =    RequestsLibrary.Put Request    session    restconf/config/onem2m-protocol-http:onem2m-protocol-http-providers/HttpProviderDefault    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be True    199 < ${status_code} < 299
    Log    ${response.content}
    ${response} =    RequestsLibrary.Get Request    session    restconf/config/onem2m-protocol-http:onem2m-protocol-http-providers/HttpProviderDefault    headers=${headers}
    Check Response Succesfull With Correct Data    ${response}    HttpProviderDefault
    ${payload} =    Set Variable    {"input": {"plugin-name":"http(s)-base"}}
    ${response1} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-plugin-data    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${response1}    "port":7777    "server-port":7777
    ${json_value1} =    Get Json Value    ${response1.content}    /output/onem2m-plugin-manager-plugins-table/0/onem2m-plugin-manager-plugin-instances/0/plugin-configuration
    ${json_value} =    Get Json Value    ${response.content}    /onem2m-protocol-http-providers/0
    ${value} =    Get Json Value    ${json_value}    /server-config/server-port
    ${value1} =    Get Json Value    ${json_value1}    /onem2m-protocol-http:server-config/server-port
    Should Be Equal    ${value}    ${value1}
    ${value} =    Get Json Value    ${json_value}    /server-config/server-security-level
    ${value1} =    Get Json Value    ${json_value1}    /onem2m-protocol-http:server-config/server-security-level
    Should Be Equal    ${value}    ${value1}
    ${value} =    Get Json Value    ${json_value}    /server-config/secure-connection
    ${value1} =    Get Json Value    ${json_value1}    /onem2m-protocol-http:server-config/secure-connection
    Should Be Equal    ${value}    ${value1}
    ${value} =    Get Json Value    ${json_value}    /router-plugin-config/secure-connection
    ${value1} =    Get Json Value    ${json_value1}    /onem2m-protocol-http:router-plugin-config/secure-connection
    Should Be Equal    ${value}    ${value1}
    ${value} =    Get Json Value    ${json_value}    /notifier-plugin-config/secure-connection
    ${value1} =    Get Json Value    ${json_value1}    /onem2m-protocol-http:notifier-plugin-config/secure-connection
    Should Be Equal    ${value}    ${value1}
    ${json_value1} =    Get Json Value    ${response_suite.content}    /output/onem2m-plugin-manager-plugins-table/0/onem2m-plugin-manager-plugin-instances/0/plugin-configuration
    ${value1} =    Get Json Value    ${json_value1}    /onem2m-protocol-http:server-config/server-port
    Should Not Be Equal    ${value1}    ${value}

6.02 Change port number of CoAP provider plugin
    [Documentation]    Configures new port number for CoAP provider module and verifies
    #todo check current configuration of coap if the feature is added to IoTDM project as in 6.01
    TODO

6.03 Change port number of MQTT provider plugin
    [Documentation]    Configures new port number for MQTT provider module and verifies
    #todo check current configuration of mqtt if the feature is added to IoTDM project as in 6.01
    TODO

6.04 Change port number of WS provider plugin
    [Documentation]    Configures new port number for WS provider module and verifies
    #todo check current configuration of ws if the feature is added to IoTDM project as in 6.01
    TODO

6.05 Change port number of Onem2mExample provider plugin
    [Documentation]    Configures new port number for Onem2mExample module using SimpleConfig and verifies
    ${payload} =    Set Variable    {"input": {"plugin-name": "Onem2mExample","instance-name": "default","plugin-simple-config" :{"key-val-list" : [{"cfg-key": "port","cfg-val": "7778"}]}}}
    ${response} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-put    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    200
    ${payload} =    Set Variable    {"input": {"plugin-name": "Onem2mExample"}}
    ${response1} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-plugin-data    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${response1}    "port":7778    "plugin-name":"Onem2mExample"

6.06 Restart IoTDM and verify configuration of all plugins
    [Documentation]    Restarts IoTDM and verifies if the modules still uses new configuration
    #${response} =    RequestsLibrary.Post Request    session    restconf/config/onem2m-protocol-http:onem2m-protocol-http-providers/HttpProviderDefault    headers=${headers}
    #${status_code} =    Status Code    ${response}
    #Should Be Equal As Integers    ${status_code}    200
    #${json_value}    Find Json Children By Value    coap(s)    ${response.json()[${output}]['onem2m-simple-config-list']}
    TODO

6.07 Revert Configurations of all plugins
    [Documentation]    Reverts configuration of all re-configured plugins back to default state
    ${response} =    RequestsLibrary.Delete Request    session    restconf/config/onem2m-protocol-http:onem2m-protocol-http-providers/HttpProviderDefault    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    200
    ${payload} =    Set Variable    {"input": {"plugin-name": "Onem2mExample","instance-name": "default","plugin-simple-config" :{"key-val-list" : [{"cfg-key": "port","cfg-val": "8283"}]}}}
    ${response} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-put    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    200

7.00 Test missing configuration of HTTP provider module
    [Documentation]    Tests multiple cases of missing mandatory configuration items of HTTP provider module
    ${payload} =    Set Variable    {"onem2m-protocol-http-providers" : [{"http-provider-instance-name": "HttpProviderDefault","router-plugin-config": {"secure-connection": false},"server-config": {"secure-connection": false,"server-port": 7777},"notifier-plugin-config": {"secure-connection": false}}]}
    ${response} =    RequestsLibrary.Put Request    session    restconf/config/onem2m-protocol-http:onem2m-protocol-http-providers/HttpProviderDefault    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    500

7.01 Test invalid values in configuration of HTTP provider module
    [Documentation]    Tests multiple cases of invalid values set in configuration of HTTP provider module
    ${payload} =    Set Variable    {"onem2m-protocol-http-providers" : [{"http-provider-instance-name": "HttpProviderDefault","router-plugin-config": {"secure-connection": false},"server-config": {"secure-connection": false,"server-security-level": "l0","server-port": 82828},"notifier-plugin-config": {"secure-connection": false}}]}
    ${response} =    RequestsLibrary.Put Request    session    restconf/config/onem2m-protocol-http:onem2m-protocol-http-providers/HttpProviderDefault    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    400
    ${payload} =    Set Variable    {"onem2m-protocol-http-providers" : [{"http-provider-instance-name": "HttpProviderDefault","router-plugin-config": {"secure-connection": false},"server-config": {"secure-connection": false,"server-security-level": "l4","server-port": 8282},"notifier-plugin-config": {"secure-connection": false}}]}
    ${response} =    RequestsLibrary.Put Request    session    restconf/config/onem2m-protocol-http:onem2m-protocol-http-providers/HttpProviderDefault    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${status_code}    400
    ${payload} =    Set Variable    {"onem2m-protocol-http-providers" : [{"http-provider-instance-name": "HttpProviderDefault","router-plugin-config": {"secure-connection": false},"server-config": {"secure-connection": "asds","server-security-level": "l0","server-port": 8282},"notifier-plugin-config": {"secure-connection": false}}]}
    ${response} =    RequestsLibrary.Put Request    session    restconf/config/onem2m-protocol-http:onem2m-protocol-http-providers/HttpProviderDefault    data=${payload}    headers=${headers}
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
    #todo check missing configuration of mqtt if the feature is added to IoTDM project as in 7.00
    TODO

7.05 Test invalid values in configuration of MQTT provider module
    [Documentation]    Tests multiple cases of invalid values set in configuration of MQTT provider module
    #todo check invalid configuration of mqtt if the feature is added to IoTDM project as in 7.01
    TODO

7.06 Test missing configuration of WS provider module
    [Documentation]    Tests multiple cases of missing mandatory configuration items of WS provider module
    #todo check missing configuration of ws if the feature is added to IoTDM project as in 7.00
    TODO

7.07 Test invalid values in configuration of WS provider module
    [Documentation]    Tests multiple cases of invalid values set in configuration of WS provider module
    #todo check invalid configuration of coap if the feature is added to IoTDM project as in 7.01
    TODO

7.08 Test conflicting configuration handling
    [Documentation]    Tests configuration of TCP port number for HTTP provider module.
    #...    The new configuration conflicts with configurtion of Onem2mExample plugin module.
    #${payload} =    Set Variable    {"onem2m-protocol-http-providers" : [{"http-provider-instance-name": "HttpProviderDefault","router-plugin-config": {"secure-connection": false},"server-config": {"secure-connection": false,"server-security-level": "l0","server-port": 8283},"notifier-plugin-config": {"secure-connection": false}}]}
    #${response} =    RequestsLibrary.Put Request    session    restconf/config/onem2m-protocol-http:onem2m-protocol-http-providers/HttpProviderDefault    data=${payload}    headers=${headers}
    #${status_code} =    Status Code    ${response}
    #Should Be Equal As Integers    ${status_code}    400

8.00 Test default configuration for plugins
    [Documentation]    Tests usage of default configuration for IoTDM plugins
    TODO

9.00 IoTDM SimpleConfig GET config
    [Documentation]    Tests if Onem2mExample plugin doesn't contain any values
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-get    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200
    Should Not Contain    ${resp.content}    key-val-list    "cfg-key":"000000"    "cfg-val":"testVal"

9.01 IoTDM SimpleConfig PUT config
    [Documentation]    Adds some values to Onem2mExample plugin
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample","instance-name":"default", "plugin-simple-config" : {"key-val-list" : [{"cfg-key":"000000","cfg-val":"testVal"}]}}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-put    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200

9.02 IoTDM SimpleConfig GET config
    [Documentation]    Tests if Onem2mExample plugin contains added values
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-get    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200
    Should Contain    ${resp.content}    key-val-list    "cfg-key":"000000"    "cfg-val":"testVal"

9.03 IoTDM SimpleConfig DELETE config
    [Documentation]    Deletes previously added values from Onem2mExample plugin
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-del    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200

9.04 IoTDM SimpleConfig GET config
    [Documentation]    Tests if Onem2mExample plugin doesn't contain any values
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-get    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200
    Should Not Contain    ${resp.content}    key-val-list    "cfg-key":"000000"    "cfg-val":"testVal"

9.05 IoTDM SimpleConfig GET config startup
    [Documentation]    Startups Onem2mExample plugin
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-get-startup    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200

9.06 IoTDM SimpleConfig GET RunningConfig
    [Documentation]    Tests if startup was successful
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-get-running-config    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200
    Should Contain    ${resp.content}    "instance-name":"default"

9.10 IoTDM SimpleConfig key GET
    [Documentation]    Tests if keyed Onem2mExample plugin doesn't contain any values
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default", "cfg-key":"testKey2"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-key-get    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200
    Should Not Contain    ${resp.content}    "cfg-val": "testVal2"

9.11 IoTDM SimpleConfig key PUT
    [Documentation]    Adds some values to keyed Onem2mExample plugin with key
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default", "cfg-key":"testKey2", "cfg-val":"testVal2"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-key-put    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200

9.12 IoTDM SimpleConfig key GET
    [Documentation]    Tests if keyed Onem2mExample plugin contains some values
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default", "cfg-key":"testKey2"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-key-get    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200
    Should Contain    ${resp.content}    "instance-name":"default"    "plugin-name":"Onem2mExample"    "cfg-key":"testKey2"    "cfg-val":"testVal2"

9.13 IoTDM SimpleConfig Key GET startup
    [Documentation]    Startups keyed Onem2mExample plugin
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default", "cfg-key":"testKey2"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-key-get-startup    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200

9.14 IoTDM SimpleConfig GET RunningConfig
    [Documentation]    Tests if startup was successful
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-get-running-config    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200
    Should Contain    ${resp.content}    "instance-name":"default"    "cfg-key":"testKey2"    "cfg-val":"testVal2"

9.15 IoTDM SimpleConfig key DELETE
    [Documentation]    Deletes previously added values from keyed Onem2mExample plugin
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default", "cfg-key":"testKey2"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-key-del    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200

9.20 IoTDM SimpleConfig GET StartupConfig
    [Documentation]    Tests if StartupConfig include all modules
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-get-startup-config    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200
    Should Contain All Sub Strings    ${resp.content}    "coap(s)"    "ws"    "http(s)-base"    "mqtt"    "Onem2mExample"

*** Keywords ***
TODO
    Fail    "Not implemented"

Check Response Succesfull With Correct Data
    [Arguments]    ${response}    @{checked}
    Should Be Equal As Strings    ${response.status_code}    200
    Should Contain All Sub Strings    ${response.content}    @{checked}

Find Json Children By Value
    [Arguments]    ${value}    ${json}
    ${length}    Get Length    ${json}
    : FOR    ${INDEX}    IN RANGE    ${length}
    \    return from keyword if    '''${value}''' in '''${json[${INDEX}]}'''    ${json[${INDEX}]}

Check Common Data On Specific Path
    [Arguments]    ${json_value}    ${jArgument_specific}    ${check-class}    ${check-name}    ${check-instance-name}
    Log    ${json_value}
    ${class} =    Set Variable    ${json_value${jArgument_specific}[${common-data}][${class}]}
    ${name} =    Set Variable    ${json_value${jArgument_specific}[${common-data}]['plugin-name']}
    ${instance_name} =    Set Variable    ${json_value${jArgument_specific}[${common-data}]['plugin-instance-name']}
    Should Be Equal    ${class}    ${check-class}
    Should Be Equal    ${name}    ${check-name}
    Should Be Equal    ${instance_name}    ${check-instance-name}

Check IoTDM Plugin Data 1
    [Arguments]    ${response}    ${jArgument}    ${jArgument_specific}
    ${json_value}    Find Json Children By Value    http(s)-base    ${response.json()[${output}][${jArgument}]}
    Check Common Data On Specific Path    ${json_value}    ${jArgument_specific}    org.opendaylight.iotdm.onem2m.protocols.http.rx.Onem2mHttpBaseIotdmPlugin    http(s)-base    default
    ${json_value}    Find Json Children By Value    mqtt    ${response.json()[${output}][${jArgument}]}
    Check Common Data On Specific Path    ${json_value}    ${jArgument_specific}    org.opendaylight.iotdm.onem2m.protocols.mqtt.rx.Onem2mMqttIotdmPlugin    mqtt    default
    ${json_value}    Find Json Children By Value    ws    ${response.json()[${output}][${jArgument}]}
    Check Common Data On Specific Path    ${json_value}    ${jArgument_specific}    org.opendaylight.iotdm.onem2m.protocols.websocket.rx.Onem2mWebsocketIotdmPlugin    ws    default
    ${json_value}    Find Json Children By Value    coap(s)    ${response.json()[${output}][${jArgument}]}
    Check Common Data On Specific Path    ${json_value}    ${jArgument_specific}    org.opendaylight.iotdm.onem2m.protocols.coap.rx.Onem2mCoapBaseIotdmPlugin    coap(s)    default

Check IoTDM Plugin Data 2
    [Arguments]    ${response}    ${jArgument}    ${jArgument_specific}
    ${json_value}    Find Json Children By Value    Onem2mExample    ${response.json()[${output}][${jArgument}]}
    Check Common Data On Specific Path    ${json_value}    ${jArgument_specific}    org.opendaylight.iotdm.onem2mexample.impl.Onem2mExampleCustomProtocol    Onem2mExample    default

Check IoTDM Plugin Common Data
    [Arguments]    ${response}    ${jArgument}    ${jArgument_specific}    ${test}
    Run Keyword If    '${test}'=='onem2m-plugin-manager-iotdm-plugin-registrations'    Run Keywords    Check IoTDM Plugin Data 1    ${response}    ${jArgument}    ${jArgument_specific}
    ...    AND    Check IoTDM Plugin Data 2    ${response}    ${jArgument}    ${jArgument_specific}
    ...    ELSE IF    '${test}'=='onem2m-plugin-manager-db-api-client-registrations'    Check IoTDM Plugin Data 2    ${response}    ${jArgument}    ${jArgument_specific}
    ...    ELSE IF    '${test}'=='onem2m-plugin-manager-simple-config-client-registrations'    Check IoTDM Plugin Data 2    ${response}    ${jArgument}    ${jArgument_specific}
    ...    ELSE IF    '${test}'=='onem2m-plugin-manager-plugin-data'    Run Keywords    Check IoTDM Plugin Data 1    ${response}    ${jArgument}
    ...    ${jArgument_specific}
    ...    AND    Check IoTDM Plugin Data 2    ${response}    ${jArgument}    ${jArgument_specific}

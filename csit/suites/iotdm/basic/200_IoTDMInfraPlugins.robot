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
${registrations-data}    'registration-data'

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
    ${resp} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-iotdm-plugin-registrations    headers=${headers}
    Set Suite Variable    ${resp}
    Check Response Succesfull With Correct Data    ${resp}    @{list}
    Check Common Data    ${resp}    ${table}    [${instances}][0]    onem2m-plugin-manager-iotdm-plugin-registrations

1.01 Registration parameters of HTTP IoTDM plugin
    [Documentation]    Verifies the default registration of HTTP provider module as IoTDM plugin
    ${jv}    Find Json Children By Value    Onem2mHttpBaseIotdmPlugin    ${resp.json()[${output}][${table}]}
    ${class} =    Set Variable    ${jv[${instances}][0][${common-data}][${class}]}
    ${regs} =    convert to string    ${jv[${instances}][0][${registrations}][0][${registrations-data}]}
    Should Contain    ${class}    Onem2mHttpBaseIotdmPlugin
    Should Contain All Sub Strings    ${regs}    TCP    http    8282    0.0.0.0

1.02 Registration parameters of CoAP IoTDM plugin
    [Documentation]    Verifies the default registration of CoAP provider module as IoTDM plugin
    ${jv}    Find Json Children By Value    Onem2mCoapBaseIotdmPlugin    ${resp.json()[${output}][${table}]}
    ${class} =    Set Variable    ${jv[${instances}][0][${common-data}][${class}]}
    ${regs} =    convert to string    ${jv[${instances}][0][${registrations}][0][${registrations-data}]}
    Should Contain    ${class}    Onem2mCoapBaseIotdmPlugin
    Should Contain All Sub Strings    ${regs}    UDP    coap    5683    0.0.0.0

1.03 Registration parameters of MQTT IoTDM plugin
    [Documentation]    Verifies the default registration of MQTT provider module as IoTDM plugin
    ${jv}    Find Json Children By Value    Onem2mMqttIotdmPlugin    ${resp.json()[${output}][${table}]}
    ${class} =    Set Variable    ${jv[${instances}][0][${common-data}][${class}]}
    ${regs} =    convert to string    ${jv[${instances}][0][${registrations}][0][${registrations-data}]}
    Should Contain    ${class}    Onem2mMqttIotdmPlugin
    Should Contain All Sub Strings    ${regs}    TCP    mqtt    1883    127.0.0.1

1.04 Registration parameters of WS IoTDM plugin
    [Documentation]    Verifies the default registration of WS provider module as IoTDM plugin
    ${jv}    Find Json Children By Value    Onem2mWebsocketIotdmPlugin    ${resp.json()[${output}][${table}]}
    ${class} =    Set Variable    ${jv[${instances}][0][${common-data}][${class}]}
    ${regs} =    convert to string    ${jv[${instances}][0][${registrations}][0][${registrations-data}]}
    Should Contain    ${class}    Onem2mWebsocketIotdmPlugin
    Should Contain All Sub Strings    ${regs}    TCP    websocket    8888    0.0.0.0

1.05 Registration parameters of Onem2mExample IoTDM plugin
    [Documentation]    Verifies the default registration of Onem2mExample as IoTDM plugin
    ${jv}    Find Json Children By Value    Onem2mExampleCustomProtocol    ${resp.json()[${output}][${table}]}
    ${class} =    Set Variable    ${jv[${instances}][0][${common-data}][${class}]}
    ${regs} =    convert to string    ${jv[${instances}][0][${registrations}][0][${registrations-data}]}
    Should Contain    ${class}    Onem2mExampleCustomProtocol
    Should Contain All Sub Strings    ${regs}    TCP    http    8283    0.0.0.0

2.00 Default result of onem2m-plugin-manager-db-api-client-registrations RPC
    [Documentation]    Verifies the result of RPC and looks for Onem2mExample registration
    ${resp} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-db-api-client-registrations    headers=${headers}
    Set Suite Variable    ${resp}    ${resp}
    Check Response Succesfull With Correct Data    ${resp}    Onem2mExample
    Check Common Data    ${resp}    'registered-db-api-client-plugins-table'    ['registered-db-api-client-plugin-instances'][0]['db-api-client-plugin-data']    onem2m-plugin-manager-db-api-client-registrations

2.01 Registration of Onem2mExample as IotdmPluginDbClient
    [Documentation]    Verifies the state of the registration of Onem2mExample plugin
    ${t} =    Set Variable    'registered-db-api-client-plugins-table'
    ${d} =    Set Variable    'db-api-client-plugin-data'
    ${acs} =    Set Variable    'db-api-client-state'
    ${pi} =    Set Variable    'registered-db-api-client-plugin-instances'
    ${jv}    Find Json Children By Value    Onem2mExample    ${resp.json()[${output}][${t}]}
    ${cs} =    convert to string    ${jv[${pi}][0][${d}][${acs}]}
    ${pn} =    Set Variable    ${jv['plugin-name']}
    Should Contain    ${pn}    Onem2mExample
    Should Contain    ${cs}    STARTED

3.00 Default result of onem2m-plugin-manager-simple-config-client-registrations RPC
    [Documentation]    Verifies the result of RPC and looks for Onem2mExample registration
    ${resp} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-simple-config-client-registrations    headers=${headers}
    Set Suite Variable    ${resp}    ${resp}
    Check Response Succesfull With Correct Data    ${resp}    Onem2mExample
    Check Common Data    ${resp}    'registered-simple-config-client-plugins-table'    ['registered-simple-config-client-plugin-instances'][0]    onem2m-plugin-manager-simple-config-client-registrations

4.00 Default result of onem2m-plugin-manager-plugin-data RPC
    [Documentation]    Verifies the result of RPC and looks for data items related to:
    ...    HTTP, CoAP, MQTT, WS and Onem2mExample
    ${resp} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-plugin-data    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    @{list}
    Check Common Data    ${resp}    'onem2m-plugin-manager-plugins-table'    ['onem2m-plugin-manager-plugin-instances'][0]    onem2m-plugin-manager-plugin-data

4.01 Plugin data of HTTP
    [Documentation]    Verifies all plugin data about HTTP provider module plugin
    ${payload} =    Set Variable    {"input": {"plugin-name": "http(s)-base"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}:onem2m-plugin-manager-plugin-data    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    default    http(s)-base    IotdmPlugin    TCP    Exclusive
    ...    8282    "0.0.0.0"    "http"    Onem2mHttpBaseIotdmPlugin    *    "server-security-level":"l0"
    ...    "server-port":8282
    Should Contain X Times    ${resp.content}    "secure-connection":false    3

4.02 Plugin data of CoAP
    [Documentation]    Verifies all plugin data about CoAP provider module plugin
    ${payload} =    Set Variable    {"input": {"plugin-name": "coap(s)"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-plugin-data    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    default    coap(s)    IotdmPlugin    UDP    Exclusive
    ...    5683    "0.0.0.0"    "coap"    Onem2mCoapBaseIotdmPlugin    *

4.03 Plugin data of MQTT
    [Documentation]    Verifies all plugin data about MQTT provider module plugin
    ${payload} =    Set Variable    {"input": {"plugin-name": "mqtt"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-plugin-data    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    default    mqtt    IotdmPlugin    TCP    Exclusive
    ...    1883    "127.0.0.1"    Onem2mMqttIotdmPlugin    *

4.04 Plugin data of WS
    [Documentation]    Verifies all plugin data about WS provider module plugin
    ${payload} =    Set Variable    {"input": {"plugin-name": "ws"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-plugin-data    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    default    ws    websocket    IotdmPlugin    TCP
    ...    Exclusive    8888    "0.0.0.0"    Onem2mWebsocketIotdmPlugin    *

4.05 Plugin data of Onem2mExample
    [Documentation]    Verifies all plugin data about Onem2mExample provider module plugin
    ${payload} =    Set Variable    {"input": {"plugin-name": "Onem2mExample"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-plugin-data    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    IotdmPluginSimpleConfigClient    IotdmPluginDbClient    IotdmPlugin    IotdmPluginConfigurable    STARTED
    ...    default    http    Onem2mExample    IotdmPlugin    TCP    Exclusive
    ...    8283    "0.0.0.0"    Onem2mExampleCustomProtocol    *

5.00 Default result of onem2m-plugin-manager-communication-channels RPC
    [Documentation]    Verifyies if the default communication channels exist
    ${resp} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-communication-channels    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    @{list}

5.01 Communication channel for HTTP plugins
    [Documentation]    Verifies the default instances of HTTP communication channel for HTTP provider and Onem2mExample
    # uses RPC input with protocol-name specified
    ${payload} =    Set Variable    {"input": {"protocol-name": "http"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-communication-channels    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    http(s)-base    "http"    0.0.0.0    8282    8283
    ...    Onem2mExample    TCP    RUNNING    SERVER    default

5.02 Communication channel for CoAP plugins
    [Documentation]    Verifies the default instance of CoAP communication channel for CoAP provider
    # use RPC input with protocol-name specified
    ${payload} =    Set Variable    {"input": {"protocol-name": "coap"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-communication-channels    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    coap(s)    "coap"    0.0.0.0    5683    UDP
    ...    RUNNING    SERVER    default

5.03 Communication channel for MQTT plugins
    [Documentation]    Verifies the default instance of MQTT communication channel for MQTT provider
    # use RPC input with protocol-name specified
    ${payload} =    Set Variable    {"input": {"protocol-name": "mqtt"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-communication-channels    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    mqtt    127.0.0.1    1883    TCP    RUNNING
    ...    CLIENT    default

5.04 Communication channel for WS plugins
    [Documentation]    Verifies the default instance of WS communication channel for WS provider
    # use RPC input with protocol-name specified
    ${payload} =    Set Variable    {"input": {"protocol-name": "websocket"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-communication-channels    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    websocket    "ws"    0.0.0.0    8888    TCP
    ...    INIT    SERVER    default

6.00 Store current outputs of PluginManager RPC calls
    [Documentation]    Stores current PluginManager data which will be used in next test cases
    ${resp} =    RequestsLibrary.Post Request    session    ${PLUGIN_CONTEXT}:onem2m-plugin-manager-plugin-data    headers=${headers}
    Set Suite Variable    ${resp}
    Check Response Succesfull With Correct Data    ${resp}    @{list}

6.01 Change port number of HTTP provider plugin
    [Documentation]    Configures new port number for HTTP provider module and verifies
    ${payload} =    Set Variable    {"input": {"plugin-name": "http(s)-base","instance-name": "default","plugin-simple-config" :{"key-val-list" : [{"cfg-key": "port","cfg-val": "7896"}]}}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-put    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200

6.02 Change port number of CoAP provider plugin
    [Documentation]    Configures new port number for CoAP provider module and verifies
    #todo check current configuration of coap if the feature is added to IoTDM project as in 6.01
    ${payload} =    Set Variable    {"input": {"plugin-name": "coap(s)","instance-name": "default","plugin-simple-config" :{"key-val-list" : [{"cfg-key": "port","cfg-val": "7896"}]}}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-put    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200

6.03 Change port number of MQTT provider plugin
    [Documentation]    Configures new port number for MQTT provider module and verifies
    #todo check current configuration of mqtt if the feature is added to IoTDM project as in 6.01
    ${payload} =    Set Variable    {"input": {"plugin-name": "mqtt","instance-name": "default","plugin-simple-config" :{"key-val-list" : [{"cfg-key": "port","cfg-val": "7896"}]}}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-put    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200

6.04 Change port number of WS provider plugin
    [Documentation]    Configures new port number for WS provider module and verifies
    #todo check current configuration of ws if the feature is added to IoTDM project as in 6.01
    ${payload} =    Set Variable    {"input": {"plugin-name": "ws","instance-name": "default","plugin-simple-config" :{"key-val-list" : [{"cfg-key": "port","cfg-val": "7896"}]}}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-put    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200

6.05 Change port number of Onem2mExample provider plugin
    [Documentation]    Configures new port number for Onem2mExample module using SimpleConfig and verifies
    #todo check current configuration of Onem2mExample if the feature is added to IoTDM project as in 6.01
    ${payload} =    Set Variable    {"input": {"plugin-name": "Onem2mExample","instance-name": "default","plugin-simple-config" :{"key-val-list" : [{"cfg-key": "port","cfg-val": "7896"}]}}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-put    data=${payload}    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200

6.06 Restart IoTDM and verify configuration of all plugins
    [Documentation]    Restarts IoTDM and verifies if the modules still uses new configuration
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-get-startup-config    headers=${headers}
    ${status_code} =    Status Code    ${resp}
    Should Be Equal As Integers    ${status_code}    200
    ${jv}    Find Json Children By Value    coap(s)    ${resp.json()[${output}]['onem2m-simple-config-list']}

6.07 Revert Configurations of all plugins
    [Documentation]    Reverts configuration of all re-configured plugins back to default state
    ${payload} =    Set Variable    {"input": {"plugin-name": "Onem2mExample","instance-name": "default"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-del    data=${payload}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    200

7.00 Test missing configuration of HTTP provider module
    [Documentation]    Tests multiple cases of missing mandatory configuration items of HTTP provider module
    TODO

7.01 Test invalid values in configuration of HTTP provider module
    [Documentation]    Tests multiple cases of invalid values set in configuration of HTTP provider module
    TODO

7.02 Test missing configuration of CoAP provider module
    [Documentation]    Tests multiple cases of missing mandatory configuration items of CoAP provider module
    TODO

7.03 Test invalid values in configuration of CoAP provider module
    [Documentation]    Tests multiple cases of invalid values set in configuration of CoAP provider module
    TODO

7.04 Test missing configuration of MQTT provider module
    [Documentation]    Tests multiple cases of missing mandatory configuration items of MQTT provider module
    TODO

7.05 Test invalid values in configuration of MQTT provider module
    [Documentation]    Tests multiple cases of invalid values set in configuration of MQTT provider module
    TODO

7.06 Test missing configuration of WS provider module
    [Documentation]    Tests multiple cases of missing mandatory configuration items of WS provider module
    TODO

7.07 Test invalid values in configuration of WS provider module
    [Documentation]    Tests multiple cases of invalid values set in configuration of WS provider module
    TODO

7.08 Test conflicting configuration handling
    [Documentation]    Tests configuration of TCP port number for HTTP provider module.
    ...    The new configuration conflicts with configurtion of Onem2mExample plugin module.
    TODO

8.00 Test default configuration for plugins
    [Documentation]    Tests usage of default configuration for IoTDM plugins
    TODO

*** Keywords ***
TODO
    Fail    "Not implemented"

Check Response Succesfull With Correct Data
    [Arguments]    ${resp}    @{checked}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain All Sub Strings    ${resp.content}    @{checked}

Find Json Children By Value
    [Arguments]    ${value}    ${json}
    ${length}    Get Length    ${json}
    : FOR    ${INDEX}    IN RANGE    ${length}
    \    return from keyword if    '''${value}''' in '''${json[${INDEX}]}'''    ${json[${INDEX}]}

Check Common Data On Specific Path
    [Arguments]    ${jv}    ${jArgumentSpecific}    ${check-class}    ${check-name}    ${check-instance-name}
    Log    ${jv}
    ${class} =    Set Variable    ${jv${jArgumentSpecific}[${common-data}][${class}]}
    ${name} =    Set Variable    ${jv${jArgumentSpecific}[${common-data}]['plugin-name']}
    ${instance-name} =    Set Variable    ${jv${jArgumentSpecific}[${common-data}]['plugin-instance-name']}
    Should Be Equal    ${class}    ${check-class}
    Should Be Equal    ${name}    ${check-name}
    Should Be Equal    ${instance-name}    ${check-instance-name}

Test data 1
    [Arguments]    ${resp}    ${jArgument}    ${jArgumentSpecific}
    ${jv}    Find Json Children By Value    http(s)-base    ${resp.json()[${output}][${jArgument}]}
    Check Common Data On Specific Path    ${jv}    ${jArgumentSpecific}    org.opendaylight.iotdm.onem2m.protocols.http.rx.Onem2mHttpBaseIotdmPlugin    http(s)-base    default
    ${jv}    Find Json Children By Value    mqtt    ${resp.json()[${output}][${jArgument}]}
    Check Common Data On Specific Path    ${jv}    ${jArgumentSpecific}    org.opendaylight.iotdm.onem2m.protocols.mqtt.rx.Onem2mMqttIotdmPlugin    mqtt    default
    ${jv}    Find Json Children By Value    ws    ${resp.json()[${output}][${jArgument}]}
    Check Common Data On Specific Path    ${jv}    ${jArgumentSpecific}    org.opendaylight.iotdm.onem2m.protocols.websocket.rx.Onem2mWebsocketIotdmPlugin    ws    default
    ${jv}    Find Json Children By Value    coap(s)    ${resp.json()[${output}][${jArgument}]}
    Check Common Data On Specific Path    ${jv}    ${jArgumentSpecific}    org.opendaylight.iotdm.onem2m.protocols.coap.rx.Onem2mCoapBaseIotdmPlugin    coap(s)    default

Test data 2
    [Arguments]    ${resp}    ${jArgument}    ${jArgumentSpecific}
    ${jv}    Find Json Children By Value    Onem2mTsdrProvider    ${resp.json()[${output}][${jArgument}]}
    Check Common Data On Specific Path    ${jv}    ${jArgumentSpecific}    org.opendaylight.iotdm.onem2m.tsdr.impl.Onem2mTsdrProvider    Onem2mTsdrProvider    default
    ${jv}    Find Json Children By Value    Onem2mSimpleAdapterProvider    ${resp.json()[${output}][${jArgument}]}
    Check Common Data On Specific Path    ${jv}    ${jArgumentSpecific}    org.opendaylight.iotdm.onem2m.simpleadapter.impl.Onem2mSimpleAdapterProvider    Onem2mSimpleAdapterProvider    default

Test data 3
    [Arguments]    ${resp}    ${jArgument}    ${jArgumentSpecific}
    ${jv}    Find Json Children By Value    Onem2mExample    ${resp.json()[${output}][${jArgument}]}
    Check Common Data On Specific Path    ${jv}    ${jArgumentSpecific}    org.opendaylight.iotdm.onem2mexample.impl.Onem2mExampleCustomProtocol    Onem2mExample    default

Check Common Data
    [Arguments]    ${resp}    ${jArgument}    ${jArgumentSpecific}    ${test}
    Run Keyword If    '${test}'=='onem2m-plugin-manager-iotdm-plugin-registrations'    Run Keywords    Test data 1    ${resp}    ${jArgument}    ${jArgumentSpecific}
    ...    AND    Test data 3    ${resp}    ${jArgument}    ${jArgumentSpecific}
    ...    ELSE IF    '${test}'=='onem2m-plugin-manager-db-api-client-registrations'    Run Keywords    Test data 3    ${resp}    ${jArgument}
    ...    ${jArgumentSpecific}
    ...    AND    Test data 2    ${resp}    ${jArgument}    ${jArgumentSpecific}
    ...    ELSE IF    '${test}'=='onem2m-plugin-manager-simple-config-client-registrations'    Test data 3    ${resp}    ${jArgument}    ${jArgumentSpecific}
    ...    ELSE IF    '${test}'=='onem2m-plugin-manager-plugin-data'    Run Keywords    Test data 1    ${resp}    ${jArgument}
    ...    ${jArgumentSpecific}
    ...    AND    Test data 2    ${resp}    ${jArgument}    ${jArgumentSpecific}
    ...    AND    Test data 3    ${resp}    ${jArgument}    ${jArgumentSpecific}

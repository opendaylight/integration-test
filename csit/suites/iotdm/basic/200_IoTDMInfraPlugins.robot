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
${REST_CONTEXT}    /restconf/operations/onem2m-plugin-manager
${o}              'output'
${ript}           'registered-iotdm-plugins-table'
${ripi}           'registered-iotdm-plugin-instances'
${icpd}           'iotdm-common-plugin-data'
${pc}             'plugin-class'
${ipr}            'iotdm-plugin-registrations'
${rd}             'registration-data'

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
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}:onem2m-plugin-manager-iotdm-plugin-registrations    headers=${headers}
    Set Suite Variable    ${resp}
    Check Response Succesfull With Correct Data    ${resp}    @{list}

1.01 Registration parameters of HTTP IoTDM plugin
    [Documentation]    Verifies the default registration of HTTP provider module as IoTDM plugin
    Log    ${resp.content}
    ${jv}    find json value by key    Onem2mHttpBaseIotdmPlugin    ${resp.json()[${o}][${ript}]}
    ${pc} =    Set Variable    ${jv[${ripi}][0][${icpd}][${pc}]}
    ${regs} =    convert to string    ${jv[${ripi}][0][${ipr}][0][${rd}]}
    Should Contain All Sub Strings    ${regs}    TCP    http    8282    0.0.0.0
    Should Contain    ${pc}    Onem2mHttpBaseIotdmPlugin

1.02 Registration parameters of CoAP IoTDM plugin
    [Documentation]    Verifies the default registration of CoAP provider module as IoTDM plugin
    ${jv}    find json value by key    Onem2mCoapBaseIotdmPlugin    ${resp.json()[${o}][${ript}]}
    ${pc} =    Set Variable    ${jv[${ripi}][0][${icpd}][${pc}]}
    ${regs} =    convert to string    ${jv[${ripi}][0][${ipr}][0][${rd}]}
    Should Contain All Sub Strings    ${regs}    UDP    coap    5683    0.0.0.0
    Should Contain    ${pc}    Onem2mCoapBaseIotdmPlugin

1.03 Registration parameters of MQTT IoTDM plugin
    [Documentation]    Verifies the default registration of MQTT provider module as IoTDM plugin
    ${jv}    find json value by key    Onem2mMqttIotdmPlugin    ${resp.json()[${o}][${ript}]}
    ${pc} =    Set Variable    ${jv[${ripi}][0][${icpd}][${pc}]}
    ${regs} =    convert to string    ${jv[${ripi}][0][${ipr}][0][${rd}]}
    Should Contain All Sub Strings    ${regs}    TCP    mqtt    1883    127.0.0.1
    Should Contain    ${pc}    Onem2mMqttIotdmPlugin

1.04 Registration parameters of WS IoTDM plugin
    [Documentation]    Verifies the default registration of WS provider module as IoTDM plugin
    ${jv}    find json value by key    Onem2mWebsocketIotdmPlugin    ${resp.json()[${o}][${ript}]}
    ${pc} =    Set Variable    ${jv[${ripi}][0][${icpd}][${pc}]}
    ${regs} =    convert to string    ${jv[${ripi}][0][${ipr}][0][${rd}]}
    Should Contain All Sub Strings    ${regs}    TCP    websocket    8888    0.0.0.0
    Should Contain    ${pc}    Onem2mWebsocketIotdmPlugin

1.05 Registration parameters of Onem2mExample IoTDM plugin
    [Documentation]    Verifies the default registration of Onem2mExample as IoTDM plugin
    ${jv}    find json value by key    Onem2mExampleCustomProtocol    ${resp.json()[${o}][${ript}]}
    ${pc} =    Set Variable    ${jv[${ripi}][0][${icpd}][${pc}]}
    ${regs} =    convert to string    ${jv[${ripi}][0][${ipr}][0][${rd}]}
    Should Contain All Sub Strings    ${regs}    TCP    http    8283    0.0.0.0
    Should Contain    ${pc}    Onem2mExampleCustomProtocol

2.00 Default result of onem2m-plugin-manager-db-api-client-registrations RPC
    [Documentation]    Verifies the result of RPC and looks for Onem2mExample registration
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}:onem2m-plugin-manager-db-api-client-registrations    headers=${headers}
    Set Suite Variable    ${resp}    ${resp}
    Check Response Succesfull With Correct Data    ${resp}    Onem2mExample

2.01 Registration of Onem2mExample as IotdmPluginDbClient
    [Documentation]    Verifies the state of the registration of Onem2mExample plugin
    ${db-table} =    Set Variable    'registered-db-api-client-plugins-table'
    ${db-data} =    Set Variable    'db-api-client-plugin-data'
    ${db-client-state} =    Set Variable    'db-api-client-state'
    ${db-instances} =    Set Variable    'registered-db-api-client-plugin-instances'
    ${jv}    find json value by key    Onem2mExample    ${resp.json()[${o}][${db-table}]}
    ${cs} =    convert to string    ${jv[${db-instances}][0][${db-data}][${db-client-state}]}
    ${name} =    Set Variable    ${jv['plugin-name']}
    Should Contain    ${name}    Onem2mExample
    Should Contain    ${cs}    STARTED

3.00 Default result of onem2m-plugin-manager-simple-config-client-registrations RPC
    [Documentation]    Verifies the result of RPC and looks for Onem2mExample registration
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}:onem2m-plugin-manager-simple-config-client-registrations    headers=${headers}
    Set Suite Variable    ${resp}    ${resp}
    Check Response Succesfull With Correct Data    ${resp}    Onem2mExample

3.01 Registration of Onem2mExample as IotdmSimpleConfigClient
    [Documentation]    Verifies the state of the registration of Onem2mExample plugin
    TODO

4.00 Default result of onem2m-plugin-manager-plugin-data RPC
    [Documentation]    Verifies the result of RPC and looks for data items related to:
    ...    HTTP, CoAP, MQTT, WS and Onem2mExample
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}:onem2m-plugin-manager-plugin-data    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    @{list}

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
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}:onem2m-plugin-manager-plugin-data    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    default    coap(s)    IotdmPlugin    UDP    Exclusive
    ...    5683    "0.0.0.0"    "coap"    Onem2mCoapBaseIotdmPlugin    *

4.03 Plugin data of MQTT
    [Documentation]    Verifies all plugin data about MQTT provider module plugin
    ${payload} =    Set Variable    {"input": {"plugin-name": "mqtt"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}:onem2m-plugin-manager-plugin-data    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    default    mqtt    IotdmPlugin    TCP    Exclusive
    ...    1883    "127.0.0.1"    Onem2mMqttIotdmPlugin    *

4.04 Plugin data of WS
    [Documentation]    Verifies all plugin data about WS provider module plugin
    ${payload} =    Set Variable    {"input": {"plugin-name": "ws"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}:onem2m-plugin-manager-plugin-data    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    default    ws    websocket    IotdmPlugin    TCP
    ...    Exclusive    8888    "0.0.0.0"    Onem2mWebsocketIotdmPlugin    *

4.05 Plugin data of Onem2mExample
    [Documentation]    Verifies all plugin data about Onem2mExample provider module plugin
    ${payload} =    Set Variable    {"input": {"plugin-name": "Onem2mExample"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}:onem2m-plugin-manager-plugin-data    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    IotdmPluginSimpleConfigClient    IotdmPluginDbClient    IotdmPluginConfigurable    STARTED    default
    ...    http    Onem2mExample    IotdmPlugin    TCP    IotdmPlugin    Exclusive
    ...    8283    "0.0.0.0"    Onem2mExampleCustomProtocol    *

5.00 Default result of onem2m-plugin-manager-communication-channels RPC
    [Documentation]    Verifyies if the default communication channels exist
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}:onem2m-plugin-manager-communication-channels    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    @{list}

5.01 Communication channel for HTTP plugins
    [Documentation]    Verifies the default instances of HTTP communication channel for HTTP provider and Onem2mExample
    # uses RPC input with protocol-name specified
    ${payload} =    Set Variable    {"input": {"protocol-name": "http"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}:onem2m-plugin-manager-communication-channels    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    http(s)-base    "http"    0.0.0.0    8282    8283
    ...    Onem2mExample    TCP    RUNNING    SERVER    default

5.02 Communication channel for CoAP plugins
    [Documentation]    Verifies the default instance of CoAP communication channel for CoAP provider
    # use RPC input with protocol-name specified
    ${payload} =    Set Variable    {"input": {"protocol-name": "coap"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}:onem2m-plugin-manager-communication-channels    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    coap(s)    "coap"    0.0.0.0    5683    UDP
    ...    RUNNING    SERVER    default

5.03 Communication channel for MQTT plugins
    [Documentation]    Verifies the default instance of MQTT communication channel for MQTT provider
    # use RPC input with protocol-name specified
    ${payload} =    Set Variable    {"input": {"protocol-name": "mqtt"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}:onem2m-plugin-manager-communication-channels    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    mqtt    127.0.0.1    1883    TCP    RUNNING
    ...    CLIENT    default

5.04 Communication channel for WS plugins
    [Documentation]    Verifies the default instance of WS communication channel for WS provider
    # use RPC input with protocol-name specified
    ${payload} =    Set Variable    {"input": {"protocol-name": "websocket"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}:onem2m-plugin-manager-communication-channels    data=${payload}    headers=${headers}
    Check Response Succesfull With Correct Data    ${resp}    websocket    "ws"    0.0.0.0    8888    TCP
    ...    INIT    SERVER    default

6.00 Store current outputs of PluginManager RPC calls
    [Documentation]    Stores current PluginManager data which will be used in next test cases
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}:onem2m-plugin-manager-plugin-data    headers=${headers}
    TODO
    Set Suite Variable    ${resp}
    Check Response Succesfull With Correct Data    ${resp}    @{list}

6.01 Change port number of HTTP provider plugin
    [Documentation]    Configures new port number for HTTP provider module and verifies
    TODO
    ${payload} =    Set Variable    {"input": {"protocol-name": "websocket"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}:onem2m-plugin-manager-communication-channels    data=${payload}    headers=${headers}

6.02 Change port number of CoAP provider plugin
    [Documentation]    Configures new port number for CoAP provider module and verifies
    TODO

6.03 Change port number of MQTT provider plugin
    [Documentation]    Configures new port number for MQTT provider module and verifies
    TODO

6.04 Change port number of WS provider plugin
    [Documentation]    Configures new port number for WS provider module and verifies
    TODO

6.05 Change port number of Onem2mExample provider plugin
    [Documentation]    Configures new port number for Onem2mExample module using SimpleConfig and verifies
    TODO

6.06 Restart IoTDM and verify configuration of all plugins
    [Documentation]    Restarts IoTDM and verifies if the modules still uses new configuration
    TODO

6.07 Revert Configurations of all plugins
    [Documentation]    Reverts configuration of all re-configured plugins back to default state
    TODO
    ${payload} =    Set Variable    {"input": {"plugin-name": "Onem2mExample","instance-name": "default"}}
    ${resp} =    RequestsLibrary.Post Request    session    ${REST_CONTEXT}:onem2m-plugin-manager-communication-channels    data=${payload}    headers=${headers}
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

Find Json Value By Key
    [Arguments]    ${key}    ${json}
    ${length}    Get Length    ${json}
    : FOR    ${INDEX}    IN RANGE    ${length}
    \    return from keyword if    '''${key}''' in '''${json[${INDEX}]}'''    ${json[${INDEX}]}

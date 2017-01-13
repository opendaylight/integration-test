*** Settings ***
Documentation     Test suite testing IoTDM PluginManager RPC calls registrations of default plugins and
...               communication channels and re-configuration of port of registered plugins
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/IoTDMUtil.robot

*** Variables ***
${REST_CONTEXT}    /restconf/operations/onem2m-plugin-manager
${headers} =    Create Dictionary    Content-Type=application/json    Authorization=Basic YWRtaW46YWRtaW4=

*** Test Cases ***
1.00 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC
    [Documentation]    Verifies if the RPC call result has set valid result code and
    ...                if it includes items of all default plugins: (HTTP, CoAP, MQTT, WS, Onem2mExample)
    ${headers} =    Create Dictionary    Content-Type=application/json    Authorization=Basic YWRtaW46YWRtaW4=
    ${resp} =   RequestsLibrary.Post Request    session
    ...    ${REST_CONTEXT}:onem2m-plugin-manager-iotdm-plugin-registrations    headers=${headers}
    Set Suite Variable   ${global_resp_1}    ${resp}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain All Sub Strings    ${resp.content}    http(s)-base    ws    mqtt    Onem2mExample    coap(s)

1.01 Registration parameters of HTTP IoTDM plugin
    [Documentation]    Verifies the default registration of HTTP provider module as IoTDM plugin
    Should Contain    ${global_resp_1.content}    registered-iotdm-plugin-instances

1.02 Registration parameters of CoAP IoTDM plugin
    [Documentation]    Verifies the default registration of CoAP provider module as IoTDM plugin
    Should Contain    ${global_resp_1.content}    registered-iotdm-plugin-instances

1.03 Registration parameters of MQTT IoTDM plugin
    [Documentation]    Verifies the default registration of MQTT provider module as IoTDM plugin
    Should Contain    ${global_resp_1.content}    registered-iotdm-plugin-instances

1.04 Registration parameters of WS IoTDM plugin
    [Documentation]    Verifies the default registration of WS provider module as IoTDM plugin
    Should Contain    ${global_resp_1.content}    registered-iotdm-plugin-instances

1.05 Registration parameters of Onem2mExample IoTDM plugin
    [Documentation]    Verifies the default registration of Onem2mExample as IoTDM plugin
    Should Contain    ${global_resp_1.content}    registered-iotdm-plugin-instances

2.00 Default result of onem2m-plugin-manager-db-api-client-registrations RPC
    [Documentation]    Verifies the result of RPC and looks for Onem2mExample registration
    ${headers} =    Create Dictionary    Content-Type=application/json    Authorization=Basic YWRtaW46YWRtaW4=
    ${resp} =   RequestsLibrary.Post Request    session
    ...    ${REST_CONTEXT}:onem2m-plugin-manager-db-api-client-registrations    headers=${headers}
    Set Suite Variable   ${global_resp_2}    ${resp}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain All Sub Strings    ${resp.content}    Onem2mExample

2.01 Registration of Onem2mExample as IotdmPluginDbClient
    [Documentation]    Verifies the state of the registration of Onem2mExample plugin
    Should Contain    ${global_resp_2.content}    registered-db-api-client-plugin-instances

3.00 Default result of onem2m-plugin-manager-simple-config-client-registrations RPC
    [Documentation]    Verifies the result of RPC and looks for Onem2mExample registration
    ${headers} =    Create Dictionary    Content-Type=application/json    Authorization=Basic YWRtaW46YWRtaW4=
    ${resp} =   RequestsLibrary.Post Request    session
    ...    ${REST_CONTEXT}:onem2m-plugin-manager-simple-config-client-registrations    headers=${headers}
    Set Suite Variable   ${global_resp_3}    ${resp}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain All Sub Strings    ${resp.content}    Onem2mExample

3.01 Registration of Onem2mExample as IotdmSimpleConfigClient
    [Documentation]    Verifies the state of the registration of Onem2mExample plugin
    Should Contain    ${global_resp_3.content}    registered-simple-config-client-plugin-instances

4.00 Default result of onem2m-plugin-manager-plugin-data RPC
    [Documentation]    Verifies the result of RPC and looks for data items related to:
    ...                HTTP, CoAP, MQTT, WS and Onem2mExample
    ${headers} =    Create Dictionary    Content-Type=application/json    Authorization=Basic YWRtaW46YWRtaW4=
    ${resp} =   RequestsLibrary.Post Request    session
    ...    ${REST_CONTEXT}:onem2m-plugin-manager-plugin-data    headers=${headers}
    Set Suite Variable   ${global_resp_4}    ${resp}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain All Sub Strings    ${resp.content}    http(s)-base    coap(s)    mqtt    ws    Onem2mExample

4.01 Plugin data of HTTP
    [Documentation]    Verifies all plugin data about HTTP provider module plugin
    Should Contain    ${global_resp_4.content}    onem2m-plugin-manager-plugin-instances

4.02 Plugin data of CoAP
    [Documentation]    Verifies all plugin data about CoAP provider module plugin
    Should Contain    ${global_resp_4.content}    onem2m-plugin-manager-plugin-instances

4.03 Plugin data of MQTT
    [Documentation]    Verifies all plugin data about MQTT provider module plugin
    Should Contain    ${global_resp_4.content}    onem2m-plugin-manager-plugin-instances

4.04 Plugin data of WS
    [Documentation]    Verifies all plugin data about WS provider module plugin
    Should Contain    ${global_resp_4.content}    onem2m-plugin-manager-plugin-instances

4.05 Plugin data of Onem2mExample
    [Documentation]    Verifies all plugin data about Onem2mExample provider module plugin
    Should Contain    ${global_resp_4.content}    onem2m-plugin-manager-plugin-instances

5.00 Default result of onem2m-plugin-manager-communication-channels RPC
    [Documentation]    Verifyies the default communication channels instantiated by PluginManager
    ${headers} =    Create Dictionary    Content-Type=application/json    Authorization=Basic YWRtaW46YWRtaW4=
    ${resp} =   RequestsLibrary.Post Request    session
    ...    ${REST_CONTEXT}:onem2m-plugin-manager-communication-channels    headers=${headers}
    Set Suite Variable   ${global_resp_5}    ${resp}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain All Sub Strings    ${resp.content}    http(s)-base    coap(s)    mqtt    ws    Onem2mExample

5.01 Communication channel for HTTP plugins
    [Documentation]    Verifies the default instances of HTTP communication channel for HTTP provider and Onem2mExample
    # uses RPC input with protocol-name specified
    Should Contain    ${global_resp_5.content}    http(s)-base
    Should Contain    ${global_resp_5.content}    Onem2mExample

5.02 Communication channel for CoAP plugins
    [Documentation]    Verifies the default instance of CoAP communication channel for CoAP provider
    # use RPC input with protocol-name specified
    Should Contain    ${global_resp_5.content}    coap(s)

5.03 Communication channel for MQTT plugins
    [Documentation]    Verifies the default instance of MQTT communication channel for MQTT provider
    # use RPC input with protocol-name specified
    Should Contain    ${global_resp_5.content}    mqtt

5.04 Communication channel for WS plugins
    [Documentation]    Verifies the default instance of WS communication channel for WS provider
    # use RPC input with protocol-name specified
    Should Contain    ${global_resp_5.content}    ws

6.00 Store current outputs of PluginManager RPC calls
    [Documentation]    Stores current PluginManager data which will be used in next test cases
    TODO

6.01 Change port number of HTTP provider plugin
    [Documentation]    Configures new port number for HTTP provider module and verifies
    TODO

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

6.06 Revert Configurations of all plugins
    [Documentation]    Reverts configuration of all re-configured plugins back to default state
    TODO

*** Keywords ***
TODO
    Fail    "Not implemented"

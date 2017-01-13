*** Settings ***
Documentation     Test suite testing IoTDM PluginManager RPC calls registrations of default plugins and
...               communication channels and re-configuration of port of registered plugins
Suite Setup       Start
Suite Teardown    Stop
Library           RequestsLibrary
Library           Process
Library           ../../../libraries/Common.py
Library           ../../../libraries/criotdm.py
Resource          ../../../variables/Variables.robot
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
${odl_jolokia_install}    {    "input": {    "karaf-feature-loader-name" : "KarafFeatureLoaderDefault",    "karaf-archive-url" : "https://nexus.opendaylight.org/service/local/repo_groups/staging/content/org/opendaylight/controller/features-extras/1.8.0-Carbon/features-extras-1.8.0-Carbon.kar",    "features-to-install": [    {    "feature-name" : "odl-jolokia"
...               }    ]    }    }
${odl_jolokia_uninstall}    {    "input": {    "karaf-feature-loader-name" : "KarafFeatureLoaderDefault",    "karaf-archive-name" : "features-extras-1.8.0-Carbon"    }    }

*** Test Cases ***
1.00 Default result of onem2m-plugin-manager-plugin-data RPC
    [Documentation]    Verifies the result of RPC and looks for data items related to:
    ...    HTTP, CoAP, MQTT, WS and Onem2mExample
    BuiltIn.Wait_Until_Keyword_Succeeds    15 sec    1 sec    Verify Default PluginData Output

1.01 Plugin data of HTTP - filtered
    [Documentation]    Verifies all plugin data about HTTP provider module plugin
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/http/filtered    verify=True

1.02 Plugin data of CoAP - filtered
    [Documentation]    Verifies all plugin data about CoAP provider module plugin
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/coap/filtered    verify=True

1.03 Plugin data of MQTT - filtered
    [Documentation]    Verifies all plugin data about MQTT provider module plugin
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/mqtt/filtered    verify=True

1.04 Plugin data of WS - filtered
    [Documentation]    Verifies all plugin data about WS provider module plugin
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/ws/filtered    verify=True

1.05 Plugin data of Onem2mExample - filtered
    [Documentation]    Verifies all plugin data about Onem2mExample provider module plugin
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/onem2m_example/filtered    verify=True

1.06 Plugin data of TSDR - filtered
    [Documentation]    Verifies all plugin data about Onem2mExample provider module plugin
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/tsdr/filtered    verify=True

1.07 Plugin data of SimpleAdapter - filtered
    [Documentation]    Verifies all plugin data about Onem2mExample provider module plugin
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/simple_adapter/filtered    verify=True

2.00.01 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC - HTTP
    [Documentation]    Verifies if the result of the RPC contains correct data about HTTP
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/iotdm_plugin_registrations/http/default    verify=True    subset_at_level=${3}

2.00.02 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC - CoAP
    [Documentation]    Verifies if the result of the RPC contains correct data about CoAP
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/iotdm_plugin_registrations/coap/default    verify=True    subset_at_level=${3}

2.00.03 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC - MQTT
    [Documentation]    Verifies if the result of the RPC contains correct data about MQTT
    TemplatedRequests.Post_As_Json_Templated_Check_Not_Included    folder=${VAR_BASE}/iotdm_plugin_registrations/mqtt/default

2.00.04 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC - WS
    [Documentation]    Verifies if the result of the RPC contains correct data about ws
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/iotdm_plugin_registrations/ws/default    verify=True    subset_at_level=${3}

2.00.05 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC - Onem2mExample
    [Documentation]    Verifies if the result of the RPC contains correct data about Onem2mExample
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/iotdm_plugin_registrations/onem2m_example/default    verify=True    subset_at_level=${3}

2.01.01 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC filtered - HTTP
    [Documentation]    Verifies if the result of the RPC with input filter contains correct data about HTTP only
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/iotdm_plugin_registrations/http/filtered    verify=True

2.01.02 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC filtered - CoAP
    [Documentation]    Verifies if the result of the RPC with input filter contains correct data about CoAP only
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/iotdm_plugin_registrations/coap/filtered    verify=True

2.01.03 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC filtered - MQTT
    [Documentation]    Verifies if the result of the RPC with input filter contains correct data about MQTT only
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/iotdm_plugin_registrations/mqtt/filtered    verify=True

2.01.04 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC filtered - WS
    [Documentation]    Verifies if the result of the RPC with input filter contains correct data about WS only
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/iotdm_plugin_registrations/ws/filtered    verify=True

2.01.05 Default result of onem2m-plugin-manager-iotdm-plugin-registrations RPC filtered - Onem2mExample
    [Documentation]    Verifies if the result of the RPC with input filter contains correct data about Onem2mExample only
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/iotdm_plugin_registrations/onem2m_example/filtered    verify=True

3.00.01 Default result of onem2m-plugin-manager-db-api-client-registrations RPC - Onem2mExample
    [Documentation]    Verifies the result of RPC and looks for Onem2mExample registration
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/db_registrations/onem2m_example/filtered    verify=True

3.00.02 Default result of onem2m-plugin-manager-db-api-client-registrations RPC - TSDR
    [Documentation]    Verifies the result of RPC and looks for TSDR registration
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/db_registrations/tsdr/default    verify=True    subset_at_level=${3}

3.00.03 Default result of onem2m-plugin-manager-db-api-client-registrations RPC - SimpleAdapter
    [Documentation]    Verifies the result of RPC and looks for SimpleAdapter registration
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/db_registrations/simple_adapter/default    verify=True    subset_at_level=${3}

3.01.00 Default result of onem2m-plugin-manager-db-api-client-registrations RPC - filtered Onem2mExample
    [Documentation]    Verifies result of RPC with input filter for Onem2mExample
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/db_registrations/onem2m_example/filtered    verify=True

3.01.01 Default result of onem2m-plugin-manager-db-api-client-registrations RPC - filtered TSDR
    [Documentation]    Verifies result of RPC with input filter for TSDR
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/db_registrations/tsdr/filtered    verify=True

3.01.02 Default result of onem2m-plugin-manager-db-api-client-registrations RPC - filtered SimpleAdapter
    [Documentation]    Verifies result of RPC with input filter for SimpleAdapter
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/db_registrations/simple_adapter/filtered    verify=True

4.00.01 Default result of onem2m-plugin-manager-simple-config-client-registrations RPC - Onem2mExample
    [Documentation]    Verifies the result of RPC and looks for Onem2mExample registration
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig_registrations/default    verify=True    subset_at_level=${3}

4.00.02 Default result of onem2m-plugin-manager-simple-config-client-registrations RPC - filtered Onem2mExample
    [Documentation]    Verifies the result of RPC with input filter and looks for Onem2mExample registration only
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig_registrations/filtered    verify=True

5.00.01 Default Communication channel for HTTP plugin
    [Documentation]    Verifies the default instance of HTTP communication channel for HTTP provider
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/communication_channels/http/default    verify=True    subset_at_level=${7}

5.00.02 Default Communication channel for CoAP plugin
    [Documentation]    Verifies the default instance of CoAP communication channel for CoAP provider
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/communication_channels/coap/default    verify=True    subset_at_level=${7}

5.00.03 Default Communication channel for MQTT plugin
    [Documentation]    Verifies the default instance of MQTT communication channel for MQTT provider
    TemplatedRequests.Post_As_Json_Templated_Check_Not_Included    folder=${VAR_BASE}/communication_channels/mqtt/default

5.00.04 Default Communication channel for WS plugin
    [Documentation]    Verifies the default instance of WS communication channel for WS provider
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/communication_channels/ws/default    verify=True    subset_at_level=${7}

5.00.05 Default Communication channel for Onem2mExample plugin
    [Documentation]    Verifies the default instance of HTTP communication channel for Onem2mExample plugin
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/communication_channels/onem2m_example/default    verify=True    subset_at_level=${7}

5.01.01 Default Communication channel for HTTP plugin - filtered
    [Documentation]    Verifies the default instances of HTTP communication channel for HTTP provider using RPC with input filter
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/communication_channels/http/filtered    verify=True

5.01.02 Default Communication channel for CoAP plugin - filtered
    [Documentation]    Verifies the default instance of CoAP communication channel for CoAP provider using RPC with input filter
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/communication_channels/coap/filtered    verify=True

5.01.03 Default Communication channel for MQTT plugin - filtered
    [Documentation]    Verifies the default instance of MQTT communication channel for MQTT provider using RPC with input filter
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/communication_channels/mqtt/filtered    verify=True

5.01.04 Default Communication channel for WS plugin - filtered
    [Documentation]    Verifies the default instance of WS communication channel for WS provider using RPC with input filter
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/communication_channels/ws/filtered    verify=True

5.01.05 Default Communication channel for Onem2mExample plugin - filtered
    [Documentation]    Verifies the default instance of HTTP communication channel for Onem2mExample plugin using RPC with input filter
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/communication_channels/onem2m_example/filtered    verify=True

6.00.01 Change port number of HTTP provider plugin
    [Documentation]    Configures new port number for HTTP provider module and verifies
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/put_http/change_port
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_BASE}/get_http    verify=True
    Verify PluginData After Reconfiguration of HTTP

6.00.02 Check HTTP communication using new port
    [Documentation]    Sends GET request to the new port and verifies if it is possible to use the new configured port
    ...    for HTTP communication and verifies also if the old port is not opened for HTTP communication.
    [Tags]    not-implemented    exclude
    TODO

6.01.01 Change port number of CoAP provider plugin
    [Documentation]    Configures new port number for CoAP provider module and verifies
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/put_coap/change_port
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
    #TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/put_mqtt
    #TODO: this will not work because we need to have MQTT broker provisioned in cluster
    #TODO: this needs to be solved with releng team
    TODO

6.02.01 Change port number of MQTT provider plugin
    [Documentation]    Configures new port number for MQTT provider module and verifies
    [Tags]    not-implemented    exclude
    #TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/put_mqtt/change_port
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
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/put_onem2m_example/change_port
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/get_onem2m_example    verify=True
    Verify PluginData After Reconfiguration of Onem2mExample

6.05 Restart IoTDM and verify configuration of all plugins
    [Documentation]    Restarts IoTDM and verifies if the modules still uses new configuration
    [Tags]    persistence
    [Setup]    Install ODL Jolokia
    Restart Cluster
    BuiltIn.Wait_Until_Keyword_Succeeds    60 sec    1 sec    Verify PluginData After Reconfiguration of All Modules
    #todo change for ws port in ${VAR_BASE}/plugin_data/changed_data when feature is added to IoTDM project
    [Teardown]    Uninstall ODL Jolokia

6.06 Revert Configurations of all plugins
    [Documentation]    Reverts configuration of all re-configured plugins back to default state
    TemplatedRequests.Delete_Templated    folder=${VAR_BASE}/put_http/change_port
    TemplatedRequests.Delete_Templated    folder=${VAR_BASE}/put_coap/change_port
    #TODO revert also MQTT when issues solved
    #    TemplatedRequests.Delete_Templated    folder=${VAR_BASE}/put_mqtt/change_port
    #TODO revert for ws when feature is added to IoTDM project
    #    TemplatedRequests.Delete_Templated    folder=${VAR_BASE}/put_ws/change_port
    # Calls RPC for configuration delete
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/put_onem2m_example

7.00 Test missing configuration of HTTP provider module
    [Documentation]    Tests multiple cases of missing mandatory configuration items of HTTP provider module
    ${uri} =    Set Variable    restconf/config/onem2m-protocol-http:onem2m-protocol-http-providers/HttpProviderDefault
    # Missing security-level
    ${payload} =    Set Variable    {"onem2m-protocol-http-providers" : [{"http-provider-instance-name": "HttpProviderDefault","router-plugin-config": {"secure-connection": false},"server-config": {"secure-connection": false,"server-port": 7777},"notifier-plugin-config": {"secure-connection": false}}]}
    Verify Negative Configuration Scenario    ${uri}    ${payload}    status_code=500
    # Missing secure-connection
    ${payload} =    Set Variable    {"onem2m-protocol-http-providers" : [{"http-provider-instance-name": "HttpProviderDefault","router-plugin-config": {"secure-connection": false},"server-config": {"server-security-level": "l0","server-port": 7777},"notifier-plugin-config": {"secure-connection": false}}]}
    Verify Negative Configuration Scenario    ${uri}    ${payload}    status_code=500
    # Missing server-port
    ${payload} =    Set Variable    {"onem2m-protocol-http-providers" : [{"http-provider-instance-name": "HttpProviderDefault","router-plugin-config": {"secure-connection": false},"server-config": {"server-security-level": "l0","secure-connection": false},"notifier-plugin-config": {"secure-connection": false}}]}
    Verify Negative Configuration Scenario    ${uri}    ${payload}    status_code=500

7.01 Test invalid values in configuration of HTTP provider module
    [Documentation]    Tests multiple cases of invalid values set in configuration of HTTP provider module
    ${uri} =    Set Variable    restconf/config/onem2m-protocol-http:onem2m-protocol-http-providers/HttpProviderDefault
    # Invalid server-port
    ${payload} =    Set Variable    {"onem2m-protocol-http-providers" : [{"http-provider-instance-name": "HttpProviderDefault","router-plugin-config": {"secure-connection": false},"server-config": {"secure-connection": false,"server-security-level": "l0","server-port": 82828},"notifier-plugin-config": {"secure-connection": false}}]}
    Verify Negative Configuration Scenario    ${uri}    ${payload}    status_code=400
    # Invalid security-level
    ${payload} =    Set Variable    {"onem2m-protocol-http-providers" : [{"http-provider-instance-name": "HttpProviderDefault","router-plugin-config": {"secure-connection": false},"server-config": {"secure-connection": false,"server-security-level": "l4","server-port": 8282},"notifier-plugin-config": {"secure-connection": false}}]}
    Verify Negative Configuration Scenario    ${uri}    ${payload}    status_code=400
    # Invalid secure-connection
    ${payload} =    Set Variable    {"onem2m-protocol-http-providers" : [{"http-provider-instance-name": "HttpProviderDefault","router-plugin-config": {"secure-connection": false},"server-config": {"secure-connection": "asds","server-security-level": "l0","server-port": 8282},"notifier-plugin-config": {"secure-connection": false}}]}
    Verify Negative Configuration Scenario    ${uri}    ${payload}    status_code=400

7.02 Test missing configuration of CoAP provider module
    [Documentation]    Tests multiple cases of missing mandatory configuration items of CoAP provider module
    ${uri} =    Set Variable    restconf/config/onem2m-protocol-coap:onem2m-protocol-coap-providers/CoapProviderDefault
    # Missing security-level
    ${payload} =    Set Variable    {"onem2m-protocol-coap-providers": [{"coap-provider-instance-name": "CoapProviderDefault","server-config": {"server-port": 5683,"secure-connection": "false"},"notifier-plugin-config": {"secure-connection": "false"},"router-plugin-config": {"secure-connection": "false"}}]}
    Verify Negative Configuration Scenario    ${uri}    ${payload}    status_code=500
    # Missing secure-connection
    ${payload} =    Set Variable    {"onem2m-protocol-coap-providers": [{"coap-provider-instance-name": "CoapProviderDefault","server-config": {"server-port": 5683,"server-security-level": "l0"},"notifier-plugin-config": {"secure-connection": "false"},"router-plugin-config": {"secure-connection": "false"}}]}
    Verify Negative Configuration Scenario    ${uri}    ${payload}    status_code=500
    # Missing server-port
    ${payload} =    Set Variable    {"onem2m-protocol-coap-providers": [{"coap-provider-instance-name": "CoapProviderDefault","server-config": {"secure-connection": "false","server-security-level": "l0"},"notifier-plugin-config": {"secure-connection": "false"},"router-plugin-config": {"secure-connection": "false"}}]}
    Verify Negative Configuration Scenario    ${uri}    ${payload}    status_code=500

7.03 Test invalid values in configuration of CoAP provider module
    [Documentation]    Tests multiple cases of invalid values set in configuration of CoAP provider module
    ${uri} =    Set Variable    restconf/config/onem2m-protocol-coap:onem2m-protocol-coap-providers/CoapProviderDefault
    # Invalid server-port
    ${payload} =    Set Variable    {"onem2m-protocol-coap-providers": [{"coap-provider-instance-name": "CoapProviderDefault","server-config": {"server-port": 82828,"secure-connection": "false","server-security-level": "l0"},"notifier-plugin-config": {"secure-connection": "false"},"router-plugin-config": {"secure-connection": "false"}}]}
    Verify Negative Configuration Scenario    ${uri}    ${payload}    status_code=400
    # Invalid security-level
    ${payload} =    Set Variable    {"onem2m-protocol-coap-providers": [{"coap-provider-instance-name": "CoapProviderDefault","server-config": {"server-port": 5683,"secure-connection": "false","server-security-level": "l4"},"notifier-plugin-config": {"secure-connection": "false"},"router-plugin-config": {"secure-connection": "false"}}]}
    Verify Negative Configuration Scenario    ${uri}    ${payload}    status_code=400
    # Invalid secure-connection
    ${payload} =    Set Variable    {"onem2m-protocol-coap-providers": [{"coap-provider-instance-name": "CoapProviderDefault","server-config": {"server-port": 5683,"secure-connection": "asds","server-security-level": "l0"},"notifier-plugin-config": {"secure-connection": "false"},"router-plugin-config": {"secure-connection": "false"}}]}
    Verify Negative Configuration Scenario    ${uri}    ${payload}    status_code=400

7.04 Test missing configuration of MQTT provider module
    [Documentation]    Tests multiple cases of missing mandatory configuration items of MQTT provider module
    ${uri} =    Set Variable    restconf/config/onem2m-protocol-mqtt:onem2m-protocol-mqtt-providers/MqttProviderDefault
    # Missing MQTT broker IP
    ${payload} =    Set Variable    {"onem2m-protocol-mqtt-providers" : [{"mqtt-provider-instance-name": "MqttProviderDefault","mqtt-client-config": {"mqtt-broker-port" : 1883,"security-level" : "l0"}}]}
    Verify Negative Configuration Scenario    ${uri}    ${payload}    status_code=500
    # Missing MQTT broker port
    ${payload} =    Set Variable    {"onem2m-protocol-mqtt-providers" : [{"mqtt-provider-instance-name": "MqttProviderDefault","mqtt-client-config": {"mqtt-broker-ip" : "127.0.0.1","security-level" : "l0"}}]}
    Verify Negative Configuration Scenario    ${uri}    ${payload}    status_code=500
    # Missing security level
    ${payload} =    Set Variable    {"onem2m-protocol-mqtt-providers" : [{"mqtt-provider-instance-name": "MqttProviderDefault","mqtt-client-config": {"mqtt-broker-port" : 1883,"mqtt-broker-ip" : "127.0.0.1"}}]}
    Verify Negative Configuration Scenario    ${uri}    ${payload}    status_code=500

7.05 Test invalid values in configuration of MQTT provider module
    [Documentation]    Tests multiple cases of invalid values set in configuration of MQTT provider module
    ${uri} =    Set Variable    restconf/config/onem2m-protocol-mqtt:onem2m-protocol-mqtt-providers/MqttProviderDefault
    # Invalid mqtt broker IP address
    ${payload} =    Set Variable    {"onem2m-protocol-mqtt-providers" : [{"mqtt-provider-instance-name": "MqttProviderDefault","mqtt-client-config": {"mqtt-broker-port" : 1883,"mqtt-broker-ip" : "12777777","security-level" : "l0"}}]}
    Verify Negative Configuration Scenario    ${uri}    ${payload}    status_code=400
    # Invalid security level
    ${payload} =    Set Variable    {"onem2m-protocol-mqtt-providers" : [{"mqtt-provider-instance-name": "MqttProviderDefault","mqtt-client-config": {"mqtt-broker-port" : 1883,"mqtt-broker-ip" : "127.0.0.1","security-level" : "l4"}}]}
    Verify Negative Configuration Scenario    ${uri}    ${payload}    status_code=400
    # Invalid MQTT broker port number
    ${payload} =    Set Variable    {"onem2m-protocol-mqtt-providers" : [{"mqtt-provider-instance-name": "MqttProviderDefault","mqtt-client-config": {"mqtt-broker-port" : 188387,"mqtt-broker-ip" : "127.0.0.1","security-level" : "l0"}}]}
    Verify Negative Configuration Scenario    ${uri}    ${payload}    status_code=400

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
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig/get_default    verify=True

9.01 Test onem2m-simple-config:iplugin-cfg-put to add values to IoTDM SimpleConfig
    [Documentation]    Adds multiple values to Simple config
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig/put    verify=True

9.02 Test onem2m-simple-config:iplugin-cfg-get contains values that were set
    [Documentation]    Tests if SimpleConfig contains added values
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig/get    verify=True

9.03 Test onem2m-simple-config:iplugin-cfg-key-get receives single data
    [Documentation]    Tests if SimpleConfig receive correct value
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig_key/get0    verify=True
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig_key/get1    verify=True

9.04 Test onem2m-simple-config:iplugin-cfg-key-put set single data
    [Documentation]    Adds value to SimpleConfig using key and verify that it exists
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig_key/put    verify=True
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig_key/put/check    verify=True

9.5 Test onem2m-simple-config:iplugin-cfg-key-get-startup data
    [Documentation]    Tests if key startup recieves correct data
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig_key/startup    verify=True

9.06 Test onem2m-simple-config:iplugin-cfg-key-del deletes single data
    [Documentation]    Deletes previously added value from SimpleConfig and verify it doesn`t exist anymore
    ${uri} =    Set Variable    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-key-del
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default", "cfg-key":"testKey2"}}
    TemplatedRequests.Post_As_Json_To_Uri    uri=${uri}    data=${payload}
    ${uri} =    Set Variable    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-key-get
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default", "cfg-key":"testKey2"}}
    Verify Negative RPC Call Scenario    ${uri}    ${payload}    status_code=500

9.07 Test onem2m-simple-config:iplugin-cfg-key-get-startup data does not exist
    [Documentation]    Calls the startup rpc on key that does not exit and checks error
    ${uri} =    Set Variable    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-key-get-startup
    ${payload} =    Set Variable    {"input": {"plugin-name": "Onem2mExample","instance-name": "default","cfg-key": "testKey2"}}
    Verify Negative RPC Call Scenario    ${uri}    ${payload}    status_code=500

9.08 Test onem2m-simple-config:iplugin-cfg-key-del delete not existing single data
    [Documentation]    Try to delete not existing data and check fail
    ${uri} =    Set Variable    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-key-del
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default", "cfg-key":"testKey2"}}
    Verify Negative RPC Call Scenario    ${uri}    ${payload}    status_code=500

9.09 Test onem2m-simple-config:iplugin-cfg-put to add wrong values and expect error
    [Documentation]    Tests if SimpleConfig doesn`t allow to add values to SimpleConfig
    ${uri} =    Set Variable    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-put
    ${payload} =    Set Variable    {"input": {"plugin-name":"aaa", "instance-name":"default", "plugin-simple-config" : {"key-val-list" : [{"cfg-key":"000000","cfg-val":"testVal"},{"cfg-key":"11111","cfg-val":"Val1"}]}}}
    Verify Negative RPC Call Scenario    ${uri}    ${payload}    status_code=500    error_message=No such plugin registered: pluginName: aaa, instanceId: default
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"aaa","plugin-simple-config" : {"key-val-list" : [{"cfg-key":"000000","cfg-val":"testVal"},{"cfg-key":"11111","cfg-val":"Val1"}]}}}
    Verify Negative RPC Call Scenario    ${uri}    ${payload}    status_code=500    error_message=No such plugin registered: pluginName: Onem2mExample, instanceId: aaa

9.10 Test onem2m-simple-config:iplugin-cfg-get-startup contains expected data
    [Documentation]    Check if startup content contains only expected data
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig/get_startup    verify=True

9.11 Test iplugin-cfg-get-startup-config and iplugin-cfg-get-running-config should equal
    [Documentation]    Tests if StartupConfig and running config are the same in content
    ${resp1} =    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig/get_startup/config    verify=True
    ${resp2} =    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig/get_running_config    verify=True
    should be equal    ${resp1}    ${resp2}

9.12 Test onem2m-simple-config:iplugin-cfg-del to delete all the values
    [Documentation]    Deletes previously added values from Onem2mExample plugin and verify that they are gone
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default"}}
    TemplatedRequests.Post_As_Json_To_Uri    uri=${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-del    data=${payload}
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig/get_startup/config/default    verify=True

9.13 Test IoTDM BUG 7593
    [Documentation]    Multiple times try to delete configuration which doesn't exist.
    ...    https://bugs.opendaylight.org/show_bug.cgi?id=7593
    ${uri} =    Set Variable    ${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-key-del
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default", "cfg-key":"testKey10"}}
    Verify Negative RPC Call Scenario    ${uri}    ${payload}    status_code=500
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default", "cfg-key":"testKey10"}}
    Verify Negative RPC Call Scenario    ${uri}    ${payload}    status_code=500
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/simpleconfig_registrations/filtered    verify=True

9.14 Test onem2m-simple-config:iplugin-cfg-del to delete empty config
    [Documentation]    Delete of empty configuration passes without error
    ${payload} =    Set Variable    {"input": {"plugin-name":"Onem2mExample", "instance-name":"default"}}
    TemplatedRequests.Post_As_Json_To_Uri    uri=${REST_CONTEXT}/onem2m-simple-config:iplugin-cfg-del    data=${payload}

*** Keywords ***
TODO
    Fail    "Not implemented"

Install ODL Jolokia
    [Documentation]    Install odl-jolokia feature needed for restarting of IoTDM running on remote machine.
    ...    KarafFeatureLoader is used to install the feature from nexus repository.
    ${payload} =    Set Variable    ${odl_jolokia_install}
    ${resp} =    RequestsLibrary.Post Request    ClusterManagement__session_1    ${REST_CONTEXT}/iotdmkaraffeatureloader:archive-install    data=${payload}    headers=${headers}
    BuiltIn.Log    ${resp.text}
    BuiltIn.Log    ${resp.status_code}
    ${status_code} =    convert to integer    ${resp.status_code}
    Run keyword if    ${status_code} != ${200}    Run keyword and ignore error    ClusterManagement.Install_Feature_On_List_Or_All    odl-jolokia
    # ignore error because of cases when odl-jolokia is already installed in system

Uninstall ODL Jolokia
    [Documentation]    Uninstall odl-jolokia feature
    ${payload} =    Set Variable    ${odl_jolokia_uninstall}
    ${resp} =    RequestsLibrary.Post Request    ClusterManagement__session_1    ${REST_CONTEXT}/iotdmkaraffeatureloader:archive-uninstall    data=${payload}    headers=${headers}
    BuiltIn.Log    ${resp.text}
    BuiltIn.Log    ${resp.status_code}
    ${status_code} =    Status Code    ${resp}
    Run keyword and ignore error    Should Be Equal As Integers    ${status_code}    200

Start
    [Documentation]    Prepares suite keywords and initialize mqtt and coap
    ${headers} =    Create Dictionary    Content-Type=application/json    Authorization=Basic YWRtaW46YWRtaW4=
    Set Suite Variable    ${headers}
    TemplatedRequests.Create_Default_Session
    ClusterManagement.ClusterManagement_Setup

Stop
    Delete all sessions

Restart Cluster
    [Documentation]    Restart IoTDM running on remote machine
    Log    Restarting cluster of IoTDM instances
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All

Verify Default PluginData Output
    [Documentation]    Verifies output of RPC call onem2m-plugin-manager:onem2m-plugin-manager-plugin-data
    ...    whether contains data about all default modules registering as plugins.
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/http/default    verify=True    subset_at_level=${3}
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/coap/default    verify=True    subset_at_level=${3}
    TemplatedRequests.Post_As_Json_Templated_Check_Not_Included    folder=${VAR_BASE}/plugin_data/mqtt/default
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/ws/default    verify=True    subset_at_level=${3}
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/onem2m_example/default    verify=True    subset_at_level=${3}
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/tsdr/default    verify=True    subset_at_level=${3}
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/simple_adapter/default    verify=True    subset_at_level=${3}

Verify PluginData After Reconfiguration of HTTP
    BuiltIn.Wait_Until_Keyword_Succeeds    15 sec    1 sec    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/http/changed_port    verify=True

Verify PluginData After Reconfiguration of CoAP
    BuiltIn.Wait_Until_Keyword_Succeeds    15 sec    1 sec    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/coap/changed_port    verify=True

Verify PluginData After Reconfiguration of MQTT
    #BuiltIn.Wait_Until_Keyword_Succeeds    15 sec    1 sec    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/mqtt/changed_port    verify=True
    TODO

Verify PluginData After Reconfiguration of Onem2mExample
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/plugin_data/onem2m_example/changed_port    verify=True

Verify PluginData After Reconfiguration of All Modules
    Verify PluginData After Reconfiguration of HTTP
    Verify PluginData After Reconfiguration of CoAP
    # TODO verify also MQTT when imlemented
    #Verify PluginData After Reconfiguration of MQTT
    Verify PluginData After Reconfiguration of Onem2mExample

Verify Negative Configuration Scenario
    [Arguments]    ${uri}    ${payload}    ${status_code}
    ${response} =    RequestsLibrary.Put Request    ClusterManagement__session_1    ${uri}    data=${payload}    headers=${headers}
    ${result_status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${result_status_code}    ${status_code}

Verify Negative RPC Call Scenario
    [Arguments]    ${uri}    ${payload}    ${status_code}    ${error_message}=${none}
    ${response} =    RequestsLibrary.Post Request    ClusterManagement__session_1    ${uri}    data=${payload}    headers=${headers}
    ${result_status_code} =    Status Code    ${response}
    Should Be Equal As Integers    ${result_status_code}    ${status_code}
    run keyword if    "${error_message}" != "${none}"    Should Contain    ${response.content}    ${error_message}

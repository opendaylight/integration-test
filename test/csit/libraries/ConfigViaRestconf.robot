*** Settings ***
Documentation     Robot keyword library (Resource) for runtime changes to config subsystem state using restconf calls.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Library           ${CURDIR}/RequestsLibrary.py
Variables         ${CURDIR}/../variables/Variables.py

*** Keywords ***
Setup_Config_Via_Restconf
    [Documentation]    Creates Requests session to be used by subsequent keywords.
    # Do not append slash at the end uf URL, Requests would add another, resulting in error.
    Create_Session    cvr_session    http://${CONTROLLER}:${RESTCONFPORT}/restconf/config/network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount    headers=${HEADERS_XML}    auth=${AUTH}

Teardown_Config_Via_Restconf
    [Documentation]    Teardown to pair with Setup (otherwise no-op).
    Log    TODO: The following line does not seem to be implemented by RequestsLibrary. Look for a workaround.
    # Delete_Session    cvr_session

Post_Xml_Config_Module_Via_Restconf
    [Arguments]    ${xml_data}
    [Documentation]    Post new XML configuration to config:modules
    # Also no slash here
    Post_Xml_Config_Via_Restconf    config:modules    ${xml_data}

Post_Xml_Config_Service_Via_Restconf
    [Arguments]    ${xml_data}
    [Documentation]    Post new XML configuration to config:services
    Post_Xml_Config_Via_Restconf    config:services    ${xml_data}

Post_Xml_Config_Via_Restconf
    [Arguments]    ${uri_part}    ${xml_data}
    [Documentation]    Post XML data to given controller-config URI, check reponse text is empty and status_code is 204.
    ${response}=    RequestsLibrary.Post    cvr_session    ${uri_part}    data=${xml_data}
    Log    ${response.text}
    Should_Be_Empty    ${response.text}
    Should_Be_Equal_As_Strings    ${response.status_code}    204

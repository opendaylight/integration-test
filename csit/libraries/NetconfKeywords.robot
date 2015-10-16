*** Settings ***
Documentation     Access Netconf via Restconf.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Library           Collections
Resource          NetconfViaRestconf.robot

*** Variables ***
${directory_with_device_templates}    ${CURDIR}/../variables/netconf/device

*** Keywords ***
Setup_Netconf_Keywords
    ${tmp}=    BuiltIn.Create_Dictionary
    BuiltIn.Set_Suite_Variable    ${mounted_device_types}    ${tmp}
    NetconfViaRestconf.Setup_Netconf_Via_Restconf
    # Setup a requests session for operational data (used by Netconf mount checks)
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.
    RequestsLibrary.Create_Session    operational    http://${CONTROLLER}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}

Mount_Device_Onto_Netconf
    [Arguments]    ${device_name}    ${device_type}=default    ${device_port}=17832
    [Documentation]    Tell Netconf to make the specified device accessible.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_IP': '${MININET}', 'DEVICE_NAME': '${device_name}', 'DEVICE_PORT': '${device_port}'}
    NetconfViaRestconf.Put_Xml_Template_Folder_Via_Restconf    ${directory_with_device_templates}${/}${device_type}    ${template_as_string}
    Collections.Set_To_Dictionary    ${mounted_device_types}    ${device_name}    ${device_type}

Count_Netconf_Connectors_For_Device
    [Arguments]    ${device_name}
    [Documentation]    Count all Netconf connectors referring to the specified device.
    ${mounts}=    Utils.Get_Data_From_URI    operational    network-topology:network-topology/topology/topology-netconf
    Builtin.Log    ${mounts}
    ${actual_count}=    Builtin.Evaluate    len('''${mounts}'''.split('"node-id":"${device_name}"'))-1
    Builtin.Return_From_Keyword    ${actual_count}

Check_Device_Has_No_Netconf_Connector
    [Arguments]    ${device_name}
    [Documentation]    Check that there are no Netconf connectors referring to the specified device.
    ${count}    Count_Netconf_Connectors_For_Device    ${device_name}
    Builtin.Should_Be_Equal_As_Strings    ${count}    0

Check_Device_Mounted
    [Arguments]    ${device_name}
    [Documentation]    Check thatthe specified device is accessible from Netconf.
    ${device_status}=    Utils.Get_Data_From_URI    operational    network-topology:network-topology/topology/topology-netconf/node/${device_name}
    Builtin.Should_Contain    ${device_status}    "netconf-node-topology:connection-status":"connected"

Wait_Device_Mounted
    [Arguments]    ${device_name}    ${timeout}=10s    ${period}=1s
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${period}    Check_Device_Mounted    ${device_name}

Unmount_Device_From_Netconf
    [Arguments]    ${device_name}
    [Documentation]    Tell Netconf to drop accessibility point for the specified device
    ${device_type}=    Collections.Pop_From_Dictionary    ${mounted_device_types}    ${device_name}
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    NetconfViaRestconf.Delete_Xml_Template_Folder_Via_Restconf    ${directory_with_device_templates}${/}${device_type}    ${template_as_string}

Wait_Device_Unmounted
    [Arguments]    ${device_name}    ${timeout}=10s    ${period}=1s
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${period}    Check_Device_Has_No_Netconf_Connector    ${device_name}

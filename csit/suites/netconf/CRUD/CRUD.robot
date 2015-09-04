*** Settings ***
Documentation     netconf-connector CRUD test suite.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Query netconf-connector and see if it works. If it doesn't,
...               start repeating the query for a minute to see whether it goes
...               up or not.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Library           Collections
Library           RequestsLibrary
Library           OperatingSystem
Library           String
Library           SSHLibrary    prompt=]>    timeout=10s
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot

*** Variables ***
${directory_with_template_folders}    ${CURDIR}/../../../variables/netconf/CRUD
${MININET_PROMPT}    ${DEFAULT_LINUX_PROMPT}
${directory_for_schemas}    \$HOME/schemas
${device_name}    controller-config_test
# netconf-test-device
@{allowed_status_codes}    ${200}    ${201}    ${204}    # List of integers, not strings. Used by both PUT and DELETE.

*** Test Cases ***
Check_Device_Is_Not_Mounted_At_Beginning
    [Documentation]    Sanity check making sure our device is not there. Fail if found.
    [Tags]    critical
    Check_Device_Has_No_Netconf_Connector

Mount_Device_On_Netconf
    [Documentation]    Make request to mount a testtool device on Netconf connector
    [Tags]    critical
    KarafKeywords.Log_Message_To_Controller_Karaf    Reconfiguring ODL to accept a connection
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_IP': '${MININET}', 'DEVICE_NAME': '${device_name}'}
    Post_Xml_Template_Folder_Via_Restconf    ${directory_with_template_folders}${/}device    ${template_as_string}

Check_ODL_Has_Netconf_Connector_For_Device
    [Documentation]    Get the list of mounts and search for our device there. Fail if not found.
    [Tags]    critical
    ${count}    Count_Netconf_Connectors_For_Device
    Builtin.Should_Be_Equal_As_Strings    ${count}    1

Wait_For_Device_To_Become_Mounted
    Wait_Until_Keyword_Succeeds    10s    1s    Check_Device_Mounted

Check_Device_Data_Is_Empty
    [Documentation]    Get the device data and make sure it is empty.
    Check_Config_Data    <data xmlns="urn:ietf:params:xml:ns:netconf:base:1.0"></data>

Create_Device_Data
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    Post_Xml_Template_Folder_Via_Restconf    ${directory_with_template_folders}${/}dataorig    ${template_as_string}

Check_Device_Data_Is_Created
    [Documentation]    Get the device data and make sure it contains the created content.
    Check_Config_Data    <data xmlns="urn:ietf:params:xml:ns:netconf:base:1.0"><cont xmlns="urn:opendaylight:test" xmlns:a="urn:ietf:params:xml:ns:netconf:base:1.0" a:operation="replace"><l>Content</l></cont></data>

Modify_Device_Data
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    Put_Xml_Template_Folder_Via_Restconf    ${directory_with_template_folders}${/}datamod1    ${template_as_string}

Check_Device_Data_Is_Modified
    [Documentation]    Get the device data and make sure it contains the created content.
    Check_Config_Data    <data xmlns="urn:ietf:params:xml:ns:netconf:base:1.0"><cont xmlns="urn:opendaylight:test" xmlns:a="urn:ietf:params:xml:ns:netconf:base:1.0" a:operation="replace"><l>Modified Content</l></cont></data>

Delete_Device_Data
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    Delete_Xml_Template_Folder_Via_Restconf    ${directory_with_template_folders}${/}datamod1    ${template_as_string}

Check_Device_Data_Is_Deleted
    [Documentation]    Get the device data and make sure it is empty.
    Check_Config_Data    <data xmlns="urn:ietf:params:xml:ns:netconf:base:1.0"></data>

Delete_Device_From_Netconf
    [Documentation]    Make request to mount a testtool device on Netconf connector
    [Tags]    critical
    KarafKeywords.Log_Message_To_Controller_Karaf    Reconfiguring ODL to accept a connection
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    Delete_Xml_Template_Folder_Via_Restconf    ${directory_with_template_folders}${/}devicedelete    ${template_as_string}

Check_Device_Gone_After_Delete
    [Documentation]    Check that the device is really gone. Fail if found.
    [Tags]    critical
    Check_Device_Has_No_Netconf_Connector

Check_Device_Gone_After_Delete_And_A_While
    Builtin.Wait_Until_Keyword_Succeeds    5s    0.25s    Check_Device_Has_No_Netconf_Connector

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup the restconf configuration module.
    Setup_Netconf_Via_Restconf
    # Connect to the Mininet machine
    SSHLibrary.Open_Connection    ${MININET}
    Utils.Flexible_SSH_Login    ${MININET_USER}    ${MININET_PASSWORD}
    # A previous test suite might be using this one. Note that this is on a remote
    # machine thus it is not possible to use OperatingSystem.Remove_Directory.
    ${response}=    SSHLibrary.Execute_Command    rm -rf ${directory_for_schemas}
    # Install test tool on the Mininet machine.
    ${urlbase}=    BuiltIn.Set_Variable    ${NEXUSURL_PREFIX}/content/repositories/opendaylight.snapshot/org/opendaylight/netconf/netconf-testtool
    ${version}=    SSHLibrary.Execute_Command    curl ${urlbase}/maven-metadata.xml | grep '<version>' | cut -d '>' -f 2 | cut -d '<' -f 1
    BuiltIn.Log    ${version}
    ${namepart}=    SSHLibrary.Execute_Command    curl ${urlbase}/${version}/maven-metadata.xml | grep value | head -n 1 | cut -d '>' -f 2 | cut -d '<' -f 1
    BuiltIn.Log    ${namepart}
    BuiltIn.Set_Suite_Variable    ${filename}    netconf-testtool-${namepart}-executable.jar
    BuiltIn.Log    ${filename}
    ${response}=    SSHLibrary.Execute_Command    curl ${urlbase}/${version}/${filename} >${filename}
    BuiltIn.Log    ${response}
    # Start the testtool
    SSHLibrary.Put_Directory    ${CURDIR}/../../../variables/netconf/CRUD/schemas
    ${response}=    SSHLibrary.Execute_Command    mkdir ${directory_for_schemas}
    BuiltIn.Log    ${response}
    SSHLibrary.Start_Command    java -Xmx1G -XX:MaxPermSize=256M -jar ${filename} --device-count 10 --debug true --schemas-dir ${directory_for_schemas} >testtool.log 2>&1
    # Wait for the testtool to boot up.
    Builtin.Sleep    5s
    # Setup a requests session
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.
    RequestsLibrary.Create_Session    operational    http://${CONTROLLER}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    # Log the start of the suite in Karaf log file.
    KarafKeywords.Open_Controller_Karaf_Console
    KarafKeywords.Log_Message_To_Controller_Karaf    Starting the Netconf CRUD suite

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    Teardown_Netconf_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    # Stop testtool and download its log.
    # FIXME: This does not work very well. It seems there there is no 'killall'
    #        command on the mininet machine.
    ${response}=    SSHLibrary.Execute_Command    killall java
    BuiltIn.Log    ${response}
    ${response}=    OperatingSystem.Run    sshpass -p${MININET_PASSWORD} scp ${MININET_USER}@${MININET}:/home/${MININET_USER}/testtool.log .
    BuiltIn.Log    ${response}

Count_Netconf_Connectors_For_Device
    ${response}=    RequestsLibrary.Get    operational    network-topology:network-topology/topology/topology-netconf
    Builtin.Log    ${response.text}
    Utils.Store_Response_Code    ${response}
    Utils.Fail_If_Status_Is_Wrong
    Builtin.Log    ${response.text}
    ${actual_count}=    Builtin.Evaluate    len(re.findall('${device_name}', '''${response.text}'''))    modules=re
    Builtin.Return_From_Keyword    ${actual_count}

Check_Device_Has_No_Netconf_Connector
    ${count}    Count_Netconf_Connectors_For_Device
    Builtin.Should_Be_Equal_As_Strings    ${count}    0

Check_Device_Mounted
    ${response}=    RequestsLibrary.Get    operational    network-topology:network-topology/topology/topology-netconf/node/${device_name}
    Utils.Store_Response_Code    ${response}
    Utils.Fail_If_Status_Is_Wrong
    Builtin.Should_Contain    ${response.text}    "netconf-node-topology:connection-status":"connected"

Check_Config_Data
    [Arguments]    ${expected}    ${contains}=False
    ${url}=    Builtin.Set_Variable    network-topology:network-topology/topology/topology-netconf/node/${device_name}/yang-ext:mount
    ${response}=    RequestsLibrary.Get    nvr_session    ${url}    headers=${ACCEPT_XML}
    Utils.Store_Response_Code    ${response}
    Utils.Fail_If_Status_Is_Wrong
    BuiltIn.Run_Keyword_Unless    ${contains}    BuiltIn.Should_Be_Equal_As_Strings    ${response.text}    ${expected}
    BuiltIn.Run_Keyword_If    ${contains}    BuiltIn.Should_Contain    ${response.text}    ${expected}

#############
### FIXME ###
#############
# The following code has a bunch of problems which are very hard to fix in
# terms of debugging and review times. Therefore I propose to merge this test
# first "as is" and solve the problems of this code in later commits. These
# problems were identified so far:
#
# - This code should be reusable. This means converting it to a Robot library
#   and putting it to the Libraries directory.
# - Code duplication. The following code is almost identical to what is
#   present in ConfigViaRestconf.robot. Fixing this means converting the code
#   below to a library and refactoring ConfigViaRestconf.robot to use this
#   library instead.
# - The interface of this code might be too optimized for the needs of this
#   test. Maybe it should be generalized.
# - The Teardown_Netconf_Via_Restconf seems to be incomplete. It is supposed
#   to close the session but (as the code suggests in a comment), the
#   functionality needed is not implemented.
#
# Issues identified when trying to make this a library:
#
# - A better name might be necessary (this actually allows not only netconf
#   to be accessed but other restconf accessible subsystems as well).
# - The ConfigViaRestconf might need to be merged with this code to avoid
#   strange name clashes when using both in a suite.

Setup_Netconf_Via_Restconf
    [Documentation]    Creates Requests session to be used by subsequent keywords.
    # Do not append slash at the end uf URL, Requests would add another, resulting in error.
    RequestsLibrary.Create_Session    nvr_session    http://${CONTROLLER}:${RESTCONFPORT}${CONFIG_API}    headers=${HEADERS_XML}    auth=${AUTH}

Teardown_Netconf_Via_Restconf
    [Documentation]    Teardown to pair with Setup (otherwise no-op).
    BuiltIn.Comment    TODO: The following line does not seem to be implemented by RequestsLibrary. Look for a workaround.
    BuiltIn.Comment    Delete_Session    nvr_session

Resolve_URI_From_Template_Folder
    [Arguments]    ${folder}    ${mapping_as_string}
    [Documentation]    Read URI template from folder, strip endline, make changes according to mapping, return the result.
    ${uri_template}=    OperatingSystem.Get_File    ${folder}${/}config.uri
    BuiltIn.Log    ${uri_template}
    ${uri_part}=    Strip_Endline_And_Apply_Substitutions_From_Mapping    ${uri_template}    ${mapping_as_string}
    [Return]    ${uri_part}

Resolve_Xml_Data_From_Template_Folder
    [Arguments]    ${folder}    ${mapping_as_string}
    [Documentation]    Read data template from folder, strip endline, make changes according to mapping, return the result.
    ${data_template}=    OperatingSystem.Get_File    ${folder}${/}data.xml
    BuiltIn.Log    ${data_template}
    ${xml_data}=    Strip_Endline_And_Apply_Substitutions_From_Mapping    ${data_template}    ${mapping_as_string}
    [Return]    ${xml_data}

Strip_Endline_And_Apply_Substitutions_From_Mapping
    [Arguments]    ${template_as_string}    ${mapping_as_string}
    [Documentation]    Strip endline, apply substitutions, Log and return the result.
    # Robot Framework does not understand dictionaries well, so resort to Evaluate.
    # Needs python module "string", and since the template string is expected to contain newline, it has to be enclosed in triple quotes.
    # Using rstrip() removes all trailing whitespace, which is what we want if there is something more than an endline.
    ${final_text}=    BuiltIn.Evaluate    string.Template('''${template_as_string}'''.rstrip()).substitute(${mapping_as_string})    modules=string
    BuiltIn.Log    ${final_text}
    [Return]    ${final_text}

Post_Xml_Via_Restconf
    [Arguments]    ${uri_part}    ${xml_data}
    [Documentation]    Post XML data to given controller-config URI, check reponse text is empty and status_code is 204.
    BuiltIn.Log    ${uri_part}
    BuiltIn.Log    ${xml_data}
    # As seen in previous two Keywords, Post does not need long specific URI.
    # But during Lithium development, Post ceased to do merge, so those Keywords do not work anymore.
    # This Keyword can still be used with specific URI to create a new container and fail if a container was already present.
    ${response}=    RequestsLibrary.Post    nvr_session    ${uri_part}    data=${xml_data}
    BuiltIn.Log    ${response.text}
    BuiltIn.Should_Be_Empty    ${response.text}
    BuiltIn.Should_Be_Equal_As_Strings    ${response.status_code}    204

Post_Xml_Template_Folder_Via_Restconf
    [Arguments]    ${folder}    ${mapping_as_string}={}
    [Documentation]    Resolve URI and data from folder, POST to restconf.
    ${uri_part}=    Resolve_URI_From_Template_Folder    ${folder}    ${mapping_as_string}
    ${xml_data}=    Resolve_Xml_Data_From_Template_Folder    ${folder}    ${mapping_as_string}
    Post_Xml_Via_Restconf    ${uri_part}    ${xml_data}

Put_Xml_Via_Restconf
    [Arguments]    ${uri_part}    ${xml_data}
    [Documentation]    Put XML data to given controller-config URI, check reponse text is empty and status_code is one of allowed ones.
    BuiltIn.Log    ${uri_part}
    BuiltIn.Log    ${xml_data}
    ${response}=    RequestsLibrary.Put    nvr_session    ${uri_part}    data=${xml_data}
    BuiltIn.Log    ${response.text}
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Should_Be_Empty    ${response.text}
    BuiltIn.Should_Contain    ${allowed_status_codes}    ${response.status_code}

Put_Xml_Template_Folder_Via_Restconf
    [Arguments]    ${folder}    ${mapping_as_string}={}
    [Documentation]    Resolve URI and data from folder, PUT to controller config.
    ${uri_part}=    Resolve_URI_From_Template_Folder    ${folder}    ${mapping_as_string}
    ${xml_data}=    Resolve_Xml_Data_From_Template_Folder    ${folder}    ${mapping_as_string}
    Put_Xml_Via_Restconf    ${uri_part}    ${xml_data}

Delete_Via_Restconf
    [Arguments]    ${uri_part}
    [Documentation]    Delete resource at controller-config URI, check reponse text is empty and status_code is 204.
    BuiltIn.Log    ${uri_part}
    ${response}=    RequestsLibrary.Delete    nvr_session    ${uri_part}
    BuiltIn.Log    ${response.text}
    BuiltIn.Should_Be_Empty    ${response.text}
    BuiltIn.Should_Contain    ${allowed_status_codes}    ${response.status_code}

Delete_Xml_Template_Folder_Via_Restconf
    [Arguments]    ${folder}    ${mapping_as_string}={}
    [Documentation]    Resolve URI from folder, DELETE from controller config.
    ${uri_part}=    Resolve_URI_From_Template_Folder    ${folder}    ${mapping_as_string}
    Delete_Via_Restconf    ${uri_part}

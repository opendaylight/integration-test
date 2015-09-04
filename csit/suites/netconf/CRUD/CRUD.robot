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
...               Perform basic operations (Create, Read, Update and Delete or CRUD) on device
...               data mounted onto a netconf connector and see if they work.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           Collections
Library           RequestsLibrary
Library           OperatingSystem
Library           String
Library           SSHLibrary    prompt=${MININET_PROMPT}    timeout=10s
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${directory_with_template_folders}    ${CURDIR}/../../../variables/netconf/CRUD
${directory_for_schemas}    \$HOME/schemas
${device_name}    netconf-test-device
@{allowed_status_codes}    ${200}    ${201}    ${204}    # List of integers, not strings. Used by both PUT and DELETE.
${netconf_ns}     urn:ietf:params:xml:ns:netconf:base:1.0

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
    Put_Xml_Template_Folder_Via_Restconf    ${directory_with_template_folders}${/}device    ${template_as_string}

Check_ODL_Has_Netconf_Connector_For_Device
    [Documentation]    Get the list of mounts and search for our device there. Fail if not found.
    [Tags]    critical
    ${count}    Count_Netconf_Connectors_For_Device
    Builtin.Should_Be_Equal_As_Strings    ${count}    1

Wait_For_Device_To_Become_Mounted
    Wait_Until_Keyword_Succeeds    10s    1s    Check_Device_Mounted

Check_Device_Data_Is_Empty
    [Documentation]    Get the device data and make sure it is empty.
    Check_Config_Data    <data xmlns="${netconf_ns}"></data>

Create_Device_Data
    [Documentation]    Send some sample test data into the device and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    Post_Xml_Template_Folder_Via_Restconf    ${directory_with_template_folders}${/}dataorig    ${template_as_string}

Check_Device_Data_Is_Created
    [Documentation]    Get the device data and make sure it contains the created content.
    Check_Config_Data    <data xmlns="${netconf_ns}"><cont xmlns="urn:opendaylight:test" xmlns:a="${netconf_ns}" a:operation="replace"><l>Content</l></cont></data>

Modify_Device_Data
    [Documentation]    Send a request to change the sample test data and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    Put_Xml_Template_Folder_Via_Restconf    ${directory_with_template_folders}${/}datamod1    ${template_as_string}

Check_Device_Data_Is_Modified
    [Documentation]    Get the device data and make sure it contains the created content.
    Check_Config_Data    <data xmlns="${netconf_ns}"><cont xmlns="urn:opendaylight:test" xmlns:a="${netconf_ns}" a:operation="replace"><l>Modified Content</l></cont></data>

Delete_Device_Data
    [Documentation]    Send a request to delete the sample test data on the device and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    Delete_Xml_Template_Folder_Via_Restconf    ${directory_with_template_folders}${/}datamod1    ${template_as_string}

Check_Device_Data_Is_Deleted
    [Documentation]    Get the device data and make sure it is empty again.
    Check_Config_Data    <data xmlns="${netconf_ns}"></data>

Delete_Device_From_Netconf
    [Documentation]    Make request to unmount a testtool device on Netconf connector.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    # TODO: Link to Bugzilla bug report "Device mount still present after device deleted via Restconf"
    #       or maybe better "Netconf device delete request returns OK while device still present".
    [Tags]    critical
    KarafKeywords.Log_Message_To_Controller_Karaf    Reconfiguring ODL to accept a connection
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${device_name}'}
    Delete_Xml_Template_Folder_Via_Restconf    ${directory_with_template_folders}${/}device    ${template_as_string}

Check_Device_Going_To_Be_Gone_After_Delete
    [Documentation]    Check that the device is really going to be gone. Fail if found after one minute.
    ...    This is an expected behavior as the unmount request is sent to the config subsystem which
    ...    then triggers asynchronous disconnection of the device which is reflected in the operational
    ...    data once completed. This test makes sure this asynchronous operation does not take
    ...    unreasonable amount of time.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_Device_Has_No_Netconf_Connector

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    Setup_Netconf_Via_Restconf
    # Connect to the Mininet machine
    SSHLibrary.Open_Connection    ${MININET}
    Utils.Flexible_Mininet_Login
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
    BuiltIn.Log    ${response}
    SSHLibrary.Write    java -Xmx1G -XX:MaxPermSize=256M -jar ${filename} --device-count 10 --debug true --schemas-dir ${directory_for_schemas} >testtool.log 2>&1
    # Wait for the testtool to boot up.
    # TODO: Replace with WUKS checking that the device ports are there.
    Builtin.Sleep    5s
    # Setup a requests session
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.
    RequestsLibrary.Create_Session    operational    http://${CONTROLLER}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    Teardown_Netconf_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    # Stop testtool and download its log.
    Utils.Write_Bare_Ctrl_C
    # TODO: Replace with WUKS checking that there are no more Java processes.
    # TODO: If that WUKS fails, send kill -9 to the Java process(es) (killall
    #       might not be there so this can get tricky). Maybe sending Ctrl-Z
    #       and then "kill -9 %1" would do the trick.
    BuiltIn.Sleep    5s
    SSHLibrary.Get_File    /home/${MININET_USER}/testtool.log

Count_Netconf_Connectors_For_Device
    ${mounts}=    Utils.Get_Data_From_URI    operational    network-topology:network-topology/topology/topology-netconf
    Builtin.Log    ${mounts}
    ${actual_count}=    Builtin.Evaluate    len(re.findall('${device_name}', '''${mounts}'''))    modules=re
    Builtin.Return_From_Keyword    ${actual_count}

Check_Device_Has_No_Netconf_Connector
    ${count}    Count_Netconf_Connectors_For_Device
    Builtin.Should_Be_Equal_As_Strings    ${count}    0

Check_Device_Mounted
    ${device_status}=    Utils.Get_Data_From_URI    operational    network-topology:network-topology/topology/topology-netconf/node/${device_name}
    Builtin.Should_Contain    ${device_status}    "netconf-node-topology:connection-status":"connected"

Check_Config_Data
    [Arguments]    ${expected}    ${contains}=False
    ${url}=    Builtin.Set_Variable    network-topology:network-topology/topology/topology-netconf/node/${device_name}/yang-ext:mount
    ${data}=    Utils.Get_Data_From_URI    nvr_session    ${url}    headers=${ACCEPT_XML}
    BuiltIn.Run_Keyword_Unless    ${contains}    BuiltIn.Should_Be_Equal_As_Strings    ${data}    ${expected}
    BuiltIn.Run_Keyword_If    ${contains}    BuiltIn.Should_Contain    ${data}    ${expected}

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

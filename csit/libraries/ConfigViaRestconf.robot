*** Settings ***
Documentation     Robot keyword library (Resource) for runtime changes to config subsystem state using restconf calls.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               The purpose of this library is to make runtime changes to ODL configuration
...               easier from Robot suite contributor point of view.
...
...               Different ODL parts have varying ways of configuration,
...               this library affects only the Config Subsystem way.
...               Config Subsystem has (apart Java APIs mostly available only from inside of ODL)
...               NETCONF server as its publicly available entry point.
...               Netconf-connector feature makes this netconf server available for RESTCONF calls.
...               Unfortunately, URIs and data payloads tend to be quite convoluted,
...               so using RequestsLibrary directly from test cases is unwieldy.
...
...               The main strength of this library are *_Template_Folder_Config_Via_Restconf keywords
...               User gives a path to directory where files with templates for URI fragment
...               and XML (or JSON) data are present, and a mapping with substitution to make;
...               the keywords will take it from there.
...
...               Prerequisities:
...               * netconf-connector feature installed on ODL.
...               * Setup_Config_Via_Restconf called from suite Setup once
...               (or before any other keyword from this library, but just once).
...
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Library           ${CURDIR}/HsfJson/hsf_json.py
Variables         ${CURDIR}/../variables/Variables.py

*** Variables ***
# TODO: Make the following list more narrow when Bug 2594 is fixed.
@{allowed_status_codes}    ${200}    ${201}    ${204}    # List of integers, not strings. Used by both PUT and DELETE.
cvr_workspace     /tmp

*** Keywords ***
Setup_Config_Via_Restconf
    [Documentation]    Creates Requests session to be used by subsequent keywords.
    ...    Also remembers worspace to use when needed and two temp files for JSON data.
    # Do not append slash at the end uf URL, Requests would add another, resulting in error.
    RequestsLibrary.Create_Session    cvr_session    http://${CONTROLLER}:${RESTCONFPORT}${CONTROLLER_CONFIG_MOUNT}    headers=${HEADERS_XML}    auth=${AUTH}
    ${workspace_defined}    BuiltIn.Run_Keyword_And_return_Status    BuiltIn.Variable_Should_Exist    ${WORKSPACE}
    BuiltIn.Run_Keyword_If    ${workspace_defined}    BuiltIn.Set_Suite_Variable    ${cvr_workspace}    ${WORKSPACE}
    BuiltIn.Set_Suite_Variable    ${cvr_actfile}    ${cvr_workspace}${/}actual.json
    BuiltIn.Set_Suite_Variable    ${cvr_expfile}    ${cvr_workspace}${/}expected.json

Teardown_Config_Via_Restconf
    [Documentation]    Teardown to pair with Setup (otherwise no-op).
    BuiltIn.Comment    TODO: The following line does not seem to be implemented by RequestsLibrary. Look for a workaround.
    BuiltIn.Comment    Delete_Session    cvr_session

Put_Xml_Template_Folder_Config_Via_Restconf
    [Arguments]    ${folder}    ${mapping_as_string}={}
    [Documentation]    Resolve URI and data from folder, PUT to controller config.
    ${uri_part}=    Resolve_URI_From_Template_Folder    ${folder}    ${mapping_as_string}
    ${xml_data}=    Resolve_Xml_Data_From_Template_Folder    ${folder}    ${mapping_as_string}
    Put_Xml_Config_Via_Restconf    ${uri_part}    ${xml_data}

Get_Xml_Template_Folder_Config_Via_Restconf
    [Arguments]    ${folder}    ${mapping_as_string}={}
    [Documentation]    Resolve URI from folder, GET from controller config in XML form.
    ${uri_part}=    Resolve_URI_From_Template_Folder    ${folder}    ${mapping_as_string}
    ${xml_data}=    Get_Xml_Config_Via_Restconf    ${uri_part}
    [Return]    ${xml_data}

Get_Json_Template_Folder_Config_Via_Restconf
    [Arguments]    ${folder}    ${mapping_as_string}={}
    [Documentation]    Resolve URI from folder, GET from controller config in JSON form.
    ${uri_part}=    Resolve_URI_From_Template_Folder    ${folder}    ${mapping_as_string}
    ${json_string}=    Get_Json_Config_Via_Restconf    ${uri_part}
    [Return]    ${json_string}

Verify_Xml_Template_Folder_Config_Via_Restconf
    # FIXME: This is subject to pseudorandom field ordering issue, use with care.
    [Arguments]    ${folder}    ${mapping_as_string}={}
    [Documentation]    Resolve URI from folder, GET from controller config, compare to expected data.
    ${expected_data}=    Resolve_Xml_Data_From_Template_Folder    ${folder}    ${mapping_as_string}
    ${actual_data}=    Get_Xml_Template_Folder_Config_Via_Restconf    ${folder}    ${mapping_as_string}
    BuiltIn.Should_Be_Equal    ${actual_data}    ${expected_data}

Verify_Json_Template_Folder_Config_Via_Restconf
    [Arguments]    ${folder}    ${mapping_as_string}={}
    [Documentation]    Resolve URI from folder, GET from controller config, compare to expected data as normalized JSONs.
    ${expected}=    Resolve_Json_Data_From_Template_Folder    ${folder}    ${mapping_as_string}
    ${actual}=    Get_Json_Template_Folder_Config_Via_Restconf    ${folder}    ${mapping_as_string}
    Normalize_Jsons_And_Compare    ${actual}    ${expected}

Normalize_Jsons_And_Compare
    [Arguments]    ${actual_raw}    ${expected_raw}
    [Documentation]    Use HsfJson to normalize both arguments, compute and Log diff, fail if diff is non-empty.
    ...    This keywords assumes ${WORKSPACE} is defined as a suite variable.
    ${actual_normalized}=    hsf_json.Hsf_Json    ${actual_raw}
    ${expected_normalized}=    hsf_json.Hsf_Json    ${expected_raw}
    OperatingSystem.Create_File    ${cvr_expfile}    ${expected_normalized}
    OperatingSystem.Create_File    ${cvr_actfile}    ${actual_normalized}
    ${diff}=    OperatingSystem.Run    diff -du '${cvr_expfile}' '${cvr_actfile}'
    BuiltIn.Log    ${diff}
    BuiltIn.Should_Be_Empty    ${diff}

Delete_Xml_Template_Folder_Config_Via_Restconf
    [Arguments]    ${folder}    ${mapping_as_string}={}
    [Documentation]    Resolve URI from folder, DELETE from controller config.
    ${uri_part}=    Resolve_URI_From_Template_Folder    ${folder}    ${mapping_as_string}
    Delete_Config_Via_Restconf    ${uri_part}

Resolve_URI_From_Template_Folder
    [Arguments]    ${folder}    ${mapping_as_string}
    [Documentation]    Read URI template from folder, strip endline, make changes according to mapping, return the result.
    ${uri_template}=    OperatingSystem.Get_File    ${folder}${/}config.uri
    BuiltIn.Log    ${uri_template}
    ${uri_part}=    Strip_Endline_And_Apply_Substitutions_From_Mapping    ${uri_template}    ${mapping_as_string}
    [Return]    ${uri_part}

Resolve_Xml_Data_From_Template_Folder
    [Arguments]    ${folder}    ${mapping_as_string}
    [Documentation]    Read XML data template from folder, strip endline, make changes according to mapping, return the result.
    ${data_template}=    OperatingSystem.Get_File    ${folder}${/}data.xml
    BuiltIn.Log    ${data_template}
    ${xml_data}=    Strip_Endline_And_Apply_Substitutions_From_Mapping    ${data_template}    ${mapping_as_string}
    [Return]    ${xml_data}

Resolve_Json_Data_From_Template_Folder
    [Arguments]    ${folder}    ${mapping_as_string}
    [Documentation]    Read JSON data template from folder, strip endline, make changes according to mapping, return the result.
    ${data_template}=    OperatingSystem.Get_File    ${folder}${/}data.json
    BuiltIn.Log    ${data_template}
    ${json_data}=    Strip_Endline_And_Apply_Substitutions_From_Mapping    ${data_template}    ${mapping_as_string}
    [Return]    ${json_data}

Strip_Endline_And_Apply_Substitutions_From_Mapping
    [Arguments]    ${template_as_string}    ${mapping_as_string}
    [Documentation]    Strip endline, apply substitutions, Log and return the result.
    # Robot Framework does not understand dictionaries well, so resort to Evaluate.
    # Needs python module "string", and since the template string is expected to contain newline, it has to be enclosed in triple quotes.
    # Using rstrip() removes all trailing whitespace, which is what we want if there is something more than an endline.
    ${final_text}=    BuiltIn.Evaluate    string.Template('''${template_as_string}'''.rstrip()).substitute(${mapping_as_string})    modules=string
    BuiltIn.Log    ${final_text}
    [Return]    ${final_text}

Put_Xml_Config_Module_Via_Restconf
    [Arguments]    ${xml_data}    ${type}    ${name}
    [Documentation]    Put new XML configuration to config:modules URI based on given module type and name.
    # Also no slash here
    Put_Xml_Config_Via_Restconf    config:modules/module/${type}/${name}    ${xml_data}

Put_Xml_Config_Service_Via_Restconf
    [Arguments]    ${xml_data}    ${type}    ${name}
    [Documentation]    Put new XML configuration to config:services URI based on given service type and instance name.
    Put_Xml_Config_Via_Restconf    config:services/service/${type}/config:instance/${name}    ${xml_data}

Put_Xml_Config_Via_Restconf
    [Arguments]    ${uri_part}    ${xml_data}
    [Documentation]    Put XML data to given controller-config URI, check reponse text is empty and status_code is one of allowed ones.
    BuiltIn.Log    ${uri_part}
    BuiltIn.Log    ${xml_data}
    ${response}=    RequestsLibrary.Put    cvr_session    ${uri_part}    data=${xml_data}
    BuiltIn.Log    ${response.text}
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Should_Be_Empty    ${response.text}
    BuiltIn.Should_Contain    ${allowed_status_codes}    ${response.status_code}

Get_Xml_Config_Via_Restconf
    [Arguments]    ${uri_part}
    [Documentation]    Get XML data from given controller-config URI, check status_code is one of allowed ones, return response text.
    BuiltIn.Log    ${uri_part}
    ${response}=    RequestsLibrary.Get    cvr_session    ${uri_part}    headers=${ACCEPT_XML}
    BuiltIn.Log    ${response.text}
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Should_Contain    ${allowed_status_codes}    ${response.status_code}
    [Return]    ${response.text}

Get_Json_Config_Via_Restconf
    [Arguments]    ${uri_part}
    [Documentation]    Get XML data from given controller-config URI, check status_code is one of allowed ones, return response text.
    BuiltIn.Log    ${uri_part}
    ${response}=    RequestsLibrary.Get    cvr_session    ${uri_part}    headers=${ACCEPT_JSON}
    BuiltIn.Log    ${response.text}
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Should_Contain    ${allowed_status_codes}    ${response.status_code}
    [Return]    ${response.text}

Delete_Config_Via_Restconf
    [Arguments]    ${uri_part}
    [Documentation]    Delete resource at controller-config URI, check reponse text is empty and status_code is 204.
    BuiltIn.Log    ${uri_part}
    ${response}=    RequestsLibrary.Delete    cvr_session    ${uri_part}
    BuiltIn.Log    ${response.text}
    BuiltIn.Should_Be_Empty    ${response.text}
    BuiltIn.Should_Contain    ${allowed_status_codes}    ${response.status_code}

Post_Xml_Config_Module_Via_Restconf
    [Arguments]    ${xml_data}
    [Documentation]    Post new XML configuration to config:modules.
    # Also no slash here
    Post_Xml_Config_Via_Restconf    config:modules    ${xml_data}

Post_Xml_Config_Service_Via_Restconf
    [Arguments]    ${xml_data}
    [Documentation]    Post new XML configuration to config:services.
    Post_Xml_Config_Via_Restconf    config:services    ${xml_data}

Post_Xml_Config_Via_Restconf
    [Arguments]    ${uri_part}    ${xml_data}
    [Documentation]    Post XML data to given controller-config URI, check reponse text is empty and status_code is 204.
    # As seen in previous two Keywords, Post does not need long specific URI.
    # But during Lithium development, Post ceased to do merge, so those Keywords do not work anymore.
    # This Keyword can still be used with specific URI to create a new container and fail if a container was already present.
    ${response}=    RequestsLibrary.Post_Request    cvr_session    ${uri_part}    data=${xml_data}
    BuiltIn.Log    ${response.text}
    BuiltIn.Should_Be_Empty    ${response.text}
    BuiltIn.Should_Be_Equal_As_Strings    ${response.status_code}    204

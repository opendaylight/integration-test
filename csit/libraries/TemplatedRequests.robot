*** Settings ***
Documentation     Resource for supporting http Requests based on data stored in files.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This Resource currently calls RequestsLibrary directly,
...               so it does not work with AuthStandalone or similar.
...               This Resource does not maintain any internal Sessions.
...               If caller does not provide any, session with alias "default" is used.
...               There is a helper Keyword to create the "default" session.
...               The session used is assumed to have most things pre-configured appropriately,
...               which includes auth, host, port and (lack of) base uri.
...               It is recommended to have everything past port (for example /restconf) be defined
...               not in session but in uri data in individual templates.
...               Headers are set in Keywords appropriately.
...
...               These Keywords contain frequent BuiltIn.Log invocations,
...               so they are not suites for scale or performance suites.
...
...               The main strength of this library are *_Templated* keywords
...               User gives a path to directory where files with templates for uri
...               and XML (or JSON) data are present, and a mapping with substitution to make;
...               the keywords will take it from there.
...               Mapping can be given as dict object, or as its json text representation.
...
...               Verify_* keywords are useful for checking responses built from a template.
...               For JSON responses, there is a support for indenting, sorting and diff-ing.
...
...               This resource has evolved from ConfigViaRestconf and NetconfViaRestconf.
...               TODO: Migrate suites to this Resource and remove *ViaRestconf Resources.
...
...               One typical use of this Resource is to make runtime changes to ODL configuration.
...               Different ODL parts have varying ways of configuration,
...               this library affects only the Config Subsystem way.
...               Config Subsystem has (apart Java APIs mostly available only from inside of ODL)
...               NETCONF server as its publicly available entry point.
...               Netconf-connector feature makes this netconf server available for RESTCONF calls.
...               Unfortunately, uris and data payloads tend to be quite convoluted,
...               so using RequestsLibrary directly from test cases is unwieldy.
...               Be careful to use appropriate feature, odl-netconf-connector* does not work in cluster.
...
...               This implementation relies on file names to distinguis data.
...               Here is a table so that users can create their own templates:
...               Traditional filenames and their meaning:
...               * location.uri    template with uri
...               * data.xml    template with xml data to send
...               * data.json    template with json data to send
...               * expected.xml    template with xml response to expect
...               * expected.json    template with json response to expect
...
...               Rules for ordering Keywords within this Resource:
...               1. User friendlier Keywords first.
...               2. Higher-level Keywords first.
...               3. Json before Xml.
...               4. Get, Put, Post, Delete, Verify.
...               Motivation: Users read from the start, so it is important
...               to offer them the better-to-use Keywords first.
...               https://wiki.opendaylight.org/view/Integration/Test/Test_Code_Guidelines#Keyword_ordering
...               In this case, templates are nicer that raw data,
...               *_As_* keywords are better than messing wth explicit header dicts,
...               Json is less prone to element ordering issues
...               and Put does not fail on existing element, also it does not allow
...               shortened URIs (container instead keyed list element) as Post does.
Library           OperatingSystem
Library           RequestsLibrary
Library           Collections
Library           ${CURDIR}/HsfJson/hsf_json.py
Variables         ${CURDIR}/../variables/Variables.py

*** Variables ***
# TODO: Make the following list more narrow when Bug 2594 is fixed.
@{ALLOWED_STATUS_CODES}    ${200}    ${201}    ${204}    # List of integers, not strings. Used by both PUT and DELETE.
# FIXME: Use a global variable from Variables.py
${TemplatedRequests__temp_dir}    /tmp

*** Keywords ***
Create_Default_Session
    [Arguments]    ${url}=http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    ${auth}=${AUTH}
    [Documentation]    Create "default" session to ${url} with default authentication.
    ...    This Keyword is in this Resource only so that user do not need to call RequestsLibrary directly.
    RequestsLibrary.Create_Session    alias=default    url=${url}    auth=${auth}

Get_As_Json_Templated
    [Arguments]    ${folder}    ${mapping}={}    ${session}=default
    [Documentation]    Add arguments sensible for JSON data, return Get_Templated response text.
    ${response_text} =    Get_Templated    folder=${folder}    mapping=${mapping}    accept=${ACCEPT_JSON}    session=${session}    normalize_json=True
    [Return]    ${response_text}

Get_As_Xml_Templated
    [Arguments]    ${folder}    ${mapping}={}    ${session}=default
    [Documentation]    Add arguments sensible for XML data, return Get_Templated response text.
    ${response_text} =    Get_Templated    folder=${folder}    mapping=${mapping}    accept=${ACCEPT_XML}    session=${session}    normalize_json=False
    [Return]    ${response_text}

Put_As_Json_Templated
    [Arguments]    ${folder}    ${mapping}={}    ${session}=default
    [Documentation]    Add arguments sensible for JSON data, return Put_Templated response text.
    ${response_text} =    Put_Templated    folder=${folder}    data_filename=data.json    mapping=${mapping}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}    normalize_json=True
    [Return]    ${response_text}

Put_As_Xml_Templated
    [Arguments]    ${folder}    ${mapping}={}    ${session}=default
    [Documentation]    Add arguments sensible for XML data, return Put_Templated response text.
    ${response_text} =    Put_Templated    folder=${folder}    data_filename=data.xml    mapping=${mapping}    accept=${ACCEPT_XML}    content_type=${HEADERS_XML}    session=${session}    normalize_json=False
    [Return]    ${response_text}

Post_As_Json_Templated
    [Arguments]    ${folder}    ${mapping}={}    ${session}=default
    [Documentation]    Add arguments sensible for JSON data, return Post_Templated response text.
    ${response_text} =    Post_Templated    folder=${folder}    data_filename=data.json    mapping=${mapping}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}    normalize_json=True
    [Return]    ${response_text}

Post_As_Xml_Templated
    [Arguments]    ${folder}    ${mapping}={}    ${session}=default
    [Documentation]    Add arguments sensible for XML data, return Post_Templated response text.
    ${response_text} =    Post_Templated    folder=${folder}    data_filename=data.xml    mapping=${mapping}    accept=${ACCEPT_XML}    content_type=${HEADERS_XML}    session=${session}    normalize_json=False
    [Return]    ${response_text}

Delete_Templated
    [Arguments]    ${folder}    ${mapping}={}    ${session}=default
    [Documentation]    Resolve URI from folder, issue DELETE request.
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${folder}    filename=location.uri    mapping=${mapping}
    ${response_text} =    Delete_From_Uri    uri=${uri}    session=${session}
    [Return]    ${response_text}

Verify_Response_As_Json_Templated
    [Arguments]    ${response}    ${folder}    ${mapping}={}
    [Documentation]    Resolve expected JSON data, should be equal to provided \${response} after normalization.
    Verify_Response_Templated    response=${response}    folder=${folder}    filename=data.json    mapping=${mapping}    normalize_json=True

Verify_Response_As_Xml_Templated
    [Arguments]    ${response}    ${folder}    ${mapping}={}
    [Documentation]    Resolve expected XML data, should be equal to provided \${response} exactly.
    Verify_Response_Templated    response=${response}    folder=${folder}    filename=data.xml    mapping=${mapping}    normalize_json=False

Get_As_Json_From_Uri
    [Arguments]    ${uri}    ${session}=default
    [Documentation]    Specify JSON headers and return Get_From_Uri normalized response text.
    ${response_text} =    Get_From_Uri    uri=${uri}    accept=${ACCEPT_JSON}    session=${session}    normalize_json=True
    [Return]    ${response_text}

Get_As_Xml_From_Uri
    [Arguments]    ${uri}    ${session}=default
    [Documentation]    Specify XML headers and return Get_From_Uri response text.
    ${response_text} =    Get_From_Uri    uri=${uri}    accept=${ACCEPT_XML}    session=${session}    normalize_json=False
    [Return]    ${response_text}

Put_As_Json_To_Uri
    [Arguments]    ${uri}    ${data}    ${session}=default
    [Documentation]    Specify JSON headers and return Put_To_Uri normalized response text.
    ...    Yang json content type is used as a workaround to RequestsLibrary json conversion eagerness.
    ${response_text} =    Put_To_Uri    uri=${uri}    data=${data}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}    normalize_json=True
    [Return]    ${response_text}

Put_As_Xml_To_Uri
    [Arguments]    ${uri}    ${data}    ${session}=default
    [Documentation]    Specify XML headers and return Put_To_Uri response text.
    ${response_text} =    Put_To_Uri    uri=${uri}    data=${data}    accept=${ACCEPT_XML}    content_type=${HEADERS_XML}    session=${session}    normalize_json=False
    [Return]    ${response_text}

Post_As_Json_To_Uri
    [Arguments]    ${uri}    ${data}    ${session}=default
    [Documentation]    Specify JSON headers and return Post_To_Uri normalized response text.
    ...    Yang json content type is used as a workaround to RequestsLibrary json conversion eagerness.
    ${response_text} =    Post_To_Uri    uri=${uri}    data=${data}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}    normalize_json=True
    [Return]    ${response_text}

Post_As_Xml_To_Uri
    [Arguments]    ${uri}    ${data}    ${session}=default
    [Documentation]    Specify XML headers and return Post_To_Uri response text.
    ${response_text} =    Post_To_Uri    uri=${uri}    data=${data}    accept=${ACCEPT_XML}    content_type=${HEADERS_XML}    session=${session}    normalize_json=False
    [Return]    ${response_text}

Delete_From_Uri
    [Arguments]    ${uri}    ${session}=default
    [Documentation]    DELETE resource at URI, check status_code and return response text..
    BuiltIn.Log    ${uri}
    ${response} =    RequestsLibrary.Delete_Request    alias=${session}    ${uri}
    Check_Status_Code    ${response}
    [Return]    ${response.text}

Get_Templated
    [Arguments]    ${folder}    ${accept}    ${mapping}={}    ${session}=default    ${normalize_json}=False
    [Documentation]    Resolve URI from folder, call Get_From_Uri, return response text.
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${folder}    filename=location.uri    mapping=${mapping}
    ${response_text} =    Get_From_Uri    uri=${uri}    accept=${accept}    session=${session}    normalize_json=${normalize_json}
    [Return]    ${response_text}

Put_Templated
    [Arguments]    ${folder}    ${data_filename}    ${content_type}    ${accept}    ${mapping}={}    ${session}=default    ${normalize_json}=False
    [Documentation]    Resolve URI and data from folder, call Put_To_Uri, return response text.
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${folder}    filename=location.uri    mapping=${mapping}
    ${data} =    Resolve_Text_From_Template_Folder    folder=${folder}    filename=${data_filename}    mapping=${mapping}
    ${response_text} =    Put_To_Uri    uri=${uri}    data=${data}    content_type=${content_type}    accept=${accept}    session=${session}    normalize_json=${normalize_json}
    [Return]    ${response_text}

Post_Templated
    [Arguments]    ${folder}    ${data_filename}    ${content_type}    ${accept}    ${mapping}={}    ${session}=default    ${normalize_json}=False
    [Documentation]    Resolve URI and data from folder, call Post_To_Uri, return response text.
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${folder}    filename=location.uri    mapping=${mapping}
    ${data} =    Resolve_Text_From_Template_Folder    folder=${folder}    filename=${data_filename}    mapping=${mapping}
    ${response_text} =    Post_To_Uri    uri=${uri}    data=${data}    content_type=${content_type}    accept=${accept}    session=${session}    normalize_json=${normalize_json}
    [Return]    ${response_text}

Verify_Response_Templated
    [Arguments]    ${response}    ${folder}    ${filename}    ${mapping}={}    normalize_json=False
    [Documentation]    Resolve expected text from template, provided response shuld be equal.
    ...    If \${normalize_json}, perform normalization before comparison.
    # TODO: Support for XML-aware comparison could be added, but there are issues with namespaces and similar.
    ${expected_text}=    Resolve_Text_From_Template_Folder    folder=${folder}    filename=${filename}    mapping=${mapping}
    BuiltIn.Run_Keyword_If    ${normalize_json}    Normalize_Jsons_And_Compare    ${expected_text}    ${response}
    ...    ELSE    BuiltIn.Should_Be_Equal    ${expected_xml}    ${response}

Get_From_Uri
    [Arguments]    ${uri}    ${accept}    ${session}=default    ${normalize_json}=False
    [Documentation]    GET data from given URI, check status code and return response text.
    ...    \${accept} is a mandatory Python object with headers to use.
    ...    If \${normalize_json}, normalize text before returning.
    BuiltIn.Log    ${uri}
    BuiltIn.Log    ${accept}
    ${response} =    RequestsLibrary.Get_Request    alias=${session}    uri=${uri}    headers=${accept}
    Check_Status_Code    ${response}
    BuiltIn.Run_Keyword_Unless    ${normalize_json}    BuiltIn.Return_From_Keyword    ${response.text}
    ${text_normalized} =    hsf_json.Hsf_Json    ${response.text}
    [Return]    ${text_normalized}

Put_To_Uri
    [Arguments]    ${uri}    ${data}    ${content_type}    ${accept}    ${session}=default    ${normalize_json}=False
    [Documentation]    PUT data to given URI, check status code and return response text.
    ...    \${content_type} and \${accept} are mandatory Python objects with headers to use.
    ...    If \${normalize_json}, normalize text before returning.
    BuiltIn.Log    ${uri}
    BuiltIn.Log    ${data}
    BuiltIn.Log    ${content_type}
    BuiltIn.Log    ${accept}
    ${headers} =    Join_Two_Headers    first=${content_type}    second=${accept}
    ${response} =    RequestsLibrary.Put_Request    alias=${session}    uri=${uri}    data=${data}    headers=${headers}
    Check_Status_Code    ${response}
    BuiltIn.Run_Keyword_Unless    ${normalize_json}    BuiltIn.Return_From_Keyword    ${response.text}
    ${text_normalized} =    hsf_json.Hsf_Json    ${response.text}
    [Return]    ${text_normalized}

Post_To_Uri
    [Arguments]    ${uri}    ${data}    ${content_type}    ${accept}    ${session}=default    ${normalize_json}=False
    [Documentation]    POST data to given URI, check status code and return response text.
    ...    \${content_type} and \${accept} are mandatory Python objects with headers to use.
    ...    If \${normalize_json}, normalize text before returning.
    BuiltIn.Log    ${uri}
    BuiltIn.Log    ${data}
    BuiltIn.Log    ${content_type}
    BuiltIn.Log    ${accept}
    ${headers} =    Join_Two_Headers    first=${content_type}    second=${accept}
    ${response} =    RequestsLibrary.Post_Request    alias=${session}    uri=${uri}    data=${data}    headers=${headers}
    Check_Status_Code    ${response}
    BuiltIn.Run_Keyword_Unless    ${normalize_json}    BuiltIn.Return_From_Keyword    ${response.text}
    ${text_normalized} =    hsf_json.Hsf_Json    ${response.text}
    [Return]    ${text_normalized}

Check_Status_Code
    [Arguments]    ${response}
    [Documentation]    Log response text, check status_code is one of allowed ones.
    # TODO: Remove overlap with keywords from Utils.robot
    BuiltIn.Log    ${response.text}
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Should_Contain    ${ALLOWED_STATUS_CODES}    ${response.status_code}
    # TODO: Add support for 404 on Delete?

Join_Two_Headers
    [Arguments]    ${first}    ${second}
    [Documentation]    Take two dicts, join them, return result. Second argument values take precedence.
    ${accumulator} =    Collections.Copy_Dictionary    ${first}
    ${items_to_add} =    Collections.Get_Dictionary_Items
    Collections.Set_To_Dictionary    dictionary=${accumulator}    items=${items_to_add}
    BuiltIn.Log    ${accumulator}
    [Return]    ${accumulator}

Strip_Endline_And_Apply_Substitutions_From_Mapping
    [Arguments]    ${template_as_string}    ${mapping}
    [Documentation]    Strip endline, apply substitutions, Log and return the result.
    ...    Due to the way BuiltIn.Evaluate works, mapping is accepted both as Python dict object and as its JSON representation.
    # Using rstrip() removes all trailing whitespace, which is what we want if there is something more than an endline.
    ${final_text}=    BuiltIn.Evaluate    string.Template('''${template_as_string}'''.rstrip()).substitute(${mapping})    modules=string
    BuiltIn.Log    ${final_text}
    [Return]    ${final_text}

Resolve_Text_From_Template_Folder
    [Arguments]    ${folder}    ${filename}    ${mapping}
    [Documentation]    Read a template from file in folder, strip endline, make changes according to mapping, return the result.
    ${template}=    OperatingSystem.Get_File    ${folder}${/}${filename}
    BuiltIn.Log    ${template}
    ${text}=    Strip_Endline_And_Apply_Substitutions_From_Mapping    ${template}    ${mapping}
    [Return]    ${text}

Normalize_Jsons_And_Compare
    [Arguments]    ${actual_raw}    ${expected_raw}
    [Documentation]    Use HsfJson to normalize both JSON arguments, compute and Log diff, fail if diff is non-empty.
    ${actual_normalized} =    hsf_json.Hsf_Json    ${actual_raw}
    ${expected_normalized} =    hsf_json.Hsf_Json    ${expected_raw}
    TemplatedRequests__Init_Workspace
    OperatingSystem.Create_File    ${TemplatedRequests__file_expected}    ${expected_normalized}
    # When using helper Keywords, this should be already normalized; but the "when" is not guaranteed.
    OperatingSystem.Create_File    ${TemplatedRequests__file_actual}    ${actual_normalized}
    ${diff} =    OperatingSystem.Run    diff -du '${TemplatedRequests__file_expected}' '${TemplatedRequests__file_actual}'
    BuiltIn.Log    ${diff}
    BuiltIn.Should_Be_Empty    ${diff}
    # TODO: Add garbage collection? Check whether temporary data accumulates.

TemplatedRequests__Init_Workspace
    [Documentation]    Remember workspace to use when needed and two temp file names for JSON data handling.
    # Avoid multiple initialization by several downstream libraries.
    ${already_done} =    BuiltIn.Get_Variable_Value    \${TemplatedRequests__has_init_run}    False
    BuiltIn.Return_From_Keyword_If    '${already_done}' != 'False'
    # If anything below fails, we still want to avoid retries.
    BuiltIn.Set_Suite_Variable    \${TemplatedRequests__has_init_run}    True
    ${temp_dir} =    BuiltIn.Get_Variable_Value    \${WORKSPACE}    ${TemplatedRequests__temp_dir}
    BuiltIn.Set_Suite_Variable    \${TemplatedRequests__file_actual}    ${temp_dir}${/}actual.json
    BuiltIn.Set_Suite_Variable    \${TemplatedRequests__file_expected}    ${temp_dir}${/}expected.json

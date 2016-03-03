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
...               The main strength of this library are *_As_*_Templated keywords
...               User gives a path to directory where files with templates for URI
...               and XML (or JSON) data are present, and a mapping with substitution to make;
...               the keywords will take it from there.
...               Mapping can be given as a dict object, or as its json text representation.
...               Simple example (tidy insists on single space where 4 spaces should be):
...               TemplatedRequests.Put_As_Json_Templated folder=${VAR_BASE}/person mapping={"NAME":"joe"}
...               TemplatedRequests.Get_As_Json_Templated folder=${VAR_BASE}/person mapping={"NAME":"joe"} verify=True
...
...               In that example, we are PUTting "person" data with specified value for "NAME" placeholder.
...               We are not verifying PUT response (probably empty string which is not a valid JSON),
...               but we are issuing GET (same URI) and verifying the repsonse matches the same data.
...               Both lines are returning text response, but in the example we are not saving it into variable.
...
...               Optionally, *_As_*_Templated keywords call verification of response.
...               There are separate Verify_* keywords, for users who use intermediate processing.
...               For JSON responses, there is a support for normalizing.
...               *_Templated keywords without As allow more customization at cost of more arguments.
...               *_Uri keywords do not use templates, but may be useful in general,
...               perhaps for users who call Resolve_Text_* keywords.
...               *_As_*_Uri are the less flexible but less argument-heavy versions of *_Uri keywords.
...
...               This resource supports generating data with simple lists.
...               ${iterations} argument control number of items, "$i" will be substituted
...               automatically (not by the provided mapping) with integers starting with ${iter_start} (default 1).
...               For example "iterations=2 iter_start=3" will create items with i=3 and i=4.
...
...               This implementation relies on file names to distinguish data.
...               Each file is expected to end in newline, compiled data has final newline removed.
...               Here is a table so that users can create their own templates:
...               location.uri: Template with URI.
...               data.xml: Template with XML data to send, or GET data to expect.
...               data.json: Template with JSON data to send, or GET data to expect.
...               post_data.xml: Template with XML data to POST, (different from GET response).
...               post_data.json: Template with JSON data to POST, (different from GET response).
...               response.xml: Template with PUT or POST XML response to expect.
...               response.json: Template with PUT or POST JSON response to expect.
...               *.prolog.*: Temlate with data before iterated items.
...               *.item.*: Template with data piece corresponding to one item.
...               *.epilog.*: Temlate with data after iterated items.
...
...               One typical use of this Resource is to make runtime changes to ODL configuration.
...               Different ODL parts have varying ways of configuration,
...               this library affects only the Config Subsystem way.
...               Config Subsystem has (except for Java APIs mostly available only from inside of ODL)
...               a NETCONF server as its publicly available entry point.
...               Netconf-connector feature makes this netconf server available for RESTCONF calls.
...               Be careful to use appropriate feature, odl-netconf-connector* does not work in cluster.
...
...               This Resource currently calls RequestsLibrary directly,
...               so it does not work with AuthStandalone or similar.
...               This Resource does not maintain any internal Sessions.
...               If caller does not provide any, session with alias "default" is used.
...               There is a helper Keyword to create the "default" session.
...               The session used is assumed to have most things pre-configured appropriately,
...               which includes auth, host, port and (lack of) base URI.
...               It is recommended to have everything past port (for example /restconf) be defined
...               not in the session, but in URI data of individual templates.
...               Headers are set in Keywords appropriately.
...
...               These Keywords contain frequent BuiltIn.Log invocations,
...               so they are not suited for scale or performance suites.
...               And as usual, performance tests should use specialized utilities,
...               as Robot in general and this Resource specifically will be too slow.
...
...               As this Resource makes assumptions about intended headers,
...               it is not flexible enough for suites specifically testing Restconf corner cases.
...               Also, list of allowed http status codes is quite rigid and broad.
...
...               Rules for ordering Keywords within this Resource:
...               1. User friendlier Keywords first.
...               2. Get, Put, Post, Delete, Verify.
...               3. Within class of equally usable, use order in which a suite would call them.
...               4. Higher-level Keywords first.
...               5. Json before Xml.
...               Motivation: Users read from the start, so it is important
...               to offer them the better-to-use Keywords first.
...               https://wiki.opendaylight.org/view/Integration/Test/Test_Code_Guidelines#Keyword_ordering
...               In this case, templates are nicer that raw data,
...               *_As_* keywords are better than messing wth explicit header dicts,
...               Json is less prone to element ordering issues.
...               PUT does not fail on existing element, also it does not allow
...               shortened URIs (container instead keyed list element) as Post does.
...
...               TODO: Add ability to override allowed status codes,
...               so that negative tests do not need to parse the failure message.
...
...               TODO: Migrate suites to this Resource and remove *ViaRestconf Resources.
...
...               TODO: Currently the verification step is only in *_As_*_Templated keywords.
...               It could be moved to "non-as" *_Templated ones,
...               but that would take even more horizontal space. Is it worth doing?
...
...               TODO: Should iterations=0 be supported for JSON (remove [])?
...
...               TODO: Currently, ${ACCEPT_EMPTY} is used for JSON-expecting requests.
...               perhaps explicit ${ACCEPT_JSON} will be better, even if it sends few bytes more?
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           ${CURDIR}/norm_json.py
Variables         ${CURDIR}/../variables/Variables.py

*** Variables ***
# TODO: Make the following list more narrow when Bug 2594 is fixed.
@{ALLOWED_STATUS_CODES}    ${200}    ${201}    ${204}    # List of integers, not strings. Used by both PUT and DELETE.

*** Keywords ***
Create_Default_Session
    [Arguments]    ${url}=http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    ${auth}=${AUTH}
    [Documentation]    Create "default" session to ${url} with default authentication.
    ...    This Keyword is in this Resource only so that user do not need to call RequestsLibrary directly.
    RequestsLibrary.Create_Session    alias=default    url=${url}    auth=${auth}

Get_As_Json_Templated
    [Arguments]    ${folder}    ${mapping}={}    ${session}=default    ${verify}=False    ${iterations}=${EMPTY}    ${iter_start}=1
    [Documentation]    Add arguments sensible for JSON data, return Get_Templated response text.
    ...    Optionally, verification against JSON data (may be iterated) is called.
    ${response_text} =    Get_Templated    folder=${folder}    mapping=${mapping}    accept=${ACCEPT_EMPTY}    session=${session}    normalize_json=True
    BuiltIn.Run_Keyword_If    ${verify}    Verify_Response_As_Json_Templated    response=${response_text}    folder=${folder}    base_name=data    mapping=${mapping}
    ...    iterations=${iterations}    iter_start=${iter_start}
    [Return]    ${response_text}

Get_As_Xml_Templated
    [Arguments]    ${folder}    ${mapping}={}    ${session}=default    ${verify}=False    ${iterations}=${EMPTY}    ${iter_start}=1
    [Documentation]    Add arguments sensible for XML data, return Get_Templated response text.
    ...    Optionally, verification against XML data (may be iterated) is called.
    ${response_text} =    Get_Templated    folder=${folder}    mapping=${mapping}    accept=${ACCEPT_XML}    session=${session}    normalize_json=False
    BuiltIn.Run_Keyword_If    ${verify}    Verify_Response_As_Xml_Templated    response=${response_text}    folder=${folder}    base_name=data    mapping=${mapping}
    ...    iterations=${iterations}    iter_start=${iter_start}
    [Return]    ${response_text}

Put_As_Json_Templated
    [Arguments]    ${folder}    ${mapping}={}    ${session}=default    ${verify}=False    ${iterations}=${EMPTY}    ${iter_start}=1
    [Documentation]    Add arguments sensible for JSON data, return Put_Templated response text.
    ...    Optionally, verification against response.json (no iteration) is called.
    ${response_text} =    Put_Templated    folder=${folder}    base_name=data    extension=json    accept=${ACCEPT_EMPTY}    content_type=${HEADERS_YANG_JSON}
    ...    mapping=${mapping}    session=${session}    normalize_json=True    endline=${\n}    iterations=${iterations}    iter_start=${iter_start}
    BuiltIn.Run_Keyword_If    ${verify}    Verify_Response_As_Json_Templated    response=${response_text}    folder=${folder}    base_name=response    mapping=${mapping}
    [Return]    ${response_text}

Put_As_Xml_Templated
    [Arguments]    ${folder}    ${mapping}={}    ${session}=default    ${verify}=False    ${iterations}=${EMPTY}    ${iter_start}=1
    [Documentation]    Add arguments sensible for XML data, return Put_Templated response text.
    ...    Optionally, verification against response.xml (no iteration) is called.
    # In case of iterations, we use endlines in data to send, as it should not matter and it is more readable.
    ${response_text} =    Put_Templated    folder=${folder}    base_name=data    extension=xml    accept=${ACCEPT_XML}    content_type=${HEADERS_XML}
    ...    mapping=${mapping}    session=${session}    normalize_json=False    endline=${\n}    iterations=${iterations}    iter_start=${iter_start}
    BuiltIn.Run_Keyword_If    ${verify}    Verify_Response_As_Xml_Templated    response=${response_text}    folder=${folder}    base_name=response    mapping=${mapping}
    [Return]    ${response_text}

Post_As_Json_Templated
    [Arguments]    ${folder}    ${mapping}={}    ${session}=default    ${verify}=False    ${iterations}=${EMPTY}    ${iter_start}=1
    [Documentation]    Add arguments sensible for JSON data, return Post_Templated response text.
    ...    Optionally, verification against response.json (no iteration) is called.
    ${response_text} =    Post_Templated    folder=${folder}    base_name=data    extension=json    accept=${ACCEPT_EMPTY}    content_type=${HEADERS_YANG_JSON}
    ...    mapping=${mapping}    session=${session}    normalize_json=True    endline=${\n}    iterations=${iterations}    iter_start=${iter_start}
    BuiltIn.Run_Keyword_If    ${verify}    Verify_Response_As_Json_Templated    response=${response_text}    folder=${folder}    base_name=response    mapping=${mapping}
    [Return]    ${response_text}

Post_As_Xml_Templated
    [Arguments]    ${folder}    ${mapping}={}    ${session}=default    ${verify}=False    ${iterations}=${EMPTY}    ${iter_start}=1
    [Documentation]    Add arguments sensible for XML data, return Post_Templated response text.
    ...    Optionally, verification against response.xml (no iteration) is called.
    # In case of iterations, we use endlines in data to send, as it should not matter and it is more readable.
    ${response_text} =    Post_Templated    folder=${folder}    base_name=data    extension=xml    accept=${ACCEPT_XML}    content_type=${HEADERS_XML}
    ...    mapping=${mapping}    session=${session}    normalize_json=False    endline=${\n}    iterations=${iterations}    iter_start=${iter_start}
    BuiltIn.Run_Keyword_If    ${verify}    Verify_Response_As_Xml_Templated    response=${response_text}    folder=${folder}    base_name=response    mapping=${mapping}
    [Return]    ${response_text}

Delete_Templated
    [Arguments]    ${folder}    ${mapping}={}    ${session}=default
    [Documentation]    Resolve URI from folder, issue DELETE request.
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${folder}    base_name=location    extension=uri    mapping=${mapping}
    ${response_text} =    Delete_From_Uri    uri=${uri}    session=${session}
    [Return]    ${response_text}

Verify_Response_As_Json_Templated
    [Arguments]    ${response}    ${folder}    ${base_name}=response    ${mapping}={}    ${iterations}=${EMPTY}    ${iter_start}=1
    [Documentation]    Resolve expected JSON data, should be equal to provided \${response}.
    ...    JSON normalization is used, endlines enabled for readability.
    Verify_Response_Templated    response=${response}    folder=${folder}    base_name=${base_name}    extension=json    mapping=${mapping}    normalize_json=True
    ...    endline=${\n}    iterations=${iterations}    iter_start=${iter_start}

Verify_Response_As_Xml_Templated
    [Arguments]    ${response}    ${folder}    ${base_name}=response    ${mapping}={}    ${iterations}=${EMPTY}    ${iter_start}=1
    [Documentation]    Resolve expected XML data, should be equal to provided \${response}.
    ...    Endline set to empty, as this Resource does not support indented XML comparison.
    Verify_Response_Templated    response=${response}    folder=${folder}    base_name=${base_name}    extension=xml    mapping=${mapping}    normalize_json=False
    ...    endline=${EMPTY}    iterations=${iterations}    iter_start=${iter_start}

Get_As_Json_From_Uri
    [Arguments]    ${uri}    ${session}=default
    [Documentation]    Specify JSON headers and return Get_From_Uri normalized response text.
    ${response_text} =    Get_From_Uri    uri=${uri}    accept=${ACCEPT_EMPTY}    session=${session}    normalize_json=True
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
    ${response_text} =    Put_To_Uri    uri=${uri}    data=${data}    accept=${ACCEPT_EMPTY}    content_type=${HEADERS_YANG_JSON}    session=${session}
    ...    normalize_json=True
    [Return]    ${response_text}

Put_As_Xml_To_Uri
    [Arguments]    ${uri}    ${data}    ${session}=default
    [Documentation]    Specify XML headers and return Put_To_Uri response text.
    ${response_text} =    Put_To_Uri    uri=${uri}    data=${data}    accept=${ACCEPT_XML}    content_type=${HEADERS_XML}    session=${session}
    ...    normalize_json=False
    [Return]    ${response_text}

Post_As_Json_To_Uri
    [Arguments]    ${uri}    ${data}    ${session}=default
    [Documentation]    Specify JSON headers and return Post_To_Uri normalized response text.
    ...    Yang json content type is used as a workaround to RequestsLibrary json conversion eagerness.
    ${response_text} =    Post_To_Uri    uri=${uri}    data=${data}    accept=${ACCEPT_EMPTY}    content_type=${HEADERS_YANG_JSON}    session=${session}
    ...    normalize_json=True
    [Return]    ${response_text}

Post_As_Xml_To_Uri
    [Arguments]    ${uri}    ${data}    ${session}=default
    [Documentation]    Specify XML headers and return Post_To_Uri response text.
    ${response_text} =    Post_To_Uri    uri=${uri}    data=${data}    accept=${ACCEPT_XML}    content_type=${HEADERS_XML}    session=${session}
    ...    normalize_json=False
    [Return]    ${response_text}

Delete_From_Uri
    [Arguments]    ${uri}    ${session}=default
    [Documentation]    DELETE resource at URI, check status_code and return response text..
    BuiltIn.Log    ${uri}
    ${response} =    RequestsLibrary.Delete_Request    alias=${session}    uri=${uri}
    Check_Status_Code    ${response}
    [Return]    ${response.text}

Get_Templated
    [Arguments]    ${folder}    ${accept}    ${mapping}={}    ${session}=default    ${normalize_json}=False
    [Documentation]    Resolve URI from folder, call Get_From_Uri, return response text.
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${folder}    base_name=location    extension=uri    mapping=${mapping}
    ${response_text} =    Get_From_Uri    uri=${uri}    accept=${accept}    session=${session}    normalize_json=${normalize_json}
    [Return]    ${response_text}

Put_Templated
    [Arguments]    ${folder}    ${base_name}    ${extension}    ${content_type}    ${accept}    ${mapping}={}
    ...    ${session}=default    ${normalize_json}=False    ${endline}=${\n}    ${iterations}=${EMPTY}    ${iter_start}=1
    [Documentation]    Resolve URI and data from folder, call Put_To_Uri, return response text.
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${folder}    base_name=location    extension=uri    mapping=${mapping}
    ${data} =    Resolve_Text_From_Template_Folder    folder=${folder}    base_name=${base_name}    extension=${extension}    mapping=${mapping}    endline=${endline}
    ...    iterations=${iterations}    iter_start=${iter_start}
    ${response_text} =    Put_To_Uri    uri=${uri}    data=${data}    content_type=${content_type}    accept=${accept}    session=${session}
    ...    normalize_json=${normalize_json}
    [Return]    ${response_text}

Post_Templated
    [Arguments]    ${folder}    ${base_name}    ${extension}    ${content_type}    ${accept}    ${mapping}={}
    ...    ${session}=default    ${normalize_json}=False    ${endline}=${\n}    ${iterations}=${EMPTY}    ${iter_start}=1
    [Documentation]    Resolve URI and data from folder, call Post_To_Uri, return response text.
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${folder}    base_name=location    extension=uri    mapping=${mapping}
    ${data} =    Resolve_Text_From_Template_Folder    folder=${folder}    name_prefix=post_    base_name=${base_name}    extension=${extension}    mapping=${mapping}
    ...    endline=${endline}    iterations=${iterations}    iter_start=${iter_start}
    ${response_text} =    Post_To_Uri    uri=${uri}    data=${data}    content_type=${content_type}    accept=${accept}    session=${session}
    ...    normalize_json=${normalize_json}
    [Return]    ${response_text}

Verify_Response_Templated
    [Arguments]    ${response}    ${folder}    ${base_name}    ${extension}    ${mapping}={}    ${normalize_json}=False
    ...    ${endline}=${\n}    ${iterations}=${EMPTY}    ${iter_start}=1
    [Documentation]    Resolve expected text from template, provided response shuld be equal.
    ...    If \${normalize_json}, perform normalization before comparison.
    # TODO: Support for XML-aware comparison could be added, but there are issues with namespaces and similar.
    ${expected_text} =    Resolve_Text_From_Template_Folder    folder=${folder}    base_name=${base_name}    extension=${extension}    mapping=${mapping}    endline=${endline}
    ...    iterations=${iterations}    iter_start=${iter_start}
    BuiltIn.Run_Keyword_If    ${normalize_json}    Normalize_Jsons_And_Compare    expected_raw=${expected_text}    actual_raw=${response}
    ...    ELSE    BuiltIn.Should_Be_Equal    ${expected_text}    ${response}

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
    ${text_normalized} =    norm_json.normalize_json_text    ${response.text}
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
    ${text_normalized} =    norm_json.normalize_json_text    ${response.text}
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
    ${text_normalized} =    norm_json.normalize_json_text    ${response.text}
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
    ${items_to_add} =    Collections.Get_Dictionary_Items    ${second}
    Collections.Set_To_Dictionary    ${accumulator}    @{items_to_add}
    BuiltIn.Log    ${accumulator}
    [Return]    ${accumulator}

Resolve_Text_From_Template_Folder
    [Arguments]    ${folder}    ${name_prefix}=${EMPTY}    ${base_name}=data    ${extension}=json    ${mapping}={}    ${iterations}=${EMPTY}
    ...    ${iter_start}=1    ${endline}=${\n}
    [Documentation]    Read a template from folder, strip endline, make changes according to mapping, return the result.
    ...    If \${iterations} value is present, put text together from "prolog", "item" and "epilog" parts,
    ...    where additional template variable ${i} goes from ${iter_start}, by one ${iterations} times.
    ...    POST (as opposed to PUT) needs slightly different data, \${name_prefix} may be used to distinguish.
    ...    (Actually, it is GET who formats data differently when URI is a top-level container.)
    BuiltIn.Run_Keyword_And_Return_If    not "${iterations}"    Resolve_Text_From_Template_File    file_path=${folder}${/}${name_prefix}${base_name}.${extension}    mapping=${mapping}
    ${prolog} =    Resolve_Text_From_Template_File    file_path=${folder}${/}${name_prefix}${base_name}.prolog.${extension}    mapping=${mapping}
    ${epilog} =    Resolve_Text_From_Template_File    file_path=${folder}${/}${name_prefix}${base_name}.epilog.${extension}    mapping=${mapping}
    # Even POST uses the same item template (except indentation), so name prefix is ignored.
    ${item_template} =    Resolve_Text_From_Template_File    file_path=${folder}${/}${base_name}.item.${extension}    mapping=${mapping}
    ${items} =    BuiltIn.Create_List
    ${separator} =    BuiltIn.Set_Variable_If    '${extension}' != 'json'    ${endline}    ,${endline}
    : FOR    ${iteration}    IN RANGE    ${iter_start}    ${iterations}+${iter_start}
    \    # Add separator only if we are beyond first item.
    \    BuiltIn.Run_Keyword_If    ${iteration} > ${iter_start}    Collections.Append_To_List    ${items}    ${separator}
    \    ${item} =    BuiltIn.Evaluate    string.Template('''${item_template}''').substitute({"i":"${iteration}"})    modules=string
    \    Collections.Append_To_List    ${items}    ${item}
    # TODO: The following makes ugly result for iterations=0. Should we fix that?
    ${final_text} =    BuiltIn.Catenate    SEPARATOR=    ${prolog}    ${endline}    @{items}    ${endline}
    ...    ${epilog}
    [Return]    ${final_text}

Resolve_Text_From_Template_File
    [Arguments]    ${file_path}    ${mapping}={}
    [Documentation]    Read an Log contents of file, remove endline, perform safe substitution, return result.
    ${template} =    OperatingSystem.Get_File    ${file_path}
    BuiltIn.Log    ${template}
    ${final_text} =    BuiltIn.Evaluate    string.Template('''${template}'''.rstrip()).safe_substitute(${mapping})    modules=string
    # Final text is logged where used.
    [Return]    ${final_text}

Normalize_Jsons_And_Compare
    [Arguments]    ${expected_raw}    ${actual_raw}
    [Documentation]    Use norm_json to normalize both JSON arguments, call Should_Be_Equal.
    ${expected_normalized} =    norm_json.normalize_json_text    ${expected_raw}
    ${actual_normalized} =    norm_json.normalize_json_text    ${actual_raw}
    # Should_Be_Equal shall print nice diff-style line comparison.
    BuiltIn.Should_Be_Equal    ${expected_normalized}    ${actual_normalized}
    # TODO: Add garbage collection? Check whether the temporary data accumulates.

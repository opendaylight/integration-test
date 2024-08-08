*** Settings ***
Documentation       Resource for supporting http Requests based on data stored in files.
...
...                 Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...                 The main strength of this library are *_As_*_Templated keywords
...                 User gives a path to directory where files with templates for URI
...                 and XML (or JSON) data are present, and a mapping with substitution to make;
...                 the keywords will take it from there.
...                 Mapping can be given as a dict object, or as its json text representation.
...                 Simple example (tidy insists on single space where 4 spaces should be):
...                 TemplatedRequests.Put_As_Json_Templated folder=${VAR_BASE}/person mapping={"NAME":"joe"}
...                 TemplatedRequests.Get_As_Json_Templated folder=${VAR_BASE}/person mapping={"NAME":"joe"} verify=True
...
...                 In that example, we are PUTting "person" data with specified value for "NAME" placeholder.
...                 We are not verifying PUT response (probably empty string which is not a valid JSON),
...                 but we are issuing GET (same URI) and verifying the repsonse matches the same data.
...                 Both lines are returning text response, but in the example we are not saving it into variable.
...
...                 Optionally, *_As_*_Templated keywords call verification of response.
...                 There are separate Verify_* keywords, for users who use intermediate processing.
...                 For JSON responses, there is a support for normalizing.
...                 *_Templated keywords without As allow more customization at cost of more arguments.
...                 *_Uri keywords do not use templates, but may be useful in general,
...                 perhaps for users who call Resolve_Text_* keywords.
...                 *_As_*_Uri are the less flexible but less argument-heavy versions of *_Uri keywords.
...
...                 This resource supports generating data with simple lists.
...                 ${iterations} argument control number of items, "$i" will be substituted
...                 automatically (not by the provided mapping) with integers starting with ${iter_start} (default 1).
...                 For example "iterations=2 iter_start=3" will create items with i=3 and i=4.
...
...                 This implementation relies on file names to distinguish data.
...                 Each file is expected to end in newline, compiled data has final newline removed.
...                 Here is a table so that users can create their own templates:
...                 location.uri: Template with URI.
...                 data.xml: Template with XML data to send, or GET data to expect.
...                 data.json: Template with JSON data to send, or GET data to expect.
...                 post_data.xml: Template with XML data to POST, (different from GET response).
...                 post_data.json: Template with JSON data to POST, (different from GET response).
...                 response.xml: Template with PUT or POST XML response to expect.
...                 response.json: Template with PUT or POST JSON response to expect.
...                 *.prolog.*: Temlate with data before iterated items.
...                 *.item.*: Template with data piece corresponding to one item.
...                 *.epilog.*: Temlate with data after iterated items.
...
...                 One typical use of this Resource is to make runtime changes to ODL configuration.
...                 Different ODL parts have varying ways of configuration,
...                 this library affects only the Config Subsystem way.
...                 Config Subsystem has (except for Java APIs mostly available only from inside of ODL)
...                 a NETCONF server as its publicly available entry point.
...                 Netconf-connector feature makes this netconf server available for RESTCONF calls.
...                 Be careful to use appropriate feature, odl-netconf-connector* does not work in cluster.
...
...                 This Resource currently calls RequestsLibrary directly,
...                 so it does not work with AuthStandalone or similar.
...                 This Resource does not maintain any internal Sessions.
...                 If caller does not provide any, session with alias "default" is used.
...                 There is a helper Keyword to create the "default" session.
...                 The session used is assumed to have most things pre-configured appropriately,
...                 which includes auth, host, port and (lack of) base URI.
...                 It is recommended to have everything past port (for example /rests) be defined
...                 not in the session, but in URI data of individual templates.
...                 Headers are set in Keywords appropriately. Http session's timout is configurable
...                 both on session level (where it becomes a default value for requests) and on request
...                 level (when present, it overrides the session value). To override the default
...                 value keywords' http_timeout parameter may be used.
...
...                 These Keywords contain frequent BuiltIn.Log invocations,
...                 so they are not suited for scale or performance suites.
...                 And as usual, performance tests should use specialized utilities,
...                 as Robot in general and this Resource specifically will be too slow.
...
...                 As this Resource makes assumptions about intended headers,
...                 it is not flexible enough for suites specifically testing Restconf corner cases.
...                 Also, list of allowed http status codes is quite rigid and broad.
...
...                 Rules for ordering Keywords within this Resource:
...                 1. User friendlier Keywords first.
...                 2. Get, Put, Post, Delete, Verify.
...                 3. Within class of equally usable, use order in which a suite would call them.
...                 4. Higher-level Keywords first.
...                 5. Json before Xml.
...                 Motivation: Users read from the start, so it is important
...                 to offer them the better-to-use Keywords first.
...                 https://wiki.opendaylight.org/view/Integration/Test/Test_Code_Guidelines#Keyword_ordering
...                 In this case, templates are nicer that raw data,
...                 *_As_* keywords are better than messing wth explicit header dicts,
...                 Json is less prone to element ordering issues.
...                 PUT does not fail on existing element, also it does not allow
...                 shortened URIs (container instead keyed list element) as Post does.
...
...                 TODO: Add ability to override allowed status codes,
...                 so that negative tests do not need to parse the failure message.
...
...                 TODO: Migrate suites to this Resource and remove *ViaRestconf Resources.
...
...                 TODO: Currently the verification step is only in *_As_*_Templated keywords.
...                 It could be moved to "non-as" *_Templated ones,
...                 but that would take even more horizontal space. Is it worth doing?
...
...                 TODO: Should iterations=0 be supported for JSON (remove [])?
...
...                 TODO: Currently, ${ACCEPT_EMPTY} is used for JSON-expecting requests.
...                 perhaps explicit ${ACCEPT_JSON} will be better, even if it sends few bytes more?

Library             Collections
Library             OperatingSystem
Library             String
Library             RequestsLibrary
Library             ${CURDIR}/norm_json.py
Resource            ${CURDIR}/../variables/Variables.robot


*** Variables ***
# TODO: Make the following list more narrow when streams without Bug 2594 fix (up to beryllium) are no longer used.
# List of integers, not strings. Used by DELETE if the resource may be not present.
@{ALLOWED_DELETE_STATUS_CODES}
...                                 ${200}
...                                 ${201}
...                                 ${204}
...                                 ${404}
...                                 ${409}
# List of integers, not strings. Used by both PUT and DELETE (if the resource should have been present).
@{ALLOWED_STATUS_CODES}
...                                 ${200}
...                                 ${201}
...                                 ${204}
@{DATA_VALIDATION_ERROR}            ${400}    # For testing mildly negative scenarios where ODL reports user error.
# List of integers, not strings. Used by DELETE if the resource may be not present.
@{DELETED_STATUS_CODES}
...                                 ${404}
...                                 ${409}
# TODO: Add option for delete to require 404.
@{INTERNAL_SERVER_ERROR}            ${500}    # Only for testing severely negative scenarios where ODL cannot recover.
@{KEYS_WITH_BITS}                   op    # the default list with keys to be sorted when norm_json libray is used
@{NO_STATUS_CODES}
# List of integers, not strings. Used in Keystone Authentication when the user is not authorized to use the requested resource.
@{UNAUTHORIZED_STATUS_CODES}
...                                 ${401}


*** Keywords ***
Create_Default_Session
    [Documentation]    Create "default" session to ${url} with authentication and connection parameters.
    ...    This Keyword is in this Resource only so that user do not need to call RequestsLibrary directly.
    [Arguments]    ${url}=http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    ${auth}=${AUTH}    ${timeout}=${DEFAULT_TIMEOUT_HTTP}    ${max_retries}=0
    RequestsLibrary.Create_Session
    ...    default
    ...    url=${url}
    ...    auth=${auth}
    ...    timeout=${timeout}
    ...    max_retries=${max_retries}

Get_As_Json_Templated
    [Documentation]    Add arguments sensible for JSON data, return Get_Templated response text.
    ...    Optionally, verification against JSON data (may be iterated) is called.
    ...    Only subset of JSON data is verified and returned if JMES path is specified in
    ...    file ${folder}${/}jmespath.expr.
    [Arguments]    ${folder}    ${mapping}=&{EMPTY}    ${session}=default    ${verify}=False    ${iterations}=${EMPTY}    ${iter_start}=1
    ...    ${http_timeout}=${EMPTY}    ${log_response}=True    ${iter_j_offset}=0
    ${response_text} =    Get_Templated
    ...    folder=${folder}
    ...    mapping=${mapping}
    ...    accept=${ACCEPT_EMPTY}
    ...    session=${session}
    ...    normalize_json=True
    ...    http_timeout=${http_timeout}
    ...    log_response=${log_response}
    IF    ${verify}
        Verify_Response_As_Json_Templated
        ...    response=${response_text}
        ...    folder=${folder}
        ...    base_name=data
        ...    mapping=${mapping}
        ...    iterations=${iterations}
        ...    iter_start=${iter_start}
        ...    iter_j_offset=${iter_j_offset}
    END
    RETURN    ${response_text}

Get_As_Xml_Templated
    [Documentation]    Add arguments sensible for XML data, return Get_Templated response text.
    ...    Optionally, verification against XML data (may be iterated) is called.
    [Arguments]    ${folder}    ${mapping}=&{EMPTY}    ${session}=default    ${verify}=False    ${iterations}=${EMPTY}    ${iter_start}=1
    ...    ${http_timeout}=${EMPTY}    ${iter_j_offset}=0
    ${response_text} =    Get_Templated
    ...    folder=${folder}
    ...    mapping=${mapping}
    ...    accept=${ACCEPT_XML}
    ...    session=${session}
    ...    normalize_json=False
    ...    http_timeout=${http_timeout}
    IF    ${verify}
        Verify_Response_As_Xml_Templated
        ...    response=${response_text}
        ...    folder=${folder}
        ...    base_name=data
        ...    mapping=${mapping}
        ...    iterations=${iterations}
        ...    iter_start=${iter_start}
        ...    iter_j_offset=${iter_j_offset}
    END
    RETURN    ${response_text}

Put_As_Json_Templated
    [Documentation]    Add arguments sensible for JSON data, return Put_Templated response text.
    ...    Optionally, verification against response.json (no iteration) is called.
    ...    Only subset of JSON data is verified and returned if JMES path is specified in
    ...    file ${folder}${/}jmespath.expr.
    [Arguments]    ${folder}    ${mapping}=&{EMPTY}    ${session}=default    ${verify}=False    ${iterations}=${EMPTY}    ${iter_start}=1
    ...    ${http_timeout}=${EMPTY}    ${iter_j_offset}=0
    ${response_text} =    Put_Templated
    ...    folder=${folder}
    ...    base_name=data
    ...    extension=json
    ...    accept=${ACCEPT_EMPTY}
    ...    content_type=${HEADERS_YANG_JSON}
    ...    mapping=${mapping}
    ...    session=${session}
    ...    normalize_json=True
    ...    endline=${\n}
    ...    iterations=${iterations}
    ...    iter_start=${iter_start}
    ...    http_timeout=${http_timeout}
    ...    iter_j_offset=${iter_j_offset}
    IF    ${verify}
        Verify_Response_As_Json_Templated
        ...    response=${response_text}
        ...    folder=${folder}
        ...    base_name=response
        ...    mapping=${mapping}
        ...    iter_j_offset=${iter_j_offset}
    END
    RETURN    ${response_text}

Put_As_Xml_Templated
    [Documentation]    Add arguments sensible for XML data, return Put_Templated response text.
    ...    Optionally, verification against response.xml (no iteration) is called.
    [Arguments]    ${folder}    ${mapping}=&{EMPTY}    ${session}=default    ${verify}=False    ${iterations}=${EMPTY}    ${iter_start}=1
    ...    ${http_timeout}=${EMPTY}    ${iter_j_offset}=0
    # In case of iterations, we use endlines in data to send, as it should not matter and it is more readable.
    ${response_text} =    Put_Templated
    ...    folder=${folder}
    ...    base_name=data
    ...    extension=xml
    ...    accept=${ACCEPT_XML}
    ...    content_type=${HEADERS_XML}
    ...    mapping=${mapping}
    ...    session=${session}
    ...    normalize_json=False
    ...    endline=${\n}
    ...    iterations=${iterations}
    ...    iter_start=${iter_start}
    ...    http_timeout=${http_timeout}
    ...    iter_j_offset=${iter_j_offset}
    IF    ${verify}
        Verify_Response_As_Xml_Templated
        ...    response=${response_text}
        ...    folder=${folder}
        ...    base_name=response
        ...    mapping=${mapping}
        ...    iter_j_offset=${iter_j_offset}
    END
    RETURN    ${response_text}

Post_As_Json_Templated
    [Documentation]    Add arguments sensible for JSON data, return Post_Templated response text.
    ...    Optionally, verification against response.json (no iteration) is called.
    ...    Only subset of JSON data is verified and returned if JMES path is specified in
    ...    file ${folder}${/}jmespath.expr.
    ...    Response status code must be one of values from ${explicit_status_codes} if specified or one of set
    ...    created from all positive HTTP status codes together with ${additional_allowed_status_codes}.
    [Arguments]    ${folder}    ${mapping}=&{EMPTY}    ${session}=default    ${verify}=False    ${iterations}=${EMPTY}    ${iter_start}=1
    ...    ${additional_allowed_status_codes}=${NO_STATUS_CODES}    ${explicit_status_codes}=${NO_STATUS_CODES}    ${http_timeout}=${EMPTY}    ${iter_j_offset}=0
    ${response_text} =    Post_Templated
    ...    folder=${folder}
    ...    base_name=data
    ...    extension=json
    ...    accept=${ACCEPT_EMPTY}
    ...    content_type=${HEADERS_YANG_JSON}
    ...    mapping=${mapping}
    ...    session=${session}
    ...    normalize_json=True
    ...    endline=${\n}
    ...    iterations=${iterations}
    ...    iter_start=${iter_start}
    ...    additional_allowed_status_codes=${additional_allowed_status_codes}
    ...    explicit_status_codes=${explicit_status_codes}
    ...    http_timeout=${http_timeout}
    ...    iter_j_offset=${iter_j_offset}
    IF    ${verify}
        Verify_Response_As_Json_Templated
        ...    response=${response_text}
        ...    folder=${folder}
        ...    base_name=response
        ...    mapping=${mapping}
        ...    iter_j_offset=${iter_j_offset}
    END
    RETURN    ${response_text}

Post_As_Json_Rfc8040_Templated
    [Documentation]    Add arguments sensible for JSON data, return Post_Templated response text.
    ...    Optionally, verification against response.json (no iteration) is called.
    ...    Only subset of JSON data is verified and returned if JMES path is specified in
    ...    file ${folder}${/}jmespath.expr.
    ...    Response status code must be one of values from ${explicit_status_codes} if specified or one of set
    ...    created from all positive HTTP status codes together with ${additional_allowed_status_codes}.
    ...    RFC8040 defines RESTCONF protocol, for configuring data defined in YANG version 1
    ...    or YANG version 1.1, using the datastore concepts defined in NETCONF.
    [Arguments]    ${folder}    ${mapping}=&{EMPTY}    ${session}=default    ${verify}=False    ${iterations}=${EMPTY}    ${iter_start}=1
    ...    ${additional_allowed_status_codes}=${NO_STATUS_CODES}    ${explicit_status_codes}=${NO_STATUS_CODES}    ${http_timeout}=${EMPTY}    ${iter_j_offset}=0
    ${response_text} =    Post_Templated
    ...    folder=${folder}
    ...    base_name=data
    ...    extension=json
    ...    accept=${ACCEPT_EMPTY}
    ...    content_type=${HEADERS_YANG_RFC8040_JSON}
    ...    mapping=${mapping}
    ...    session=${session}
    ...    normalize_json=True
    ...    endline=${\n}
    ...    iterations=${iterations}
    ...    iter_start=${iter_start}
    ...    additional_allowed_status_codes=${additional_allowed_status_codes}
    ...    explicit_status_codes=${explicit_status_codes}
    ...    http_timeout=${http_timeout}
    ...    iter_j_offset=${iter_j_offset}
    IF    ${verify}
        Verify_Response_As_Json_Templated
        ...    response=${response_text}
        ...    folder=${folder}
        ...    base_name=response
        ...    mapping=${mapping}
        ...    iter_j_offset=${iter_j_offset}
    END
    RETURN    ${response_text}

Post_As_Xml_Templated
    [Documentation]    Add arguments sensible for XML data, return Post_Templated response text.
    ...    Optionally, verification against response.xml (no iteration) is called.
    [Arguments]    ${folder}    ${mapping}=&{EMPTY}    ${session}=default    ${verify}=False    ${iterations}=${EMPTY}    ${iter_start}=1
    ...    ${additional_allowed_status_codes}=${NO_STATUS_CODES}    ${explicit_status_codes}=${NO_STATUS_CODES}    ${http_timeout}=${EMPTY}    ${iter_j_offset}=0
    # In case of iterations, we use endlines in data to send, as it should not matter and it is more readable.
    ${response_text} =    Post_Templated
    ...    folder=${folder}
    ...    base_name=data
    ...    extension=xml
    ...    accept=${ACCEPT_XML}
    ...    content_type=${HEADERS_XML}
    ...    mapping=${mapping}
    ...    session=${session}
    ...    normalize_json=False
    ...    endline=${\n}
    ...    iterations=${iterations}
    ...    iter_start=${iter_start}
    ...    additional_allowed_status_codes=${additional_allowed_status_codes}
    ...    explicit_status_codes=${explicit_status_codes}
    ...    http_timeout=${http_timeout}
    ...    iter_j_offset=${iter_j_offset}
    IF    ${verify}
        Verify_Response_As_Xml_Templated
        ...    response=${response_text}
        ...    folder=${folder}
        ...    base_name=response
        ...    mapping=${mapping}
        ...    iter_j_offset=${iter_j_offset}
    END
    RETURN    ${response_text}

Delete_Templated
    [Documentation]    Resolve URI from folder, issue DELETE request.
    [Arguments]    ${folder}    ${mapping}=&{EMPTY}    ${session}=default    ${additional_allowed_status_codes}=${NO_STATUS_CODES}    ${http_timeout}=${EMPTY}    ${location}=location
    ${uri} =    Resolve_Text_From_Template_Folder
    ...    folder=${folder}
    ...    base_name=${location}
    ...    extension=uri
    ...    mapping=${mapping}
    ...    percent_encode=True
    ${response_text} =    Delete_From_Uri
    ...    uri=${uri}
    ...    session=${session}
    ...    additional_allowed_status_codes=${additional_allowed_status_codes}
    ...    http_timeout=${http_timeout}
    RETURN    ${response_text}

Verify_Response_As_Json_Templated
    [Documentation]    Resolve expected JSON data, should be equal to provided \${response}.
    ...    JSON normalization is used, endlines enabled for readability.
    [Arguments]    ${response}    ${folder}    ${base_name}=response    ${mapping}=&{EMPTY}    ${iterations}=${EMPTY}    ${iter_start}=1    ${iter_j_offset}=0
    Verify_Response_Templated
    ...    response=${response}
    ...    folder=${folder}
    ...    base_name=${base_name}
    ...    extension=json
    ...    mapping=${mapping}
    ...    normalize_json=True
    ...    endline=${\n}
    ...    iterations=${iterations}
    ...    iter_start=${iter_start}
    ...    iter_j_offset=${iter_j_offset}

Verify_Response_As_Xml_Templated
    [Documentation]    Resolve expected XML data, should be equal to provided \${response}.
    ...    Endline set to empty, as this Resource does not support indented XML comparison.
    [Arguments]    ${response}    ${folder}    ${base_name}=response    ${mapping}=&{EMPTY}    ${iterations}=${EMPTY}    ${iter_start}=1    ${iter_j_offset}=0
    Verify_Response_Templated
    ...    response=${response}
    ...    folder=${folder}
    ...    base_name=${base_name}
    ...    extension=xml
    ...    mapping=${mapping}
    ...    normalize_json=False
    ...    endline=${EMPTY}
    ...    iterations=${iterations}
    ...    iter_start=${iter_start}
    ...    iter_j_offset=${iter_j_offset}

Get_As_Json_From_Uri
    [Documentation]    Specify JSON headers and return Get_From_Uri normalized response text.
    [Arguments]    ${uri}    ${session}=default    ${http_timeout}=${EMPTY}    ${log_response}=True
    ${response_text} =    Get_From_Uri
    ...    uri=${uri}
    ...    accept=${ACCEPT_EMPTY}
    ...    session=${session}
    ...    normalize_json=True
    ...    http_timeout=${http_timeout}
    ...    log_response=${log_response}
    RETURN    ${response_text}

Get_As_Xml_From_Uri
    [Documentation]    Specify XML headers and return Get_From_Uri response text.
    [Arguments]    ${uri}    ${session}=default    ${http_timeout}=${EMPTY}    ${log_response}=True
    ${response_text} =    Get_From_Uri
    ...    uri=${uri}
    ...    accept=${ACCEPT_XML}
    ...    session=${session}
    ...    normalize_json=False
    ...    http_timeout=${http_timeout}
    ...    log_response=${log_response}
    RETURN    ${response_text}

Put_As_Json_To_Uri
    [Documentation]    Specify JSON headers and return Put_To_Uri normalized response text.
    ...    Yang json content type is used as a workaround to RequestsLibrary json conversion eagerness.
    [Arguments]    ${uri}    ${data}    ${session}=default    ${http_timeout}=${EMPTY}
    ${response_text} =    Put_To_Uri
    ...    uri=${uri}
    ...    data=${data}
    ...    accept=${ACCEPT_EMPTY}
    ...    content_type=${HEADERS_YANG_JSON}
    ...    session=${session}
    ...    normalize_json=True
    ...    http_timeout=${http_timeout}
    RETURN    ${response_text}

Put_As_Xml_To_Uri
    [Documentation]    Specify XML headers and return Put_To_Uri response text.
    [Arguments]    ${uri}    ${data}    ${session}=default    ${http_timeout}=${EMPTY}
    ${response_text} =    Put_To_Uri
    ...    uri=${uri}
    ...    data=${data}
    ...    accept=${ACCEPT_XML}
    ...    content_type=${HEADERS_XML}
    ...    session=${session}
    ...    normalize_json=False
    ...    http_timeout=${http_timeout}
    RETURN    ${response_text}

Post_As_Json_To_Uri
    [Documentation]    Specify JSON headers and return Post_To_Uri normalized response text.
    ...    Yang json content type is used as a workaround to RequestsLibrary json conversion eagerness.
    ...    Response status code must be one of values from ${explicit_status_codes} if specified or one of set
    ...    created from all positive HTTP status codes together with ${additional_allowed_status_codes}.
    [Arguments]    ${uri}    ${data}    ${session}=default    ${additional_allowed_status_codes}=${NO_STATUS_CODES}    ${explicit_status_codes}=${NO_STATUS_CODES}    ${http_timeout}=${EMPTY}
    ${response_text} =    Post_To_Uri
    ...    uri=${uri}
    ...    data=${data}
    ...    accept=${ACCEPT_EMPTY}
    ...    content_type=${HEADERS_YANG_JSON}
    ...    session=${session}
    ...    normalize_json=True
    ...    additional_allowed_status_codes=${additional_allowed_status_codes}
    ...    explicit_status_codes=${explicit_status_codes}
    ...    http_timeout=${http_timeout}
    RETURN    ${response_text}

Post_As_Xml_To_Uri
    [Documentation]    Specify XML headers and return Post_To_Uri response text.
    [Arguments]    ${uri}    ${data}    ${session}=default    ${http_timeout}=${EMPTY}
    ${response_text} =    Post_To_Uri
    ...    uri=${uri}
    ...    data=${data}
    ...    accept=${ACCEPT_XML}
    ...    content_type=${HEADERS_XML}
    ...    session=${session}
    ...    normalize_json=False
    ...    http_timeout=${http_timeout}
    RETURN    ${response_text}

Delete_From_Uri
    [Documentation]    DELETE resource at URI, check status_code and return response text..
    [Arguments]    ${uri}    ${session}=default    ${additional_allowed_status_codes}=${NO_STATUS_CODES}    ${http_timeout}=${EMPTY}
    BuiltIn.Log    ${uri}
    IF    """${http_timeout}""" == """${EMPTY}"""
        ${response} =    RequestsLibrary.Delete_On_Session    ${session}    ${uri}
    ELSE
        ${response} =    RequestsLibrary.Delete_On_Session    ${session}    ${uri}    timeout=${http_timeout}
    END
    Check_Status_Code    ${response}    additional_allowed_status_codes=${additional_allowed_status_codes}
    RETURN    ${response.text}

Resolve_Jmes_Path
    [Documentation]    Reads JMES path from file ${folder}${/}jmespath.expr if the file exists and
    ...    returns the JMES path. Empty string is returned otherwise.
    [Arguments]    ${folder}
    ${read_jmes_file} =    BuiltIn.Run Keyword And Return Status
    ...    OperatingSystem.File Should Exist
    ...    ${folder}${/}jmespath.expr
    IF    ${read_jmes_file} == ${true}
        ${jmes_expression} =    OperatingSystem.Get_File    ${folder}${/}jmespath.expr
    ELSE
        ${jmes_expression} =    Set Variable    ${None}
    END
    ${expression} =    BuiltIn.Set Variable If    ${read_jmes_file} == ${true}    ${jmes_expression}    ${EMPTY}
    RETURN    ${expression}

Resolve_Volatiles_Path
    [Documentation]    Reads Volatiles List from file ${folder}${/}volatiles.list if the file exists and
    ...    returns the Volatiles List. Empty string is returned otherwise.
    [Arguments]    ${folder}
    ${read_volatiles_file} =    BuiltIn.Run Keyword And Return Status
    ...    OperatingSystem.File Should Exist
    ...    ${folder}${/}volatiles.list
    IF    ${read_volatiles_file} == ${false}    RETURN    ${EMPTY}
    ${volatiles} =    OperatingSystem.Get_File    ${folder}${/}volatiles.list
    ${volatiles_list} =    String.Split_String    ${volatiles}    ${\n}
    RETURN    ${volatiles_list}

Get_Templated
    [Documentation]    Resolve URI from folder, call Get_From_Uri, return response text.
    [Arguments]    ${folder}    ${accept}    ${mapping}=&{EMPTY}    ${session}=default    ${normalize_json}=False    ${http_timeout}=${EMPTY}    ${log_response}=True
    ${uri} =    Resolve_Text_From_Template_Folder
    ...    folder=${folder}
    ...    base_name=location
    ...    extension=uri
    ...    mapping=${mapping}
    ...    percent_encode=True
    ${jmes_expression} =    Resolve_Jmes_Path    ${folder}
    ${volatiles_list} =    Resolve_Volatiles_Path    ${folder}
    ${response_text} =    Get_From_Uri
    ...    uri=${uri}
    ...    accept=${accept}
    ...    session=${session}
    ...    normalize_json=${normalize_json}
    ...    jmes_path=${jmes_expression}
    ...    http_timeout=${http_timeout}
    ...    keys_with_volatiles=${volatiles_list}
    ...    log_response=${log_response}
    RETURN    ${response_text}

Put_Templated
    [Documentation]    Resolve URI and data from folder, call Put_To_Uri, return response text.
    [Arguments]    ${folder}    ${base_name}    ${extension}    ${content_type}    ${accept}    ${mapping}=&{EMPTY}
    ...    ${session}=default    ${normalize_json}=False    ${endline}=${\n}    ${iterations}=${EMPTY}    ${iter_start}=1    ${http_timeout}=${EMPTY}    ${iter_j_offset}=0
    ${uri} =    Resolve_Text_From_Template_Folder
    ...    folder=${folder}
    ...    base_name=location
    ...    extension=uri
    ...    mapping=${mapping}
    ...    percent_encode=True
    ${data} =    Resolve_Text_From_Template_Folder
    ...    folder=${folder}
    ...    base_name=${base_name}
    ...    extension=${extension}
    ...    mapping=${mapping}
    ...    endline=${endline}
    ...    iterations=${iterations}
    ...    iter_start=${iter_start}
    ...    iter_j_offset=${iter_j_offset}
    ${jmes_expression} =    Resolve_Jmes_Path    ${folder}
    ${response_text} =    Put_To_Uri
    ...    uri=${uri}
    ...    data=${data}
    ...    content_type=${content_type}
    ...    accept=${accept}
    ...    session=${session}
    ...    http_timeout=${http_timeout}
    ...    normalize_json=${normalize_json}
    ...    jmes_path=${jmes_expression}
    RETURN    ${response_text}

Post_Templated
    [Documentation]    Resolve URI and data from folder, call Post_To_Uri, return response text.
    [Arguments]    ${folder}    ${base_name}    ${extension}    ${content_type}    ${accept}    ${mapping}=&{EMPTY}
    ...    ${session}=default    ${normalize_json}=False    ${endline}=${\n}    ${iterations}=${EMPTY}    ${iter_start}=1    ${additional_allowed_status_codes}=${NO_STATUS_CODES}
    ...    ${explicit_status_codes}=${NO_STATUS_CODES}    ${http_timeout}=${EMPTY}    ${iter_j_offset}=0
    ${uri} =    Resolve_Text_From_Template_Folder
    ...    folder=${folder}
    ...    base_name=location
    ...    extension=uri
    ...    mapping=${mapping}
    ...    percent_encode=True
    ${data} =    Resolve_Text_From_Template_Folder
    ...    folder=${folder}
    ...    name_prefix=post_
    ...    base_name=${base_name}
    ...    extension=${extension}
    ...    mapping=${mapping}
    ...    endline=${endline}
    ...    iterations=${iterations}
    ...    iter_start=${iter_start}
    ...    iter_j_offset=${iter_j_offset}
    ${jmes_expression} =    Resolve_Jmes_Path    ${folder}
    ${response_text} =    Post_To_Uri
    ...    uri=${uri}
    ...    data=${data}
    ...    content_type=${content_type}
    ...    accept=${accept}
    ...    session=${session}
    ...    jmes_path=${jmes_expression}
    ...    normalize_json=${normalize_json}
    ...    additional_allowed_status_codes=${additional_allowed_status_codes}
    ...    explicit_status_codes=${explicit_status_codes}
    ...    http_timeout=${http_timeout}
    RETURN    ${response_text}

Verify_Response_Templated
    [Documentation]    Resolve expected text from template, provided response shuld be equal.
    ...    If \${normalize_json}, perform normalization before comparison.
    [Arguments]    ${response}    ${folder}    ${base_name}    ${extension}    ${mapping}=&{EMPTY}    ${normalize_json}=False
    ...    ${endline}=${\n}    ${iterations}=${EMPTY}    ${iter_start}=1    ${iter_j_offset}=0
    # TODO: Support for XML-aware comparison could be added, but there are issues with namespaces and similar.
    ${expected_text} =    Resolve_Text_From_Template_Folder
    ...    folder=${folder}
    ...    base_name=${base_name}
    ...    extension=${extension}
    ...    mapping=${mapping}
    ...    endline=${endline}
    ...    iterations=${iterations}
    ...    iter_start=${iter_start}
    ...    iter_j_offset=${iter_j_offset}
    BuiltIn.Run_Keyword_And_Return_If
    ...    """${expected_text}""" == """${EMPTY}"""
    ...    BuiltIn.Should_Be_Equal
    ...    ${EMPTY}
    ...    ${response}
    IF    ${normalize_json}
        Normalize_Jsons_And_Compare    expected_raw=${expected_text}    actual_raw=${response}
    ELSE
        BuiltIn.Should_Be_Equal    ${expected_text}    ${response}
    END

Get_From_Uri
    [Documentation]    GET data from given URI, check status code and return response text.
    ...    \${accept} is a Python object with headers to use.
    ...    If \${normalize_json}, normalize as JSON text before returning.
    [Arguments]    ${uri}    ${accept}=${ACCEPT_EMPTY}    ${session}=default    ${normalize_json}=False    ${jmes_path}=${EMPTY}    ${http_timeout}=${EMPTY}
    ...    ${keys_with_volatiles}=${EMPTY}    ${log_response}=True
    BuiltIn.Log    ${uri}
    BuiltIn.Log    ${accept}
    IF    """${http_timeout}""" == """${EMPTY}"""
        ${response} =    RequestsLibrary.Get_On_Session    ${session}    url=${uri}    headers=${accept}
    ELSE
        ${response} =    RequestsLibrary.Get_On_Session
        ...    ${session}
        ...    url=${uri}
        ...    headers=${accept}
        ...    timeout=${http_timeout}
    END
    Check_Status_Code    ${response}    log_response=${log_response}
    IF    not ${normalize_json}    RETURN    ${response.text}
    ${text_normalized} =    norm_json.normalize_json_text
    ...    ${response.text}
    ...    jmes_path=${jmes_path}
    ...    keys_with_volatiles=${keys_with_volatiles}
    RETURN    ${text_normalized}

Put_To_Uri
    [Documentation]    PUT data to given URI, check status code and return response text.
    ...    \${content_type} and \${accept} are mandatory Python objects with headers to use.
    ...    If \${normalize_json}, normalize text before returning.
    [Arguments]    ${uri}    ${data}    ${content_type}    ${accept}    ${session}=default    ${normalize_json}=False
    ...    ${jmes_path}=${EMPTY}    ${http_timeout}=${EMPTY}
    BuiltIn.Log    ${uri}
    BuiltIn.Log    ${data}
    BuiltIn.Log    ${content_type}
    BuiltIn.Log    ${accept}
    ${headers} =    Join_Two_Headers    first=${content_type}    second=${accept}
    IF    """${http_timeout}""" == """${EMPTY}"""
        ${response} =    RequestsLibrary.Put_On_Session
        ...    ${session}
        ...    ${uri}
        ...    data=${data}
        ...    headers=${headers}
    ELSE
        ${response} =    RequestsLibrary.Put_On_Session
        ...    ${session}
        ...    ${uri}
        ...    data=${data}
        ...    headers=${headers}
        ...    timeout=${http_timeout}
    END
    Check_Status_Code    ${response}
    IF    not ${normalize_json}    RETURN    ${response.text}
    ${text_normalized} =    norm_json.normalize_json_text    ${response.text}    jmes_path=${jmes_path}
    RETURN    ${text_normalized}

Post_To_Uri
    [Documentation]    POST data to given URI, check status code and return response text.
    ...    \${content_type} and \${accept} are mandatory Python objects with headers to use.
    ...    If \${normalize_json}, normalize text before returning.
    [Arguments]    ${uri}    ${data}    ${content_type}    ${accept}    ${session}=default    ${normalize_json}=False
    ...    ${jmes_path}=${EMPTY}    ${additional_allowed_status_codes}=${NO_STATUS_CODES}    ${explicit_status_codes}=${NO_STATUS_CODES}    ${http_timeout}=${EMPTY}
    BuiltIn.Log    ${uri}
    BuiltIn.Log    ${data}
    BuiltIn.Log    ${content_type}
    BuiltIn.Log    ${accept}
    ${headers} =    Join_Two_Headers    first=${content_type}    second=${accept}
    IF    """${http_timeout}""" == """${EMPTY}"""
        ${response} =    RequestsLibrary.Post_On_Session
        ...    ${session}
        ...    ${uri}
        ...    data=${data}
        ...    headers=${headers}
    ELSE
        ${response} =    RequestsLibrary.Post_On_Session
        ...    ${session}
        ...    ${uri}
        ...    data=${data}
        ...    headers=${headers}
        ...    timeout=${http_timeout}
    END
    Check_Status_Code
    ...    ${response}
    ...    additional_allowed_status_codes=${additional_allowed_status_codes}
    ...    explicit_status_codes=${explicit_status_codes}
    IF    not ${normalize_json}    RETURN    ${response.text}
    ${text_normalized} =    norm_json.normalize_json_text    ${response.text}    jmes_path=${jmes_path}
    RETURN    ${text_normalized}

Check_Status_Code
    [Documentation]    Log response text, check status_code is one of allowed ones. In cases where this keyword is
    ...    called in a WUKS it could end up logging tons of data and it may be desired to skip the logging by passing
    ...    log_response=False, but by default it remains True.
    [Arguments]    ${response}    ${additional_allowed_status_codes}=${NO_STATUS_CODES}    ${explicit_status_codes}=${NO_STATUS_CODES}    ${log_response}=True
    # TODO: Remove overlap with keywords from Utils.robot
    IF    "${log_response}" == "True"    BuiltIn.Log    ${response.text}
    IF    "${log_response}" == "True"    BuiltIn.Log    ${response.status_code}
    # In order to allow other existing keywords to consume this keyword by passing a single non-list status code, we need to
    # check the type of the argument passed and convert those single non-list codes in to a one item list
    ${status_codes_type} =    Evaluate    type($additional_allowed_status_codes).__name__
    IF    "${status_codes_type}"!="list"
        ${allowed_status_codes_list} =    Create List    ${additional_allowed_status_codes}
    ELSE
        ${allowed_status_codes_list} =    Set Variable    ${additional_allowed_status_codes}
    END
    ${status_codes_type} =    Evaluate    type($explicit_status_codes).__name__
    IF    "${status_codes_type}"!="list"
        ${explicit_status_codes_list} =    Create List    ${explicit_status_codes}
    ELSE
        ${explicit_status_codes_list} =    Set Variable    ${explicit_status_codes}
    END
    BuiltIn.Run_Keyword_And_Return_If
    ...    """${explicit_status_codes_list}""" != """${NO_STATUS_CODES}"""
    ...    Collections.List_Should_Contain_Value
    ...    ${explicit_status_codes_list}
    ...    ${response.status_code}
    ${final_allowd_list} =    Collections.Combine_Lists    ${ALLOWED_STATUS_CODES}    ${allowed_status_codes_list}
    Collections.List_Should_Contain_Value    ${final_allowd_list}    ${response.status_code}

Join_Two_Headers
    [Documentation]    Take two dicts, join them, return result. Second argument values take precedence.
    [Arguments]    ${first}    ${second}
    ${accumulator} =    Collections.Copy_Dictionary    ${first}
    ${items_to_add} =    Collections.Get_Dictionary_Items    ${second}
    Collections.Set_To_Dictionary    ${accumulator}    @{items_to_add}
    BuiltIn.Log    ${accumulator}
    RETURN    ${accumulator}

Resolve_Text_From_Template_Folder
    [Documentation]    Read a template from folder, strip endline, make changes according to mapping, return the result.
    ...    If \${iterations} value is present, put text together from "prolog", "item" and "epilog" parts,
    ...    where additional template variable ${i} goes from ${iter_start}, by one ${iterations} times.
    ...    Template variable ${j} is calculated as ${i} incremented by offset ${iter_j_offset} ( j = i + iter_j_offset )
    ...    used to create non uniform data in order to be able to validate UPDATE operations.
    ...    POST (as opposed to PUT) needs slightly different data, \${name_prefix} may be used to distinguish.
    ...    (Actually, it is GET who formats data differently when URI is a top-level container.)
    [Arguments]    ${folder}    ${name_prefix}=${EMPTY}    ${base_name}=data    ${extension}=json    ${mapping}=${EMPTY}    ${iterations}=${EMPTY}
    ...    ${iter_start}=1    ${iter_j_offset}=0    ${endline}=${\n}    ${percent_encode}=False
    BuiltIn.Run_Keyword_And_Return_If
    ...    not "${iterations}"
    ...    Resolve_Text_From_Template_File
    ...    folder=${folder}
    ...    file_name=${name_prefix}${base_name}.${extension}
    ...    mapping=${mapping}
    ...    percent_encode=${percent_encode}
    ${prolog} =    Resolve_Text_From_Template_File
    ...    folder=${folder}
    ...    file_name=${name_prefix}${base_name}.prolog.${extension}
    ...    mapping=${mapping}
    ...    percent_encode=${percent_encode}
    ${epilog} =    Resolve_Text_From_Template_File
    ...    folder=${folder}
    ...    file_name=${name_prefix}${base_name}.epilog.${extension}
    ...    mapping=${mapping}
    ...    percent_encode=${percent_encode}
    # Even POST uses the same item template (except indentation), so name prefix is ignored.
    ${item_template} =    Resolve_Text_From_Template_File
    ...    folder=${folder}
    ...    file_name=${base_name}.item.${extension}
    ...    mapping=${mapping}
    ${items} =    BuiltIn.Create_List
    ${separator} =    BuiltIn.Set_Variable_If    '${extension}' != 'json'    ${endline}    ,${endline}
    FOR    ${iteration}    IN RANGE    ${iter_start}    ${iterations}+${iter_start}
        IF    ${iteration} > ${iter_start}
            Collections.Append_To_List    ${items}    ${separator}
        END
        ${j} =    BuiltIn.Evaluate    ${iteration}+${iter_j_offset}
        ${item} =    BuiltIn.Evaluate
        ...    string.Template('''${item_template}''').substitute({"i":"${iteration}", "j":${j}})
        ...    modules=string
        Collections.Append_To_List    ${items}    ${item}
        # TODO: The following makes ugly result for iterations=0. Should we fix that?
    END
    ${final_text} =    BuiltIn.Catenate    SEPARATOR=    ${prolog}    ${endline}    @{items}    ${endline}
    ...    ${epilog}
    RETURN    ${final_text}

Resolve_Text_From_Template_File
    [Documentation]    Check if ${folder}.${ODL_STREAM}/${file_name} exists. If yes read and Log contents of file ${folder}.${ODL_STREAM}/${file_name},
    ...    remove endline, perform safe substitution, return result.
    ...    If no do it with the default ${folder}/${file_name}.
    [Arguments]    ${folder}    ${file_name}    ${mapping}=&{EMPTY}    ${percent_encode}=False
    ${file_path_stream} =    BuiltIn.Set Variable    ${folder}.${ODL_STREAM}${/}${file_name}
    ${file_stream_exists} =    BuiltIn.Run Keyword And Return Status
    ...    OperatingSystem.File Should Exist
    ...    ${file_path_stream}
    ${file_path} =    BuiltIn.Set Variable If
    ...    ${file_stream_exists}
    ...    ${file_path_stream}
    ...    ${folder}${/}${file_name}
    ${template} =    OperatingSystem.Get_File    ${file_path}
    BuiltIn.Log    ${template}
    IF    ${percent_encode} == True
        ${mapping_to_use} =    Encode_Mapping    ${mapping}
    ELSE
        ${mapping_to_use} =    BuiltIn.Set_Variable    ${mapping}
    END
    ${final_text} =    BuiltIn.Evaluate
    ...    string.Template('''${template}'''.rstrip()).safe_substitute(${mapping_to_use})
    ...    modules=string
    RETURN    ${final_text}

    # Final text is logged where used.

Normalize_Jsons_And_Compare
    [Documentation]    Use norm_json to normalize both JSON arguments, call Should_Be_Equal.
    [Arguments]    ${expected_raw}    ${actual_raw}
    ${expected_normalized} =    norm_json.normalize_json_text    ${expected_raw}
    ${actual_normalized} =    norm_json.normalize_json_text    ${actual_raw}
    # Should_Be_Equal shall print nice diff-style line comparison.
    BuiltIn.Should_Be_Equal    ${expected_normalized}    ${actual_normalized}
    # TODO: Add garbage collection? Check whether the temporary data accumulates.

Normalize_Jsons_With_Bits_And_Compare
    [Documentation]    Use norm_json to normalize both JSON arguments, call Should_Be_Equal.
    [Arguments]    ${expected_raw}    ${actual_raw}    ${keys_with_bits}=${KEYS_WITH_BITS}
    ${expected_normalized} =    norm_json.normalize_json_text    ${expected_raw}    keys_with_bits=${keys_with_bits}
    ${actual_normalized} =    norm_json.normalize_json_text    ${actual_raw}    keys_with_bits=${keys_with_bits}
    BuiltIn.Should_Be_Equal    ${expected_normalized}    ${actual_normalized}

Encode_Mapping
    [Arguments]    ${mapping}
    BuiltIn.Log    mapping: ${mapping}
    ${encoded_mapping} =    BuiltIn.Create_Dictionary
    FOR    ${key}    ${value}    IN    &{mapping}
        ${encoded_value} =    Percent_Encode_String    ${value}
        Collections.Set_To_Dictionary    ${encoded_mapping}    ${key}    ${encoded_value}
    END
    RETURN    ${encoded_mapping}

Percent_Encode_String
    [Documentation]    Percent encodes reserved characters in the given string so it can be used as part of url.
    [Arguments]    ${value}
    ${string_value} =    BuiltIn.Convert To String    ${value}
    ${encoded} =    String.Replace_String_Using_Regexp    ${string_value}    :    %3A
    RETURN    ${encoded}

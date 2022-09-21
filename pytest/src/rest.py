import os
import re
import logging
import string
import requests
import norm_json
from variables import ACCEPT_EMPTY, ACCEPT_XML, HEADERS_XML, HEADERS_YANG_JSON, AUTH, ODL_SYSTEM_IP, RESTCONFPORT

ALLOWED_STATUS_CODES = [200, 201, 204]
ALLOWED_DELETE_STATUS_CODES = [200, 201, 204, 404]
NO_STATUS_CODES = []
url = "http://{}:{}".format(ODL_SYSTEM_IP, RESTCONFPORT)


def create_default_session(auth=AUTH):
    '''Create default session to url with authentication and connection parameters'''
    session = requests.Session()
    session.auth = tuple(auth)
    return session


default_session = create_default_session(AUTH)


def check_status_code(response, additional_allowed_status_codes=[], explicit_status_codes=[], log_response=True):
    if log_response is True:
        print(response.text)
        print(response.status_code)

    if type(additional_allowed_status_codes) != list:
        allowed_status_codes_list = list(additional_allowed_status_codes)
    else:
        allowed_status_codes_list = additional_allowed_status_codes

    if type(explicit_status_codes) != list:
        explicit_status_codes_list = list(explicit_status_codes)
    else:
        explicit_status_codes_list = explicit_status_codes

    if explicit_status_codes_list != NO_STATUS_CODES:
        return response.status_code in explicit_status_codes_list

    final_allowed_list = allowed_status_codes_list.extend(ALLOWED_STATUS_CODES)
    return response.status_code in final_allowed_list


def join_two_headers(dict1, dict2):
    """Takes two dictionaries, joins them and returns the result"""
    accumulator = dict1.copy()
    return {**accumulator, **dict2}


def get_from_uri(url, session=default_session, accept=ACCEPT_EMPTY, normalize_json=False, jmes_path="", http_timeout="", keys_with_volatiles="", log_response=True):
    """GET data from given URI, check status code and return response text."""
    print(url)
    print(accept)

    if http_timeout == "":
        response = session.get(url=url, headers=accept)
    else:
        response = session.get(url=url, headers=accept, timeout=int(http_timeout))

    status_code = check_status_code(response=response, log_response=log_response)

    if not normalize_json:
        return (response.text, status_code)

    text_normalized = norm_json.normalize_json_text(
        text=response.text, jmes_path=jmes_path, keys_with_volatiles=keys_with_volatiles)
    return (text_normalized, status_code)


def put_to_uri(url, data, content_type, accept, session=default_session, normalize_json=False, jmes_path="", http_timeout=""):
    """PUT data to given url, vcheck status code and return response text
       content_type and accept are mandatory python objcets with headers to use
       If normalize_json, normalize text before returning"""

    headers = join_two_headers(content_type, accept)

    if http_timeout == "":
        response = session.put(url=url, data=data, headers=headers)
    else:
        response = session.put(url=url, data=data, headers=headers, timeout=int(http_timeout))

    status_code = check_status_code(response=response)

    if not normalize_json:
        return (response.text, status_code)

    text_normalized = norm_json.normalize_json_text(text=response.text, jmes_path=jmes_path)
    return (text_normalized, status_code)


def post_to_uri(url, data, content_type, accept, session=default_session, normalize_json=False, jmes_path="", additional_allowed_status_codes=NO_STATUS_CODES, explicit_status_codes=NO_STATUS_CODES, http_timeout=""):
    """POST data to the given url, check status code and return the result"""

    headers = join_two_headers(content_type, accept)

    if http_timeout == "":
        response = session.post(url=url, data=data, headers=headers)
    else:
        response = session.post(url=url, data=data, headers=headers, timeout=int(http_timeout))

    status_code = check_status_code(response=response, additional_allowed_status_codes=additional_allowed_status_codes,
                                    explicit_status_codes=explicit_status_codes)

    if not normalize_json:
        return (response.text, status_code)

    text_normalized = norm_json.normalize_json_text(text=response.text, jmes_path=jmes_path)
    return (text_normalized, status_code)


def delete_from_uri(url, session=default_session, additional_allowed_status_codes=NO_STATUS_CODES, http_timeout=""):
    """DELETE resource at url, check status code and return the response text"""

    if http_timeout == "":
        response = session.delete(url=url)
    else:
        response = session.delete(url=url, timeout=http_timeout)

    status_code = check_status_code(response=response, additional_allowed_status_codes=additional_allowed_status_codes)
    return (response.text, status_code)


def get_as_xml_from_uri(url, session=default_session, http_timeout="", log_response=True):
    """Specify XML headers and return get_from_uri response text"""
    response_text, status_code = get_from_uri(url=url, accept=ACCEPT_XML, session=session,
                                              normalize_json=False, http_timeout=http_timeout)
    return (response_text, status_code)


def post_as_xml_to_uri(url, data, sesion=default_session, http_timeout=""):
    """Specify XML headers and return post_to_uri response text"""
    response_text, status_code = post_to_uri(url=url, data=data, accept=ACCEPT_XML, content_type=HEADERS_XML,
                                             session=sesion, normalize_json=False, http_timeout=http_timeout)
    return (response_text, status_code)


def put_as_xml_to_uri(url, data, session=default_session, http_timeout=""):
    """Specify XML headers and return put_to_uri response text"""
    response_text, status_code = put_to_uri(url == url, data=data, accept=ACCEPT_XML, content_type=HEADERS_XML,
                                            session=session, normalize_json=False, http_timeout=http_timeout)
    return (response_text, status_code)


def get_as_json_from_uri(url, session=default_session, http_timeout="", log_response=True):
    """Specify JSON headers and return get_from_uri normalized response text"""
    response_text, status_code = get_from_uri(url, session=session, accept=ACCEPT_EMPTY, normalize_json=True,
                                              http_timeout=http_timeout, log_response=log_response)
    return (response_text, status_code)


def post_as_json_to_uri(url, data, session=default_session, additional_allowed_status_codes=NO_STATUS_CODES, explicit_status_codes=NO_STATUS_CODES, http_timeout=""):
    """Specify JSON headers and return post_to_uri normalized response text
    Response status code must be one of values from explicit_status_codes if specified or one of set
    created from all positive HTTP status codes together with additional_allowed_status_codes."""

    response_text, status_code = post_to_uri(url=url, data=data, accept=ACCEPT_EMPTY, content_type=HEADERS_YANG_JSON, session=session, normalize_json=True,
                                             additional_allowed_status_codes=additional_allowed_status_codes, explicit_status_codes=explicit_status_codes, http_timeout=http_timeout)
    return (response_text, status_code)


def put_as_json_to_uri(url, data, session=default_session, http_timeout=""):
    """Specify JSON headers and return put_to_uri normalized response text."""
    response_text, status_code = put_to_uri(url=url, data=data, accept=ACCEPT_EMPTY, content_type=HEADERS_YANG_JSON,
                                            session=session, normalize_json=True, http_timeout=http_timeout)
    return (response_text, status_code)


def percent_encode_string(value):
    """Percent encodes reserved characters in the given string so it can be used as part of url."""
    encoded = re.sub(":", "%3A", value)
    return encoded


def encode_mapping(mapping):
    logging.info("maping: {}".format(mapping))
    encoded_mapping = {}
    for key, value in mapping:
        encoded_value = percent_encode_string(value)
        encoded_mapping[key] = encoded_value

    return encode_mapping


def resolve_text_from_template_file(folder, file_name, mapping={}, percent_encode=False, ODL_STREAM="Sulfur-SR1"):
    """Chcek if {folder}.{ODL_STREAM}/{file_name} exists
       If yes read and Log contents of file {folder}.{ODL_STREAM}/{file_name},
       remove endline, perform safe substitution, return result.
       If no do it with the default {folder}/{file_name}."""

    file_path_stream = "{}.{}/{}".format(folder, ODL_STREAM, file_name)
    file_stream_exists = os.path.exists(file_path_stream)

    if file_stream_exists:
        file_path = file_path_stream
    else:
        file_path = "{}/{}".format(folder, file_name)

    with open(file_path) as fp:
        template = fp.read()

    logging.info(template)

    if percent_encode is True:
        mapping_to_use = encode_mapping(mapping)
    else:
        mapping_to_use = mapping

    final_text = string.Template(template.rstrip()).safe_substitute(mapping_to_use)

    return final_text


def resolve_text_from_template_folder(folder, name_prefix="", base_name="data", extension="json", mapping="", iterations="", iter_start=1, iter_j_offset=0, endline="\n", percent_encode=False):
    """Read a template from folder, strip endline, make changes according to mapping, return the result.
       If {iterations} value is present, put text together from "prolog", "item" and "epilog" parts,
       where additional template variable {i} goes from {iter_start}, by one {iterations} times.
       Template variable {j} is calculated as {i} incremented by offset {iter_j_offset} ( j = i + iter_j_offset )
       used to create non uniform data in order to be able to validate UPDATE operations.
       POST (as opposed to PUT) needs slightly different data, {name_prefix} may be used to distinguish.
       (Actually, it is GET who formats data differently when URI is a top-level container.)
    """

    if not iterations:
        return resolve_text_from_template_file(folder=folder, file_name=name_prefix + base_name + "." + extension, mapping=mapping, percent_encode=percent_encode)

    prolog = resolve_text_from_template_file(
        folder=folder, file_name=name_prefix + base_name + ".prolog." + extension, mapping=mapping, percent_encode=percent_encode)

    epilog = resolve_text_from_template_file(
        folder=folder, file_name=name_prefix + base_name + ".epilog." + extension, mapping=mapping, percent_encode=percent_encode)

    # Even POST uses the same item template (except indentation), so name prefix is ignored.

    item_template = resolve_text_from_template_file(
        folder=folder, file_name=base_name + ".item." + extension, mapping=mapping)

    items = []

    if extension == 'json':
        separator = endline
    else:
        separator = "," + endline

    for iteration in range(iter_start, iter_start + int(iterations)):
        if iteration > iter_start:
            items.append(separator)
        j = iteration + iter_j_offset
        item = string.Template(item_template).substitute({"i": iteration, "j": j})
        items.append(item)

    items = [str(item) for item in items]
    items = "".join(items)
    final_text = "".join([prolog, endline, items, endline, epilog])

    return final_text


def resolve_jmes_path(folder):
    """Reads JMES path from file ${folder}${/}jmespath.expr if the file exists and
       returns the JMES path. Empty string is returned otherwise."""

    read_jmes_file = os.path.exists(folder + "/jmespath.expr")

    if read_jmes_file is True:
        with open(folder + "/jmespath.expr") as fp:
            jmes_expression = fp.read()
        return jmes_expression
    else:
        return ""


def resolve_volatiles_path(folder):
    """Reads Volatiles List from file ${folder}${/}volatiles.list if the file exists and
       returns the Volatiles List. Empty string is returned otherwise."""

    read_volatiles_file = os.path.exists(folder + "/volatiles.list")

    if read_volatiles_file is False:
        return ""

    with open(folder + "/volatiles.list") as fp:
        volatiles = fp.read()

    volatiles_list = volatiles.split("\n")
    return volatiles_list


def get_templated(folder, accept, mapping={}, session=default_session, normalize_json=False, http_timeout="", log_response=True):
    """Resolve URI from folder, call Get_From_Uri, return response text."""

    uri = resolve_text_from_template_folder(folder=folder, base_name="location",
                                            extension="uri", mapping=mapping, percent_encode=True)

    jmes_expression = resolve_jmes_path(folder)
    volatiles_list = resolve_volatiles_path(folder)

    response_text, status_code = get_from_uri(url=uri, accept=accept, session=session, normalize_json=normalize_json,
                                              jmes_path=jmes_expression, http_timeout=http_timeout, keys_with_volatiles=volatiles_list, log_response=log_response)

    return (response_text, status_code)


def put_templated(folder, base_name, extension, content_type, accept, mapping={}, session=default_session, normalize_json=False, endline="\n", iterations="", iter_start=1, iter_j_offset=0, http_timeout=""):
    """Resolve URI and data from folder, call put_to_uri, return response text."""
    uri = resolve_text_from_template_folder(folder=folder, base_name="location",
                                            extension="uri", mapping=mapping, percent_encode=True)
    data = resolve_text_from_template_folder(folder=folder, base_name=base_name, extension=extension, mapping=mapping,
                                             endline=endline, iterations=iterations, iter_start=iter_start, iter_j_offset=iter_j_offset)
    jmes_expression = resolve_jmes_path(folder)

    response_text, status_code = put_to_uri(url=uri, data=data, content_type=content_type, accept=accept, session=session,
                                            http_timeout=http_timeout, normalize_json=normalize_json, jmes_path=jmes_expression)

    return (response_text, status_code)


def post_templated(folder, base_name, extension, content_type, accept, mapping={}, session=default_session, normalize_json=False, endline="\n", iterations="", iter_start=1, iter_j_offset=0, http_timeout="", additional_allowed_status_codes=NO_STATUS_CODES, explicit_status_codes=NO_STATUS_CODES):
    """Resolve URI and data from folder, call post_to_uri, return response text."""
    uri = resolve_text_from_template_folder(folder=folder, base_name="location",
                                            extension="uri", mapping=mapping, percent_encode=True)
    data = resolve_text_from_template_folder(folder=folder, name_prefix="post_", base_name=base_name, extension=extension, mapping=mapping,
                                             endline=endline, iterations=iterations, iter_start=iter_start, iter_j_offset=iter_j_offset)
    jmes_expression = resolve_jmes_path(folder)

    response_text, status_code = post_to_uri(url=uri, data=data, content_type=content_type, accept=accept, session=session,
                                             http_timeout=http_timeout, normalize_json=normalize_json, jmes_path=jmes_expression, additional_allowed_status_codes=additional_allowed_status_codes, explicit_status_codes=explicit_status_codes)

    return (response_text, status_code)


def delete_templated(folder, mapping={}, session=default_session, additional_allowed_status_codes=NO_STATUS_CODES, http_timeout="", location="location"):
    """Resolve URI from folder, issue DELETE request."""
    uri = resolve_text_from_template_folder(folder=folder, base_name=location,
                                            extension="uri", mapping=mapping, percent_encode=True)
    response_text, status_code = delete_from_uri(
        url=uri, session=session, additional_allowed_status_codes=additional_allowed_status_codes, http_timeout=http_timeout)

    return (response_text, status_code)


def normalize_jsons_and_compare(expected_raw, actual_raw):
    """Use norm_json to normalize both JSON arguments, which should be equal."""
    expected_normalized = norm_json.normalize_json_text(expected_raw)
    actual_normalized = norm_json.normalize_json_text(actual_raw)

    return expected_normalized == actual_normalized


def verify_response_templated(response, folder, base_name, extension, mapping={}, normalize_json=False, endline="\n", iterations="", iter_start=1, iter_j_offset=0):
    """Resolve expected text from template, provided response shuld be equal.
       If {normalize_json}, perform normalization before comparison."""
    expected_text = resolve_text_from_template_folder(folder=folder, base_name=base_name, extension=extension,
                                                      mapping=mapping, endline=endline, iterations=iterations, iter_start=iter_start, iter_j_offset=iter_j_offset)

    if expected_text == "":
        return "" == response

    if normalize_json:
        return normalize_jsons_and_compare(expected_raw=expected_text, actual_raw=response)
    else:
        return expected_text == response


def verify_response_as_xml_templated(response, folder, base_name="response", mapping={}, iterations="", iter_start=1, iter_j_offset=0):
    """Resolve expected XML data, should be equal to provided {response}.
       Endline set to empty, as this Resource does not support indented XML comparison."""

    return verify_response_templated(response=response, folder=folder, base_name=base_name, extension="xml", mapping=mapping,
                                     normalize_json=False, endline="", iterations=iterations, iter_start=iter_start, iter_j_offset=iter_j_offset)


def verify_response_as_json_templated(response, folder, base_name="response", mapping={}, iterations="", iter_start=1, iter_j_offset=0):
    """Resolve expected JSON data, should be equal to provided {response}.
       JSON normalization is used, endlines enabled for readability."""

    return verify_response_templated(response=response, folder=folder, base_name=base_name, extension="json", mapping=mapping,
                                     normalize_json=True, endline="\n", iterations=iterations, iter_start=iter_start, iter_j_offset=iter_j_offset)


def get_as_xml_templated(folder, mapping={}, session=default_session, verify=False, iterations="", iter_start=1, http_timeout="", iter_j_offset=0):
    """Add arguments sensible for XML data, return get_templated response text.
       Optionally, verification against XML data (may be iterated) is called."""

    response_text, status_code = get_templated(folder=folder, mapping=mapping, accept=ACCEPT_XML,
                                               session=session, normalize_json=False, http_timeout=http_timeout)

    if verify:
        verify_response_as_xml_templated(response=response_text, folder=folder, base_name="data",
                                         mapping=mapping, iterations=iterations, iter_start=iter_start, iter_j_offset=iter_j_offset)

    return (response_text, status_code)


def put_as_xml_templated(folder, mapping={}, session=default_session, verify=False, iterations="", iter_start=1, http_timeout="", iter_j_offset=0):
    """Add arguments sensible for XML data, return put_templated response text.
       Optionally, verification against response.xml (no iteration) is called."""

    response_text, status_code = put_templated(folder=folder, base_name="data", extension="xml", accept=ACCEPT_XML, content_type=HEADERS_XML, mapping=mapping, session=session,
                                               normalize_json=False, endline="\n", iterations=iterations, iter_start=iter_start, http_timeout=http_timeout, iter_j_offset=iter_j_offset)

    if verify:
        verify_response_as_xml_templated(response=response_text, folder=folder,
                                         base_name="response", mapping=mapping, iter_j_offset=iter_j_offset)

    return (response_text, status_code)


def post_as_xml_templated(folder, mapping={}, session=default_session, verify=False, iterations="", iter_start=1, additional_allowed_status_codes=NO_STATUS_CODES, explicit_status_codes=NO_STATUS_CODES, http_timeout="", iter_j_offset=0):
    """Add arguments sensible for XML data, return post_templated response text.
       Optionally, verification against response.xml (no iteration) is called."""

    response_text, status_code = post_templated(folder=folder, base_name="data", extension="xml", accept=ACCEPT_XML, content_type=HEADERS_XML, mapping=mapping, session=session,
                                                normalize_json=False, endline="\n", iterations=iterations, iter_start=iter_start, additional_allowed_status_codes=additional_allowed_status_codes, explicit_status_codes=explicit_status_codes, http_timeout=http_timeout, iter_j_offset=iter_j_offset)

    if verify:
        verify_response_as_xml_templated(response=response_text, folder=folder,
                                         base_name="response", mapping=mapping, iter_j_offset=iter_j_offset)

    return (response_text, status_code)


def post_as_json_templated(folder, mapping={}, session=default_session, verify=False, iterations="", iter_start=1, additional_allowed_status_codes=NO_STATUS_CODES, explicit_status_codes=NO_STATUS_CODES, http_timeout="", iter_j_offset=0):
    """Add arguments sensible for JSON data, return Post_Templated response text.
       Optionally, verification against response.json (no iteration) is called.
       Only subset of JSON data is verified and returned if JMES path is specified in
       file {folder}/jmespath.expr.
       Response status code must be one of values from {explicit_status_codes} if specified or one of set
       created from all positive HTTP status codes together with {additional_allowed_status_codes}."""

    response_text, status_code = post_templated(folder=folder, base_name="data", extension="json", accept=ACCEPT_EMPTY, content_type=HEADERS_YANG_JSON, mapping=mapping, session=session, normalize_json=True, endline="\n",
                                                iterations=iterations, iter_start=iter_start, additional_allowed_status_codes=additional_allowed_status_codes, explicit_status_codes=explicit_status_codes, http_timeout=http_timeout, iter_j_offset=iter_j_offset)

    if verify:
        verify_response_as_json_templated(response=response_text, folder=folder,
                                          base_name="response", mapping=mapping, iter_j_offset=iter_j_offset)

    return (response_text, status_code)

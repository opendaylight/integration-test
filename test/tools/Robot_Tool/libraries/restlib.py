"""
CSIT test tools.
Authors: Denghui Huang@IBM, Baohua Yang@IBM
Updated: 2013-11-06
"""
import json

import requests


# Global variables
DEFAULT_CONTROLLER_IP = '127.0.0.1'
#DEFAULT_CONTROLLER_IP = '9.186.105.113' #just for temp test
DEFAULT_PORT = '8080'
DEFAULT_PREFIX = 'http://' + DEFAULT_CONTROLLER_IP + ':' + DEFAULT_PORT
DEFAULT_CONTAINER = 'default'
DEFAULT_USER = 'admin'
DEFAULT_PWD = 'admin'
MODULES_DIR = 'modules'
TIMEOUTS = 2

'''
Send a POST request.
'''


def do_post_request(url, content_type, payload=None, user=DEFAULT_USER, password=DEFAULT_PWD):
    data = payload
    headers = {}
    if content_type == 'json':
        headers = {'Content-type': 'application/json', 'Accept': 'application/json'}
        if payload != None:
            data = json.dumps(payload)
    elif content_type == 'xml':
        headers = {'Content-type': 'application/xml', 'Accept': 'application/xml'}
    else:
        print 'unsupported content-type'
    try:
        r = requests.post(url, data, headers=headers, auth=(user, password), timeout=TIMEOUTS)
        r.raise_for_status()
    except (requests.exceptions.HTTPError, requests.exceptions.Timeout) as e:
        return 400
    else:
        return r.status_code


def do_get_request_with_status_code(url, content_type, user=DEFAULT_USER, password=DEFAULT_PWD):
    '''
    Send a GET request.
    @return The status code.
    '''
    r = None
    try:
        r = requests.get(url, auth=(user, password), timeout=TIMEOUTS)
        r.raise_for_status()
    except (requests.exceptions.HTTPError, requests.exceptions.Timeout) as e:
        print e
        return r.status_code
    finally:
        return r.status_code


def do_put_request(url, content_type, payload=None, user=DEFAULT_USER, password=DEFAULT_PWD):
    '''
    Send a PUT request.
    @return The status code.
    '''
    data = payload
    headers = {}
    if content_type == 'json':
        headers = {'Content-type': 'application/json', 'Accept': 'application/json'}
        if payload != None:
            data = json.dumps(payload)
    elif content_type == 'xml':
        headers = {'Content-type': 'application/xml', 'Accept': 'application/xml'}
    else:
        print 'unsupported content-type'
    try:
        r = requests.put(url, data, headers=headers, auth=(user, password), timeout=TIMEOUTS)
        r.raise_for_status()
    except (requests.exceptions.HTTPError, requests.exceptions.Timeout) as e:
        return 400
    else:
        return r.status_code


def do_delete_request(url, user=DEFAULT_USER, password=DEFAULT_PWD):
    '''
    Send a DELETE request.
    @return The status code.
    '''
    r = None
    try:
        r = requests.delete(url, auth=(user, password), timeout=TIMEOUTS)
        r.raise_for_status()
    except (requests.exceptions.HTTPError, requests.exceptions.Timeout) as e:
        print e
    finally:
        if r:
            return r.status_code


def convert_result_to_list(result):
    '''
    Convert the result content to list.
    '''
    list2 = []
    #print result
    content = result.values()
    for list1 in content:
        list2 = [dict1.values() for dict1 in list1]
        #print list2
    list3 = []
    for list4 in list2:
        for element in list4:
            list3.append(element)
            #print list3
    return list3


def do_get_request_with_response_content(url, content_type, user=DEFAULT_USER, password=DEFAULT_PWD,
                                         convert_to_list=False):
    '''
    Send a GET request and get the response.
    @return response content as list.
    '''
    try:
        r = requests.get(url, auth=(user, password), timeout=TIMEOUTS)
        r.raise_for_status()
    except (requests.exceptions.HTTPError, requests.exceptions.Timeout) as e:
        print e
        return None
    else:
        if r != None:
            if content_type == 'json':
                content = r.json()
                return convert_result_to_list(content) if convert_to_list else content
            elif content_type == 'xml':#TODO: add parser to xml
                return None


if __name__ == '__main__':
    #example
    #Note: in json body, all field name and value (if it is string type) must be enclosed in double quotes.
    #This constraint maybe cause by json parser.
    body = {"status": "Success", "dstNodeConnector": "OF|1@OF|00:00:00:00:00:00:00:01", "name": "link3",
            "srcNodeConnector": "OF|1@OF|00:00:00:00:00:00:00:03"}
    url = 'http://127.0.0.1:8080/controller/nb/v2/topology/default/userLink/link3'
    content_type = 'json'
    print do_put_request(url, content_type, body)


__author__ = "Basheeruddin Ahmed"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "syedbahm@cisco.com"


import requests


def get(url, userId, password):
    """Helps in making GET REST calls"""
    headers = {}
    headers['Accept'] = 'application/xml'

    # Send the GET request
    req = requests.get(url, None, headers)

    # Read the response
    return req


def nonprintpost(url, userId, password, data):
    """Helps in making POST REST calls without outputs"""
    headers = {}
    headers['Content-Type'] = 'application/json'
    # headers['Accept']= 'application/xml'

    resp = requests.post(url, data.encode(), headers=headers)

    return resp


def post(url, userId, password, data):
    """Helps in making POST REST calls"""
    print("post request with url " + url)
    print("post request with data " + data)
    headers = {}
    headers['Content-Type'] = 'application/json'
    # headers['Accept']= 'application/xml'

    resp = requests.post(url, data.encode(), headers=headers)

    # print (resp.raise_for_status())
    print(resp.headers)

    return resp


def delete(url, userId, password):
    """Helps in making DELET REST calls"""
    print("delete all resources belonging to url" + url)
    resp = requests.delete(url)  # noqa

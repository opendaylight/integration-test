"""This is the base library for criotdm. Both work for IoTDM project."""

import requests

op_provision = ":8181/restconf/operations/onem2m:onem2m-cse-provisioning"
op_tree = ":8181/restconf/operational/onem2m:onem2m-resource-tree"
op_cleanup = ":8181/restconf/operations/onem2m:onem2m-cleanup-store"

cse_payload = '''
{    "input": {
        "onem2m-primitive": [
           {
                "name": "CSE_ID",
                "value": "%s"
            },
            {
                "name": "CSE_TYPE",
                "value": "IN-CSE"
            }
        ]
    }
}
'''

resourcepayload = '''
{
    %s
}
'''


def find_key(response, key):
    """Deserialize response, return value for key or None."""
    val = response.json()
    return val.get(key, None)


def name(response):
    """Return the resource name in the response."""
    return find_key(response, "rn")


def lastModifiedTime(response):
    """Return the lastModifiedTime in the response."""
    return find_key(response, "lt")


def resid(response):
    """Return the resource id in the response."""
    return find_key(response, "ri")


def parent(response):
    """Return the parent resource id in the response."""
    return find_key(response, "pi")


def content(response):
    """Return the content the response."""
    return find_key(response, "con")


def restype(response):
    """Return the resource type the response."""
    return find_key(response, "rty")


def status(response):
    """Return the protocol status code in the response."""
    try:
        return response.status_code
    except(TypeError, AttributeError):
        return None


def headers(response):
    """Return the protocol headers in the response."""
    try:
        return response.headers
    except(TypeError, AttributeError):
        return None


def error(response):
    """Return the error string in the response."""
    try:
        return response.json()['error']
    except(TypeError, AttributeError):
        return None


def normalize(resourceURI):
    """Remove the first / of /InCSE1/ae1."""
    if resourceURI is not None:
        if resourceURI[0] == "/":
            return resourceURI[1:]
    return resourceURI


class connect:

    """Create the connection."""

    def __init__(self, server="localhost", base='InCSE1',
                 auth=('admin', 'admin'), protocol="http"):
        """Connect to a IoTDM server."""
        self.session = requests.Session()
        self.session.auth = auth
        self.session.headers.update({'content-type': 'application/json'})
        self.timeout = 5
        self.payload = cse_payload % (base)
        self.headers = {
            # Admittedly these are "magic values" but are required
            # and until a proper defaulting initializer is in place
            # are hard-coded.
            'content-type': 'application/vnd.onem2m-res+json',
            'X-M2M-Origin': '//localhost:10000',
            'X-M2M-RI': '12345',
            'X-M2M-OT': 'NOW'
        }
        self.server = "%s://" % (protocol) + server
        if base is not None:
            self.url = self.server + op_provision
            self.response = self.session.post(
                self.url, data=self.payload, timeout=self.timeout)
            print(self.response.text)

    def create(self, parent, restype, attr=None, name=None):
        """Create resource."""
        if parent is None:
            return None
        payload = resourcepayload % (attr)
        print payload
        self.headers['X-M2M-NM'] = name
        self.headers['content-type'] = 'application/\
            vnd.onem2m-res+json;ty=%s' % (restype)
        parent = normalize(parent)
        self.url = self.server + ":8282/%s?&rcn=1" % (
            parent)
        self.response = self.session.post(
            self.url, payload, timeout=self.timeout, headers=self.headers)
        return self.response

    def createWithCommand(self, parent, restype,
                          command, attr=None, name=None):
        """Create resource."""
        if parent is None:
            return None
        payload = resourcepayload % (attr)
        print payload
        if name is None:
            self.headers['X-M2M-NM'] = None
        else:
            self.headers['X-M2M-NM'] = name
        self.headers['content-type'] = 'application/\
            vnd.onem2m-res+json;ty=%s' % (restype)
        parent = normalize(parent)
        self.url = self.server + ":8282/%s?%s" % (
            parent, command)
        self.response = self.session.post(
            self.url, payload, timeout=self.timeout, headers=self.headers)
        return self.response

    def retrieve(self, resourceURI):
        """Retrieve resource."""
        if resourceURI is None:
            return None
        resourceURI = normalize(resourceURI)
        self.url = self.server + ":8282/%s?rcn=5" % (resourceURI)
        self.headers['X-M2M-NM'] = None
        self.headers['content-type'] = 'application/vnd.onem2m-res+json'
        self.response = self.session.get(
            self.url, timeout=self.timeout, headers=self.headers
        )
        return self.response

    def retrieveWithCommand(self, resourceURI, command):
        """Retrieve resource with command."""
        if resourceURI is None:
            return None
        if command is None:
            return None
        resourceURI = normalize(resourceURI)
        self.url = self.server + ":8282/%s?%s" % (resourceURI, command)
        self.headers['X-M2M-NM'] = None
        self.headers['content-type'] = 'application/vnd.onem2m-res+json'
        self.response = self.session.get(
            self.url, timeout=self.timeout, headers=self.headers
        )
        return self.response

    def update(self, resourceURI, restype, attr=None, name=None):
        """Update resource attr."""
        if resourceURI is None:
            return None
        resourceURI = normalize(resourceURI)
        # print(payload)
        payload = resourcepayload % (attr)
        print payload
        if name is None:
            self.headers['X-M2M-NM'] = None
        else:
            self.headers['X-M2M-NM'] = name
        self.headers['content-type'] = 'application/vnd.onem2m-res+json'
        self.url = self.server + ":8282/%s" % (resourceURI)
        self.response = self.session.put(
            self.url, payload, timeout=self.timeout, headers=self.headers)
        return self.response

    def updateWithCommand(self, resourceURI, restype,
                          command, attr=None, name=None):
        """Update resource attr."""
        if resourceURI is None:
            return None
        resourceURI = normalize(resourceURI)
        # print(payload)
        payload = resourcepayload % (attr)
        print payload
        if name is None:
            self.headers['X-M2M-NM'] = None
        else:
            self.headers['X-M2M-NM'] = name
        self.headers['content-type'] = 'application/vnd.onem2m-res+json'
        self.url = self.server + ":8282/%s?%s" % (resourceURI, command)
        self.response = self.session.put(
            self.url, payload, timeout=self.timeout, headers=self.headers)
        return self.response

    def delete(self, resourceURI):
        """Delete the resource with the provresourceURIed resourceURI."""
        if resourceURI is None:
            return None
        resourceURI = normalize(resourceURI)
        self.url = self.server + ":8282/%s" % (resourceURI)
        self.headers['X-M2M-NM'] = None
        self.headers['content-type'] = 'application/vnd.onem2m-res+json'
        self.response = self.session.delete(self.url, timeout=self.timeout,
                                            headers=self.headers)
        return self.response

    def deleteWithCommand(self, resourceURI, command):
        """Delete the resource with the provresourceURIed resourceURI."""
        if resourceURI is None:
            return None
        resourceURI = normalize(resourceURI)
        self.url = self.server + ":8282/%s?%s" % (resourceURI, command)
        self.headers['X-M2M-NM'] = None
        self.headers['content-type'] = 'application/vnd.onem2m-res+json'
        self.response = self.session.delete(self.url, timeout=self.timeout,
                                            headers=self.headers)
        return self.response

    def tree(self):
        """Get the resource tree."""
        self.url = self.server + op_tree
        self.response = self.session.get(self.url)
        return self.response

    def kill(self):
        """Kill the tree."""
        self.url = self.server + op_cleanup
        self.response = self.session.post(self.url)
        return self.response

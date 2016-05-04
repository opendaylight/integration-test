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

template_payload = '''
{
    "m2m:%s" : {%s}
}
'''

resources = {"m2m:acp", "m2m:ae", "m2m:cnt", "m2m:cin",
             "m2m:cb", "m2m:div", "m2m:evcg", "m2m:evin",
             "m2m:grp", "m2m:lcp", "m2m:mssp", "m2m:mgc",
             "m2m:mgo", "m2m:nod", "m2m:pch", "m2m:csr",
             "m2m:req", "m2m:sch", "m2m:asar", "m2m:svsn",
             "m2m:stcl", "m2m:stcg", "m2m:sub"}

payname_map = {1: "acp", 2: "ae", 3: "cnt", 4: "cin",
               5: "cb", 6: "div", 7: "evcg", 8: "evin",
               9: "grp", 10: "lcp", 11: "mssp", 12: "mgc",
               13: "mgo", 14: "nod", 15: "pch", 16: "csr",
               17: "req", 18: "sch", 19: "asar", 20: "svsn",
               21: "stcl", 22: "stcg", 23: "sub"}


def find_key(response, key):
    """Deserialize response, return value for key or None."""
    dic = response.json()
    key1 = list(dic.keys())
    if len(key1) != 1:
        raise ValueError("The response should be json object")
    if key1[0] not in resources:
        raise ValueError("The resource is not recognized")
    return dic.get(key1[0], None).get(key, None)


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


def normalize(resource_uri):
    """Remove the first / of /InCSE1/ae1."""
    if resource_uri is not None:
        if resource_uri[0] == "/":
            return resource_uri[1:]
    return resource_uri


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
        self.url = self.server + op_provision
        self.response = self.session.post(
            self.url, data=self.payload, timeout=self.timeout)

    def modify_headers_origin(self, new_origin):
        """Modify the headers to test ACP."""
        self.headers['X-M2M-Origin'] = new_origin

    def create(self, parent, restype, attr=None):
        """Create certain resource with attributes under parent URI.

        Args:
            :param parent: the target URI
            :param restype: the resourceType of the resource
            :param attr: the payload of the resource
        """
        if parent is None:
            return None
        restype = int(restype)
        payload = template_payload % (payname_map[restype], attr)
        self.headers['content-type'] = 'application/\
            vnd.onem2m-res+json;ty=%s' % (restype)
        parent = normalize(parent)
        self.url = self.server + ":8282/%s?&rcn=1" % (
            parent)
        self.response = self.session.post(
            self.url, payload, timeout=self.timeout, headers=self.headers)

    def create_with_command(self, parent, restype,
                            command, attr=None):
        """Create certain resource with attributes under parent URI.

        Args:
            :param parent: the target URI
            :param restype: the resourceType of the resource
            :param command: the command would be in the URI after &
            :param attr: the payload of the resource
        """
        if parent is None:
            return None
        restype = int(restype)
        payload = template_payload % (payname_map[restype], attr)
        self.headers['content-type'] = 'application/\
            vnd.onem2m-res+json;ty=%s' % (restype)
        parent = normalize(parent)
        self.url = self.server + ":8282/%s?%s" % (
            parent, command)
        self.response = self.session.post(
            self.url, payload, timeout=self.timeout, headers=self.headers)

    def retrieve(self, resource_uri):
        """Retrieve resource using resource_uri."""
        if resource_uri is None:
            return None
        resource_uri = normalize(resource_uri)
        self.url = self.server + ":8282/%s" % (resource_uri)
        self.headers['X-M2M-NM'] = None
        self.headers['content-type'] = 'application/vnd.onem2m-res+json'
        self.response = self.session.get(
            self.url, timeout=self.timeout, headers=self.headers
        )

    def retrieve_with_command(self, resource_uri, command):
        """Retrieve resource using resource_uri with command."""
        if resource_uri is None:
            return None
        if command is None:
            return None
        resource_uri = normalize(resource_uri)
        self.url = self.server + ":8282/%s?%s" % (resource_uri, command)
        self.headers['X-M2M-NM'] = None
        self.headers['content-type'] = 'application/vnd.onem2m-res+json'
        self.response = self.session.get(
            self.url, timeout=self.timeout, headers=self.headers
        )

    def update(self, resource_uri, restype, attr=None):
        """Update resource at resource_uri with new attributes."""
        if resource_uri is None:
            return None
        resource_uri = normalize(resource_uri)
        restype = int(restype)
        payload = template_payload % (payname_map[restype], attr)
        self.headers['content-type'] = 'application/vnd.onem2m-res+json'
        self.url = self.server + ":8282/%s" % (resource_uri)
        self.response = self.session.put(
            self.url, payload, timeout=self.timeout, headers=self.headers)

    def update_with_command(self, resource_uri, restype,
                            command, attr=None):
        """Update resource at resource_uri with new attributes."""
        if resource_uri is None:
            return None
        resource_uri = normalize(resource_uri)
        restype = int(restype)
        payload = template_payload % (payname_map[restype], attr)
        self.headers['content-type'] = 'application/vnd.onem2m-res+json'
        self.url = self.server + ":8282/%s?%s" % (resource_uri, command)
        self.response = self.session.put(
            self.url, payload, timeout=self.timeout, headers=self.headers)

    def delete(self, resource_uri):
        """Delete the resource at the resource_uri."""
        if resource_uri is None:
            return None
        resource_uri = normalize(resource_uri)
        self.url = self.server + ":8282/%s" % (resource_uri)
        self.headers['X-M2M-NM'] = None
        self.headers['content-type'] = 'application/vnd.onem2m-res+json'
        self.response = self.session.delete(self.url, timeout=self.timeout,
                                            headers=self.headers)

    def delete_with_command(self, resource_uri, command):
        """Delete the resource at the resource_uri."""
        if resource_uri is None:
            return None
        resource_uri = normalize(resource_uri)
        self.url = self.server + ":8282/%s?%s" % (resource_uri, command)
        self.headers['X-M2M-NM'] = None
        self.headers['content-type'] = 'application/vnd.onem2m-res+json'
        self.response = self.session.delete(self.url, timeout=self.timeout,
                                            headers=self.headers)

    def tree(self):
        """Get the resource tree."""
        self.url = self.server + op_tree
        self.response = self.session.get(self.url)

    def kill(self):
        """Kill the tree."""
        self.url = self.server + op_cleanup
        self.response = self.session.post(self.url)

"""
CSIT test tools.
Authors: Baohua Yang@IBM, Denghui Huang@IBM
Updated: 2013-10-30
"""

from restlib import *


class TestModule(object):
    """
    Basic module class for test restful APIS.
    Support the standard Create, Read, Update, Delete (CRUD) actions.
    """

    def __init__(self, restSubContext, user=DEFAULT_USER, password=DEFAULT_PWD, container=DEFAULT_CONTAINER,
                 contentType='json', prefix=DEFAULT_PREFIX):
        self.restSubContext = restSubContext
        self.container = container
        self.user = user
        self.password = password
        self.contentType = contentType
        self.prefix = prefix


    def extract_properties(self, content, key, property):
        """
        Return all nodes.
        """
        if not isinstance(content, dict) or not content.has_key(key):
            return None
        else:
            return [e.get(property) for e in content[key]]

    def get_entries(self, suffix=None, key=None):
        """
        Get the existed entries in the service.
        """
        if isinstance(suffix, list) and key:
            result = {}
            result[key] = []
            for s in suffix:
                result[key].extend(self.get_entries(s).get(key))
            return result
        elif isinstance(suffix, str):
            return self.read(suffix)
        elif not suffix:
            return self.read()
        else:
            return None

    def add_entry(self, suffix, name, body):
        """
        Add entry to the service.
        """
        self.update(suffix + '/' + name, body)

    def remove_entry(self, suffix, name):
        """
        Remove entry from the service.
        """
        self.delete(suffix + '/' + name)

    def test_add_remove_operations(self, suffix_entries, suffix_entry, name, body, key):
        result = []
        #Add an entry
        self.add_entry(suffix_entry, name, body)
        r = self.get_entries(suffix_entries, key)
        if r:
            v = r.get(key)
            result.append(body in v if v else False)
            #Remove the added entry
        if result == [True]:
            self.remove_entry(suffix_entry, name)
            r = self.get_entries(suffix_entries, key)
            v = r.get(key)
            result.append(body not in v if v else True)
        return result == [True, True]

    def create(self, suffix, body=None):
        """
        POST to given suffix url.
        TODO: complete
        """
        url = self.prefix + self.restSubContext
        if self.container:
            url += '/' + self.container
        if suffix:
            url += '/' + suffix
        return do_post_request(url, self.contentType, body, self.user, self.password)

    def read(self, suffix=None):
        """
        GET from given suffix url.
        """
        url = self.prefix + self.restSubContext
        if self.container:
            url += '/' + self.container
        if suffix:
            url += '/' + suffix
        return do_get_request_with_response_content(url, self.contentType, self.user, self.password)

    def update(self, suffix, body=None):
        """
        PUT to given suffix url.
        """
        url = self.prefix + self.restSubContext
        if self.container:
            url += '/' + self.container
        if suffix:
            url += '/' + suffix
        return do_put_request(url, self.contentType, body, self.user, self.password)

    def delete(self, suffix):
        """
        DELETE to given suffix url.
        TODO: complete
        """
        url = self.prefix + self.restSubContext
        if self.container:
            url += '/' + self.container
        if suffix:
            url += '/' + suffix
        return do_delete_request(url, self.user, self.password)

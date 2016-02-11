import requests
import json

from urllib import urlencode


import robot

from robot.libraries.BuiltIn import BuiltIn


class RequestsLibrary(object):
    ROBOT_LIBRARY_SCOPE = 'Global'

    def __init__(self):
        self._cache = robot.utils.ConnectionCache('No sessions created')
        self.builtin = BuiltIn()

    def _utf8_urlencode(self, data):
        if not type(data) is dict:
            return data

        utf8_data = {}
        for k, v in data.iteritems():
            utf8_data[k] = unicode(v).encode('utf-8')
        return urlencode(utf8_data)

    def create_session(self, alias, url, headers={}, cookies=None,
                       auth=None, timeout=None, proxies=None,
                       verify=False):

        """ Create Session: create a HTTP session to a server

        `url` Base url of the server

        `alias` Robot Framework alias to identify the session

        `headers` Dictionary of default headers

        `auth` Dictionary of username & password for HTTP Basic Auth

        `timeout` connection timeout

        `proxies` proxy server url

        `verify` set to True if Requests should verify the certificate
        """

        self.builtin.log('Creating session: %s' % alias, 'DEBUG')
        auth = requests.auth.HTTPBasicAuth(*auth) if auth else None
        s = session = requests.Session()
        s.headers.update(headers)
        s.auth = auth if auth else s.auth
        s.proxies = proxies if proxies else s.proxies

        s.verify = self.builtin.convert_to_boolean(verify)

        # cant pass these into the Session anymore
        self.timeout = timeout
        self.cookies = cookies
        self.verify = verify

        # cant use hooks :(
        s.url = url

        self._cache.register(session, alias=alias)
        return session

    def delete_all_sessions(self):
        """Removes all the session objects"""

        self._cache.empty_cache()

    def to_json(self, content):
        """Convert a string to a JSON object

        `content` String content to convert into JSON
        """
        return json.loads(content)

    def _get_url(self, session, uri):
        """Helpere method to get the full url"""
        url = session.url
        if uri:
            slash = '' if uri.startswith('/') else '/'
            url = "%s%s%s" % (session.url, slash, uri)
        return url

    def get(self, alias, uri, headers=None):
        """Send a GET request on the session object found using the given `alias`

        `alias` that will be used to identify the Session object in the cache

        `uri` to send the GET request to

        `headers` a dictionary of headers to use with the request
        """

        session = self._cache.switch(alias)
        resp = session.get(self._get_url(session, uri),
                           headers=headers,
                           cookies=self.cookies, timeout=self.timeout)

        # store the last response object
        session.last_resp = resp
        return resp

    def post(self, alias, uri, data={}, headers=None, files={}):
        """Send a POST request on the session object found using the given `alias`

        `alias` that will be used to identify the Session object in the cache

        `uri` to send the GET request to

        `data` a dictionary of key-value pairs that will be urlencoded
               and sent as POST data
               or binary data that is sent as the raw body content

        `headers` a dictionary of headers to use with the request

        `files` a dictionary of file names containing file data to POST to the server
        """

        session = self._cache.switch(alias)
        data = self._utf8_urlencode(data)

        resp = session.post(self._get_url(session, uri),
                            data=data, headers=headers,
                            files=files,
                            cookies=self.cookies, timeout=self.timeout)

        # store the last response object
        session.last_resp = resp
        self.builtin.log("Post response: " + resp.content, 'DEBUG')
        return resp

    def postjson(self, alias, uri, data={}, headers=None, files={}):
        """Send a POST request on the session object found using the given `alias`

        `alias` that will be used to identify the Session object in the cache

        `uri` to send the GET request to

        `data` a dictionary of key-value pairs that will be urlencoded
               and sent as POST data
               or binary data that is sent as the raw body content

        `headers` a dictionary of headers to use with the request

        `files` a dictionary of file names containing file data to POST to the server
        """

        session = self._cache.switch(alias)
        data = json.dumps(data)

        resp = session.post(self._get_url(session, uri),
                            data=data, headers=headers,
                            files=files,
                            cookies=self.cookies, timeout=self.timeout)

        # store the last response object
        session.last_resp = resp
        self.builtin.log("Post response: " + resp.content, 'DEBUG')
        return resp

    def put(self, alias, uri, data=None, headers=None):
        """Send a PUT request on the session object found using the given `alias`

        `alias` that will be used to identify the Session object in the cache

        `uri` to send the PUT request to

        `headers` a dictionary of headers to use with the request

        """

        session = self._cache.switch(alias)
        # data = self._utf8_urlencode(data)
        data = json.dumps(data)

        resp = session.put(self._get_url(session, uri),
                           data=data, headers=headers,
                           cookies=self.cookies, timeout=self.timeout)

        self.builtin.log("PUT response: %s DEBUG" % resp.content)

        # store the last response object
        session.last_resp = resp
        return resp

    def put_xml(self, alias, uri, data=None, headers=None):
        """Send a PUT_xml request on the session object found using the given `alias`

        `alias` that will be used to identify the Session object in the cache

        `uri` to send the PUT_xml request to

        `headers` a dictionary of headers to use with the request

        """

        session = self._cache.switch(alias)
        data = self._utf8_urlencode(data)
        # data = json.dumps(data)

        resp = session.put(self._get_url(session, uri),
                           data=data, headers=headers,
                           cookies=self.cookies, timeout=self.timeout)

        self.builtin.log("PUT response: %s DEBUG" % resp.content)

        # store the last response object
        session.last_resp = resp
        return resp

    def delete(self, alias, uri, data=(), headers=None):
        """Send a DELETE request on the session object found using the given `alias`

        `alias` that will be used to identify the Session object in the cache

        `uri` to send the DELETE request to

        `headers` a dictionary of headers to use with the request

        """

        session = self._cache.switch(alias)
        args = "?%s" % urlencode(data) if data else ''
        resp = session.delete("%s%s" % (self._get_url(session, uri), args),
                              headers=headers, cookies=self.cookies,
                              timeout=self.timeout)

        # store the last response object
        session.last_resp = resp
        return resp

    def head(self, alias, uri, headers=None):
        """Send a HEAD request on the session object found using the given `alias`

        `alias` that will be used to identify the Session object in the cache

        `uri` to send the HEAD request to

        `headers` a dictionary of headers to use with the request

        """

        session = self._cache.switch(alias)
        resp = session.head(self._get_url(session, uri), headers=headers,
                            cookies=self.cookies, timeout=self.timeout)

        # store the last response object
        session.last_resp = resp
        return resp

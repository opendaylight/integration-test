"""
This module contains functions to manipulate gerrit queries.
"""

import datetime
import json
import os
import re
import requests
import shlex
import subprocess
import traceback
import sys
import urllib3

# TODO: Need to test with python3

if sys.version < '3':
    import urllib
    import urlparse
    urlencode = urllib.urlencode
    urljoin = urlparse.urljoin
    urlparse = urlparse.urlparse
    do_input = raw_input
else:
    import urllib.parse
    import urllib.request
    urlencode = urllib.parse.urlencode
    urljoin = urllib.parse.urljoin
    urlparse = urllib.parse.urlparse
    do_input = input


class GitReviewException(Exception):
    EXIT_CODE = 127


class ChangeSetException(GitReviewException):

    def __init__(self, e):
        GitReviewException.__init__(self)
        self.e = str(e)

    def __str__(self):
        return self.__doc__ % self.e


class ReviewInformationNotFound(ChangeSetException):
    "Could not fetch review information for change %s"
    EXIT_CODE = 35


class CommandFailed(GitReviewException):
    """Command Failure Analysis"""
    def __init__(self, *args):
        Exception.__init__(self, *args)
        (self.rc, self.output, self.argv, self.envp) = args
        self.quickmsg = dict([
            ("argv", " ".join(self.argv)),
            ("rc", self.rc),
            ("output", self.output)])

    def __str__(self):
        return self.__doc__ + """
The following command failed with exit code %(rc)d
    "%(argv)s"
-----------------------
%(output)s
-----------------------""" % self.quickmsg


def get_gerrit_query(remote_url, branch, query_limit, verbose):
    if remote_url.startswith('http://') or remote_url.startswith('https://'):
        return HttpGerritQuery(remote_url, branch, query_limit, verbose)
    else:
        return SshGerritQuery(remote_url, branch, query_limit, verbose)


class GerritQuery:
    REMOTE_URL = 'ssh://git.opendaylight.org:29418'
    BRANCH = 'master'
    QUERY_LIMIT = 50

    remote_url = REMOTE_URL
    branch = BRANCH
    query_limit = QUERY_LIMIT
    verbose = 0

    def __init__(self, remote_url, branch, query_limit, verbose):
        self.remote_url = remote_url
        self.branch = branch
        self.query_limit = query_limit
        self.verbose = verbose

    def set_verbose(self, verbose):
        self.verbose = verbose

    @staticmethod
    def print_safe_encoding(string):
        if sys.stdout.encoding is None:
            print(string)
        else:
            print(string.encode(sys.stdout.encoding, 'replace'))

    def run_command_status(self, *argv, **kwargs):

        if self.verbose >= 2:
            print(datetime.datetime.now(), "Running:", " ".join(argv))
        if len(argv) == 1:
            # for python2 compatibility with shlex
            if sys.version_info < (3,) and isinstance(argv[0], unicode):
                argv = shlex.split(argv[0].encode('utf-8'))
            else:
                argv = shlex.split(str(argv[0]))
        stdin = kwargs.pop('stdin', None)
        newenv = os.environ.copy()
        newenv['LANG'] = 'C'
        newenv['LANGUAGE'] = 'C'
        newenv.update(kwargs)
        p = subprocess.Popen(argv,
                             stdin=subprocess.PIPE if stdin else None,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT,
                             env=newenv)
        (out, nothing) = p.communicate(stdin)
        out = out.decode('utf-8', 'replace')
        return p.returncode, out.strip()

    def run_command(self, *argv, **kwargs):
        (rc, output) = self.run_command_status(*argv, **kwargs)
        return output

    def run_command_exc(self, klazz, *argv, **env):
        """
        Run command *argv, on failure raise klazz

        klazz should be derived from CommandFailed
        """
        (rc, output) = self.run_command_status(*argv, **env)
        if rc != 0:
            raise klazz(rc, output, argv, env)
        return output

    def get_gerrits(self, project, changeid=None, limit=1, msg=None):
        """
        Get a list of gerrits from gerrit query request.

        Gerrit returns queries in order of lastUpdated so resort based on merge time.
        Also because gerrit returns them in lastUpdated order, it means all gerrits
        merged after the one we are using will be returned, so the query limit needs to be
        high enough to capture those extra merges plus the limit requested.
        TODO: possibly add the before query to set a start time for the query around the change

        :param str project: The project to search
        :param str or None changeid: A Change-Id to search
        :param int limit: The number of items to return
        :param str msg: A commit-msg to search
        :return str: A gerrit query
        """
        query = self.make_gerrit_query(project, changeid, limit, msg)
        gerrits = self.gerrit_request(query)
        from operator import itemgetter
        sorted_gerrits = sorted(gerrits, key=itemgetter('grantedOn'), reverse=True)
        return sorted_gerrits

    def make_gerrit_query(self, project, changeid, limit, msg):
        pass

    def gerrit_request(self, query):
        pass


class SshGerritQuery(GerritQuery):

    def parse_gerrit(self, line, parse_exc=Exception):
        """
        Parse a single gerrit line and copy certain fields to a dictionary.

        The merge time is found by looking for the Patch Set->Approval with
        a SUBM type. Then use the grantedOn value.

        :param str line: A single line from a previous gerrit query
        :param parse_exc: The exception to except
        :return dict: Pairs of gerrit items and their values
        """
        parsed = {}
        try:
            if line and line[0] == "{":
                try:
                    data = json.loads(line)
                    parsed['id'] = data['id']
                    parsed['subject'] = data['subject']
                    parsed['url'] = data['url']
                    parsed['number'] = data['number']
                    parsed['lastUpdated'] = data['lastUpdated']
                    if "patchSets" in data:
                        patch_sets = data['patchSets']
                        for patch_set in reversed(patch_sets):
                            if "approvals" in patch_set:
                                approvals = patch_set['approvals']
                                for approval in approvals:
                                    if 'type' in approval and approval['type'] == 'SUBM':
                                        parsed['grantedOn'] = approval['grantedOn']
                                        break
                                if parsed['grantedOn']:
                                    break
                except Exception:
                    if self.verbose:
                        print("Failed to decode JSON: %s" % traceback.format_exc())
                        self.print_safe_encoding(line)
        except Exception as err:
            print("Exception: %s" % traceback.format_exc())
            raise parse_exc(err)
        return parsed

    def extract_lines_from_json(self, changes):
        """
        Extract a list of lines from the JSON gerrit query response.

        Drop the stats line.

        :param unicode changes: The full JSON gerrit query response
        :return list: Lines of the JSON
        """
        lines = []
        for line in changes.split("\n"):
            if line.find('stats') == -1:
                lines.append(line)
        if self.verbose >= 2:
            print("get_gerrit_lines: found %d lines" % len(lines))
        return lines

    def parse_gerrit_ssh_params_from_git_url(self):
        """
        Parse a given Git "URL" into Gerrit parameters. Git "URLs" are either
        real URLs or SCP-style addresses.
        """

        # The exact code for this in Git itself is a bit obtuse, so just do
        # something sensible and pythonic here instead of copying the exact
        # minutiae from Git.

        # Handle real(ish) URLs
        if "://" in self.remote_url:
            parsed_url = urlparse(self.remote_url)
            path = parsed_url.path

            hostname = parsed_url.netloc
            username = None
            port = parsed_url.port

            # Workaround bug in urlparse on OSX
            if parsed_url.scheme == "ssh" and parsed_url.path[:2] == "//":
                hostname = parsed_url.path[2:].split("/")[0]

            if "@" in hostname:
                (username, hostname) = hostname.split("@")
            if ":" in hostname:
                (hostname, port) = hostname.split(":")

            if port is not None:
                port = str(port)

        # Handle SCP-style addresses
        else:
            username = None
            port = None
            (hostname, path) = self.remote_url.split(":", 1)
            if "@" in hostname:
                (username, hostname) = hostname.split("@", 1)

        # Strip leading slash and trailing .git from the path to form the project
        # name.
        project_name = re.sub(r"^/|(\.git$)", "", path)

        return hostname, username, port, project_name

    def gerrit_request(self, request):
        """
        Send a gerrit request and receive a response.

        :param str request: A gerrit query
        :return list str: A list of gerrits
        """
        (hostname, username, port, project_name) = \
            self.parse_gerrit_ssh_params_from_git_url()

        port_data = "p%s" % port if port is not None else ""
        if username is None:
            userhost = hostname
        else:
            userhost = "%s@%s" % (username, hostname)

        if self.verbose >= 2:
            print("gerrit request %s %s" % (self.remote_url, request))
        output = self.run_command_exc(
            CommandFailed,
            "ssh", "-x" + port_data, userhost,
            request)
        if self.verbose >= 3:
            self.print_safe_encoding(output)

        lines = self.extract_lines_from_json(output)
        gerrits = []
        for line in lines:
            gerrits.append(self.parse_gerrit(line))
        return gerrits

    def make_gerrit_query(self, project, changeid=None, limit=1, msg=None):
        """
        Make a gerrit query by combining the given options.

        :param str project: The project to search
        :param str changeid: A Change-Id to search
        :param int limit: The number of items to return
        :param str msg: A commit-msg to search
        :return str: A gerrit query
        """
        query = "gerrit query --format=json limit:%d status:merged --all-approvals " \
                "project:%s branch:%s" \
                % (limit, project, self.branch)
        if changeid:
            query += " change:%s" % changeid
        if msg:
            query += " message:%s" % msg
        return query


class HttpGerritQuery(GerritQuery):

    @staticmethod
    def utc_to_epoch(utc):
        import calendar
        utc = str(utc).split(".", 1)[0]
        dtime = datetime.datetime.strptime(utc, "%Y-%m-%d %H:%M:%S")
        epoch = calendar.timegm(dtime.timetuple())
        return epoch

    def parse_query(self, line, parse_exc=Exception):
        """
        Parse a single gerrit query and copy certain fields to a dictionary.

        The merge time is found by looking for the last revision and using
        it's created time.

        :param str line: A single response from a previous gerrit query
        :param parse_exc: The exception to except
        :return dict: Pairs of gerrit items and their values
        """
        gerrits = []
        try:
            try:
                lines = json.loads(line)
                for line in lines:
                    parsed = {}
                    parsed['id'] = line['change_id']
                    parsed['subject'] = line['subject']
                    parsed['number'] = str(line['_number'])
                    parsed['lastUpdated'] = self.utc_to_epoch(line['updated'])
                    parsed['url'] = "https://git.opendaylight.org/gerrit/" + parsed['number']
                    for message in line["messages"]:
                        if str(message['message']).find("Change has been successfully merged") != -1:
                            parsed['grantedOn'] = self.utc_to_epoch(message['date'])
                            break
                    if parsed['grantedOn']:
                        gerrits.append(parsed)

            except Exception:
                if self.verbose:
                    print("Failed to decode JSON: %s" % traceback.format_exc())
                    self.print_safe_encoding(line)
        except Exception as err:
            print("Exception: %s" % traceback.format_exc())
            raise parse_exc(err)
        return gerrits

    @staticmethod
    def http_code_2_return_code(code):
        """Tranform http status code to system return code."""
        return (code - 301) % 255 + 1

    def run_http_exc(self, klazz, url, **env):
        """Run http GET request url, on failure raise klazz

        klazz should be derived from CommandFailed
        """
        try:
            res = requests.get(url, **env)
            #if res.status_code == 401:
            #    creds = git_credentials(url)
            #    if creds:
            #        env['auth'] = creds
            #        res = requests.get(url, **env)
        except klazz:
            raise
        except Exception as err:
            raise klazz(255, str(err), ('GET', url), env)
        if not 200 <= res.status_code < 300:
            raise klazz(self. http_code_2_return_code(res.status_code),
                        res.text, ('GET', url), env)
        return res

    def gerrit_request(self, request):
        urllib3.disable_warnings()
        if self.verbose >= 2:
            print("gerrit request %s" % (request))
        output = self.run_http_exc(CommandFailed, request)

        if self.verbose >= 3:
            self.print_safe_encoding(output.text)

        gerrits = self.parse_query(output.text[4:])
        return gerrits

    def make_gerrit_query(self, project, changeid=None, limit=1, msg=None):
        """
        Make a gerrit query by combining the given options.

        :param str project: The project to search
        :param str changeid: A Change-Id to search
        :param int limit: The number of items to return
        :param str msg: A commit-msg to search
        :return str: A gerrit query
        """
        # https://git.opendaylight.org/gerrit/changes/?q=branch:master+project:netvirt+status:merged+change:I3250a8d1976c0b9e18b27960818525dcfb50f35f&n=1&o=CURRENT_REVISION
        query = urljoin(self.remote_url, "/gerrit/changes/")
        query += "?q=branch:%s+project:%s+status:merged" \
                 % (self.branch, project)
        if changeid:
            query += "+change:%s" % changeid
        if msg:
            query += "+message:%s" % msg
        query += "&n=%d&o=MESSAGES" % limit
        return query

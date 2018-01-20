"""
This module contains functions to manipulate gerrit queries.
"""
import datetime
import json
import logging
import os
import re
import shlex
import subprocess
import traceback
import sys

# TODO: Haven't tested python 3
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


logger = logging.getLogger("changes.gerritquery")


class GitReviewException(Exception):
    EXIT_CODE = 127


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


class GerritQuery:
    REMOTE_URL = 'ssh://git.opendaylight.org:29418'
    BRANCH = 'master'
    QUERY_LIMIT = 50

    remote_url = REMOTE_URL
    branch = BRANCH
    query_limit = QUERY_LIMIT

    def __init__(self, remote_url, branch, query_limit, verbose):
        self.remote_url = remote_url
        self.branch = branch
        self.query_limit = query_limit
        self.verbose = verbose

    @staticmethod
    def print_safe_encoding(string):
        if type(string) == unicode:
            encoding = 'utf-8'
            if hasattr(sys.stdout, 'encoding') and sys.stdout.encoding:
                encoding = sys.stdout.encoding
            return string.encode(encoding or 'utf-8', 'replace')
        else:
            return str(string)

    def run_command_status(self, *argv, **kwargs):
        logger.debug("%s Running: %s", datetime.datetime.now(), " ".join(argv))
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
        :return unicode: The JSON response
        """
        (hostname, username, port, project_name) = \
            self.parse_gerrit_ssh_params_from_git_url()

        port_data = "p%s" % port if port is not None else ""
        if username is None:
            userhost = hostname
        else:
            userhost = "%s@%s" % (username, hostname)

        logger.debug("gerrit request %s %s" % (self.remote_url, request))
        output = self.run_command_exc(CommandFailed, "ssh", "-x" + port_data, userhost, request)
        if logger.isEnabledFor(logging.DEBUG):
            logger.debug("%s", self.print_safe_encoding(output))
        return output

    def make_gerrit_query(self, project, changeid=None, limit=1, msg=None, status=None, comments=False, commitid=None):
        """
        Make a gerrit query by combining the given options.

        :param str project: The project to search
        :param str changeid: A Change-Id to search
        :param int limit: The number of items to return
        :param str msg or None: A commit-msg to search
        :param str status or None: The gerrit status, i.e. merged
        :param bool comments: If true include comments
        :param commitid: A commit hash to search
        :return str: A gerrit query
        """

        if project == "odlparent" or project == "yangtools":
            query = "gerrit query --format=json limit:%d " \
                    "project:%s" \
                    % (limit, project)
        else:
            query = "gerrit query --format=json limit:%d " \
                    "project:%s branch:%s" \
                    % (limit, project, self.branch)
        if changeid:
            query += " change:%s" % changeid
        if msg:
            query += " message:{%s}" % msg
        if commitid:
            query += " commit:%s" % commitid
        if status:
            query += " status:%s --all-approvals" % status
        if comments:
            query += " --comments"
        return query

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
                    parsed['number'] = data['number']
                    parsed['subject'] = data['subject']
                    parsed['url'] = data['url']
                    parsed['lastUpdated'] = data['lastUpdated']
                    parsed['grantedOn'] = 0
                    if "patchSets" in data:
                        patch_sets = data['patchSets']
                        for patch_set in reversed(patch_sets):
                            if "approvals" in patch_set:
                                approvals = patch_set['approvals']
                                for approval in approvals:
                                    if 'type' in approval and approval['type'] == 'SUBM':
                                        parsed['grantedOn'] = approval['grantedOn']
                                        break
                                if parsed['grantedOn'] != 0:
                                    break
                    if "comments" in data:
                        comments = data['comments']
                        for comment in reversed(comments):
                            if "message" in comment and "timestamp" in comment:
                                message = comment['message']
                                timestamp = comment['timestamp']
                                if "Build Started" in message and "patch-test" in message:
                                    parsed['grantedOn'] = timestamp
                                    break
                except Exception:
                    logger.warn("Failed to decode JSON: %s", traceback.format_exc())
                    if logger.isEnabledFor(logging.DEBUG):
                        logger.warn(self.print_safe_encoding(line))
        except Exception as err:
            logger.warn("Exception: %s", traceback.format_exc())
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
            if line.find('"type":"error","message"') != -1:
                logger.warn("there was a query error")
                continue
            if line.find('stats') == -1:
                lines.append(line)
        logger.debug("get_gerrit_lines: found %d lines", len(lines))
        return lines

    def get_gerrits(self, project, changeid=None, limit=1, msg=None, status=None, comments=False, commitid=None):
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
        :param str or None msg: A commit-msg to search
        :param str or None status: The gerrit status, i.e. merged
        :param bool comments: If true include comments
        :param commitid: A commit hash to search
        :return str: List of gerrits sorted by merge time
        """
        logger.debug("get_gerrits: project: %s, changeid: %s, limit: %d, msg: %s, status: %s, comments: %s, " +
                     "commitid: %s",
                     project, changeid, limit, msg, status, comments, commitid)
        query = self.make_gerrit_query(project, changeid, limit, msg, status, comments, commitid)
        changes = self.gerrit_request(query)
        lines = self.extract_lines_from_json(changes)
        gerrits = []
        sorted_gerrits = []
        for line in lines:
            gerrits.append(self.parse_gerrit(line))

        from operator import itemgetter
        if gerrits is None:
            logger.warn("No gerrits were found for %s", project)
            return gerrits
        try:
            sorted_gerrits = sorted(gerrits, key=itemgetter('grantedOn'), reverse=True)
        except KeyError, e:
            logger.warn("KeyError exception in %s, %s", project, str(e))
        return sorted_gerrits

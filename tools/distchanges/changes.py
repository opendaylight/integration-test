#!/usr/bin/env python
import argparse
import gerritquery
import logging
import os
import re
import sys
import time
import urllib3
import zipfile

"""
TODO:
1. What about the time between when a merge is submitted and
the patch is in the distribution? Should we look at the other
events and see when the merge job finished?
2. Use the git query option to request records in multiple queries
rather than grabbing all 50 in one shot. Keep going until the requested
number is found. Verify if this is better than just doing all 50 in one
shot since multiple requests are ssh round trips per request.
"""

# This file started as an exact copy of git-review so including it"s copyright

COPYRIGHT = """\
Copyright (C) 2011-2017 OpenStack LLC.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.

See the License for the specific language governing permissions and
limitations under the License."""


logger = logging.getLogger("changes")
logger.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s - %(levelname).4s - %(name)s - %(lineno)04d - %(message)s')
ch = logging.StreamHandler()
ch.setLevel(logging.INFO)
ch.setFormatter(formatter)
logger.addHandler(ch)
fh = logging.FileHandler("/tmp/changes.txt", "w")
fh.setLevel(logging.DEBUG)
fh.setFormatter(formatter)
logger.addHandler(fh)


class ChangeId(object):
    def __init__(self, changeid, merged):
        self.changeid = changeid
        self.merged = merged


class Changes(object):
    # NETVIRT_PROJECTS, as taken from autorelease dependency info [0]
    # TODO: it would be nice to fetch the dependency info on the fly in case it changes down the road
    # [0] https://logs.opendaylight.org/releng/jenkins092/autorelease-release-carbon/127/archives/dependencies.log.gz
    NETVIRT_PROJECTS = ["netvirt", "controller", "dlux", "dluxapps", "genius", "infrautils", "mdsal", "netconf",
                        "neutron", "odlparent", "openflowplugin", "ovsdb", "sfc", "yangtools"]
    PROJECT_NAMES = NETVIRT_PROJECTS
    VERBOSE = logging.INFO
    DISTRO_PATH = "/tmp/distribution-karaf"
    DISTRO_URL = None
    REMOTE_URL = gerritquery.GerritQuery.REMOTE_URL
    BRANCH = "master"
    LIMIT = 10
    QUERY_LIMIT = 50

    gerritquery = None
    distro_path = DISTRO_PATH
    distro_url = DISTRO_URL
    project_names = PROJECT_NAMES
    branch = BRANCH
    limit = LIMIT
    qlimit = QUERY_LIMIT
    remote_url = REMOTE_URL
    verbose = VERBOSE
    projects = {}
    regex_changeid = None
    regex_shortmsg = None
    regex_longmsg = None

    def __init__(self, branch=BRANCH, distro_path=DISTRO_PATH,
                 limit=LIMIT, qlimit=QUERY_LIMIT,
                 project_names=PROJECT_NAMES, remote_url=REMOTE_URL,
                 verbose=VERBOSE):
        self.branch = branch
        self.distro_path = distro_path
        self.limit = limit
        self.qlimit = qlimit
        self.project_names = project_names
        self.remote_url = remote_url
        self.verbose = verbose
        self.projects = {}
        self.set_log_level(verbose)
        self.regex_changeid = re.compile(r'(Change-Id.*: (\bI[a-f0-9]{40})\b|\bI([a-f0-9]{8})\b)')
        # self.regex_shortmsg = re.compile(r'"([^"]*)"|(git.commit.message.short=(.*))')
        self.regex_shortmsg1 = re.compile(r'(git.commit.message.short=.*"([^"]*)")')
        self.regex_shortmsg2 = re.compile(r'(git.commit.message.short=(.*))')
        self.regex_longmsg = re.compile(r'git.commit.message.full=(.*)')
        self.regex_commitid = re.compile(r'(git.commit.id=(.*))')

    @staticmethod
    def set_log_level(level):
        ch.setLevel(level)

    def epoch_to_utc(self, epoch):
        utc = time.gmtime(epoch)

        return time.strftime("%Y-%m-%d %H:%M:%S", utc)

    def pretty_print_gerrits(self, project, gerrits):
        if project:
            print("%s" % project)
        print("i  grantedOn           lastUpdatd          chang subject")
        print("-- ------------------- ------------------- ----- -----------------------------------------")
        if gerrits is None:
            print("gerrit is under review")
            return
        for i, gerrit in enumerate(gerrits):
            if isinstance(gerrit, dict):
                print("%02d %19s %19s %5s %s"
                      % (i,
                         self.epoch_to_utc(gerrit["grantedOn"]) if "grantedOn" in gerrit else 0,
                         self.epoch_to_utc(gerrit["lastUpdated"]) if "lastUpdated" in gerrit else 0,
                         gerrit["number"] if "number" in gerrit else "00000",
                         gerrit["subject"].encode('ascii', 'replace') if "subject" in gerrit else "none"))

    def pretty_print_projects(self, projects):
        print("========================================")
        print("distchanges")
        print("========================================")
        if isinstance(projects, dict):
            for project_name, values in sorted(projects.items()):
                if "includes" in values:
                    self.pretty_print_gerrits(project_name, values["includes"])

    def set_projects(self, project_names=PROJECT_NAMES):
        for project in project_names:
            self.projects[project] = {"commit": [], "includes": []}

    def download_distro(self):
        """
        Download the distribution from self.distro_url and extract it to self.distro_path
        """
        logger.info("attempting to download distribution from %s and extract to %s", self.distro_url, self.distro_path)

        tmp_distro_zip = '/tmp/distro.zip'
        tmp_unzipped_location = '/tmp/distro_unzipped'
        downloader = urllib3.PoolManager(cert_reqs='CERT_NONE')

        # disabling warnings to prevent scaring the user with InsecureRequestWarning
        urllib3.disable_warnings()

        downloaded_distro = downloader.request('GET', self.distro_url)
        with open(tmp_distro_zip, 'wb') as f:
            f.write(downloaded_distro.data)

        downloaded_distro.release_conn()

        # after the .zip is extracted we want to rename it to be the distro_path which may have
        # been given by the user
        distro_zip = zipfile.ZipFile(tmp_distro_zip, 'r')
        distro_zip.extractall(tmp_unzipped_location)
        unzipped_distro_folder = os.listdir(tmp_unzipped_location)

        # if the distro_path already exists, we wont overwrite it and just continue hoping what's
        # there is relevant (and maybe already put there by this tool earlier)
        try:
            os.rename(tmp_unzipped_location + "/" + unzipped_distro_folder[0], self.distro_path)
        except OSError as e:
            logger.warn(e)
            logger.warn("Unable to move extracted files from %s to %s. Using whatever bits are already there",
                        tmp_unzipped_location, self.distro_path)

    def get_includes(self, project, changeid=None, msg=None, merged=True):
        """
        Get the gerrits that would be included before the change merge time.

        :param str project: The project to search
        :param str or None changeid: The Change-Id of the gerrit to use for the merge time
        :param str or None msg: The commit message of the gerrit to use for the merge time
        :param bool merged: The requested gerrit was merged
        :return list: includes[0] is the gerrit requested, [1 to limit] are the gerrits found.
        """
        if merged:
            includes = self.gerritquery.get_gerrits(project, changeid, 1, msg, status="merged")
        else:
            includes = self.gerritquery.get_gerrits(project, changeid, 1, None, None, True)
        if not includes:
            logger.info("Review %s in %s:%s was not found", changeid, project, self.gerritquery.branch)
            return None

        gerrits = self.gerritquery.get_gerrits(project, changeid=None, limit=self.qlimit, msg=msg, status="merged")
        for gerrit in gerrits:
            # don"t include the same change in the list
            if gerrit["id"] == changeid:
                continue

            # TODO: should the check be < or <=?
            if gerrit["grantedOn"] <= includes[0]["grantedOn"]:
                includes.append(gerrit)

            # break out if we have the number requested
            if len(includes) == self.limit + 1:
                break

        if len(includes) != self.limit + 1:
            logger.info("%s query limit was not large enough to capture %d gerrits", project, self.limit)

        return includes

    @staticmethod
    def extract_gitproperties_file(fullpath):
        """
        Extract a git.properties from a jar archive.

        :param str fullpath: Path to the jar
        :return str: Containing git.properties or None if not found
        """
        if zipfile.is_zipfile(fullpath):
            zf = zipfile.ZipFile(fullpath, "r")
            try:
                pfile = zf.open("META-INF/git.properties")
                return str(pfile.read())
            except KeyError:
                pass
        return None

    def get_changeid_from_properties(self, project, pfile):
        """
        Parse the git.properties file to find a Change-Id.

        There are a few different forms that we know of so far:
        - I0123456789012345678901234567890123456789
        - I01234567
        - no Change-Id at all. There is a commit message and commit hash.
        In this example the commit hash cannot be found because it was a merge
        so you must use the message. Note spaces need to be replaced with 's.
        - a patch that has not been merged. For these we look at the gerrit comment
        for when the patch-test job starts.

        :param str project: The project to search
        :param str pfile: String containing the content of the git.properties file
        :return ChangeId: The Change-Id with a valid Change-Id or None if not found
        """
        logger.info("trying Change-Id from git.properties in %s", project)
        # match a 40 or 8 char Change-Id hash. both start with I
        changeid = self.regex_changeid.search(pfile)
        if changeid and changeid.group(2):
            logger.info("trying Change-Id from git.properties as merged in %s: %s", project, changeid.group(2))

            gerrits = self.gerritquery.get_gerrits(project, changeid.group(2), 1, None, status="merged")
            if gerrits:
                logger.info("found Change-Id from git.properties as merged in %s", project)
                return ChangeId(changeid.group(2), True)

            # Maybe this is a patch that has not merged yet
            logger.info("did not find Change-Id from git.properties as merged in %s, trying as unmerged: %s",
                        project, changeid.group(2))

            gerrits = self.gerritquery.get_gerrits(project, changeid.group(2), 1, None, status=None, comments=True)
            if gerrits:
                logger.info("found Change-Id from git.properties as unmerged in %s", project)
                return ChangeId(gerrits[0]["id"], False)

        logger.info("did not find Change-Id from git.properties in %s, trying commitid", project)

        # match a git commit id
        commitid = self.regex_commitid.search(pfile)
        if commitid and commitid.group(2):
            logger.info("trying commitid from git.properties in %s: %s", project, commitid.group(2))

            gerrits = self.gerritquery.get_gerrits(project, commitid=commitid.group(2))
            if gerrits:
                logger.info("found Change-Id from git.properties as unmerged in %s", project)
                return ChangeId(gerrits[0]["id"], True)

        logger.info("did not find Change-Id from commitid from git.properties in %s, trying short commit message1",
                    project)

        # Didn't find a Change-Id so try to get a commit message
        # match on "blah" but only keep the blah
        msg = self.regex_shortmsg1.search(pfile)
        if msg and msg.group(2):
            # logger.info("msg.groups 0: %s, 1: %s, 2: %s", msg.group(), msg.group(1), msg.group(2))
            logger.info("trying with short commit-msg 1 from git.properties in %s: %s", project, msg.group(2))

            gerrits = self.gerritquery.get_gerrits(project, msg=msg.group(2))
            if gerrits:
                logger.info("found Change-Id from git.properties short commit-msg 1 in %s", project)
                return ChangeId(gerrits[0]["id"], True)

            msg_no_spaces = msg.group(2).replace(" ", "+")
            logger.info("did not find Change-Id in %s, trying with commit-msg 1 (no spaces): %s",
                        project, msg_no_spaces)

            gerrits = self.gerritquery.get_gerrits(project, msg=msg_no_spaces)
            if gerrits:
                logger.info("found Change-Id from git.properties short commit-msg 1 (no spaces) in %s", project)
                return ChangeId(gerrits[0]["id"], True)

        logger.info("did not find Change-Id from short commit message1 from git.properties in %s", project)

        # Didn't find a Change-Id so try to get a commit message
        # match on "blah" but only keep the blah
        msg = self.regex_shortmsg2.search(pfile)
        if msg and msg.group(2):
            logger.info("trying with short commit-msg 2 from git.properties in %s: %s", project, msg.group(2))

            gerrits = self.gerritquery.get_gerrits(project, msg=msg.group(2))
            if gerrits:
                logger.info("found Change-Id from git.properties short commit-msg 2 in %s", project)
                return ChangeId(gerrits[0]["id"], True)

            msg_no_spaces = msg.group(2).replace(" ", "+")
            logger.info("did not find Change-Id in %s, trying with commit-msg 2 (no spaces): %s",
                        project, msg_no_spaces)

            gerrits = self.gerritquery.get_gerrits(project, msg=msg_no_spaces)
            if gerrits:
                logger.info("found Change-Id from git.properties short commit-msg 2 (no spaces) in %s", project)
                return ChangeId(gerrits[0]["id"], True)

        logger.info("did not find Change-Id from short commit message2 from git.properties in %s", project)

        # Maybe one of the monster 'merge the world' gerrits
        msg = self.regex_longmsg.search(pfile)
        first_msg = None
        if msg:
            lines = str(msg.group()).split("\\n")
            cli = next((i for i, line in enumerate(lines[:-1]) if '* changes\\:' in line), None)
            first_msg = lines[cli + 1] if cli else None
        if first_msg:
            logger.info("did not find Change-Id or short commit-msg in %s, trying with merge commit-msg: %s",
                        project, first_msg)
            gerrits = self.gerritquery.get_gerrits(project, None, 1, first_msg)
            if gerrits:
                logger.info("found Change-Id from git.properties merge commit-msg in %s", project)
                return ChangeId(gerrits[0]["id"], True)

        logger.warn("did not find Change-Id for %s" % project)

        return ChangeId(None, False)

    def find_distro_changeid(self, project):
        """
        Find a distribution Change-Id by finding a project jar in
        the distribution and parsing it's git.properties.

        :param str project: The project to search
        :return ChangeId: The Change-Id with a valid Change-Id or None if not found
        """
        project_dir = os.path.join(self.distro_path, "system", "org", "opendaylight", project)
        pfile = None
        for root, dirs, files in os.walk(project_dir):
            for file_ in files:
                if file_.endswith(".jar"):
                    fullpath = os.path.join(root, file_)
                    pfile = self.extract_gitproperties_file(fullpath)
                    if pfile:
                        changeid = self.get_changeid_from_properties(project, pfile)
                        if changeid.changeid:
                            return changeid
                        else:
                            logger.warn("Could not find %s Change-Id in git.properties", project)
                            break  # all jars will have the same git.properties
            if pfile is not None:
                break  # all jars will have the same git.properties
        if pfile is None:
            logger.warn("Could not find a git.properties file for %s", project)
        return ChangeId(None, False)

    def get_taglist(self):
        """
        Read a taglist.log file into memory

        :return taglist: The taglist.log file read into memory
        """
        tagfile = os.path.join(self.distro_path, "taglist.log")
        taglist = None
        # Ensure the file exists and then read it
        if os.path.isfile(tagfile):
            with open(tagfile, 'r') as fp:
                taglist = fp.read()
        return taglist

    def find_project_commit_changeid(self, taglist, project):
        """
        Find a commit id for the given project

        :param str taglist: the taglist.log file read into memory
        :param str project: The project to search
        :return ChangeId: The Change-Id with a valid Change-Id or None if not found
        """
        # break the regex up since {} is a valid regex element but we need it for the format project
        re1 = r'({0} '.format(project)
        re1 = re1 + r'(\b[a-f0-9]{40})\b|\b([a-f0-9]{8})\b' + r')'
        commitid = re.search(re1, taglist)
        if commitid and commitid.group(2):
            logger.info("trying commitid from taglist.log in %s: %s", project, commitid.group(2))

            gerrits = self.gerritquery.get_gerrits(project, commitid=commitid.group(2))
            if gerrits:
                logger.info("found Change-Id from taglist.log as merged in %s", project)
                return ChangeId(gerrits[0]["id"], True)

        logger.warn("did not find Change-Id from commitid from taglist.log in %s", project)
        return ChangeId(None, False)

    def init(self):
        self.gerritquery = gerritquery.GerritQuery(self.remote_url, self.branch, self.qlimit, self.verbose)
        self.set_projects(self.project_names)

    def print_options(self):
        print("Using these options: branch: %s, limit: %d, qlimit: %d"
              % (self.branch, self.limit, self.qlimit))
        print("remote_url: %s" % self.remote_url)
        print("distro_path: %s" % self.distro_path)
        print("projects: %s" % (", ".join(map(str, self.projects))))
        print("gerrit 00 is the most recent patch from which the project was built followed by the next most"
              " recently merged patches up to %s." % self.limit)

    def run_cmd(self):
        """
        Internal wrapper between main, options parser and internal code.

        Get the gerrit for the given Change-Id and parse it.
        Loop over all projects:
            get qlimit gerrits and parse them
            copy up to limit gerrits with a SUBM time (grantedOn) <= to the given change-id
        """
        # TODO: need method to validate the branch matches the distribution

        self.init()
        self.print_options()

        if self.distro_url is not None:
            self.download_distro()

        logger.info("Checking if this is an autorelease build by looking for taglist.log")
        taglist = self.get_taglist()
        if taglist is not None:
            for project in sorted(self.projects):
                logger.info("Processing %s using taglist.log", project)
                changeid = self.find_project_commit_changeid(taglist, project)
                if changeid.changeid:
                    self.projects[project]['commit'] = changeid.changeid
                    self.projects[project]["includes"] = \
                        self.get_includes(project, changeid.changeid, msg=None, merged=changeid.merged)
            return self.projects

        logger.info("This is not an autorelease build, continuing as integration distribution")
        for project in sorted(self.projects):
            logger.info("Processing %s", project)
            changeid = self.find_distro_changeid(project)
            if changeid.changeid:
                self.projects[project]['commit'] = changeid.changeid
                self.projects[project]["includes"] =\
                    self.get_includes(project, changeid.changeid, msg=None, merged=changeid.merged)
        return self.projects

    def main(self):
        parser = argparse.ArgumentParser(description=COPYRIGHT)

        parser.add_argument("-b", "--branch", default=self.BRANCH,
                            help="git branch for patch under test")
        parser.add_argument("-d", "--distro-path", dest="distro_path", default=self.DISTRO_PATH,
                            help="path to the expanded distribution, i.e. " + self.DISTRO_PATH)
        parser.add_argument("-u", "--distro-url", dest="distro_url", default=self.DISTRO_URL,
                            help="optional url to download a distribution " + str(self.DISTRO_URL))
        parser.add_argument("-l", "--limit", dest="limit", type=int, default=self.LIMIT,
                            help="number of gerrits to return")
        parser.add_argument("-p", "--projects", dest="projects", default=self.PROJECT_NAMES,
                            help="list of projects to include in output")
        parser.add_argument("-q", "--query-limit", dest="qlimit", type=int, default=self.QUERY_LIMIT,
                            help="number of gerrits to search")
        parser.add_argument("-r", "--remote", dest="remote_url", default=self.REMOTE_URL,
                            help="git remote url to use for gerrit")
        parser.add_argument("-v", "--verbose", dest="verbose", action="count", default=self.VERBOSE,
                            help="Output more information about what's going on")
        parser.add_argument("--license", dest="license", action="store_true",
                            help="Print the license and exit")
        parser.add_argument("-V", "--version", action="version",
                            version="%s version %s" %
                                    (os.path.split(sys.argv[0])[-1], 0.1))

        options = parser.parse_args()

        if options.license:
            print(COPYRIGHT)
            sys.exit(0)

        self.branch = options.branch
        self.distro_path = options.distro_path
        self.distro_url = options.distro_url
        self.limit = options.limit
        self.qlimit = options.qlimit
        self.remote_url = options.remote_url
        self.verbose = options.verbose
        if options.projects != self.PROJECT_NAMES:
            self.project_names = options.projects.split(',')

        # TODO: add check to verify that the remote can be reached,
        # though the first gerrit query will fail anyways

        projects = self.run_cmd()
        self.pretty_print_projects(projects)
        sys.exit(0)


def main():
    changez = Changes()
    try:
        changez.main()
    except Exception as e:
        # If one does unguarded print(e) here, in certain locales the implicit
        # str(e) blows up with familiar "UnicodeEncodeError ... ordinal not in
        # range(128)". See rhbz#1058167.
        try:
            u = unicode(e)
        except NameError:
            # Python 3, we"re home free.
            logger.warn(e)
        else:
            logger.warn(u.encode("utf-8"))
            raise
        sys.exit(getattr(e, "EXIT_CODE", -1))


if __name__ == "__main__":
    main()

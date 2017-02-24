#!/usr/bin/env python
import argparse
import gerritquery
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


class Changes(object):
    # NETVIRT_PROJECTS, as taken from autorelease dependency info [0]
    # TODO: it would be nice to fetch the dependency info on the fly in case it changes down the road
    # [0] https://logs.opendaylight.org/releng/jenkins092/autorelease-release-carbon/127/archives/dependencies.log.gz
    NETVIRT_PROJECTS = ["netvirt", "controller", "dlux", "dluxapps", "genius", "infrautils", "mdsal", "netconf",
                        "neutron", "odlparent", "openflowplugin", "ovsdb", "sfc", "yangtools"]
    PROJECT_NAMES = NETVIRT_PROJECTS
    VERBOSE = 0
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

    def epoch_to_utc(self, epoch):
        utc = time.gmtime(epoch)

        return time.strftime("%Y-%m-%d %H:%M:%S", utc)

    def pretty_print_gerrits(self, project, gerrits):
        print("")
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
                         gerrit["subject"] if "subject" in gerrit else "none"))

    def pretty_print_projects(self, projects):
        if isinstance(projects, dict):
            for project_name, values in projects.items():
                if "includes" in values:
                    self.pretty_print_gerrits(project_name, values["includes"])

    def set_projects(self, project_names=PROJECT_NAMES):
        for project in project_names:
            self.projects[project] = {"commit": [], "includes": []}

    def download_distro(self):
        """
        Download the distribution from self.distro_url and extract it to self.distro_path
        """
        if self.verbose >= 2:
            print("attempting to download distribution from %s and extract to %s " %
                  (self.distro_url, self.distro_path))

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
            print(e)
            print("Unable to move extracted files from %s to %s. Using whatever bits are already there" %
                  (tmp_unzipped_location, self.distro_path))

    def get_includes(self, project, changeid=None, msg=None):
        """
        Get the gerrits that would be included before the change merge time.

        :param str project: The project to search
        :param str changeid: The Change-Id of the gerrit to use for the merge time
        :param str msg: The commit message of the gerrit to use for the merge time
        :return list: includes[0] is the gerrit requested, [1 to limit] are the gerrits found.
        """
        includes = self.gerritquery.get_gerrits(project, changeid, 1, msg)
        if not includes:
            print("Review %s in %s:%s was not found" % (changeid, project, self.gerritquery.branch))
            return None

        gerrits = self.gerritquery.get_gerrits(project, changeid=None, limit=self.qlimit, msg=msg)
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
            print("%s query limit was not large enough to capture %d gerrits" % (project, self.limit))

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
        so you must use the message. Note spaces need to be replaced with +"s

        :param str project: The project to search
        :param str pfile: String containing the content of the git.properties file
        :return str: The Change-Id or None if not found
        """
        # match a 40 or 8 char Change-Id hash. both start with I
        regex = re.compile(r'\bI([a-f0-9]{40})\b|\bI([a-f0-9]{8})\b')
        changeid = regex.search(pfile)
        if changeid:
            return changeid.group()

        # Didn't find a Change-Id so try to get a commit message
        # match on "blah" but only keep the blah
        if self.verbose >= 2:
            print("did not find Change-Id in %s, trying with commit-msg" % (project))
        regex_msg = re.compile(r'"([^"]*)"|^git.commit.message.short=(.*)$')
        msg = regex_msg.search(pfile)
        if msg:
            if self.verbose >= 2:
                print("did not find Change-Id in %s, trying with commit-msg: %s" % (project, msg.group()))

                # TODO: add new query using this msg
            gerrits = self.gerritquery.get_gerrits(project, None, 1, msg.group())
            if gerrits:
                return gerrits[0]["id"]

        # Maybe one of the monster 'merge the world' gerrits
        regex_msg = re.compile(r'git.commit.message.full=(.*)')
        msg = regex_msg.search(pfile)
        first_msg = None
        if msg:
            lines = str(msg.group()).split("\\n")
            cli = next((i for i, line in enumerate(lines[:-1]) if '* changes\\:' in line), None)
            first_msg = lines[cli+1] if cli else None
        if first_msg:
            gerrits = self.gerritquery.get_gerrits(project, None, 1, first_msg)
            if gerrits:
                return gerrits[0]["id"]

        print("did not find Change-Id for %s" % project)

        return None

    def find_distro_changeid(self, project):
        """
        Find a distribution Change-Id by finding a project jar in
        the distribution and parsing it's git.properties.

        :param str project: The project to search
        :return str: The Change-Id or None if not found
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
                        if changeid:
                            return changeid
                        else:
                            print("Could not find %s Change-Id in git.properties" % project)
                            break  # all jars will have the same git.properties
            if pfile is not None:
                break  # all jars will have the same git.properties
        return None

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

        for project in self.projects:
            changeid = self.find_distro_changeid(project)
            if changeid:
                self.projects[project]['commit'] = changeid
                self.projects[project]["includes"] = self.get_includes(project, changeid)
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
            print(e)
        else:
            print(u.encode("utf-8"))
            raise
        sys.exit(getattr(e, "EXIT_CODE", -1))


if __name__ == "__main__":
    main()

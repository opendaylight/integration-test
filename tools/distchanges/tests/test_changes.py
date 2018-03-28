#!/usr/bin/env python

# TODO: Add more tests here using all the tests/resources/* and automate those tests in a verify job

import logging
import unittest
import distcompare
from changes import Changes

REMOTE_URL = 'ssh://git.opendaylight.org:29418'
NETVIRT_PROJECTS = ["controller", "dlux", "dluxapps", "genius", "infrautils", "mdsal", "netconf", "netvirt",
                    "neutron", "odlparent", "openflowplugin", "ovsdb", "sfc", "yangtools"]
PROJECT_NAMES = NETVIRT_PROJECTS
DISTRO_PATH = "/tmp/distribution-karaf"
BRANCH = 'master'
LIMIT = 10
QLIMIT = 50


class TestChanges(unittest.TestCase):

    def setUp(self):
        print("Starting test: %s" % self.id())

    @staticmethod
    def run_cmd(branch, distro_patch, limit, qlimit, project_names, remote_url, loglevel=0):
        changes = Changes(branch, distro_patch, limit, qlimit, project_names, remote_url, loglevel)
        projects = changes.run_cmd()
        changes.pretty_print_projects(projects)

    def test_run_cmd_single(self):
        project_names = ['netvirt']
        branch = BRANCH
        self.run_cmd(branch, DISTRO_PATH, LIMIT, QLIMIT, project_names, REMOTE_URL, logging.INFO)

    def test_run_cmd_multiple(self):
        project_names = PROJECT_NAMES
        branch = BRANCH
        self.run_cmd(branch, DISTRO_PATH, LIMIT, QLIMIT, project_names, REMOTE_URL, logging.INFO)

    def test_pretty_print(self):
        project_names = PROJECT_NAMES
        changes = Changes(BRANCH, DISTRO_PATH, LIMIT, QLIMIT, project_names, REMOTE_URL)
        projects = {}
        for project in project_names:
            projects[project] = {"commit": 1, "includes": [{'a': 1}]}
        changes.pretty_print_projects(projects)
        for project in project_names:
            projects[project] = {"commit": 1,
                                 "includes": [{"grantedOn": 1, "lastUpdated": 11,
                                               "number": "12345", "subject": "This is a test for " + project},
                                              {"grantedOn": 2, "lastUpdated": 22,
                                               "number": "56789", "subject": "This is a test for " + project}]}
        changes.pretty_print_projects(projects)

    def test_epoch_to_utc(self):
        project_names = PROJECT_NAMES
        changes = Changes(BRANCH, DISTRO_PATH, LIMIT, QLIMIT, project_names, REMOTE_URL)
        print("utc: %s" % changes.epoch_to_utc(1483974872))

    def test_distcompare(self):
        distcompare.main()


if __name__ == '__main__':
    unittest.main()

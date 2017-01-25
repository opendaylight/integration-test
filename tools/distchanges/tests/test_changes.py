#!/usr/bin/env python

import unittest

from changes import Changes

REMOTE_URL = 'ssh://git.opendaylight.org:29418'
# PROJECT_NAMES = ['genius', 'mdsal', 'netvirt', 'neutron', 'openflowjava', 'openflowplugin', 'ovsdb', 'yangtools']
PROJECT_NAMES = ['netconf', 'ovsdb', 'dlux', 'mdsal', 'dluxapps', 'netvirt', 'yangtools', 'openflowplugin', 'genius',
                 'controller', 'infrautils', 'odlparent', 'sfc', 'neutron']
DISTRO_PATH = "/tmp/distribution-karaf"
BRANCH = 'master'
LIMIT = 10
QLIMIT = 50


class TestChanges(unittest.TestCase):

    def setUp(self):
        print("Starting test: %s" % self.id())

    @staticmethod
    def run_cmd(branch, distro_patch, limit, qlimit, project_names, remote_url):
        changes = Changes(branch, distro_patch, limit, qlimit, project_names, remote_url, 0)
        projects = changes.run_cmd()
        changes.pretty_print_projects(projects)

    def test_run_cmd_single(self):
        project_names = ['netvirt']
        self.run_cmd(BRANCH, DISTRO_PATH, LIMIT, QLIMIT, project_names, REMOTE_URL)

    def test_run_cmd_multiple(self):
        project_names = PROJECT_NAMES
        self.run_cmd(BRANCH, DISTRO_PATH, LIMIT, QLIMIT, project_names, REMOTE_URL)

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

if __name__ == '__main__':
    unittest.main()

#!/usr/bin/env python

import unittest

from changes import Changes

REMOTE_URL = 'ssh://git.opendaylight.org:29418'
NETVIRT_PROJECTS = ["netvirt", "controller", "dlux", "dluxapps", "genius", "infrautils", "mdsal", "netconf",
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
    def run_cmd(branch, distro_patch, limit, qlimit, project_names, remote_url):
        changes = Changes(branch, distro_patch, limit, qlimit, project_names, remote_url, 3)
        projects = changes.run_cmd()
        changes.pretty_print_projects(projects)

    def test_run_cmd_single(self):
        project_names = ['netconf']
        self.run_cmd(BRANCH, DISTRO_PATH, LIMIT, QLIMIT, project_names, REMOTE_URL)

    def test_run_cmd_multiple(self):
        project_names = PROJECT_NAMES
        self.run_cmd(BRANCH, DISTRO_PATH, LIMIT, QLIMIT, project_names, REMOTE_URL)


if __name__ == '__main__':
    unittest.main()

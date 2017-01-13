#!/usr/bin/env python

import unittest

from changes import Changes

REMOTE_URL = 'ssh://git.opendaylight.org:29418'
PROJECT_NAMES = ['genius', 'mdsal', 'netvirt', 'neutron', 'openflowjava', 'openflowplugin', 'ovsdb', 'yangtools']
DISTRO_PATH = "/tmp/distribution-karaf"
BRANCH = 'master'
LIMIT = 10
QLIMIT = 50


class TestChanges(unittest.TestCase):

    def setUp(self):
        print("Starting test: %s" % self.id())

    @staticmethod
    def run_cmd(branch, distro_patch, limit, qlimit, project_names, remote_url):
        changes = Changes(branch, distro_patch, limit, qlimit, project_names, remote_url)
        projects = changes.run_cmd()
        changes.pretty_print_projects(projects)

    def test_run_cmd_single(self):
        project_names = ['openflowplugin']
        self.run_cmd(BRANCH, DISTRO_PATH, LIMIT, QLIMIT, project_names, REMOTE_URL)

    def test_run_cmd_multiple(self):
        project_names = PROJECT_NAMES
        self.run_cmd(BRANCH, DISTRO_PATH, LIMIT, QLIMIT, project_names, REMOTE_URL)

if __name__ == '__main__':
    unittest.main()

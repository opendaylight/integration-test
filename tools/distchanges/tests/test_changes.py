#!/usr/bin/env python
import calendar
from datetime import datetime
import time
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

    def test_time(self):
        def ismatch(t1, t2):
            return t1 == t2

        timestrs = {
            "updated": [1484408653, "2017-01-14 15:44:13.000000000"],
            "merged": [1484404299, "2017-01-14 14:31:39.000000000"],
            "created": [1484400353, "2017-01-14 13:25:53.000000000"]
        }

        for event, tstr in timestrs.items():
            gmtime = datetime.strptime(tstr[1], "%Y-%m-%d %H:%M:%S.000000000")
            print("time:     %s - %s - %s" % (tstr[0], event, tstr[1]))
            mtime = time.mktime(gmtime.timetuple())
            print("gmtime:   %f %s" % (mtime, ismatch(mtime, tstr[0])))
            ctime = calendar.timegm(gmtime.timetuple())
            print("calendar: %d, %s" % (ctime, ismatch(ctime, tstr[0])))

    @staticmethod
    def run_cmd(branch, distro_patch, limit, qlimit, project_names, remote_url, verbose=0):
        changes = Changes(branch, distro_patch, limit, qlimit, project_names, remote_url, verbose)
        projects = changes.run_cmd()
        changes.pretty_print_projects(projects)

    def test_ssh_run_cmd_single(self):
        project_names = ['openflowplugin']
        self.run_cmd(BRANCH, DISTRO_PATH, LIMIT, QLIMIT, project_names, REMOTE_URL)

    def test_ssh_run_cmd_multiple(self):
        project_names = PROJECT_NAMES
        self.run_cmd(BRANCH, DISTRO_PATH, LIMIT, QLIMIT, project_names, REMOTE_URL)

    def test_http_run_cmd_single(self):
        project_names = ['openflowplugin']
        remote_url = 'https://git.opendaylight.org/gerrit'
        self.run_cmd(BRANCH, DISTRO_PATH, LIMIT, QLIMIT, project_names, remote_url, 0)

    def test_http_run_cmd_multiple(self):
        project_names = PROJECT_NAMES
        remote_url = 'https://git.opendaylight.org/gerrit'
        self.run_cmd(BRANCH, DISTRO_PATH, LIMIT, QLIMIT, project_names, remote_url, 0)

if __name__ == '__main__':
    unittest.main()

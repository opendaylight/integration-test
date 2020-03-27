# Copyright (c) 2018 Red Hat, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html

import logging
import unittest
from gerritquery import GerritQuery
import logg


REMOTE_URL = GerritQuery.remote_url
BRANCH = "stable/oxygen"
LIMIT = 10
QLIMIT = 50
VERBOSE = 0
PROJECT = "controller"


class TestRequest(unittest.TestCase):
    def setUp(self):
        logg.Logger(logging.DEBUG, logging.INFO)
        self.gerritquery = GerritQuery(REMOTE_URL, BRANCH, QLIMIT, VERBOSE)

    def test_get_gerrits(self):
        changeid = "I41232350532e56340c1fe9853ef7e74e3aa03359"
        gerrits = self.gerritquery.get_gerrits(PROJECT, changeid, 1, status="merged")
        print("{}".format(gerrits))


if __name__ == "__main__":
    unittest.main()

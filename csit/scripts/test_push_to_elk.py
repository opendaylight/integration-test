#!/usr/bin/python
# -*- coding: utf-8 -*-

# @License EPL-1.0 <http://spdx.org/licenses/EPL-1.0>
##############################################################################
# Copyright (c) 2018 Taseer Ahmed and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

import unittest
from test.test_support import EnvironmentVarGuard


class TestJsonPayLoad(unittest.TestCase):

    """
    Tests the JSON payload pushed to Elastic
    """

    def setUp(self):
        self.env = EnvironmentVarGuard()
        self.env.set('SILO', 'intel')
        self.env.set('JOB_NAME', 'csit')
        self.env.set('BUILD_NUMBER', '5')
        self.env.set('WORKSPACE', './testfiles')

    def test_json_type(self):
        import push_to_elk
        with self.env:
            payload = push_to_elk.construct_json()
            assert(isinstance(payload, dict))


if __name__ == '__main__':
    unittest.main()

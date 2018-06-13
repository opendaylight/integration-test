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

from mock import patch
import os
import push_to_elk
import unittest


class TestJsonPayLoad(unittest.TestCase):

    """
    Tests the JSON payload pushed to Elastic
    """

    def test_json_type(self):
        with patch.dict('os.environ', {'SILO': 'jenkins',
                                       'JOB_NAME': 'csit',
                                       'BUILD_NUMBER': '5',
                                       'WORKSPACE': os.path.join(os.path.dirname(__file__), 'testfiles')}):
            payload = push_to_elk.construct_json()
            assert(isinstance(payload, dict))


if __name__ == '__main__':
    unittest.main()

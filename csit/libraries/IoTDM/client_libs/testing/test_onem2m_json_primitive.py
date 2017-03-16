#
# Copyright (c) 2017 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html
#

import unittest
import json

from onem2m_json_primitive import OneM2MJsonPrimitiveBuilder
from onem2m_primitive import OneM2M


class TestOneM2MJsonPrimitive(unittest.TestCase):
    """Class of unittests testing OneM2MJsonPrimitive objects"""

    params = """{"test": {"value": 1} }"""
    content = """{"content": 123, "content2": {"content_element": "ce1"}}"""
    proto_params = """{"proto_param1": 1, "proto_param2": 2, "proto_param3" : {"element1": "e1"}}"""

    def test_primitive_build_no_content(self):
        builder = OneM2MJsonPrimitiveBuilder()
        builder.set_parameters(self.params)
        primitive = builder.build()
        self.assertIsNotNone(primitive)
        self.assertIsNotNone(primitive.get_parameters_str())
        self.assertIsNotNone(primitive.get_primitive_str())
        json_primitive = json.loads(primitive.get_primitive_str())
        self.assertNotIn(OneM2M.short_primitive_content, json_primitive)

        self.assertEqual(json.dumps(json_primitive),
                         primitive.get_parameters_str())

    def _create_primitive(self):
        builder = OneM2MJsonPrimitiveBuilder()\
               .set_parameters(self.params)\
               .set_content(self.content)\
               .set_protocol_specific_parameters(self.proto_params)
        return builder.build()

    def test_primitive_build_with_content(self):
        primitive = self._create_primitive()
        self.assertIsNotNone(primitive)
        self.assertIsNotNone(primitive.get_parameters_str())
        self.assertIsNotNone(primitive.get_primitive_str())

        json_primitive = json.loads(primitive.get_primitive_str())
        self.assertIn(OneM2M.short_primitive_content, json_primitive)

        self.assertEqual(json.dumps(json_primitive[OneM2M.short_primitive_content]),
                         primitive.get_content_str())

    def test_primitive_items_access(self):
        primitive = self._create_primitive()
        test_param = primitive.get_param("/test")
        self.assertIsNotNone(test_param)
        self.assertTrue(isinstance(test_param, dict))

        item_val = primitive.get_param("/test/value")
        self.assertEqual(item_val, 1)

        content2_attr = primitive.get_attr("/content2")
        self.assertIsNotNone(content2_attr)
        self.assertTrue(isinstance(content2_attr, dict))

        item_val = primitive.get_attr("/content/")
        self.assertEqual(item_val, 123)
        item_val = primitive.get_attr("/content")
        self.assertEqual(item_val, 123)
        item_val = primitive.get_attr("/content2/content_element")
        self.assertEqual(item_val, "ce1")

        proto_param3 = primitive.get_proto_param("/proto_param3")
        self.assertIsNotNone(proto_param3)
        self.assertTrue(isinstance(proto_param3, dict))

        item_val = primitive.get_proto_param("/proto_param2")
        self.assertEqual(item_val, 2)
        item_val = primitive.get_proto_param("/proto_param3/element1/")
        self.assertEqual(item_val, "e1")

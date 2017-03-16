#
# Copyright (c) 2017 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html
#

import unittest

from onem2m_json_primitive import OneM2MJsonPrimitiveBuilder
import onem2m_http
from onem2m_http import OneM2MHttpJsonEncoderTx
from onem2m_http import OneM2MHttpJsonDecoderTx
from onem2m_http import OneM2MHttpJsonDecoderRx
from onem2m_http import OneM2MHttpJsonEncoderRx
from onem2m_http import OneM2MHttpTx
from onem2m_http import OneM2MHttpRx
from onem2m_http import http_result_code
from onem2m_primitive import OneM2M


class TestOneM2MHttp(unittest.TestCase):
    """Class of unittests testing OneM2M HTTP communication and related classes"""

    params = {OneM2M.short_to: "InCSE2/Postman", "op": 2, "fr": "AE1", "rqi": 12345}
    proto_params = {onem2m_http.protocol_address: "localhost", onem2m_http.protocol_port: 8282,
                    "Content-Type": "application/json"}
    content = {"content": 123}

    def test_primitive_encoding(self):
        builder = OneM2MJsonPrimitiveBuilder()
        builder.set_parameters(self.params)
        builder.set_protocol_specific_parameters(self.proto_params)
        primitive = builder.build()
        encoder = OneM2MHttpJsonEncoderTx()
        http_req = encoder.encode(primitive)
        self.assertIsNotNone(http_req)

    def test_primitive_decoding(self):
        # TODO
        raise NotImplementedError()

    def test_primitive_encoded_decode_compare(self):
        # TODO encode primitive, decode encoded primitive and use _compare()
        # TODO method of primitive and the primitives should be equal
        raise NotImplementedError()

    def _rx_cb(self, request_primitive):
        # TODO just return the request_primitive as passed (as loopback)

        # now just set result code and return
        rsp_builder = OneM2MJsonPrimitiveBuilder()
        rsp_builder.set_param(OneM2M.short_response_status_code, OneM2M.result_code_ok)
        rsp_builder.set_proto_param(http_result_code, 200)
        return rsp_builder.build()

    def test_communicaton_send(self):
        params = {OneM2M.short_to: "InCSE2/Postman", "op": 2, "fr": "AE1", "rqi": 12345, "rcn": 1, "ty": 4}
        proto_params = {onem2m_http.protocol_address: "localhost", onem2m_http.protocol_port: 5000,
                        "Content-Type": "application/json"}
        content = {"content": 123}

        encoder = OneM2MHttpJsonEncoderTx()
        decoder = OneM2MHttpJsonDecoderTx()
        tx = OneM2MHttpTx(encoder, decoder)
        tx.start()

        decoder = OneM2MHttpJsonDecoderRx()
        encoder = OneM2MHttpJsonEncoderRx()
        rx = OneM2MHttpRx(decoder, encoder, 5000)
        rx.start(self._rx_cb)

        builder = OneM2MJsonPrimitiveBuilder()
        builder.set_parameters(params)
        builder.set_protocol_specific_parameters(proto_params)
        builder.set_content(content)
        primitive = builder.build()

        rsp_primitive = tx.send(primitive)
        # TODO rsp_primitive should be the same primitive, just use _compare()
        # TODO method of primitive if was correctly encoded / decoded

        tx.stop()
        rx.stop()

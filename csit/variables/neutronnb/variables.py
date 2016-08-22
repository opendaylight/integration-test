"""Variables for interacting with ODL's Neutron Northbound API."""

import os

templates_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                             "request_templates")

CREATE_EXT_NET_TEMPLATE = os.path.join(templates_dir, "create_ext_net.json")

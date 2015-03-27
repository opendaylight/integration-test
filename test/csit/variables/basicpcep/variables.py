"""Variables file for basicpcep suite.

Expected JSON templates are fairly long,
therefore there are moved out of testcase file.
Also, it is needed to generate base64 encoded tunnel name
from Mininet IP (which is not known beforehand),
so it is easier to employ Python here,
than do manipulation in Robot file."""
# Copyright (c) 2015 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html

__author__ = "Vratko Polak"
__copyright__ = "Copyright(c) 2015, Cisco Systems, Inc."
__license__ = "Eclipse Public License v1.0"
__email__ = "vrpolak@cisco.com"

import binascii
from string import Template


def get_variables(mininet_ip):
    """Return dict of variables for the given IP addtess of Mininet VM."""
    tunnelname = 'pcc_' + mininet_ip + '_tunnel_1'
    pathcode = binascii.b2a_base64(tunnelname)[:-1]  # remove endline
    offjson = '''{
 "topology": [
  {
   "topology-id": "pcep-topology",
   "topology-types": {
    "network-topology-pcep:topology-pcep": {}
   }
  }
 ]
}'''
    onjsontempl = Template('''{
 "topology": [
  {
   "node": [
    {
     "network-topology-pcep:path-computation-client": {
      "ip-address": "$IP",
      "reported-lsp": [
       {
        "name": "$NAME",
        "path": [
         {
          "ero": {
           "ignore": false,
           "processing-rule": false,
           "subobject": [
            {
             "ip-prefix": {
              "ip-prefix": "1.1.1.1/32"
             },
             "loose": false
            }
           ]
          },
          "lsp-id": 1,
          "odl-pcep-ietf-stateful07:lsp": {
           "administrative": true,
           "delegate": true,
           "ignore": false,
           "odl-pcep-ietf-initiated00:create": false,
           "operational": "up",
           "plsp-id": 1,
           "processing-rule": false,
           "remove": false,
           "sync": true,
           "tlvs": {
            "lsp-identifiers": {
             "ipv4": {
              "ipv4-extended-tunnel-id": "$IP",
              "ipv4-tunnel-endpoint-address": "1.1.1.1",
              "ipv4-tunnel-sender-address": "$IP"
             },
             "lsp-id": 1,
             "tunnel-id": 1
            },
            "symbolic-path-name": {
             "path-name": "$CODE"
            }
           }
          }
         }
        ]
       }
      ],
      "state-sync": "synchronized",
      "stateful-tlv": {
       "odl-pcep-ietf-stateful07:stateful": {
        "lsp-update-capability": true,
        "odl-pcep-ietf-initiated00:initiation": true
       }
      }
     },
     "node-id": "pcc://$IP"
    }
   ],
   "topology-id": "pcep-topology",
   "topology-types": {
    "network-topology-pcep:topology-pcep": {}
   }
  }
 ]
}''')
    repl_dict = {'IP': mininet_ip, 'NAME': tunnelname, 'CODE': pathcode}
    onjson = onjsontempl.substitute(repl_dict)
    variables = {'offjson': offjson, 'onjson': onjson}
    return variables

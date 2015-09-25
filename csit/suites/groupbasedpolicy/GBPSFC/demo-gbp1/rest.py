#!/usr/bin/python
import argparse
import requests,json
from requests.auth import HTTPBasicAuth
from subprocess import call
import time
import sys
import os


DEFAULT_PORT='8181'


USERNAME='admin'
PASSWORD='admin'


OPER_NODES='/restconf/operational/opendaylight-inventory:nodes/'
CONF_TENANT='/restconf/config/policy:tenants'

def get(host, port, uri):
    url='http://'+host+":"+port+uri
    #print url
    r = requests.get(url, auth=HTTPBasicAuth(USERNAME, PASSWORD))
    jsondata=json.loads(r.text)
    return jsondata

def put(host, port, uri, data, debug=False):
    '''Perform a PUT rest operation, using the URL and data provided'''

    url='http://'+host+":"+port+uri

    headers = {'Content-type': 'application/yang.data+json',
               'Accept': 'application/yang.data+json'}
    if debug == True:
        print "PUT %s" % url
        print json.dumps(data, indent=4, sort_keys=True)
    r = requests.put(url, data=json.dumps(data), headers=headers, auth=HTTPBasicAuth(USERNAME, PASSWORD))
    if debug == True:
        print r.text
    r.raise_for_status()

def post(host, port, uri, data, debug=False):
    '''Perform a POST rest operation, using the URL and data provided'''

    url='http://'+host+":"+port+uri
    headers = {'Content-type': 'application/yang.data+json',
               'Accept': 'application/yang.data+json'}
    if debug == True:
        print "POST %s" % url
        print json.dumps(data, indent=4, sort_keys=True)
    r = requests.post(url, data=json.dumps(data), headers=headers, auth=HTTPBasicAuth(USERNAME, PASSWORD))
    if debug == True:
        print r.text
    r.raise_for_status()
    

def get_tenant_data():
    return {
    "policy:tenant": {
        "contract": [
            {
                "clause": [
                    {
                        "name": "allow-http-clause", 
                        "subject-refs": [
                            "allow-http-subject", 
                            "allow-icmp-subject"
                        ]
                    }
                ], 
                "id": "22282cca-9a13-4d0c-a67e-a933ebb0b0ae", 
                "subject": [
                    {
                        "name": "allow-http-subject", 
                        "rule": [
                            {
                                "classifier-ref": [
                                    {
                                        "direction": "in", 
                                        "name": "http-dest",
					"instance-name" : "http-dest",
                                    }, 
                                    {
                                        "direction": "out", 
                                        "name": "http-src",
					"instance-name" : "http-src"
                                    }
                                ],
                                                    "action-ref": [
                      {
                        "name": "allow1",
                        "order": 0
                      }
                    ],

                                "name": "allow-http-rule"
                            }
                        ]
                    }, 
                    {
                        "name": "allow-icmp-subject", 
                        "rule": [
                            {
                                "classifier-ref": [
                                    {
                                        "name": "icmp",
					"instance-name" : "icmp"
                                    }
                                ], 
                                                    "action-ref": [
                      {
                        "name": "allow1",
                        "order": 0
                      }
                    ],

                                "name": "allow-icmp-rule"
                            }
                        ]
                    }
                ]
            }
        ], 
        "endpoint-group": [
            {
                "consumer-named-selector": [
                    {
                        "contract": [
                            "22282cca-9a13-4d0c-a67e-a933ebb0b0ae"
                        ], 
                        "name": "e593f05d-96be-47ad-acd5-ba81465680d5-1eaf9a67-a171-42a8-9282-71cf702f61dd-22282cca-9a13-4d0c-a67e-a933ebb0b0ae"
                    }
                ], 
                "id": "1eaf9a67-a171-42a8-9282-71cf702f61dd", 
                "network-domain": "d2779562-ebf1-45e6-93a4-78e2362bc418", 
                "provider-named-selector": []
            }, 
            {
                "consumer-named-selector": [], 
                "id": "e593f05d-96be-47ad-acd5-ba81465680d5", 
                "network-domain": "2c71d675-693e-406f-899f-12a026eb55f1", 
                "provider-named-selector": [
                    {
                        "contract": [
                            "22282cca-9a13-4d0c-a67e-a933ebb0b0ae"
                        ], 
                        "name": "e593f05d-96be-47ad-acd5-ba81465680d5-1eaf9a67-a171-42a8-9282-71cf702f61dd-22282cca-9a13-4d0c-a67e-a933ebb0b0ae"
                    }
                ]
            }
        ], 
        "id": "f5c7d344-d1c7-4208-8531-2c2693657e12", 
        "l2-bridge-domain": [
            {
                "id": "7b796915-adf4-4356-b5ca-de005ac410c1", 
                "parent": "cbe0cc07-b8ff-451d-8171-9eef002a8e80"
            }
        ], 
        "l2-flood-domain": [
            {
                "id": "1ddde8d8-c2bc-48d7-8ce0-d78eb6ed4b5b", 
                "parent": "7b796915-adf4-4356-b5ca-de005ac410c1"
            }, 
            {
                "id": "03f69af2-481c-4554-97d6-c4fedca5d126", 
                "parent": "7b796915-adf4-4356-b5ca-de005ac410c1"
            }
        ], 
        "l3-context": [
            {
                "id": "cbe0cc07-b8ff-451d-8171-9eef002a8e80"
            }
        ], 
        "name": "GBPPOC", 
        "subject-feature-instances": {
            "classifier-instance": [
                {
                    "classifier-definition-id": "4250ab32-e8b8-445a-aebb-e1bd2cdd291f", 
                    "name": "http-dest", 
                    "parameter-value": [
                        {
                            "int-value": "6", 
                            "name": "proto"
                        }, 
                        {
                            "int-value": "80", 
                            "name": "destport"
                        }
                    ]
                }, 
                {
                    "classifier-definition-id": "4250ab32-e8b8-445a-aebb-e1bd2cdd291f", 
                    "name": "http-src", 
                    "parameter-value": [
                        {
                            "int-value": "6", 
                            "name": "proto"
                        }, 
                        {
                            "int-value": "80", 
                            "name": "sourceport"
                        }
                    ]
                }, 
                {
                    "classifier-definition-id": "79c6fdb2-1e1a-4832-af57-c65baf5c2335", 
                    "name": "icmp", 
                    "parameter-value": [
                        {
                            "int-value": "1", 
                            "name": "proto"
                        }
                    ]
                }
            ],
          "action-instance": [
            {
              "name": "allow1",
              "action-definition-id": "f942e8fd-e957-42b7-bd18-f73d11266d17"
            }
          ]
        }, 
        "subnet": [
            {
                "id": "d2779562-ebf1-45e6-93a4-78e2362bc418", 
                "ip-prefix": "10.0.35.1/24", 
                "parent": "1ddde8d8-c2bc-48d7-8ce0-d78eb6ed4b5b", 
                "virtual-router-ip": "10.0.35.1"
            }, 
            {
                "id": "2c71d675-693e-406f-899f-12a026eb55f1", 
                "ip-prefix": "10.0.36.1/24", 
                "parent": "03f69af2-481c-4554-97d6-c4fedca5d126", 
                "virtual-router-ip": "10.0.36.1"
            }
        ]
    }
            }

# Main definition - constants
 
# =======================
#     MENUS FUNCTIONS
# =======================
 
# Main menu

# =======================
#      MAIN PROGRAM
# =======================
 
# Main Program

def get_tenant_uri():
    return "/restconf/config/policy:tenants/policy:tenant/f5c7d344-d1c7-4208-8531-2c2693657e12"

def get_tunnel_data():
    return {
  "opendaylight-inventory:nodes": {
    "node": [
      {
        "id": "openflow:1",
        "ofoverlay:tunnel": [
          {
            "tunnel-type": "overlay:tunnel-type-vxlan-gpe",
            "node-connector-id": "openflow:1:1",
            "ip": "192.168.50.70",
            "port": 6633
          },
          {
            "tunnel-type": "overlay:tunnel-type-vxlan",
            "node-connector-id": "openflow:1:2",
            "ip": "192.168.50.70",
            "port": 4789
          }
        ]
      },
      {
        "id": "openflow:2",
        "ofoverlay:tunnel": [
          {
            "tunnel-type": "overlay:tunnel-type-vxlan-gpe",
            "node-connector-id": "openflow:2:1",
            "ip": "192.168.50.71",
            "port": 6633
          },
          {
            "tunnel-type": "overlay:tunnel-type-vxlan",
            "node-connector-id": "openflow:2:2",
            "ip": "192.168.50.71",
            "port": 4789
          }
        ]
      },
                   {
        "id": "openflow:3",
        "ofoverlay:tunnel": [
          {
            "tunnel-type": "overlay:tunnel-type-vxlan-gpe",
            "node-connector-id": "openflow:3:1",
            "ip": "192.168.50.72",
            "port": 6633
          },
          {
            "tunnel-type": "overlay:tunnel-type-vxlan",
            "node-connector-id": "openflow:3:2",
            "ip": "192.168.50.72",
            "port": 4789
          }
        ]
      },
             
    ]
  }
            }
    
def get_tunnel_uri():
    return "/restconf/config/opendaylight-inventory:nodes"

def get_endpoint_data():
    return [{
    "input": {

        "endpoint-group": "1eaf9a67-a171-42a8-9282-71cf702f61dd", 

        "network-containment" : "d2779562-ebf1-45e6-93a4-78e2362bc418",

        "l2-context": "7b796915-adf4-4356-b5ca-de005ac410c1", 
        "mac-address": "00:00:00:00:35:02", 

        "l3-address": [
            {
                "ip-address": "10.0.35.2", 
                "l3-context": "cbe0cc07-b8ff-451d-8171-9eef002a8e80"
            }
        ], 
        "port-name": "vethl-h35_2", 
        "tenant": "f5c7d344-d1c7-4208-8531-2c2693657e12"
    }
},
            {
    "input": {

        "endpoint-group": "1eaf9a67-a171-42a8-9282-71cf702f61dd", 

        "network-containment" : "d2779562-ebf1-45e6-93a4-78e2362bc418",

        "l2-context": "7b796915-adf4-4356-b5ca-de005ac410c1", 
        "mac-address": "00:00:00:00:35:03", 

        "l3-address": [
            {
                "ip-address": "10.0.35.3", 
                "l3-context": "cbe0cc07-b8ff-451d-8171-9eef002a8e80"
            }
        ], 
        "port-name": "vethl-h35_3", 
        "tenant": "f5c7d344-d1c7-4208-8531-2c2693657e12"
    }
},
            {
    "input": {

        "endpoint-group": "1eaf9a67-a171-42a8-9282-71cf702f61dd", 

        "network-containment" : "d2779562-ebf1-45e6-93a4-78e2362bc418",

        "l2-context": "7b796915-adf4-4356-b5ca-de005ac410c1", 
        "mac-address": "00:00:00:00:35:04", 

        "l3-address": [
            {
                "ip-address": "10.0.35.4", 
                "l3-context": "cbe0cc07-b8ff-451d-8171-9eef002a8e80"
            }
        ], 
        "port-name": "vethl-h35_4", 
        "tenant": "f5c7d344-d1c7-4208-8531-2c2693657e12"
    }
},
            {
    "input": {

        "endpoint-group": "1eaf9a67-a171-42a8-9282-71cf702f61dd", 

        "network-containment" : "d2779562-ebf1-45e6-93a4-78e2362bc418",

        "l2-context": "7b796915-adf4-4356-b5ca-de005ac410c1", 
        "mac-address": "00:00:00:00:35:05", 

        "l3-address": [
            {
                "ip-address": "10.0.35.5", 
                "l3-context": "cbe0cc07-b8ff-451d-8171-9eef002a8e80"
            }
        ], 
        "port-name": "vethl-h35_5", 
        "tenant": "f5c7d344-d1c7-4208-8531-2c2693657e12"
    }
},
            {
    "input": {

        "endpoint-group": "e593f05d-96be-47ad-acd5-ba81465680d5", 

        "network-containment" : "2c71d675-693e-406f-899f-12a026eb55f1",

        "l2-context": "7b796915-adf4-4356-b5ca-de005ac410c1", 
        "mac-address": "00:00:00:00:36:02", 

        "l3-address": [
            {
                "ip-address": "10.0.36.2", 
                "l3-context": "cbe0cc07-b8ff-451d-8171-9eef002a8e80"
            }
        ], 
        "port-name": "vethl-h36_2", 
        "tenant": "f5c7d344-d1c7-4208-8531-2c2693657e12"
    }
},
            {
    "input": {

        "endpoint-group": "e593f05d-96be-47ad-acd5-ba81465680d5", 

        "network-containment" : "2c71d675-693e-406f-899f-12a026eb55f1",

        "l2-context": "7b796915-adf4-4356-b5ca-de005ac410c1", 
        "mac-address": "00:00:00:00:36:03", 

        "l3-address": [
            {
                "ip-address": "10.0.36.3", 
                "l3-context": "cbe0cc07-b8ff-451d-8171-9eef002a8e80"
            }
        ], 
        "port-name": "vethl-h36_3", 
        "tenant": "f5c7d344-d1c7-4208-8531-2c2693657e12"
    }
},
            {
    "input": {

        "endpoint-group": "e593f05d-96be-47ad-acd5-ba81465680d5", 

        "network-containment" : "2c71d675-693e-406f-899f-12a026eb55f1",

        "l2-context": "7b796915-adf4-4356-b5ca-de005ac410c1", 
        "mac-address": "00:00:00:00:36:04", 

        "l3-address": [
            {
                "ip-address": "10.0.36.4", 
                "l3-context": "cbe0cc07-b8ff-451d-8171-9eef002a8e80"
            }
        ], 
        "port-name": "vethl-h36_4", 
        "tenant": "f5c7d344-d1c7-4208-8531-2c2693657e12"
    }
},{
    "input": {

        "endpoint-group": "e593f05d-96be-47ad-acd5-ba81465680d5", 

        "network-containment" : "2c71d675-693e-406f-899f-12a026eb55f1",

        "l2-context": "7b796915-adf4-4356-b5ca-de005ac410c1", 
        "mac-address": "00:00:00:00:36:05", 

        "l3-address": [
            {
                "ip-address": "10.0.36.5", 
                "l3-context": "cbe0cc07-b8ff-451d-8171-9eef002a8e80"
            }
        ], 
        "port-name": "vethl-h36_5", 
        "tenant": "f5c7d344-d1c7-4208-8531-2c2693657e12"
    }
}]

def get_endpoint_uri():
    return "/restconf/operations/endpoint:register-endpoint"

if __name__ == "__main__":
    # Launch main menu


    # Some sensible defaults
    controller=os.environ.get('ODL')
    if controller == None:
        sys.exit("No controller set.")
    

    print "tenants"
    tenants=get(controller,DEFAULT_PORT,CONF_TENANT)
    print tenants
    
    print "sending tenant"
    put(controller, DEFAULT_PORT, get_tenant_uri(), get_tenant_data(),True)
    print "sending tunnel"
    put(controller, DEFAULT_PORT, get_tunnel_uri(), get_tunnel_data(), True)
    print "registering endpoints"
    for endpoint in get_endpoint_data():
        post(controller, DEFAULT_PORT, get_endpoint_uri(),endpoint,True)
        
        
    
    

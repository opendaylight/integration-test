#!/bin/bash

honeycomb_restconf_port=$1

post_data='{"interface": [
{"name": "tap0",
"description": "for testing purposes",
"type": "v3po:tap",
"tap" :
{"tap-name" : "tap0"}
}
]
}
'
echo $post_data
curl -u admin:admin -X PUT -d "$post_data" -H 'Content-Type: application/json' http://localhost:$honeycomb_restconf_port/restconf/config/ietf-interfaces:interfaces/interface/tap0


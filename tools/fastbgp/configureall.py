#!/usr/bin/env python3

import requests
from subprocess import Popen, PIPE

for i in range(2, 12):

	url1 = "http://localhost:8181/restconf/config/openconfig-network-instance:network-instances/network-instance/global-bgp/openconfig-network-instance:protocols/protocol/openconfig-policy-types:BGP/example-bgp-rib/bgp/neighbors/neighbor/127.0.0." + str(i)
	#print(url1)
	payload = "<neighbor xmlns=\"urn:opendaylight:params:xml:ns:yang:bgp:openconfig-extensions\">\n    <neighbor-address>127.0.0." + str(i) \
	+ "</neighbor-address>\n    <route-reflector>\n        <config>\n            <route-reflector-client>false</route-reflector-client>\n        </config>\n    </route-reflector>\n    <timers>\n        <config>\n            <hold-time>180</hold-time>\n            <connect-retry>5</connect-retry>\n        </config>\n    </timers>\n    <transport>\n        <config>\n            <remote-port>17900</remote-port>\n            <passive-mode>true</passive-mode>\n        </config>\n    </transport>\n    <config>\n        <peer-type>INTERNAL</peer-type>\n    </config>\n    <afi-safis>\n        <afi-safi>\n            <afi-safi-name xmlns:x=\"http://openconfig.net/yang/bgp-types\">x:IPV4-UNICAST</afi-safi-name>\n        </afi-safi>\n        <afi-safi>\n            <afi-safi-name xmlns:x=\"http://openconfig.net/yang/bgp-types\">x:IPV6-UNICAST</afi-safi-name>\n        </afi-safi>\n        <afi-safi>\n            <afi-safi-name>LINKSTATE</afi-safi-name>\n        </afi-safi>\n    </afi-safis>\n</neighbor>\n"
	#print(payload)
	headers = {
		'Content-Type': "application/xml",
		'Cache-Control': "no-cache",
		}

	response = requests.request("PUT", url=url1, data=payload, headers=headers, auth=('admin', 'admin'))

	print(response)

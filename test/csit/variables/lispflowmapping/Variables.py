# Copyright (c) 2015 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html

__author__ = "Lorand Jakab"
__copyright__ = "Copyright(c) 2015, Cisco Systems, Inc."
__license__ = "Eclipse Public License v1.0"
__email__ = "lojakab@cisco.com"


def get_variables():
    add_key = {
        "key": "password",
        "maskLength": 24,
        "address": {
            "ipAddress": "192.0.2.0",
            "afi": 1
        }
    }
    add_mapping = {
        "key": "password",
        "mapregister": {
            "proxyMapReply": True,
            "eidToLocatorRecords": [{
                "authoritative": True,
                "prefixGeneric": {
                    "ipAddress": "192.0.2.0",
                    "afi": 1
                },
                "mapVersion": 0,
                "maskLength": 24,
                "action": "NoAction",
                "locators": [{
                    "multicastPriority": 255,
                    "locatorGeneric": {
                        "ipAddress": "127.0.0.1",
                        "afi": 1
                    },
                    "routed": True,
                    "multicastWeight": 0,
                    "rlocProbed": False,
                    "localLocator": False,
                    "priority": 1,
                    "weight": 1
                }, {
                    "multicastPriority": 255,
                    "locatorGeneric": {
                        "ipAddress": "127.0.0.2",
                        "afi": 1
                    },
                    "routed": True,
                    "multicastWeight": 0,
                    "rlocProbed": False,
                    "localLocator": False,
                    "priority": 2,
                    "weight": 1
                }],
                "recordTtl": 5
            }],
            "keyId": 0
        }
    }
    get_mapping = {
        "recordTtl": 5,
        "maskLength": 24,
        "action": "NoAction",
        "authoritative": True,
        "mapVersion": 0,
        "prefixGeneric": {
            "afi": 1,
            "ipAddress": "192.0.2.0",
            "instanceId": 0,
            "asNum": 0,
            "lcafType": 0,
            "protocol": 0,
            "ipTos": 0,
            "localPort": 0,
            "remotePort": 0,
            "iidMaskLength": 0,
            "srcMaskLength": 0,
            "dstMaskLength": 0,
            "lookup": False,
            "RLOCProbe": False,
            "strict": False
        },
        "locators": [{
            "priority": 1,
            "weight": 1,
            "multicastPriority": 255,
            "multicastWeight": 0,
            "localLocator": False,
            "rlocProbed": False,
            "routed": True,
            "locatorGeneric": {
                "afi": 1,
                "ipAddress": "127.0.0.1",
                "instanceId": 0,
                "asNum": 0,
                "lcafType": 0,
                "protocol": 0,
                "ipTos": 0,
                "localPort": 0,
                "remotePort": 0,
                "iidMaskLength": 0,
                "srcMaskLength": 0,
                "dstMaskLength": 0,
                "lookup": False,
                "RLOCProbe": False,
                "strict": False
            }
        }, {
            "priority": 2,
            "weight": 1,
            "multicastPriority": 255,
            "multicastWeight": 0,
            "localLocator": False,
            "rlocProbed": False,
            "routed": True,
            "locatorGeneric": {
                "afi": 1,
                "ipAddress": "127.0.0.2",
                "instanceId": 0,
                "asNum": 0,
                "lcafType": 0,
                "protocol": 0,
                "ipTos": 0,
                "localPort": 0,
                "remotePort": 0,
                "iidMaskLength": 0,
                "srcMaskLength": 0,
                "dstMaskLength": 0,
                "lookup": False,
                "RLOCProbe": False,
                "strict": False
            }
        }]
    }
    variables = {'add_key': add_key,
                 'add_mapping': add_mapping,
                 'get_mapping': get_mapping}
    return variables

"""Singlethreaded utility for rapid Netconf device connection configuration via topology.

This utility is intended for stress testing netconf topology way
of configuring (and deconfiguring) connectors to netconf devices.

The utility does not stop by itself, ctrl+c is needed to stop activity and print results.
The utility counts responses of different status and text, summary is printed on break.
The utility can still fail early, for example if http connection is refused.

Only config datastore write is performed,
it is never verified whether a connection between ODL and device was even attempted.

To avoid resource starvation, both the number of available devices
and the number of configured devices have to be limited.
Thus this utility also deconfigures connectors added previously when a certain number is achieved.

Note that if ODL ignores some deconfiguration writes, it may end up leaking connections
and eventually run into the resource issues.
TODO: Is there a reasonable way to detect or prevent such a leak?

The set of devices to connect is assumed to have IP addresses the same
and ports in continuous segment (so that single testtool can emulate them all).
Each connector has unique name, devices are assigned in cyclic fashion.
"""

# Copyright (c) 2016 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html

import argparse
import collections
import signal
import string
import sys
import AuthStandalone


__author__ = "Vratko Polak"
__copyright__ = "Copyright(c) 2016, Cisco Systems, Inc."
__license__ = "Eclipse Public License v1.0"
__email__ = "vrpolak@cisco.com"


def str2bool(text):
    """Utility converter, based on http://stackoverflow.com/a/19227287"""
    return text.lower() in ("yes", "true", "y", "t", "1")


def parse_arguments():
    """Return parsed form of command-line arguments."""
    parser = argparse.ArgumentParser()
    parser.add_argument("--odladdress", default="127.0.0.1",
                        help="IP address of ODL Restconf to be used")
    parser.add_argument("--restconfport", default="8181",
                        help="Port on which ODL Restconf to be used")
    parser.add_argument("--restconfuser", default="admin",
                        help="Username for ODL Restconf authentication")
    parser.add_argument("--restconfpassword", default="admin",
                        help="Password for ODL Restconf authentication")
    parser.add_argument("--scope", default="sdn",
                        help="Scope for ODL Restconf authentication")
    parser.add_argument("--deviceaddress", default="127.0.0.1",
                        help="Common IP address for all available devices")
    parser.add_argument("--devices", default="1", type=int,
                        help="Number of devices available for connecting")
    parser.add_argument("--deviceuser", default="admin",
                        help="Username for netconf device authentication")
    parser.add_argument("--devicepassword", default="admin",
                        help="Password for netconf device authentication")
    parser.add_argument("--startport", default="17830", type=int,
                        help="Port number of first device")
    parser.add_argument("--disconndelay", default="0", type=int,
                        help="Deconfigure oldest device if more than this devices were configured")
    parser.add_argument("--basename", default="sim-device",
                        help="Name of device without the generated suffixes")
    parser.add_argument("--reuse", default="True", type=str2bool,
                        help="Should single requests session be re-used")
    return parser.parse_args()  # arguments are read


DATA_TEMPLATE = string.Template('''{
    "network-topology:node": {
        "node-id": "$DEVICE_NAME",
        "host": "$DEVICE_IP",
        "port": $DEVICE_PORT,
        "username": "$DEVICE_USER",
        "password": "$DEVICE_PASSWORD",
        "tcp-only": "false",
        "keepalive-delay": 0
    }
}''')


def count_response(counter, response, metadata):
    """Add counter item built from response data and given metadata."""
    counter_item = metadata + " " + str(response.status_code)
    if response.text:
        counter_item += " " + response.text
    counter[counter_item] += 1


def main():
    """Top-level logic to execute."""
    args = parse_arguments()
    uri_part = "config/network-topology:network-topology/topology/topology-netconf/node/"
    put_headers = {"Content-Type": "application/json", "Accept": "application/json"}
    delete_headers = {"Accept": "application/json"}
    counter = collections.Counter()

    def handle_sigint(received_signal, frame):  # This is a closure as it refers to counter.
        """Upon SIGINT, print counter contents and exit gracefully."""
        signal.signal(signal.SIGINT, signal.SIG_DFL)
        print repr(counter)
        sys.exit(0)

    signal.signal(signal.SIGINT, handle_sigint)
    session = AuthStandalone.Init_Session(args.odladdress, args.restconfuser, args.restconfpassword,
                                          args.scope, args.reuse)
    subst_dict = {}
    subst_dict["DEVICE_IP"] = args.deviceaddress
    subst_dict["DEVICE_USER"] = args.deviceuser
    subst_dict["DEVICE_PASSWORD"] = args.devicepassword
    iteration = 0
    delayed = collections.deque()
    wrap_port = args.startport + args.devices
    while 1:
        iteration += 1
        port = args.startport
        while port < wrap_port:
            if len(delayed) > args.disconndelay:
                delete_name = delayed.popleft()
                response = AuthStandalone.Delete_Using_Session(session, uri_part + delete_name, headers=delete_headers)
                count_response(counter, response, "delete")
            put_name = args.basename + "-" + str(port) + "-" + str(iteration)
            subst_dict["DEVICE_NAME"] = put_name
            subst_dict["DEVICE_PORT"] = str(port)
            put_data = DATA_TEMPLATE.substitute(subst_dict)
            uri = uri_part + put_name
            response = AuthStandalone.Put_Using_Session(session, uri, data=put_data, headers=put_headers)
            count_response(counter, response, "put")
            delayed.append(put_name)  # schedule for deconfiguration unconditionally
            port += 1


if __name__ == "__main__":
    main()

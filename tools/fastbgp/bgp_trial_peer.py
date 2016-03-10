"""This program performs required BGP application peer operations."""

# Copyright (c) 2015 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html

import argparse
import ipaddr
import logging
import requests
import string
import time


__author__ = "Radovan Sajben"
__copyright__ = "Copyright(c) 2015, Cisco Systems, Inc."
__license__ = "Eclipse Public License v1.0"
__email__ = "rsajben@cisco.com"


add_data_template = '''<input xmlns="urn:opendaylight:params:xml:ns:yang:bgptrial">
<prefix>$ADDR/$LEN</prefix>
<count>$COUNT</count>
<batchsize>$BATCH</batchsize>
<nexthop>$HOP</nexthop>
</input>
'''


delete_data_template = '''<input xmlns="urn:opendaylight:params:xml:ns:yang:bgptrial">
<prefix>$ADDR/$LEN</prefix>
<count>$COUNT</count>
<batchsize>$BATCH</batchsize>
</input>
'''


def _build_url(odl_ip, port, uri):
    """Compose URL from generic IP, port and URI fragment.

    Args:
        :param odl_ip: controller's ip address or hostname

        :param port: controller's restconf port

        :param uri: URI without /restconf/ to complete URL

    Returns:
        :returns url: full restconf url corresponding to params
    """

    url = "http://" + str(odl_ip) + ":" + port + "/restconf/" + uri
    return url


def send_request(operation, odl_ip, port, uri, auth, xml_data=None, expect_status_code=200):
    """Send a http request.

    Args:
        :operation: GET, POST, PUT, DELETE

        :param odl_ip: controller's ip address or hostname

        :param port: controller's restconf port

        :param uri: URI without /restconf/ to complete URL

        :param auth: authentication credentials

        :param xml_data: list of routes as xml data

    Returns:
        :returns http response object
    """
    global total_response_time_counter
    global total_number_of_responses_counter

    ses = requests.Session()

    url = _build_url(odl_ip, port, uri)
    header = {"Content-Type": "application/xml"}
    req = requests.Request(operation, url, headers=header, data=xml_data, auth=auth)
    prep = req.prepare()
    try:
        send_request_timestamp = time.time()
        rsp = ses.send(prep, timeout=60)
        total_response_time_counter += time.time() - send_request_timestamp
        total_number_of_responses_counter += 1
    except requests.exceptions.Timeout:
        logger.error("No response from %s", odl_ip)
    else:
        if rsp.status_code == expect_status_code:
            logger.debug("%s %s", rsp.request, rsp.request.url)
            logger.debug("Request headers: %s:", rsp.request.headers)
            logger.debug("Response: %s", rsp.text)
            logger.debug("%s %s", rsp, rsp.reason)
        else:
            logger.error("%s %s", rsp.request, rsp.request.url)
            logger.error("Request headers: %s:", rsp.request.headers)
            logger.error("Response: %s", rsp.text)
            logger.error("%s %s", rsp, rsp.reason)
        return rsp


def delete_prefixes(odl_ip, port, auth, prefix_base, prefix_len, count, batchsize):
    """POST RPC for BGP trial to add prefixes

    Args:
        :param odl_ip: controller's ip address or hostname

        :param port: controller's restconf port

        :param auth: authentication tupple as (user, password)

        :param prefix_base: IP address of the first prefix

        :prefix_len: length of the prefix in bites (specifies the increment as well)

        :param count: number of prefixes to be processed

        :param batchsize: number of prefixes per transaction

    Returns:
        :returns None
    """
    logger.info("Delete %s in batches of %s prefixes (starting from %s/%s) into %s:%s",
                count, batchsize, prefix_base, prefix_len, odl_ip, port)
    uri_add = "operations/bgptrial:delete-prefix"
    data_dict = {
        "ADDR": prefix_base,
        "LEN": prefix_len,
        "COUNT": count,
        "BATCH": batchsize,
    }
    data = string.Template(delete_data_template).substitute(data_dict)
    send_request("POST", odl_ip, port, uri_add, auth, xml_data=data, expect_status_code=204)


def add_prefixes(odl_ip, port, auth, prefix_base, prefix_len, nexthop, count, batchsize):
    """POST RPC for BGP trial to add prefixes

    Args:
        :param odl_ip: controller's ip address or hostname

        :param port: controller's restconf port

        :param auth: authentication tupple as (user, password)

        :param prefix_base: IP address of the first prefix

        :prefix_len: length of the prefix in bites (specifies the increment as well)

        :nexthop: IPv4 address to use as next hop

        :param count: number of prefixes to be processed

        :param batchsize: number of prefixes per transaction

    Returns:
        :returns None
    """
    logger.info("Add %s in batches of %s prefixes (starting from %s/%s) with nexthop %s into %s:%s",
                count, batchsize, prefix_base, prefix_len, nexthop, odl_ip, port)
    uri_add = "operations/bgptrial:add-prefix"
    data_dict = {
        "ADDR": prefix_base,
        "LEN": prefix_len,
        "COUNT": count,
        "BATCH": batchsize,
        "HOP": nexthop
    }
    data = string.Template(add_data_template).substitute(data_dict)
    send_request("POST", odl_ip, port, uri_add, auth, xml_data=data, expect_status_code=204)


_commands = ["add", "delete"]

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="BGP application peer script")
    parser.add_argument("--host", type=ipaddr.IPv4Address, default="127.0.0.1",
                        help="ODL controller IP address")
    parser.add_argument("--port", default="8181",
                        help="ODL RESTCONF port")
    parser.add_argument("--command", choices=_commands, metavar="command",
                        help="Command to be performed."
                        "add, delete")
    parser.add_argument("--prefix", type=ipaddr.IPv4Address, default="8.0.1.0",
                        help="First prefix IP address")
    parser.add_argument("--prefixlen", type=int, help="Prefix length in bites",
                        default=28)
    parser.add_argument("--nexthop", type=ipaddr.IPv4Address, default="1.2.3.4",
                        help="IPv4 address of next hop to use")
    parser.add_argument("--count", type=int, help="Number of prefixes",
                        default=1)
    parser.add_argument("--batchsize", type=int, help="Number of prefixes per one transaction",
                        default=1)
    parser.add_argument("--user", help="Restconf user name", default="admin")
    parser.add_argument("--password", help="Restconf password", default="admin")
    parser.add_argument("--error", dest="loglevel", action="store_const",
                        const=logging.ERROR, default=logging.INFO,
                        help="Set log level to error (default is info)")
    parser.add_argument("--warning", dest="loglevel", action="store_const",
                        const=logging.WARNING, default=logging.INFO,
                        help="Set log level to warning (default is info)")
    parser.add_argument("--info", dest="loglevel", action="store_const",
                        const=logging.INFO, default=logging.INFO,
                        help="Set log level to info (default is info)")
    parser.add_argument("--debug", dest="loglevel", action="store_const",
                        const=logging.DEBUG, default=logging.INFO,
                        help="Set log level to debug (default is info)")
    parser.add_argument("--logfile", default="bgp_app_peer.log", help="Log file name")

    args = parser.parse_args()

    logger = logging.getLogger("logger")
    log_formatter = logging.Formatter("%(asctime)s %(levelname)s: %(message)s")
    console_handler = logging.StreamHandler()
    file_handler = logging.FileHandler(args.logfile, mode="w")
    console_handler.setFormatter(log_formatter)
    file_handler.setFormatter(log_formatter)
    logger.addHandler(console_handler)
    logger.addHandler(file_handler)
    logger.setLevel(args.loglevel)

    odl_ip = args.host
    port = args.port
    command = args.command
    prefix_base = args.prefix
    prefix_len = args.prefixlen
    nexthop = args.nexthop
    count = args.count
    batchsize = args.batchsize
    auth = (args.user, args.password)

    test_start_time = time.time()
    total_build_data_time_counter = 0
    total_response_time_counter = 0
    total_number_of_responses_counter = 0

    if command == "add":
        add_prefixes(odl_ip, port, auth, prefix_base, prefix_len, nexthop, count, batchsize)
    elif command == "delete":
        delete_prefixes(odl_ip, port, auth, prefix_base, prefix_len, nexthop, count, batchsize)

    total_test_execution_time = time.time() - test_start_time

    logger.info("Total test execution time: %.3fs", total_test_execution_time)
    logger.info("Total build data time: %.3fs", total_build_data_time_counter)
    logger.info("Total response time: %.3fs", total_response_time_counter)
    logger.info("Total number of response(s): %s", total_number_of_responses_counter)
    file_handler.close()

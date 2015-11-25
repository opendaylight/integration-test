"""This program performs required BGP application peer operations."""

# Copyright (c) 2015 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html

__author__ = "Radovan Sajben"
__copyright__ = "Copyright(c) 2015, Cisco Systems, Inc."
__license__ = "Eclipse Public License v1.0"
__email__ = "rsajben@cisco.com"

import requests
import ipaddr
import argparse
import logging
import xml.dom.minidom as md


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


def _build_data(xml_template, prefix_base, prefix_len, count):
    """Generate list of routes based on xml templates.

    Args:
        :xml_template: xml template for routes

        :prefix_base: first prefix IP address

        :prefix_len: prefix length in bits

        :count: number of routes to be generated

    Returns:
        :returns xml_data: list of routes in as xml data
    """

    routes = md.parse(xml_template)

    routes_node = routes.getElementsByTagName("ipv4-routes")[0]
    route_node = routes.getElementsByTagName("ipv4-route")[0]
    routes_node.removeChild(route_node)
    if count:
        prefix_gap = 2 ** (32 - prefix_len)

    for prefix_index in range(count):
        new_route_node = route_node.cloneNode(True)
        new_route_prefix = new_route_node.getElementsByTagName("prefix")[0]

        prefix = prefix_base + prefix_index * prefix_gap
        new_route_prefix.childNodes[0].nodeValue = str(prefix) + "/" + str(prefix_len)

        routes_node.appendChild(new_route_node)

    xml_data = routes_node.toxml()
    routes.unlink()
    logger.debug("xml data generated:\n%s", xml_data)
    return xml_data


def send_request(operation, odl_ip, port, uri, auth, xml_data=None):
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

    ses = requests.Session()

    url = _build_url(odl_ip, port, uri)
    header = {"Content-Type": "application/xml"}
    req = requests.Request(operation, url, headers=header, data=xml_data, auth=auth)
    prep = req.prepare()
    try:
        rsp = ses.send(prep, timeout=60)
    except requests.exceptions.Timeout:
        logger.error("No response from %s", odl_ip)
    else:
        logger.debug("%s %s", rsp.request, rsp.request.url)
        logger.debug("Request headers: %s:", rsp.request.headers)
        logger.debug("Request body: %s", rsp.request.body)
        logger.debug("Response: %s", rsp.text)
        logger.info("%s %s", rsp, rsp.reason)
    return rsp


def get_prefixes(odl_ip, port, uri, auth, prefix_base=None, prefix_len=None,
                 count=None, xml_template=None):
    """Send a http GET request for getting prefixes.

    Args:
        :param odl_ip: controller's ip address or hostname

        :param port: controller's restconf port

        :param uri: URI without /restconf/ to complete URL

        :param auth: authentication tupple as (user, password)

        :param prefix_base: IP address of the first prefix

        :prefix_len: length of the prefix in bites (specifies the increment as well)

        :param count: number of prefixes to be processed

        :param xml_template: xml template for building the xml data

    Returns:
        :returns None
    """

    logger.info("Get prefixes from %s:%s/restconf/%s", odl_ip, port, uri)
    rsp = send_request("GET", odl_ip, port, uri, auth)
    if rsp is not None:
        s = rsp.text
        s = s.replace("{", "")
        s = s.replace("}", "")
        s = s.replace("[", "")
        s = s.replace("]", "")
        prefixes = ''
        prefix_count = 0
        for item in s.split(","):
            if "prefix" in item:
                prefixes += item + ","
                prefix_count += 1
        prefixes = prefixes[:len(prefixes)-1]
        logger.debug("prefix_list=%s", prefixes)
        logger.info("prefix_count=%s", prefix_count)


def post_prefixes(odl_ip, port, uri, auth, prefix_base=None, prefix_len=None,
                  count=0, xml_template=None, batch_size=1):
    """Send a http POST request for creating a new prefix list.

    Args:
        :param odl_ip: controller's ip address or hostname

        :param port: controller's restconf port

        :param uri: URI without /restconf/ to complete URL

        :param auth: authentication tupple as (user, password)

        :param prefix_base: IP address of the first prefix

        :prefix_len: length of the prefix in bites (specifies the increment as well)

        :param count: number of prefixes to be processed

        :param xml_template: xml template for building the xml data (not used)

        :batch_size: number of prefixes processed in one request (not used)

    Returns:
        :returns None
    """
    logger.info("Create %s prefixes (starting from %s/%s) into %s:%s/restconf/%s",
                count, prefix_base, prefix_len, odl_ip, port, uri)
    xml_data = _build_data(xml_template, prefix_base, prefix_len, count)
    send_request("POST", odl_ip, port, uri, auth, xml_data)


def put_prefixes(odl_ip, port, uri, auth, prefix_base, prefix_len, count,
                 xml_template=None, batch_size=None):
    """Send a http PUT request for updating / adding prefixes.

    Args:
        :param odl_ip: controller's ip address or hostname

        :param port: controller's restconf port

        :param uri: URI without /restconf/ to complete URL

        :param auth: authentication tupple as (user, password)

        :param prefix_base: IP address of the first prefix

        :prefix_len: length of the prefix in bites (specifies the increment as well)

        :param count: number of prefixes to be processed

        :param xml_template: xml template for building the xml data (not used)

        :batch_size: number of prefixes processed in one request

    Returns:
        :returns None
    """
    if batch_size is None:
        batch_size = count
    for batch in range((count - 1) / batch_size + 1):
        actual_count = min(batch_size, count - batch * batch_size)
        prefix_gap = 2 ** (32 - prefix_len)
        prefix = prefix_base + batch * batch_size * prefix_gap
        logger.info("Add %s prefixes (starting from %s/%s) to %s:%s/restconf/%s",
                    actual_count, prefix, prefix_len, odl_ip, port, uri)
        uri_add_prefix = uri + _uri_suffix_ipv4_routes
        xml_data = _build_data(xml_template, prefix, prefix_len, actual_count)
        send_request("PUT", odl_ip, port, uri_add_prefix, auth, xml_data)


def delete_prefixes(odl_ip, port, uri, auth, prefix_base, prefix_len, count,
                    xml_template=None, batch_size=1):
    """Send a http DELETE requests for deleting prefixes.

    Args:
        :param odl_ip: controller's ip address or hostname

        :param port: controller's restconf port

        :param uri: URI without /restconf/ to complete URL

        :param auth: authentication tupple as (user, password)

        :param prefix_base: IP address of the first prefix

        :prefix_len: length of the prefix in bites (specifies the increment as well)

        :param count: number of prefixes to be processed

        :param xml_template: xml template for building the xml data (not used)

        :batch_size: number of prefixes processed in one request (not used)

    Returns:
        :returns None
    """
    logger.info("Delete %s prefixes (starting from %s/%s) from %s:%s/restconf/%s",
                count, prefix_base, prefix_len, odl_ip, port, uri)
    uri_del_prefix = uri + _uri_suffix_ipv4_routes + _uri_suffix_ipv4_route
    prefix_gap = 2 ** (32 - prefix_len)
    for prefix_index in range(count):
        prefix = str(prefix_base + prefix_index * prefix_gap) + "%2F" + str(prefix_len)
        send_request("DELETE", odl_ip, port, uri_del_prefix + prefix, auth)


def delete_all_prefixes(odl_ip, port, uri, auth, prefix_base=None,
                        prefix_len=None, count=None, xml_template=None,
                        batch_size=None):
    """Send a http DELETE request for deleting all prefixes.

    Args:
        :param odl_ip: controller's ip address or hostname

        :param port: controller's restconf port

        :param uri: URI without /restconf/ to complete URL

        :param auth: authentication tupple as (user, password)

        :param prefix_base: IP address of the first prefix (not used)

        :prefix_len: length of the prefix in bites (not used)

        :param count: number of prefixes to be processed (not used)

        :param xml_template: xml template for building the xml data (not used)

        :batch_size: number of prefixes processed in one request (not used)

    Returns:
        :returns None
    """
    logger.info("Delete all prefixes from %s:%s/restconf/%s", odl_ip, port, uri)
    uri_del_all_prefixes = uri + _uri_suffix_ipv4_routes
    send_request("DELETE", odl_ip, port, uri_del_all_prefixes, auth)


_commands = ["post", "put", "delete", "delete-all", "get"]
_uri_suffix_ipv4_routes = "bgp-inet:ipv4-routes/"
_uri_suffix_ipv4_route = "bgp-inet:ipv4-route/"   # followed by IP address like 1.1.1.1%2F32

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="BGP application peer script")
    parser.add_argument("--host", type=ipaddr.IPv4Address, default="127.0.0.1",
                        help="ODL controller IP address")
    parser.add_argument("--port", default="8181",
                        help="ODL RESTCONF port")
    parser.add_argument("--command", choices=_commands, metavar="command",
                        help="Command to be performed.")
    parser.add_argument("--prefix", type=ipaddr.IPv4Address, default="8.0.1.0",
                        help="First prefix IP address")
    parser.add_argument("--prefixlen", type=int, help="Prefix length in bites",
                        default=28)
    parser.add_argument("--count", type=int, help="Number of prefixes",
                        default=1)
    parser.add_argument("--batch", type=int, help="Number of prefixes in a single request",
                        default=10000)
    parser.add_argument("--user", help="Restconf user name", default="admin")
    parser.add_argument("--password", help="Restconf password", default="admin")
    parser.add_argument("--uri", help="The uri part of requests",
                        default="config/bgp-rib:application-rib/example-app-rib/"
                                "tables/bgp-types:ipv4-address-family/"
                                "bgp-types:unicast-subsequent-address-family/")
    parser.add_argument("--xml", help="File name of the xml data template",
                        default="ipv4-routes-template.xml")
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

    auth = (args.user, args.password)

    odl_ip = args.host
    port = args.port
    command = args.command
    prefix_base = args.prefix
    prefix_len = args.prefixlen
    count = args.count
    batch_size = args.batch
    auth = (args.user, args.password)
    uri = args.uri
    xml_template = args.xml

    if command == "post":
        post_prefixes(odl_ip, port, uri, auth, prefix_base, prefix_len, count,
                      xml_template, batch_size)
    if command == "put":
        put_prefixes(odl_ip, port, uri, auth, prefix_base, prefix_len, count,
                     xml_template, batch_size)
    elif command == "delete":
        delete_prefixes(odl_ip, port, uri, auth, prefix_base, prefix_len, count)
    elif command == "delete-all":
        delete_all_prefixes(odl_ip, port, uri, auth)
    elif command == "get":
        get_prefixes(odl_ip, port, uri, auth)

    logger.info("Done")
    file_handler.close()

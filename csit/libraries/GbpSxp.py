import isodate
from robot.api import logger
from robot.errors import ExecutionFailed
import json


def check_iso8601_datetime_younger_then_limit(status_timestamp_raw, limit):
    """
    Compare timestamp of given status to given limit, raise exception if status is older or equal to limit

    :param status_timestamp_raw: json from DS/operational (ise-source status)
    :param limit: datetime value - status must be younger than this
    """

    logger.debug("limit:{0}".format(limit))

    timestamp_raw = status_timestamp_raw
    # 2016-11-23T13:25:00.733+01:00
    status_tstamp = isodate.parse_datetime(timestamp_raw)
    limit_tstamp = isodate.parse_datetime(limit)
    limit_tstamp = limit_tstamp.replace(tzinfo=status_tstamp.tzinfo)

    if status_tstamp <= limit_tstamp:
        logger.info("status stamp --> {0}".format(status_tstamp))
        logger.info("limit        --> {0}".format(limit_tstamp))
        raise ExecutionFailed(
            "received status is not up-to-date: {0}".format(status_tstamp)
        )


def replace_ise_source_address(ise_source_json, new_target):
    """
    Replace ise server url with given target

    :param ise_source_json: ise source configuration as json
    :param new_target: current ise server url
    """
    ise_source_json["ise-source-config"]["connection-config"][
        "ise-rest-url"
    ] = new_target


def remove_endpoint_timestamp(endpoint_json):
    """
    Remove timestamp from given endpoint node and return plain text (for simple comparison)
    :param endpoint_json: endpoint node from DS/operational
    :return: plain text without timestamp
    """
    try:
        for address_endpoint in endpoint_json["endpoints"]["address-endpoints"][
            "address-endpoint"
        ]:
            del address_endpoint["timestamp"]
    except KeyError:
        msg = "No endpoint present - can not wipe timestamp"
        logger.debug(msg)
        raise ExecutionFailed(msg)

    return json.dumps(endpoint_json)


def resolve_sxp_node_is_enabled(sxp_node_json):
    """
    Try to get value of leaf enabled
    :param sxp_node_json: sxp node operational state
    :return: enabled value
    """
    enabled = None
    try:
        for node in sxp_node_json["node"]:
            enabled = node["sxp-node:enabled"]
    except KeyError:
        msg = "No sxp node content present - can not read value of enabled"
        logger.debug(msg)
        raise ExecutionFailed(msg)

    return enabled


def replace_netconf_node_host(netconf_node_json, node_name, host_value):
    """
    Replace host value in netconf node configuration
    :param netconf_node_json: netconf node configuration
    :param node_name:  required node-name value
    :param host_value: required host value
    :return: plain text with replaced host value
    """
    try:
        for node in netconf_node_json["node"]:
            node["netconf-node-topology:host"] = host_value
            node["node-id"] = node_name
    except KeyError:
        msg = "No host found in given netconf node config"
        logger.debug(msg)
        raise ExecutionFailed(msg)

    return json.dumps(netconf_node_json)


def replace_ip_mgmt_address_in_forwarder(sf_forwarders_json, ip_mgmt_map):
    """
    Find and replace ip-mgmt-address values for corresponding forwarders names
    :param sf_forwarders_json: sfc forwarders json
    :param ip_mgmt_map: key=forwarder-name, value=ip-mgmt-address
    :return: plain sfc forwarders with replaced ip-mgmt-addresses
    """
    try:
        for sff in sf_forwarders_json["service-function-forwarders"][
            "service-function-forwarder"
        ]:
            sff_name = sff["name"]
            if sff_name in ip_mgmt_map:
                sff["ip-mgmt-address"] = ip_mgmt_map[sff_name]

    except KeyError:
        msg = "Expected sff not found in given config"
        logger.debug(msg)
        raise ExecutionFailed(msg)

    return json.dumps(sf_forwarders_json)


def replace_renderer_policy_version(renderer_policy_json, next_version):
    """
    Find and replace version of given renderer-policy json
    :param renderer_policy_json:    renderer policy
    :param next_version:    version to be written into given policy
    :return: plain renderer policy with replaced version
    """
    try:
        renderer_policy_json["renderer-policy"]["version"] = next_version
    except KeyError:
        msg = "Expected version element not found in given renderer-policy"
        logger.debug(msg)
        raise ExecutionFailed(msg)

    return json.dumps(renderer_policy_json)

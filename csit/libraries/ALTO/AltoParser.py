"""
Library for ALTO project robot system test framework.
Author: linxiao9292@outlook.com
"""

import json
import re

content_key_set = {"meta", "resources"}
resource_key_set = {"uri", "media-type", "accepts", "capabilities", "uses"}
cost_type_key_set = {"cost-mode", "cost-metric", "description"}
media_type_set = {"application/alto-directory+json",
                  "application/alto-networkmap+json",
                  "application/alto-networkmapfilter+json",
                  "application/alto-costmap+json",
                  "application/alto-costmapfilter+json",
                  "application/alto-endpointprop+json",
                  "application/alto-endpointpropparams+json",
                  "application/alto-endpointcost+json",
                  "application/alto-endpointcostparams+json",
                  "application/alto-error+json"
                  }


def get_basic_info(response):
    """Get basic information of the simple IRD.

    Args:
        :param response: response from restconf/operational/alto-simple-ird:information
            contains context-id and base-url for alto-simple-ird.
    Returns:
        :returns tuple: context-id - Identifier of different implementations of one service.
            The formation of it is xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
            For example, we have three implementations of IRD service, and we could use
            different context-id to identify them.

                        base-url - ALTO northbound URL of simple IRD.
    """
    resp = json.loads(response)
    return resp["information"]["context-id"], resp["information"]["base-url"]


def check_ird_configuration_entry(response, ird_resource_id, context_id, resource_id):
    """Check whether resources we added are in the resource pool.

    Args:
        :param response: response from restconf/operational/alto-resourcepool:context/context-id
            context-id is from get_basic_info(response).

        :param ird_resource_id: ID of the IRD.

        :param context_id: See above.

        :param resource_id: ID of the resource.
            context-id and resource-id together could determine one implementation of one service.
    Returns:
        :return bool: False if we do not get the resource we added before
    """
    resp = json.loads(response)
    resources = resp["context"][0]["resource"]
    for resource in resources:
        if resource["resource-id"] == ird_resource_id:
            context_tags = resource["context-tag"]
            for tag in context_tags:
                if "dependency" in tag:
                    for one_dependency in tag["dependency"]:
                        _context_id = re.findall("\d{8}-\d{4}-\d{4}-\d{4}-\d{12}", one_dependency)[0]
                        if _context_id == context_id:
                            long_resource_id = re.findall("resource-id='[a-zA-Z\-]*'", one_dependency)[0]
                            short_resource_id = re.findall("'.*'", long_resource_id)[0]
                            _resource_id = short_resource_id.replace("'", "")
                            if _resource_id == resource_id:
                                return True
    return False


def verify_ird(response):
    """Semantic check of IRD response, more information in RFC 7285 9.2.

    Args:
        :param response: response from ALTO northbound URL of IRD.
    Returns:
        :return: bool: False if there are some semantic errors.
            One semantic error is that we only define routing-cost in cost-type, but we find that one capability of a
            resource is bandwidth.
    """
    if response.headers["content-type"] != "application/alto-directory+json":
        return False
    try:
        resp = json.loads(response.content)
    except ValueError:
        return False
    if "meta" not in resp:
        return False
    meta = resp["meta"]
    if "cost-types" in meta:
        cost_types = meta["cost-types"]
        for cost_type in cost_types:
            if set(cost_type).issubset(cost_type_key_set):
                if "cost-mode" in cost_type and "cost-metric" in cost_type:
                    continue
                else:
                    return False
            else:
                return False

    resources = resp["resources"]
    for resource in resources.keys():
        if set(resources[resource].keys()).issubset(resource_key_set):
            if "uri" not in resources[resource] or "media-type" not in resources[resource]:
                return False
            else:
                _resource = resources[resource]
                media_type = _resource["media-type"]
                if media_type not in media_type_set:
                    return False
                if "capabilities" in _resource:
                    capabilities = _resource["capabilities"]
                    if "cost-type-names" in capabilities:
                        cost_type_names = capabilities["cost-type-names"]
                        for cost_type_name in cost_type_names:
                            if cost_type_name not in cost_types:
                                return False
        else:
            return False
    return True

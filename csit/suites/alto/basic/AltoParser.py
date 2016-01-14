"""
Library for ALTO project
Author: linxiao9292@outlook.com
"""

import json
import re

content_key = {"meta", "resources"}
resource_key = {"uri", "media-type", "accepts", "capabilities", "uses"}
cost_type_key = {"cost-mode", "cost-metric", "description"}
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
def get_context_id_and_base_url_in_IRD_information(response):
    r = json.loads(response)
    return (r["information"]["context-id"], r["information"]["base-url"])


def check_ird_configuration_entry(response, my_ird_resource_id, my_context_id, my_resource_id):
    r = json.loads(response)
    resources = r["context"][0]["resource"]
    for resource in resources:
        if resource["resource-id"] == my_ird_resource_id:
            context_tags = resource["context-tag"]
            for tag in context_tags:
                if "dependency" in tag:
                    for one_dependency in tag["dependency"]:
                        context_id = re.findall("\d{8}-\d{4}-\d{4}-\d{4}-\d{12}", one_dependency)[0]
                        if context_id == my_context_id:
                            long_resource_id = re.findall("resource-id='[a-zA-Z\-]*'", one_dependency)[0]
                            short_resource_id = re.findall("'.*'", long_resource_id)[0]
                            resource_id = short_resource_id.replace("'", "")
                            if resource_id == my_resource_id:
                                return True
    return False

def verify_ird(response):
    if response.headers["content-type"] != "application/alto-directory+json":
        return False
    try:
        r = json.loads(response.content)
    except ValueError:
        return False
    if "meta" not in r:
        return False
    meta = r["meta"]
    if "cost-types" in meta:
        cost_types = meta["cost-types"]
        for cost_type in cost_types:
            cost_type = cost_types[cost_type]
            if set(cost_type).issubset(cost_type_key):
                if "cost-mode" in cost_type and "cost-metric" in cost_type:
                    continue
                else:
                    return False
            else:
                return False

    resources = r["resources"]
    for resource in resources.keys():
        if set(resources[resource].keys()).issubset(resource_key):
            if "uri" not in resources[resource] or "media-type" not in resources[resource]:
                return False
            else:
                my_resource = resources[resource]
                media_type = my_resource["media-type"]
                if media_type not in media_type_set:
                    return False
                if "capabilities" in my_resource:
                    capabilities = my_resource["capabilities"]
                    if "cost-type-names" in capabilities:
                        cost_type_names = capabilities["cost-type-names"]
                        for cost_type_name in cost_type_names:
                            if cost_type_name not in cost_types:
                                return False
        else:
            return False
    return True

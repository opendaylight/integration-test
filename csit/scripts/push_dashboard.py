#!/usr/bin/python
# -*- coding: utf-8 -*-

# @License EPL-1.0 <http://spdx.org/licenses/EPL-1.0>
##############################################################################
# Copyright (c) 2017 Raghuram Vadapalli, Jaspreet Singh and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

"""
This script is used to parse dashboard config files, construct
JSON BODY and push it to ELK DB.

Usage: python push_dashboard.py host:port

"""

# stdlib
import json
import os
import sys
import glob

# 3rd party lib
from elasticsearch import Elasticsearch, RequestsHttpConnection, exceptions
import yaml

# User defined libs
import generate_visState as vis_gen
import generate_uiStateJSON as uiStateJSON_gen
import generate_dashVis as dash_gen
import generate_searchSourceJSON as searchSourceJSON_gen
import data_generate as data_gen


def p(x):
    print(json.dumps(x, indent=6, sort_keys=True))


# ELK DB host and port to be passed as ':' separated argument
if len(sys.argv) > 1:
    if ":" in sys.argv[1]:
        ELK_DB_HOST = sys.argv[1].split(":")[0]
        ELK_DB_PORT = sys.argv[1].split(":")[1]
else:
    print("Usage: python push_to_elk.py host:port")
    print("Unable to publish data to ELK. Exiting.")
    sys.exit()

try:
    es = Elasticsearch(
        hosts=[{"host": ELK_DB_HOST, "port": int(ELK_DB_PORT)}],
        scheme="https",
        connection_class=RequestsHttpConnection,
    )
except Exception as e:
    print("Unexpected Error Occurred. Exiting")
    print(e)
# print(es.info())


# sys.exit()
# Function to convert JSON object to string.
# Python puts 'true' as 'True' etc. which need handling.


def JSONToString(jobj):
    retval = str(jobj)
    retval = retval.replace("'", '"')
    retval = retval.replace(": ", ":")
    retval = retval.replace(", ", ",")
    retval = retval.replace("True", "true")
    retval = retval.replace("False", "false")
    retval = retval.replace("None", "null")
    return retval


# Clear .kibana index before pushing visualizations
try:
    index = ".kibana"
    res = es.indices.delete(index=index)
except Exception as e:
    print(e)
    # raise e
    print("Unable to push data to ElasticSearch")


# Create and push index-pattern to be used by visualizations

TEST_DATA_INDEX = "opendaylight-test"

INDEX_PATTERN_BODY = {
    "type": "index-pattern",
    "index-pattern": {"timeFieldName": "@timestamp", "title": TEST_DATA_INDEX},
}


KIBANA_CONFIG = {
    "config": {
        "defaultIndex": "pattern-for-{}".format(TEST_DATA_INDEX),
        "timepicker:timeDefaults": '{\n  "from": "now-5y",\n \
                                "to": "now",\n  "mode": "quick"\n}',
        "xPackMonitoring:showBanner": False,
    },
    "type": "config",
}

res = es.index(index=".kibana", doc_type="doc", id="config:6.2.4", body=KIBANA_CONFIG)


try:
    index = ".kibana"
    ES_ID = "index-pattern:pattern-for-{}".format(TEST_DATA_INDEX)
    res = es.index(index=index, doc_type="doc", id=ES_ID, body=INDEX_PATTERN_BODY)
    p(json.dumps(INDEX_PATTERN_BODY, indent=4))
    print(json.dumps(res, indent=4))
except Exception as e:
    print(e)
    # raise e
    print("Unable to push data to ElasticSearch")

try:
    viz_config_path = glob.glob("**/dashboard/viz_config.yaml")[0]
except IndexError:
    print("Visualization template file not found!")
    sys.exit()

try:
    dash_config_path = glob.glob("**/dashboard/dash_config.yaml")[0]
except IndexError:
    print("Dashboard configuration file not found!")
    sys.exit()

with open(dash_config_path, "r") as f:
    dash_config = yaml.safe_load(f)

with open(viz_config_path, "r") as f:
    viz_config = yaml.safe_load(f)


# Create and push visualizations
for dashboard_id, dashboard_content in dash_config.items():

    for _, i in dash_config[dashboard_id]["viz"].items():
        intermediate_format, visState = vis_gen.generate(
            i, viz_config[i["viz-template"]]
        )

        searchSourceJSON = searchSourceJSON_gen.generate(
            i, viz_config[i["viz-template"]], intermediate_format["index_pattern"]
        )

        uiStateJSON = uiStateJSON_gen.generate(i, viz_config[i["viz-template"]])

        # p(intermediate_format)
        # p(visState)

        # Template for visualization template
        VIZ_BODY = {
            "type": "visualization",
            "visualization": {
                "title": None,
                "visState": None,
                "uiStateJSON": "{}",
                "description": None,
                "version": 1,
                "kibanaSavedObjectMeta": {"searchSourceJSON": None},
            },
        }

        VIZ_BODY["visualization"]["title"] = intermediate_format["title"]
        VIZ_BODY["visualization"]["visState"] = JSONToString(visState)
        VIZ_BODY["visualization"]["uiStateJSON"] = JSONToString(uiStateJSON)
        VIZ_BODY["visualization"]["description"] = intermediate_format["desc"]
        VIZ_BODY["visualization"]["kibanaSavedObjectMeta"][
            "searchSourceJSON"
        ] = JSONToString(searchSourceJSON)

        p(VIZ_BODY)
        # Pushing visualization to Kibana
        index = ".kibana"
        ES_ID = "visualization:{}".format(i["id"])
        res = es.index(index=index, doc_type="doc", id=ES_ID, body=VIZ_BODY)
        print(json.dumps(res, indent=4))

    # Create and push dashboards

    # Template for dashboard body in Kibana
    DASH_BODY = {
        "type": "dashboard",
        "dashboard": {
            "title": None,
            "description": None,
            "panelsJSON": None,
            "optionsJSON": '{"darkTheme":false,\
                            "hidePanelTitles":false,"useMargins":true}',
            "version": 1,
            "kibanaSavedObjectMeta": {
                "searchSourceJSON": '{"query":{"language":"lucene", \
                                     "query":""}, \
                                     "filter":[],"highlightAll" \
                                      :true,"version":true}'
            },
        },
    }

    DASH_BODY["dashboard"]["title"] = dashboard_content["title"]
    DASH_BODY["dashboard"]["description"] = dashboard_content["desc"]
    DASH_BODY["dashboard"]["panelsJSON"] = JSONToString(
        dash_gen.generate(dashboard_content["viz"])
    )

    p(DASH_BODY)
    # Pushing dashboard to kibana
    index = ".kibana"
    ES_ID = "dashboard:{}".format(dashboard_content["id"])
    res = es.index(index=index, doc_type="doc", id=ES_ID, body=DASH_BODY)
    print(json.dumps(res, indent=4))

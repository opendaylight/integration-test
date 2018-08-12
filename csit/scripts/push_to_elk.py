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
This script is used to parse logs, construct JSON BODY and push
it to ELK DB.

Usage: python construct_json.py host:port

JSON body similar to following is \
constructed from robot files, jenkins environment
and plot files available in workspace available post-build.
{
    "project": "opendaylight", <- fix string for ODL project
    "subject": "test", <- fix string for ODL test
    "test-type": "performance", <- if there are csv files, \
                                     otherwise "functional"
    "jenkins-silo": "releng" <- from Jenkins $SILO
    "test-name": "openflowplugin-csit-1node-periodic \
                -bulkomatic-perf-daily-only-carbon", <- from Jenkins $JOB_NAME
    "test-run": 289, <- from Jenkins $BUILD_NUMBER
    "start-time": "20170612 16:50:04 GMT-07:00",  <- from robot log
    "duration": "00:01:05.942", <- from robot log
    "pass-tests": 9, <- from robot log
    "fail-tests": 0, <- from robot log
    "plots": {
        "rate": { <- csv filename
            "Config DS": 5816.99726601, <- from csv file
            "OVS Switch": 5757.05238918, <- from csv file
            "Operational DS": 2654.49139945 <- from csv file
        },
        "time": { <- csv filename
            "Config DS": 17.191, <- from csv file
            "OVS Switch": 17.37, <- from csv file
            "Operational DS": 37.672 <- from csv file
        }
    }
}
"""

# stdlib
import json
import os
import sys


# 3rd party lib
from elasticsearch import Elasticsearch, RequestsHttpConnection, exceptions
import yaml

# User defined libs
import generate_visState as vis_gen
import generate_dashVis as dash_gen
import data_generate as data_gen


def p(x):
    print(json.dumps(x, indent=6, sort_keys=True))
# ELK DB host and port to be passed as ':' separated argument


if len(sys.argv) > 1:
    if ':' in sys.argv[1]:
        ELK_DB_HOST = sys.argv[1].split(':')[0]
        ELK_DB_PORT = sys.argv[1].split(':')[1]
else:
    print('Usage: python push_to_elk.py host:port')
    print('Unable to publish data to ELK. Exiting.')
    sys.exit()

# Construct json body

# BODY = {}

try:
    es = Elasticsearch(
        hosts=[{'host': ELK_DB_HOST, 'port': int(ELK_DB_PORT)}],
        scheme='https',
        connection_class=RequestsHttpConnection
    )
except Exception as e:
    print('Unexpected Error Occurred. Exiting')
    print(e)
# print(es.info())


# get data from the user defined script
BODY = data_gen.generate()

print(json.dumps(BODY, indent=4))

# Try to send request to ELK DB.

try:
    index = '{}-{}'.format(BODY[BODY['type']]['project'],
                           BODY[BODY['type']]['subject'])
    ES_ID = '{}:{}-{}'.format(BODY['type'], BODY[BODY['type']]
                              ['test-name'], BODY[BODY['type']]['test-run'])
    res = es.index(index=index, doc_type='doc', id=ES_ID, body=BODY)
    print(json.dumps(res, indent=4))
except Exception as e:
    print(e)
    print('Unable to push data to ElasticSearch')


# sys.exit()
# Function to convert JSON object to string.
# Python puts 'true' as 'True' etc. which need handling.


def JSONToString(jobj):
    retval = str(jobj)
    retval = retval.replace('\'', '"')
    retval = retval.replace(': ', ':')
    retval = retval.replace(', ', ',')
    retval = retval.replace('True', 'true')
    retval = retval.replace('False', 'false')
    retval = retval.replace('None', 'null')
    return retval


# Create and push index-pattern to be used by visualizations

INDEX_PATTERN_BODY = {
    "type": "index-pattern",
    "index-pattern": {
        "timeFieldName": "performance.@timestamp",
        "title": '{}-{}'.format(BODY[BODY['type']]['project'],
                                BODY[BODY['type']]['subject'])
    }
}


KIBANA_CONFIG = {'config': {
    'defaultIndex': 'pattern-for-{}-{}'.format(BODY[BODY['type']]['project'],
                                               BODY[BODY['type']]['subject']),
    'timepicker:timeDefaults': '{\n  "from": "now-5y",\n \
                                "to": "now",\n  "mode": "quick"\n}',
    'xPackMonitoring:showBanner': False},
    'type': 'config',
}

res = es.index(index='.kibana', doc_type='doc',
               id='config:6.2.4', body=KIBANA_CONFIG)


try:
    index = '.kibana'
    ES_ID = 'index-pattern:pattern-for-{}-{}'.format(
        BODY[BODY['type']]['project'], BODY[BODY['type']]['subject'])
    res = es.index(index=index, doc_type='doc',
                   id=ES_ID, body=INDEX_PATTERN_BODY)
    p(json.dumps(INDEX_PATTERN_BODY, indent=4))
    print(json.dumps(res, indent=4))
except Exception as e:
    print(e)
    # raise e
    print('Unable to push data to ElasticSearch')

# Create and push visualizations
try:
    viz_config_path = glob.glob('**/dashboard/viz_config.yaml')[0]
except IndexError:
    print('Visualization template file not found!')
    sys.exit()

try:
    dash_config_path = glob.glob('**/dashboard/dash_config.yaml')[0]
except IndexError:
    print('Dashboard configuration file not found!')
    sys.exit()

with open(dash_config_path, 'r') as f:
    dash_config = yaml.safe_load(f)

with open(viz_config_path, 'r') as f:
    viz_config = yaml.safe_load(f)

SEARCH_SOURCE = {"index": None, "filter": [],
                 "query": {"language": "lucene", "query": ""}}

for _, i in dash_config['dashboard']['viz'].items():
    intermediate_format, visState = vis_gen.generate(
        i, viz_config[i['viz-template']])

    # p(intermediate_format)
    # p(visState)

    SEARCH_SOURCE['index'] = intermediate_format['index_pattern']
    VIZ_BODY = {
        'type': 'visualization',
        'visualization': {
            "title": None,
            "visState": None,
            "uiStateJSON": "{}",
            "description": None,
            "version": 1,
            "kibanaSavedObjectMeta": {
                "searchSourceJSON": JSONToString(SEARCH_SOURCE)
            }
        }
    }

    VIZ_BODY['visualization']['title'] = intermediate_format['title']
    VIZ_BODY['visualization']['visState'] = JSONToString(visState)
    VIZ_BODY['visualization']['description'] = intermediate_format['desc']

    p(VIZ_BODY)
    index = '.kibana'
    ES_ID = 'visualization:{}'.format(i['id'])
    res = es.index(index=index, doc_type='doc', id=ES_ID, body=VIZ_BODY)
    print(json.dumps(res, indent=4))


# Create and push dashboard


for _, i in dash_config.items():
    DASH_BODY = {
        'type': 'dashboard',
        'dashboard': {
            'title': None,
            'description': None,
            'panelsJSON': None,
            'optionsJSON': '{\"darkTheme\":false,\
                            \"hidePanelTitles\":false,\"useMargins\":true}',
            'version': 1,
            'kibanaSavedObjectMeta': {
                'searchSourceJSON': '{\"query\":{\"language\":\"lucene\", \
                                     \"query\":\"\"}, \
                                     \"filter\":[],\"highlightAll\" \
                                      :true,\"version\":true}'
            }
        }
    }

    DASH_BODY['dashboard']['title'] = i['title']
    DASH_BODY['dashboard']['description'] = i['desc']
    DASH_BODY['dashboard']['panelsJSON'] = JSONToString(
        dash_gen.generate(i['viz']))

    p(DASH_BODY)

    index = '.kibana'
    ES_ID = 'dashboard:{}'.format(i['id'])
    res = es.index(index=index, doc_type='doc', id=ES_ID, body=DASH_BODY)
    print(json.dumps(res, indent=4))

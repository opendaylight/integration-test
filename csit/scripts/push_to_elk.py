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

JSON body similar to following is constructed from robot files, jenkins environment
and plot files available in workspace available post-build.
{
    "project": "opendaylight", <- fix string for ODL project
    "subject": "test", <- fix string for ODL test
    "test-type": "performance", <- if there are csv files, otherwise "functional"
    "jenkins-silo": "releng" <- from Jenkins $SILO
    "test-name": "openflowplugin-csit-1node-periodic-bulkomatic-perf-daily-only-carbon", <- from Jenkins $JOB_NAME
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
from datetime import datetime
import glob
import json
import os
import requests
import sys
import time
import xml.etree.ElementTree as ET

# 3rd party lib
import yaml

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

BODY = {}

ts = time.time()
formatted_ts = \
    datetime.fromtimestamp(ts).strftime('%Y-%m-%dT%H:%M:%S.%fZ')
BODY['@timestamp'] = formatted_ts

# Plots are obtained from csv files (present in archives directory in $WORKSPACE).

csv_files = glob.glob('archives/*.csv')
BODY['project'] = 'opendaylight'
BODY['subject'] = 'test'

# If there are no csv files, then it is a functional test.
# Parse csv files and fill perfomance parameter values

if len(csv_files) == 0:
    BODY['test-type'] = 'functional'
else:
    BODY['test-type'] = 'performance'
    BODY['plots'] = {}
    for f in csv_files:
        key = (f.split('/')[-1])[:-4]
        BODY['plots'][key] = {}
        with open(f) as file:
            lines = file.readlines()
        props = lines[0].strip().split(',')
        vals = lines[1].strip().split(',')
        BODY['plots'][key][props[0]] = float(vals[0])
        BODY['plots'][key][props[1]] = float(vals[1])
        BODY['plots'][key][props[2]] = float(vals[2])

# Fill the required parameters whose values are obtained from environment.

BODY['jenkins-silo'] = os.environ['SILO']
BODY['test-name'] = os.environ['JOB_NAME']
BODY['test-run'] = os.environ['BUILD_NUMBER']

# Parsing robot log for statistics on no of start-time, pass/fail tests and duration.

robot_log = os.environ['WORKSPACE'] + '/output.xml'
tree = ET.parse(robot_log)
BODY['id'] = '{}-{}'.format(os.environ['JOB_NAME'],
                            os.environ['BUILD_NUMBER'])
BODY['start-time'] = tree.getroot().attrib['generated']
BODY['pass-tests'] = tree.getroot().find('statistics')[0][1].get('pass')
BODY['fail-tests'] = tree.getroot().find('statistics')[0][1].get('fail')
endtime = tree.getroot().find('suite').find('status').get('endtime')
starttime = tree.getroot().find('suite').find('status').get('starttime')
elap_time = datetime.strptime(endtime, '%Y%m%d %H:%M:%S.%f') \
    - datetime.strptime(starttime, '%Y%m%d %H:%M:%S.%f')
BODY['duration'] = str(elap_time)

# Parse JSON BODY to construct PUT_URL

PUT_URL_INDEX = '/{}-{}'.format(BODY['project'], BODY['subject'])
PUT_URL_TYPE = '/{}'.format(BODY['test-type'])
PUT_URL_ID = '/{}-{}'.format(BODY['test-name'], BODY['test-run'])
PUT_URL = 'https://{}:{}{}{}{}'.format(ELK_DB_HOST, ELK_DB_PORT, PUT_URL_INDEX, PUT_URL_TYPE, PUT_URL_ID)
print(PUT_URL)

print(json.dumps(BODY, indent=4))

# Try to send request to ELK DB.

try:
    r = requests.put(PUT_URL, json=BODY)
    print(r.status_code)
    print(json.dumps(json.loads(r.content), indent=4))
except:
    print('Unable to push data to ElasticSearch')


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


# This function takes
# testname (string, eg: 'openflowplugin-csit-1node-periodic-bulkomatic-perf-daily-only-carbon'),
# fieldlist (list of fields, eg: ['pass-tests', 'failed-tests']),
# plotkey (string, eg: 'rate')
# as parameters and constructs a visualization object in JSON format

def getVisualization(testname, fieldlist, plotkey=''):
    vis = {}
    vis['title'] = testname
    if plotkey != '':
        vis['title'] += '-' + plotkey
    vis['description'] = 'visualization of ' + plotkey \
        + ' trends for testplan ' + testname
    vis['version'] = 1
    vis['kibanaSavedObjectMeta'] = {'searchSourceJSON': ''}
    searchSourceJSON = {
        'index': 'opendaylight-test',
        'query': {
            'query_string': {
                'analyze_wildcard': True,
                'query': '*'
            }
        },
        'filter': [{
            'meta': {
                'index': 'opendaylight-test',
                'negate': False,
                'disabled': False,
                'alias': None,
                'type': 'phrase',
                'key': 'test-name',
                'value': testname,
            },
            'query': {
                'match': {
                    'test-name': {
                        'query': testname,
                        'type': 'phrase'
                    }
                }
            },
            '$state': {
                'store': 'appState'
            }
        }]
    }

    vis['kibanaSavedObjectMeta']['searchSourceJSON'] = \
        JSONToString(searchSourceJSON)
    vis['uiStateJSON'] = '{"vis":{"legendOpen":true, "colors":{"pass-tests":"#7EB26D","failed-tests":"#E24D42"}}}'
    visState = {
        'title': vis['title'],
        'type': 'area',
        'params': {
            'addLegend': True,
            'addTimeMarker': False,
            'addTooltip': True,
            'times': [],
            'grid': {
                'categoryLines': False,
                'style': {
                    'color': '#eee'
                }
            },
            'legendPosition': 'right',
            'seriesParams': [],
            'categoryAxes': [{
                'id': 'CategoryAxis-1',
                'labels': {'show': True, 'truncate': 100},
                'position': 'bottom',
                'scale': {'type': 'linear'},
                'show': True,
                'style': {},
                'title': {'text': 'Test run number'},
                'type': 'category',
            }],
            'valueAxes': [{
                'id': 'ValueAxis-1',
                'labels': {
                    'filter': False,
                    'rotate': 0,
                    'show': True,
                    'truncate': 100,
                },
                'name': 'LeftAxis-1',
                'position': 'left',
                'scale': {'mode': 'normal', 'type': 'linear'},
                'show': True,
                'style': {},
                'title': {'text': ''},
                'type': 'value',
            }],
        },
        'aggs': [{
            'id': '2',
            'enabled': True,
            'type': 'histogram',
            'schema': 'segment',
            'params': {
                'field': 'test-run',
                'interval': 1,
                'extended_bounds': {},
                'customLabel': 'Test run number',
            },
        }],
        'listeners': {},
    }
    if plotkey != '':  # Performance plot
        visState['type'] = 'line'
    for field in fieldlist:
        seriesParam = {
            'show': True,
            'mode': 'normal',
            'type': 'area',
            'drawLinesBetweenPoints': True,
            'showCircles': True,
            'interpolate': 'linear',
            'lineWidth': 2,
            'data': {
                'id': str(len(visState['params']['seriesParams']) + 1) + '-' + vis['title'],
                'label': field.split('.')[-1]
            },
            'valueAxis': 'ValueAxis-1',
        }
        if plotkey != '':  # Performance plot
            seriesParam['type'] = 'line'
        agg = {
            'id': str(len(visState['params']['seriesParams']) + 1) + '-' + vis['title'],
            'enabled': True,
            'type': 'sum',
            'schema': 'metric',
            'params': {
                'field': field,
                'customLabel': field.split('.')[-1]
            },
        }

        visState['params']['seriesParams'].append(seriesParam)
        visState['aggs'].append(agg)

    vis['visState'] = JSONToString(visState)
    return vis


vis_ids = []
if BODY['test-type'] == 'performance':

    # Create visualizations for performance tests
    # One visualization for one plot

    for key in BODY['plots']:
        fieldlist = []
        for subkey in BODY['plots'][key]:
            fieldlist.append('plots.' + key + '.' + subkey)
        vis = getVisualization(BODY['test-name'], fieldlist, key)
        vis_ids.append(BODY['test-name'] + '-' + key)
        PUT_URL = \
            'https://{}:{}/.kibana/visualization/{}-{}'.format(ELK_DB_HOST, ELK_DB_PORT, BODY['test-name'], key)
        print(PUT_URL)
        print(json.dumps(vis, indent=4))
        try:
            r = requests.put(PUT_URL, json=vis)
            print(r.status_code)
            print(json.dumps(json.loads(r.content), indent=4))
        except:
            print('Unable to push visualization to Kibana')

vis = getVisualization(BODY['test-name'],
                       ['pass-tests', 'failed-tests'])
vis_ids.append(BODY['test-name'])
PUT_URL = 'https://{}:{}/.kibana/visualization/{}'.format(ELK_DB_HOST, ELK_DB_PORT, BODY['test-name'])
print(PUT_URL)
print(json.dumps(vis, indent=4))
try:
    r = requests.put(PUT_URL, json=vis)
    print(r.status_code)
    print(json.dumps(json.loads(r.content), indent=4))
except:
    print('Unable to push dashboard to Kibana')

# Create dashboard and add above created visualizations to it

DASHBOARD_NAME = BODY['test-name'].split('-')[0]
dashboard = {}
dashboard['title'] = DASHBOARD_NAME
dashboard['description'] = 'Dashboard for visualizing ' \
    + DASHBOARD_NAME
dashboard['uiStateJSON'] = '{}'
dashboard['optionsJSON'] = '{"darkTheme":false}'
dashboard['version'] = 1
dashboard['timeRestore'] = False
dashboard['kibanaSavedObjectMeta'] = {
    'searchSourceJSON': '{"filter":[{"query":{"query_string":{"query":"*","analyze_wildcard":true}}}],'
    '"highlightAll":true,"version":true}'
}

# Check if visualizations already present in dashboard. If present, don't add, else, add at end

GET_URL = 'https://{}:{}/.kibana/dashboard/{}'.format(ELK_DB_HOST, ELK_DB_PORT, DASHBOARD_NAME)
r = requests.get(GET_URL)
response = json.loads(r.content)
dashboard_found = response['found']
vis_ids_present = set()
panelsJSON = []

print json.dumps(response, indent=4)
if dashboard_found:
    panelsJSON = yaml.safe_load(response['_source']['panelsJSON'])
    for vis in panelsJSON:
        vis_ids_present.add(vis['id'])

size_x = 6
size_y = 3
xpos = (len(vis_ids_present) % 2) * 6 + 1
ypos = (len(vis_ids_present) / 2) * 3 + 1
for (i, vis_id) in enumerate(vis_ids):
    if (not dashboard_found or vis_id not in vis_ids_present):
        panelJSON = {
            'size_x': size_x,
            'size_y': size_y,
            'panelIndex': len(vis_ids_present) + i,
            'type': 'visualization',
            'id': vis_id,
            'col': xpos,
            'row': ypos,
        }
        xpos += size_x
        if xpos > 12:
            xpos = 1
            ypos += size_y
        panelsJSON.append(panelJSON)
    else:
        print('visualization ' + vis_id + ' already present in dashboard')

dashboard['panelsJSON'] = JSONToString(panelsJSON)
PUT_URL = 'https://{}:{}/.kibana/dashboard/{}'.format(ELK_DB_HOST, ELK_DB_PORT, DASHBOARD_NAME)
print(PUT_URL)
print(json.dumps(dashboard, indent=4))
r = requests.put(PUT_URL, json=dashboard)
print(r.status_code)
print(json.dumps(json.loads(r.content), indent=4))

#!/usr/bin/python

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


# ELK DB host and port to be passed as ':' separated argument
if len(sys.argv) > 1:
    if ':' in sys.argv[1]:
        ELK_DB_HOST = sys.argv[1].split(':')[0]
        ELK_DB_PORT = sys.argv[1].split(':')[1]
else:
    print("Usage: python push_to_elk.py host:port")
    print("Unable to publish data to ELK. Exiting.")
    sys.exit()

# Construct json body
BODY = {}

ts = time.time()
formatted_ts = datetime.fromtimestamp(ts).strftime('%Y-%m-%dT%H:%M:%S.%fZ')
BODY['@timestamp'] = formatted_ts
# Plots are obtained from csv files (present in archives directory in $WORKSPACE).
csv_files = glob.glob('archives/*.csv')
BODY['project'] = 'opendaylight'
BODY['subject'] = 'test'

# If there are no csv files, then it is a functional test.
# Parse csv files and fill perfomance parameter values
if (len(csv_files) == 0):
    BODY['test-type'] = 'functional'
else:
    BODY['test-type'] = 'performance'
    BODY['plots'] = {}
    for f in csv_files:
        key = f.split('/')[-1][:-4]
        BODY['plots'][key] = {}
        lines = open(f).readlines()
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
BODY['id'] = '{}-{}'.format(os.environ['JOB_NAME'], os.environ['BUILD_NUMBER'])
BODY['start-time'] = tree.getroot().attrib['generated']
BODY['pass-tests'] = tree.getroot().find('statistics')[0][1].get('pass')
BODY['fail-tests'] = tree.getroot().find('statistics')[0][1].get('fail')
endtime = tree.getroot().find('suite').find('status').get('endtime')
starttime = tree.getroot().find('suite').find('status').get('starttime')
elap_time = datetime.strptime(endtime, '%Y%m%d %H:%M:%S.%f') - datetime.strptime(starttime, '%Y%m%d %H:%M:%S.%f')
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
    print(r.content)
except:
    print('Unable to send PUT request')

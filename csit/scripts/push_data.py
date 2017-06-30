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
This script is responsible for sending JSON BODY parsed from logs to ELK DB.
In order to use this script, the following fields are must for constructing
REST request.
'project',
'subject',
'test-type',
'test-name',
'test-run'

'@timestamp' is also required even if it is not used in constructing REST request.
It is required by Kibana.

ELK DB IP can be given as an argument to this script.
"""

# stdlib
import json
import sys

# 3rd party
import requests

# local
import settings
import construct_json

settings.init()
construct_json.construct()

ELK_DB_IP = settings.ELK_DB_IP
ELK_DB_PORT = settings.ELK_DB_PORT
BODY = settings.BODY

# ELK DB IP to be passed as argument
if len(sys.argv) > 1:
    ELK_DB_IP = sys.argv[1]

# Parse JSON BODY to construct PUT_URL
PUT_URL_INDEX = '/{}-{}'.format(BODY['project'], BODY['subject'])
PUT_URL_TYPE = '/{}'.format(BODY['test-type'])
PUT_URL_ID = '/{}-{}'.format(BODY['test-name'], BODY['test-run'])
PUT_URL = 'http://{}:{}{}{}{}'.format(ELK_DB_IP, ELK_DB_PORT, PUT_URL_INDEX, PUT_URL_TYPE, PUT_URL_ID)
print(PUT_URL)

print(json.dumps(BODY, indent=4))
# Try to send request to ELK DB.
try:
    r = requests.put(PUT_URL, json=BODY)
    print(r.status_code)
except:
    print('Unable to send PUT request')

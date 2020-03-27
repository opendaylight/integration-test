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
This script is used to parse test logs, construct JSON BODY and push
it to ELK DB.

Usage: python push_test_data.py host:port

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
import sys

# 3rd party lib
from elasticsearch import Elasticsearch, RequestsHttpConnection, exceptions

# User defined libs
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

# Construct json body

# BODY = {}

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


# get data from the user defined script
BODY = data_gen.generate()

print(json.dumps(BODY, indent=4))

# Skip ELK update if it comes from sandbox.
if BODY["jenkins-silo"] == "sandbox":
    print("silo is sandbox, ELK update is skipped")
    sys.exit()

# Try to send request to ELK DB.
try:
    index = "{}-{}".format(BODY["project"], BODY["subject"])
    ES_ID = "{}:{}-{}".format(BODY["test-type"], BODY["test-name"], BODY["test-run"])
    res = es.index(index=index, doc_type="doc", id=ES_ID, body=BODY)
    print(json.dumps(res, indent=4))
except Exception as e:
    print(e)
    print("Unable to push data to ElasticSearch")

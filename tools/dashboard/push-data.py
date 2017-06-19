#!/usr/bin/python
import sys
import requests
import glob
import json
import os
import xml.etree.ElementTree as ET
from datetime import datetime

ELK_DB_IP = '127.0.0.1'
if len(sys.argv) > 1:
    ELK_DB_IP = sys.argv[1]
POST_URL = 'http://' + ELK_DB_IP + ':8585'
print POST_URL
BODY = {}
csv_files = glob.glob('archives/*.csv')
BODY['project'] = 'opendaylight'
BODY['subject'] = 'test'

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

BODY['jenkins-silo'] = os.environ['SILO']
BODY['test-name'] = os.environ['JOB_NAME']
BODY['test-run'] = os.environ['BUILD_NUMBER']

robot_log = os.environ['WORKSPACE'] + '/output.xml'
tree = ET.parse(robot_log)
BODY['start-time'] = tree.getroot().attrib['generated']
BODY['pass-tests'] = tree.getroot().find('statistics')[0][1].get('pass')
BODY['fail-tests'] = tree.getroot().find('statistics')[0][1].get('fail')
endtime = tree.getroot().find('suite').find('status').get('endtime')
starttime = tree.getroot().find('suite').find('status').get('starttime')
elap_time = datetime.strptime(endtime, '%Y%m%d %H:%M:%S.%f') - datetime.strptime(starttime, '%Y%m%d %H:%M:%S.%f')
BODY['duration'] = str(elap_time)

print json.dumps(BODY, indent=4)
try:
    r = requests.post(POST_URL, json=BODY)
    print r.status_code
except:
    print 'Unable to send POST request'

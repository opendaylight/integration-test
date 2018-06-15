# -*- coding: utf-8 -*-

# @License EPL-1.0 <http://spdx.org/licenses/EPL-1.0>
##############################################################################
# Copyright (c) 2018 Taseer Ahmed and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

import argparse
import push_to_elk

parser = argparse.ArgumentParser("description=Push CSIT job results to Elastic")
parser.add_argument("host", help="IP/Hostname of Elastic host")
parser.add_argument("port", help="Port where Elastic is listening")
args = parser.parse_args()

ELK_DB_HOST = args.host
ELK_DB_PORT = args.port

payload = push_to_elk.construct_json()
push_to_elk.push_to_elastic(payload, ELK_DB_HOST, ELK_DB_PORT)
push_to_elk.publish_dashboard(payload, ELK_DB_HOST, ELK_DB_PORT)

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

"""Initialize global ELK variables

This script is responsible to set global variables
"""

def init():
    global BODY
    global ELK_DB_IP
    global ELK_DB_PORT
    BODY = {}
    ELK_DB_IP = "127.0.0.1"
    ELK_DB_PORT = 9200

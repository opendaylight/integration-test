*** Settings ***
Documentation     DOMDataBroker testing: Common keywords
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Library           ${CURDIR}/../MdsalLowlevelPy.py
Resource          ${CURDIR}/../MdsalLowlevel.robot

*** Variables ***

*** Keywords ***
Move_Leader
    BuiltIn.Sleep   1s

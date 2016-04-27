*** Settings ***
Documentation     Bug 4462 test suite.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Try to detect whether Karaf hangs when trying to install
...               "odl-integration-compatible-with-all".
#Suite Setup       Setup_Everything
#Suite Teardown    Teardown_Everything
#Library           RequestsLibrary
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
#Resource          ${CURDIR}/../../../libraries/Utils.robot
#Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${KARAF_CHECK_TIMEOUT}    3m

*** Testcases ***
Try_To_Install_Compatible_With_All
    [Documentation]    Try to install "odl-integration-comptible-with-all" and check whether Karaf hangs on it or not (bug 4462).
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install odl-integration-comptible-with-all    timeout=${KARAF_CHECK_TIMEOUT}

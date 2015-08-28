*** Settings ***
Documentation     Robot keyword library (Resource) for common BGP handling primitives
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Library           RequestsLibrary
Resource          ${CURDIR}/Utils.robot

*** Keywords ***
Get_Topology_Count_Core
    [Documentation]    Get count of prefixes in the topology. Expects the name of the file where
    ...    the topology data should be stored. Stores the response code into ${response_code} and
    ...    does not fail if it is not 200 (call Fail_If_Status_Is_Wrong afterwards if that is
    ...    not the desired behavior).
    ${response}=    RequestsLibrary.Get    operational    network-topology:network-topology/topology/example-ipv4-topology
    Utils.Store_Response_Code    ${response}
    ${actual_count}=    Builtin.Evaluate    len(re.findall('${prefix_pattern}', '''${response.text}'''))    modules=re
    Builtin.Return_From_Keyword    ${actual_count}

Get_Topology_Count
    [Documentation]    Get count of prefixes in the topology. Fails if the response is not 200.
    ${result}=    Get_Topology_Count_Core
    Utils.Fail_If_Status_Is_Wrong
    Builtin.Return_From_Keyword    ${result}

Check_Topology_Count
    [Arguments]    ${expected_count}
    [Documentation]    Check that the count of prefixes matches the expected count. Fails if it does not.
    ...    Fails if the status code is not 200.
    ${actual_count}=    Get_Topology_Count
    BuiltIn.Should_Be_Equal_As_Strings    ${actual_count}    ${expected_count}

*** Settings ***
Documentation     Robot keyword library (Resource) for common BGP handling primitives
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This resource assumes that RequestsLibrary has an open
Library           RequestsLibrary
Resource          ${CURDIR}/Utils.robot

*** Keywords ***
Count_Prefixes_In_Topology_Data
    [Arguments]    ${data}
    [Documentation]    Count prefixes in ${data}.
    ${actual_count}=    Builtin.Evaluate    len(re.findall('"prefix":"', '''${data}'''))    modules=re
    [Return]    ${actual_count}

Check_Count_In_Topology_Data
    [Arguments]    ${expected_count}    ${data}
    [Documentation]    Check that ${data} represents a topology with ${expected_count}
    ...    prefixes, fail if not.
    ${actual_count}=    Count_Prefixes_In_Topology_Data    ${data}
    BuiltIn.Should_Be_Equal_As_Strings    ${actual_count}    ${expected_count}

Get_And_Process_Topology
    [Arguments]    @{processor}
    [Documentation]    Get the topology data, run it through ${processor} and return the
    ...    result. Fail on a HTTP error.
    ${topology}=    Utils.Get_Data_From_URI    operational    network-topology:network-topology/topology/example-ipv4-topology
    ${result}=    BuiltIn.Run_Keyword    @{processor}    ${topology}
    [Return]    ${result}

Get_Topology_Count
    [Documentation]    Get count of prefixes in the topology. Fails if the response is not 200.
    ${result}=    Get_And_Process_Topology    Count_Prefixes_In_Topology_Data
    [Return]    ${result}

Check_Topology_Count
    [Arguments]    ${expected_count}
    [Documentation]    Check that the count of prefixes matches the expected count. Fails if it does not.
    ...    Fails if the status code is not 200.
    Get_And_Process_Topology    Check_Count_In_Topology_Data    ${expected_count}

Check_Topology_Is_Empty
    [Documentation]    Check that ${data} represents an empty topology, fail if not.
    Check_Topology_Count    0

Initial_Wait_For_Topology_To_Become_Empty
    [Arguments]    @{keyword}
    [Documentation]    Check that the count of prefixes matches the expected count. Fails if it does not.
    ...    Fails if the status code is not 200.
    # TODO: Verify that 120 seconds is not too short if this is run immediatelly after ODL is started.
    Utils.Wait_For_Data_To_Satisfy_Keyword_And_Ignore_Errors    120s    10s    1    Check_Topology_Is_Empty

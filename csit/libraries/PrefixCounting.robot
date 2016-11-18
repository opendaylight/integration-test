*** Settings ***
Documentation     Robot keyword library (Resource) for common BGP actions concerned with counting prefixes.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Currently, all keywords count prefixes only in ${topology}.
...               Prefix is identified by simplistic regular expression on JSON data.
...
...               This resource assumes that RequestsLibrary has open a connection named "operational"
...               which points to (an analogue of) http://<ip-addr>:${RESTCONFPORT}/${OPERATIONAL_API}
...               or user has to provide a similar session.
Library           RequestsLibrary
Resource          ${CURDIR}/WaitUtils.robot
Resource          ${CURDIR}/ScalarClosures.robot

*** Keywords ***
PC_Setup
    [Documentation]    Call dependency setups and construct suite variables.
    WaitUtils.WU_Setup    # includes ScalarClosures.SC_Setup

Get_Ipv4_Topology
    [Arguments]    ${session}=operational    ${topology}=example-ipv4-topology
    [Documentation]    GET the ${topology} data, check status is 200, return the topology data.
    ...
    ...    Contrary to Utils.Get_Data_From_URI, this does not Log the (potentially huge) content.
    ${response} =    RequestsLibrary.Get_Request    ${session}    network-topology:network-topology/topology/${topology}
    Run_Keyword_If    ${response.status_code} != 200    Fail    Get on ${topology} returned status code ${response.status_code} with message: ${response.text}
    [Return]    ${response.text}

Get_Ipv4_Topology_Count
    [Arguments]    ${session}=operational    ${topology}=example-ipv4-topology
    [Documentation]    Get topology. If not fail, return number of prefixes in the topology.
    ${topology} =    Get_Ipv4_Topology    session=${session}    topology=${topology}
    # Triple quotes are precaution against formatted output.
    ${prefix_count} =    Builtin.Evaluate    len(re.findall('"prefix":"', '''${topology}'''))    modules=re
    [Return]    ${prefix_count}

Check_Ipv4_Topology_Count
    [Arguments]    ${expected_count}    ${session}=operational    ${topology}=example-ipv4-topology
    [Documentation]    Check that the count of prefixes matches the expected count. Fails if it does not. In either case, collect garbage.
    ${actual_count} =    ScalarClosures.Run_Keyword_And_Collect_Garbage    Get_Ipv4_Topology_Count    session=${session}    topology=${topology}
    BuiltIn.Log To Console    A: ${actual_count} ${expected_count}
    BuiltIn.Should_Be_Equal_As_Strings    ${actual_count}    ${expected_count}

Check_Ipv4_Topology_Is_Empty
    [Arguments]    ${session}=operational    ${topology}=example-ipv4-topology
    [Documentation]    Example_Ipv4_Topology has to give status 200 with zero prefixes.
    ...
    ...    Functional suites should use a more strict Keyword which tests for the whole JSON structure.
    Check_Ipv4_Topology_Count    0    session=${session}    topology=${topology}

Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable
    [Arguments]    ${timeout}=60s    ${period}=5s    ${repetitions}=1    ${excluded_count}=-1    ${session}=operational    ${topology}=example-ipv4-topology
    [Documentation]    Each ${period} get prefix count. After ${repetitions} of stable different from ${excluded_count} within ${timeout}, Return validator output. Fail early on getter error.
    # This is very similar to ChangeCounter keyword, but attempt to extract common code would increase overall code size.
    ${getter} =    ScalarClosures.Closure_From_Keyword_And_Arguments    Get_Ipv4_Topology_Count    session=${session}    topology=${topology}
    ${validator} =    ScalarClosures.Closure_From_Keyword_And_Arguments    WaitUtils.Excluding_Stability_Safe_Stateful_Validator_As_Keyword    state_holder    data_holder    excluded_value=${excluded_count}
    ${result} =    WaitUtils.Wait_For_Getter_Error_Or_Safe_Stateful_Validator_Consecutive_Success    timeout=${timeout}    period=${period}    count=${repetitions}    getter=${getter}    safe_validator=${validator}
    ...    initial_state=${excluded_count}
    [Return]    ${result}

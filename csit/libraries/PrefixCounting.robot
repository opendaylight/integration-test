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
...               This resource assumes that RequestsLibrary has open a connection named "operational"
...               which points to (an analogue of) http://${ODL_SYSTEM_IP}:${RESTCONFPORT}/${OPERATIONAL_API}
Library           RequestsLibrary
Resource          ${CURDIR}/WaitUtils.robot

*** Keywords ***
PC_Setup
    [Documentation]    Call dependency setups and construct suite variables.
    WaitUtils.WU_Setup
    ${getter} =    ScalarClosures.Closure_From_Keyword_And_Arguments    Get_Ipv4_Topology_Count
    BuiltIn.Set_Suite_Variable    ${PrefixCounting__getter}    ${getter}

Get_Ipv4_Topology
    [Documentation]    GET the example-ipv4-topology data, check status is 200, return the topology data.
    ${response} =    RequestsLibrary.Get_Request    operational    network-topology:network-topology/topology/example-ipv4-topology
    Run_Keyword_If    ${response.status_code} != 200    Fail    Get on example-ipv4-topology returned status code ${response.status_code}
    [Return]    ${response.text}

Get_Ipv4_Topology_Count
    [Documentation]    Get topology. If not fail, return number of prefixes in the topology.
    ${topology} =    Get_Ipv4_Topology
    ${prefix_count} =    Builtin.Evaluate    len(re.findall('"prefix":"', '''${topology}'''))    modules=re
    [Return]    ${prefix_count}

Check_Ipv4_Topology_Count
    [Arguments]    ${expected_count}
    [Documentation]    Check that the count of prefixes matches the expected count. Fails if it does not.
    ...    Fails if the status code is not 200.
    ${actual_count} =    ScalarClosures.Run_Keyword_And_Collect_Garbage    Get_Ipv4_Topology_Count
    BuiltIn.Should_Be_Equal_As_Strings    ${actual_count}    ${expected_count}

Check_Ipv4_Topology_Is_Empty
    [Documentation]    Example_Ipv4_Topology has to give status 200 with have zero prefixes.
    Check_Ipv4_Topology_Count    0

Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable
    [Arguments]    ${timeout}=60s    ${period}=5s    ${repetitions}=1    ${count_to_overcome}=-1
    [Documentation]    Each ${period} get prefix count. After ${repetitions} of stable value above ${count_to_overcome} within ${timeout}, Return validator output. Fail early on getter error.
    ${validator} =    WaitUtils.Create_Limiting_Stability_Safe_Stateful_Validator_From_Value_To_Overcome    maximum_invalid=${count_to_overcome}
    ${result} =    WaitUtils.Wait_For_Getter_Error_Or_Safe_Stateful_Validator_Consecutive_Success    timeout=${timeout}    period=${period}    count=${repetitions}    getter=${PrefixCounting__getter}    safe_validator=${validator}
    ...    initial_state=${count_to_overcome}
    [Return]    ${result}

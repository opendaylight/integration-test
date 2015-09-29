*** Settings ***
Documentation    Basic tests for ping and curl
Library           SSHLibrary
Library           Collections
Resource          ../Utils.robot
Resource          ConnUtils.robot
Resource          DockerUtils.robot
Variables         ../../variables/Variables.py
Library           OperatingSystem

*** Keywords ***
Find Flow in DPCTL Output
    [Arguments]    ${flow_match_criteria}    ${flow_action_criteria}
    [Documentation]    Executes 'ovs-dpctl dump-flows' on remote system and goes through each output line.
    ...    A line is returned if all the criterias in actions part and matches part are matched. This is
    ...    done by calling 'Check Match' keyword. If no match is found for any of the flows, caller test case
    ...    will be failed.
    ${output}    SSHLibrary.ExecuteCommand    sudo ovs-dpctl dump-flows
    Log  ${output}
    @{lines}    Split To Lines    ${output}
    ${match_result}    Set Variable
    ${action_result}    Set Variable
    :FOR    ${line}    IN    @{lines}
    \    ${match}    Get Matches Part    ${line}
    \    ${action}    Get Actions Part    ${line}
    \    ${match_result}    Check Match    ${match}    @{flow_match_criteria}
    \    ${action_result}    Check Match    ${action}    @{flow_action_criteria}
    \    Run Keyword If    "${match_result}" == "TRUE" and "${action_result}" == "TRUE"
    \    ...    Return From Keyword    ${line}
    Log    ${flow_match_criteria}
    Log    ${flow_action_criteria}
    Fail    Flow not found!

Get Matches Part
    [Arguments]    ${ovs-dpctl_flow}
    [Documentation]    Returns matches part of a flow captured with 'ovs-dpctl dump-flows'.
    @{matches_actions}    Split String    ${ovs-dpctl_flow}    actions
    Log    ${matches_actions[0]}
    [Return]    ${matches_actions[0]}

Get Actions Part
    [Arguments]    ${ovs-dpctl_flow}
    [Documentation]    Returns actions part of a flow captured with 'ovs-dpctl dump-flows'.
    @{matches_actions}    Split String    ${ovs-dpctl_flow}    actions
    [Return]    ${matches_actions[1]}

Check Match
    [Arguments]    ${string}    @{match_criteria}
    [Documentation]    Applies 'grep' on the string argument for each criterion.
    ${conditions}    Set Variable
    :FOR    ${criterio}    IN    @{match_criteria}
    \    ${grep_criterio}    Catenate    | grep     ${criterio}
    \    ${conditions}    Catenate   ${conditions}    ${grep_criterio}
    ${output}    OperatingSystem.Run    echo "${string}" ${conditions}
    Log    ${output}
    Run Keyword If    "${output}" == "${EMPTY}"
    ...    Return From Keyword    FALSE
    ...    ELSE    Return From Keyword    TRUE

Append Proto Check
    [Arguments]    ${list}    ${proto}
    [Documentation]    Returns proto part of flow can be captured with 'ovs-dpctl dump-flows'.
    Append To List    ${list}    proto=${proto}

Append Inner MAC Check
    [Arguments]    ${list}    ${src_addr}=${EMPTY}    ${dst_addr}=${EMPTY}
    [Documentation]    Returns encapsulated MAC addresses part of flow can be captured with 'ovs-dpctl dump-flows'.
    Run Keyword If     "${src_addr}" != "${EMPTY}" and "${dst_addr}" != "${EMPTY}"
    ...    Append To List    ${list}    "eth(src=${src_addr},dst=${dst_addr})"
    ...    ELSE IF    "${src_addr}" != "${EMPTY}"
    ...    Append To List    ${list}    "eth(src=${src_addr},dst=.*)"
    ...    ELSE IF    "${dst_addr}" != "${EMPTY}"
    ...    Append To List    ${list}    "eth(src=.*,dst=${dst_addr})"
    ...    ELSE    Fail    Specify at liest src or dest IP!

Append Inner IPs Check
    [Arguments]    ${list}    ${src_ip}=${EMPTY}    ${dst_ip}=${EMPTY}
    [Documentation]    Returns encapsulated IP addresses part of flow can be captured with 'ovs-dpctl dump-flows'.
    Run Keyword If     "${src_ip}" != "${EMPTY}" and "${dst_ip}" != "${EMPTY}"
    ...    Append To List    ${list}    "ipv4(src=${src_ip},dst=${dst_ip}"
    ...    ELSE IF    "${src_ip}" != "${EMPTY}"
    ...    Append To List    ${list}    "ipv4(src=${src_ip},dst=.*"
    ...    ELSE IF    "${dst_ip}" != "${EMPTY}"
    ...    Append To List    ${list}    "ipv4(src=.*,dst=${dst_ip}"
    ...    ELSE    Fail    Specify at liest src or dest IP!

Append Outer IPs Check
    [Arguments]    ${list}    ${src_ip}=${EMPTY}    ${dst_ip}=${EMPTY}
    [Documentation]    Returns packet IP addresses part of flow can be captured with 'ovs-dpctl dump-flows'.
    Run Keyword If     "${src_ip}" != "${EMPTY}"
    ...    Append To List    ${list}    src=${src_ip}
    ...    ELSE IF    "${dst_ip}" != "${EMPTY}"
    ...    Append To List    ${list}    dst=${dst_ip}
    ...    ELSE    Fail    Specify at liest src or dest IP!

Append In Port Check
    [Arguments]    ${list}    ${in_port}
    [Documentation]    Returns ingress port part of flow can be captured with 'ovs-dpctl dump-flows'.
    Append To List    ${list}    "in_port(${in_port})"

Append Out Port Check
    [Arguments]    ${list}    ${out_port}
    [Documentation]    Returns egress port part of flow can be captured with 'ovs-dpctl dump-flows'.
    Append To List    ${list}    ,${out_port}

Append L4 Check
    [Arguments]    ${list}    ${src_port}=${EMPTY}    ${dst_port}=${EMPTY}
    [Documentation]    Returns L4 port part of flow can be captured with 'ovs-dpctl dump-flows'.
    Run Keyword If     "${src_port}" != "${EMPTY}"
    ...    Append To List    ${list}    src=${src_port}
    ...    ELSE IF    "${dst_port}" != "${EMPTY}"
    ...    Append To List    ${list}    dst=${dst_port}
    ...    ELSE    Fail    Specify at liest src or dest port!

Append NSI Check
    [Arguments]    ${list}    ${nsi}
    [Documentation]    Returns NSI part of flow can be captured with 'ovs-dpctl dump-flows'.
    Append To List    ${list}    nsi=${nsi}

Append NSP Check
    [Arguments]    ${list}    ${nsp}
    [Documentation]    Returns NSP part of flow can be captured with 'ovs-dpctl dump-flows'.
    Append To List    ${list}    nsp=${nsp}

Append Ether-Type Check
    [Arguments]    ${list}    ${eth_type}
    [Documentation]    Returns Ether-Type part of flow can be captured with 'ovs-dpctl dump-flows'.
    Append To List    ${list}    "eth_type(${eth_type})"

Append Tunnel Set Check
    [Arguments]    ${list}
    [Documentation]    Tunnel ID is locally significant to neighbouring nodes and it is not
    ...    statically determined. By checking it's presence in match ( or action) fields,
    ...    we can say whether a packet was received (or send out) via tunnel port.
    Append To List    ${list}    tun_id

Append Tunnel Not Set Check
    [Arguments]    ${list}
    [Documentation]    Tunnel ID is locally significant to neighbouring nodes and it is not
    ...    statically determined. By checking it's presence in match ( or action) fields,
    ...    we can say whether a packet was received (or send out) via tunnel port.
    Append To List    ${list}    -v tun_id

Get NSP Value From Flow
    [Arguments]    ${flow}
    [Documentation]    Reads and returns nsp value from flow captured with 'ovs-dpctl dump-flows'.
    ${flow}    Get Actions Part    ${flow}
    ${output}    OperatingSystem.Run    echo "\$${flow}" | sed 's/.*nsp=/nsp=/' | sed 's/,.*//' | sed 's/.*=//'
    [Return]    ${output}

Wait For Flows On Switch
    [Arguments]  ${switch_ip}  ${switch_name}
    [Documentation]  Counts flows on switch, fails if 0
    ConnUtils.Connect and Login  ${switch_ip}  timeout=${timeout}
    Wait Until Keyword Succeeds  2 min  20 sec  Count Flows On Switch  ${switch_name}
    SSHLibrary.Close Connection

Count Flows On Switch
    [Arguments]  ${switch_name}
    ${out}  SSHLibrary.Execute Command  printf "%d" $(($(sudo ovs-ofctl dump-flows ${switch_name} -OOpenFlow13 | wc -l)-1))
    Should Not Be Equal As Integers  ${out}  0

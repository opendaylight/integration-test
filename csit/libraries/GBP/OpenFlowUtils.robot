*** Settings ***
Documentation       Operations on Docker containers for GBP

Library             SSHLibrary
Library             Collections
Resource            ../Utils.robot
Resource            ConnUtils.robot
Resource            DockerUtils.robot
Variables           ../../variables/Variables.py
Library             OperatingSystem


*** Keywords ***
Inspect Service Function
    [Documentation]    Inspects traffic passing through service function node.
    [Arguments]    ${in_port}    ${out_port}    ${outer_src_ip}    ${outer_dst_ip}    ${eth_type}    ${inner_src_ip}
    ...    ${inner_dst_ip}    ${next_hop_ip}    ${nsp}    ${received_nsi}    ${proto}=${EMPTY}
    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check    ${matches}    ${in_port}
    Append Ether-Type Check    ${matches}    ${eth_type}
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check
    ...    ${matches}
    ...    src_ip=${outer__src_ip}/255.255.255.255
    ...    dst_ip=${outer_dst_ip}/255.255.255.255
    Append NSI Check    ${matches}    ${received_nsi}
    Append NSP Check    ${matches}    ${nsp}
    Append Inner IPs Check    ${matches}    ${inner_src_ip}/0.0.0.0    ${inner_dst_ip}/0.0.0.0
    IF    "${proto}" != "${EMPTY}"
        Append Proto Check    ${matches}    ${proto}
    END
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=${next_hop_ip}
    ${rewritten_nsi}    Evaluate    ${received_nsi} -1
    Append NSI Check    ${actions}    ${rewritten_nsi}
    Append NSP Check    ${actions}    ${nsp}
    Append Out Port Check    ${actions}    ${out_port}
    ${flow}    Find Flow in DPCTL Output    ${matches}    ${actions}
    RETURN    ${flow}

Inspect Service Function Forwarder
    [Documentation]    Inspects traffic passing through service function forwarder node.
    [Arguments]    ${in_port}    ${out_port}    ${outer_src_ip}    ${outer_dst_ip}    ${eth_type}    ${inner_src_ip}
    ...    ${inner_dst_ip}    ${next_hop_ip}    ${nsp}    ${nsi}    ${proto}=${EMPTY}
    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check    ${matches}    ${in_port}
    Append Ether-Type Check    ${matches}    ${eth_type}
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=${outer_src_ip}    dst_ip=${outer_dst_ip}
    Append NSI Check    ${matches}    ${nsi}
    Append NSP Check    ${matches}    ${nsp}
    Append Inner IPs Check    ${matches}    ${inner_src_ip}/255.255.255.255    ${inner_dst_ip}/255.255.255.255
    IF    "${proto}" != "${EMPTY}"
        Append Proto Check    ${matches}    ${proto}
    END
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=${next_hop_ip}
    Append NSI Check    ${actions}    ${nsi}
    Append NSP Check    ${actions}    ${nsp}
    Append Out Port Check    ${actions}    ${out_port}
    ${flow}    Find Flow in DPCTL Output    ${matches}    ${actions}
    RETURN    ${flow}

Inspect Classifier Outbound
    [Documentation]    Inspects outbound traffic of a classifier. Traffic source should be located on the classifier.
    ...    If traffic destination is located on the same VM, do not specify neither of next_hop_ip and nsi.
    ...    If traffic destination is located on different VM and the traffic is not forwarded into a chain, specify
    ...    next_hop_ip and don't specify nsi.
    ...    If traffic destination is located on different VM and the traffic is forwarded into a chain, specify both
    ...    next_hop_ip and nsi.
    [Arguments]    ${in_port}    ${out_port}    ${eth_type}    ${inner_src_ip}    ${inner_dst_ip}    ${next_hop_ip}=${EMPTY}
    ...    ${nsi}=${EMPTY}    ${proto}=${EMPTY}    ${src_port}=${EMPTY}    ${dst_port}=${EMPTY}
    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check    ${matches}    ${in_port}
    Append Ether-Type Check    ${matches}    ${eth_type}
    IF    "${proto}" != "${EMPTY}"
        Append Proto Check    ${matches}    ${proto}
    END
    IF    "${src_port}"!="${EMPTY}" or "${dst_port}"!="${EMPTY}"
        Append L4 Check    ${matches}    src_port=${src_port}    dst_port=${dst_port}
    END
    Append Out Port Check    ${actions}    ${out_port}
    Append Inner IPs Check    ${actions}    ${inner_src_ip}    ${inner_dst_ip}
    IF    "${next_hop_ip}"!="${EMPTY}"
        Append Tunnel Set Check    ${actions}
        Append Outer IPs Check    ${actions}    dst_ip=${next_hop_ip}
    ELSE
        Append Tunnel Not Set Check    ${actions}
    END
    IF    "${nsi}"!="${EMPTY}"    Append NSI Check    ${actions}    255
    ${flow}    Find Flow in DPCTL Output    ${matches}    ${actions}
    RETURN    ${flow}

Inspect Classifier Inbound
    [Documentation]    Inspects inbound traffic of a classifier. Traffic destination should be located on the classifier.
    ...    If traffic source is located on different VM and the traffic comes out of a chain, specify nsi and nsp values.
    ...    If traffic source is located on different VM and the traffic does not comes out of a chain, do not specify
    ...    neither of nsi and nsp values.
    [Arguments]    ${in_port}    ${out_port}    ${eth_type}    ${inner_src_ip}    ${inner_dst_ip}    ${outer_src_ip}
    ...    ${outer_dst_ip}    ${nsp}=${EMPTY}    ${nsi}=${EMPTY}    ${proto}=${EMPTY}    ${src_port}=${EMPTY}    ${dst_port}=${EMPTY}
    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check    ${matches}    ${in_port}
    Append Ether-Type Check    ${matches}    ${eth_type}
    Append Outer IPs Check    ${matches}    src_ip=${outer_src_ip}    dst_ip=${outer_dst_ip}
    Append Inner IPs Check    ${matches}    ${inner_src_ip}    ${inner_dst_ip}
    IF    "${src_port}"!="${EMPTY}" or "${dst_port}"!="${EMPTY}"
        Append L4 Check    ${matches}    src_port=${src_port}    dst_port=${dst_port}
    END
    Append Tunnel Set Check    ${matches}
    IF    "${nsi}"!="${EMPTY}" and "${nsp}"!="${EMPTY}"
        Append NSI Check    ${matches}    ${nsi}
        Append NSP Check    ${matches}    ${nsp}
    END
    IF    "${proto}" != "${EMPTY}"
        Append Proto Check    ${matches}    ${proto}
        Append Proto Check    ${actions}    ${proto}
    END
    Append Out Port Check    ${actions}    ${out_port}
    Append Inner IPs Check    ${actions}    ${inner_src_ip}    ${inner_dst_ip}
    ${flow}    Find Flow in DPCTL Output    ${matches}    ${actions}
    RETURN    ${flow}

Find Flow in DPCTL Output
    [Documentation]    Executes 'ovs-dpctl dump-flows' on remote system and goes through each output line.
    ...    A line is returned if all the criterias in actions part and matches part are matched. This is
    ...    done by calling 'Check Match' keyword. If no match is found for any of the flows, caller test case
    ...    will be failed.
    [Arguments]    ${flow_match_criteria}    ${flow_action_criteria}
    ${output}    SSHLibrary.Execute Command    sudo ovs-dpctl dump-flows
    Log    ${output}
    @{lines}    Split To Lines    ${output}
    ${match_result}    Set Variable
    ${action_result}    Set Variable
    FOR    ${line}    IN    @{lines}
        ${match}    Get Matches Part    ${line}
        ${action}    Get Actions Part    ${line}
        ${match_result}    Check Match    ${match}    @{flow_match_criteria}
        ${action_result}    Check Match    ${action}    @{flow_action_criteria}
        IF    "${match_result}" == "TRUE" and "${action_result}" == "TRUE"
            RETURN    ${line}
        END
    END
    Log    ${flow_match_criteria}
    Log    ${flow_action_criteria}
    Fail    Flow not found!

Get Matches Part
    [Documentation]    Returns matches part of a flow captured with 'ovs-dpctl dump-flows'.
    [Arguments]    ${ovs-dpctl_flow}
    @{matches_actions}    Split String    ${ovs-dpctl_flow}    actions
    Log    ${matches_actions[0]}
    RETURN    ${matches_actions[0]}

Get Actions Part
    [Documentation]    Returns actions part of a flow captured with 'ovs-dpctl dump-flows'.
    [Arguments]    ${ovs-dpctl_flow}
    @{matches_actions}    Split String    ${ovs-dpctl_flow}    actions
    RETURN    ${matches_actions[1]}

Check Match
    [Documentation]    Applies 'grep' on the string argument for each criterion.
    [Arguments]    ${string}    @{match_criteria}
    ${conditions}    Set Variable
    FOR    ${criterio}    IN    @{match_criteria}
        ${grep_criterio}    Catenate    | grep    ${criterio}
        ${conditions}    Catenate    ${conditions}    ${grep_criterio}
        ${debug_output}    OperatingSystem.Run    echo "${string}" ${conditions}
        Log    ${debug_output}
        IF    "${debug_output}" == "${EMPTY}"    Log    ${criterio}
    END
    ${output}    OperatingSystem.Run    echo "${string}" ${conditions}
    Log    ${output}
    IF    "${output}" == "${EMPTY}"    RETURN    FALSE    ELSE    RETURN    TRUE

Append Proto Check
    [Documentation]    Returns proto part of flow can be captured with 'ovs-dpctl dump-flows'.
    [Arguments]    ${list}    ${proto}
    Append To List    ${list}    proto=${proto}

Append Inner MAC Check
    [Documentation]    Returns encapsulated MAC addresses part of flow can be captured with 'ovs-dpctl dump-flows'.
    [Arguments]    ${list}    ${src_addr}=${EMPTY}    ${dst_addr}=${EMPTY}
    IF    "${src_addr}" != "${EMPTY}" and "${dst_addr}" != "${EMPTY}"
        Append To List    ${list}    "eth(src=${src_addr},dst=${dst_addr})"
    ELSE IF    "${src_addr}" != "${EMPTY}"
        Append To List    ${list}    "eth(src=${src_addr},dst=.*)"
    ELSE IF    "${dst_addr}" != "${EMPTY}"
        Append To List    ${list}    "eth(src=.*,dst=${dst_addr})"
    ELSE
        Fail    Specify at liest src or dest IP!
    END

Append Inner IPs Check
    [Documentation]    Returns encapsulated IP addresses part of flow can be captured with 'ovs-dpctl dump-flows'.
    [Arguments]    ${list}    ${src_ip}=${EMPTY}    ${dst_ip}=${EMPTY}
    IF    "${src_ip}" != "${EMPTY}" and "${dst_ip}" != "${EMPTY}"
        Append To List    ${list}    "ipv4(src=${src_ip},dst=${dst_ip}"
    ELSE IF    "${src_ip}" != "${EMPTY}"
        Append To List    ${list}    "ipv4(src=${src_ip},dst=.*"
    ELSE IF    "${dst_ip}" != "${EMPTY}"
        Append To List    ${list}    "ipv4(src=.*,dst=${dst_ip}"
    ELSE
        Fail    Specify at liest src or dest IP!
    END

Append Outer IPs Check
    [Documentation]    Returns packet IP addresses part of flow can be captured with 'ovs-dpctl dump-flows'.
    [Arguments]    ${list}    ${src_ip}=${EMPTY}    ${dst_ip}=${EMPTY}
    IF    "${src_ip}" != "${EMPTY}"
        Append To List    ${list}    src=${src_ip}
    ELSE IF    "${dst_ip}" != "${EMPTY}"
        Append To List    ${list}    dst=${dst_ip}
    ELSE
        Fail    Specify at liest src or dest IP!
    END

Append In Port Check
    [Documentation]    Returns ingress port part of flow can be captured with 'ovs-dpctl dump-flows'.
    [Arguments]    ${list}    ${in_port}
    Append To List    ${list}    "in_port(${in_port})"

Append Out Port Check
    [Documentation]    Returns egress port part of flow can be captured with 'ovs-dpctl dump-flows'.
    [Arguments]    ${list}    ${out_port}
    Append To List    ${list}    ,${out_port}

Append L4 Check
    [Documentation]    Returns L4 port part of flow can be captured with 'ovs-dpctl dump-flows'.
    [Arguments]    ${list}    ${src_port}=${EMPTY}    ${dst_port}=${EMPTY}
    IF    "${src_port}" != "${EMPTY}"
        Append To List    ${list}    src=${src_port}
    ELSE IF    "${dst_port}" != "${EMPTY}"
        Append To List    ${list}    dst=${dst_port}
    ELSE
        Fail    Specify at liest src or dest port!
    END

Append NSI Check
    [Documentation]    Returns NSI part of flow can be captured with 'ovs-dpctl dump-flows'.
    [Arguments]    ${list}    ${nsi}
    Append To List    ${list}    nsi=${nsi}

Append NSP Check
    [Documentation]    Returns NSP part of flow can be captured with 'ovs-dpctl dump-flows'.
    [Arguments]    ${list}    ${nsp}
    Append To List    ${list}    nsp=${nsp}

Append Ether-Type Check
    [Documentation]    Returns Ether-Type part of flow can be captured with 'ovs-dpctl dump-flows'.
    [Arguments]    ${list}    ${eth_type}
    Append To List    ${list}    "eth_type(${eth_type})"

Append Tunnel Set Check
    [Documentation]    Tunnel ID is locally significant to neighbouring nodes and it is not
    ...    statically determined. By checking it's presence in match ( or action) fields,
    ...    we can say whether a packet was received (or send out) via tunnel port.
    [Arguments]    ${list}
    Append To List    ${list}    tun_id

Append Tunnel Not Set Check
    [Documentation]    Tunnel ID is locally significant to neighbouring nodes and it is not
    ...    statically determined. By checking it's presence in match ( or action) fields,
    ...    we can say whether a packet was received (or send out) via tunnel port.
    [Arguments]    ${list}
    Append To List    ${list}    -v tun_id

Get NSP Value From Flow
    [Documentation]    Reads and returns nsp value from flow captured with 'ovs-dpctl dump-flows'.
    [Arguments]    ${flow}
    ${flow}    Get Actions Part    ${flow}
    ${output}    OperatingSystem.Run    echo "\$${flow}" | sed 's/.*nsp=/nsp=/' | sed 's/,.*//' | sed 's/.*=//'
    RETURN    ${output}

Manager is Connected
    ${output}    SSHLibrary.Execute Command    sudo ovs-vsctl show
    Should Contain    ${output}    is_connected: true

Manager and Switch Connected
    [Arguments]    ${sw_name}
    ${output}    SSHLibrary.Execute Command    sudo ovs-vsctl show
    Should Contain    ${output}    ${sw_name}
    Should Contain x Times    ${output}    is_connected: true    2

Wait For Flows On Switch
    [Documentation]    Counts flows on switch, fails if 0
    [Arguments]    ${switch_ip}    ${switch_name}
    ConnUtils.Connect and Login    ${switch_ip}
    # check for OVS errors first
    ${stdout}    ${stderr}    SSHLibrary.Execute Command
    ...    sudo ovs-ofctl dump-flows ${switch_name} -OOpenFlow13
    ...    return_stderr=True
    IF    "${stderr}" != "${EMPTY}"    Fatal Error    ${stderr}
    Wait Until Keyword Succeeds    120s    20s    Count Flows On Switch    ${switch_name}
    SSHLibrary.Close Connection

Show Switch Status
    [Documentation]    Shows status of a switch for easier debugging.
    [Arguments]    ${switch_name}
    ${stdout}    ${stderr}    SSHLibrary.Execute Command
    ...    sudo ovs-ofctl dump-flows ${switch_name} -OOpenFlow13
    ...    return_stderr=True
    Log    ${stdout}
    ${stdout}    ${stderr}    SSHLibrary.Execute Command    sudo ovs-vsctl show    return_stderr=True
    Log    ${stdout}

Count Flows On Switch
    [Arguments]    ${switch_name}
    ${out}    SSHLibrary.Execute Command
    ...    printf "%d" $(($(sudo ovs-ofctl dump-flows ${switch_name} -OOpenFlow13 | wc -l)-1))
    Should Be True    ${out}>0

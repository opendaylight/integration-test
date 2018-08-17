*** Settings ***
Documentation     Robot wrapper around ODLTools.
Resource          ../variables/Variables.robot

*** Keywords ***
Version
    [Documentation]    Get the odltools version
    ${cmd} =    BuiltIn.Set Variable    odltools -V
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Log    rc: ${rc}, output: ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    [Return]    ${output}

Get EOS
    [Arguments]    ${node_ip}=${TOOLS_SYSTEM_IP}    ${port}=${RESTCONFPORT}    ${test_name}=${SUITE_NAME}.${TEST_NAME}
    [Documentation]    Get the various ODL entity ownership information
    ${cmd} =    BuiltIn.Set Variable    odltools show eos -i ${node_ip} -t ${port} -u ${ODL_RESTCONF_USER} -w ${ODL_RESTCONF_PASSWORD} --path /tmp/${test_name}
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Log    rc: ${rc}, output: ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    [Return]    ${output}

Get Cluster Info
    [Arguments]    ${port}=${RESTCONFPORT}
    [Documentation]    Get ODL Cluster related information like transaction counts, commit rates etc
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${cmd} =    BuiltIn.Set Variable    odltools show cluster-info -i ${ODL_SYSTEM_${i+1}_IP} -t ${port} -u ${ODL_RESTCONF_USER} -w ${ODL_RESTCONF_PASSWORD}
    \    ${output} =    OperatingSystem.Run    ${cmd}
    \    BuiltIn.Log    output: ${output}

Analyze Tunnels
    [Arguments]    ${node_ip}=${TOOLS_SYSTEM_IP}    ${port}=${RESTCONFPORT}    ${test_name}=${SUITE_NAME}.${TEST_NAME}
    [Documentation]    Analyze Tunnel Mesh creation for any errorsand log results
    ${cmd} =    BuiltIn.Set Variable    odltools analyze tunnels -i ${node_ip} -t ${port} -u ${ODL_RESTCONF_USER} -w ${ODL_RESTCONF_PASSWORD} --path /tmp/${test_name}
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Log    rc: ${rc}, output: ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    [Return]    ${output}

Get All
    [Arguments]    ${node_ip}=${TOOLS_SYSTEM_IP}    ${port}=${RESTCONFPORT}
    [Documentation]    Get all results provided by ODLTools
    ODLTools.Get Cluster Info
    BuiltIn.run Keyword And Ignore Error    ODLTools.Get EOS    ${HA_PROXY_IP}
    BuiltIn.run Keyword And Ignore Error    ODLTools.Analyze Tunnels    ${HA_PROXY_IP}

*** Settings ***
Documentation     Robot wrapper around ODLTools.
Library           OperatingSystem
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
    [Arguments]    ${node_ip}=${ODL_SYSTEM_IP}    ${port}=${RESTCONFPORT}    ${test_name}=${SUITE_NAME}.${TEST_NAME}
    [Documentation]    Get the various ODL entity ownership information
    ${dstdir} =    Get Path    ${test_name}
    ${cmd} =    BuiltIn.Set Variable    odltools netvirt show eos -i ${node_ip} -t ${port} -u ${ODL_RESTCONF_USER} -w ${ODL_RESTCONF_PASSWORD} --path ${dstdir}
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Log    rc: ${rc}, output: ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    [Return]    ${output}

Get Cluster Info
    [Arguments]    ${port}=${RESTCONFPORT}
    [Documentation]    Get ODL Cluster related information like transaction counts, commit rates, etc.
    FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
        ${cmd} =    BuiltIn.Set Variable    odltools netvirt show cluster-info -i ${ODL_SYSTEM_${i+1}_IP} -t ${port} -u ${ODL_RESTCONF_USER} -w ${ODL_RESTCONF_PASSWORD}
        ${output} =    OperatingSystem.Run    ${cmd}
        BuiltIn.Log    output: ${output}
    END

Analyze Tunnels
    [Arguments]    ${node_ip}=${ODL_SYSTEM_IP}    ${port}=${RESTCONFPORT}    ${test_name}=${SUITE_NAME}.${TEST_NAME}
    [Documentation]    Analyze Tunnel Mesh creation for any errors and log results
    ${dstdir} =    Get Path    ${test_name}
    ${cmd} =    BuiltIn.Set Variable    odltools netvirt analyze tunnels -i ${node_ip} -t ${port} -u ${ODL_RESTCONF_USER} -w ${ODL_RESTCONF_PASSWORD} --path ${dstdir}
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Log    rc: ${rc}, output: ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    [Return]    ${output}

Get All
    [Arguments]    ${node_ip}=${ODL_SYSTEM_IP}    ${port}=${RESTCONFPORT}    ${test_name}=${SUITE_NAME}.${TEST_NAME}
    [Documentation]    Get all results provided by ODLTools
    ODLTools.Get Cluster Info
    BuiltIn.run Keyword And Ignore Error    ODLTools.Get EOS    ${node_ip}    test_name=${test_name}
    BuiltIn.run Keyword And Ignore Error    ODLTools.Analyze Tunnels    ${node_ip}    test_name=${test_name}

Get Path
    [Arguments]    ${test_name}=${SUITE_NAME}.${TEST_NAME}
    [Documentation]    Get odltools path for a given test case
    ${tmpdir} =    BuiltIn.Evaluate    """${test_name}""".replace(" ","_").replace("/","_").replace(".","_").replace("(","_").replace(")","_")
    [Return]    /tmp/${tmpdir}

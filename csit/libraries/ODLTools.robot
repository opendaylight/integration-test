*** Settings ***
Documentation       Robot wrapper around ODLTools.

Library             OperatingSystem
Resource            ../variables/Variables.robot


*** Keywords ***
Version
    [Documentation]    Get the odltools version
    ${cmd} =    BuiltIn.Set Variable    odltools -V
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Log    rc: ${rc}, output: ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    RETURN    ${output}

Get EOS
    [Documentation]    Get the various ODL entity ownership information
    [Arguments]    ${node_ip}=${ODL_SYSTEM_IP}    ${port}=${RESTCONFPORT}    ${test_name}=${SUITE_NAME}.${TEST_NAME}
    ${dstdir} =    Get Path    ${test_name}
    ${cmd} =    BuiltIn.Set Variable
    ...    odltools netvirt show eos -i ${node_ip} -t ${port} -u ${ODL_RESTCONF_USER} -w ${ODL_RESTCONF_PASSWORD} --path ${dstdir}
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Log    rc: ${rc}, output: ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    RETURN    ${output}

Get Cluster Info
    [Documentation]    Get ODL Cluster related information like transaction counts, commit rates, etc.
    [Arguments]    ${port}=${RESTCONFPORT}
    FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
        ${cmd} =    BuiltIn.Set Variable
        ...    odltools netvirt show cluster-info -i ${ODL_SYSTEM_${i+1}_IP} -t ${port} -u ${ODL_RESTCONF_USER} -w ${ODL_RESTCONF_PASSWORD}
        ${output} =    OperatingSystem.Run    ${cmd}
        BuiltIn.Log    output: ${output}
    END

Analyze Tunnels
    [Documentation]    Analyze Tunnel Mesh creation for any errors and log results
    [Arguments]    ${node_ip}=${ODL_SYSTEM_IP}    ${port}=${RESTCONFPORT}    ${test_name}=${SUITE_NAME}.${TEST_NAME}
    ${dstdir} =    Get Path    ${test_name}
    ${cmd} =    BuiltIn.Set Variable
    ...    odltools netvirt analyze tunnels -i ${node_ip} -t ${port} -u ${ODL_RESTCONF_USER} -w ${ODL_RESTCONF_PASSWORD} --path ${dstdir}
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Log    rc: ${rc}, output: ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    RETURN    ${output}

Get All
    [Documentation]    Get all results provided by ODLTools
    [Arguments]    ${node_ip}=${ODL_SYSTEM_IP}    ${port}=${RESTCONFPORT}    ${test_name}=${SUITE_NAME}.${TEST_NAME}
    ODLTools.Get Cluster Info
    BuiltIn.run Keyword And Ignore Error    ODLTools.Get EOS    ${node_ip}    test_name=${test_name}
    BuiltIn.run Keyword And Ignore Error    ODLTools.Analyze Tunnels    ${node_ip}    test_name=${test_name}

Get Path
    [Documentation]    Get odltools path for a given test case
    [Arguments]    ${test_name}=${SUITE_NAME}.${TEST_NAME}
    ${tmpdir} =    BuiltIn.Evaluate
    ...    """${test_name}""".replace(" ","_").replace("/","_").replace(".","_").replace("(","_").replace(")","_")
    RETURN    /tmp/${tmpdir}

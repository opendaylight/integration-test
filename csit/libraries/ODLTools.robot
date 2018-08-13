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
    [Arguments]    ${node_ip}=${TOOLS_SYSTEM_IP}    ${port}=${RESTCONFPORT}
    [Documentation]    Get the odltools version
    ${cmd} =    BuiltIn.Set Variable    odltools show eos -i ${node_ip} -t ${port} -u ${ODL_RESTCONF_USER} -w ${ODL_RESTCONF_PASSWORD}
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Log    rc: ${rc}, output: ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    [Return]    ${output}

Get Cluster Info
    [Arguments]    ${port}=${RESTCONFPORT}
    [Documentation]    Get ODL Cluster related information like transaction counts, commit rates etc
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
        \    ${cmd} =    BuiltIn.Set Variable    odltools show cluter-info -i ${ODL_SYSTEM_${i+1}_IP} -t ${port} -u ${ODL_RESTCONF_USER} -w ${ODL_RESTCONF_PASSWORD}
        \    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
        \    BuiltIn.Log    rc: ${rc}, output: ${output}
        \    BuiltIn.Should Be True    '${rc}' == '0'

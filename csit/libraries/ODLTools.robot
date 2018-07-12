*** Settings ***
Documentation     Robot wrapper around ODLTools.

*** Keywords ***
Version
    [Documentation]    Get the odltools version
    ${cmd} =    BuiltIn.Set Variable    odltools -V
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Log    rc: ${rc}, output: ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    [Return]    ${output}

Get EOS
    [Documentation]    Get the odltools version
    [Arguments]    ${node_ip}=${TOOLS_SYSTEM_IP}    ${port}=${RESTCONFPORT}
    ${cmd} =    BuiltIn.Set Variable    odltools show eos -i ${node_ip} -t {port} -u admin -w admin --path /tmp/odtmodels
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Log    rc: ${rc}, output: ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    [Return]    ${output}

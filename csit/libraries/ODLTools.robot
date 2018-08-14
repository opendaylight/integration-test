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
    [Documentation]    Get the various ODL entity ownership information
    ${cmd} =    BuiltIn.Set Variable    odltools show eos -i ${node_ip} -t ${port} -u ${ODL_RESTCONF_USER} -w ${ODL_RESTCONF_PASSWORD}
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Log    rc: ${rc}, output: ${output}
    BuiltIn.Should Be True    '${rc}' == '0'
    [Return]    ${output}

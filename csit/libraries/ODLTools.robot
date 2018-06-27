*** Settings ***
Documentation     Robot wrapper around ODLTools.

*** Keywords ***
Version
[Documentation]    Get the odltools version
    ${cmd} =    BuiltIn.Set Variable    odltools -V
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Log    rc: ${rc}, output: ${output}
    # BuiltIn.Should Be True    '${rc}' == '0'
    [Return]    ${output}

Version 2
[Documentation]    Get the odltools version
    ${cmd} =    BuiltIn.Set Variable    python -m odltools -V
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    ${cmd}
    BuiltIn.Log    rc: ${rc}, output: ${output}
    # BuiltIn.Should Be True    '${rc}' == '0'
    [Return]    ${output}

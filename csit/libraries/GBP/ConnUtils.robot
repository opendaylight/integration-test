*** Settings ***
Library           SSHLibrary
Resource          ../Utils.robot

*** Variables ***
${VE_DIR}    ${WORKSPACE}/GBPSFC_VE

*** Keywords ***
Connect and Login
    [Arguments]    ${ip}    ${timeout}==3s
    SSHLibrary.Open Connection    ${ip}    timeout=${timeout}
    Utils.Flexible Mininet Login

Execute in VE
    [Arguments]    ${cmd}    ${virt_env_path}=${VE_DIR}    ${timeout}==3s
    # TODO timeout
    ${stderr}    SSHLibrary.Execute Command    source ${virt_env_path}/bin/activate;${cmd}    return_stderr=True    return_stdout=False    return_rc=False
    Log    ${stderr}
    #TODO return output and rc as well
    [Return]    ${stderr}


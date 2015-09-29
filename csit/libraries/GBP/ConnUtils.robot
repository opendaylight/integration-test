*** Settings ***
Library           SSHLibrary
Resource          ../Utils.robot


*** Variables ***


*** Keywords ***
Connect and Login
    [Arguments]    ${ip}    ${timeout}==3s
    SSHLibrary.Open Connection    ${ip}    timeout=${timeout}
    Utils.Flexible Mininet Login

Execute Command in VE
    [Arguments]    ${command}    ${virt_env_path}=${VIRT_ENV_DIR}
    SSHLibrary.Write    source ${virt_env_path}/bin/activate
    ${output}    SSHLibrary.Read Until    )${MININET_USER}@
    SSHLibrary.Write    ${command}
    ${output}    SSHLibrary.Read Until    )${MININET_USER}@
    SSHLibrary.Write    deactivate
    ${output}    SSHLibrary.Read Until    ${MININET_USER}@

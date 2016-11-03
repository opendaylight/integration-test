*** Settings ***
Library           SSHLibrary
Library           OperatingSystem
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/GBP/ConnUtils.robot
Variables         ../../../variables/Variables.py
Resource          Variables.robot

*** Keywords ***
Register Node
    [Arguments]    ${VPP_NAME}    ${VPP_IP}
    [Documentation]    Write node to netconf topology in ODL datastore
    ConnUtils.Connect and Login    ${VPP_IP}    timeout=10s
    ${out}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/register_vpp_node.sh ${ODL_SYSTEM_1_IP} ${RESTCONFPORT} ${ODL_RESTCONF_USER} ${ODL_RESTCONF_PASSWORD} ${VPP_NAME} ${VPP_IP}
    Log    ${out}
    SSHLibrary.Close Connection
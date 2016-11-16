*** Settings ***
Suite Setup       Start Connections
Library           SSHLibrary    60 seconds
Resource          ../Variables.robot
Resource          ../Connections.robot
Resource          ../../../../libraries/KarafKeywords.robot
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBP/DockerUtils.robot
Resource          ../../../../libraries/GBP/ConnUtils.robot

*** Test Cases ***
Inicilaize ODL
    Set Suite Variable    ${ODL_SYSTEM_IP}    ${GBP_MASTER_IP}
    Register Node    controller    ${VPP1}
    Wait For Karaf Log    controller is capable and ready    karaf_ip=${ODL_SYSTEM_IP}
    Register Node    compute0    ${VPP2}
    Wait For Karaf Log    compute0 is capable and ready    karaf_ip=${ODL_SYSTEM_IP}
    Register Node    compute1    ${VPP3}
    Wait For Karaf Log    compute1 is capable and ready    karaf_ip=${ODL_SYSTEM_IP}
    Add Elements To URI From File And Verify    "http://"+${ODL_SYSTEM_IP}+":"+${RESTCONFPORT} +"/restconf/config/neutron:neutron"    ${NEUTRON_FILE}
    Wait For Karaf Log    Renderer updated renderer policy to version    karaf_ip=${ODL_SYSTEM_IP}
    ConnUtils.Connect and Login    ${VPP2}    timeout=10s
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br1 tap00000000-01
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br1 tap00000000-02
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br2 tap00000000-03
    ConnUtils.Connect and Login    ${VPP3}    timeout=10s
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br1 tap00000000-01
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br1 tap00000000-02
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br2 tap00000000-03
    Switch Connection    VPP1_CONNECTION
    Ping From Docker    docker1    10.100.0.3

*** Keywords ***
Register Node
    [Arguments]    ${VPP_NAME}    ${VPP_IP}
    [Documentation]    Write node to netconf topology in ODL datastore
    ConnUtils.Connect and Login    ${VPP_IP}    timeout=10s
    ${out}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/register_vpp_node.sh ${ODL_SYSTEM_1_IP} ${RESTCONFPORT} ${ODL_RESTCONF_USER} ${ODL_RESTCONF_PASSWORD} ${VPP_NAME} ${VPP_IP}
    Log    ${out}
    SSHLibrary.Close Connection
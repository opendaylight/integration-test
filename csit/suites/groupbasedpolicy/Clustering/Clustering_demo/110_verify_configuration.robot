*** Settings ***
Suite Setup       Start Connections
Library           SSHLibrary    120 seconds
Library           RequestsLibrary
Resource          ../Variables.robot
Resource          ../Connections.robot
Resource          ../../../../libraries/KarafKeywords.robot
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBP/ConnUtils.robot

*** Test Cases ***
Verify Setup
    Set Suite Variable    ${ODL_SYSTEM_IP}    ${GBP_MASTER_IP}
    Wait For Karaf Log    controller is capable and ready    karaf_ip=${ODL_SYSTEM_IP}
    Wait For Karaf Log    compute0 is capable and ready    karaf_ip=${ODL_SYSTEM_IP}
    Wait For Karaf Log    compute1 is capable and ready    karaf_ip=${ODL_SYSTEM_IP}
    Wait For Karaf Log    Renderer updated renderer policy to version    karaf_ip=${ODL_SYSTEM_IP}
    Switch Connection    VPP2_CONNECTION
    Wait Until Keyword Succeeds    5x    10 sec    Check Ports
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br1 tap00000000-01
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br2 tap00000000-02
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br3 tap00000000-03
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh int
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh br
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh br 1 det
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh br 2 det
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh vxlan tunnel
    Log    ${out}
    Switch Connection    VPP3_CONNECTION
    Wait Until Keyword Succeeds    5x    10 sec    Check Ports
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br1 tap00000000-01
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br2 tap00000000-02
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br3 tap00000000-03
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh int
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh br
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh br 1 det
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh br 2 det
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh vxlan tunnel
    Log    ${out}

*** Keywords ***
Register Node
    [Arguments]    ${VPP_NAME}    ${VPP_IP}
    [Documentation]    Write node to netconf topology in ODL datastore
    ConnUtils.Connect and Login    ${VPP_IP}    timeout=10s
    ${out}    SSHLibrary.Execute Command    ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/register_vpp_node.sh ${ODL_SYSTEM_1_IP} ${RESTCONFPORT} ${ODL_RESTCONF_USER} ${ODL_RESTCONF_PASSWORD} ${VPP_NAME} ${VPP_IP}
    Log    ${out}
    SSHLibrary.Close Connection

Check Ports
    [Documentation]    Checks whether all port are already present
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh int
    Log    ${out}
    Should Contain    ${out}    tap-1
    Should Contain    ${out}    tap-2
    Should Contain    ${out}    tap-3
    Should Contain    ${out}    vxlan_tunnel0
    Should Contain    ${out}    vxlan_tunnel1
    Should Contain    ${out}    vxlan_tunnel2
    Should Contain    ${out}    vxlan_tunnel3
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh br
    Should Contain    ${out}    1
    Should Contain    ${out}    2
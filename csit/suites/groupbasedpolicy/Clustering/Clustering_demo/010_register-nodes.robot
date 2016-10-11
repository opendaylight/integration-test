*** Settings ***
Resource          ../Variables.robot
Resource          ../Nodes.robot

*** Test Cases ***
Register Nodes
    Register Node    controller    ${VPP1}
    Register Node2    compute0    ${VPP2}
    Register Node    compute1    ${VPP3}

*** Keywords ***
Register Node
    [Arguments]    ${VPP_NAME}    ${VPP_IP}
    [Documentation]    Write node to netconf topology in ODL datastore
    ${out}    Run    ../register_vpp_node.sh ${ODL_SYSTEM_1_IP} ${RESTCONFPORT} ${ODL_RESTCONF_USER} ${ODL_RESTCONF_PASSWORD} ${VPP_NAME} ${VPP_IP}
    Log    ${out}
    Log    ${CURDIR}
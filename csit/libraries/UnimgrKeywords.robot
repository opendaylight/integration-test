*** Settings ***
Documentation     Unimgr keywords defination that will be used in Unimgr suite.
Library           OperatingSystem
Library           SSHLibrary
Library           String
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${Bridge_Name}    ovsbr0
${UniMgr_Variables_DIR}    ../variables/unimgr

*** Keywords ***
Setup Unimgr Test Environment
    [Documentation]    Establish the Opendayligh session and prepair the Mininet VMs
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Prepair Unimgr Test Environment    ${TOOLS_SYSTEM_IP}
    Prepair Unimgr Test Environment    ${TOOLS_SYSTEM_2_IP}

Prepair Unimgr Test Environment
    [Arguments]    ${Mininet_IP}
    [Documentation]    delete the ovs bridge and manager then set the manager to a passive mode ptcp:6640.
    Run Command On Remote System    ${Mininet_IP}    sudo ovs-vsctl del-manager
    Run Command On Remote System    ${Mininet_IP}    sudo ovs-vsctl del-br ${Bridge_Name}
    Run Command On Remote System    ${Mininet_IP}    sudo ovs-vsctl set-manager ptcp:${OVSDBPORT}
    ${stdout}=    Run Command On Remote System    ${Mininet_IP}    sudo ovs-vsctl show
    Should Contain    ${stdout}    "ptcp:${OVSDBPORT}"

Get Add Uni Json
    [Arguments]    ${IP-Address}    ${MAC-Address}
    [Documentation]    read the add_uni.json file and replace the IPaddress and MACaddress with the give arguments.
    ${json}    OperatingSystem.Get File    ${UniMgr_Variables_DIR}/add_uni.json
    ${temp}    Replace String    ${json}    {mac-address}    ${MAC-Address}
    ${uniJson}    Replace String    ${temp}    {uni-ip}    ${IP-Address}
    [Return]    ${uniJson}

Get Add Evc Json
    [Arguments]    ${UNI1-IP}    ${UNI2-IP}
    [Documentation]    read the add_evc.json file and replace the IP-address with the give arguments.
    ${Json}    OperatingSystem.Get File    ${UniMgr_Variables_DIR}/add_evc.json
    ${temp}    Replace String    ${Json}    {uni1-ip}    ${UNI1-IP}
    ${evcJson}    Replace String    ${temp}    {uni2-ip}    ${UNI2-IP}
    [Return]    ${evcJson}

*** Settings ***
Library           SSHLibrary
Resource          ../Variables.robot
Resource          ../GBPVPP_setup.robot
Resource          ../../../../libraries/GBP/ConnUtils.robot

*** Test Cases ***
Initialize Nodes
    Setup Nodes    ${VPPs}    ${CURDIR}/init_scripts

*** Keywords ***
Setup ODL Schema
    [Arguments]    ${ODL_IP}    ${schema_dir}
    [Documentation]    Copy models to avoid netconf initialization
    ConnUtils.Connect and Login    ${ODL_IP}    timeout=10s
    SSHLibrary.Put Directory    ${schema_dir}    ${WORKSPACE}/${BUNDLEFOLDER}/cache    mode=0755

*** Settings ***
Library           SSHLibrary
Resource          ../Variables.robot
Resource          ../GBPVPP_setup.robot
Resource          ../../../../libraries/GBP/ConnUtils.robot

*** Test Cases ***
Initialize Nodes
    Setup Nodes    ${VPPs}    ${CURDIR}/init_scripts
    Setup ODL Schema    ${ODL_SYSTEM_1_IP}    ${CURDIR}/hc-schema
    Setup ODL Schema    ${ODL_SYSTEM_2_IP}    ${CURDIR}/hc-schema
    Setup ODL Schema    ${ODL_SYSTEM_3_IP}    ${CURDIR}/hc-schema

***Keywords***
Setup ODL Schema
    [Arguments]    ${ODL_IP}    ${schema_dir}
    [Documentation]    Copy models to avoid netconf initialization
    ConnUtils.Connect and Login    ${GBPVPP}    timeout=${timeout}
    SSHLibrary.Put Directory    ${schema_dir}    ${WORKSPACE}/${BUNDLEFOLDER}/cache    mode=0755

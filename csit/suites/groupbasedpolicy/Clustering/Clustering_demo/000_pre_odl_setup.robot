*** Settings ***
Library           SSHLibrary
Resource          ../Variables.robot
Resource          ../GBPVPP_setup.robot
Resource          ../../../../libraries/GBP/ConnUtils.robot

*** Test Cases ***
Initialize Nodes
    Setup Nodes    ${VPPs}    ${CURDIR}/init_scripts


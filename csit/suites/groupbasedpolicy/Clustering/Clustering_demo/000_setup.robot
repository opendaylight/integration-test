*** Settings ***
Resource          ../Variables.robot
Resource          ../GBPVPP_setup.robot

*** Test Cases ***
Initialize Nodes
    Setup Nodes    ${VPPs}    ${CURDIR}/init_scripts

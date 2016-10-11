*** Settings ***
Resource          ../Variables.robot
Resource          ../GBPVPP_setup.robot
Resource          ../Connections.robot

*** Test Cases ***
Initialize Nodes
    Setup Nodes    ${VPPs}    ${CURDIR}/init_scripts
    Start Connections

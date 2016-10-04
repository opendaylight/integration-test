*** Settings ***
Resource          ../Variables.robot
Resource          ../GBPVPP_setup.robot

*** Test Cases ***
Initialize Nodes
    Setup Nodes    ${GBPVPPs}    ${CURDIR}/init_scripts

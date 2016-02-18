*** Settings ***
Resource          ../Variables.robot
Resource          ../GBPSFC_6node.robot

*** Test Cases ***
Initialize Nodes
    Setup Nodes    ${GBPSFCs}    ${CURDIR}/init_scripts

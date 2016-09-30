*** Settings ***
Resource          ${CURDIR}/../Variables.robot
Resource          ${CURDIR}/../GBPSFC_6node.robot

*** Test Cases ***
Initialize Nodes
    Setup Nodes    ${GBPSFCs}    ${CURDIR}/init_scripts

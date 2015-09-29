*** Settings ***
Documentation    Global variables for GBPSFC 6-node topology

*** Variables ***
${VM_HOME_FOLDER} =  /opt/jenkins
${VM_SCRIPTS_FOLDER} =  scripts
${GBP1}=    ${MININET}
${GBP2}=    ${MININET1}
${GBP3}=    ${MININET2}
@{GBPs} =    ${GBP1}    ${GBP2}    ${GBP3}
${VIRT_ENV_DIR} =    ${WORKSPACE}/GBPSFC_VE

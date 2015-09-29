*** Settings ***
Documentation    Global variables for GBPSFC 6-node topology

*** Variables ***
${VM_HOME_FOLDER} =  /opt/jenkins
${VM_SCRIPTS_FOLDER} =  scripts
${GBPSFC1} =    ${MININET}
${GBPSFC2} =    ${MININET1}
${GBPSFC3} =    ${MININET2}
${GBPSFC4} =    ${MININET3}
${GBPSFC5} =    ${MININET4}
${GBPSFC6} =    ${MININET5}
@{GBPSFCs} =    ${GBPSFC1}    ${GBPSFC2}    ${GBPSFC3}
...             ${GBPSFC4}    ${GBPSFC5}    ${GBPSFC6}
${VIRT_ENV_DIR}    ${WORKSPACE}/GBPSFC_VE

*** Settings ***
Documentation    Global variables for GBPSFC 6-node topology

*** Variables ***
${VM_HOME_FOLDER} =  /opt/jenkins
${VM_SCRIPTS_FOLDER} =  scripts
${ODL} =    ${ODL_SYSTEM_IP}
${GBPSFC1} =    ${TOOLS_SYSTEM_IP}
${GBPSFC2} =    ${TOOLS_SYSTEM_2_IP}
${GBPSFC3} =    ${TOOLS_SYSTEM_3_IP}
${GBPSFC4} =    ${TOOLS_SYSTEM_4_IP}
${GBPSFC5} =    ${TOOLS_SYSTEM_5_IP}
${GBPSFC6} =    ${TOOLS_SYSTEM_6_IP}
@{GBPSFCs} =    ${GBPSFC1}    ${GBPSFC2}    ${GBPSFC3}
...             ${GBPSFC4}    ${GBPSFC5}    ${GBPSFC6}
${VIRT_ENV_DIR}    ${WORKSPACE}/GBPSFC_VE

*** Settings ***
Documentation    Global variables for GBPSFC 6-node topology

*** Variables ***
#${VM_HOME_FOLDER} =  /opt/jenkins
${VM_HOME_FOLDER} =  /home/vagrant
${VM_SCRIPTS_FOLDER} =  scripts
${ODL} =    ${ODL_SYSTEM_IP}
${GBPSFC1} =    ${TOOLS_SYSTEM_IP}
${GBPSFC2} =    ${TOOLS_SYSTEM_2_IP}
${GBPSFC3} =    ${TOOLS_SYSTEM_3_IP}
@{GBPs} =    ${GBP1}    ${GBP2}    ${GBP3}
${VIRT_ENV_DIR} =    ${WORKSPACE}/GBPSFC_VE

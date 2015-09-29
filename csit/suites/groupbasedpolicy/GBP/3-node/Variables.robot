*** Settings ***
Documentation    Global variables for GBPSFC 6-node topology

*** Variables ***
#${VM_HOME_FOLDER} =  ${WORKSPACE}
${VM_HOME_FOLDER} =  /home/vagrant
${VM_SCRIPTS_FOLDER} =  scripts
# ${ODL} =     ${ODL_SYSTEM_IP}
# ${GBP1} =    ${TOOLS_SYSTEM_IP}
# ${GBP2} =    ${TOOLS_SYSTEM_2_IP}
# ${GBP3} =    ${TOOLS_SYSTEM_3_IP}
${ODL} =     ${CONTROLLER}
${GBP1} =    ${MININET}
${GBP2} =    ${MININET1}
${GBP3} =    ${MININET2}
@{GBPs} =    ${GBP1}    ${GBP2}    ${GBP3}

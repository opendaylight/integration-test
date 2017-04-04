*** Settings ***
Documentation     Global variables for GBPSFC 6node topology. Some variables are release specific and their value depend on
...               ODL_VERSION variable which contains release name and is defined in Jenkins job. Keywords for setting release specific
...               data are located in this file.
Variables         ../../../variables/Variables.py

*** Variables ***
${VM_HOME_FOLDER}       ${WORKSPACE}
${VM_SCRIPTS_FOLDER}    scripts
${VPP_NODE_1}           ${TOOLS_SYSTEM_1_IP}
${VPP_NODE_2}           ${TOOLS_SYSTEM_2_IP}
${VPP_NODE_3}           ${TOOLS_SYSTEM_3_IP}
@{VPP_NODES}            ${VPP_NODE_1}    ${VPP_NODE_2}    ${VPP_NODE_3}
${HONEYCOMB_LOG}        /var/log/honeycomb/honeycomb.log


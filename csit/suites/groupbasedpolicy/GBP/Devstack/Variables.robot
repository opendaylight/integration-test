*** Settings ***
Documentation     Global variables for GBPSFC 6node topology. Some variables are release specific and their value depend on
...               ODL_VERSION variable which contains release name and is defined in Jenkins job. Keywords for setting release specific
...               data are located in this file.
Variables         ../../../../variables/Variables.py

*** Variables ***
${BERYLLIUM_BOOT_URL}    restconf/config/neutron-mapper:mappings
${MASTER_BOOT_URL}    restconf/config/neutron-gbp-mapper:mappings
${OF_OVERLAY_BOOT_URL}    restconf/config/ofoverlay:of-overlay-config
${PROMPT_TIMEOUT}    ${DEFAULT_TIMEOUT}
${DEVSTACK_BRANCH}    ${OPENSTACK_BRANCH}
${DEVSTACK_IP}    ${TOOLS_SYSTEM_IP}
${DEVSTACK_USER}    ${TOOLS_SYSTEM_USER}
${DEVSTACK_PROMPT}    ${DEFAULT_LINUX_PROMPT}
# modify the below var for local testing
${DEVSTACK_DIR}    ${DEVSTACK_DEPLOY_PATH}
# modify the below var for local testing
${DEVSTACK_PWD}    ${EMPTY}

*** Settings ***
Documentation     Global variables for GBPSFC 6node topology. Some variables are release specific and their value depend on
...               ODL_VERSION variable which contains release name and is defined in Jenkins job. Keywords for setting release specific
...               data are located in this file.
Variables         ../../../../variables/Variables.py

*** Variables ***
${DEVSTACK_IP}           ${DEVSTACK_SYSTEM_IP}
${DEVSTACK_USER}         ${DEVSTACK_SYSTEM_USER}

# uncomment and specify the following variable for local testing
#${DEVSTACK_PWD}          ${DEVSTACK_SYSTEM_PASSWORD}

${DEVSTACK_PROMPT}       ${DEFAULT_LINUX_PROMPT}
${PROMPT_TIMEOUT}        30


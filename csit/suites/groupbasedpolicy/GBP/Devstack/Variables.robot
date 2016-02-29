*** Settings ***
Documentation     Global variables for GBPSFC 6node topology. Some variables are release specific and their value depend on
...               ODL_VERSION variable which contains release name and is defined in Jenkins job. Keywords for setting release specific
...               data are located in this file.
Variables         ../../../../variables/Variables.py

*** Variables ***
${DEVSTACK_IP}           ${DEVSTACK_SYSTEM_IP}
${DEVSTACK_USER}         ${DEVSTACK_SYSTEM_USER}
${DEVSTACK_PWD}          ${DEVSTACK_SYSTEM_PASSWORD}
${DEVSTACK_PROMPT}       ${DEFAULT_LINUX_PROMPT}
${PROMPT_TIMEOUT}        ${default_devstack_prompt_timeout}
${NETWORK_CLIENT_GROUP}  ccc5e444-573c-11e5-885d-feff819cdc9f
${UUID_NO_DASHES}        [0-9a-f]{8}[0-9a-f]{4}[0-9a-f]{4}[0-9a-f]{4}[0-9a-f]{12}
${UUID_PATTERN}          [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
${NAME_PATTERN}          [a-zA-Z]([a-zA-Z0-9\-_.])*

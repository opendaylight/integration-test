*** Settings ***
Documentation     Global variables for GBPSFC 6node topology. Some variables are release specific and their value depend on
...               ODL_VERSION variable which contains release name and is defined in Jenkins job. Keywords for setting release specific
...               data are located in this file.
Variables         ../../../../variables/Variables.py

*** Variables ***
${NEURONMAPPER_BOOT_URL}   restconf/config/neutron-mapper:mappings
${OF_OVERLAY_BOOT_URL}     restconf/config/ofoverlay:of-overlay-config
${PROMPT_TIMEOUT}          30
${DEVSTACK_BRANCH}         ${OPENSTACK_BRANCH}
${DEVSTACK_IP}             ${TOOLS_SYSTEM_IP}
${DEVSTACK_USER}           ${TOOLS_SYSTEM_USER}
${DEVSTACK_PROMPT}         ${DEFAULT_LINUX_PROMPT}
${KARAF_BOOT_WAIT_URL}     restconf/operational/network-topology:network-topology/topology/ovsdb:1
${KARAF_FEATURES}          odl-groupbasedpolicy-neutron-and-ofoverlay,odl-restconf
# modify the below var for local testing
${ODL_IP}                  ${CONTROLLER}
# modify the below var for local testing
${DEVSTACK_DIR}            /opt/stack/new/devstack
# modify the below var for local testing
${DEVSTACK_PWD}

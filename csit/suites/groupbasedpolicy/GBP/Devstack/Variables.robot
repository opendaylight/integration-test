*** Settings ***
Documentation     Global variables for GBPSFC 6node topology. Some variables are release specific and their value depend on
...               ODL_VERSION variable which contains release name and is defined in Jenkins job. Keywords for setting release specific
...               data are located in this file.
Variables         ../../../../variables/Variables.py

*** Variables ***
${NEURONMAPPER_BOOT_URL}   restconf/config/neutron-mapper:mappings
${OF_OVERLAY_BOOT_URL}     restconf/config/ofoverlay:of-overlay-config
${DEVSTACK_CONN_ALIAS}     devstack_conn
${PROMPT_TIMEOUT}          30
${DEVSTACK_BRANCH}         ${OPENSTACK_BRANCH}
${DEVSTACK_IP}             ${DEVSTACK_SYSTEM_IP}
${DEVSTACK_USER}           ${DEVSTACK_SYSTEM_USER}
${DEVSTACK_PROMPT}         ${DEFAULT_LINUX_PROMPT}
${KARAF_FEATURES}          odl-base-all,odl-restconf-all,odl-aaa-authn,odl-dlux-core,odl-mdsal-apidocs,odl-adsal-northbound,odl-nsf-all,odl-ovsdb-northbound,odl-groupbasedpolicy-neutronmapper
# modify the below var for local testing
${ODL_IP}                  ${DEVSTACK_SYSTEM_IP}
# modify the below var for local testing
${DEVSTACK_DIR}            /opt/stack/new/devstack
# modify the below var for local testing
${DEVSTACK_PWD}
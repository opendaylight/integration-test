*** Settings ***
Documentation     Resource consisting purely of variable definitions useful for multiple project suites.

*** Variables ***
${CANCEL_EXPORT_URL}    /restconf/operations/data-export-import:cancel-export
${EXPORT_FILE}    ${CURDIR}/schedule_export.json
${EXP_DIR}        /tmp/Export
${EXPORT_EXCLUDE_FILE}    ${CURDIR}/schedule_export_exclude.json
${SCHEDULE_EXPORT_URL}    /restconf/operations/data-export-import:schedule-export
${EXP_DATA_FILE}    odl_backup_config.json
${EXP_OPER_FILE}    odl_backup_operational.json
${MODELS_FILE}    odl_backup_models.json
${STATUS_EXPORT_URL}    /restconf/operations/data-export-import:status-export
${NETCONF_PAYLOAD_JSON}    ../variables/daexim/netconf_mount.json
${NETCONF_MOUNT_URL}    /restconf/config/network-topology:network-topology/topology/topology-netconf/node/
${TOPOLOGY_URL}    /restconf/config/network-topology:network-topology/
${NETCONF_EP_NAME}    CONTROLLER1
${EXPORT_INITIAL_STATUS}    initial
${EXPORT_SCHEDULED_STATUS}    scheduled
${EXPORT_COMPLETE_STATUS}    complete
${FIRST_CONTROLLER_INDEX}    1
${SECOND_CONTROLLER_INDEX}    2
${THIRD_CONTROLLER_INDEX}    3
${NTCF_TPLG_OPR_URL}    /restconf/operational/network-topology:network-topology/topology/topology-netconf/node/
${NETCONF_PORT}    1830
${NTCF_OPR_STATUS}    connected
${DAEXIM_DATA_DIRECTORY}    ../variables/daexim/daexim
${MDL_DEF_FLAG}    false
${STR_DEF_FLAG}    data
${IMPORT_PAYLOAD}    ../variables/daexim/import.json
${IMPORT_URL}     /restconf/operations/data-export-import:immediate-import

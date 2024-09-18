*** Settings ***
Documentation       Resource consisting purely of variable definitions useful for multiple project suites.


*** Variables ***
${CANCEL_EXPORT_URL}                /rests/operations/data-export-import:cancel-export
${EXPORT_FILE}                      ${CURDIR}/schedule_export.json
${EXPORT_INCLUDE_FILE}              ${CURDIR}/schedule_export_include.json
${EXP_DIR}                          /tmp/Export
${EXPORT_EXCLUDE_FILE}              ${CURDIR}/schedule_export_exclude.json
${EXPORT_INCEXCLUDE_FILE}           ${CURDIR}/schedule_export_include_exclude.json
${SCHEDULE_EXPORT_URL}              /rests/operations/data-export-import:schedule-export
${EXP_DATA_FILE}                    odl_backup_config.json
${EXP_OPER_FILE}                    odl_backup_operational.json
${MODELS_FILE}                      odl_backup_models.json
${STATUS_EXPORT_URL}                /rests/operations/data-export-import:status-export
${NETCONF_PAYLOAD_JSON}             ../variables/daexim/netconf_mount.json
${NETCONF_NODE_URL}                 /rests/data/network-topology:network-topology/topology=topology-netconf/node
${TOPOLOGY_URL}                     /rests/data/network-topology:network-topology
${NETCONF_EP_NAME}                  CONTROLLER1
${EXPORT_INITIAL_STATUS}            initial
${EXPORT_SCHEDULED_STATUS}          scheduled
${EXPORT_COMPLETE_STATUS}           complete
${EXPORT_SKIPPED_STATUS}            skipped
${FIRST_CONTROLLER_INDEX}           1
${SECOND_CONTROLLER_INDEX}          2
${THIRD_CONTROLLER_INDEX}           3
${NETCONF_PORT}                     1830
${NTCF_OPR_STATUS}                  connected
${DAEXIM_DATA_DIRECTORY_CALCIUM}    ../variables/daexim/calcium/daexim
${DAEXIM_DATA_DIRECTORY_SCANDIUM}   ../variables/daexim/scandium/daexim
${MDL_DEF_FLAG}                     false
${STR_DEF_FLAG}                     data
${IMPORT_PAYLOAD_CALCIUM}           ../variables/daexim/calcium/import.json
${IMPORT_PAYLOAD_SCANDIUM}          ../variables/daexim/scandium/import.json
${IMPORT_URL}                       /rests/operations/data-export-import:immediate-import

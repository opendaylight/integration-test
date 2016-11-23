*** Settings ***
Documentation     Resource consisting purely of variable definitions useful for multiple project suites.

*** Variables ***
${CANCEL_BACKUP_URL}    /restconf/operations/data-export-import:cancel-export
${BACKUP_FILE}    ${CURDIR}/schedule_backup.json
${BKP_DIR}        /tmp/Backup
${BACKUP_EXCLUDE_FILE}    ${CURDIR}/schedule_backup_exclude.json
${SCHEDULE_BACKUP_URL}    /restconf/operations/data-export-import:schedule-export
${BKP_DATA_FILE}    odl_backup_config.json
${BKP_OPER_FILE}    odl_backup_operational.json
${MODELS_FILE}    odl_backup_models.json
${STATUS_BACKUP_URL}    /restconf/operations/data-export-import:status-export

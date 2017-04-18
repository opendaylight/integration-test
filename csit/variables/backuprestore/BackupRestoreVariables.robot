*** Settings ***
Documentation     Resource consisting purely of variable definitions useful for multiple project suites.

*** Variables ***
${EXP_DIR}        /tmp/Export
${EXP_DATA_FILE}    odl_backup_config.json
${EXP_OPER_FILE}    odl_backup_operational.json
${RELATIVE_BEFORE_BACKUP_DIR}    beforeBackup
${RELATIVE_AFTER_RESTORE_DIR}    afterRestore

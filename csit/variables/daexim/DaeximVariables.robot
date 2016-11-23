*** Settings ***
Documentation     Resource consisting purely of variable definitions useful for multiple project suites.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               These variables are considered global and immutable, so their names are in ALL_CAPS.
...
...               If a variable is only specific to few projects, define it in csit/variables/{project}/Variables.robot file instead.
...               If a variable only affects few Resources, define it in csit/libraries/{resource}.robot file instead.
...
...               Please include a short comment on why the variable is useful and why particular value was chosen.
...               Also a well-known variables provided by releng/builder script should be listed here,
...               the value should be a reasonable default.
...
...               Use ODL_SYSTEM instead of CONTROLLER and TOOLS_SYSTEM instead of MININET when referring to VMs.

*** Variables ***
${CANCEL_BACKUP_URL}    /restconf/operations/data-export-import:cancel-export
${BACKUP_FILE}    ${CURDIR}/schedule_backup.json
${BKP_DIR}      /tmp/Backup
${BACKUP_EXCLUDE_FILE}    ${CURDIR}/schedule_backup_exclude.json
${RESTORE_FILE}    ${CURDIR}/restore.json
${SCHEDULE_BACKUP_URL}    /restconf/operations/data-export-import:schedule-export
${BKP_DATA_FILE}     odl_backup_config.json
${BKP_OPER_FILE}     odl_backup_operational.json
${MODELS_FILE}        odl_backup_models.json
${STATUS_BACKUP_URL}    /restconf/operations/data-export-import:status-export

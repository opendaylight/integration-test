*** Settings ***
Documentation     Variable definitions, currently just for URI parts relevant in Centinel tests.
...               FIXME: Add a copyright/license statement.
Resource          ${CURDIR}/../Variables.robot

*** Variables ***
# Keep this list sorted alphabetically.
${ALERTFIELDCONTENTRULERECORD}    /restconf/config/alertrule:alertFieldContentRuleRecord/    # FIXME: Add description about what the value means and what the variable name stands for.
${ALERTFIELDVALUERULERECORD}    /restconf/config/alertrule:alertFieldValueRuleRecord    # FIXME: Add description about what the value means and what the variable name stands for.
${ALERTMESSAGECOUNTRULERECORD}    /restconf/config/alertrule:alertMessageCountRuleRecord/    # FIXME: Add description about what the value means and what the variable name stands for.
${DELETE_DASHBOARDRECORD}    /restconf/operations/dashboardrule:delete-dashboard    # FIXME: Add description about what the value means and what the variable name stands for.
${GET_CONFIGURATION_URI}    /restconf/operational/configuration:configurationRecord/    # FIXME: Add description about what the value means and what the variable name stands for.
${GET_DASHBOARDRECORD}    /restconf/operational/dashboardrule:dashboardRecord/    # FIXME: Add description about what the value means and what the variable name stands for.
${SET_ALERTFIELDCONTENTRULERECORD}    /restconf/operations/alertrule:set-alert-field-content-rule    # FIXME: Add description about what the value means and what the variable name stands for.
${SET_ALERTFIELDVALUERULERECORD}    /restconf/operations/alertrule:set-alert-field-value-rule    # FIXME: Add description about what the value means and what the variable name stands for.
${SET_ALERTMESSAGECOUNTRULERECORD}    /restconf/operations/alertrule:set-alert-message-count-rule    # FIXME: Add description about what the value means and what the variable name stands for.
${SET_CONFIGURATION_URI}    /restconf/operations/configuration:set-centinel-configurations    # FIXME: Add description about what the value means and what the variable name stands for.
${SET_DASHBOARDRECORD}    /restconf/operations/dashboardrule:set-dashboard    # FIXME: Add description about what the value means and what the variable name stands for.
${SET_STREAMRECORD}    /restconf/operations/stream:set-stream    # FIXME: Add description about what the value means and what the variable name stands for.
${SET_SUBSCRIBEUSER}    /restconf/operations/subscribe:subscribe-user    # FIXME: Add description about what the value means and what the variable name stands for.
${STREAMRECORD_CONFIG}    /restconf/config/stream:streamRecord    # FIXME: Add description about what the value means and what the variable name stands for.
${SUBSCRIPTION}    /restconf/config/subscribe:subscription/    # FIXME: Add description about what the value means and what the variable name stands for.
# Keep this list sorted alphabetically.

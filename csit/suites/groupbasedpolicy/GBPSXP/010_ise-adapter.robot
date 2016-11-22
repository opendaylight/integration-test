*** Settings ***
Documentation     Test suite for Group Based Policy, sxp-ise-adapter component.
Suite Setup       Setup ise cohort
Suite Teardown    Wipe clean ise source cohort
Library           OperatingSystem    WITH NAME    os
Library           SSHLibrary
Library           RequestsLibrary
Library           DateTime
Library           ../../../libraries/GbpSxp.py    WITH NAME    gbpsxp
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/GbpSxp.robot

*** Variables ***
${ISE_REST_PORT}    9060
${CONFIGURE_ISE_SOURCE_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-ise-source.json
${SXP_ISE_ADAPTER_CONFIG_URI}    /restconf/config/sxp-ise-adapter-model:gbp-sxp-ise-adapter
${SXP_ISE_ADAPTER_OPERATIONAL_URI}    /restconf/operational/sxp-ise-adapter-model:gbp-sxp-ise-adapter
${GBP_EP_TEMPLATES_CONFIG_URI}    /restconf/config/sxp-ep-provider-model:sxp-ep-mapper
${GBP_TENANT_CONFIG_URI}    /restconf/config/policy:tenants/tenant/tenant-red
${EXPECTED_EP_POLICY_TEMPLATES_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-ep-policy-templates.json
${EXPECTED_TENANT_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-tenant.json
${ISE_API_DIR}    ${CURDIR}/../../../variables/gbp/ise-mock-server-api
${ISE_MOCK_SERVER_API_FOLDER}    mock-server-tc010

*** Test Cases ***
Configure ise source and check results
    [Documentation]    Configure ise source using JSON file,
    ...    read status of ise-source harvest action (DS/operational/ise-source),
    ...    read+check ep-templates and endpoint-groups
    # post ise-source configuration and wait for status
    ${ise_harvest_status_json}    Configure ise source and gain harvest status    session    ${CONFIGURE_ISE_SOURCE_FILE}    http://${TOOLS_SYSTEM_IP}:${ISE_REST_PORT}
    Check ise harvest status    ${ise_harvest_status_json}    5
    # check ep-templates in sxp-ep-mapper
    ${expected_templates}    os.Get file    ${EXPECTED_EP_POLICY_TEMPLATES_FILE}
    ${actual_templates}    Get Data From URI    session    ${GBP_EP_TEMPLATES_CONFIG_URI}
    Normalize_Jsons_And_Compare    ${expected_templates}    ${actual_templates}
    # check endpoint-groups in tenant
    ${expected_tenant}    os.Get file    ${EXPECTED_TENANT_FILE}
    ${actual_tenant}    Get Data From URI    session    ${GBP_TENANT_CONFIG_URI}
    Normalize_Jsons_And_Compare    ${expected_tenant}    ${actual_tenant}

*** Keywords ***
Setup ise cohort
    [Documentation]    Start ise mock and prepare restconf session
    # start http session
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Prepare ssh tooling
    Deploy ise mock server    ${ISE_MOCK_SERVER_API_FOLDER}    ${ISE_REST_PORT}

Wipe clean ise source cohort
    [Documentation]    Delete ise-source config, all ep-policy-templates, all endpoint-groups
    # clean DS/config
    Clean ise source config
    Run keyword and ignore error    Remove All Elements If Exist    ${GBP_EP_TEMPLATES_CONFIG_URI}
    Run keyword and ignore error    Remove All Elements If Exist    ${GBP_TENANT_CONFIG_URI}
    Teardown ise mock server    ${ISE_MOCK_SERVER_API_FOLDER}
    Teardown ssh tooling
    Delete All Sessions

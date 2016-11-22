*** Settings ***
Documentation     Test suite for Group Based Policy, sxp-ise-adapter component.
Suite Setup       Setup_Ise_Cohort
Suite Teardown    Wipe_Clean_Ise_Source_Cohort
Library           OperatingSystem    WITH NAME    os
Library           SSHLibrary
Library           RequestsLibrary
Library           DateTime
Library           ../../../libraries/GbpSxp.py    WITH NAME    gbpsxp
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/GbpSxp.robot

*** Variables ***
${CONFIGURE_ISE_SOURCE_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-ise-source.json
${EXPECTED_EP_POLICY_TEMPLATES_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-ep-policy-templates.json
${EXPECTED_TENANT_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-tenant.json
${ISE_API_DIR}    ${CURDIR}/../../../variables/gbp/ise-mock-server-api
${ISE_MOCK_SERVER_API_FOLDER}    mock-server-tc010

*** Test Cases ***
Configure_Ise_Source_And_Check_Results
    [Documentation]    Configure ise source using JSON file,
    ...    read status of ise-source harvest action (DS/operational/ise-source),
    ...    read+check ep-templates and endpoint-groups
    Comment    PAUSE    # effectively breakpoint for ride.py
    # post ise-source configuration and wait for status
    ${ise_harvest_status_json}    gbpsxp.Configure_Ise_Source_And_Gain_Harvest_Status    session    ${CONFIGURE_ISE_SOURCE_FILE}    http://${TOOLS_SYSTEM_IP}:${ISE_REST_PORT}
    gbpsxp.Check_Ise_Harvest_Status    ${ise_harvest_status_json}    5
    # check ep-templates in sxp-ep-mapper
    ${expected_templates}    os.Get_File    ${EXPECTED_EP_POLICY_TEMPLATES_FILE}
    ${actual_templates}    Utils.Get_Data_From_URI    session    ${GBP_EP_TEMPLATES_CONFIG_URI}
    TemplatedRequests.Normalize_Jsons_And_Compare    ${expected_templates}    ${actual_templates}
    # check endpoint-groups in tenant
    ${expected_tenant}    os.Get_File    ${EXPECTED_TENANT_FILE}
    ${actual_tenant}    Utils.Get_Data_From_URI    session    ${GBP_TENANT_CONFIG_URI}
    TemplatedRequests.Normalize_Jsons_And_Compare    ${expected_tenant}    ${actual_tenant}

*** Keywords ***
Setup_Ise_Cohort
    [Documentation]    Start ise mock and prepare restconf session
    # start http session
    RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    GbpSxp.Prepare_Ssh_Tooling
    gbpsxp.Deploy_Ise_Mock_Server    ${ISE_MOCK_SERVER_API_FOLDER}    ${ISE_REST_PORT}

Wipe_Clean_Ise_Source_Cohort
    [Documentation]    Delete ise-source config, all ep-policy-templates, all endpoint-groups
    # clean DS/config
    gbpsxp.Clean_ise_source_config
    BuiltIn.Run_Keyword_And_Ignore_Error    Utils.Remove_All_Elements_If_Exist    ${GBP_EP_TEMPLATES_CONFIG_URI}
    BuiltIn.Run_Keyword_And_Ignore_Error    Utils.Remove_All_Elements_If_Exist    ${GBP_TENANT_CONFIG_URI}
    gbpsxp.Teardown_Ise_Mock_Server    ${ISE_MOCK_SERVER_API_FOLDER}
    gbpsxp.Teardown_Ssh_Tooling
    RequestsLibrary.Delete_All_Sessions

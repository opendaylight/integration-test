*** Settings ***
Documentation     Test suite for Group Based Policy, sxp-ep-provider component.
Suite Setup       Setup http and netconf
Suite Teardown    Teardown http and netconf
Test Setup        Prepare renderer prerequisities
Test Teardown     Wipe clean renderer policy cohort
Library           OperatingSystem    WITH NAME    os
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/GbpSxp.py    WITH NAME    gbpsxp
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/NetconfKeywords.robot
Resource          ../../../libraries/GbpSxp.robot

*** Variables ***
${EP_PROVIDER_TEMPLATES_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-ep-policy-templates
${SXP_EP_PROVIDER_CONFIG_URI}    /restconf/config/sxp-ep-provider-model:sxp-ep-mapper
${IOS_XE_SCHEMAS_FOLDER}    ${CURDIR}/../../../variables/gbp/ios-xe-schemas
${GBP_TENANT_CONFIG_URI}    /restconf/config/policy:tenants/tenant/tenant-red
${GBP_RENDERER_POLICY_FILE}    ${CURDIR}/../../../variables/gbp/gbpsxp-renderer-policy.json
${GBP_RENDERER_CONFIG_URI}    /restconf/config/renderer:renderers/renderer/ios-xe-renderer
${GBP_RENDERER_POLICY_OPERATIONAL_URI}    /restconf/operational/renderer:renderers/renderer/ios-xe-renderer/renderer-policy
${GBP_RENDERER_POLICY_STATUS_OPERATIONAL_URI}    ${GBP_RENDERER_POLICY_OPERATIONAL_URI}/status
# netconf
@{IOS_XE_IP}      ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}
@{IOS_XE_NODE_NAMES}    ios-xe-mock-1    ios-xe-mock-2
${NETCONF_CONFIG_URI}    /restconf/config/network-topology:network-topology/topology/topology-netconf
${NETCONF_CONFIG_IOSXE_NODE_FILE}    ${CURDIR}/../../../variables/gbp/ios-xe-netconf-node.json
${NETCONF_OPERATIONAL_URI}    /restconf/operational/network-topology:network-topology/topology/topology-netconf
${MOUNTPOINT_IOSXE_SUFFIX}    yang-ext:mount/ned:native
# sfc configuration
${SFC_SERVICE_FUNCTIONS_FILE}    ${CURDIR}/../../../variables/gbp/sfc/service-functions.json
${SFC_SERVICE_FUNCTIONS_URI}    /restconf/config/service-function:service-functions
${SFC_SF_FORWARDERS_FILE}    ${CURDIR}/../../../variables/gbp/sfc/service-function-forwarders.json
${SFC_SF_FORWARDERS_URI}    /restconf/config/service-function-forwarder:service-function-forwarders
${SFC_SF_CHAINS_FILE}    ${CURDIR}/../../../variables/gbp/sfc/service-function-chains.json
${SFC_SF_CHAINS_URI}    /restconf/config/service-function-chain:service-function-chains
${SFC_SF_PATHS_FILE}    ${CURDIR}/../../../variables/gbp/sfc/service-function-paths.json
${SFC_SF_PATHS_URI}    /restconf/config/service-function-path:service-function-paths

*** Test Cases ***
Configure sfc and ios-xe renderer using generated sgt
    [Documentation]    Elicit netconf device configuration by providing sfc configurations and ios-xe renderer policy
    # PUT renderer policy
    ${renderer_policy}    ${next_version}    Provision renderer policy    session    ${GBP_RENDERER_POLICY_FILE}
    Add Elements To URI And Verify    ${GBP_RENDERER_CONFIG_URI}/renderer-policy    ${renderer_policy}
    # wait for configuration processed on DS/operational
    WAIT UNTIL KEYWORD SUCCEEDS    30    2    Check renderer policy status version    session    ${next_version}
    # check source and destination on device
    ${security_group_json}    wait until keyword succeeds    20    2    Seek security group    session    ${NETCONF_CONFIG_URI}/node/${IOS_XE_NODE_NAMES[1]}/${MOUNTPOINT_IOSXE_SUFFIX}
    Log    ${security_group_json['source']['tag']}    level=DEBUG
    Log    ${security_group_json['destination']['tag']}    level=DEBUG
    should be equal as integers    101    ${security_group_json['source']['tag']}
    should be equal as integers    100    ${security_group_json['destination']['tag']}
    # check generated ep-policy-templates
    ${expected_templates}    os.Get file    ${EP_PROVIDER_TEMPLATES_FILE}-3.1.json
    ${actual_templates}    Get Data From URI    session    ${SXP_EP_PROVIDER_CONFIG_URI}
    Normalize_Jsons_And_Compare    ${expected_templates}    ${actual_templates}

Configure sfc and ios-xe renderer using existing sgt
    [Documentation]    Elicit netconf device configuration by providing sfc configurations and ios-xe renderer policy and ep-policy-templates
    # ep-policy-templates
    Add Elements To URI From File    ${SXP_EP_PROVIDER_CONFIG_URI}    ${EP_PROVIDER_TEMPLATES_FILE}-3.2.json
    # PUT renderer policy
    ${renderer_policy}    ${next_version}    Provision renderer policy    session    ${GBP_RENDERER_POLICY_FILE}
    Add Elements To URI And Verify    ${GBP_RENDERER_CONFIG_URI}/renderer-policy    ${renderer_policy}
    # wait for configuration processed on DS/operational
    WAIT UNTIL KEYWORD SUCCEEDS    30    2    Check renderer policy status version    session    ${next_version}
    # check source and destination on device
    ${security_group_json}    wait until keyword succeeds    20    2    Seek security group    session    ${NETCONF_CONFIG_URI}/node/${IOS_XE_NODE_NAMES[1]}/${MOUNTPOINT_IOSXE_SUFFIX}
    Log    ${security_group_json['source']['tag']}    level=DEBUG
    Log    ${security_group_json['destination']['tag']}    level=DEBUG
    should be equal as integers    43    ${security_group_json['source']['tag']}
    should be equal as integers    42    ${security_group_json['destination']['tag']}

*** Keywords ***
Setup http and netconf
    [Documentation]    Setup http session, setup ssh session to tools, deploy netconf-testtool (with ios-xe schemas) and start
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${tools_1_session}    Prepare_Ssh_Tooling    ${TOOLS_SYSTEM_IP}
    ${tools_2_session}    Prepare_Ssh_Tooling    ${TOOLS_SYSTEM_2_IP}
    @{tools_sessions}    create list    ${tools_1_session}    ${tools_2_session}
    set suite variable    ${TOOLS_SESSIONS}    ${tools_sessions}
    Setup_NetconfKeywords
    # hack - manage netconf-testtool manually
    ${run_netconf_testtool_manually}    get variable value    ${run_netconf_testtool_manually}    ${False}
    ${logfile}    Utils.Get_Log_File_Name    testtool
    run keyword if    ${run_netconf_testtool_manually}    BuiltIn.Set_Suite_Variable    ${testtool_log}    ${logfile}
    : FOR    ${ssh_session}    IN    @{TOOLS_SESSIONS}
    \    Restore_Current_Ssh_Connection_From_Index    ${ssh_session}
    \    run keyword unless    ${run_netconf_testtool_manually}    Install_And_Start_Testtool    device-count=1    debug=false    schemas=${IOS_XE_SCHEMAS_FOLDER}
    \    ...    mdsal=true
    # hack ^^^

Teardown http and netconf
    [Documentation]    Close http session, close ssh session to tools, stop netconf-testtool
    : FOR    ${ssh_session}    IN    @{TOOLS_SESSIONS}
    \    Log    ${ssh_session}
    \    RESTORE_CURRENT_SSH_CONNECTION_FROM_INDEX    ${ssh_session}
    \    Stop_Testtool
    Teardown ssh tooling    ${TOOLS_SESSIONS}
    Delete All Sessions

Prepare renderer prerequisities
    [Documentation]    Prepare sfc configurations, connect netconf device
    # config netconf devices
    : FOR    ${INDEX}    IN RANGE    0    2
    \    Log    ${INDEX}
    \    ${netconf_node_configuration_json}    Json Parse From File    ${NETCONF_CONFIG_IOSXE_NODE_FILE}
    \    ${netconf_node_configuration}    gbpsxp.Replace netconf node host    ${netconf_node_configuration_json}    ${IOS_XE_NODE_NAMES[${INDEX}]}    ${IOS_XE_IP[${INDEX}]}
    \    Log    ${netconf_node_configuration}    level=DEBUG
    \    Add Elements To URI And Verify    ${NETCONF_CONFIG_URI}/node/${IOS_XE_NODE_NAMES[${INDEX}]}    ${netconf_node_configuration}
    # verify netconf devices connection status
    : FOR    ${INDEX}    IN RANGE    0    2
    \    Log    ${INDEX}
    \    wait until keyword succeeds    30    2    Check netconf node status    session    ${NETCONF_OPERATIONAL_URI}/node/${IOS_XE_NODE_NAMES[${INDEX}]}
    # config sfc
    Sleep    5
    Add Elements To URI From File    ${SFC_SERVICE_FUNCTIONS_URI}    ${SFC_SERVICE_FUNCTIONS_FILE}
    &{ip_mgmt_map}    Create Dictionary    SFF1=${TOOLS_SYSTEM_2_IP}    SFF2=${TOOLS_SYSTEM_IP}
    ${sfc_sf_forwarders_json}    Json Parse From File    ${SFC_SF_FORWARDERS_FILE}
    ${sfc_sf_forwarders}    gbpsxp.Replace ip mgmt address in forwarder    ${sfc_sf_forwarders_json}    ${ip_mgmt_map}
    Add Elements To URI And Verify    ${SFC_SF_FORWARDERS_URI}    ${sfc_sf_forwarders}
    Add Elements To URI From File    ${SFC_SF_CHAINS_URI}    ${SFC_SF_CHAINS_FILE}
    Add Elements To URI From File    ${SFC_SF_PATHS_URI}    ${SFC_SF_PATHS_FILE}

Check netconf node status
    [Arguments]    ${session_arg}    ${node_operational_uri}
    [Documentation]    Check if connection status of given node is 'connected'
    ${node_content}    Get Data From URI    ${session_arg}    ${node_operational_uri}
    ${node_content_json}    Json Parse From String    ${node_content}
    Should be equal as strings    connected    ${node_content_json['node'][0]['netconf-node-topology:connection-status']}

Wipe clean renderer policy cohort
    [Documentation]    Delete ep-policy-templates, renderer-policy, sfc configuraions, netconf-device config
    # clean sfc configs
    Run keyword and ignore error    Remove All Elements If Exist    ${SFC_SERVICE_FUNCTIONS_URI}
    Run keyword and ignore error    Remove All Elements If Exist    ${SFC_SF_FORWARDERS_URI}
    Run keyword and ignore error    Remove All Elements If Exist    ${SFC_SF_CHAINS_URI}
    Run keyword and ignore error    Remove All Elements If Exist    ${SFC_SF_PATHS_URI}
    # clean renderer-policy configuration
    Run keyword and ignore error    Remove All Elements If Exist    ${GBP_RENDERER_CONFIG_URI}
    # clean netconf-device config (behind mountpoint) and disconnect by removing it from DS/config
    : FOR    ${ios_xe_node_name}    IN    @{IOS_XE_NODE_NAMES}
    \    Run keyword and ignore error    Remove All Elements If Exist    ${NETCONF_CONFIG_URI}/node/${ios_xe_node_name}/${MOUNTPOINT_IOSXE_SUFFIX}
    \    Run keyword and ignore error    Remove All Elements If Exist    ${NETCONF_CONFIG_URI}/node/${ios_xe_node_name}
    # wait till netconf node disappears from DS/operational
    : FOR    ${ios_xe_node_name}    IN    @{IOS_XE_NODE_NAMES}
    \    wait until keyword succeeds    5    1    No Content From URI    session    ${NETCONF_OPERATIONAL_URI}/node/${ios_xe_node_name}
    # clean ep-templates
    Run keyword and ignore error    Remove All Elements If Exist    ${SXP_EP_PROVIDER_CONFIG_URI}
    # clean epg
    Run keyword and ignore error    Remove All Elements If Exist    ${GBP_TENANT_CONFIG_URI}

Seek security group
    [Arguments]    ${session_arg}    ${config_uri}
    [Documentation]    Read given DS and seek CONFIG['native']['class-map'][0]['match']['security-group']
    ${device_ds_config}    Get Data From URI    ${session_arg}    ${config_uri}
    ${device_ds_config_json}    Json Parse From String    ${device_ds_config}
    [Return]    ${device_ds_config_json['native']['class-map'][0]['match']['security-group']}

Propose renderer configuration next version
    [Arguments]    ${session_arg}
    [Documentation]    Read current renderer configuration status and compute next version or use 0 if status absents
    ${renderer_policy}    Run keyword and ignore error    Get Data From URI    ${session_arg}    ${GBP_RENDERER_POLICY_OPERATIONAL_URI}
    return from keyword if    '${renderer_policy[0]}' != 'PASS'    0
    ${renderer_policy_json}    Json Parse From String    ${renderer_policy[1]}
    ${current_version}    Convert to integer    ${renderer_policy_json['renderer-policy']['version']}
    [Return]    ${current_version + 1}

Provision renderer policy
    [Arguments]    ${session_arg}    ${renderer_policy_file}
    [Documentation]    Replace version number in given renderer-policy in order to be the next expected value
    ${renderer_policy_json}    Json Parse From File    ${renderer_policy_file}
    ${next_version}    Propose renderer configuration next version    ${session_arg}
    ${renderer_policy_updated}    gbpsxp.Replace renderer policy version    ${renderer_policy_json}    ${next_version}
    [Return]    ${renderer_policy_updated}    ${next_version}

Check renderer policy status version
    [Arguments]    ${session_arg}    ${expected_version}
    [Documentation]    Read current renderer policy version and compare it to expected version
    ${renderer_policy}    Get Data From URI    ${session_arg}    ${GBP_RENDERER_POLICY_OPERATIONAL_URI}
    ${renderer_policy_json}    Json Parse From String    ${renderer_policy}
    should be equal as integers    ${renderer_policy_json['renderer-policy']['version']}    ${expected_version}

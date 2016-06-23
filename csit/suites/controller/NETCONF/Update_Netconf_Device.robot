*** Settings ***
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Library           SSHLibrary
Library           OperatingSystem
Library           String
Library           Collections
Library           ../../../libraries/XmlComparator.py
Library           ../../../libraries/netconf_library.py
Library           Process
Library           RequestsLibrary
Resource          ../../../libraries/NexusKeywords.robot
Resource          ../../../libraries/NetconfKeywords.robot
Resource          ../../../variables/netconf_scale/NetScale_variables.robot

*** Variables ***
${tt-sim-dev}     27830
${tt-sim-dev_user}    admin
${FILE}           ${CURDIR}/../../../variables/xmls/netconf.xml
${REST_CONT_CONF}    /restconf/config/network-topology:network-topology/topology/topology-netconf    # restconf/config/network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount/config:modules/module/odl-sal-netconf-connector-cfg:sal-netconf-connector/${tt-sim-dev}
${REST_CONT_OPER}    /restconf/operational/network-topology:network-topology/topology/topology-netconf
${REST_SIm-Dev_Mount}    node/controller-config/yang-ext:mount/config:modules
${REST_SIM-DEV_CONF}    estconf/config/network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount/config:modules/module/odl-sal-netconf-connector-cfg:sal-netconf-connector/${tt-sim-dev}    # estconf/config/network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount/config:modules/module/odl-sal-netconf-connector-cfg:sal-netconf-connector/${tt-sim-dev}
${update_cfg_xml}    ${CURDIR}/../../../variables/xmls/netconf_update_cfg.xml

${NEXUS_FALLBACK_URL}    ${NEXUSURL_PREFIX}/content/repositories/opendaylight.snapshot

*** Test Cases ***
Start TestTool
    Open Connection    ${CONTROLLER}
    SSHLibrary.Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Execute Command    mkdir -p ${ttlocation}
    Execute Command    rm -r ${ttlocation}/*
    NetconfKeywords.Install_And_Start_Testtool    device-count=1    debug=false    mdsal=false

Mount Netconf Device
    Comment    ${XML1}    Get File    ${FILE}
    Comment    ${XML2}    Replace String    ${XML1}    127.0.0.1    ${tt-sim-dev}
    Log        ${AUTH}
    Comment    ${body}    Replace String    ${XML2}    admin    ${tt-sim-dev_USER}
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}
    ${body}    Operating System.Get File    ${update_cfg_xml}
    Log    ${body}
    ${resp}    RequestsLibrary.Post    session    ${REST_CONT_CONF}/${REST_Sim-Dev_Mount}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204
    ${resp}    RequestsLibrary.Get    session    ${REST_CONT_OPER}/node/${tt-sim-dev}

Netconf Device Base CFG
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}
    ${resp}    RequestsLibrary.Get    session    ${REST_CONT_CONF}/${REST_Sim-DEV_MOUNT}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    {}
    Delete    session    http://${CONTROLLER}:${RESTCONFPORT}

Update Netconf Device CFG
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}
    ${resp}    RequestsLibrary.Get    session    ${REST_CONT_OPER}/${REST_SIM-DEV_MOUNT}
    Log    ${resp}
    ${resp}    RequestsLibrary.Put    session    ${REST_SIM-DEV_CONF}    data=${update_cfg_xml}
    Log    ${resp}
    Should Be Equal As Strings    ${resp.status_code}    200

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    NetconfKeywords.Setup_Netconf_Keywords

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    RequestsLibrary.Delete_All_Sessions
    BuiltIn.Run_Keyword_And_Ignore_Error    NetconfKeywords.Stop_Testtool

*** Settings ***
Library           SSHLibrary
Library           OperatingSystem
Library           String
Library           Collections
Library           ../../../libraries/XmlComparator.py
Library           ../../../libraries/netconf_library.py
Library           Process
Library           RequestsLibrary
Resource          ../../../libraries/NexusKeywords.robot
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
${CNTLR_ADMIN}    ${EMPTY}
${CNTLR_ADMIN_PASSWORD}    ${EMPTY}

*** Test Cases ***
Start TestTool
    Open Connection    ${CONTROLLER}
    Login    ${CNTLR_ADMIN}    ${CNTLR_ADMIN_PASSWORD}
    Execute Command    mkdir -p ${ttlocation}
    Execute Command    rm -r ${ttlocation}/*
#    Run    wget https://nexus.opendaylight.org/service/local/repositories/autorelease-1290/content/org/opendaylight/controller/netconf-testtool/0.3.5-Lithium-SR5/netconf-testtool-0.3.5-Lithium-SR5-executable.jar -O ${ttlocation}/netconf-testtool.jar
    Deploy_Test_Tool    netconf    netconf-testtool
    Start Process    java     -jar     ${ttlocation}/netconf-testtool.jar    alias=netconf_testtool_process
    Is Process Running    netconf_testtool_process

Mount Netconf Device
    Comment    ${XML1}    Get File    ${FILE}
    Comment    ${XML2}    Replace String    ${XML1}    127.0.0.1    ${tt-sim-dev}
    Log        ${AUTH}
    Comment    ${body}    Replace String    ${XML2}    admin    ${tt-sim-dev_USER}
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}
    ${body}    Operating System.Get File    ${update_cfg_xml}
    Log    ${body}
    ${resp}    Post    session    ${REST_CONT_CONF}/${REST_Sim-Dev_Mount}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204
    ${resp}    Get    session    ${REST_CONT_OPER}/node/${tt-sim-dev}

Netconf Device Base CFG
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}
    ${resp}    Get    session    ${REST_CONT_CONF}/${REST_Sim-DEV_MOUNT}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    {}
    Delete    session    http://${CONTROLLER}:${RESTCONFPORT}

Update Netconf Device CFG
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}
    ${resp}    Get    session    ${REST_CONT_OPER}/${REST_SIM-DEV_MOUNT}
    Log    ${resp}
    ${resp}    Put    session    ${REST_SIM-DEV_CONF}    data=${update_cfg_xml}
    Log    ${resp}
    Should Be Equal As Strings    ${resp.status_code}    200

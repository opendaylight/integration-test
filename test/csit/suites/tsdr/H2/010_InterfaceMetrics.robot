*** Settings ***
Documentation     Test suite for H2 DataStore
Suite Setup       Run Keywords    Start Tsdr Suite    Initialize the REST Client Session 
Suite Teardown    Run Keywords    Stop Suite    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           String
Library           ../../../libraries/RequestsLibrary.py
Library           ../../../libraries/Common.py
Resource          ../../../libraries/KarafKeywords.txt
Resource          ../../../libraries/Utils.txt
Resource          ../../../libraries/TsdrUtils.txt
Variables         ../../../variables/Variables.py

*** Variables ***
@{INTERFACE_METRICS}    TransmittedPackets    TransmittedBytes    TransmitErrors    TransmitDrops    ReceivedPackets    ReceivedBytes    ReceiveOverRunError
...               ReceiveFrameError    ReceiveErrors    ReceiveDrops    ReceiveCrcError    CollisionCount
@{CATEGORY}       InterfaceMetrics    FlowTableMetrics    GroupMetrics    FlowMetrics    QueueMetrics
${INTERFACE_QUERY}    scan 'InterfaceMetrics'

*** Test Cases ***
Verification Feature Installation
    [Documentation]    Verify the H2 datastore is installed
    Install a Feature    odl-tsdr-all    ${CONTROLLER}    ${KARAF_SHELL_PORT}    30
    Verify Feature Is Installed    odl-tsdr-all
    Verify Feature Is Installed    odl-tsdr-H2-persistence
    Verify Feature Is Installed    odl-tsdr-core

Get list of nodes from RESTAPI
    [Documentation]    Get the inventory, should not contain address observations
    ${resp}    RequestsLibrary.Get    session    ${OPERATIONAL_NODES_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    openflow:1
    Should Contain    ${resp.content}    openflow:2

Verification TSDR Command is exist in Help
    [Documentation]    Verify the TSDR List command on Help
    ${output}=    Issue Command On Karaf Console    tsdr\t
    Should Contain    ${output}    tsdr:list
    Should Contain    ${output}    tsdr:purgeall
    ${output}=    Issue Command On Karaf Console    tsdr:list\t\t
    : FOR    ${list}    IN    @{CATEGORY}
    \    Should Contain    ${output}    ${list}
    COMMENT    Intentional Sleep time for Data Collection purpose
    Sleep    15

Verification of TSDR InterfaceMetrics
    [Documentation]    Verify the TSDR InterfaceMetrics
    ${output}=    Issue Command On Karaf Console    tsdr:list    ${CONTROLLER}    ${KARAF_SHELL_PORT}    30
    : FOR    ${list}    IN    @{INTERFACE_METRICS}
    \    Should Contain    ${output}    ${list}

Uninstall all TSDR H2 Feature
    [Documentation]    UnInstall all TSDR H2 Features
    Uninstall a Feature    odl-tsdr-core
    Verify Feature Is Not Installed    odl-tsdr-core
    Uninstall a Feature    odl-tsdr-all
    Verify Feature Is Not Installed    odl-tsdr-all
    Uninstall a Feature    odl-tsdr-H2-persistence
    Verify Feature Is Not Installed    odl-tsdr-H2-persistence

Verification TSDR Command shouldnot exist in help
    [Documentation]    Verify the TSDR List command on help
    ${output}=    Issue Command On Karaf Console    tsdr\t    ${CONTROLLER}    ${KARAF_SHELL_PORT}
    Should not Contain    ${output}    tsdr:list
    Comment    Should not Contain    ${output}    tsdr:purgeall

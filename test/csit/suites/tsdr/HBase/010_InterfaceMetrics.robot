*** Settings ***
Documentation     Test suite for Hbase DataStore Verification
Suite Setup       Run Keywords    Start Tsdr Suite    Initialize the HBase for TSDR
Suite Teardown    Run Keywords    Stop Suite    Stop the HBase Server
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
Install the TSDR HBase Feature
    [Documentation]    Install and Verify the TSDR HBase Features
    Install a Feature    odl-tsdr-hbase    ${CONTROLLER}    ${KARAF_SHELL_PORT}    30
    Verify Feature Is Installed    odl-tsdr-hbase
    Verify Feature Is Installed    odl-tsdr-hbase-persistence
    Verify Feature Is Installed    odl-hbaseclient

Verification TSDR Command is exist in Help
    [Documentation]    Verify the TSDR List command on Help
    ${output}=    Issue Command On Karaf Console    tsdr\t
    Should Contain    ${output}    tsdr:list
    COMMENT    Should Contain    ${output}    tsdr:purgeall
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

Verification of InterfaceMetrics on HBase Client
    [Documentation]    Verification of the InterfaceMetrics from HBase Client
    ${out}=    Query the Data from HBaseClient    ${INTERFACE_QUERY}
    LOG    ${out}

Uninstall all TSDR HBase Feature
    [Documentation]    UnInstall all TSDR HBase Features
    Uninstall a Feature    odl-tsdr-hbase-persistence
    Verify Feature Is Not Installed    odl-tsdr-hbase-persistence
    Uninstall a Feature    odl-hbaseclient
    Verify Feature Is Not Installed    odl-hbaseclient
    Uninstall a Feature    odl-tsdr-core
    Verify Feature Is Not Installed    odl-tsdr-core
    Uninstall a Feature    odl-tsdr-hbase
    Verify Feature Is Not Installed    odl-tsdr-hbase

Verification TSDR Command shouldnot exist in help
    [Documentation]    Verify the TSDR List command on help
    ${output}=    Issue Command On Karaf Console    tsdr\t    ${CONTROLLER}    ${KARAF_SHELL_PORT}
    Should not Contain    ${output}    tsdr:list
    Comment    Should not Contain    ${output}    tsdr:purgeall

Verify node1 Aggregate stats doesnot zero value
    [Documentation]    Verfiy the nodes doesnot have stats value with zero
    ${result}=    Run Command On Remote System    ${MININET}    sudo ovs-ofctl dump-aggregate s1 -O OpenFlow13
    Comment    Write    sh ovs-ofctl dump-aggregate s1 -O OpenFlow13
    Comment    ${result}    Read Until    mininet>
    Should Not Contain    ${result}    packet_count=0
    Should Not Contain    ${result}    byte_count=0
    Should Not Contain    ${result}    flow_count=0

Verify node1 Ports stats doesnot zero value
    [Documentation]    Verfiy the nodes doesnot have stats value with zero
    ${result}=    Run Command On Remote System    ${MININET}    sudo ovs-ofctl dump-ports s1 -O OpenFlow13
    Comment    Write    sh ovs-ofctl dump-ports s1 -O OpenFlow13
    Comment    ${result}    Read Until    mininet>
    ${port1}=    Get Lines Containing String    ${result}    1:
    Should Not Contain    ${port1}    rx pkts=0
    Should Not Contain    ${port1}    bytes=0
    ${port1_tx}=    Get Line    ${result}    6
    Should Not Contain    ${port1_tx}    tx pkts=0

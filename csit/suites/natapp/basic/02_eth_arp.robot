*** Settings ***
Documentation     Test suite for Ethernet,QoS, ARP and Action drop
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
@{FLOWELEMENTS}    arp    FLOOD
${start}          sudo mn --mac --controller=remote,ip=${ODL_SYSTEM_IP},port=6653 --topo=single,10 --switch ovsk,protocols=OpenFlow13

*** Test Cases ***
Add and Verify flows for flooding the arp packets
    [Documentation]    Flood ARP packets
    [Tags]    Switch
    #Start Suite
    Switch Connection    ${mininet_conn_id}
    write    sh ovs-ofctl add-flow s1 arp,actions=FLOOD
    sleep    5
    write    sh ovs-ofctl dump-flows s1
    ${switchoutput}    Read Until    >
    : FOR    ${flowElement}    IN    @{FLOWELEMENTS}
    \    should Contain    ${switchoutput}    ${flowElement}

*** Settings ***
Documentation     Test suite for VTN Manager
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           ../../../libraries/RequestsLibrary.py
Library           ../../../libraries/Common.py
Library           ../../../libraries/Topology.py
Variables         ../../../variables/Variables.py

*** Variables ***
${REST_CONTEXT_VTNS}    controller/nb/v2/vtn/default/vtns

*** Test Cases ***
Add a vtn Tenant1
    [Documentation]    Add a vtn Tenant1
    Add a vtn    Tenant1    {"description": "Virtual Tenant 1 for Hackfest network"}

Add a vBridge vBridge1
    [Documentation]    Add a vBridge vBridge1 in vtn Tenant1
    Add a vBridge    Tenant1    vBridge1    {}

Add a interface If1
    [Documentation]    Add a interface if1 into vBridge vBrdige1
    Add a interface    Tenant1    vBridge1    if1    {}

Add a interface if2
    [Documentation]    Add a interface if2 into vBridge vBrdige1
    Add a interface    Tenant1    vBridge1    if2    {}

Add a portmap for interface if1
    [Documentation]    Create a portmap on Interface if1 of vBridge1
    ${node}    Create Dictionary    type    OF    id    00:00:00:00:00:00:00:02
    ${port}    Create Dictionary    name    s2-eth1
    ${portmap_data}    Create Dictionary    node    ${node}    port    ${port}
    Add a portmap    Tenant1    vBridge1    if1    ${portmap_data}

Add a portmap for interface if2
    [Documentation]    Create a portmap on Interface if2 of vBridge1
    ${node}    Create Dictionary    type    OF    id    00:00:00:00:00:00:00:03
    ${port}    Create Dictionary    name    s3-eth1
    ${portmap_data}    Create Dictionary    node    ${node}    port    ${port}
    Add a portmap    Tenant1    vBridge1    if2    ${portmap_data} 

Add a vBridge vBridge2
    [Documentation]    Add a vBridge vBridge2 in vtn Tenant1
    Add a vBridge    Tenant1    vBridge2    {}

Add a interface If3
    [Documentation]    Add a interface if3 into vBridge vBrdige2
    Add a interface    Tenant1    vBridge2    if3    {}

Add a interface if4
    [Documentation]    Add a interface if4 into vBridge vBrdige2
    Add a interface    Tenant1    vBridge2    if4    {}

Add a portmap for interface if3
    [Documentation]    Create a portmap on Interface if3 of vBridge2
    ${node}    Create Dictionary    type    OF    id    00:00:00:00:00:00:00:02
    ${port}    Create Dictionary    name    s2-eth2
    ${portmap_data}    Create Dictionary    node    ${node}    port    ${port}
    Add a portmap    Tenant1    vBridge2    if3    ${portmap_data}

Add a portmap for interface if4
    [Documentation]    Create a portmap on Interface if4 of vBridge2
    ${node}    Create Dictionary    type    OF    id    00:00:00:00:00:00:00:03
    ${port}    Create Dictionary    name    s3-eth2
    ${portmap_data}    Create Dictionary    node    ${node}    port    ${port}
    Add a portmap    Tenant1    vBridge2    if4    ${portmap_data}

Ping h1 to h3
    [Documentation]    Ping h1 to h3, verify no packet loss
    Write    h1 ping -w 10 h3
    ${result}    Read Until    mininet>
    Should Contain    ${result}    64 bytes

Ping h2 to h4
    [Documentation]    Ping h2 to h4, verify no packet loss
    Write    h2 ping -w 10 h4
    ${result}    Read Until    mininet>
    Should Contain    ${result}    64 bytes

Delete a vtn Tenant1
    [Documentation]    Delete a vtn Tenant1
    Delete a vtn    Tenant1

*** Keywords ***
Add a vtn
    [Arguments]    ${vtn_name}    ${vtn_data}
    [Documentation]    Create a vtn with specified parameters.
    ${resp}    Post    session    ${REST_CONTEXT_VTNS}/${vtn_name}    data=${vtn_data}
    Should Be Equal As Strings    ${resp.status_code}    201

Delete a vtn
    [Arguments]    ${vtn_name}
    [Documentation]    Create a vtn with specified parameters.
    ${resp}    Delete    session    ${REST_CONTEXT_VTNS}/${vtn_name}
    Should Be Equal As Strings    ${resp.status_code}    200

Add a vBridge
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${vBridge_data}
    [Documentation]    Create a vBridge in a VTN
    ${resp}    Post    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}    data=${vBridge_data}
    Should Be Equal As Strings    ${resp.status_code}    201

Add a interface
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}    ${interface_data}
    [Documentation]    Create a interface into a vBridge of a VTN
    ${resp}    Post    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/interfaces/${interface_name}    data=${interface_data}
    Should Be Equal As Strings    ${resp.status_code}    201

Add a portmap
    [Arguments]    ${vtn_name}    ${vBridge_name}    ${interface_name}    ${portmap_data}
    [Documentation]    Create a portmap for a interface of a vbridge
    ${resp}    Put    session    ${REST_CONTEXT_VTNS}/${vtn_name}/vbridges/${vBridge_name}/interfaces/${interface_name}/portmap    data=${portmap_data}
    Should Be Equal As Strings    ${resp.status_code}    200

*** Settings ***
Documentation       Test suite for VTN Manager using OF13

Resource            ../../../libraries/VtnMaKeywords.robot
Resource            ../../../libraries/Utils.robot

Suite Setup         Start SuiteVtnMaTest
Suite Teardown      Stop SuiteVtnMaTest


*** Variables ***
${flowconditiondata}
...                             "vtn-flow-match":[{"vtn-inet-match":{"source-network":"10.0.0.1/32","destination-network":"10.0.0.3/32"},"index":"1"}]
${flowfilterInetdata}
...                             "vtn-flow-filter":[{"condition":"cond_1","vtn-pass-filter":{},"vtn-flow-action":[{"order": "1","vtn-set-inet-src-action":{"ipv4-address":"192.0.0.1/32"}},{"order": "2","vtn-set-inet-dst-action":{"ipv4-address":"192.0.0.2/32"}}],"index": "1"}]
${flowfilterInetdropdata}
...                             "vtn-flow-filter":[{"condition":"cond_1","vtn-drop-filter":{},"vtn-flow-action":[{"order": "1","vtn-set-inet-src-action":{"ipv4-address":"10.0.0.2/32"}},{"order": "2","vtn-set-inet-dst-action":{"ipv4-address":"10.0.0.4/32"}}],"index": "1"}]
${flowfilterIcmpCodedata}
...                             "vtn-flow-filter": [{"condition": "cond_1","index": "1", "vtn-pass-filter": {}, "vtn-flow-action": [{ "order": "1", "vtn-set-icmp-code-action":{"code": "1"}},{"order": "2","vtn-set-icmp-type-action": {"type": "3"}}]}]
${flowfilterTpsrcTpdstdata}
...                             "vtn-flow-filter": [{"condition": "cond_1","vtn-pass-filter": {},"vtn-flow-action": [{"order": "1","vtn-set-port-src-action": {"port": "5"}},{"order": "2","vtn-set-port-dst-action": {"port": "10"}}],"index": "1"}]
${flowfilterDscpdata}
...                             "vtn-flow-filter":[{"condition": "cond_1","vtn-pass-filter": {},"vtn-flow-action": [{"order": "1","vtn-set-inet-dscp-action": {"dscp":"32"}}],"index":"1"}]
${flowfilterdlsrc}
...                             "vtn-flow-filter":[{"condition": "cond_1","vtn-pass-filter": {},"vtn-flow-action": [{"order": "1","vtn-set-dl-src-action": {"address":"00:00:00:00:00:11"}}],"index":"1"}]
${flowfiltervlanpcp}
...                             "vtn-flow-filter":[{"condition":"cond_1","vtn-pass-filter":{},"vtn-flow-action":[{"order":"3","vtn-set-icmp-code-action":{"code":"1"}},{"order":"4","vtn-set-vlan-pcp-action":{"vlan-pcp":"3"}}],"index":"1"}]


*** Test Cases ***
Check if switch1 detected
    [Documentation]    Check if openflow:1 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    12    3    Fetch vtn switch inventory    openflow:1

Check if switch2 detected
    [Documentation]    Check if openflow:2 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    3    1    Fetch vtn switch inventory    openflow:2

Check if switch3 detected
    [Documentation]    Check if openflow:3 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    3    1    Fetch vtn switch inventory    openflow:3

Add a vtn Tenant1
    [Documentation]    Add a vtn Tenant1
    Add a vtn    Tenant1

Add a vBridge vBridge1
    [Documentation]    Add a vBridge vBridge1 in vtn Tenant1
    Add a vBridge    Tenant1    vBridge1

Add a interface If1
    [Documentation]    Add a interface if1 into vBridge vBridge1
    Add a interface    Tenant1    vBridge1    if1

Add a interface if2
    [Documentation]    Add a interface if2 into vBridge vBridge1
    Add a interface    Tenant1    vBridge1    if2

Add a portmap for interface if1
    [Documentation]    Create a portmap on Interface if1 of vBridge1
    Add a portmap    Tenant1    vBridge1    if1    openflow:2    s2-eth1

Add a portmap for interface if2
    [Documentation]    Create a portmap on Interface if2 of vBridge1
    Add a portmap    Tenant1    vBridge1    if2    openflow:3    s3-eth1

Ping h1 to h3
    [Documentation]    Ping h1 to h3, verify no packet loss
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Succeed    h1    h3

Add a vBridge vBridge2
    [Documentation]    Add a vBridge vBridge2 in vtn Tenant1
    Add a vBridge    Tenant1    vBridge2

Add a interface If3
    [Documentation]    Add a interface if3 into vBrdige vBridge2
    Add a interface    Tenant1    vBridge2    if3

Add a interface if4
    [Documentation]    Add a interface if4 into vBrdige vBridge2
    Add a interface    Tenant1    vBridge2    if4

Add a portmap for interface if3
    [Documentation]    Create a portmap on Interface if3 of vBridge2
    Add a portmap    Tenant1    vBridge2    if3    openflow:2    s2-eth2

Add a portmap for interface if4
    [Documentation]    Create a portmap on Interface if4 of vBridge2
    Add a portmap    Tenant1    vBridge2    if4    openflow:3    s3-eth2

Ping h2 to h4
    [Documentation]    Ping h2 to h4, verify no packet loss
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Succeed    h2    h4

Add a flowcondition
    [Documentation]    Create a flowcondition cond_1 using restconfig api
    Add a flowcondition    cond_1    ${flowconditiondata}

Add a vtn flowfilter with inet4src and inet4dst
    [Documentation]    Create a flowfilter with inet4 and Verify ping
    Add a vtn flowfilter    Tenant1    ${flowfilterInetdata}
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Not Succeed    h1    h3

Verify inet4src and inet4dst of vtn flowfilter
    [Documentation]    Verify vtn flowfilter actions in Flow Enties for inet4src and inet4dst
    Wait_Until_Keyword_Succeeds
    ...    20s
    ...    1s
    ...    Verify Flow Entries for Flowfilter
    ...    ${FF_DUMPFLOWS_OF13}
    ...    @{inet_action}
    [Teardown]    Run Keywords    Report_Failure_Due_To_Bug    6643
    ...    AND    Collect Debug Info

Remove vtn Flowfilter index
    [Documentation]    Remove a index of vtn flowfilter
    Remove a vtn flowfilter    Tenant1    ${filter_index}

Add a vbr flowfilter with inet4src and inet4dst
    [Documentation]    Create a flowfilter with inet4 and Verify ping
    Add a vbr flowfilter    Tenant1    vBridge1    ${flowfilterInetdata}
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Not Succeed    h1    h3

Verify inet4src and inet4dst of vbr flowfilter
    [Documentation]    Verify actions in Flow Enties for inet4src and inet4dst
    Wait_Until_Keyword_Succeeds
    ...    20s
    ...    1s
    ...    Verify Flow Entries for Flowfilter
    ...    ${FF_DUMPFLOWS_OF13}
    ...    @{inet_action}

Remove vbr Flowfilter index
    [Documentation]    Remove a index of vbr flowfilter
    Remove a vbr flowfilter    Tenant1    vBridge1    ${filter_index}

Add a vbrif flowfilter with inet4src and inet4dst
    [Documentation]    Create a flowfilter with inet4 and Verify ping
    Add a vbrif flowfilter    Tenant1    vBridge1    if1    ${flowfilterInetdata}
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Not Succeed    h1    h3

Verify inet4src and inet4dst of vbrif flowfilter
    [Documentation]    Verify actions in Flow Enties for inet4src and inet4dst
    Wait_Until_Keyword_Succeeds
    ...    20s
    ...    1s
    ...    Verify Flow Entries for Flowfilter
    ...    ${FF_DUMPFLOWS_OF13}
    ...    @{inet_action}

Remove vbrif Flowfilter index
    [Documentation]    Remove a index of vbrif flowfilter
    Remove a vbrif flowfilter    Tenant1    vBridge1    if1    ${filter_index}

Add a vtn flowfilter with Icmp code
    [Documentation]    Create a flowfilter with icmp code and Verify ping
    Add a vtn flowfilter    Tenant1    ${flowfilterIcmpCodedata}
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Not Succeed    h1    h3

Verify icmp action for vtn flowfilter
    [Documentation]    Verify actions in Flow Enties for icmp code and type
    [Tags]    exclude
    Wait_Until_Keyword_Succeeds
    ...    20s
    ...    1s
    ...    Verify Flow Entries for Flowfilter
    ...    ${FF_DUMPFLOWS_OF13}
    ...    @{icmp_action}

Remove vtn Flowfilter index which has ICMP
    [Documentation]    Remove a index of vtn flowfilter which have ICMP
    Remove a vtn flowfilter    Tenant1    ${filter_index}

Add a vbr flowfilter with Icmp code
    [Documentation]    Create a flowfilter with icmp code and Verify ping
    Add a vbr flowfilter    Tenant1    vBridge1    ${flowfilterIcmpCodedata}
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Not Succeed    h1    h3

Verify icmp action for vbr flowfilter
    [Documentation]    Verify actions in Flow Enties for icmp code and type
    [Tags]    exclude
    Wait_Until_Keyword_Succeeds
    ...    20s
    ...    1s
    ...    Verify Flow Entries for Flowfilter
    ...    ${FF_DUMPFLOWS_OF13}
    ...    @{icmp_action}

Remove vbr Flowfilter index which has ICMP
    [Documentation]    Remove a index of vbr flowfilter which have ICMP
    Remove a vbr flowfilter    Tenant1    vBridge1    ${filter_index}

Add a vbrif flowfilter with Icmp code
    [Documentation]    Create a flowfilter with icmp code and Verify ping
    Add a vbrif flowfilter    Tenant1    vBridge1    if1    ${flowfilterIcmpCodedata}
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Not Succeed    h1    h3

Verify icmp action for vbrif flowfilter
    [Documentation]    Verify actions in Flow Enties for icmp code and type
    [Tags]    exclude
    Wait_Until_Keyword_Succeeds
    ...    20s
    ...    1s
    ...    Verify Flow Entries for Flowfilter
    ...    ${FF_DUMPFLOWS_OF13}
    ...    @{icmp_action}

Remove vbrif Flowfilter index which has ICMP
    [Documentation]    Remove a index of vbrif flowfilter which have ICMP
    Remove a vbrif flowfilter    Tenant1    vBridge1    if1    ${filter_index}

Add a vtn flowfilter with dscp
    [Documentation]    Create a flowfilter with dscp and Verify ping
    Add a vtn flowfilter    Tenant1    ${flowfilterDscpdata}
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Succeed    h1    h3

Verify dscp action for vtn flowfilter
    [Documentation]    Verify actions in Flow Enties for dscp
    Wait_Until_Keyword_Succeeds    20s    1s    Verify flowactions    ${dscp_action}    ${FF_DUMPFLOWS_OF13}

Remove vtn Flowfilter index which have dscp
    [Documentation]    Remove a index of vtn flowfilter which have DSCP
    Remove a vtn flowfilter    Tenant1    ${filter_index}

Add a vbr flowfilter with dscp
    [Documentation]    Create a flowfilter with dscp and Verify ping
    Add a vbr flowfilter    Tenant1    vBridge1    ${flowfilterDscpdata}
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Succeed    h1    h3

Verify dscp action for vbr flowfilter
    [Documentation]    Verify actions in Flow Enties for dscp
    Wait_Until_Keyword_Succeeds    20s    1s    Verify flowactions    ${dscp_action}    ${FF_DUMPFLOWS_OF13}

Remove vbr Flowfilter index which have dscp
    [Documentation]    Remove a index of vbr flowfilter which have DSCP
    Remove a vbr flowfilter    Tenant1    vBridge1    ${filter_index}

Add a vbrif flowfilter with dscp
    [Documentation]    Create a flowfilter with dscp and Verify ping
    Add a vbrif flowfilter    Tenant1    vBridge1    if1    ${flowfilterDscpdata}
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Succeed    h1    h3

Verify dscp action for vbrif flowfilter
    [Documentation]    Verify actions in Flow Enties for dscp
    Wait_Until_Keyword_Succeeds    20s    1s    Verify flowactions    ${dscp_action}    ${FF_DUMPFLOWS_OF13}

Remove vbrif Flowfilter index which have dscp
    [Documentation]    Remove a index of vbrif flowfilter which have DSCP
    Remove a vbrif flowfilter    Tenant1    vBridge1    if1    ${filter_index}

Add a vtn flowfilter with dl-src
    [Documentation]    Create a flowfilter with dl-src and Verify ping
    Add a vtn flowfilter    Tenant1    ${flowfilterdlsrc}
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Succeed    h1    h3

Verify dl-src action for vtn flowfilter
    [Documentation]    Verify actions in Flow Enties for dl-src
    Wait_Until_Keyword_Succeeds    20s    1s    Verify flowactions    ${dlsrc_actions}    ${FF_DUMPFLOWS_OF13}

Remove vtn Flowfilter index which have dl-src
    [Documentation]    Remove a index of vtn flowfilter which have DL_SRC
    Remove a vtn flowfilter    Tenant1    ${filter_index}

Add a vbr flowfilter with dl-src
    [Documentation]    Create a flowfilter with dl-src and Verify ping
    Add a vbr flowfilter    Tenant1    vBridge1    ${flowfilterdlsrc}
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Succeed    h1    h3

Verify dl-src action for vbr flowfilter
    [Documentation]    Verify actions in Flow Enties for dl-src
    Wait_Until_Keyword_Succeeds    20s    1s    Verify flowactions    ${dlsrc_actions}    ${FF_DUMPFLOWS_OF13}

Remove vbr Flowfilter index which have dl-src
    [Documentation]    Remove a index of vbr flowfilter which have DL_SRC
    Remove a vbr flowfilter    Tenant1    vBridge1    ${filter_index}

Add a vbrif flowfilter with dl-src
    [Documentation]    Create a flowfilter with dl-src and Verify ping
    Add a vbrif flowfilter    Tenant1    vBridge1    if1    ${flowfilterdlsrc}
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Succeed    h1    h3

Verify dl-src action for vbrif flowfilter
    [Documentation]    Verify actions in Flow Enties for dl-src
    Wait_Until_Keyword_Succeeds    20s    1s    Verify flowactions    ${dlsrc_actions}    ${FF_DUMPFLOWS_OF13}

Remove vbrif Flowfilter index which have dl-src
    [Documentation]    Remove a index of vbrif flowfilter which have DL_SRC
    Remove a vbrif flowfilter    Tenant1    vBridge1    if1    ${filter_index}

Add a flowfilter with inet4 for drop
    [Documentation]    Create a flowfilter with inet4 for drop action and Verify no pinging
    Add a vbrif flowfilter    Tenant1    vBridge1    if1    ${flowfilterInetdropdata}
    Wait_Until_Keyword_Succeeds    20s    1s    Mininet Ping Should Not Succeed    h1    h3

Verify Removed Flow Entry For Inet After Drop Action
    [Documentation]    Verify no flows between the hosts after drop
    Wait_Until_Keyword_Succeeds    20s    1s    Verify flowactions    ${drop_action}    ${DROP_DUMPFLOWS_OF13}

Delete a flowcondition
    [Documentation]    Delete a flowcondition
    Remove flowcondition    cond_1

Delete a vtn Tenant1
    [Documentation]    Delete vtn Tenant1
    Delete a vtn    Tenant1

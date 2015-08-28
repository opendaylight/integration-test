*** Settings ***
Documentation     OF1.3 Suite to cover TTL Actions
...               - Set IP TTL
...               - Decrement IP TTL
...               - Copy TTL outwards
...               - Copy TTL inwards
...               - Set MPLS TTL
...               - Decrement MPLS TTL
...
...               NOTE: for OVS, it appears that set_ttl, and both copy in/out are not supported, so need to skip those checks for now.
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Test Template     Create And Remove Flow
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           XML
Resource          ../../../libraries/FlowLib.robot
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py

*** Variables ***
${REST_CON}       /restconf/config/opendaylight-inventory:nodes
${GENERIC_ACTION_FLOW_FILE}    ${CURDIR}/../../../variables/xmls/genericActionFlow.xml
${ipv4_src}       10.1.2.0/24
${ipv4_dst}       40.4.0.0/16
${eth_type}       0x800
${eth_src}        00:00:00:01:23:ae
${eth_dst}        ff:ff:ff:ff:ff:ff
${node_id}        openflow:1
${set_ip_ttl_doc}    OF1.3: \ OFPAT_SET_NW_TTL = 23, /* IP TTL. */\n(currently not supported on OVS)
${dec_ttl_doc}    OF1.3: \ OFPAT_DEC_NW_TTL = 24, /* Decrement IP TTL. */
${copy_ttl_in_doc}    OFPAT_COPY_TTL_IN = 12, /* Copy TTL "inwards" -- from outermost to\nnext-to-outermost */\n(currently NOT supported in OVS)\n
${copy_ttl_out_doc}    OFPAT_COPY_TTL_OUT = 11, /* Copy TTL "outwards" -- from next-to-outermost\nto outermost */\n(currently NOT suported in OVS)
${set_mpls_ttl_doc}    OFPAT_SET_MPLS_TTL = 15, /* MPLS TTL */
${dec_mpls_ttl_doc}    OFPAT_DEC_MPLS_TTL = 16, /* Decrement MPLS TTL */

*** Test Cases ***    ODL flow action        action key             action value    tableID    flowID    priority    verify OVS?    OVS specific string?
Set_IP_TTL            [Documentation]        ${set_ip_ttl_doc}
                      [Tags]                 ttl                    set
                      set-nw-ttl-action      nw-ttl                 1               2          101       10          no             set_ttl

Dec_TTL               [Documentation]        ${dec_ttl_doc}
                      [Tags]                 ttl                    dec
                      dec-nw-ttl             none                   none            3          305       311          yes            dec_ttl

Copy_TTL_In           [Documentation]        ${copy_ttl_in_doc}
                      [Tags]                 ttl                    copyin
                      copy-ttl-in            none                   none            9          202       9          no             copy_ttl_in

Copy_TTL_Out          [Documentation]        ${copy_ttl_out_doc}
                      [Tags]                 ttl                    copyout
                      copy-ttl-out           none                   none            8          909       4242          no             copy_ttl_out

Set_MPLS_TTL          [Documentation]        ${set_mpls_ttl_doc}
                      [Tags]                 ttl                    setmpls
                      set-mpls-ttl-action    mpls-ttl               1               4          505       9021          yes            set_mpls_ttl

Dec_MPLS_TTL          [Documentation]        ${dec_mpls_ttl_doc}
                      [Tags]                 ttl                    decmpls
                      dec-mpls-ttl           none                   none            2          1001      81          yes            dec_mpls_ttl

*** Keywords ***
Create And Remove Flow
    [Arguments]    ${flow_action}    ${action_key}    ${action_value}    ${table_id}    ${flow_id}    ${priority}
    ...    ${verify_switch_flag}    ${additional_ovs_flowelements}
    @{OVS_FLOWELEMENTS}    Create List    dl_dst=${eth_dst}    table=${table_id}    dl_src=${eth_src}    nw_src=${ipv4_src}    nw_dst=${ipv4_dst}
    ...    ${additional_ovs_flowelements}
    ##The dictionaries here will be used to populate the match and action elements of the flow mod
    ${ethernet_match_dict}=    Create Dictionary    type=${eth_type}    destination=${eth_dst}    source=${eth_src}
    ${ipv4_match_dict}=    Create Dictionary    source=${ipv4_src}    destination=${ipv4_dst}
    ##flow is a python Object to build flow details, including the xml format to send to controller
    ${flow}=    Create Inventory Flow
    Set "${flow}" "table_id" With "${table_id}"
    Set "${flow}" "id" With "${flow_id}"
    Set "${flow}" "priority" With "${priority}"
    Clear Flow Actions    ${flow}
    Set Flow Action    ${flow}    0    0    ${flow_action}
    Set Flow Ethernet Match    ${flow}    ${ethernet_match_dict}
    Set Flow IPv4 Match    ${flow}    ${ipv4_match_dict}
    ##If the ${flow_action} contains the string "set" we need to include a deeper action detail (e.g. set-ttl needs a element to indicate the value to set it to)
    Run Keyword If    "set" in "${flow_action}"    Add Flow XML Element    ${flow}    ${action_key}    ${action_value}    instructions/instruction/apply-actions/action/${flow_action}
    Log    Flow XML is ${flow.xml}
    Add Flow To Controller And Verify    ${flow.xml}    ${node_id}    ${flow.table_id}    ${flow.id}
    Run Keyword If    "${verify_switch_flag}" == "yes"    Verify Flow On Mininet Switch    ${OVS_FLOWELEMENTS}
    Remove Flow From Controller And Verify    ${flow.xml}    ${node_id}    ${flow.table_id}    ${flow.id}
    Run Keyword If    "${verify_switch_flag}" == "yes"    Verify Flow Does Not Exist On Mininet Switch    ${OVS_FLOWELEMENTS}

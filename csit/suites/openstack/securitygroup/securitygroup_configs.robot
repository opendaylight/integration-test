*** Settings ***
Documentation           Test Suite for Security_groups basic configuration and validation same in ODL and verify the SG Flows
Suite Setup             Start Suite
Suite Teardown         Stop Suite
Library                 String
Library                 RequestsLibrary
Library                 SSHLibrary
Library                 Collections
Library                 json
Library                 OperatingSystem
Resource                ../../../libraries/Utils.robot
Resource                ../../../libraries/OpenStackOperations.robot
Resource                ../../../libraries/DevstackUtils.robot
Resource                ../../../libraries/SetupUtils.robot
Resource                ../../../libraries/KarafKeywords.robot
Resource                ../../../libraries/OVSDB.robot
Resource                ../../../variables/Variables.robot
Resource                ../../../variables/netvirt/Variables.robot


*** Variables ***
${DEFAULT_SG}    default
${CUSTOM_SG}    customsg
@{SECURITY_GROUP}    sg1    sg2    sg3    sg4    sg5    sg6
@{NETWORKS}    sg_net_1    sg_net_2
@{SUBNETS}    sg_sub_1    sg_sub_2
${ROUTER}    sg_router
@{PORT_NAME}    PORT1    PORT2    PORT3    PORT4
@{NET_1_VMS}    net_1_sg1_vm_1    net_1_sg1_vm_2    net_1_sg1_vm_3    net_1_sg1_vm_4     net_1_sg1_vm_5    net_1_sg1_vm_6
@{NET_2_VMS}    net_2_sg2_vm_1    net_2_sg2_vm_2
@{SUBNET_CIDRS}    10.0.0.0/24    20.0.0.0/24
@{EGRESS_TABLES}    table=210    table=211    table=212    table=213    table=214    table=215    table=216    table=217
@{INGRESS_TABLES}    table=239    table=240    table=241    table=242    table=243    table=244    table=245    table=246    table=247
@{ACL_Anti_Spoofing_Tables}    table=210    table=240
@{ACL_Conntrack_Classifier_Tables}    table=211    table=241
@{ACL_Conntrack_Sender_Tables}    table=212    table=242
@{ACL_Existing_Traffic_Tables}    table=213    table=243
@{ACL_Filter_Cum_Dispature_Tables}    table=214    table=244
@{ACL_Rule_Based_Filter_Tables}    table=215    table=245
@{ACL_Remote_ACL_Tables}    table=216    table=246
@{ACL_Committer_Tables}    table=217    table=247
@{PROTOCOL_NAME}    icmp    tcp    udp    vrrp    ospf    sctp
@{PROTOCOL_NUM}    1    6    17    112    89    132
${SEC_GROUP_URI_JSON}    /restconf/config/neutron:neutron/security-groups/
${SEC_RULE_URI_JSON}    /restconf/config/neutron:neutron/security-rules/
@{DPN1_VM_NAMES}    SGVM1_DPN1   SGVM2_DPN1
@{DPN2_VM_NAMES}    SGVM1_DPN2   SGVM2_DPN2
${dump_flows}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int


*** Test Cases ***
TC_01_Verify security group default flows are getting configured in Flow table
    [Documentation]    This test case validates the default security group flows in the ACL pipeline flow.
    [Tags]    Regression
   # ${defalut_flows}=     OpenStackOperations.OpenStack CLI     sudo ovs-ofctl dump-flows br-int -OOPenflow13
    ${defalut_flows}     Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows}
    log    ${defalut_flows}
    : FOR    ${egress_FT}    IN    @{EGRESS_TABLES}
    \    ${resp} =    BuiltIn.Should Contain    ${defalut_flows}    ${egress_FT}
    log    All egress tables passed
    : FOR    ${ingress_FT}    IN    @{INGRESS_TABLES}
    \    ${resp} =    BuiltIn.Should Contain    ${defalut_flows}    ${ingress_FT}
    log    All ingress tables passed

TC_02_Verify the default security group is getting created by default and validate same is getting reflected in ODL
    [Documentation]    This test case validates the default security group is getting created by default and validate same is getting reflected in ODL.
    [Tags]    Regression
    ${SG_LIST}=     List Security Groups
    log       ${SG_LIST}
    Should Contain    ${SG_LIST}    default
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}     headers=${HEADERS_XML}
    ${resp}    RequestsLibrary.Get Request    session    ${SEC_GROUP_URI_JSON}
    Log    ${resp.content}
    Should Contain    ${resp.content}   ${DEFAULT_SG}

TC_03_Verify the default security group rules and validate same is getting reflected in ODL
    [Documentation]    This test case validates default security group rules and validate same is getting reflected in ODL
    [Tags]    Regression
    ${default_rules}=     OpenStackOperations.OpenStack CLI     openstack security group show default
    log    ${default_rules}
    Should Contain    ${default_rules}    direction='ingress'      ethertype='IPv4'    remote_group_id=
    Should Contain    ${default_rules}    direction='egress'       ethertype='IPv4'
    Should Contain    ${default_rules}    direction='ingress'      ethertype='IPv6'    remote_group_id=
    Should Contain    ${default_rules}    direction='egress'       ethertype='IPv6'
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}     headers=${HEADERS_XML}
    ${resp}    RequestsLibrary.Get Request    session    ${SEC_RULE_URI_JSON}
    Log    ${resp.content}
    ${sg_rules_output} =    OpenStack CLI    openstack security group rule list ${DEFAULT_SG} -cID -fvalue
    @{sg_rules} =    String.Split String    ${sg_rules_output}    \n
    : FOR    ${rule}    IN    @{sg_rules}
    \    Should Contain    ${resp.content}    ${rule}

TC_04_05_Verify Custom Security group is getting created and validate same in the ODL
    [Documentation]     This test case validates Custom Security group is getting created and validate same in the ODL. [TC-04+TC-05]
    [Tags]    Regression
    ${OUTPUT}    ${SGP_ID}    Neutron Security Group Create    @{SECURITY_GROUP}[2]
    Set Global Variable    ${SGP_ID}
    ${custom_sg}=     OpenStackOperations.OpenStack CLI     openstack security group list
    Should Contain    ${custom_sg}    @{SECURITY_GROUP}[2]
    ${custom_sg_defaultrules}=     OpenStackOperations.OpenStack CLI     openstack security group show @{SECURITY_GROUP}[2]
    Should Contain    ${custom_sg_defaultrules}    direction='egress'       ethertype='IPv4'
    Should Contain    ${custom_sg_defaultrules}    direction='egress'       ethertype='IPv6'
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}     headers=${HEADERS_XML}
    ${resp}    RequestsLibrary.Get Request    session    ${SEC_GROUP_URI_JSON}
    Log    ${resp.content}
    Should Contain    ${resp.content}   @{SECURITY_GROUP}[2]
    ${resp}    RequestsLibrary.Get Request    session    ${SEC_RULE_URI_JSON}
    Log    ${resp.content}
    ${sg_rules_output} =    OpenStack CLI    openstack security group rule list @{SECURITY_GROUP}[2] -cID -fvalue
    @{sg_rules} =    String.Split String    ${sg_rules_output}    \n
    : FOR    ${rule}    IN    @{sg_rules}
    \    Should Contain    ${resp.content}    ${rule}

TC_06_07_Verify security group custom rule with direction ingress/egress and verify in the SG
     [Documentation]    This test case validates Custom Security group is getting created and validate same in the ODL. [TC-06-07]
     [Tags]    Regression
     OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=ingress     protocol=tcp    remote_group_id=@{SECURITY_GROUP}[2]
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[2]    direction=egress      protocol=tcp    remote_group_id=@{SECURITY_GROUP}[2]
    ${customsg_customrules}=     OpenStackOperations.OpenStack CLI      openstack security group show @{SECURITY_GROUP}[2]
    log      ${customsg_customrules}
    Should Contain    ${customsg_customrules}    direction='ingress'      protocol=tcp
    Should Contain    ${customsg_customrules}    direction='egress'       protocol=tcp
    ${resp}    RequestsLibrary.Get Request    session    ${SEC_RULE_URI_JSON}
    Log    ${resp.content}
    ${sg_rules_output} =    OpenStack CLI    openstack security group rule list @{SECURITY_GROUP}[2] -cID -fvalue
    @{sg_rules} =    String.Split String    ${sg_rules_output}    \n
    : FOR    ${rule}    IN    @{sg_rules}
    \    Should Contain    ${resp.content}    ${rule}

TC_08_Verify security group rule with protocol Name in default security group(TCP/ICMP/UDP/SCTP/VRRP/OSPF) and validate ODL
     [Documentation]    This test case validates security group rule with protocol Name in default security group and validate same in the ODL.
     [Tags]    Regression
    : FOR    ${ingress_rules}    IN    @{PROTOCOL_NAME}
    \    ${rule_create} =    OpenStackOperations.Neutron Security Group Rule Create    ${DEFAULT_SG}    direction=egress    protocol=${ingress_rules}    remote-ip=0.0.0.0/24
    \    ${rule_create} =    OpenStackOperations.Neutron Security Group Rule Create    ${DEFAULT_SG}    direction=ingress    protocol=${ingress_rules}    remote-ip=0.0.0.0/24
    ${SG_rules_Protocolname}=     OpenStackOperations.OpenStack CLI     openstack security group show default
    log     ${SG_rules_Protocolname}
    Should Contain    ${SG_rules_Protocolname}     @{PROTOCOL_NAME}[0]    @{PROTOCOL_NAME}[1]    @{PROTOCOL_NAME}[2]
    Should Contain    ${SG_rules_Protocolname}     @{PROTOCOL_NAME}[3]    @{PROTOCOL_NAME}[4]    @{PROTOCOL_NAME}[5]
    ${resp}    RequestsLibrary.Get Request    session    ${SEC_RULE_URI_JSON}
    Log    ${resp.content}
    ${sg_rules_output} =    OpenStack CLI    openstack security group rule list ${DEFAULT_SG} -cID -fvalue
    @{sg_rules} =    String.Split String    ${sg_rules_output}    \n
    : FOR    ${rule}    IN    @{sg_rules}
    \    Should Contain    ${resp.content}    ${rule}

TC_09_Verify security group rule with protocol Number in custom security group and validate ODL
     [Documentation]    This test case validates security group rule with protocol Number in Custom security group and validate same in the ODL.
     [Tags]    Regression
     Security Group Create Without Default Security Rules       @{SECURITY_GROUP}[3]
     : FOR    ${ingress_rules_num}    IN    @{PROTOCOL_NUM}
     \    ${rule_create_num} =    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=egress    protocol=${ingress_rules_num}    remote-ip=0.0.0.0/24
     \    ${rule_create_num} =    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[3]    direction=ingress    protocol=${ingress_rules_num}    remote-ip=0.0.0.0/24
    ${SG_rules_Protocolnum}=     OpenStackOperations.OpenStack CLI     openstack security group show @{SECURITY_GROUP}[3]
    log     ${SG_rules_Protocolnum}
    Should Contain    ${SG_rules_Protocolnum}     @{PROTOCOL_NUM}[0]    @{PROTOCOL_NUM}[1]    @{PROTOCOL_NUM}[2]
    Should Contain    ${SG_rules_Protocolnum}     @{PROTOCOL_NUM}[3]    @{PROTOCOL_NUM}[4]    @{PROTOCOL_NUM}[5]
    ${resp}    RequestsLibrary.Get Request    session    ${SEC_RULE_URI_JSON}
    Log    ${resp.content}
    ${sg_rules_output} =    OpenStack CLI    openstack security group rule list @{SECURITY_GROUP}[3] -cID -fvalue
    @{sg_rules} =    String.Split String    ${sg_rules_output}    \n
    : FOR    ${rule}    IN    @{sg_rules}
    \    Should Contain    ${resp.content}    ${rule}

TC_10_Verify security group rule with remote IP prefix and validate the Flow entry
     [Documentation]    This test case validates security group rule with remote security group id in custom security group and validate the corresponding flow is getting created in the ACL  Rule based Filter table
    [Tags]    Regression
    Security Group Create Without Default Security Rules       @{SECURITY_GROUP}[4]
    OpenStackOperations.Neutron Security Group Rule Create     @{SECURITY_GROUP}[4]    direction=ingress     protocol=icmp      remote-ip=0.0.0.0/24
    OpenStackOperations.Neutron Security Group Rule Create     @{SECURITY_GROUP}[4]    direction=egress      protocol=icmp      remote-ip=0.0.0.0/24
    OpenStackOperations.Create Vm Instance On Compute Node     @{NETWORKS}[0]    @{NET_1_VMS}[2]    ${OS_CMP1_HOSTNAME}    sg=@{SECURITY_GROUP}[4]
#    ${ingress_rule_flow}    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.OpenStack CLI      sudo ovs-ofctl dump-flows br-int -OOPenflow13 | grep table=244 | grep icmp
#    ${egress_rule_flow}    BuiltIn.Wait Until Keyword Succeeds    30s    10s     OpenStackOperations.OpenStack CLI      sudo ovs-ofctl dump-flows br-int -OOPenflow13 | grep table=214 | grep icmp
    ${ingress_rule_flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows} | grep @{ACL_Filter_Cum_Dispature_Tables}[1]| grep @{PROTOCOL_NAME}[0]
    ${egress_rule_flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows} | grep @{ACL_Filter_Cum_Dispature_Tables}[0]| grep @{PROTOCOL_NAME}[0]
    BuiltIn.Run Keyword And Ignore Error    Delete Vm Instance    @{NET_1_VMS}[2]
TC_11_Verify security group rule with remote group ID and validate the Flow entry
    [Documentation]    This test case validates Verify security group rule with remote security group id in custom security group and validate the corresponding flow is getting created in the ACL  Rule based Filter table
    [Tags]    Regression
    Security Group Create Without Default Security Rules       @{SECURITY_GROUP}[5]
    OpenStackOperations.Neutron Security Group Rule Create     @{SECURITY_GROUP}[5]    direction=ingress     protocol=icmp      remote_group_id=@{SECURITY_GROUP}[5]
    OpenStackOperations.Neutron Security Group Rule Create     @{SECURITY_GROUP}[5]    direction=egress      protocol=icmp      remote_group_id=@{SECURITY_GROUP}[5]
    OpenStackOperations.Create Vm Instance On Compute Node     @{NETWORKS}[0]    @{NET_1_VMS}[3]    ${OS_CMP1_HOSTNAME}    sg=@{SECURITY_GROUP}[5]
#    ${ingress_rule_flow}    BuiltIn.Wait Until Keyword Succeeds    30s    10s     OpenStackOperations.OpenStack CLI      sudo ovs-ofctl dump-flows br-int -OOPenflow13 | grep table=245 | grep icmp
#    ${egress_rule_flow}    BuiltIn.Wait Until Keyword Succeeds    30s    10s     OpenStackOperations.OpenStack CLI      sudo ovs-ofctl dump-flows br-int -OOPenflow13 | grep table=215 | grep icmp
    ${ingress_rule_flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows} | grep @{ACL_Rule_Based_Filter_Tables}[1]| grep @{PROTOCOL_NAME}[0]
    ${egress_rule_flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows} | grep @{ACL_Rule_Based_Filter_Tables}[0]| grep @{PROTOCOL_NAME}[0]
    BuiltIn.Run Keyword And Ignore Error    Delete Vm Instance    @{NET_1_VMS}[3]
TC_12_Verify security group rules getting deleted with protocol name in default security group
    [Documentation]    This test case validates deletion of security group rules those are created with protocol name
    [Tags]    Regression
    : FOR    ${sg_rules}    IN    @{PROTOCOL_NAME}
    \       ${sg_rules_delete}=     Delete Specific Security Group Rules with Protocol Names    ${DEFAULT_SG}    ${sg_rules}
    log     Custom Rules Deleted
    ${SG_rules_Protocolname_delete}=     OpenStackOperations.OpenStack CLI     openstack security group show default
    log     ${SG_rules_Protocolname_delete}
    Should Not Contain    ${SG_rules_Protocolname_delete}     @{PROTOCOL_NAME}[0]    @{PROTOCOL_NAME}[1]    @{PROTOCOL_NAME}[2]
    Should Not Contain    ${SG_rules_Protocolname_delete}     @{PROTOCOL_NAME}[3]    @{PROTOCOL_NAME}[4]    @{PROTOCOL_NAME}[5]

TC_13_Verify security group rules getting deleted with protocol Number in Custom security group
    [Documentation]    This test case validates deletion of security group rules those are created with protocol number
    [Tags]    Regression
    : FOR    ${sg_rules_num}    IN    @{PROTOCOL_NUM}
    \       ${sg_rules_delete_num}=     Delete Specific Security Group Rules with Protocol Number    @{SECURITY_GROUP}[3]    ${sg_rules_num}
    log     Custom Rules Deleted
    ${SG_rules_Protocolnum_delete}=     OpenStackOperations.OpenStack CLI     openstack security group show @{SECURITY_GROUP}[3]
    log     ${SG_rules_Protocolnum_delete}

TC_14_Verify addition and deletion of security group rules dynamically with IP Prefix in Custom SG

    [Documentation]    This test case validates addition and deletion of security group rules dynamically with IP Prefix in Custom SG also verify the table 214/244
    [Tags]    Regression
    ${OUTPUT_TCPI}    ${RULE_ID_TCPI}    OpenStackOperations.Neutron Security Group Rule Create     @{SECURITY_GROUP}[4]    direction=ingress     protocol=tcp      remote-ip=0.0.0.0/24
    ${OUTPUT_TCPE}    ${RULE_ID_TCPE}    OpenStackOperations.Neutron Security Group Rule Create     @{SECURITY_GROUP}[4]    direction=egress      protocol=tcp       remote-ip=0.0.0.0/24
    OpenStackOperations.Create Vm Instance On Compute Node     @{NETWORKS}[0]    @{NET_1_VMS}[4]    ${OS_CMP1_HOSTNAME}    sg=@{SECURITY_GROUP}[4]
#    ${ingress_tcprule_flow}    BuiltIn.Wait Until Keyword Succeeds    30s    10s   OpenStackOperations.OpenStack CLI      sudo ovs-ofctl dump-flows br-int -OOPenflow13 | grep table=244 | grep tcp
#    ${egress_tcprule_flow}    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.OpenStack CLI      sudo ovs-ofctl dump-flows br-int -OOPenflow13 | grep table=214 | grep tcp
    ${ingress_tcprule_flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows} | grep @{ACL_Filter_Cum_Dispature_Tables}[1] | grep @{PROTOCOL_NAME}[1] 
    ${egress_tcprule_flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows} | grep @{ACL_Filter_Cum_Dispature_Tables}[0]| grep @{PROTOCOL_NAME}[1]
    log    ${OUTPUT_TCPI}
    log    ${RULE_ID_TCPI}
    Set Global Variable    ${RULE_ID_TCPI}
    Set Global Variable    ${RULE_ID_TCPE}
    Delete Specific Security Group Rules with Protocol Names     @{SECURITY_GROUP}[4]     ${RULE_ID_TCPI}
    Delete Specific Security Group Rules with Protocol Names     @{SECURITY_GROUP}[4]     ${RULE_ID_TCPE}
#    ${ingressrule_after_delete}   BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.OpenStack CLI      sudo ovs-ofctl dump-flows br-int -OOPenflow13 | grep table=244
#    ${egressrule_after_delete}    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.OpenStack CLI      sudo ovs-ofctl dump-flows br-int -OOPenflow13 | grep table=214
    ${ingressrule_after_delete}   Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows} | grep @{ACL_Filter_Cum_Dispature_Tables}[1]
    ${egressrule_after_delete}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows} | grep @{ACL_Filter_Cum_Dispature_Tables}[0]
    Should Not Contain    ${ingressrule_after_delete}    tcp
    Should Not Contain    ${egressrule_after_delete}    tcp
    ${resp}    RequestsLibrary.Get Request    session    ${SEC_RULE_URI_JSON}
    Log    ${resp.content}
    Should Not Contain    ${resp.content}    ${RULE_ID_TCPI}
    Should Not Contain    ${resp.content}    ${RULE_ID_TCPE}
    BuiltIn.Run Keyword And Ignore Error    Delete Vm Instance    @{NET_1_VMS}[4]

TC_15_Verify addition and deletion of security group rules dynamically with remote security group id in Custom SG

    [Documentation]    This test case validates addition and deletion of security group rules dynamically with with remote security group id in Custom SG also verify the table 215/245/246
    [Tags]    Regression
    ${OUTPUT_TCPI}    ${RULE_ID_TCPI}    OpenStackOperations.Neutron Security Group Rule Create     @{SECURITY_GROUP}[5]    direction=ingress     protocol=tcp      remote_group_id=@{SECURITY_GROUP}[5]
    ${OUTPUT_TCPE}    ${RULE_ID_TCPE}    OpenStackOperations.Neutron Security Group Rule Create     @{SECURITY_GROUP}[5]    direction=egress      protocol=tcp      remote_group_id=@{SECURITY_GROUP}[5]
    OpenStackOperations.Create Vm Instance On Compute Node     @{NETWORKS}[0]    @{NET_1_VMS}[5]    ${OS_CMP1_HOSTNAME}    sg=@{SECURITY_GROUP}[5]
#    ${ingress_tcprule_flow}     BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.OpenStack CLI      sudo ovs-ofctl dump-flows br-int -OOPenflow13 | grep table=245 | grep tcp
#    ${egress_tcprule_flow}     BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.OpenStack CLI      sudo ovs-ofctl dump-flows br-int -OOPenflow13 | grep table=215 | grep tcp
    ${ingress_tcprule_flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows} | grep @{ACL_Rule_Based_Filter_Tables}[1] | grep @{PROTOCOL_NAME}[1] 
    ${egress_tcprule_flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows} | grep @{ACL_Rule_Based_Filter_Tables}[0]| grep @{PROTOCOL_NAME}[1] 
    log    ${OUTPUT_TCPI}
    log    ${RULE_ID_TCPI}
    Set Global Variable    ${RULE_ID_TCPI}
    Set Global Variable    ${RULE_ID_TCPE}
    Delete Specific Security Group Rules with Protocol Names     @{SECURITY_GROUP}[5]     ${RULE_ID_TCPI}
    Delete Specific Security Group Rules with Protocol Names     @{SECURITY_GROUP}[5]     ${RULE_ID_TCPE}
#    ${ingressrule_after_delete}    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.OpenStack CLI      sudo ovs-ofctl dump-flows br-int -OOPenflow13 | grep table=245
#    ${egressrule_after_delete}    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.OpenStack CLI      sudo ovs-ofctl dump-flows br-int -OOPenflow13 | grep table=215
    ${ingressrule_after_delete}   Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows} | grep @{ACL_Rule_Based_Filter_Tables}[1]
    ${egressrule_after_delete}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows} | grep @{ACL_Rule_Based_Filter_Tables}[0]
    Should Not Contain    ${ingressrule_after_delete}    tcp
    Should Not Contain    ${egressrule_after_delete}    tcp
    ${resp}    RequestsLibrary.Get Request    session    ${SEC_RULE_URI_JSON}
    Log    ${resp.content}
    Should Not Contain    ${resp.content}    ${RULE_ID_TCPI}
    Should Not Contain    ${resp.content}    ${RULE_ID_TCPE}
    BuiltIn.Run Keyword And Ignore Error    Delete Vm Instance    @{NET_1_VMS}[5]

TC_16_Verify acl flow is is getting created for Remote Ip using remote group id rules in Custom SG
    [Documentation]    This test case validates acl flow is is getting created for Remote Ip using remote group id rules in Custom SG
    [Tags]    Regression
    log    ${vm1_ip_dpn1}
    log    ${vm2_ip_dpn2}
    ${ingress_icmprule_flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows} | grep @{ACL_Rule_Based_Filter_Tables}[1]| grep @{PROTOCOL_NAME}[0]
    ${egress_icmprule_flow}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows} | grep @{ACL_Rule_Based_Filter_Tables}[0]| grep @{PROTOCOL_NAME}[0]
    Should Contain    ${ingress_icmprule_flow}    icmp
    Should Contain    ${egress_icmprule_flow}    icmp
    ${Remote_ACL_Tables_VM1_Egress}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows} | grep @{ACL_Remote_ACL_Tables}[0] | grep nw_dst=
    ${Remote_ACL_Tables_VM1_Ingress}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows} | grep @{ACL_Remote_ACL_Tables}[1] | grep nw_src=
    Should Contain    ${Remote_ACL_Tables_VM1_Egress}    ${vm2_ip_dpn2}
    Should Contain    ${Remote_ACL_Tables_VM1_Ingress}   ${vm2_ip_dpn2}
    log   Compute node Login and validation
    ${ingress_tcprule_flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    ${dump_flows} | grep @{ACL_Rule_Based_Filter_Tables}[1]| grep @{PROTOCOL_NAME}[1]
    ${egress_tcprule_flow}    Run Command On Remote System    ${OS_COMPUTE_2_IP}    ${dump_flows} | grep @{ACL_Rule_Based_Filter_Tables}[0]| grep @{PROTOCOL_NAME}[1]
    Should Contain    ${ingress_tcprule_flow}    tcp
    Should Contain    ${egress_tcprule_flow}    tcp
    ${Remote_ACL_Tables_VM2_Egress}    Run Command On Remote System    ${OS_COMPUTE_2_IP}     grep @{ACL_Remote_ACL_Tables}[0] | grep nw_dst=
    ${Remote_ACL_Tables_VM2_Ingress}    Run Command On Remote System    ${OS_COMPUTE_2_IP}     grep @{ACL_Remote_ACL_Tables}[0] | grep nw_src=
    Should Contain    ${Remote_ACL_Tables_VM2_Egress}    ${vm1_ip_dpn1}
    Should Contain    ${Remote_ACL_Tables_VM2_Ingress}   ${vm1_ip_dpn1}
    BuiltIn.Run Keyword And Ignore Error    Delete Vm Instance    ${DPN1_VM_NAMES[0]}
    BuiltIn.Run Keyword And Ignore Error    Delete Vm Instance    ${DPN2_VM_NAMES[0]}
    log     VM Deletion success

*** Keywords ***
Start Suite
    [Documentation]    Test Suite for SG_156
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DevstackUtils.Devstack Suite Setup
    Create Setup
    #RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    #RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}

Create Setup
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create Network    @{NETWORKS}[1]
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS}[1]    @{SUBNET_CIDRS}[1]
    OpenStackOperations.Security Group Create Without Default Security Rules        @{SECURITY_GROUP}[0]
    OpenStackOperations.Security Group Create Without Default Security Rules        @{SECURITY_GROUP}[1]
    OpenStackOperations.Neutron Security Group Rule Create     @{SECURITY_GROUP}[0]    direction=ingress     protocol=icmp     remote_group_id=@{SECURITY_GROUP}[1]
    OpenStackOperations.Neutron Security Group Rule Create     @{SECURITY_GROUP}[0]    direction=egress      protocol=icmp     remote_group_id=@{SECURITY_GROUP}[1]
    OpenStackOperations.Neutron Security Group Rule Create     @{SECURITY_GROUP}[1]    direction=ingress     protocol=tcp      remote_group_id=@{SECURITY_GROUP}[0]
    OpenStackOperations.Neutron Security Group Rule Create     @{SECURITY_GROUP}[1]    direction=egress      protocol=tcp      remote_group_id=@{SECURITY_GROUP}[0]
    OpenStackOperations.Create Router       ${ROUTER}
    : FOR    ${interface}    IN    @{SUBNETS}
    \    OpenStackOperations.Add Router Interface    ${ROUTER}    ${interface}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    ${DPN1_VM_NAMES[0]}    ${OS_CMP1_HOSTNAME}    sg=@{SECURITY_GROUP}[0]
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    ${DPN2_VM_NAMES[0]}    ${OS_CMP2_HOSTNAME}    sg=@{SECURITY_GROUP}[1]
    ${vm1_ip_dpn1}    Wait Until Keyword Succeeds    240s    10s    Get VM IP    @{DPN1_VM_NAMES}[0]
    ${vm2_ip_dpn2}    Wait Until Keyword Succeeds    240s    10s    Get VM IP    @{DPN2_VM_NAMES}[0]
#   ${vm1_ip_dpn1}    Wait Until Keyword Succeeds    240s    10s   OpenStackOperations.Get VM IP   true     @{DPN1_VM_NAMES}[0]
#   ${vm1_ip_dpn1}    Wait Until Keyword Succeeds    240s    10s   OpenStackOperations.Get VM IP   true     @{DPN2_VM_NAMES}[0]
    BuiltIn.Set Suite Variable    ${vm1_ip_dpn1}
    BuiltIn.Set Suite Variable    ${vm2_ip_dpn2}
    log    ${vm1_ip_dpn1}
    log    ${vm2_ip_dpn2}

Delete Specific Security Group Rules with Protocol Names
    [Arguments]    ${sg_name}   ${protocol}
    [Documentation]    Delete specific security rules from a specified security group
    ${cmd}    Set Variable    openstack security group rule list ${sg_name}| grep ${protocol}| awk '{print $2}'
    ${sg_rules_output} =    OpenStackOperations.OpenStack CLI    ${cmd}
    @{sg_rules} =    String.Split String    ${sg_rules_output}    \n
    : FOR    ${rule}    IN    @{sg_rules}
    \    ${output} =    OpenStack CLI    openstack security group rule delete ${rule}

Delete Specific Security Group Rules with Protocol Number
    [Arguments]    ${sg_name}   ${protocol_num}
    [Documentation]    Delete specific security rules with protocol number from a specified security group
    ${cmd_num}   Set Variable    openstack security group rule list sg4| awk '{print $2,$4}'
    ${output} =    OpenStackOperations.OpenStack CLI    ${cmd_num}
    log     ${cmd_num}
    ${dict}    Get Regexp Matches     ${output}       ([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}) ([0-9]+)    2    1
    &{protocol_id}      Convert To Dictionary    ${dict}
    log many    &{protocol_id}
    :FOR     ${key}   IN   @{protocol_id.keys()}
    \     OpenStack CLI    openstack security group rule delete ${protocol_id["${key}"]}

Get VM IP
    [Documentation]    Show information of a given VM and grep for ip address. VM name should be sent as arguments.
    [Arguments]     ${vm_name}
    ${cmd}    Set Variable    openstack server show ${vm_name} | grep "addresses" | awk '{print $4}'
    ${output} =    OpenStack CLI     ${cmd}
    @{z}    Split String    ${output}    =
    [Return]    ${z[1]}


Stop Suite
    [Documentation]    Delete the created VMs, ports, subnet and networks
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    Log    Delete the VM instance
#    : FOR    ${VM1}   @{NET_1_VMS}
#    \    Run Keyword And Ignore Error    OpenStackOperations.Delete Vm Instance    ${VM1}
#    : FOR    ${VM2}   @{NET_2_VMS}
#    \    Run Keyword And Ignore Error    OpenStackOperations.Delete Vm Instance    ${VM2}
#    Log    Delete the Ports created
#    : FOR    ${port}    IN    @{PORT_NAME}
#    \    Run Keyword And Ignore Error    OpenStackOperations.Delete Port    ${port}
    Log    Delete the Security group created
    : FOR    ${sg}    IN    @{SECURITY_GROUP}
    \    Run Keyword And Ignore Error    OpenStackOperations.Delete SecurityGroup    ${sg}
    Log    remove interface to the router
    :FOR    ${interface}    IN   @{SUBNETS}
    \    Run Keyword And Ignore Error    Remove Interface    ${ROUTER}     ${interface}
    Log    Remove router
    Run Keyword And Ignore Error    Delete Router    ${ROUTER}
    Log    Delete-Subnet
    :FOR    ${Snet}    IN    @{SUBNETS}
    \    Run Keyword And Ignore Error    Delete SubNet    ${Snet}
    Log    Delete the Network Created
    : FOR    ${net}    IN    @{NETWORKS}
    \    Run Keyword And Ignore Error    OpenStackOperations.Delete Network    ${net}


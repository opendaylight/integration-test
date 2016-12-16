/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.aclservice.tests

import org.opendaylight.genius.mdsalutil.ActionInfoBuilder
import org.opendaylight.genius.mdsalutil.ActionType
import org.opendaylight.genius.mdsalutil.FlowEntity
import org.opendaylight.genius.mdsalutil.InstructionInfo
import org.opendaylight.genius.mdsalutil.InstructionType
import org.opendaylight.genius.mdsalutil.MatchFieldType
import org.opendaylight.genius.mdsalutil.MatchInfoBuilder
import org.opendaylight.genius.mdsalutil.MetaDataUtil
import org.opendaylight.genius.mdsalutil.NxMatchFieldType
import org.opendaylight.genius.mdsalutil.NxMatchInfoBuilder

import static extension org.opendaylight.mdsal.binding.testutils.XtendBuilderExtensions.operator_doubleGreaterThan

class FlowEntryObjectsStateless extends FlowEntryObjectsBase {

    static def fixedFlowsPort1() {
        #[ fixedIngressFlowsPort1, fixedEgressFlowsPort1 ]
    }

    static def etherFlows() {
        fixedIngressFlowsPort1
        + etherFlowIngressPort1
        + fixedEgressFlowsPort1
        + etherFlowEgressPort1
        + fixedIngressFlowsPort2
        + etherIngressFlowsPort2
        + fixedEgrssFlowsPort2
        + etheregressFlowPort2
    }

    static def tcpFlows() {
        fixedIngressFlowsPort1
        + tcpIngressFlowPort1
        + fixedEgressFlowsPort1
        + tcpEgressFlowPort1
        + fixedIngressFlowsPort2
        + tcpIngressFlowPort2
        + fixedEgrssFlowsPort2
        + tcpEgressFlowPort2
    }

    static def udpFlows() {
        fixedIngressFlowsPort1
        + fixedEgressFlowsPort1
        + fixedIngressFlowsPort2
        + fixedEgrssFlowsPort2
    }

    static def icmpFlows() {
        fixedIngressFlowsPort1
        + fixedEgressFlowsPort1
        + fixedIngressFlowsPort2
        + fixedEgrssFlowsPort2
    }

    static def dstRangeFlows() {
        fixedIngressFlowsPort1
        + fixedEgressFlowsPort1
        + tcpEgressRangeFlows
    }

    static def dstAllFlows() {
        fixedIngressFlowsPort1
        + fixedEgressFlowsPort1
    }

    static def icmpFlowsForTwoAclsHavingSameRules() {
        fixedIngressFlowsPort3
        + fixedEgressFlowsPort3
    }

    static def etherFlowIngressPort1() {
        #[
            new FlowEntity(123bi) => [
            cookie = 110100480bi
            flowId = "SYN_ETHERnullIngress98785cc3048-abc3-43cc-89b3-377341426ac7"
            flowName = "ACL_SYN_"
            instructionInfoList = #[
                new InstructionInfo(InstructionType.apply_actions, #[
                    new ActionInfoBuilder >> [
                        actionType = ActionType.nx_resubmit
                        actionValues = #[
                            "220"
                        ]
                    ]
                ])
            ]
            matchInfoList = #[
                new MatchInfoBuilder >> [
                    matchField = MatchFieldType.eth_type
                    matchValues = #[
                        2048L
                    ]
                ],
                new MatchInfoBuilder >> [
                    matchField = MatchFieldType.eth_type
                    matchValues = #[
                        2048L
                    ]
                ],
                new MatchInfoBuilder >> [
                    bigMatchValues = #[
                        1085217976614912bi,
                        1152920405095219200bi
                    ]
                    matchField = MatchFieldType.metadata
                ]
            ]
            priority = 61005
            tableId = 251 as short
        ]
     ]
 }
    static def etherFlowEgressPort1() {
        #[
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "SYN_ETHERnullEgress98785cc3048-abc3-43cc-89b3-377341426ac6"
                flowName = "ACL_SYN_"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            1152920405095219200bi
                        ]
                        matchField = MatchFieldType.metadata
                    ]
                ]
                priority = 61005
                tableId = 40 as short
            ]
        ]
    }
    static def etherIngressFlowsPort2() {
        #[
               new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "SYN_ETHERnullIngress98785cc3048-abc3-43cc-89b3-377341426ac7"
                flowName = "ACL_SYN_"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "220"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            1152920405095219200bi
                        ]
                        matchField = MatchFieldType.metadata
                    ]
                ]
                priority = 61005
                tableId = 251 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "SYN_ETHERnullIngress98785cc3048-abc3-43cc-89b3-377341426ac7"
                flowName = "ACL_SYN_"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "220"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            1152920405095219200bi
                        ]
                        matchField = MatchFieldType.metadata
                    ]
                ]
                priority = 61005
                tableId = 251 as short
            ]
        ]
    }

    static def etherEgressFlowsPort1() {
        #[
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "[SYN_ETHERnullIngress98785cc3048-abc3-43cc-89b3-377341426ac7"
        flowName = "ACL_SYN_"
        instructionInfoList = #[
            new InstructionInfo(InstructionType.apply_actions, #[
                new ActionInfoBuilder >> [
                    actionType = ActionType.nx_resubmit
                    actionValues = #[
                        "220"
                    ]
                ]
            ])
        ]
        matchInfoList = #[
            new MatchInfoBuilder >> [
                matchField = MatchFieldType.eth_type
                matchValues = #[
                    2048L
                ]
            ],
            new MatchInfoBuilder >> [
                matchField = MatchFieldType.eth_type
                matchValues = #[
                    2048L
                ]
            ],
            new MatchInfoBuilder >> [
                bigMatchValues = #[
                    1085217976614912bi,
                    1152920405095219200bi
                ]
                matchField = MatchFieldType.metadata
            ]
        ]
        priority = 61005
        tableId = 251 as short
            ]
        ]
    }

    static def etheregressFlowPort2() {
        #[
           new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "SYN_ETHERnullEgress98785cc3048-abc3-43cc-89b3-377341426ac6"
                flowName = "ACL_SYN_"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            1152920405095219200bi
                        ]
                        matchField = MatchFieldType.metadata
                    ]
                ]
                priority = 61005
                tableId = 40 as short
            ]
        ]
    }

    static def tcpIngressFlowPort1() {
        #[
                new FlowEntity(123bi) => [
                    cookie = 110100480bi
                    flowId = "SYN_TCP_DESTINATION_80_65535Ingress98785cc3048-abc3-43cc-89b3-377341426ac7"
                    flowName = "ACL_SYN_"
                    instructionInfoList = #[
                        new InstructionInfo(InstructionType.apply_actions, #[
                            new ActionInfoBuilder >> [
                                actionType = ActionType.nx_resubmit
                                actionValues = #[
                                    "220"
                                ]
                            ]
                        ])
                    ]
                    matchInfoList = #[
                        new MatchInfoBuilder >> [
                            matchField = MatchFieldType.eth_type
                            matchValues = #[
                                2048L
                            ]
                        ],
                        new MatchInfoBuilder >> [
                            matchField = MatchFieldType.eth_type
                            matchValues = #[
                                2048L
                            ]
                        ],
                        new NxMatchInfoBuilder >> [
                            matchField = NxMatchFieldType.nx_tcp_dst_with_mask
                            matchValues = #[
                                80L,
                                65535L
                            ]
                        ],
                        new MatchInfoBuilder >> [
                            matchField = MatchFieldType.ip_proto
                            matchValues = #[
                                6L
                            ]
                        ],
                        new MatchInfoBuilder >> [
                            bigMatchValues = #[
                                1085217976614912bi,
                                1152920405095219200bi
                            ]
                            matchField = MatchFieldType.metadata
                        ],
                        new MatchInfoBuilder >> [
                            matchField = MatchFieldType.tcp_flags
                            matchValues = #[
                                2L
                            ]
                        ]
                    ]
                    priority = 61005
                    tableId = 251 as short
                ]
        ]
    }

    static def tcpIngressFlowPort2() {
        #[
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "SYN_TCP_DESTINATION_80_65535Ingress98785cc3048-abc3-43cc-89b3-377341426ac7"
                flowName = "ACL_SYN_"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "220"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.nx_tcp_dst_with_mask
                        matchValues = #[
                            80L,
                            65535L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            6L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            1152920405095219200bi
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.tcp_flags
                        matchValues = #[
                            2L
                        ]
                    ]
                ]
                priority = 61005
                tableId = 251 as short
            ]
        ]
    }

    static def tcpEgressFlowPort1() {
        #[
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "SYN_TCP_DESTINATION_80_65535Egress98785cc3048-abc3-43cc-89b3-377341426ac6"
                flowName = "ACL_SYN_"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.nx_tcp_dst_with_mask
                        matchValues = #[
                            80L,
                            65535L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            6L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            1152920405095219200bi
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.tcp_flags
                        matchValues = #[
                            2L
                        ]
                    ]
                ]
                priority = 61005
                tableId = 40 as short
            ]
        ]
    }

    static def tcpEgressFlowPort2() {
        #[
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "SYN_TCP_DESTINATION_80_65535Egress98785cc3048-abc3-43cc-89b3-377341426ac6"
                flowName = "ACL_SYN_"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.nx_tcp_dst_with_mask
                        matchValues = #[
                            80L,
                            65535L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            6L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            1152920405095219200bi
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.tcp_flags
                        matchValues = #[
                            2L
                        ]
                    ]
                ]
                priority = 61005
                tableId = 40 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "SYN_TCP_DESTINATION_80_65535Egress98785cc3048-abc3-43cc-89b3-377341426ac6"
                flowName = "ACL_SYN_"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.nx_tcp_dst_with_mask
                        matchValues = #[
                            80L,
                            65535L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            6L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            1152920405095219200bi
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.tcp_flags
                        matchValues = #[
                            2L
                        ]
                    ]
                ]
                priority = 61005
                tableId = 40 as short
            ]
        ]
    }

    static def udpEgressFlowsPort1() {
        #[
             new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "UDP_DESTINATION_80_65535Egress98785cc3048-abc3-43cc-89b3-377341426ac6"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionKey = 2
                            actionType = ActionType.nx_conntrack
                            actionValues = #[
                                "1",
                                "0",
                                "5000",
                                "255"
                            ]
                        ],
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.nx_udp_dst_with_mask
                        matchValues = #[
                            80L,
                            65535L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            17L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.ct_state
                        matchValues = #[
                            33L,
                            33L
                        ]
                    ]
                ]
                priority = 61010
                tableId = 41 as short
            ]
        ]
    }

    static def udpIngressFlowsPort2() {
        #[
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "UDP_DESTINATION_80_65535_ipv4_remoteACL_interface_aap_AllowedAddressPairsKey "
                        +"[_macAddress=MacAddress [_value=0D:AA:D8:42:30:F3], _ipAddress=IpPrefixOrAddress "
                        +"[_ipPrefix=IpPrefix [_ipv4Prefix=Ipv4Prefix [_value=10.0.0.1/24]]]]"
                        +"Ingress98785cc3048-abc3-43cc-89b3-377341426ac7"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionKey = 2
                            actionType = ActionType.nx_conntrack
                            actionValues = #[
                                "1",
                                "0",
                                "5000",
                                "255"
                            ]
                        ],
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "220"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ipv4_source
                        stringMatchValues = #[
                            "10.0.0.1",
                            "24"
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.nx_udp_dst_with_mask
                        matchValues = #[
                            80L,
                            65535L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            17L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.ct_state
                        matchValues = #[
                            33L,
                            33L
                        ]
                    ]
                ]
                priority = 61010
                tableId = 252 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "UDP_DESTINATION_80_65535_ipv4_remoteACL_interface_aap_AllowedAddressPairsKey [_macAddress=MacAddress [_value=0D:AA:D8:42:30:F4], _ipAddress=IpPrefixOrAddress [_ipPrefix=IpPrefix [_ipv4Prefix=Ipv4Prefix [_value=10.0.0.2/24]]]]Ingress98785cc3048-abc3-43cc-89b3-377341426ac7"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionKey = 2
                            actionType = ActionType.nx_conntrack
                            actionValues = #[
                                "1",
                                "0",
                                "5000",
                                "255"
                            ]
                        ],
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "220"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ipv4_source
                        stringMatchValues = #[
                            "10.0.0.2",
                            "24"
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.nx_udp_dst_with_mask
                        matchValues = #[
                            80L,
                            65535L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            17L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.ct_state
                        matchValues = #[
                            33L,
                            33L
                        ]
                    ]
                ]
                priority = 61010
                tableId = 252 as short
            ]
        ]
    }

    static def udpEgressFlowsPort2() {
        #[
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "UDP_DESTINATION_80_65535Egress98785cc3048-abc3-43cc-89b3-377341426ac6"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionKey = 2
                            actionType = ActionType.nx_conntrack
                            actionValues = #[
                                "1",
                                "0",
                                "5000",
                                "255"
                            ]
                        ],
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.nx_udp_dst_with_mask
                        matchValues = #[
                            80L,
                            65535L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            17L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.ct_state
                        matchValues = #[
                            33L,
                            33L
                        ]
                    ]
                ]
                priority = 61010
                tableId = 41 as short
            ]
        ]
    }

    static def icmpIngressFlowsPort1() {
        #[
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "ICMP_V4_DESTINATION_23_Ingress98785cc3048-abc3-43cc-89b3-377341426ac7"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionKey = 2
                            actionType = ActionType.nx_conntrack
                            actionValues = #[
                                "1",
                                "0",
                                "5000",
                                "255"
                            ]
                        ],
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "220"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.icmp_v4
                        matchValues = #[
                            2L,
                            3L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            1L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.ct_state
                        matchValues = #[
                            33L,
                            33L
                        ]
                    ]
                ]
                priority = 61010
                tableId = 252 as short
            ]
        ]
    }

    static def icmpIngressFlowsPort2() {
        #[
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "ICMP_V4_DESTINATION_23_Ingress98785cc3048-abc3-43cc-89b3-377341426ac7"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionKey = 2
                            actionType = ActionType.nx_conntrack
                            actionValues = #[
                                "1",
                                "0",
                                "5000",
                                "255"
                            ]
                        ],
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "220"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.icmp_v4
                        matchValues = #[
                            2L,
                            3L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            1L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.ct_state
                        matchValues = #[
                            33L,
                            33L
                        ]
                    ]
                ]
                priority = 61010
                tableId = 252 as short
            ]
        ]
    }

    static def icmpEgressFlowsPort2() {
        #[
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "ICMP_V4_DESTINATION_23__ipv4_remoteACL_interface_aap_AllowedAddressPairsKey "
                        +"[_macAddress=MacAddress [_value=0D:AA:D8:42:30:F3], _ipAddress=IpPrefixOrAddress "
                        +"[_ipPrefix=IpPrefix [_ipv4Prefix=Ipv4Prefix [_value=10.0.0.1/24]]]]"
                        +"Egress98785cc3048-abc3-43cc-89b3-377341426ac6"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionKey = 2
                            actionType = ActionType.nx_conntrack
                            actionValues = #[
                                "1",
                                "0",
                                "5000",
                                "255"
                            ]
                        ],
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ipv4_destination
                        stringMatchValues = #[
                            "10.0.0.1",
                            "24"
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.icmp_v4
                        matchValues = #[
                            2L,
                            3L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            1L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.ct_state
                        matchValues = #[
                            33L,
                            33L
                        ]
                    ]
                ]
                priority = 61010
                tableId = 41 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "ICMP_V4_DESTINATION_23__ipv4_remoteACL_interface_aap_AllowedAddressPairsKey "
                        +"[_macAddress=MacAddress [_value=0D:AA:D8:42:30:F4], _ipAddress=IpPrefixOrAddress "
                        +"[_ipPrefix=IpPrefix [_ipv4Prefix=Ipv4Prefix [_value=10.0.0.2/24]]]]"
                        +"Egress98785cc3048-abc3-43cc-89b3-377341426ac6"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionKey = 2
                            actionType = ActionType.nx_conntrack
                            actionValues = #[
                                "1",
                                "0",
                                "5000",
                                "255"
                            ]
                        ],
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ipv4_destination
                        stringMatchValues = #[
                            "10.0.0.2",
                            "24"
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.icmp_v4
                        matchValues = #[
                            2L,
                            3L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            1L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.ct_state
                        matchValues = #[
                            33L,
                            33L
                        ]
                    ]
                ]
                priority = 61010
                tableId = 41 as short
            ]
        ]
    }

    static def udpIngressPortRangeFlows() {
        #[
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "UDP_DESTINATION_2000_65532Ingress98785cc3048-abc3-43cc-89b3-377341426ac7"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionKey = 2
                            actionType = ActionType.nx_conntrack
                            actionValues = #[
                                "1",
                                "0",
                                "5000",
                                "255"
                            ]
                        ],
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "220"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.nx_udp_dst_with_mask
                        matchValues = #[
                            2000L,
                            65532L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            17L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.ct_state
                        matchValues = #[
                            33L,
                            33L
                        ]
                    ]
                ]
                priority = 61010
                tableId = 252 as short
            ]
        ]
    }

    static def tcpEgressRangeFlows() {
        #[
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "SYN_TCP_DESTINATION_776_65534Egress98785cc3048-abc3-43cc-89b3-377341426ac6"
                flowName = "ACL_SYN_"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.nx_tcp_dst_with_mask
                        matchValues = #[
                            776L,
                            65534L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            6L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            1152920405095219200bi
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.tcp_flags
                        matchValues = #[
                            2L
                        ]
                    ]
                ]
                priority = 61005
                tableId = 40 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "SYN_TCP_DESTINATION_512_65280Egress98785cc3048-abc3-43cc-89b3-377341426ac6"
                flowName = "ACL_SYN_"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.nx_tcp_dst_with_mask
                        matchValues = #[
                            512L,
                            65280L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            6L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            1152920405095219200bi
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.tcp_flags
                        matchValues = #[
                            2L
                        ]
                    ]
                ]
                priority = 61005
                tableId = 40 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "SYN_TCP_DESTINATION_334_65534Egress98785cc3048-abc3-43cc-89b3-377341426ac6"
                flowName = "ACL_SYN_"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.nx_tcp_dst_with_mask
                        matchValues = #[
                            334L,
                            65534L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            6L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            1152920405095219200bi
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.tcp_flags
                        matchValues = #[
                            2L
                        ]
                    ]
                ]
                priority = 61005
                tableId = 40 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "SYN_TCP_DESTINATION_333_65535Egress98785cc3048-abc3-43cc-89b3-377341426ac6"
                flowName = "ACL_SYN_"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.nx_tcp_dst_with_mask
                        matchValues = #[
                            333L,
                            65535L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            6L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            1152920405095219200bi
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.tcp_flags
                        matchValues = #[
                            2L
                        ]
                    ]
                ]
                priority = 61005
                tableId = 40 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "SYN_TCP_DESTINATION_336_65520Egress98785cc3048-abc3-43cc-89b3-377341426ac6"
                flowName = "ACL_SYN_"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.nx_tcp_dst_with_mask
                        matchValues = #[
                            336L,
                            65520L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            6L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            1152920405095219200bi
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.tcp_flags
                        matchValues = #[
                            2L
                        ]
                    ]
                ]
                priority = 61005
                tableId = 40 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "SYN_TCP_DESTINATION_352_65504Egress98785cc3048-abc3-43cc-89b3-377341426ac6"
                flowName = "ACL_SYN_"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.nx_tcp_dst_with_mask
                        matchValues = #[
                            352L,
                            65504L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            6L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            1152920405095219200bi
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.tcp_flags
                        matchValues = #[
                            2L
                        ]
                    ]
                ]
                priority = 61005
                tableId = 40 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "SYN_TCP_DESTINATION_384_65408Egress98785cc3048-abc3-43cc-89b3-377341426ac6"
                flowName = "ACL_SYN_"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.nx_tcp_dst_with_mask
                        matchValues = #[
                            384L,
                            65408L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            6L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            1152920405095219200bi
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.tcp_flags
                        matchValues = #[
                            2L
                        ]
                    ]
                ]
                priority = 61005
                tableId = 40 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "SYN_TCP_DESTINATION_768_65528Egress98785cc3048-abc3-43cc-89b3-377341426ac6"
                flowName = "ACL_SYN_"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.nx_tcp_dst_with_mask
                        matchValues = #[
                            768L,
                            65528L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            6L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            1152920405095219200bi
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.tcp_flags
                        matchValues = #[
                            2L
                        ]
                    ]
                ]
                priority = 61005
                tableId = 40 as short
            ]
        ]
    }

   static def icmpIngressFlowsPort3() {
        #[
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "ICMP_V4_DESTINATION_23_Ingress98785cc3048-abc3-43cc-89b3-377341426ac7"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionKey = 2
                            actionType = ActionType.nx_conntrack
                            actionValues = #[
                                "1",
                                "0",
                                "5000",
                                "255"
                            ]
                        ],
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "220"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.icmp_v4
                        matchValues = #[
                            2L,
                            3L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            1L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.ct_state
                        matchValues = #[
                            33L,
                            33L
                        ]
                    ]
                ]
                priority = AclServiceTestBase.FLOW_PRIORITY_SG_1
                tableId = 252 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "ICMP_V4_DESTINATION_23_Ingress98785cc3048-abc3-43cc-89b3-377341426a22"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionKey = 2
                            actionType = ActionType.nx_conntrack
                            actionValues = #[
                                "1",
                                "0",
                                "5000",
                                "255"
                            ]
                        ],
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "220"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.icmp_v4
                        matchValues = #[
                            2L,
                            3L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            1L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.ct_state
                        matchValues = #[
                            33L,
                            33L
                        ]
                    ]
                ]
                priority = AclServiceTestBase.FLOW_PRIORITY_SG_2
                tableId = 252 as short
            ]
        ]
    }

    static def icmpEgressFlowsPort3() {
        #[
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "ICMP_V4_DESTINATION_23_Egress98785cc3048-abc3-43cc-89b3-377341426ac6"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionKey = 2
                            actionType = ActionType.nx_conntrack
                            actionValues = #[
                                "1",
                                "0",
                                "5000",
                                "255"
                            ]
                        ],
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.icmp_v4
                        matchValues = #[
                            2L,
                            3L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            1L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.ct_state
                        matchValues = #[
                            33L,
                            33L
                        ]
                    ]
                ]
                priority = AclServiceTestBase.FLOW_PRIORITY_SG_1
                tableId = 41 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "ICMP_V4_DESTINATION_23_Egress98785cc3048-abc3-43cc-89b3-377341426a21"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionKey = 2
                            actionType = ActionType.nx_conntrack
                            actionValues = #[
                                "1",
                                "0",
                                "5000",
                                "255"
                            ]
                        ],
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.icmp_v4
                        matchValues = #[
                            2L,
                            3L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            1L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ],
                    new NxMatchInfoBuilder >> [
                        matchField = NxMatchFieldType.ct_state
                        matchValues = #[
                            33L,
                            33L
                        ]
                    ]
                ]
                priority = AclServiceTestBase.FLOW_PRIORITY_SG_2
                tableId = 41 as short
            ]
        ]
    }
    static def expectedFlows(String mac) {
        // Code auto. generated by https://github.com/vorburger/xtendbeans
        #[
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "Ingress_DHCP_Server_v4123_987__Permit_"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "220"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            17L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.udp_dst
                        matchValues = #[
                            68L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.udp_src
                        matchValues = #[
                            67L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ]
                ]
                priority = 63010
                tableId = 251 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "Ingress_DHCP_Server_v6_123_987___Permit_"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "220"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            34525L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            17L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.udp_dst
                        matchValues = #[
                            546L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.udp_src
                        matchValues = #[
                            547L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ]
                ]
                priority = 63010
                tableId = 251 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "Ingress_ICMPv6_123_987_130_Permit_"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "220"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            34525L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            58L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.icmp_v6
                        matchValues = #[
                            130L,
                            0L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ]
                ]
                priority = 63010
                tableId = 251 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "Ingress_ICMPv6_123_987_135_Permit_"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "220"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            34525L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            58L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.icmp_v6
                        matchValues = #[
                            135L,
                            0L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ]
                ]
                priority = 63010
                tableId = 251 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "Ingress_ICMPv6_123_987_136_Permit_"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "220"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            34525L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            58L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.icmp_v6
                        matchValues = #[
                            136L,
                            0L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ]
                ]
                priority = 63010
                tableId = 251 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "Ingress_ARP_123_987"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "220"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2054L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ]
                ]
                priority = 63010
                tableId = 251 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "Egress_DHCP_Client_v4123_987__Permit_"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            17L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.udp_dst
                        matchValues = #[
                            67L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.udp_src
                        matchValues = #[
                            68L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ]
                ]
                priority = 63010
                tableId = 40 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "Egress_DHCP_Client_v6_123_987__Permit_"
                flowName = "ACL"
                instructionInfoList = #[
                    new InstructionInfo(InstructionType.apply_actions, #[
                        new ActionInfoBuilder >> [
                            actionType = ActionType.nx_resubmit
                            actionValues = #[
                                "17"
                            ]
                        ]
                    ])
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            34525L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            17L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.udp_dst
                        matchValues = #[
                            547L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.udp_src
                        matchValues = #[
                            546L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ]
                ]
                priority = 63010
                tableId = 40 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "Egress_DHCP_Server_v4123_987__Drop_"
                flowName = "ACL"
                instructionInfoList = #[
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            2048L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            17L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.udp_dst
                        matchValues = #[
                            68L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.udp_src
                        matchValues = #[
                            67L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ]
                ]
                priority = 63010
                tableId = 40 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "Egress_DHCP_Server_v6_123_987__Drop_"
                flowName = "ACL"
                instructionInfoList = #[
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            34525L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            17L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.udp_dst
                        matchValues = #[
                            546L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.udp_src
                        matchValues = #[
                            547L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ]
                ]
                priority = 63010
                tableId = 40 as short
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "Egress_ICMPv6_123_987_134_Drop_"
                flowName = "ACL"
                instructionInfoList = #[
                ]
                matchInfoList = #[
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.eth_type
                        matchValues = #[
                            34525L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.ip_proto
                        matchValues = #[
                            58L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.icmp_v6
                        matchValues = #[
                            134L,
                            0L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        bigMatchValues = #[
                            1085217976614912bi,
                            MetaDataUtil.METADATA_MASK_LPORT_TAG
                        ]
                        matchField = MatchFieldType.metadata
                    ]
                ]
                priority = 63020
                tableId = 40 as short
            ]
        ]
    }
}

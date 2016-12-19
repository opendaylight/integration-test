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

import static extension org.opendaylight.mdsal.binding.testutils.XtendBuilderExtensions.operator_doubleGreaterThan

class FlowEntryObjectsBase {

    static def fixedFlowsPort1() {
        #[ fixedIngressFlowsPort1, fixedEgressFlowsPort1 ]
    }

    static def fixedIngressFlowsPort1() {
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
            ]

            ]
    }

    static def fixedEgressFlowsPort1() {
        #[

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
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "Egress_ARP_123_0D:AA:D8:42:30:F3"
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
                            2054L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.arp_sha
                        stringMatchValues = #[
                            "0D:AA:D8:42:30:F3"
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
            ]
        ]
    }


    static def fixedIngressFlowsPort2() {
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
            ]
        ]
    }

    static def fixedEgrssFlowsPort2 () {
        #[
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
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "Egress_ARP_123_0D:AA:D8:42:30:F4"
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
                            2054L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.arp_sha
                        stringMatchValues = #[
                            "0D:AA:D8:42:30:F4"
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
            ]
        ]

    }

    static def fixedIngressFlowsPort3() {
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
            ]
        ]
    }

    static def fixedEgressFlowsPort3 () {
        #[
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
            ],
            new FlowEntity(123bi) => [
                cookie = 110100480bi
                flowId = "Egress_ARP_123_0D:AA:D8:42:30:F5"
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
                            2054L
                        ]
                    ],
                    new MatchInfoBuilder >> [
                        matchField = MatchFieldType.arp_sha
                        stringMatchValues = #[
                            "0D:AA:D8:42:30:F5"
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

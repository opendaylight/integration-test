/*
 * Copyright (c) 2016 NEC Corporation and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.openstack.netvirt.providers.openflow13.services;

import java.math.BigInteger;
import java.util.List;
import java.util.ArrayList;

import org.opendaylight.netvirt.openstack.netvirt.providers.openflow13.AbstractServiceInstance;
import org.opendaylight.netvirt.openstack.netvirt.providers.openflow13.Service;
import org.opendaylight.netvirt.openstack.netvirt.providers.ConfigInterface;
import org.opendaylight.netvirt.openstack.netvirt.api.L2ForwardingLearnProvider;
import org.opendaylight.netvirt.openstack.netvirt.api.LearnConstants;
import org.opendaylight.netvirt.openstack.netvirt.api.LearnConstants.LearnFlowModsType;
import org.opendaylight.netvirt.openstack.netvirt.providers.NetvirtProvidersProvider;
import org.opendaylight.netvirt.utils.mdsal.openflow.ActionUtils;
import org.opendaylight.netvirt.utils.mdsal.openflow.FlowUtils;
import org.opendaylight.netvirt.utils.mdsal.openflow.MatchUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.PortNumber;
import org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.list.Action;
import org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.list.ActionBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.list.ActionKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.FlowBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.flow.InstructionsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.flow.MatchBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.instruction.ApplyActionsCase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.instruction.ApplyActionsCaseBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.instruction.apply.actions._case.ApplyActions;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.instruction.apply.actions._case.ApplyActionsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.Instruction;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.InstructionKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.InstructionBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.NodeBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowjava.nx.match.rev140421.NxmNxReg;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowjava.nx.match.rev140421.NxmNxReg0;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowjava.nx.match.rev140421.NxmNxReg6;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.add.group.input.buckets.bucket.action.action.NxActionResubmitRpcAddGroupCaseBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.nx.action.resubmit.grouping.NxResubmitBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.dst.choice.grouping.dst.choice.DstNxRegCaseBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.flow.mod.spec.flow.mod.spec.FlowModAddMatchFromFieldCaseBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.flow.mod.spec.flow.mod.spec.FlowModAddMatchFromValueCaseBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.flow.mod.spec.flow.mod.spec.FlowModCopyFieldIntoFieldCaseBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.flow.mod.spec.flow.mod.spec.FlowModCopyValueIntoFieldCaseBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.flow.mod.spec.flow.mod.spec.FlowModOutputToPortCaseBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.flow.mod.spec.flow.mod.spec.flow.mod.add.match.from.field._case.FlowModAddMatchFromFieldBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.flow.mod.spec.flow.mod.spec.flow.mod.add.match.from.value._case.FlowModAddMatchFromValueBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.flow.mod.spec.flow.mod.spec.flow.mod.copy.field.into.field._case.FlowModCopyFieldIntoFieldBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.flow.mod.spec.flow.mod.spec.flow.mod.copy.value.into.field._case.FlowModCopyValueIntoFieldBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.flow.mod.spec.flow.mod.spec.flow.mod.output.to.port._case.FlowModOutputToPortBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.nodes.node.table.flow.instructions.instruction.instruction.apply.actions._case.apply.actions.action.action.NxActionLearnNodesNodeTableFlowApplyActionsCaseBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.nx.action.learn.grouping.NxLearnBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.nx.action.learn.grouping.nx.learn.FlowMods;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.nx.action.learn.grouping.nx.learn.FlowModsBuilder;
import org.osgi.framework.BundleContext;
import org.osgi.framework.ServiceReference;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.collect.Lists;

public class EgressAclLearnServiceUtil {

    /*
     * (Table:EgressAclLearnService) EgressACL Learning
     * Match: reg6 = LearnConstants.NxmOfFieldType.NXM_NX_REG6
     * Action: learn and resubmit to next table
     * "table=40,dl_src=fa:16:3e:d3:bb:8a,tcp,priority=61002,tcp_dst=22,actions=learn(table=39,idle_timeout=18000,fin_idle_timeout=300,
     * fin_hard_timeout=0,priority=61010, cookie=0x6900000,eth_type=0x800,nw_proto=6, NXM_OF_IP_SRC[]=NXM_OF_IP_DST[],NXM_OF_IP_DST[]=NXM_OF_IP_SRC[],
     * NXM_OF_TCP_SRC[]=NXM_OF_TCP_DST[],NXM_OF_TCP_DST[]=NXM_OF_TCP_SRC[],load:0x1->NXM_NX_REG6[0..7]),resubmit(,50)"
     */
    public static FlowBuilder programEgressAclLearnRuleForTcp(FlowBuilder flowBuilder, InstructionBuilder instructionBuilder, short learnTableId, short resubmitId) {
        List<Action> listAction = new ArrayList<>();

        // Create learn action

        /*
         * learn header
         * 0 1 2 3 4 5 6 7 idleTO hardTO prio cook flags table finidle finhard
         *
         * learn flowmod
         * 0 1 2 3 learnFlowModType srcField dstField FlowModNumBits
         */
        /*String[] header = new String[] {
                "18000", "0", "61010", "0", "0", "39", "300", "0"
        };*/
        String[] header = new String[] {
            String.valueOf(NetvirtProvidersProvider.getSecurityGroupTcpIdleTimeout()),
            String.valueOf(NetvirtProvidersProvider.getSecurityGroupTcpHardTimeout()),
            LearnConstants.LEARN_PRIORITY,
            "0",
            LearnConstants.DELETE_LEARNED_FLAG_VALUE,
            String.valueOf(learnTableId),
            String.valueOf(NetvirtProvidersProvider.getSecurityGroupTcpFinIdleTimeout()),
            String.valueOf(NetvirtProvidersProvider.getSecurityGroupTcpFinHardTimeout())
        };

        String[][] flowMod = new String[8][];
        //eth_type=0x800
        flowMod[0] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_VALUE.name(),
                Integer.toString(LearnConstants.ETHTYPE_IPV4),
                LearnConstants.NxmOfFieldType.NXM_OF_ETH_TYPE.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_ETH_TYPE.getFlowModHeaderLen() };
        flowMod[1] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_VALUE.name(),
                Integer.toString(LearnConstants.IP_PROT_TCP),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_PROTO.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_PROTO.getFlowModHeaderLen() };
        //nw_proto=6
        //NXM_OF_IP_SRC[]=NXM_OF_IP_DST[]
        flowMod[2] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_DST.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_SRC.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_DST.getFlowModHeaderLen()};
        // NXM_OF_IP_DST[]=NXM_OF_IP_SRC[]
        flowMod[3] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_SRC.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_DST.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_SRC.getFlowModHeaderLen()};
        //NXM_OF_TCP_SRC[]=NXM_OF_TCP_DST[]
        flowMod[4] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                LearnConstants.NxmOfFieldType.NXM_OF_TCP_DST.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_TCP_SRC.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_TCP_DST.getFlowModHeaderLen()};
        //NXM_OF_TCP_DST[]=NXM_OF_TCP_SRC[]
        flowMod[5] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                LearnConstants.NxmOfFieldType.NXM_OF_TCP_SRC.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_TCP_DST.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_TCP_SRC.getFlowModHeaderLen()};
       // NXM_NX_TUN_ID[]
        flowMod[6] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                LearnConstants.NxmOfFieldType.NXM_NX_TUN_ID.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_NX_TUN_ID.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_NX_TUN_ID.getFlowModHeaderLen() };
        flowMod[7] = new String[] {
                LearnConstants.LearnFlowModsType.COPY_FROM_VALUE.name(), "1",
                LearnConstants.NxmOfFieldType.NXM_NX_REG6.getHexType(), "8" };
        listAction.add(buildAction(0, header, flowMod));
        ActionBuilder ab = new ActionBuilder();
        ab = new ActionBuilder();
        ab.setAction(createResubmitActions(resubmitId));
        ab.setKey(new ActionKey(1));
        listAction.add(ab.build());
        ApplyActions applyActions = new ApplyActionsBuilder().setAction(listAction).build();
        ApplyActionsCase applyActionsCase = new ApplyActionsCaseBuilder().setApplyActions(applyActions).build();
        InstructionsBuilder instructionsBuilder = new InstructionsBuilder();
        List<Instruction> instructions = Lists.newArrayList();
        if(instructionBuilder == null) {
            instructionBuilder = new InstructionBuilder();
        }
        instructionBuilder.setInstruction(applyActionsCase);
        instructionBuilder.setOrder(0);
        instructionBuilder.setKey(new InstructionKey(0));
        instructions.add(instructionBuilder.build());
        // Add InstructionBuilder to the Instruction(s)Builder List
        instructionsBuilder.setInstruction(instructions);
        // Add InstructionsBuilder to FlowBuilder
        flowBuilder.setInstructions(instructionsBuilder.build());

        return flowBuilder;

    }

   /*
     * (Table:EgressAclLearnService) EgressACL Learning
     * Match: reg6 = LearnConstants.NxmOfFieldType.NXM_NX_REG6
     * Action: learn and resubmit to next table
     * "table=40,dl_src=fa:16:3e:d3:bb:8a,tcp,priority=61002,tcp_dst=22,actions=learn(table=39,idle_timeout=300,fin_idle_timeout=0,
     * fin_hard_timeout=0,priority=61010, cookie=0x6900000,eth_type=0x800,nw_proto=6, NXM_OF_IP_SRC[]=NXM_OF_IP_DST[],NXM_OF_IP_DST[]=NXM_OF_IP_SRC[],
     * NXM_OF_UDP_SRC[]=NXM_OF_UDP_DST[],NXM_OF_UDP_DST[]=NXM_OF_UDP_SRC[],load:0x1->NXM_NX_REG6[0..7]),resubmit(,50)"
     */
    public static FlowBuilder programEgressAclLearnRuleForUdp(FlowBuilder flowBuilder, InstructionBuilder instructionBuilder,short learnTableId, short resubmitId) {
        List<Action> listAction = new ArrayList<>();
        // Create learn action
        /*
         * learn header
         * 0 1 2 3 4 5 6 7 idleTO hardTO prio cook flags table finidle finhard
         *
         * learn flowmod
         * 0 1 2 3 learnFlowModType srcField dstField FlowModNumBits
         */
        /*String[] header = new String[] {
                "300", "0", "61010", "0", "0", "39", "0", "0"
        };*/
        String[] header = new String[] {
            String.valueOf(NetvirtProvidersProvider.getSecurityGroupUdpIdleTimeout()),
            String.valueOf(NetvirtProvidersProvider.getSecurityGroupUdpHardTimeout()),
            LearnConstants.LEARN_PRIORITY,
            "0",
            LearnConstants.DELETE_LEARNED_FLAG_VALUE,
            String.valueOf(learnTableId),
            "0",
            "0"
        };

        String[][] flowMod = new String[8][];
        //eth_type=0x800
        flowMod[0] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_VALUE.name(),
                Integer.toString(LearnConstants.ETHTYPE_IPV4),
                LearnConstants.NxmOfFieldType.NXM_OF_ETH_TYPE.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_ETH_TYPE.getFlowModHeaderLen() };
        flowMod[1] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_VALUE.name(),
                Integer.toString(LearnConstants.IP_PROT_UDP),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_PROTO.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_PROTO.getFlowModHeaderLen() };
        //nw_proto=6
        //NXM_OF_IP_SRC[]=NXM_OF_IP_DST[]
        flowMod[2] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_DST.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_SRC.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_DST.getFlowModHeaderLen()};
        // NXM_OF_IP_DST[]=NXM_OF_IP_SRC[]
        flowMod[3] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_SRC.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_DST.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_SRC.getFlowModHeaderLen()};
        //NXM_OF_TCP_SRC[]=NXM_OF_TCP_DST[]
        flowMod[4] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                LearnConstants.NxmOfFieldType.NXM_OF_UDP_DST.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_UDP_SRC.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_UDP_DST.getFlowModHeaderLen()};
        //NXM_OF_TCP_DST[]=NXM_OF_TCP_SRC[]
        flowMod[5] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                LearnConstants.NxmOfFieldType.NXM_OF_UDP_SRC.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_UDP_DST.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_UDP_SRC.getFlowModHeaderLen()};
     // NXM_NX_TUN_ID[]
        flowMod[6] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                LearnConstants.NxmOfFieldType.NXM_NX_TUN_ID.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_NX_TUN_ID.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_NX_TUN_ID.getFlowModHeaderLen() };
        flowMod[7] = new String[] {
                LearnConstants.LearnFlowModsType.COPY_FROM_VALUE.name(), LearnConstants.LEARN_MATCH_REG_VALUE,
                LearnConstants.NxmOfFieldType.NXM_NX_REG6.getHexType(), "8" };
        listAction.add(buildAction(0, header, flowMod));
        ActionBuilder ab = new ActionBuilder();
        ab = new ActionBuilder();
        ab.setAction(createResubmitActions(resubmitId));
        ab.setKey(new ActionKey(1));
        listAction.add(ab.build());
        ApplyActions applyActions = new ApplyActionsBuilder().setAction(listAction).build();
        ApplyActionsCase applyActionsCase = new ApplyActionsCaseBuilder().setApplyActions(applyActions).build();
        InstructionsBuilder instructionsBuilder = new InstructionsBuilder();
        List<Instruction> instructions = Lists.newArrayList();
        if(instructionBuilder == null) {
        instructionBuilder = new InstructionBuilder();
        }
        instructionBuilder.setInstruction(applyActionsCase);
        instructionBuilder.setOrder(0);
        instructionBuilder.setKey(new InstructionKey(0));
        instructions.add(instructionBuilder.build());
        // Add InstructionBuilder to the Instruction(s)Builder List
        instructionsBuilder.setInstruction(instructions);
        // Add InstructionsBuilder to FlowBuilder
        flowBuilder.setInstructions(instructionsBuilder.build());

        return flowBuilder;

    }

    /*
     * (Table:EgressAclLearnService) EgressACL Learning
     * Match: reg6 = LearnConstants.NxmOfFieldType.NXM_NX_REG6
     * Action: learn and resubmit to next table
     * "table=40,dl_src=fa:16:3e:d3:bb:8a,tcp,priority=61002,tcp_dst=22,actions=learn(table=39,idle_timeout=300,fin_idle_timeout=0,
     * fin_hard_timeout=0,priority=61010, cookie=0x6900000,eth_type=0x800,nw_proto=6, NXM_OF_IP_SRC[]=NXM_OF_IP_DST[],NXM_OF_IP_DST[]=NXM_OF_IP_SRC[],
     * NXM_OF_UDP_SRC[]=NXM_OF_UDP_DST[],NXM_OF_UDP_DST[]=NXM_OF_UDP_SRC[],load:0x1->NXM_NX_REG6[0..7]),resubmit(,50)"
     */
    public static FlowBuilder programEgressAclLearnRuleForIcmp(FlowBuilder flowBuilder, InstructionBuilder instructionBuilder, String icmpType, String icmpCode,short learnTableId, short resubmitId) {
        List<Action> listAction = new ArrayList<>();

        String[] header = new String[] {
            String.valueOf(NetvirtProvidersProvider.getSecurityGroupDefaultIdleTimeout()),
            String.valueOf(NetvirtProvidersProvider.getSecurityGroupDefaultHardTimeout()),
            LearnConstants.LEARN_PRIORITY,
            "0",
            LearnConstants.DELETE_LEARNED_FLAG_VALUE,
            String.valueOf(learnTableId),
            "0",
            "0"
        };

        String[][] flowMod = new String[7][];
        //eth_type=0x800
        flowMod[0] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_VALUE.name(),
                Integer.toString(LearnConstants.ETHTYPE_IPV4),
                LearnConstants.NxmOfFieldType.NXM_OF_ETH_TYPE.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_ETH_TYPE.getFlowModHeaderLen() };
        //nw_proto=1
        flowMod[1] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_VALUE.name(),
                Integer.toString(LearnConstants.IP_PROT_ICMP),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_PROTO.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_PROTO.getFlowModHeaderLen() };
        //NXM_OF_IP_SRC[]=NXM_OF_IP_DST[]
        flowMod[2] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_DST.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_SRC.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_DST.getFlowModHeaderLen()};
        // NXM_OF_IP_DST[]=NXM_OF_IP_SRC[]
        flowMod[3] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_SRC.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_DST.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_SRC.getFlowModHeaderLen()};
        //icmp_type=0
        flowMod[4] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_VALUE.name(),
                icmpType,
                LearnConstants.NxmOfFieldType.NXM_OF_ICMP_TYPE.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_ICMP_TYPE.getFlowModHeaderLen()};
        //icmp_code=0
        flowMod[5] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_VALUE.name(),
                icmpCode,
                LearnConstants.NxmOfFieldType.NXM_OF_ICMP_CODE.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_ICMP_CODE.getFlowModHeaderLen()};
        flowMod[6] = new String[] {
                LearnConstants.LearnFlowModsType.COPY_FROM_VALUE.name(), LearnConstants.LEARN_MATCH_REG_VALUE,
                LearnConstants.NxmOfFieldType.NXM_NX_REG6.getHexType(), "8" };
        listAction.add(buildAction(0, header, flowMod));
        ActionBuilder ab = new ActionBuilder();
        ab = new ActionBuilder();
        ab.setAction(createResubmitActions(resubmitId));
        ab.setKey(new ActionKey(1));
        listAction.add(ab.build());
        ApplyActions applyActions = new ApplyActionsBuilder().setAction(listAction).build();
        ApplyActionsCase applyActionsCase = new ApplyActionsCaseBuilder().setApplyActions(applyActions).build();
        InstructionsBuilder instructionsBuilder = new InstructionsBuilder();
        List<Instruction> instructions = Lists.newArrayList();

        if(instructionBuilder == null) {
            instructionBuilder = new InstructionBuilder();
        }
        instructionBuilder.setInstruction(applyActionsCase);
        instructionBuilder.setOrder(0);
        instructionBuilder.setKey(new InstructionKey(0));
        instructions.add(instructionBuilder.build());
        // Add InstructionBuilder to the Instruction(s)Builder List
        instructionsBuilder.setInstruction(instructions);

        // Add InstructionsBuilder to FlowBuilder
        flowBuilder.setInstructions(instructionsBuilder.build());

        return flowBuilder;

    }

    /*
     * (Table:EgressAclLearnService) EgressACL Learning
     * Match: reg6 = LearnConstants.NxmOfFieldType.NXM_NX_REG6
     * Action: learn and resubmit to next table
     * "table=40,dl_src=fa:16:3e:d3:bb:8a,priority=61003,icmp,dl_src=fa:16:3e:55:71:d1,actions=learn(table=39,idle_timeout=300,fin_idle_timeout=0,
     * fin_hard_timeout=0,priority=61010, cookie=0x6900000,eth_type=0x800,nw_proto=6, NXM_OF_IP_SRC[]=NXM_OF_IP_DST[],NXM_OF_IP_DST[]=NXM_OF_IP_SRC[],
     * NXM_OF_ICMP_TYPE=NXM_OF_ICMP_TYPE,NXM_OF_ICMP_CODE=NXM_OF_ICMP_CODE,load:0x1->NXM_NX_REG6[0..7]),resubmit(,50)"
     */
    public static FlowBuilder programEgressAclLearnRuleForIcmpAll(FlowBuilder flowBuilder, InstructionBuilder instructionBuilder, short learnTableId, short resubmitId) {
        List<Action> listAction = new ArrayList<>();

        String[] header = new String[] {
            String.valueOf(NetvirtProvidersProvider.getSecurityGroupDefaultIdleTimeout()),
            String.valueOf(NetvirtProvidersProvider.getSecurityGroupDefaultHardTimeout()),
            LearnConstants.LEARN_PRIORITY,
            "0",
            LearnConstants.DELETE_LEARNED_FLAG_VALUE,
            String.valueOf(learnTableId),
            "0",
            "0"
        };

        String[][] flowMod = new String[7][];
        //eth_type=0x800
        flowMod[0] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_VALUE.name(),
                Integer.toString(LearnConstants.ETHTYPE_IPV4),
                LearnConstants.NxmOfFieldType.NXM_OF_ETH_TYPE.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_ETH_TYPE.getFlowModHeaderLen() };
        //nw_proto=1
        flowMod[1] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_VALUE.name(),
                Integer.toString(LearnConstants.IP_PROT_ICMP),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_PROTO.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_PROTO.getFlowModHeaderLen() };
        //NXM_OF_IP_SRC[]=NXM_OF_IP_DST[]
        flowMod[2] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_DST.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_SRC.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_DST.getFlowModHeaderLen()};
        // NXM_OF_IP_DST[]=NXM_OF_IP_SRC[]
        flowMod[3] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_SRC.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_DST.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IP_SRC.getFlowModHeaderLen()};
         //NXM_OF_ICMP_TYPE=NXM_OF_ICMP_TYPE
        flowMod[4] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                LearnConstants.NxmOfFieldType.NXM_OF_ICMP_TYPE.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_ICMP_TYPE.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_ICMP_TYPE.getFlowModHeaderLen()};
        // NXM_OF_ICMP_CODE=NXM_OF_ICMP_CODE
        flowMod[5] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                LearnConstants.NxmOfFieldType.NXM_OF_ICMP_CODE.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_ICMP_CODE.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_ICMP_CODE.getFlowModHeaderLen()};
        flowMod[6] = new String[] {
                LearnConstants.LearnFlowModsType.COPY_FROM_VALUE.name(), LearnConstants.LEARN_MATCH_REG_VALUE,
                LearnConstants.NxmOfFieldType.NXM_NX_REG6.getHexType(), "8" };
        listAction.add(buildAction(0, header, flowMod));
        ActionBuilder ab = new ActionBuilder();
        ab.setAction(createResubmitActions(resubmitId));
        ab.setKey(new ActionKey(1));
        listAction.add(ab.build());
        ApplyActions applyActions = new ApplyActionsBuilder().setAction(listAction).build();
        ApplyActionsCase applyActionsCase = new ApplyActionsCaseBuilder().setApplyActions(applyActions).build();
        InstructionsBuilder instructionsBuilder = new InstructionsBuilder();
        List<Instruction> instructions = Lists.newArrayList();

        if(instructionBuilder == null) {
            instructionBuilder = new InstructionBuilder();
        }
        instructionBuilder.setInstruction(applyActionsCase);
        instructionBuilder.setOrder(0);
        instructionBuilder.setKey(new InstructionKey(0));
        instructions.add(instructionBuilder.build());
        // Add InstructionBuilder to the Instruction(s)Builder List
        instructionsBuilder.setInstruction(instructions);

        // Add InstructionsBuilder to FlowBuilder
        flowBuilder.setInstructions(instructionsBuilder.build());

        return flowBuilder;

    }

    /*
     * build Action
     *
     * copy from org.opendaylight.genius.mdsalutil.ActionType.learn
     */
    private static Action buildAction(int newActionKey, String[] header, String[][] actionValues) {
        NxLearnBuilder learnBuilder = new NxLearnBuilder();
        learnBuilder.setIdleTimeout(Integer.parseInt(header[0]));
        learnBuilder.setHardTimeout(Integer.parseInt(header[1]));
        learnBuilder.setPriority(Integer.parseInt(header[2]));
        learnBuilder.setCookie(BigInteger.valueOf(Long.valueOf(header[3])));
        learnBuilder.setFlags(Integer.parseInt(header[4]));
        learnBuilder.setTableId(Short.parseShort(header[5]));
        learnBuilder.setFinIdleTimeout(Integer.parseInt(header[6]));
        learnBuilder.setFinHardTimeout(Integer.parseInt(header[7]));

        List<FlowMods> flowModsList = new ArrayList<>();
        for(String[] values : actionValues) {
            if(LearnFlowModsType.MATCH_FROM_FIELD.name().equals(values[0])) {
                FlowModAddMatchFromFieldBuilder builder = new FlowModAddMatchFromFieldBuilder();
                builder.setSrcField(Long.decode(values[1]));
                builder.setSrcOfs(0);
                builder.setDstField(Long.decode(values[2]));
                builder.setDstOfs(0);
                builder.setFlowModNumBits(Integer.parseInt(values[3]));

                FlowModsBuilder flowModsBuilder = new FlowModsBuilder();
                FlowModAddMatchFromFieldCaseBuilder caseBuilder = new FlowModAddMatchFromFieldCaseBuilder();
                caseBuilder.setFlowModAddMatchFromField(builder.build());
                flowModsBuilder.setFlowModSpec(caseBuilder.build());
                flowModsList.add(flowModsBuilder.build());
            } else if (LearnFlowModsType.MATCH_FROM_VALUE.name().equals(values[0])) {
                FlowModAddMatchFromValueBuilder builder = new FlowModAddMatchFromValueBuilder();
                builder.setValue(Integer.parseInt(values[1]));
                builder.setSrcField(Long.decode(values[2]));
                builder.setSrcOfs(0);
                builder.setFlowModNumBits(Integer.parseInt(values[3]));

                FlowModsBuilder flowModsBuilder = new FlowModsBuilder();
                FlowModAddMatchFromValueCaseBuilder caseBuilder = new FlowModAddMatchFromValueCaseBuilder();
                caseBuilder.setFlowModAddMatchFromValue(builder.build());
                flowModsBuilder.setFlowModSpec(caseBuilder.build());
                flowModsList.add(flowModsBuilder.build());
            } else if (LearnFlowModsType.COPY_FROM_FIELD.name().equals(values[0])) {
                FlowModCopyFieldIntoFieldBuilder builder = new FlowModCopyFieldIntoFieldBuilder();
                builder.setSrcField(Long.decode(values[1]));
                builder.setSrcOfs(0);
                builder.setDstField(Long.decode(values[2]));
                builder.setDstOfs(0);
                builder.setFlowModNumBits(Integer.parseInt(values[3]));

                FlowModsBuilder flowModsBuilder = new FlowModsBuilder();
                FlowModCopyFieldIntoFieldCaseBuilder caseBuilder = new FlowModCopyFieldIntoFieldCaseBuilder();
                caseBuilder.setFlowModCopyFieldIntoField(builder.build());
                flowModsBuilder.setFlowModSpec(caseBuilder.build());
                flowModsList.add(flowModsBuilder.build());
            } else if (LearnFlowModsType.COPY_FROM_VALUE.name().equals(values[0])) {
                FlowModCopyValueIntoFieldBuilder builder = new FlowModCopyValueIntoFieldBuilder();
                builder.setValue(Integer.parseInt(values[1]));
                builder.setDstField(Long.decode(values[2]));
                builder.setDstOfs(0);
                builder.setFlowModNumBits(Integer.parseInt(values[3]));

                FlowModsBuilder flowModsBuilder = new FlowModsBuilder();
                FlowModCopyValueIntoFieldCaseBuilder caseBuilder = new FlowModCopyValueIntoFieldCaseBuilder();
                caseBuilder.setFlowModCopyValueIntoField(builder.build());
                flowModsBuilder.setFlowModSpec(caseBuilder.build());
                flowModsList.add(flowModsBuilder.build());
            } else if (LearnFlowModsType.OUTPUT_TO_PORT.name().equals(values[0])) {
                FlowModOutputToPortBuilder builder = new FlowModOutputToPortBuilder();
                builder.setSrcField(Long.decode(values[1]));
                builder.setSrcOfs(0);
                builder.setFlowModNumBits(Integer.parseInt(values[2]));

                FlowModsBuilder flowModsBuilder = new FlowModsBuilder();
                FlowModOutputToPortCaseBuilder caseBuilder = new FlowModOutputToPortCaseBuilder();
                caseBuilder.setFlowModOutputToPort(builder.build());
                flowModsBuilder.setFlowModSpec(caseBuilder.build());
                flowModsList.add(flowModsBuilder.build());
            }
        }
        learnBuilder.setFlowMods(flowModsList);

        ActionBuilder abExt = new ActionBuilder();
        abExt.setKey(new ActionKey(newActionKey));

        abExt.setAction(new NxActionLearnNodesNodeTableFlowApplyActionsCaseBuilder()
            .setNxLearn(learnBuilder.build()).build());
        return abExt.build();
    }

    private static org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.Action createResubmitActions(short tableId) {

        NxResubmitBuilder gttb = new NxResubmitBuilder();
        gttb.setTable(tableId);

        // Wrap our Apply Action in an InstructionBuilder
        return (new NxActionResubmitRpcAddGroupCaseBuilder().setNxResubmit(gttb.build())).build();
    }
}

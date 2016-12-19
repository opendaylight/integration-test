/*
 * Copyright (c) 2016 NEC Corporation and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.openstack.netvirt.providers.openflow13.services;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;

import org.opendaylight.netvirt.openstack.netvirt.api.L2ForwardingLearnProvider;
import org.opendaylight.netvirt.openstack.netvirt.api.LearnConstants;
import org.opendaylight.netvirt.openstack.netvirt.api.LearnConstants.LearnFlowModsType;
import org.opendaylight.netvirt.openstack.netvirt.providers.ConfigInterface;
import org.opendaylight.netvirt.openstack.netvirt.providers.openflow13.AbstractServiceInstance;
import org.opendaylight.netvirt.openstack.netvirt.providers.openflow13.Service;
import org.opendaylight.netvirt.utils.mdsal.openflow.FlowUtils;
import org.opendaylight.netvirt.utils.mdsal.openflow.MatchUtils;
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
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.InstructionBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.InstructionKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.NodeBuilder;
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

public class L2ForwardingLearnService  extends AbstractServiceInstance implements ConfigInterface, L2ForwardingLearnProvider {
    private static final Logger LOG = LoggerFactory.getLogger(L2ForwardingLearnService.class);

    public L2ForwardingLearnService() {
        super(Service.L2_LEARN);
    }

    public L2ForwardingLearnService(Service service) {
        super(service);
    }

    /*
     * (Table:L2ForwardingLearn) Remote Tep Learning
     * Match: reg0 = ClassifierService.REG_VALUE_FROM_REMOTE
     * Action: learn and goto next table
     * table=105,reg0=0x2 actions=learn(table=110,hard_timeout=300,priority=16400,NXM_NX_TUN_ID[],NXM_OF_ETH_DST[]=NXM_OF_ETH_SRC[],output:NXM_OF_IN_PORT[]),goto_table:110
     */
    @Override
    public void programL2ForwardingLearnRule(Long dpidLong) {
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        FlowBuilder flowBuilder = new FlowBuilder();
        String flowName = "L2ForwardingLearn";
        FlowUtils.initFlowBuilder(flowBuilder, flowName, getTable());
        List<Action> listAction = new ArrayList<>();

        MatchBuilder matchBuilder = new MatchBuilder();
        MatchUtils.addNxRegMatch(matchBuilder, new MatchUtils.RegMatch(ClassifierService.REG_FIELD, ClassifierService.REG_VALUE_FROM_REMOTE));
        flowBuilder.setMatch(matchBuilder.build());

        // Create learn action

        /*
         * learn header
         * 0 1 2 3 4 5 6 7 idleTO hardTO prio cook flags table finidle finhard
         *
         * learn flowmod
         * 0 1 2 3 learnFlowModType srcField dstField FlowModNumBits
         */
        String[] header = new String[] {
                "0", "300", "16400", "0", "0", "110", "0", "0"
        };

        String[][] flowMod = new String[3][];
        // NXM_NX_TUN_ID[]
        flowMod[0] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                LearnConstants.NxmOfFieldType.NXM_NX_TUN_ID.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_NX_TUN_ID.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_NX_TUN_ID.getFlowModHeaderLen() };
        // NXM_OF_ETH_DST[]=NXM_OF_ETH_SRC[]
        flowMod[1] = new String[] { LearnConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                LearnConstants.NxmOfFieldType.NXM_OF_ETH_SRC.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_ETH_DST.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_ETH_DST.getFlowModHeaderLen()};
        // output:NXM_OF_IN_PORT[]
        flowMod[2] = new String[] { LearnConstants.LearnFlowModsType.OUTPUT_TO_PORT.name(),
                LearnConstants.NxmOfFieldType.NXM_OF_IN_PORT.getHexType(),
                LearnConstants.NxmOfFieldType.NXM_OF_IN_PORT.getFlowModHeaderLen() };

        listAction.add(buildAction(0, header, flowMod));

        ApplyActions applyActions = new ApplyActionsBuilder().setAction(listAction).build();
        ApplyActionsCase applyActionsCase = new ApplyActionsCaseBuilder().setApplyActions(applyActions).build();
        InstructionsBuilder instructionsBuilder = new InstructionsBuilder();
        InstructionBuilder instructionBuilder = new InstructionBuilder();
        List<Instruction> instructions = Lists.newArrayList();

        instructionBuilder.setInstruction(applyActionsCase);
        instructionBuilder.setOrder(0);
        instructionBuilder.setKey(new InstructionKey(0));
        instructions.add(instructionBuilder.build());

        // Next service GOTO Instructions Need to be appended to the List
        instructionBuilder = this.getMutablePipelineInstructionBuilder();
        instructionBuilder.setOrder(1);
        instructionBuilder.setKey(new InstructionKey(1));
        instructions.add(instructionBuilder.build());

        // Add InstructionBuilder to the Instruction(s)Builder List
        instructionsBuilder.setInstruction(instructions);

        // Add InstructionsBuilder to FlowBuilder
        flowBuilder.setInstructions(instructionsBuilder.build());

        writeFlow(flowBuilder, nodeBuilder);

    }

    /*
     * build Action
     *
     * copy from org.opendaylight.genius.mdsalutil.ActionType.learn
     */
    private Action buildAction(int newActionKey, String[] header, String[][] actionValues) {
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

    @Override
    public void setDependencies(BundleContext bundleContext, ServiceReference serviceReference) {
        super.setDependencies(bundleContext.getServiceReference(L2ForwardingLearnProvider.class.getName()), this);
    }

    @Override
    public void setDependencies(Object impl) {
    }
}

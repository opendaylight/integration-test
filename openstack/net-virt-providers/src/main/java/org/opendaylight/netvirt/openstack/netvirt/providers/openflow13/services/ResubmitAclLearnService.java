/*
 * Copyright (c) 2016 NEC Corporation and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.openstack.netvirt.providers.openflow13.services;

import java.math.BigInteger;
import java.net.InetAddress;
import java.net.Inet6Address;
import java.net.UnknownHostException;
import java.util.List;
import java.util.ArrayList;

import org.opendaylight.netvirt.openstack.netvirt.api.StatusCode;
import org.opendaylight.netvirt.openstack.netvirt.api.InboundNatProvider;
import org.opendaylight.netvirt.openstack.netvirt.api.Status;
import org.opendaylight.netvirt.openstack.netvirt.api.ResubmitAclLearnProvider;
import org.opendaylight.netvirt.openstack.netvirt.providers.openflow13.AbstractServiceInstance;
import org.opendaylight.netvirt.openstack.netvirt.providers.ConfigInterface;
import org.opendaylight.netvirt.openstack.netvirt.providers.openflow13.Service;
import org.opendaylight.netvirt.utils.mdsal.openflow.ActionUtils;
import org.opendaylight.netvirt.utils.mdsal.openflow.FlowUtils;
import org.opendaylight.netvirt.utils.mdsal.openflow.InstructionUtils;
import org.opendaylight.netvirt.utils.mdsal.openflow.MatchUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv4Prefix;
import org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.list.Action;
import org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.list.ActionBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowjava.nx.match.rev140421.NxmNxReg;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowjava.nx.match.rev140421.NxmNxReg3;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.dst.choice.grouping.dst.choice.DstNxRegCaseBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.FlowBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.flow.InstructionsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.flow.MatchBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.Instruction;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.InstructionBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.InstructionKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.NodeBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.list.ActionKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.instruction.ApplyActionsCase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.instruction.ApplyActionsCaseBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.instruction.apply.actions._case.ApplyActions;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.instruction.apply.actions._case.ApplyActionsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.add.group.input.buckets.bucket.action.action.NxActionResubmitRpcAddGroupCaseBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.nx.action.resubmit.grouping.NxResubmitBuilder;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.osgi.framework.BundleContext;
import org.osgi.framework.ServiceReference;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.collect.Lists;

public class ResubmitAclLearnService extends AbstractServiceInstance implements ConfigInterface, ResubmitAclLearnProvider {
    private static final Logger LOG = LoggerFactory.getLogger(ResubmitAclLearnService.class);
    public static final Class<? extends NxmNxReg> REG_FIELD = NxmNxReg3.class;

    public ResubmitAclLearnService() {
        super(Service.RESUBMIT_ACL_SERVICE);
    }

    public ResubmitAclLearnService(Service service) {
        super(service);
    }

    @Override
    public Status programResubmit(Long dpid) {
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpid);
        FlowBuilder flowBuilder = new FlowBuilder();
        String flowName = "ReSubmit_";
        FlowUtils.initFlowBuilder(flowBuilder, flowName, getTable()).setPriority(0);
        List<Action> listAction = new ArrayList<>();

        NxResubmitBuilder nxarsb = new NxResubmitBuilder();
        //nxarsb.setTable(Short.parseShort("39"));
        nxarsb.setTable(getTable(Service.ACL_LEARN_SERVICE));
        ActionBuilder actionBuilder = new ActionBuilder();
        actionBuilder.setAction(new NxActionResubmitRpcAddGroupCaseBuilder().setNxResubmit(nxarsb.build()).build());
        actionBuilder.setKey(new ActionKey(0));
        listAction.add(actionBuilder.build());

        nxarsb = new NxResubmitBuilder();
        //nxarsb.setTable(Short.parseShort("40"));
        nxarsb.setTable(getTable(Service.EGRESS_ACL));
        actionBuilder = new ActionBuilder();
        actionBuilder.setAction(new NxActionResubmitRpcAddGroupCaseBuilder().setNxResubmit(nxarsb.build()).build());
        actionBuilder.setKey(new ActionKey(1));
        listAction.add(actionBuilder.build());

        ApplyActions applyActions = new ApplyActionsBuilder().setAction(listAction).build();
        ApplyActionsCase applyActionsCase = new ApplyActionsCaseBuilder().setApplyActions(applyActions).build();
        InstructionsBuilder instructionsBuilder = new InstructionsBuilder();
        InstructionBuilder instructionBuilder = new InstructionBuilder();
        List<Instruction> instructions = Lists.newArrayList();
        instructionBuilder.setInstruction(applyActionsCase);
        instructionBuilder.setOrder(0);
        instructionBuilder.setKey(new InstructionKey(0));
        instructions.add(instructionBuilder.build());
        instructionsBuilder.setInstruction(instructions);
        // Add InstructionsBuilder to FlowBuilder
        flowBuilder.setInstructions(instructionsBuilder.build());

        writeFlow(flowBuilder, nodeBuilder);

        // ToDo: WriteFlow/RemoveFlow should return something we can use to check success
        return new Status(StatusCode.SUCCESS);
    }

    @Override
    protected void programDefaultPipelineRule(Node node) {
         // no default flow for Resubmit ACL Learn Service
    }

    @Override
    public void setDependencies(BundleContext bundleContext, ServiceReference serviceReference) {
        super.setDependencies(bundleContext.getServiceReference(ResubmitAclLearnProvider.class.getName()), this);
    }

    @Override
    public void setDependencies(Object impl) {}
}

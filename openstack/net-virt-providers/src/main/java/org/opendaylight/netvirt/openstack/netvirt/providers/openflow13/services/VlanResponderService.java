/*
 * Copyright (c) 2016 NEC Corporation and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.openstack.netvirt.providers.openflow13.services;

import java.util.Collections;

import org.opendaylight.netvirt.openstack.netvirt.api.VlanResponderProvider;
import org.opendaylight.netvirt.openstack.netvirt.providers.ConfigInterface;
import org.opendaylight.netvirt.openstack.netvirt.providers.openflow13.AbstractServiceInstance;
import org.opendaylight.netvirt.openstack.netvirt.providers.openflow13.Service;
import org.opendaylight.netvirt.utils.mdsal.openflow.FlowUtils;
import org.opendaylight.netvirt.utils.mdsal.openflow.InstructionUtils;
import org.opendaylight.netvirt.utils.mdsal.openflow.MatchUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.MacAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.FlowId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.FlowBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.FlowKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.flow.MatchBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.Instruction;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.InstructionBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.InstructionKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.NodeBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.l2.types.rev130827.VlanId;
import org.osgi.framework.BundleContext;
import org.osgi.framework.ServiceReference;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class VlanResponderService extends AbstractServiceInstance implements VlanResponderProvider, ConfigInterface {
    private static final Logger LOG = LoggerFactory.getLogger(VlanResponderService.class);

    public VlanResponderService() {
        super(Service.OUTBOUND_NAT);
    }

    public VlanResponderService(Service service) {
        super(service);
    }

    /**
     * Write or remove the flows for output instructions based on flag value actions.
     * Sample flow: table=100, n_packets=1192, n_bytes=55496, priority=4,in_port=5,dl_src=fa:16:3e:74:a9:2e actions=output:3
     */
    @Override
    public void programProviderNetworkOutput(Long dpidLong, Long ofPort, Long patchPort, String macAddress, boolean write) {
        try {
            String nodeName = OPENFLOW + dpidLong;
            NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(nodeName);
            FlowBuilder flowBuilder = new FlowBuilder();
            // Create the OF Match using MatchBuilder
            MatchBuilder matchBuilder = new MatchBuilder();
            //Match In Port
            MatchUtils.createInPortMatch(matchBuilder, dpidLong, ofPort);
            MatchUtils.createEthSrcMatch(matchBuilder, new MacAddress(macAddress));
            flowBuilder.setMatch(matchBuilder.build());
            // Add Flow Attributes
            String flowName = "InternalBridge_output_" + dpidLong + "_" + ofPort;
            final FlowId flowId = new FlowId(flowName);
            flowBuilder.setId(flowId).setBarrier(true).setTableId(getTable()).setKey(new FlowKey(flowId))
                    .setPriority(4).setFlowName(flowName).setHardTimeout(0).setIdleTimeout(0);
            if (write) {
                // Set the Output Port/Iface
                Instruction outputPortInstruction = InstructionUtils.createOutputPortInstructions(new InstructionBuilder(),
                        dpidLong, patchPort).setOrder(0).setKey(new InstructionKey(0)).build();
                // Add InstructionsBuilder to FlowBuilder
                InstructionUtils.setFlowBuilderInstruction(flowBuilder, outputPortInstruction);
                writeFlow(flowBuilder, nodeBuilder);
            } else {
                removeFlow(flowBuilder, nodeBuilder);
            }
        } catch (Exception e) {
            LOG.error("Error while writing/removing output instruction flow. dpidLong = {}, patchPort={}, write = {}."
                    +" Caused due to, {}", dpidLong, patchPort, write, e.getMessage());
        }
    }

    /**
     * Write or remove the flows for POP VLAN instructions based on flag value actions.
     * Sample flow: table=100, n_packets=218, n_bytes=15778, priority=4,in_port=3,dl_vlan=100 actions=pop_vlan,output:5
     */
    @Override
    public void programProviderNetworkPopVlan(Long dpidLong, String segmentationId, Long ofPort, Long patchPort, boolean write) {
        try {
            String nodeName = OPENFLOW + dpidLong;
            NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(nodeName);
            FlowBuilder flowBuilder = new FlowBuilder();
            // Create the OF Match using MatchBuilder
            MatchBuilder matchBuilder = new MatchBuilder();
            // Match Vlan ID
            MatchUtils.createVlanIdMatch(matchBuilder, new VlanId(Integer.valueOf(segmentationId)), true);
            //Match In Port
            MatchUtils.createInPortMatch(matchBuilder, dpidLong, patchPort);
            flowBuilder.setMatch(matchBuilder.build());
            // Add Flow Attributes
            String flowName = "InternalBridge_popVLAN_" + segmentationId + "_" + patchPort;
            final FlowId flowId = new FlowId(flowName);
            flowBuilder.setId(flowId).setBarrier(true).setTableId(getTable()).setKey(new FlowKey(flowId))
                    .setPriority(4).setFlowName(flowName).setHardTimeout(0).setIdleTimeout(0);
            if (write) {
                /* Strip vlan and store to tmp instruction space*/
                Instruction stripVlanInstruction = InstructionUtils.createPopVlanInstructions(new InstructionBuilder())
                        .setOrder(0).setKey(new InstructionKey(0)).build();
                // Set the Output Port/Iface
                Instruction setOutputPortInstruction =
                        InstructionUtils.addOutputPortInstructions(new InstructionBuilder(), dpidLong, ofPort,
                        Collections.singletonList(stripVlanInstruction)).setOrder(1).setKey(new InstructionKey(0)).build();
                // Add InstructionsBuilder to FlowBuilder
                InstructionUtils.setFlowBuilderInstruction(flowBuilder, setOutputPortInstruction);
                writeFlow(flowBuilder, nodeBuilder);
            } else {
                removeFlow(flowBuilder, nodeBuilder);
            }
        } catch (Exception e) {
            LOG.error("Error while writing/removing pop vlan instruction flow. dpidLong = {}, patchPort={}, write = {}."
                    + "Caused due to, {}", dpidLong, patchPort, write, e.getMessage());
        }
    }

    /**
     * Write or remove the flows for push VLAN instructions based on flag value actions.
     * Sample flow: cookie=0x0, duration=4831.827s, table=0, n_packets=1202, n_bytes=56476, priority=4,in_port=3, dl_src=fa:16:3e:74:a9:2e actions=push_vlan:0x8100,set_field:4196 vlan_vid,NORMAL
     */
    @Override
    public void programProviderNetworkPushVlan(Long dpidLong, String segmentationId, Long patchExtPort,
            String macAddress, boolean write) {
        try {
            String nodeName = OPENFLOW + dpidLong;
            NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(nodeName);
            FlowBuilder flowBuilder = new FlowBuilder();
            // Create the OF Match using MatchBuilder
            MatchBuilder matchBuilder = new MatchBuilder();
            MatchUtils.createEthSrcMatch(matchBuilder, new MacAddress(macAddress));
            //Match In Port
            MatchUtils.createInPortMatch(matchBuilder, dpidLong, patchExtPort);
            flowBuilder.setMatch(matchBuilder.build());
            // Add Flow Attributes
            String flowName = "ExternalBridge_pushVLAN_" + dpidLong + "_" + segmentationId;
            final FlowId flowId = new FlowId(flowName);
            flowBuilder.setId(flowId).setBarrier(true).setTableId((short) 0).setKey(new FlowKey(flowId))
                    .setPriority(4).setFlowName(flowName).setHardTimeout(0).setIdleTimeout(0);
            if (write) {
                InstructionBuilder ib = new InstructionBuilder();
                // Set VLAN ID Instruction
                InstructionUtils.createSetVlanAndNormalInstructions(ib, new VlanId(Integer.valueOf(segmentationId)));
                ib.setOrder(0);
                ib.setKey(new InstructionKey(0));
                Instruction pushVLANInstruction = ib.build();
                InstructionUtils.setFlowBuilderInstruction(flowBuilder, pushVLANInstruction);
                writeFlow(flowBuilder, nodeBuilder);
            } else {
                removeFlow(flowBuilder, nodeBuilder);
            }
        } catch (Exception e) {
            LOG.error("Error while writing/removing push vlan instruction flow. dpidLong = {}, patchPort={}, write = {}."
                    + "Caused due to, {}", dpidLong, patchExtPort, write, e.getMessage());
        }
    }

    /**
     * Write or remove the flows for drop instructions based on flag value actions.
     * Sample flow: table=0, n_packets=0, n_bytes=0, priority=2,in_port=3 actions=drop
     */
    @Override
    public void programProviderNetworkDrop(Long dpidLong, Long patchExtPort, boolean write) {
        try {
            String nodeName = OPENFLOW + dpidLong;
            NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(nodeName);
            FlowBuilder flowBuilder = new FlowBuilder();
            // Create the OF Match using MatchBuilder
            MatchBuilder matchBuilder = new MatchBuilder();
            //Match In Port
            MatchUtils.createInPortMatch(matchBuilder, dpidLong, patchExtPort);
            flowBuilder.setMatch(matchBuilder.build());
            // Add Flow Attributes
            String flowName = "ExternalBridge_drop_" + dpidLong + "_" + patchExtPort;
            final FlowId flowId = new FlowId(flowName);
            flowBuilder.setId(flowId).setBarrier(true).setTableId((short) 0)
                    .setKey(new FlowKey(flowId)).setPriority(2).setFlowName(flowName)
                    .setHardTimeout(0).setIdleTimeout(0);
            if (write) {
                // Call the InstructionBuilder Methods Containing Actions
                Instruction dropInstruction = InstructionUtils.createDropInstructions(new InstructionBuilder())
                        .setOrder(0)
                        .setKey(new InstructionKey(0))
                        .build();
                // Add InstructionsBuilder to FlowBuilder
                InstructionUtils.setFlowBuilderInstruction(flowBuilder, dropInstruction);
                writeFlow(flowBuilder, nodeBuilder);
            } else {
                removeFlow(flowBuilder, nodeBuilder);
            }
        } catch (Exception e) {
            LOG.error("Error while writing/removing drop instruction flow. dpidLong = {}, patchPort={}, write = {}."
                    + "Caused due to, {}", dpidLong, patchExtPort, write, e.getMessage());
        }
    }

    @Override
    public void setDependencies(BundleContext bundleContext, ServiceReference serviceReference) {
        super.setDependencies(bundleContext.getServiceReference(VlanResponderProvider.class.getName()), this);
    }

    @Override
    public void setDependencies(Object impl) {}

}

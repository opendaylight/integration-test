/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.dhcpservice;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.CheckedFuture;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;
import java.util.concurrent.ExecutionException;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.TransactionCommitFailedException;
import org.opendaylight.genius.mdsalutil.ActionInfo;
import org.opendaylight.genius.mdsalutil.ActionType;
import org.opendaylight.genius.mdsalutil.FlowEntity;
import org.opendaylight.genius.mdsalutil.InstructionInfo;
import org.opendaylight.genius.mdsalutil.InstructionType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.MatchFieldType;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.genius.mdsalutil.packet.IPProtocols;
import org.opendaylight.genius.utils.ServiceIndex;
import org.opendaylight.netvirt.dhcpservice.api.DhcpMConstants;
import org.opendaylight.netvirt.neutronvpn.api.utils.NeutronUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.InterfacesState;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.Instruction;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.ServiceBindings;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.ServiceModeIngress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.ServiceTypeFlowBased;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.StypeOpenflow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.StypeOpenflowBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.ServicesInfo;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.ServicesInfoKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.services.info.BoundServices;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.services.info.BoundServicesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.services.info.BoundServicesKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.Nodes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.Node;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.ElanDpnInterfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.dpn.interfaces.ElanDpnInterfacesList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.dpn.interfaces.ElanDpnInterfacesListKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.dpn.interfaces.elan.dpn.interfaces.list.DpnInterfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.NetworkTypeVxlan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.networks.attributes.Networks;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.networks.attributes.networks.Network;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.networks.attributes.networks.NetworkKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.Ports;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DhcpServiceUtils {

    private static final Logger LOG = LoggerFactory.getLogger(DhcpServiceUtils.class);

    public static void setupDhcpFlowEntry(BigInteger dpId, short tableId, String vmMacAddress, int addOrRemove,
                                          IMdsalApiManager mdsalUtil, WriteTransaction tx) {
        if (dpId == null || dpId.equals(DhcpMConstants.INVALID_DPID) || vmMacAddress == null) {
            return;
        }
        List<MatchInfo> matches = getDhcpMatch(vmMacAddress);

        List<InstructionInfo> instructions = new ArrayList<>();
        List<ActionInfo> actionsInfos = new ArrayList<>();

        // Punt to controller
        actionsInfos.add(new ActionInfo(ActionType.punt_to_controller,
                new String[] {}));
        instructions.add(new InstructionInfo(InstructionType.apply_actions,
                actionsInfos));
        if (addOrRemove == NwConstants.DEL_FLOW) {
            FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, tableId,
                    getDhcpFlowRef(dpId, tableId, vmMacAddress),
                    DhcpMConstants.DEFAULT_DHCP_FLOW_PRIORITY, "DHCP", 0, 0,
                    DhcpMConstants.COOKIE_DHCP_BASE, matches, null);
            LOG.trace("Removing DHCP Flow DpId {}, vmMacAddress {}", dpId, vmMacAddress);
            DhcpServiceCounters.remove_dhcp_flow.inc();
            mdsalUtil.removeFlowToTx(flowEntity, tx);
        } else {
            FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, tableId,
                    getDhcpFlowRef(dpId, tableId, vmMacAddress), DhcpMConstants.DEFAULT_DHCP_FLOW_PRIORITY,
                    "DHCP", 0, 0, DhcpMConstants.COOKIE_DHCP_BASE, matches, instructions);
            LOG.trace("Installing DHCP Flow DpId {}, vmMacAddress {}", dpId, vmMacAddress);
            DhcpServiceCounters.install_dhcp_flow.inc();
            mdsalUtil.addFlowToTx(flowEntity, tx);
        }
    }

    private static String getDhcpFlowRef(BigInteger dpId, long tableId, String vmMacAddress) {
        return new StringBuffer().append(DhcpMConstants.FLOWID_PREFIX)
                .append(dpId).append(NwConstants.FLOWID_SEPARATOR)
                .append(tableId).append(NwConstants.FLOWID_SEPARATOR)
                .append(vmMacAddress).toString();
    }

    public static void setupDhcpDropAction(BigInteger dpId, short tableId, String vmMacAddress, int addOrRemove,
                                           IMdsalApiManager mdsalUtil, WriteTransaction tx) {
        if (dpId == null || dpId.equals(DhcpMConstants.INVALID_DPID) || vmMacAddress == null) {
            return;
        }
        List<MatchInfo> matches = getDhcpMatch(vmMacAddress);

        List<ActionInfo> actionsInfos = new ArrayList<>();
        List<InstructionInfo> instructions = new ArrayList<>();
        instructions.add(new InstructionInfo(InstructionType.apply_actions, actionsInfos));
        // Drop Action
        actionsInfos.add(new ActionInfo(ActionType.drop_action,
                new String[] {}));
        if (addOrRemove == NwConstants.DEL_FLOW) {
            FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, tableId,
                    getDhcpFlowRef(dpId, tableId, vmMacAddress),
                    DhcpMConstants.DEFAULT_DHCP_FLOW_PRIORITY, "DHCP", 0, 0,
                    DhcpMConstants.COOKIE_DHCP_BASE, matches, null);
            LOG.trace("Removing DHCP Drop Flow DpId {}, vmMacAddress {}", dpId, vmMacAddress);
            DhcpServiceCounters.remove_dhcp_drop_flow.inc();
            mdsalUtil.removeFlowToTx(flowEntity, tx);
        } else {
            FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, tableId,
                    getDhcpFlowRef(dpId, tableId, vmMacAddress), DhcpMConstants.DEFAULT_DHCP_FLOW_PRIORITY,
                    "DHCP", 0, 0, DhcpMConstants.COOKIE_DHCP_BASE, matches, instructions);
            LOG.trace("Installing DHCP Drop Flow DpId {}, vmMacAddress {}", dpId, vmMacAddress);
            DhcpServiceCounters.install_dhcp_drop_flow.inc();
            mdsalUtil.addFlowToTx(flowEntity, tx);
        }
    }

    private static List<MatchInfo> getDhcpMatch(String vmMacAddress) {
        List<MatchInfo> matches = new ArrayList<>();
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { NwConstants.ETHTYPE_IPV4 }));
        matches.add(new MatchInfo(MatchFieldType.ip_proto,
                new long[] { IPProtocols.UDP.intValue() }));
        matches.add(new MatchInfo(MatchFieldType.udp_src,
                new long[] { DhcpMConstants.DHCP_CLIENT_PORT}));
        matches.add(new MatchInfo(MatchFieldType.udp_dst,
                new long[] { DhcpMConstants.DHCP_SERVER_PORT}));
        matches.add(new MatchInfo(MatchFieldType.eth_src,
                new String[] { vmMacAddress }));
        return matches;
    }

    public static List<BigInteger> getListOfDpns(DataBroker broker) {
        List<BigInteger> dpnsList = new LinkedList<>();
        InstanceIdentifier<Nodes> nodesInstanceIdentifier = InstanceIdentifier.builder(Nodes.class).build();
        Optional<Nodes> nodesOptional =
                MDSALUtil.read(broker, LogicalDatastoreType.OPERATIONAL, nodesInstanceIdentifier);
        if (!nodesOptional.isPresent()) {
            return dpnsList;
        }
        Nodes nodes = nodesOptional.get();
        List<Node> nodeList = nodes.getNode();
        for (Node node : nodeList) {
            NodeId nodeId = node.getId();
            if (nodeId == null) {
                continue;
            }
            BigInteger dpnId = MDSALUtil.getDpnIdFromNodeName(nodeId);
            dpnsList.add(dpnId);
        }
        return dpnsList;
    }

    public static List<BigInteger> getDpnsForElan(String elanInstanceName, DataBroker broker) {
        List<BigInteger> elanDpns = new LinkedList<>();
        InstanceIdentifier<ElanDpnInterfacesList> elanDpnInstanceIdentifier =
                InstanceIdentifier.builder(ElanDpnInterfaces.class)
                        .child(ElanDpnInterfacesList.class, new ElanDpnInterfacesListKey(elanInstanceName)).build();
        Optional<ElanDpnInterfacesList> elanDpnOptional =
                MDSALUtil.read(broker, LogicalDatastoreType.OPERATIONAL, elanDpnInstanceIdentifier);
        if (elanDpnOptional.isPresent()) {
            List<DpnInterfaces> dpns = elanDpnOptional.get().getDpnInterfaces();
            for (DpnInterfaces dpnInterfaces : dpns) {
                elanDpns.add(dpnInterfaces.getDpId());
            }
        }
        return elanDpns;
    }

    public static org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces
            .state.Interface getInterfaceFromOperationalDS(String interfaceName, DataBroker dataBroker) {
        org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces
                .state.InterfaceKey interfaceKey =
                new org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces
                        .state.InterfaceKey(interfaceName);
        InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508
                .interfaces.state.Interface> interfaceId = InstanceIdentifier.builder(InterfacesState.class)
                .child(org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508
                        .interfaces.state.Interface.class, interfaceKey).build();
        Optional<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces
                .state.Interface> interfaceOptional =
                MDSALUtil.read(LogicalDatastoreType.OPERATIONAL, interfaceId, dataBroker);
        if (!interfaceOptional.isPresent()) {
            return null;
        }
        return interfaceOptional.get();
    }


    public static String getSegmentationId(Uuid networkId, DataBroker broker) {
        InstanceIdentifier<Network> inst = InstanceIdentifier.create(Neutron.class)
                .child(Networks.class).child(Network.class, new NetworkKey(networkId));
        Optional<Network> optionalNetwork = MDSALUtil.read(broker, LogicalDatastoreType.CONFIGURATION, inst);
        if (!optionalNetwork.isPresent()) {
            return null;
        }
        Network network = optionalNetwork.get();
        String segmentationId = NeutronUtils.getSegmentationIdFromNeutronNetwork(network, NetworkTypeVxlan.class);
        return segmentationId;
    }

    public static String getNodeIdFromDpnId(BigInteger dpnId) {
        return MDSALUtil.NODE_PREFIX + MDSALUtil.SEPARATOR + dpnId.toString();
    }

    public static String getTrunkPortMacAddress(String parentRefName,
            DataBroker broker) {
        InstanceIdentifier<Port> portInstanceIdentifier =
                InstanceIdentifier.create(Neutron.class).child(Ports.class).child(Port.class);
        Optional<Port> trunkPort = MDSALUtil.read(broker, LogicalDatastoreType.CONFIGURATION, portInstanceIdentifier);
        if (!trunkPort.isPresent()) {
            LOG.warn("Trunk port {} not available for sub-port", parentRefName);
            return null;
        }
        return trunkPort.get().getMacAddress().getValue();
    }

    public static String getJobKey(String interfaceName) {
        return new StringBuilder().append(DhcpMConstants.DHCP_JOB_KEY_PREFIX).append(interfaceName).toString();
    }

    public static void submitTransaction(WriteTransaction tx) {
        CheckedFuture<Void, TransactionCommitFailedException> futures = tx.submit();
        try {
            futures.get();
        } catch (InterruptedException | ExecutionException e) {
            LOG.error("Error writing to datastore tx {} error {}", tx, e.getMessage());
        }
    }

    public static void bindDhcpService(String interfaceName, short tableId, WriteTransaction tx) {
        int instructionKey = 0;
        List<Instruction> instructions = new ArrayList<>();
        instructions.add(MDSALUtil.buildAndGetGotoTableInstruction(tableId, ++instructionKey));
        short serviceIndex = ServiceIndex.getIndex(NwConstants.DHCP_SERVICE_NAME, NwConstants.DHCP_SERVICE_INDEX);
        BoundServices
                serviceInfo =
                getBoundServices(String.format("%s.%s", "dhcp", interfaceName),
                        serviceIndex, DhcpMConstants.DEFAULT_FLOW_PRIORITY,
                        DhcpMConstants.COOKIE_VM_INGRESS_TABLE, instructions);
        tx.put(LogicalDatastoreType.CONFIGURATION,
                buildServiceId(interfaceName, serviceIndex), serviceInfo, true);
    }

    public static void unbindDhcpService(String interfaceName, WriteTransaction tx) {
        short serviceIndex = ServiceIndex.getIndex(NwConstants.DHCP_SERVICE_NAME, NwConstants.DHCP_SERVICE_INDEX);
        tx.delete(LogicalDatastoreType.CONFIGURATION,
                buildServiceId(interfaceName, serviceIndex));
    }

    private static InstanceIdentifier<BoundServices> buildServiceId(String interfaceName,
                                                             short dhcpServicePriority) {
        return InstanceIdentifier.builder(ServiceBindings.class)
                .child(ServicesInfo.class, new ServicesInfoKey(interfaceName, ServiceModeIngress.class))
                .child(BoundServices.class, new BoundServicesKey(dhcpServicePriority)).build();
    }

    public static BoundServices getBoundServices(String serviceName, short servicePriority, int flowPriority,
                                          BigInteger cookie, List<Instruction> instructions) {
        StypeOpenflowBuilder augBuilder = new StypeOpenflowBuilder().setFlowCookie(cookie)
                .setFlowPriority(flowPriority).setInstruction(instructions);
        return new BoundServicesBuilder().setKey(new BoundServicesKey(servicePriority))
                .setServiceName(serviceName).setServicePriority(servicePriority)
                .setServiceType(ServiceTypeFlowBased.class)
                .addAugmentation(StypeOpenflow.class, augBuilder.build()).build();
    }
}
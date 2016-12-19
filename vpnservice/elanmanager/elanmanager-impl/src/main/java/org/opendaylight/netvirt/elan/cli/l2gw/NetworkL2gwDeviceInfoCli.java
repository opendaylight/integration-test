/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.elan.cli.l2gw;

import com.google.common.base.Optional;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.apache.karaf.shell.commands.Command;
import org.apache.karaf.shell.commands.Option;
import org.apache.karaf.shell.console.OsgiCommandSupport;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.utils.hwvtep.HwvtepSouthboundConstants;
import org.opendaylight.genius.utils.hwvtep.HwvtepUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Uri;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.ElanInstances;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepLogicalSwitchRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepPhysicalLocatorRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepPhysicalPortAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LocalMcastMacs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LocalUcastMacs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LogicalSwitches;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.RemoteMcastMacs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.RemoteUcastMacs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.Switches;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical.locator.set.attributes.LocatorSet;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical.port.attributes.VlanBindings;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NetworkTopology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NodeId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.TopologyKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.NodeKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPoint;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Prints L2Gw devices and Elan details .
 * Print result as per each elan instance , printing all Mcast , UCast macs and vlan binding
 * for each l2Gw device .
 */
@Command(scope = "l2gw", name = "dump", description = "Provide l2gw info per network")
public class NetworkL2gwDeviceInfoCli extends OsgiCommandSupport {

    private static final Logger LOG = LoggerFactory.getLogger(L2GwUtilsCacheCli.class);

    private static final String GAP = "                              ";
    private static final String HEADINGUCAST = "    Mac " + GAP + "          Locator";
    private static final String HEADINGMCAST = "    Mac " + GAP + "          Locator Set";
    private static final String HEADINGVLAN = "    TepId " + GAP + "          Vlan ID";

    @Option(name = "-elan", aliases = {"--elan"}, description = "elan name",
            required = false, multiValued = false)
    String elanName;

    @Option(name = "-nodeId", aliases = {"--nodeId"}, description = "hwvtep node id",
            required = false, multiValued = false)
    String nodeId;

    InstanceIdentifier<Topology> createHwvtepTopologyInstanceIdentifier() {
        return InstanceIdentifier.create(NetworkTopology.class).child(Topology.class,
                new TopologyKey(HwvtepSouthboundConstants.HWVTEP_TOPOLOGY_ID));
    }

    InstanceIdentifier<Node> createInstanceIdentifier(NodeId nodeId) {
        return InstanceIdentifier.create(NetworkTopology.class).child(Topology.class,
                new TopologyKey(HwvtepSouthboundConstants.HWVTEP_TOPOLOGY_ID)).child(Node.class, new NodeKey(nodeId));
    }

    Map<NodeId, Node> opNodes = new HashMap<>();
    Map<NodeId, Node> configNodes = new HashMap<>();
    Map<NodeId, Node> opPSNodes = new HashMap<>();
    Map<NodeId, Node> configPSNodes = new HashMap<>();

    private DataBroker dataBroker;

    public void setDataBroker(DataBroker dataBroker) {
        this.dataBroker = dataBroker;
    }

    @Override
    protected Object doExecute() throws Exception {
        List<Node> nodes = new ArrayList<>();
        Set<String> networks = new HashSet<>();
        if (nodeId == null) {
            Optional<Topology> topologyOptional = MDSALUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL,
                    createHwvtepTopologyInstanceIdentifier());
            if (topologyOptional.isPresent()) {
                nodes = topologyOptional.get().getNode();
            }
        } else {
            Optional<Node> nodeOptional = MDSALUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL,
                    createInstanceIdentifier(new NodeId(new Uri(nodeId))));
            if (nodeOptional.isPresent()) {
                nodes.add(nodeOptional.get());
            }
        }
        if (elanName == null) {
            //get all elan instance
            //get all device node id
            //print result
            Optional<ElanInstances> elanInstancesOptional = MDSALUtil.read(dataBroker,
                    LogicalDatastoreType.CONFIGURATION,
                    InstanceIdentifier.builder(ElanInstances.class).build());
            if (elanInstancesOptional.isPresent()) {
                List<ElanInstance> elans = elanInstancesOptional.get().getElanInstance();
                if (elans != null) {
                    for (ElanInstance elan : elans) {
                        networks.add(elan.getElanInstanceName());
                    }
                }
            }
        } else {
            networks.add(elanName);
        }

        for (Node node : nodes) {
            if (node.getNodeId().getValue().contains("physicalswitch")) {
                continue;
            }
            Node hwvtepConfigNode =
                    HwvtepUtils.getHwVtepNode(dataBroker, LogicalDatastoreType.CONFIGURATION, node.getNodeId());
            Node hwvtepOpPsNode = getPSnode(dataBroker, node, LogicalDatastoreType.OPERATIONAL);
            Node hwvtepConfigPsNode = null;
            if (hwvtepOpPsNode != null) {
                hwvtepConfigPsNode = HwvtepUtils.getHwVtepNode(dataBroker, LogicalDatastoreType.CONFIGURATION,
                        hwvtepOpPsNode.getNodeId());
                opPSNodes.put(node.getNodeId(), hwvtepOpPsNode);
            }
            opNodes.put(node.getNodeId(), node);
            configNodes.put(node.getNodeId(), hwvtepConfigNode);

            if (hwvtepConfigPsNode != null) {
                configPSNodes.put(node.getNodeId(), hwvtepConfigPsNode);
            }
        }
        for (String network : networks) {
            session.getConsole().println("Network info for " + network);
            for (Node node : nodes) {
                if (node.getNodeId().getValue().contains("physicalswitch")) {
                    continue;
                }
                session.getConsole().println("Printing for node " + node.getNodeId().getValue());
                process(node.getNodeId(), network);
            }
        }
        return null;
    }

    void process(NodeId hwvtepNodeId, String elanName) {
        Node hwvtepConfigNode = configNodes.get(hwvtepNodeId);
        session.getConsole().println("Config Data >>");
        printLocalUcastMacs(hwvtepConfigNode, elanName);
        session.getConsole().println("Operational Data >>");
        Node hwvtepOpNode = opNodes.get(hwvtepNodeId);
        printLocalUcastMacs(hwvtepOpNode, elanName);
        session.getConsole().println("Config Data >>");
        printLocalMcastMacs(hwvtepConfigNode, elanName);
        session.getConsole().println("Operational Data >>");
        printLocalMcastMacs(hwvtepOpNode, elanName);
        session.getConsole().println("Config Data >>");
        printRemoteUcastMacs(hwvtepConfigNode, elanName);
        session.getConsole().println("Operational Data >>");
        printRemoteUcastMacs(hwvtepOpNode, elanName);
        session.getConsole().println("Config Data >>");
        printRemoteMcastMacs(hwvtepConfigNode, elanName);
        session.getConsole().println("Operational Data >>");
        printRemoteMcastMacs(hwvtepOpNode, elanName);
        Node hwvtepConfigPsNode = configPSNodes.get(hwvtepNodeId);
        session.getConsole().println("Config Data >>");
        printVlanBindings(hwvtepConfigPsNode, elanName);
        session.getConsole().println("Operational Data >>");
        Node hwvtepOpPsNode = opPSNodes.get(hwvtepNodeId);
        printVlanBindings(hwvtepOpPsNode, elanName);
    }

    void printRemoteUcastMacs(Node hwvtepNode, String elanName) {
        session.getConsole().println("RemoteUCast macs :");
        session.getConsole().println(HEADINGUCAST);
        if (hwvtepNode == null || hwvtepNode.getAugmentation(HwvtepGlobalAugmentation.class) == null) {
            return;
        }
        List<RemoteUcastMacs> remoteUcastMacs =
                hwvtepNode.getAugmentation(HwvtepGlobalAugmentation.class).getRemoteUcastMacs();
        if (remoteUcastMacs == null || remoteUcastMacs.isEmpty()) {
            return;
        }
        for (RemoteUcastMacs remoteMac : remoteUcastMacs) {
            String lsFromRemoteMac = getLogicalSwitchValue(remoteMac.getLogicalSwitchRef());
            if (elanName.equals(lsFromRemoteMac)) {
                String mac = remoteMac.getMacEntryKey().getValue();
                String locator = getLocatorValue(remoteMac.getLocatorRef());
                session.getConsole().println(mac + GAP + locator);
            }
        }


    }

    void printLocalUcastMacs(Node hwvtepNode, String elanName) {
        session.getConsole().println("LocalUCast macs :");
        session.getConsole().println(HEADINGUCAST);
        if (hwvtepNode == null || hwvtepNode.getAugmentation(HwvtepGlobalAugmentation.class) == null) {
            return;
        }
        List<LocalUcastMacs> localUcastMacs =
                hwvtepNode.getAugmentation(HwvtepGlobalAugmentation.class).getLocalUcastMacs();
        if (localUcastMacs == null || localUcastMacs.isEmpty()) {
            return;
        }
        for (LocalUcastMacs localMac : localUcastMacs) {
            String lsFromLocalMac = getLogicalSwitchValue(localMac.getLogicalSwitchRef());
            if (elanName.equals(lsFromLocalMac)) {
                String mac = localMac.getMacEntryKey().getValue();
                String locator = getLocatorValue(localMac.getLocatorRef());
                session.getConsole().println(mac + GAP + locator);
            }
        }


    }

    void printLocalMcastMacs(Node hwvtepNode, String elanName) {
        session.getConsole().println("LocalMcast macs :");
        session.getConsole().println(HEADINGMCAST);
        if (hwvtepNode == null || hwvtepNode.getAugmentation(HwvtepGlobalAugmentation.class) == null) {
            return;
        }
        List<LocalMcastMacs> localMcastMacs =
                hwvtepNode.getAugmentation(HwvtepGlobalAugmentation.class).getLocalMcastMacs();
        if (localMcastMacs == null || localMcastMacs.isEmpty()) {
            return;
        }
        for (LocalMcastMacs localMac : localMcastMacs) {
            String lsFromLocalMac = getLogicalSwitchValue(localMac.getLogicalSwitchRef());
            if (elanName.equals(lsFromLocalMac)) {
                String mac = localMac.getMacEntryKey().getValue();
                List<String> locatorsets = new ArrayList<>();
                for (LocatorSet locatorSet : localMac.getLocatorSet()) {
                    locatorsets.add(getLocatorValue(locatorSet.getLocatorRef()));
                }
                session.getConsole().println(mac + GAP + locatorsets.toString());
            }
        }


    }

    void printRemoteMcastMacs(Node hwvtepNode, String elanName) {
        session.getConsole().println("RemoteMCast macs :");
        session.getConsole().println(HEADINGMCAST);
        if (hwvtepNode == null || hwvtepNode.getAugmentation(HwvtepGlobalAugmentation.class) == null) {
            return;
        }
        List<RemoteMcastMacs> remoteMcastMacs =
                hwvtepNode.getAugmentation(HwvtepGlobalAugmentation.class).getRemoteMcastMacs();
        if (remoteMcastMacs == null || remoteMcastMacs.isEmpty()) {
            return;
        }
        for (RemoteMcastMacs remoteMac : remoteMcastMacs) {
            String lsFromremoteMac = getLogicalSwitchValue(remoteMac.getLogicalSwitchRef());
            if (elanName.equals(lsFromremoteMac)) {
                String mac = remoteMac.getMacEntryKey().getValue();
                List<String> locatorsets = new ArrayList<>();
                for (LocatorSet locatorSet : remoteMac.getLocatorSet()) {
                    locatorsets.add(getLocatorValue(locatorSet.getLocatorRef()));
                }
                session.getConsole().println(mac + GAP + locatorsets.toString());
            }
        }


    }

    void printVlanBindings(Node psNode, String elanName) {
        session.getConsole().println("Vlan Bindings :");
        session.getConsole().println(HEADINGVLAN);
        if (psNode == null) {
            return;
        }
        List<TerminationPoint> terminationPoints = psNode.getTerminationPoint();
        List<String> vlanIds = new ArrayList<>();
        if (terminationPoints == null || terminationPoints.isEmpty()) {
            return;
        }
        for (TerminationPoint terminationPoint : terminationPoints) {
            HwvtepPhysicalPortAugmentation aug =
                    terminationPoint.getAugmentation(HwvtepPhysicalPortAugmentation.class);
            if (aug == null || aug.getVlanBindings() == null) {
                continue;
            }
            for (VlanBindings vlanBindings : aug.getVlanBindings()) {
                String lsFromremoteMac = getLogicalSwitchValue(vlanBindings.getLogicalSwitchRef());
                if (elanName.equals(lsFromremoteMac)) {
                    session.getConsole().println(terminationPoint.getTpId().getValue()
                            + GAP + vlanBindings.getVlanIdKey().toString());
                }
            }
        }


    }

    String getLocatorValue(HwvtepPhysicalLocatorRef locatorRef) {
        if (locatorRef == null) {
            return null;
        }
        return locatorRef.getValue()
                .firstKeyOf(TerminationPoint.class).getTpId().getValue();
    }

    String getLogicalSwitchValue(HwvtepLogicalSwitchRef logicalSwitchRef) {
        if (logicalSwitchRef == null) {
            return null;
        }
        return logicalSwitchRef.getValue()
                .firstKeyOf(LogicalSwitches.class).getHwvtepNodeName().getValue();
    }

    Node getPSnode(DataBroker dataBroker, Node hwvtepNode, LogicalDatastoreType datastoreType) {
        if (hwvtepNode.getAugmentation(HwvtepGlobalAugmentation.class) != null
                && hwvtepNode.getAugmentation(HwvtepGlobalAugmentation.class).getSwitches() != null) {
            for (Switches switches : hwvtepNode.getAugmentation(HwvtepGlobalAugmentation.class).getSwitches()) {
                NodeId psNodeId = switches.getSwitchRef().getValue().firstKeyOf(Node.class).getNodeId();
                return HwvtepUtils.getHwVtepNode(dataBroker, datastoreType, psNodeId);
            }
        }
        return null;
    }
}

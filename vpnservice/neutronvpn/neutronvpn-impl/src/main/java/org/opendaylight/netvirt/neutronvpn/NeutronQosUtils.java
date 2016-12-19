/*
 * Copyright (c) 2016 Intel Corporation and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.neutronvpn;

import com.google.common.base.Optional;
import java.math.BigInteger;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.ReadOnlyTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.ovsdb.utils.southbound.utils.SouthboundUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406.BridgeInterfaceInfo;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406.BridgeRefInfo;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406.bridge._interface.info.BridgeEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406.bridge._interface.info.BridgeEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406.bridge.ref.info.BridgeRefEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406.bridge.ref.info.BridgeRefEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetDpidFromInterfaceInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetDpidFromInterfaceInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetDpidFromInterfaceOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.networks.attributes.networks.Network;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.qos.ext.rev160613.QosNetworkExtension;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.qos.ext.rev160613.QosPortExtension;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.qos.rev160613.qos.attributes.qos.policies.QosPolicy;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.qos.rev160613.qos.attributes.qos.policies.qos.policy.BandwidthLimitRules;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.qos.rev160613.qos.attributes.qos.policies.qos.policy.BandwidthLimitRulesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbBridgeRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbTerminationPointAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbTerminationPointAugmentationBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.ovsdb.port._interface.attributes.InterfaceExternalIds;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NetworkTopology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.TopologyKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPoint;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPointBuilder;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPointKey;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public class NeutronQosUtils {
    private static final Logger LOG = LoggerFactory.getLogger(NeutronQosUtils.class);
    private static final String EXTERNAL_ID_INTERFACE_ID = "iface-id";

    public static void handleNeutronPortQosUpdate(DataBroker db, OdlInterfaceRpcService odlInterfaceRpcService,
            Port port, Uuid qosUuid) {
        LOG.trace("Handling Port QoS update: port: {} qos: {}", port.getUuid(), qosUuid);

        // handle Bandwidth Limit Rules update
        QosPolicy qosPolicy = NeutronvpnUtils.qosPolicyMap.get(qosUuid);
        if (qosPolicy != null && qosPolicy.getBandwidthLimitRules() != null
                && !qosPolicy.getBandwidthLimitRules().isEmpty()) {
            setPortBandwidthLimits(db, odlInterfaceRpcService, port,
                    qosPolicy.getBandwidthLimitRules().get(0));
        }
    }

    public static void handleNeutronPortQosRemove(DataBroker db, OdlInterfaceRpcService odlInterfaceRpcService,
            Port port, Uuid qosUuid) {
        LOG.trace("Handling Port QoS removal: port: {} qos: {}", port.getUuid(), qosUuid);

        // handle Bandwidth Limit Rules removal
        QosPolicy qosPolicy = NeutronvpnUtils.qosPolicyMap.get(qosUuid);
        if (qosPolicy != null && qosPolicy.getBandwidthLimitRules() != null
                && !qosPolicy.getBandwidthLimitRules().isEmpty()) {
            BandwidthLimitRulesBuilder bwLimitBuilder = new BandwidthLimitRulesBuilder();
            setPortBandwidthLimits(db, odlInterfaceRpcService, port,
                    bwLimitBuilder.setMaxBurstKbps(BigInteger.ZERO).setMaxKbps(BigInteger.ZERO).build());
        }

        // check for network qos to apply
        Network network = NeutronvpnUtils.getNeutronNetwork(db, port.getNetworkId());
        if (network != null && network.getAugmentation(QosNetworkExtension.class) != null) {
            Uuid networkQosUuid = network.getAugmentation(QosNetworkExtension.class).getQosPolicyId();
            if (networkQosUuid != null) {
                handleNeutronPortQosUpdate(db, odlInterfaceRpcService, port, networkQosUuid);
            }
        }
    }

    public static void handleNeutronNetworkQosUpdate(DataBroker db, OdlInterfaceRpcService odlInterfaceRpcService,
            Network network, Uuid qosUuid) {
        LOG.trace("Handling Network QoS update: net: {} qos: {}", network.getUuid(), qosUuid);
        QosPolicy qosPolicy = NeutronvpnUtils.qosPolicyMap.get(qosUuid);
        if (qosPolicy == null || qosPolicy.getBandwidthLimitRules() == null
                || qosPolicy.getBandwidthLimitRules().isEmpty()) {
            return;
        }
        List<Uuid> subnetIds = NeutronvpnUtils.getSubnetIdsFromNetworkId(db, network.getUuid());
        if (subnetIds != null) {
            for (Uuid subnetId : subnetIds) {
                List<Uuid> portIds = NeutronvpnUtils.getPortIdsFromSubnetId(db, subnetId);
                if (portIds != null) {
                    for (Uuid portId : portIds) {
                        Port port = NeutronvpnUtils.portMap.get(portId);
                        if (port != null && (port.getAugmentation(QosPortExtension.class) == null
                                || port.getAugmentation(QosPortExtension.class).getQosPolicyId() == null)) {
                            setPortBandwidthLimits(db, odlInterfaceRpcService, port,
                                    qosPolicy.getBandwidthLimitRules().get(0));
                        }
                    }
                }
            }
        }
    }

    public static void handleNeutronNetworkQosRemove(DataBroker db, OdlInterfaceRpcService odlInterfaceRpcService,
            Network network, Uuid qosUuid) {
        LOG.trace("Handling Network QoS removal: net: {} qos: {}", network.getUuid(), qosUuid);

        List<Uuid> subnetIds = NeutronvpnUtils.getSubnetIdsFromNetworkId(db, network.getUuid());
        if (subnetIds != null) {
            for (Uuid subnetId : subnetIds) {
                List<Uuid> portIds = NeutronvpnUtils.getPortIdsFromSubnetId(db, subnetId);
                if (portIds != null) {
                    for (Uuid portId : portIds) {
                        Port port = NeutronvpnUtils.portMap.get(portId);
                        if (port != null && (port.getAugmentation(QosPortExtension.class) == null
                                || port.getAugmentation(QosPortExtension.class).getQosPolicyId() == null)) {
                            BandwidthLimitRulesBuilder bwLimitBuilder = new BandwidthLimitRulesBuilder();
                            setPortBandwidthLimits(db, odlInterfaceRpcService, port,
                                    bwLimitBuilder.setMaxBurstKbps(BigInteger.ZERO)
                                    .setMaxKbps(BigInteger.ZERO).build());
                        }
                    }
                }
            }
        }
    }

    public static void setPortBandwidthLimits(DataBroker db, OdlInterfaceRpcService odlInterfaceRpcService,
            Port port, BandwidthLimitRules bwLimit) {
        LOG.trace("Setting bandwidth limits {} on Port {}", port, bwLimit);

        BigInteger dpId = getDpnForInterface(odlInterfaceRpcService, port.getUuid().getValue());
        if (dpId.equals(BigInteger.ZERO)) {
            LOG.info("DPN ID for interface {} not found", port.getUuid().getValue());
            return;
        }

        OvsdbBridgeRef bridgeRefEntry = getBridgeRefEntryFromOperDS(dpId, db);
        Optional<Node> bridgeNode = MDSALUtil.read(LogicalDatastoreType.OPERATIONAL,
                bridgeRefEntry.getValue().firstIdentifierOf(Node.class), db);


        TerminationPoint tp = getTerminationPoint(bridgeNode.get(), port.getUuid().getValue());
        OvsdbTerminationPointAugmentation ovsdbTp = tp.getAugmentation(OvsdbTerminationPointAugmentation.class);

        OvsdbTerminationPointAugmentationBuilder tpAugmentationBuilder = new OvsdbTerminationPointAugmentationBuilder();
        tpAugmentationBuilder.setName(ovsdbTp.getName());
        tpAugmentationBuilder.setIngressPolicingRate(bwLimit.getMaxKbps().longValue());
        tpAugmentationBuilder.setIngressPolicingBurst(bwLimit.getMaxBurstKbps().longValue());

        TerminationPointBuilder tpBuilder = new TerminationPointBuilder();
        tpBuilder.setKey(tp.getKey());
        tpBuilder.addAugmentation(OvsdbTerminationPointAugmentation.class, tpAugmentationBuilder.build());
        MDSALUtil.syncUpdate(db, LogicalDatastoreType.CONFIGURATION, InstanceIdentifier
                .create(NetworkTopology.class)
                .child(Topology.class, new TopologyKey(SouthboundUtils.OVSDB_TOPOLOGY_ID))
                .child(Node.class, bridgeNode.get().getKey())
                .child(TerminationPoint.class, new TerminationPointKey(tp.getKey())), tpBuilder.build());
    }

    private static TerminationPoint getTerminationPoint(Node bridgeNode, String interfaceName) {
        for (TerminationPoint tp : bridgeNode.getTerminationPoint()) {
            Boolean found = false;
            OvsdbTerminationPointAugmentation ovsdbTp = tp.getAugmentation(OvsdbTerminationPointAugmentation.class);
            if (ovsdbTp.getInterfaceExternalIds() != null
                    && !ovsdbTp.getInterfaceExternalIds().isEmpty()) {
                for (InterfaceExternalIds entry : ovsdbTp.getInterfaceExternalIds()) {
                    if (entry.getExternalIdKey().equals(EXTERNAL_ID_INTERFACE_ID)
                            && entry.getExternalIdValue().equals(interfaceName)) {
                        found = true;
                        continue;
                    }
                }
            }
            if (found) {
                return tp;
            }
        }
        return null;
    }

    private static BigInteger getDpnForInterface(OdlInterfaceRpcService interfaceManagerRpcService, String ifName) {
        BigInteger nodeId = BigInteger.ZERO;
        try {
            GetDpidFromInterfaceInput
                dpIdInput = new GetDpidFromInterfaceInputBuilder().setIntfName(ifName).build();
            Future<RpcResult<GetDpidFromInterfaceOutput>>
                dpIdOutput = interfaceManagerRpcService.getDpidFromInterface(dpIdInput);
            RpcResult<GetDpidFromInterfaceOutput> dpIdResult = dpIdOutput.get();
            if (dpIdResult.isSuccessful()) {
                nodeId = dpIdResult.getResult().getDpid();
            } else {
                LOG.error("Could not retrieve DPN Id for interface {}", ifName);
            }
        } catch (NullPointerException | InterruptedException | ExecutionException e) {
            LOG.error("Exception when getting dpn for interface {}", ifName,  e);
        }
        return nodeId;
    }

    private static BridgeEntry getBridgeEntryFromConfigDS(BigInteger dpnId,
            DataBroker dataBroker) {
        BridgeEntryKey bridgeEntryKey = new BridgeEntryKey(dpnId);
        InstanceIdentifier<BridgeEntry> bridgeEntryInstanceIdentifier = getBridgeEntryIdentifier(bridgeEntryKey);
        LOG.debug("Trying to retrieve bridge entry from config for Id: {}", bridgeEntryInstanceIdentifier);
        return getBridgeEntryFromConfigDS(bridgeEntryInstanceIdentifier,
                dataBroker);
    }

    private static BridgeEntry getBridgeEntryFromConfigDS(InstanceIdentifier<BridgeEntry> bridgeEntryInstanceIdentifier,
            DataBroker dataBroker) {
        Optional<BridgeEntry> bridgeEntryOptional =
            read(LogicalDatastoreType.CONFIGURATION, bridgeEntryInstanceIdentifier, dataBroker);
        if (!bridgeEntryOptional.isPresent()) {
            return null;
        }
        return bridgeEntryOptional.get();
    }

    private static BridgeRefEntry getBridgeRefEntryFromOperDS(InstanceIdentifier<BridgeRefEntry> dpnBridgeEntryIid,
            DataBroker dataBroker) {
        Optional<BridgeRefEntry> bridgeRefEntryOptional =
                read(LogicalDatastoreType.OPERATIONAL, dpnBridgeEntryIid, dataBroker);
        if (!bridgeRefEntryOptional.isPresent()) {
            return null;
        }
        return bridgeRefEntryOptional.get();
    }

    private static OvsdbBridgeRef getBridgeRefEntryFromOperDS(BigInteger dpId,
            DataBroker dataBroker) {
        BridgeRefEntryKey bridgeRefEntryKey = new BridgeRefEntryKey(dpId);
        InstanceIdentifier<BridgeRefEntry> bridgeRefEntryIid = getBridgeRefEntryIdentifier(bridgeRefEntryKey);
        BridgeRefEntry bridgeRefEntry = getBridgeRefEntryFromOperDS(bridgeRefEntryIid, dataBroker);
        if (bridgeRefEntry == null) {
            // bridge ref entry will be null if the bridge is disconnected from controller.
            // In that case, fetch bridge reference from bridge interface entry config DS
            BridgeEntry bridgeEntry = getBridgeEntryFromConfigDS(dpId, dataBroker);
            if (bridgeEntry == null) {
                return null;
            }
            return  bridgeEntry.getBridgeReference();
        }
        return bridgeRefEntry.getBridgeReference();
    }

    private static InstanceIdentifier<BridgeRefEntry> getBridgeRefEntryIdentifier(BridgeRefEntryKey bridgeRefEntryKey) {
        InstanceIdentifier.InstanceIdentifierBuilder<BridgeRefEntry> bridgeRefEntryInstanceIdentifierBuilder =
                InstanceIdentifier.builder(BridgeRefInfo.class)
                        .child(BridgeRefEntry.class, bridgeRefEntryKey);
        return bridgeRefEntryInstanceIdentifierBuilder.build();
    }

    private static InstanceIdentifier<BridgeEntry> getBridgeEntryIdentifier(BridgeEntryKey bridgeEntryKey) {
        InstanceIdentifier.InstanceIdentifierBuilder<BridgeEntry> bridgeEntryIdBuilder =
                InstanceIdentifier.builder(BridgeInterfaceInfo.class).child(BridgeEntry.class, bridgeEntryKey);
        return bridgeEntryIdBuilder.build();
    }

    private static <T extends DataObject> Optional<T> read(LogicalDatastoreType datastoreType,
            InstanceIdentifier<T> path, DataBroker broker) {

        ReadOnlyTransaction tx = broker.newReadOnlyTransaction();

        Optional<T> result = Optional.absent();
        try {
            result = tx.read(datastoreType, path).get();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

        return result;
    }
}

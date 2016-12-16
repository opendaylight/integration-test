/*
 * Copyright (c) 2016 Brocade Communications Systems, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.openstack.sfc.translator;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.netvirt.utils.mdsal.utils.MdsalUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbBridgeAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbNodeAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbNodeRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbTerminationPointAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.ovsdb.port._interface.attributes.InterfaceExternalIds;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NetworkTopology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.TopologyId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.TopologyKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.NodeKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPoint;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

/**
 * Utility methods to read OpenDaylight OVSDB models.
 */
public class OvsdbMdsalHelper {
    private static final Logger LOG = LoggerFactory.getLogger(SfcMdsalHelper.class);
    private static final String OVSDB_TOPOLOGY_ID = "ovsdb:1";
    private static final InstanceIdentifier<Topology> topologyPath
            = InstanceIdentifier.create(NetworkTopology.class)
            .child(Topology.class, new TopologyKey(new TopologyId(OVSDB_TOPOLOGY_ID)));

    private final DataBroker dataBroker;
    private final MdsalUtils mdsalUtils;

    public OvsdbMdsalHelper(DataBroker dataBroker) {
        this.dataBroker = dataBroker;
        mdsalUtils = new MdsalUtils(this.dataBroker);
    }

    public Topology getOvsdbTopologyTree() {
        LOG.info("Reading OVSDB Topolog Tree (ovsdb:1)");
        return mdsalUtils.read(LogicalDatastoreType.OPERATIONAL, topologyPath);
    }

    public OvsdbPortMetadata getOvsdbPortMetadata(Uuid ingressPort) {
        LOG.info("Extract ovsdb port details for neutron port {}", ingressPort.getValue());
        Topology ovsdbTopology = mdsalUtils.read(LogicalDatastoreType.OPERATIONAL, topologyPath);
        return getOvsdbPortMetadata(ingressPort, ovsdbTopology);
    }
    public OvsdbPortMetadata getOvsdbPortMetadata(Uuid ingressPort, Topology ovsdbTopology) {
        LOG.debug("Extract ovsdb port details for neutron port {} from Topology {}",
                ingressPort.getValue(), ovsdbTopology);
        OvsdbPortMetadata ovsdbPortMetadata = new OvsdbPortMetadata();
        OvsdbBridgeAugmentation bridgeAugmentation = null;
        if (ovsdbTopology != null) {
            List<Node> nodes = ovsdbTopology.getNode();
            for (Node node : nodes) {
                if (node.getTerminationPoint() != null) {
                    for (TerminationPoint tp : node.getTerminationPoint()) {
                        OvsdbTerminationPointAugmentation tpAugmentation
                                = tp.getAugmentation(OvsdbTerminationPointAugmentation.class);
                        List<InterfaceExternalIds> externalIds = tpAugmentation.getInterfaceExternalIds();
                        if (externalIds != null ) {
                            for (InterfaceExternalIds externalId : externalIds) {
                                if(externalId.getExternalIdValue().equals(ingressPort.getValue())) {
                                    LOG.info("OVSDB port found for neutron port {} : {}", ingressPort, tpAugmentation);
                                    ovsdbPortMetadata.setOvsdbPort(tpAugmentation);
                                    break;
                                }
                            }
                            if (ovsdbPortMetadata.getOvsdbPort() != null) {
                                break;
                            }
                        }
                    }
                }
                if (ovsdbPortMetadata.getOvsdbPort() != null) {
                    bridgeAugmentation = node.getAugmentation(OvsdbBridgeAugmentation.class);
                    if (bridgeAugmentation != null) {
                        ovsdbPortMetadata.setOvsdbBridgeNode(bridgeAugmentation);
                    } else {
                        LOG.warn("Brige augmentation is not present " +
                                "for the termination point {}",ovsdbPortMetadata.getOvsdbPort());
                        return null;
                    }
                    break;
                }
            }
            OvsdbNodeRef ovsdbNode = bridgeAugmentation.getManagedBy();
            if (ovsdbNode != null) {
                NodeKey ovsdbNodeKey = ovsdbNode.getValue().firstKeyOf(Node.class);
                for (Node node : nodes) {
                    if(node.getKey().equals(ovsdbNodeKey)) {
                        OvsdbNodeAugmentation nodeAugmentation = node.getAugmentation(OvsdbNodeAugmentation.class);
                        ovsdbPortMetadata.setOvsdbNode(nodeAugmentation);
                        break;
                    }
                }
            } else {
                LOG.warn("Ovsdb Node not found for ovsdb bridge {}",bridgeAugmentation);
            }

        } else {
            LOG.warn("OVSDB Operational topology not avaialble.");
        }
        LOG.info("Neutron port's {} respective Ovsdb metadata {}", ingressPort, ovsdbPortMetadata);
        return ovsdbPortMetadata;
    }

    public static String getOvsdbPortName(OvsdbTerminationPointAugmentation ovsdbPort) {
        return ovsdbPort.getName();
    }

    public static String getNodeIpAddress(OvsdbNodeAugmentation ovsdbNode) {
        //Currently we support only ipv4
        return ovsdbNode.getConnectionInfo().getRemoteIp().getIpv4Address().getValue();
    }

    public static String getNodeKey(InstanceIdentifier<?> node) {
        return node.firstKeyOf(Node.class).getNodeId().getValue();
    }
}

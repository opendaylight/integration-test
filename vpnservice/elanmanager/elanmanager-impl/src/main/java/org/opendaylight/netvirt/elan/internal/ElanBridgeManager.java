/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.internal;

import com.google.common.base.Optional;
import com.google.common.base.Splitter;
import com.google.common.base.Strings;

import java.math.BigInteger;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.genius.interfacemanager.globals.IfmConstants;
import org.opendaylight.ovsdb.utils.config.ConfigProperties;
import org.opendaylight.ovsdb.utils.mdsal.utils.MdsalUtils;
import org.opendaylight.ovsdb.utils.southbound.utils.SouthboundUtils;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.DatapathTypeBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.DatapathTypeNetdev;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbNodeAugmentation;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * This class provides functions for creating bridges via OVSDB, specifically the br-int bridge.
 * Note and TODO: br-ex is temporary. vpnservice does not require it but for the time being it is
 * left here because devstack expects it.
 */
public class ElanBridgeManager {
    private static final Logger LOG = LoggerFactory.getLogger(ElanBridgeManager.class);

    public static final String PROVIDER_MAPPINGS_KEY = "provider_mappings";
    private static final String INTEGRATION_BRIDGE = "br-int";
    private static final String INT_SIDE_PATCH_PORT_SUFFIX = "-patch";
    private static final String EX_SIDE_PATCH_PORT_SUFFIX = "-int-patch";
    private static final int MAX_LINUX_INTERFACE_NAME_LENGTH = 15;

    private final MdsalUtils mdsalUtils;
    final SouthboundUtils southboundUtils;
    private Random random;

    /**
     * Construct a new ElanBridgeManager.
     * @param dataBroker DataBroker
     */
    public ElanBridgeManager(DataBroker dataBroker) {
        //TODO: ClusterAware!!!??
        this.mdsalUtils = new MdsalUtils(dataBroker);
        this.southboundUtils = new SouthboundUtils(mdsalUtils);
        this.random = new Random(System.currentTimeMillis());
    }

    /**
     * Is OVS running in userspace mode?
     * @return true if the ovsdb.userspace.enabled variable is set to true
     */
    public boolean isUserSpaceEnabled() {
        final String enabledPropertyStr = ConfigProperties.getProperty(this.getClass(), "ovsdb.userspace.enabled");
        return enabledPropertyStr != null && enabledPropertyStr.equalsIgnoreCase("yes");
    }

    /**
     * Is the Node object an OVSDB node.
     * @param node unidentified node object
     * @return true if the Node is an OVSDB node
     */
    public boolean isOvsdbNode(Node node) {
        return southboundUtils.extractNodeAugmentation(node) != null;
    }

    /**
     * Is this Node the integration bridge (br-int).
     * @param node unidentified noe object
     * @return true if the Node is a bridge and it is the integration bridge
     */
    public boolean isIntegrationBridge(Node node) {
        if (!isBridgeNode(node)) {
            return false;
        }

        String bridgeName = southboundUtils.extractBridgeName(node);
        if (bridgeName == null) {
            return false;
        }

        return bridgeName.equals(INTEGRATION_BRIDGE);
    }

    /**
     * Is this node a bridge.
     * @param node unidentified node object
     * @return true if this node is a bridge
     */
    public boolean isBridgeNode(Node node) {
        return southboundUtils.extractBridgeAugmentation(node) != null;
    }

    /**
     * Advance the "preperation" of the OVSDB node. This re-entrant method advances the state of an OVSDB
     * node towards the prepared state where all bridges and patch ports are created and active. This method
     * should be invoked for the OVSDB node and the integration bridge node BUT IT IS SAFE TO INVOKE IT ON ANY NODE.
     * @param node A node
     * @param generateIntBridgeMac whether or not the int bridge's mac should be set to a random value
     */
    public void processNodePrep(Node node, boolean generateIntBridgeMac) {
        if (isOvsdbNode(node)) {
            ensureBridgesExist(node, generateIntBridgeMac);

            //if br-int already exists, we can add provider networks
            Node brIntNode = southboundUtils.readBridgeNode(node, INTEGRATION_BRIDGE);
            if (brIntNode != null) {
                if (!addControllerToBridge(node, INTEGRATION_BRIDGE)) {
                    LOG.error("Failed to set controller to existing integration bridge {}", brIntNode);
                }

                prepareIntegrationBridge(node, brIntNode);
            }
            return;
        }

        Node ovsdbNode = southboundUtils.readOvsdbNode(node);
        if (ovsdbNode == null) {
            LOG.error("Node is neither bridge nor ovsdb {}", node);
            return;
        }

        if (isIntegrationBridge(node)) {
            prepareIntegrationBridge(ovsdbNode, node);
        }

    }

    private void prepareIntegrationBridge(Node ovsdbNode, Node brIntNode) {
        Optional<Map<String, String>> providerMappings = getOpenvswitchOtherConfigMap(ovsdbNode, PROVIDER_MAPPINGS_KEY);

        for (String value : providerMappings.or(Collections.emptyMap()).values()) {
            if (southboundUtils.extractTerminationPointAugmentation(brIntNode, value) != null) {
                LOG.debug("prepareIntegrationBridge: port {} already exists on {}", value, INTEGRATION_BRIDGE);
                continue;
            }

            Node exBridgeNode = southboundUtils.readBridgeNode(ovsdbNode, value);
            if (exBridgeNode != null) {
                LOG.debug("prepareIntegrationBridge: bridge {} found. Patching to {}", value, INTEGRATION_BRIDGE);
                patchBridgeToBrInt(brIntNode, exBridgeNode, value);
            } else {
                LOG.debug("prepareIntegrationBridge: adding interface {} to {}", value, INTEGRATION_BRIDGE);
                if (!addPortToBridge(brIntNode, INTEGRATION_BRIDGE, value)) {
                    LOG.error("Failed to add {} port to {}", value, brIntNode);
                }
            }

        }

    }

    private void patchBridgeToBrInt(Node intBridgeNode, Node exBridgeNode, String physnetBridgeName) {

        String portNameInt = getIntSidePatchPortName(physnetBridgeName);
        String portNameExt = getExSidePatchPortName(physnetBridgeName);
        if (!addPatchPort(intBridgeNode, INTEGRATION_BRIDGE, portNameInt, portNameExt)) {
            LOG.error("Failed to add patch port {} to {}", portNameInt, intBridgeNode);
            return;
        }

        if (!addPatchPort(exBridgeNode, physnetBridgeName, portNameExt, portNameInt)) {
            LOG.error("Failed to add patch port {} to {}", portNameExt, exBridgeNode);
            return;
        }
    }

    @SuppressWarnings("checkstyle:IllegalCatch")
    private void ensureBridgesExist(Node ovsdbNode, boolean generateIntBridgeMac) {
        try {
            createIntegrationBridge(ovsdbNode, generateIntBridgeMac);
        } catch (RuntimeException e) {
            LOG.error("Error creating bridge on " + ovsdbNode, e);
        }
    }

    private boolean createIntegrationBridge(Node ovsdbNode, boolean generateIntBridgeMac) {
        // Make sure iface-type exist in Open_vSwitch table prior to br-int creation
        // in order to allow mixed topology of both DPDK and non-DPDK OVS nodes
        if (!ifaceTypesExist(ovsdbNode)) {
            LOG.debug("Skipping integration bridge creation as if-types has not been initialized");
            return false;
        }

        LOG.debug("ElanBridgeManager.createIntegrationBridge, skipping if exists");
        if (!addBridge(ovsdbNode, INTEGRATION_BRIDGE,
                generateIntBridgeMac ? generateRandomMac() : null)) {
            LOG.warn("Integration Bridge Creation failed");
            return false;
        }
        return true;
    }

    private boolean ifaceTypesExist(Node ovsdbNode) {
        OvsdbNodeAugmentation ovsdbNodeAugmentation = southboundUtils.extractNodeAugmentation(ovsdbNode);
        return ovsdbNodeAugmentation != null && ovsdbNodeAugmentation.getInterfaceTypeEntry() != null
                && !ovsdbNodeAugmentation.getInterfaceTypeEntry().isEmpty();
    }

    /**
     * Add a bridge to the OVSDB node but check that it does not exist in the
     * CONFIGURATION or OPERATIONAL md-sals first.
     *
     * @param ovsdbNode Which OVSDB node
     * @param bridgeName Name of the bridge
     * @param mac mac address to set on the bridge or null
     * @return true if no errors occurred
     */
    public boolean addBridge(Node ovsdbNode, String bridgeName, String mac) {
        boolean rv = true;
        if (!southboundUtils.isBridgeOnOvsdbNode(ovsdbNode, bridgeName)
                || southboundUtils.getBridgeFromConfig(ovsdbNode, bridgeName) == null) {
            Class<? extends DatapathTypeBase> dpType = null;
            if (isUserSpaceEnabled()) {
                dpType = DatapathTypeNetdev.class;
            }
            rv = southboundUtils.addBridge(ovsdbNode, bridgeName,
                    southboundUtils.getControllersFromOvsdbNode(ovsdbNode), dpType, mac);
        }
        return rv;
    }

    private boolean addControllerToBridge(Node ovsdbNode,String bridgeName) {
        return southboundUtils.setBridgeController(ovsdbNode,
                            bridgeName, southboundUtils.getControllersFromOvsdbNode(ovsdbNode));
    }

    /**
     * Extract OpenvSwitch other-config to key value map.
     * @param node OVSDB node
     * @param key key to extract from other-config
     * @return Optional of key-value Map
     */
    public Optional<Map<String, String>> getOpenvswitchOtherConfigMap(Node node, String key) {
        String providerMappings = southboundUtils.getOpenvswitchOtherConfig(node, key);
        return extractMultiKeyValueToMap(providerMappings);
    }

    /**
     * Get the OVS node physical interface name from provider mappings.
     * @param node OVSDB node
     * @param physicalNetworkName name of physical network
     * @return physical network name
     */
    public String getProviderMappingValue(Node node, String physicalNetworkName) {
        Optional<Map<String, String>> providerMappings = getOpenvswitchOtherConfigMap(node, PROVIDER_MAPPINGS_KEY);
        if (!providerMappings.isPresent()) {
            LOG.trace("Physical network {} not found in {}", physicalNetworkName, PROVIDER_MAPPINGS_KEY);
            return null;
        }

        return providerMappings.get().get(physicalNetworkName);
    }

    /**
     * Get the name of the port in br-int for the given provider-mapping value. This is either a patch port to a bridge
     * with providerMappingValue - patch-&lt;providerMappingValue&gt; or simply a port with the same name as
     * providerMappingValue
     * @param bridgeNode br-int Node
     * @param providerMappingValue this is the last part of provider_mappings=net_name:THIS
     * @return the name of the port on br-int
     */
    public String getIntBridgePortNameFor(Node bridgeNode, String providerMappingValue) {
        String res = providerMappingValue;
        Node managingNode = southboundUtils.readOvsdbNode(bridgeNode);
        if (managingNode != null && southboundUtils.isBridgeOnOvsdbNode(managingNode, providerMappingValue)) {
            res = getIntSidePatchPortName(providerMappingValue);
        }

        return res;
    }

    /**
     * Get the name of the patch-port which is patched to the bridge containing
     * interfaceName. Patch port name is truncated to the maximum allowed characters
     *
     * @param interfaceName The external interface
     * @return interface name
     */
    public String getIntSidePatchPortName(String interfaceName) {
        String patchPortName = interfaceName + INT_SIDE_PATCH_PORT_SUFFIX;
        if (patchPortName.length() <= MAX_LINUX_INTERFACE_NAME_LENGTH) {
            return patchPortName;
        }

        LOG.warn("Patch port {} exceeds maximum allowed length. Truncating to {} characters", patchPortName,
                MAX_LINUX_INTERFACE_NAME_LENGTH);
        return patchPortName.substring(0, MAX_LINUX_INTERFACE_NAME_LENGTH - 1);
    }

    private String getExSidePatchPortName(String physicalInterfaceName) {
        return physicalInterfaceName + EX_SIDE_PATCH_PORT_SUFFIX;
    }

    /**
     * Add a port to a bridge.
     * @param node the bridge node
     * @param bridgeName name of the bridge
     * @param portName name of port to add
     * @return true if successful in writing to mdsal
     */
    public boolean addPortToBridge(Node node, String bridgeName, String portName) {
        boolean rv = true;

        if (southboundUtils.extractTerminationPointAugmentation(node, portName) == null) {
            rv = southboundUtils.addTerminationPoint(node, bridgeName, portName, null);

            if (rv) {
                LOG.debug("addPortToBridge: node: {}, bridge: {}, portname: {} status: success",
                        node.getNodeId().getValue(), bridgeName, portName);
            } else {
                LOG.error("addPortToBridge: node: {}, bridge: {}, portname: {} status: FAILED",
                        node.getNodeId().getValue(), bridgeName, portName);
            }
        } else {
            LOG.trace("addPortToBridge: node: {}, bridge: {}, portname: {} status: not_needed",
                    node.getNodeId().getValue(), bridgeName, portName);
        }

        return rv;
    }

    /**
     * Add a patch port to a bridge.
     * @param node the bridge node
     * @param bridgeName name of the bridge
     * @param portName name of the port
     * @param peerPortName name of the port's peer (the other side)
     * @return true if successful
     */
    public boolean addPatchPort(Node node, String bridgeName, String portName, String peerPortName) {
        boolean rv = true;

        if (southboundUtils.extractTerminationPointAugmentation(node, portName) == null) {
            rv = southboundUtils.addPatchTerminationPoint(node, bridgeName, portName, peerPortName);

            if (rv) {
                LOG.info("addPatchPort: node: {}, bridge: {}, portname: {} peer: {} status: success",
                        node.getNodeId().getValue(), bridgeName, portName, peerPortName);
            } else {
                LOG.error("addPatchPort: node: {}, bridge: {}, portname: {} peer: {} status: FAILED",
                        node.getNodeId().getValue(), bridgeName, portName, peerPortName);
            }
        } else {
            LOG.trace("addPatchPort: node: {}, bridge: {}, portname: {} peer: {} status: not_needed",
                    node.getNodeId().getValue(), bridgeName, portName, peerPortName);
        }

        return rv;
    }

    private String generateRandomMac() {
        byte[] macBytes = new byte[6];
        random.nextBytes(macBytes);
        macBytes[0] &= 0xfc; //the two low bits of the first byte need to be zero

        StringBuilder stringBuilder = new StringBuilder();

        int index = 0;
        while (true) {
            stringBuilder.append(String.format("%02x", macBytes[index++]));
            if (index >= 6) {
                break;
            }
            stringBuilder.append(':');
        }

        return stringBuilder.toString();
    }

    private static Optional<Map<String, String>> extractMultiKeyValueToMap(String multiKeyValueStr) {
        if (Strings.isNullOrEmpty(multiKeyValueStr)) {
            return Optional.absent();
        }

        Map<String, String> valueMap = new HashMap<>();
        Splitter splitter = Splitter.on(",");
        for (String keyValue : splitter.split(multiKeyValueStr)) {
            String[] split = keyValue.split(":", 2);
            if (split != null && split.length == 2) {
                valueMap.put(split[0], split[1]);
            }
        }

        return Optional.of(valueMap);
    }

    public Node getBridgeNode(BigInteger dpId) {
        List<Node> ovsdbNodes = southboundUtils.getOvsdbNodes();
        if (null == ovsdbNodes) {
            LOG.debug("Could not find any (?) ovsdb nodes");
            return null;
        }

        for (Node node : ovsdbNodes) {
            if (!isIntegrationBridge(node)) {
                continue;
            }

            long nodeDpid = southboundUtils.getDataPathId(node);
            if (dpId.equals(BigInteger.valueOf(nodeDpid))) {
                return node;
            }
        }

        return null;
    }

    public String getProviderInterfaceName(BigInteger dpId, String physicalNetworkName) {
        Node brNode;

        brNode = getBridgeNode(dpId);
        if (brNode == null) {
            LOG.debug("Could not find bridge node for {}", dpId);
            return null;
        }

        return getProviderInterfaceName(brNode, physicalNetworkName);
    }

    public String getProviderInterfaceName(Node bridgeNode, String physicalNetworkName) {
        if (physicalNetworkName == null) {
            return null;
        }

        String providerMappingValue = getProviderMappingValue(bridgeNode, physicalNetworkName);
        if (providerMappingValue == null) {
            LOG.trace("No provider mapping found for physicalNetworkName {} node {}", physicalNetworkName,
                    bridgeNode.getNodeId().getValue());
            return null;
        }

        long dataPathId = southboundUtils.getDataPathId(bridgeNode);
        if (dataPathId < 1) {
            LOG.info("No DatapathID for node {} with physicalNetworkName {}",
                    bridgeNode.getNodeId().getValue(), physicalNetworkName);
            return null;
        }

        return dataPathId + IfmConstants.OF_URI_SEPARATOR
                + getIntBridgePortNameFor(bridgeNode, providerMappingValue);
    }

    public boolean hasDatapathID(Node node) {
        return southboundUtils.getDataPathId(node) > 0 ? true : false;
    }

    public Boolean isBridgeOnOvsdbNode(Node ovsdbNode, String bridgename) {
        return southboundUtils.isBridgeOnOvsdbNode(ovsdbNode, bridgename);
    }

    public String getIntegrationBridgeName() {
        return INTEGRATION_BRIDGE;
    }
}

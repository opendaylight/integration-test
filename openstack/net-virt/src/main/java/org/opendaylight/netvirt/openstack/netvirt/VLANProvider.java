/*
 * Copyright (c) 2016 NEC Corporation and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.openstack.netvirt;

import java.util.List;

import org.apache.commons.lang3.tuple.ImmutablePair;
import org.opendaylight.netvirt.openstack.netvirt.api.ConfigurationService;
import org.opendaylight.netvirt.openstack.netvirt.api.NodeCacheManager;
import org.opendaylight.netvirt.openstack.netvirt.api.VlanResponderProvider;
import org.opendaylight.netvirt.openstack.netvirt.api.Southbound;
import org.opendaylight.netvirt.openstack.netvirt.translator.NeutronNetwork;
import org.opendaylight.netvirt.openstack.netvirt.translator.NeutronPort;
import org.opendaylight.netvirt.openstack.netvirt.translator.Neutron_IPs;
import org.opendaylight.netvirt.utils.servicehelper.ServiceHelper;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbTerminationPointAugmentation;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPoint;
import org.osgi.framework.ServiceReference;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.base.Preconditions;

/**
 * This class is used to add the flows when l3 is disabled in the ODL.
 */
public class VLANProvider implements ConfigInterface {
    private final Logger LOG = LoggerFactory.getLogger(VLANProvider.class);

    // The implementation for each of these services is resolved by the OSGi Service Manager
    private volatile ConfigurationService configurationService;
    private volatile NodeCacheManager nodeCacheManager;
    private volatile VlanResponderProvider vlanResponderProvider;
    private Southbound southbound;

    public void programProviderNetworkFlow(Node envNode, OvsdbTerminationPointAugmentation port, NeutronNetwork network,
            NeutronPort neutronPort, Boolean write) {
        try {
            final String brInt = configurationService.getIntegrationBridgeName();
            final String brExt = configurationService.getExternalBridgeName();
            final String portNameInt = configurationService.getPatchPortName(new ImmutablePair<>(brInt, brExt));
            final String portNameExt = configurationService.getPatchPortName(new ImmutablePair<>(brExt, brInt));
            Long ofPort = port.getOfport();
            String macAddress = neutronPort.getMacAddress();
            final Long dpIdInt = getDpidForIntegrationBridge(envNode, portNameInt);
            final Long dpIdExt = getDpidForExternalBridge();
            Long patchIntPort = getPatchPort(dpIdInt, portNameInt);
            Long patchExtPort = getPatchPort(dpIdExt, portNameExt);
            Preconditions.checkNotNull(dpIdInt);
            Preconditions.checkNotNull(dpIdExt);
            Preconditions.checkNotNull(portNameInt);
            vlanResponderProvider.programProviderNetworkOutput(dpIdInt, ofPort, patchIntPort, macAddress, write);
            vlanResponderProvider.programProviderNetworkPopVlan(dpIdInt, network.getProviderSegmentationID(),
                   ofPort, patchIntPort, write);
            vlanResponderProvider.programProviderNetworkPushVlan(dpIdExt, network.getProviderSegmentationID(),
                   patchExtPort, macAddress, write);
            vlanResponderProvider.programProviderNetworkDrop(dpIdExt, patchExtPort, write);
        } catch(Exception e) {
            LOG.error("programProviderNetworkFlow:Error while writing a flows. Caused due to, " + e.getMessage());
        }
    }

    private Long getPatchPort(final Long dpId, final String portName) {
        final Long dpidPrimitive = dpId;
        for (Node node : nodeCacheManager.getBridgeNodes()) {
            if (dpidPrimitive == southbound.getDataPathId(node)) {
                final OvsdbTerminationPointAugmentation terminationPointOfBridge =
                        southbound.getTerminationPointOfBridge(node, portName);
                return (terminationPointOfBridge == null) ? null : terminationPointOfBridge.getOfport();
            }
        }
        return null;
    }

    @Override
    public void setDependencies(final ServiceReference serviceReference) {
        vlanResponderProvider =
                (VlanResponderProvider) ServiceHelper.getGlobalInstance(VlanResponderProvider.class, this);
        configurationService =
                (ConfigurationService) ServiceHelper.getGlobalInstance(ConfigurationService.class, this);
        southbound =
                (Southbound) ServiceHelper.getGlobalInstance(Southbound.class, this);
        nodeCacheManager =
                (NodeCacheManager) ServiceHelper.getGlobalInstance(NodeCacheManager.class, this);
    }

    @Override
    public void setDependencies(final Object impl) {
        if (impl instanceof VlanResponderProvider) {
            vlanResponderProvider = (VlanResponderProvider)impl;
        }
    }

    private Long getDpidForIntegrationBridge(Node node, final String portName) {
        if (southbound.getBridgeName(node).equals(configurationService.getIntegrationBridgeName())) {
            TerminationPoint tp = southbound.readTerminationPoint(node, null, portName);
            if (tp != null) {
                final long dpid = southbound.getDataPathId(node);
                return dpid;
            }
        }
        return null;
    }

    private Long getDpidForExternalBridge() {
        List<Long> dpids =  nodeCacheManager.getBridgeDpids(configurationService.getExternalBridgeName());
        return dpids.get(0);
    }
}

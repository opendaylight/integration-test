/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.neutronvpn;

import com.google.common.base.Optional;
import java.util.ArrayList;
import java.util.List;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.networkmaps.NetworkMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.networkmaps.NetworkMapBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.networkmaps.NetworkMapKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.networks.attributes.networks.Network;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnets.attributes.Subnets;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnets.attributes.subnets.Subnet;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class NeutronSubnetChangeListener extends AsyncDataTreeChangeListenerBase<Subnet, NeutronSubnetChangeListener>
        implements AutoCloseable {
    private static final Logger LOG = LoggerFactory.getLogger(NeutronSubnetChangeListener.class);
    private final DataBroker dataBroker;
    private final NeutronvpnManager nvpnManager;

    public NeutronSubnetChangeListener(final DataBroker dataBroker, final NeutronvpnManager nVpnMgr) {
        super(Subnet.class, NeutronSubnetChangeListener.class);
        this.dataBroker = dataBroker;
        nvpnManager = nVpnMgr;
    }

    public void start() {
        LOG.info("{} start", getClass().getSimpleName());
        registerListener(LogicalDatastoreType.CONFIGURATION, dataBroker);
    }

    @Override
    protected InstanceIdentifier<Subnet> getWildCardPath() {
        return InstanceIdentifier.create(Neutron.class).child(Subnets.class).child(Subnet.class);
    }

    @Override
    protected NeutronSubnetChangeListener getDataTreeChangeListener() {
        return NeutronSubnetChangeListener.this;
    }


    @Override
    protected void add(InstanceIdentifier<Subnet> identifier, Subnet input) {
        LOG.trace("Adding Subnet : key: {}, value={}", identifier, input);
        Uuid networkId = input.getNetworkId();
        Network network = NeutronvpnUtils.getNeutronNetwork(dataBroker, networkId);
        if (network == null || !NeutronvpnUtils.isNetworkTypeSupported(network)) {
            //FIXME: This should be removed when support for VLAN and GRE network types is added
            LOG.error("neutron vpn doesn't support vlan/gre network provider type for the port {} which is part of network {}."
                    + " Skipping the processing of Subnet add DCN", input.getName(), network);
            return;
        }
        handleNeutronSubnetCreated(input.getUuid(), String.valueOf(input.getCidr().getValue()), networkId,
                input.getTenantId());
        NeutronvpnUtils.addToSubnetCache(input);
    }

    @Override
    protected void remove(InstanceIdentifier<Subnet> identifier, Subnet input) {
        LOG.trace("Removing subnet : key: {}, value={}", identifier, input);
        Uuid networkId = input.getNetworkId();
        Network network = NeutronvpnUtils.getNeutronNetwork(dataBroker, networkId);
        if (network == null || !NeutronvpnUtils.isNetworkTypeSupported(network)) {
            //FIXME: This should be removed when support for GRE network types is added
            LOG.error("neutron vpn doesn't support gre network provider type for the port {} which is part of network {}."
                    + " Skipping the processing of Subnet remove DCN", input.getName(), network);
            return;
        }
        handleNeutronSubnetDeleted(input.getUuid(), networkId, null);
        NeutronvpnUtils.removeFromSubnetCache(input);
    }

    @Override
    protected void update(InstanceIdentifier<Subnet> identifier, Subnet original, Subnet update) {
        LOG.trace("Updating Subnet : key: {}, original value={}, update value={}", identifier, original, update);
        Uuid networkId = update.getNetworkId();
        Network network = NeutronvpnUtils.getNeutronNetwork(dataBroker, networkId);
        if (network == null || !NeutronvpnUtils.isNetworkTypeSupported(network)) {
            LOG.error("neutron vpn doesn't support vlan/gre network provider type for the port {} which is part of network {}."
                    + " Skipping the processing of Subnet update DCN", update.getName(), network);
            return;
        }
        handleNeutronSubnetUpdated(update.getUuid(), networkId, update.getTenantId());
        NeutronvpnUtils.addToSubnetCache(update);
    }

    private void handleNeutronSubnetCreated(Uuid subnetId, String subnetIp, Uuid networkId, Uuid tenantId) {
        nvpnManager.updateSubnetNode(subnetId, subnetIp, tenantId, networkId, null/*routerID*/, null/*vpnID*/);
        if (networkId != null) {
            createSubnetToNetworkMapping(subnetId, networkId);
        }
    }

    private void handleNeutronSubnetDeleted(Uuid subnetId, Uuid networkId, Uuid tenantId) {
        Uuid vpnId = NeutronvpnUtils.getVpnForNetwork(dataBroker, networkId);
        if (vpnId != null) {
            nvpnManager.removeSubnetFromVpn(vpnId, subnetId);
        }
        if (networkId != null)  {
            deleteSubnetToNetworkMapping(subnetId, networkId);
        }
        nvpnManager.deleteSubnetMapNode(subnetId);
    }

    private void handleNeutronSubnetUpdated(Uuid subnetId, Uuid networkId, Uuid tenantId) {
        Uuid oldNetworkId = NeutronvpnUtils.getSubnetmap(dataBroker, subnetId).getNetworkId();
        if (oldNetworkId != null && !oldNetworkId.equals(networkId)) {
            deleteSubnetToNetworkMapping(subnetId, oldNetworkId);
        }
        if (networkId != null && !networkId.equals(oldNetworkId)) {
            createSubnetToNetworkMapping(subnetId, networkId);
        }
        nvpnManager.updateSubnetNode(subnetId, null, tenantId, networkId, null/*routerID*/, null/*vpnID*/);
    }

    private void createSubnetToNetworkMapping(Uuid subnetId, Uuid networkId) {
        try {
            InstanceIdentifier networkMapIdentifier = NeutronvpnUtils.buildNetworkMapIdentifier(networkId);
            Optional<NetworkMap> optionalNetworkMap = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType.CONFIGURATION,
                    networkMapIdentifier);
            NetworkMapBuilder nwMapBuilder = null;
            if (optionalNetworkMap.isPresent()) {
                nwMapBuilder = new NetworkMapBuilder(optionalNetworkMap.get());
            } else {
                nwMapBuilder = new NetworkMapBuilder().setKey(new NetworkMapKey(networkId)).setNetworkId(networkId);
                LOG.debug("Adding a new network node in NetworkMaps DS for network {}", networkId.getValue());
            }
            List<Uuid> subnetIdList = nwMapBuilder.getSubnetIdList();
            if (subnetIdList == null) {
                subnetIdList = new ArrayList<>();
            }
            subnetIdList.add(subnetId);
            nwMapBuilder.setSubnetIdList(subnetIdList);
            MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, networkMapIdentifier, nwMapBuilder.build());
            LOG.debug("Created subnet-network mapping for subnet {} network {}", subnetId.getValue(),
                    networkId.getValue());
        } catch (Exception e) {
            LOG.error("Create subnet-network mapping failed for subnet {} network {}", subnetId.getValue(),
                    networkId.getValue());
        }
    }

    private void deleteSubnetToNetworkMapping(Uuid subnetId, Uuid networkId) {
        try {
            InstanceIdentifier networkMapIdentifier = NeutronvpnUtils.buildNetworkMapIdentifier(networkId);
            Optional<NetworkMap> optionalNetworkMap = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType.CONFIGURATION,
                    networkMapIdentifier);
            if (optionalNetworkMap.isPresent()) {
                NetworkMapBuilder nwMapBuilder = new NetworkMapBuilder(optionalNetworkMap.get());
                List<Uuid> subnetIdList = nwMapBuilder.getSubnetIdList();
                if (subnetIdList.remove(subnetId)) {
                    if (subnetIdList.size() == 0) {
                        MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION, networkMapIdentifier);
                        LOG.debug("Deleted network node in NetworkMaps DS for network {}", subnetId.getValue(),
                                networkId.getValue());
                    } else {
                        nwMapBuilder.setSubnetIdList(subnetIdList);
                        MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, networkMapIdentifier,
                                nwMapBuilder.build());
                        LOG.debug("Deleted subnet-network mapping for subnet {} network {}", subnetId.getValue(),
                                networkId.getValue());
                    }
                } else {
                    LOG.error("Subnet {} is not mapped to network {}", subnetId.getValue(), networkId.getValue());
                }
            } else {
                LOG.error("network {} not present for subnet {} ", networkId, subnetId);
            }
        } catch (Exception e) {
            LOG.error("Delete subnet-network mapping failed for subnet {} network {}", subnetId.getValue(),
                    networkId.getValue());
        }
    }
}


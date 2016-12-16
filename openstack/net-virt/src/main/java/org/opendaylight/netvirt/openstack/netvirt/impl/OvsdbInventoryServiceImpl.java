/*
 * Copyright © 2015, 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.openstack.netvirt.impl;

import com.google.common.collect.Sets;

import java.util.Set;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.sal.binding.api.BindingAwareBroker.ProviderContext;
import org.opendaylight.netvirt.openstack.netvirt.translator.iaware.impl.NeutronFloatingIPDataTreeChangeListener;
import org.opendaylight.netvirt.openstack.netvirt.translator.iaware.impl.NeutronRouterChangeListener;
import org.opendaylight.netvirt.openstack.netvirt.translator.iaware.impl.NeutronSecurityRuleDataChangeListener;
import org.opendaylight.netvirt.openstack.netvirt.ClusterAwareMdsalUtils;
import org.opendaylight.netvirt.openstack.netvirt.ConfigInterface;
import org.opendaylight.netvirt.openstack.netvirt.NetvirtProvider;
import org.opendaylight.netvirt.openstack.netvirt.api.Constants;
import org.opendaylight.netvirt.openstack.netvirt.api.OvsdbInventoryService;
import org.opendaylight.netvirt.openstack.netvirt.api.OvsdbInventoryListener;
import org.opendaylight.netvirt.openstack.netvirt.translator.iaware.impl.NeutronNetworkChangeListener;
import org.opendaylight.netvirt.openstack.netvirt.translator.iaware.impl.NeutronPortChangeListener;
import org.opendaylight.netvirt.openstack.netvirt.translator.iaware.impl.NeutronSubnetChangeListener;
import org.opendaylight.netvirt.openstack.netvirt.translator.iaware.impl.NeutronLoadBalancerPoolChangeListener;
import org.opendaylight.netvirt.openstack.netvirt.translator.iaware.impl.NeutronLoadBalancerPoolMemberChangeListener;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Uri;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NetworkTopology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.TopologyId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.TopologyBuilder;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.TopologyKey;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.osgi.framework.ServiceReference;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * OvsdbInventoryServiceImpl is the implementation for {@link OvsdbInventoryService}
 *
 * @author Sam Hague (shague@redhat.com)
 */
public class OvsdbInventoryServiceImpl implements ConfigInterface, OvsdbInventoryService {
    private static final Logger LOG = LoggerFactory.getLogger(OvsdbInventoryServiceImpl.class);
    private final DataBroker dataBroker;
    private static Set<OvsdbInventoryListener> ovsdbInventoryListeners = Sets.newCopyOnWriteArraySet();
    private OvsdbDataChangeListener ovsdbDataChangeListener = null;
    private static ClusterAwareMdsalUtils mdsalUtils = null;

    public OvsdbInventoryServiceImpl(final DataBroker dataBroker) {
        this.dataBroker = dataBroker;
        LOG.info("OvsdbInventoryServiceImpl initialized");
        ovsdbDataChangeListener = new OvsdbDataChangeListener(dataBroker);
        mdsalUtils = new ClusterAwareMdsalUtils(dataBroker);
    }

    @Override
    public void listenerAdded(OvsdbInventoryListener listener) {
        ovsdbInventoryListeners.add(listener);
        LOG.info("listenerAdded: {}", listener);
    }

    @Override
    public void listenerRemoved(OvsdbInventoryListener listener) {
        ovsdbInventoryListeners.remove(listener);
        LOG.info("listenerRemoved: {}", listener);
    }

    @Override
    public void providersReady() {
        ovsdbDataChangeListener.start();
        initializeNeutronModelsDataChangeListeners(dataBroker);
        initializeNetvirtTopology();
    }

    public static Set<OvsdbInventoryListener> getOvsdbInventoryListeners() {
        return ovsdbInventoryListeners;
    }

    @Override
    public void setDependencies(ServiceReference serviceReference) {}

    @Override
    public void setDependencies(Object impl) {}

    private void initializeNetvirtTopology() {
        while(!NetvirtProvider.isMasterElected()){
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                LOG.warn("Netvirt thread waiting on Netvirt Ownership Election is interrupted");
            }
        }
        final TopologyId topologyId = new TopologyId(new Uri(Constants.NETVIRT_TOPOLOGY_ID));
        InstanceIdentifier<Topology> path =
                InstanceIdentifier.create(NetworkTopology.class).child(Topology.class, new TopologyKey(topologyId));
        TopologyBuilder tpb = new TopologyBuilder();
        tpb.setTopologyId(topologyId);
        if (! mdsalUtils.put(LogicalDatastoreType.OPERATIONAL, path, tpb.build())) {
            LOG.error("Error initializing netvirt topology");
        }
    }

    private void initializeNeutronModelsDataChangeListeners(
            DataBroker db) {
        new NeutronNetworkChangeListener(db);
        new NeutronSubnetChangeListener(db);
        new NeutronPortChangeListener(db);
        new NeutronRouterChangeListener(db);
        new NeutronFloatingIPDataTreeChangeListener(db).init();
        new NeutronLoadBalancerPoolChangeListener(db);
        new NeutronLoadBalancerPoolMemberChangeListener(db);
        new NeutronSecurityRuleDataChangeListener(db);
    }

}

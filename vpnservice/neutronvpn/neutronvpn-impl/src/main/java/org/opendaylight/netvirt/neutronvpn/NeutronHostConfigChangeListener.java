/*
 * Copyright (c) 2016 Intel Corporation.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.neutronvpn;

import com.google.common.collect.Maps;
import java.util.Map;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.ovsdb.utils.mdsal.utils.MdsalUtils;
import org.opendaylight.ovsdb.utils.southbound.utils.SouthboundUtils;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.hostconfig.rev150712.hostconfig.attributes.Hostconfigs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.hostconfig.rev150712.hostconfig.attributes.hostconfigs.Hostconfig;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.hostconfig.rev150712.hostconfig.attributes.hostconfigs.HostconfigBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbNodeAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.ovsdb.node.attributes.OpenvswitchExternalIds;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NetworkTopology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.TopologyKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class NeutronHostConfigChangeListener extends AsyncDataTreeChangeListenerBase<Node,
        NeutronHostConfigChangeListener> implements AutoCloseable {
    private static final Logger LOG = LoggerFactory.getLogger(NeutronHostConfigChangeListener.class);
    private final DataBroker dataBroker;
    private final SouthboundUtils southboundUtils;
    private final MdsalUtils mdsalUtils;
    private static final String OS_HOST_CONFIG_HOST_ID_KEY = "odl_os_hostconfig_hostid";
    private static final String OS_HOST_CONFIG_CONFIG_KEY_PREFIX = "odl_os_hostconfig_config_odl_";
    private static int HOST_TYPE_STR_LEN = 8;

    private enum Action {
        ADD,
        UPDATE,
        DELETE
    }

    public NeutronHostConfigChangeListener(final DataBroker dataBroker){
        super(Node.class,NeutronHostConfigChangeListener.class);
        this.dataBroker = dataBroker;
        this.mdsalUtils = new MdsalUtils(dataBroker);
        this.southboundUtils = new SouthboundUtils(mdsalUtils);
    }

    public void start() {
        LOG.info("{} start", getClass().getSimpleName());
        registerListener(LogicalDatastoreType.OPERATIONAL, dataBroker);
    }

    @Override
    protected InstanceIdentifier<Node> getWildCardPath(){
        return InstanceIdentifier
                .create(NetworkTopology.class)
                .child(Topology.class,new TopologyKey(SouthboundUtils.OVSDB_TOPOLOGY_ID))
                .child(Node.class);
    }

    @Override
    protected NeutronHostConfigChangeListener getDataTreeChangeListener() {
        return NeutronHostConfigChangeListener.this;
    }


    @Override
    protected void remove(InstanceIdentifier<Node>identifier, Node del){
        updateHostConfig(del, Action.DELETE);
    }

    @Override
    protected void update(InstanceIdentifier<Node>identifier, Node original, Node update){
        updateHostConfig(update, Action.UPDATE);
    }

    @Override
    protected void add(InstanceIdentifier<Node>identifier, Node add){
        updateHostConfig(add, Action.ADD);

    }

    private void updateHostConfig(Node node, Action action) {
        String hostId = getExternalId(node, OS_HOST_CONFIG_HOST_ID_KEY);
        if (hostId == null){
            return;
        }
        for(Map.Entry<String,String> entry : extractHostConfig(node).entrySet()) {
            updateMdsal(buildHostConfigInfo(hostId, entry.getKey(), entry.getValue()), action);
        }
    }

    private Map<String, String> extractHostConfig(Node node) {
        Map<String, String> config = Maps.newHashMap();
        OvsdbNodeAugmentation ovsdbNode = getOvsdbNodeAugmentation(node);
        if (ovsdbNode != null && ovsdbNode.getOpenvswitchExternalIds() != null) {
            for (OpenvswitchExternalIds openvswitchExternalIds : ovsdbNode.getOpenvswitchExternalIds()) {
                if (openvswitchExternalIds.getExternalIdKey().startsWith(OS_HOST_CONFIG_CONFIG_KEY_PREFIX)) {
                    // Extract the host type. Max 8 characters after
                    // suffix OS_HOST_CONFIG_CONFIG_KEY_PREFIX.length()
                    String hostType = openvswitchExternalIds.getExternalIdKey().substring(
                            OS_HOST_CONFIG_CONFIG_KEY_PREFIX.length());
                    if (null != hostType && hostType.length() > 0) {
                        if (hostType.length() > HOST_TYPE_STR_LEN) {
                            hostType = hostType.substring(0, HOST_TYPE_STR_LEN);
                        }
                        hostType = "ODL " + hostType.toUpperCase();
                        if (null != openvswitchExternalIds.getExternalIdValue())
                            config.put(hostType, openvswitchExternalIds.getExternalIdValue());
                    }
                }
            }
        }
        return config;
    }

    private void updateMdsal(Hostconfig hostConfig, Action action) {
        boolean result;
        InstanceIdentifier<Hostconfig> hostConfigId;
        if (hostConfig == null) {
            return;
        }
        switch (action) {
            case ADD:
            case UPDATE:
                hostConfigId = createInstanceIdentifier(hostConfig);
                result = mdsalUtils.put(LogicalDatastoreType.OPERATIONAL, hostConfigId, hostConfig);
                LOG.trace("Add Node: result: {}", result);
                break;
            case DELETE:
                hostConfigId = createInstanceIdentifier(hostConfig);
                result = mdsalUtils.delete(LogicalDatastoreType.OPERATIONAL, hostConfigId);
                LOG.trace("Delete Node: result: {}", result);
                break;
        }
    }

    private Hostconfig buildHostConfigInfo(String hostId, String hostType, String hostConfig) {
        HostconfigBuilder hostconfigBuilder = new HostconfigBuilder();
        hostconfigBuilder.setHostId(hostId);
        hostconfigBuilder.setHostType(hostType);
        hostconfigBuilder.setConfig(hostConfig);
        return hostconfigBuilder.build();
    }

    private String getExternalId(Node node, String key) {
        OvsdbNodeAugmentation ovsdbNode = getOvsdbNodeAugmentation(node);
        if (ovsdbNode != null && ovsdbNode.getOpenvswitchExternalIds() != null) {
            for (OpenvswitchExternalIds openvswitchExternalIds : ovsdbNode.getOpenvswitchExternalIds()) {
                if (openvswitchExternalIds.getExternalIdKey().equals(key)) {
                    return openvswitchExternalIds.getExternalIdValue();
                }
            }
        }
        return null;
    }

    private OvsdbNodeAugmentation getOvsdbNodeAugmentation(Node node)
    {
        OvsdbNodeAugmentation ovsdbNode = southboundUtils.extractOvsdbNode(node);
        if (ovsdbNode == null) {
            Node nodeFromReadOvsdbNode = southboundUtils.readOvsdbNode(node);
            if (nodeFromReadOvsdbNode != null) {
                ovsdbNode = southboundUtils.extractOvsdbNode(nodeFromReadOvsdbNode);
            }
        }
        return ovsdbNode;
    }

    private InstanceIdentifier<Hostconfig> createInstanceIdentifier() {
        return InstanceIdentifier.create(Neutron.class)
                .child(Hostconfigs.class)
                .child(Hostconfig.class);
    }

    private InstanceIdentifier<Hostconfig> createInstanceIdentifier(Hostconfig hostconfig) {
        return InstanceIdentifier.create(Neutron.class)
                .child(Hostconfigs.class)
                .child(Hostconfig.class, hostconfig.getKey());
    }
}

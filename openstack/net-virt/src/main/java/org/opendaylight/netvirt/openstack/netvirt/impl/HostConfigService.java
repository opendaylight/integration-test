/*
 * Copyright (c) 2016 Intel Corporation.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.openstack.netvirt.impl;

import com.google.common.collect.Maps;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.netvirt.openstack.netvirt.ClusterAwareMdsalUtils;
import org.opendaylight.netvirt.openstack.netvirt.ConfigInterface;
import org.opendaylight.netvirt.openstack.netvirt.api.Action;
import org.opendaylight.netvirt.openstack.netvirt.api.OvsdbInventoryListener;
import org.opendaylight.netvirt.openstack.netvirt.api.OvsdbInventoryService;
import org.opendaylight.netvirt.openstack.netvirt.api.Southbound;
import org.opendaylight.netvirt.openstack.netvirt.api.OvsdbTables;
import org.opendaylight.netvirt.utils.servicehelper.ServiceHelper;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.hostconfig.rev150712.hostconfig.attributes.Hostconfigs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.hostconfig.rev150712.hostconfig.attributes.hostconfigs.Hostconfig;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbNodeAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.ovsdb.node.attributes.OpenvswitchExternalIds;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.hostconfig.rev150712.hostconfig.attributes.hostconfigs.HostconfigBuilder;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.osgi.framework.ServiceReference;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.Map;


public class HostConfigService implements OvsdbInventoryListener, ConfigInterface {
    private static final Logger LOG = LoggerFactory.getLogger(HostConfigService.class);

    private static final String OS_HOST_CONFIG_HOST_ID_KEY = "odl_os_hostconfig_hostid";
    private static final String OS_HOST_CONFIG_CONFIG_KEY_PREFIX = "odl_os_hostconfig_config_odl_";
    private static int HOST_TYPE_STR_LEN = 8;

    private final DataBroker databroker;
    private final ClusterAwareMdsalUtils mdsalUtils;
    private volatile OvsdbInventoryService ovsdbInventoryService;
    private volatile Southbound southbound;

    public HostConfigService(DataBroker dataBroker) {
        this.databroker = dataBroker;
        mdsalUtils = new ClusterAwareMdsalUtils(dataBroker);
    }

    @Override
    public void ovsdbUpdate(Node node, DataObject resourceAugmentationData, OvsdbType ovsdbType, Action action) {
        if (ovsdbType != OvsdbType.NODE) {
            return;
        }
        LOG.trace("ovsdbUpdate: {} - {} - <<{}>> <<{}>>", ovsdbType, action, node, resourceAugmentationData);
        String hostId = southbound.getExternalId(node, OvsdbTables.OPENVSWITCH, OS_HOST_CONFIG_HOST_ID_KEY);
        if (hostId == null){
            return;
        }
        for(Map.Entry<String,String> entry : extractHostConfig(node).entrySet()) {
            ovsdbUpdateConfig(buildHostConfigInfo(hostId, entry.getKey(), entry.getValue()), action);
        }
    }

    @Override
    public void triggerUpdates() {
        List<Node> ovsdbNodes = southbound.readOvsdbTopologyNodes();
        for (Node node : ovsdbNodes) {
            ovsdbUpdate(node, node.getAugmentation(OvsdbNodeAugmentation.class),
                    OvsdbInventoryListener.OvsdbType.NODE, Action.ADD);
        }
    }

    private Map<String, String> extractHostConfig(Node node) {
        OvsdbNodeAugmentation ovsdbNode = southbound.extractNodeAugmentation(node);
        Map<String, String> config = Maps.newHashMap();
        if (ovsdbNode == null) {
            Node nodeFromReadOvsdbNode = southbound.readOvsdbNode(node);
            if (nodeFromReadOvsdbNode != null) {
                ovsdbNode = southbound.extractNodeAugmentation(nodeFromReadOvsdbNode);
            }
        }
        if (ovsdbNode != null && ovsdbNode.getOpenvswitchExternalIds() != null) {
            for (OpenvswitchExternalIds openvswitchExternalIds : ovsdbNode.getOpenvswitchExternalIds()) {
                if (openvswitchExternalIds.getExternalIdKey().startsWith(OS_HOST_CONFIG_CONFIG_KEY_PREFIX)) {
                    // Extract the host type. Max 8 characters after suffix OS_HOST_CONFIG_CONFIG_KEY_PREFIX.length()
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

    private void ovsdbUpdateConfig(Hostconfig hostConfig, Action action) {
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

    @Override
    public void setDependencies(ServiceReference serviceReference) {
        southbound =
                (Southbound) ServiceHelper.getGlobalInstance(Southbound.class, this);
        ovsdbInventoryService =
                (OvsdbInventoryService) ServiceHelper.getGlobalInstance(OvsdbInventoryService.class, this);
        ovsdbInventoryService.listenerAdded(this);
    }

    @Override
    public void setDependencies(Object impl) {
    }
}

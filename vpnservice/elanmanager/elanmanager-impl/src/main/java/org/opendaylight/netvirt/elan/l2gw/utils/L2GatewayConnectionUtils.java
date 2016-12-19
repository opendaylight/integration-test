/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.elan.l2gw.utils;

import com.google.common.base.Optional;
import com.google.common.collect.Lists;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.clustering.EntityOwnershipService;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.utils.hwvtep.HwvtepUtils;
import org.opendaylight.netvirt.elan.internal.ElanInstanceManager;
import org.opendaylight.netvirt.elan.l2gw.jobs.AssociateHwvtepToElanJob;
import org.opendaylight.netvirt.elan.l2gw.jobs.DisAssociateHwvtepFromElanJob;
import org.opendaylight.netvirt.elan.l2gw.listeners.HwvtepLogicalSwitchListener;
import org.opendaylight.netvirt.elan.utils.ElanClusterUtils;
import org.opendaylight.netvirt.elan.utils.ElanUtils;
import org.opendaylight.netvirt.elanmanager.utils.ElanL2GwCacheUtils;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.L2GatewayDevice;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.utils.L2GatewayCacheUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l2gateways.rev150712.l2gateway.attributes.Devices;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l2gateways.rev150712.l2gateway.connections.attributes.L2gatewayConnections;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l2gateways.rev150712.l2gateway.connections.attributes.l2gatewayconnections.L2gatewayConnection;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l2gateways.rev150712.l2gateways.attributes.L2gateways;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l2gateways.rev150712.l2gateways.attributes.l2gateways.L2gateway;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l2gateways.rev150712.l2gateways.attributes.l2gateways.L2gatewayKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LogicalSwitches;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NodeId;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class L2GatewayConnectionUtils {
    private static final Logger LOG = LoggerFactory.getLogger(L2GatewayConnectionUtils.class);

    private final DataBroker broker;
    private final ElanInstanceManager elanInstanceManager;
    private final ElanL2GatewayUtils elanL2GatewayUtils;
    private final EntityOwnershipService entityOwnershipService;
    private final ElanUtils elanUtils;
    private final ElanL2GatewayMulticastUtils elanL2GatewayMulticastUtils;

    public L2GatewayConnectionUtils(DataBroker dataBroker, ElanInstanceManager elanInstanceManager,
                                    EntityOwnershipService entityOwnershipService, ElanUtils elanUtils) {
        this.broker = dataBroker;
        this.elanInstanceManager = elanInstanceManager;
        this.elanL2GatewayUtils = elanUtils.getElanL2GatewayUtils();
        this.entityOwnershipService = entityOwnershipService;
        this.elanUtils = elanUtils;
        this.elanL2GatewayMulticastUtils = elanUtils.getElanL2GatewayMulticastUtils();
    }

    public static boolean isGatewayAssociatedToL2Device(L2GatewayDevice l2GwDevice) {
        return l2GwDevice.getL2GatewayIds().size() > 0;
    }

    public static L2gateway getNeutronL2gateway(DataBroker broker, Uuid l2GatewayId) {
        LOG.debug("getNeutronL2gateway for {}", l2GatewayId.getValue());
        InstanceIdentifier<L2gateway> inst = InstanceIdentifier.create(Neutron.class).child(L2gateways.class)
                .child(L2gateway.class, new L2gatewayKey(l2GatewayId));
        Optional<L2gateway> l2Gateway = MDSALUtil.read(broker, LogicalDatastoreType.CONFIGURATION, inst);
        if (l2Gateway.isPresent()) {
            return l2Gateway.get();
        }
        return null;
    }

    public static List<L2gateway> getL2gatewayList(DataBroker broker) {
        InstanceIdentifier<L2gateways> inst = InstanceIdentifier.create(Neutron.class).child(L2gateways.class);
        Optional<L2gateways> l2gateways = MDSALUtil.read(broker, LogicalDatastoreType.CONFIGURATION, inst);

        if (l2gateways.isPresent()) {
            return l2gateways.get().getL2gateway();
        }
        return null;
    }

    public static List<L2gatewayConnection> getAllL2gatewayConnections(DataBroker broker) {
        InstanceIdentifier<L2gatewayConnections> inst = InstanceIdentifier.create(Neutron.class)
                .child(L2gatewayConnections.class);
        Optional<L2gatewayConnections> l2GwConns = MDSALUtil.read(broker, LogicalDatastoreType.CONFIGURATION, inst);
        if (l2GwConns.isPresent()) {
            return l2GwConns.get().getL2gatewayConnection();
        }
        return null;
    }

    /**
     * Gets the associated l2 gw connections.
     *
     * @param broker
     *            the broker
     * @param l2GatewayIds
     *            the l2 gateway ids
     * @return the associated l2 gw connections
     */
    public static List<L2gatewayConnection> getAssociatedL2GwConnections(DataBroker broker, Set<Uuid> l2GatewayIds) {
        List<L2gatewayConnection> l2GwConnections = null;
        List<L2gatewayConnection> allL2GwConns = getAllL2gatewayConnections(broker);
        if (allL2GwConns != null) {
            l2GwConnections = new ArrayList<>();
            for (Uuid l2GatewayId : l2GatewayIds) {
                for (L2gatewayConnection l2GwConn : allL2GwConns) {
                    if (l2GwConn.getL2gatewayId().equals(l2GatewayId)) {
                        l2GwConnections.add(l2GwConn);
                    }
                }
            }
        }
        return l2GwConnections;
    }

    /**
     * Gets the associated l2 gw connections.
     *
     * @param broker
     *            the broker
     * @param elanName
     *            the elan Name
     * @return the associated l2 gw connection with elan
     */
    public static List<L2gatewayConnection> getL2GwConnectionsByElanName(DataBroker broker, String elanName) {
        List<L2gatewayConnection> allL2GwConns = getAllL2gatewayConnections(broker);
        List<L2gatewayConnection> elanL2GateWayConnections = Lists.newArrayList();
        if (allL2GwConns != null) {
            for (L2gatewayConnection l2GwConn : allL2GwConns) {
                if (l2GwConn.getNetworkId().getValue().equalsIgnoreCase(elanName)) {
                    elanL2GateWayConnections.add(l2GwConn);
                }
            }
        }
        return elanL2GateWayConnections;
    }

    public void addL2GatewayConnection(L2gatewayConnection input) {
        addL2GatewayConnection(input, null/*deviceName*/);
    }

    public void addL2GatewayConnection(L2gatewayConnection input, String l2GwDeviceName) {
        LOG.info("Adding L2gateway Connection with ID: {}", input.getKey().getUuid());

        Uuid networkUuid = input.getNetworkId();
        ElanInstance elanInstance = elanInstanceManager.getElanInstanceByName(networkUuid.getValue());
        if (elanInstance == null || !ElanUtils.isVxlan(elanInstance)) {
            LOG.error("Neutron network with id {} is not present", networkUuid.getValue());
        } else {
            Uuid l2GatewayId = input.getL2gatewayId();
            L2gateway l2Gateway = getNeutronL2gateway(broker, l2GatewayId);
            if (l2Gateway == null) {
                LOG.error("L2Gateway with id {} is not present", l2GatewayId.getValue());
            } else {
                associateHwvtepsToElan(elanInstance, l2Gateway, input, l2GwDeviceName);
            }
        }
    }

    public void deleteL2GatewayConnection(L2gatewayConnection input) {
        LOG.info("Deleting L2gateway Connection with ID: {}", input.getKey().getUuid());

        Uuid networkUuid = input.getNetworkId();
        String elanName = networkUuid.getValue();
        Uuid l2GatewayId = input.getL2gatewayId();
        disAssociateHwvtepsFromElan(elanName, input);
    }

    private void disAssociateHwvtepsFromElan(String elanName, L2gatewayConnection input) {
        Integer defaultVlan = input.getSegmentId();
        List<L2GatewayDevice> l2Devices = ElanL2GwCacheUtils.getAllElanDevicesFromCache();
        List<Devices> l2gwDevicesToBeDeleted = new ArrayList<>();
        for (L2GatewayDevice elanL2gwDevice : l2Devices) {
            if (elanL2gwDevice.getL2GatewayIds().contains(input.getKey().getUuid())) {
                l2gwDevicesToBeDeleted.addAll(elanL2gwDevice.getL2gwConnectionIdToDevices()
                        .get(input.getKey().getUuid()));
            }
        }
        for (Devices l2Device : l2gwDevicesToBeDeleted) {
            String l2DeviceName = l2Device.getDeviceName();
            L2GatewayDevice l2GatewayDevice = L2GatewayCacheUtils.getL2DeviceFromCache(l2DeviceName);
            String hwvtepNodeId = l2GatewayDevice.getHwvtepNodeId();
            boolean isLastL2GwConnDeleted = false;
            L2GatewayDevice elanL2GwDevice = ElanL2GwCacheUtils.getL2GatewayDeviceFromCache(elanName, hwvtepNodeId);
            if (isLastL2GwConnBeingDeleted(elanL2GwDevice)) {
                // Delete L2 Gateway device from 'ElanL2GwDevice' cache
                LOG.debug("Elan L2Gw Conn cache removed for id {}", hwvtepNodeId);
                ElanL2GwCacheUtils.removeL2GatewayDeviceFromCache(elanName, hwvtepNodeId);
                isLastL2GwConnDeleted = true;
            } else {
                Uuid l2GwConnId = input.getKey().getUuid();
                LOG.debug("Elan L2Gw Conn cache with id {} is being referred by other L2Gw Conns; so only "
                        + "L2 Gw Conn {} reference is removed", hwvtepNodeId, l2GwConnId);
                elanL2GwDevice.removeL2GatewayId(l2GwConnId);
            }

            DisAssociateHwvtepFromElanJob disAssociateHwvtepToElanJob =
                    new DisAssociateHwvtepFromElanJob(broker, elanL2GatewayUtils, elanL2GatewayMulticastUtils,
                            elanL2GwDevice, elanName,
                            l2Device, defaultVlan, isLastL2GwConnDeleted);
            ElanClusterUtils.runOnlyInLeaderNode(entityOwnershipService, disAssociateHwvtepToElanJob.getJobKey(),
                    "remove l2gw connection job ", disAssociateHwvtepToElanJob);
        }
    }

    private void associateHwvtepsToElan(ElanInstance elanInstance,
            L2gateway l2Gateway, L2gatewayConnection input, String l2GwDeviceName) {
        String elanName = elanInstance.getElanInstanceName();
        Integer defaultVlan = input.getSegmentId();
        Uuid l2GwConnId = input.getKey().getUuid();
        List<Devices> l2Devices = l2Gateway.getDevices();

        LOG.trace("Associating ELAN {} with L2Gw Conn Id {} having below L2Gw devices {}", elanName, l2GwConnId,
                l2Devices);

        for (Devices l2Device : l2Devices) {
            String l2DeviceName = l2Device.getDeviceName();
            // L2gateway can have more than one L2 Gw devices. Configure Logical Switch, VLAN mappings,...
            // only on the switch which has come up just now and exclude all other devices from
            // preprovisioning/re-provisioning
            if (l2GwDeviceName != null && !l2GwDeviceName.equals(l2DeviceName)) {
                LOG.debug("Associating Hwvtep to ELAN is not been processed for {}; as only {} got connected now!",
                        l2DeviceName, l2GwDeviceName);
                continue;
            }
            L2GatewayDevice l2GatewayDevice = L2GatewayCacheUtils.getL2DeviceFromCache(l2DeviceName);
            if (isL2GwDeviceConnected(l2GatewayDevice)) {
                NodeId hwvtepNodeId = new NodeId(l2GatewayDevice.getHwvtepNodeId());

                // Delete pending delete logical switch task if scheduled
                elanL2GatewayUtils.cancelDeleteLogicalSwitch(hwvtepNodeId,
                        ElanL2GatewayUtils.getLogicalSwitchFromElan(elanName));

                // Add L2 Gateway device to 'ElanL2GwDevice' cache
                boolean createLogicalSwitch;
                LogicalSwitches logicalSwitch = HwvtepUtils.getLogicalSwitch(broker, LogicalDatastoreType.OPERATIONAL,
                        hwvtepNodeId, elanName);
                if (logicalSwitch == null) {
                    HwvtepLogicalSwitchListener hwVTEPLogicalSwitchListener = new HwvtepLogicalSwitchListener(broker,
                            elanL2GatewayUtils, entityOwnershipService, elanUtils, elanL2GatewayMulticastUtils,
                            l2GatewayDevice, elanName, l2Device, defaultVlan, l2GwConnId);
                    hwVTEPLogicalSwitchListener.registerListener(LogicalDatastoreType.OPERATIONAL, broker);
                    createLogicalSwitch = true;
                } else {
                    addL2DeviceToElanL2GwCache(elanName, l2GatewayDevice, l2GwConnId, l2Device);
                    createLogicalSwitch = false;
                }
                AssociateHwvtepToElanJob associateHwvtepToElanJob = new AssociateHwvtepToElanJob(broker,
                        elanL2GatewayUtils, elanUtils, elanL2GatewayMulticastUtils, l2GatewayDevice, elanInstance,
                        l2Device, defaultVlan, createLogicalSwitch);

                ElanClusterUtils.runOnlyInLeaderNode(entityOwnershipService, associateHwvtepToElanJob.getJobKey() ,
                        "create logical switch in hwvtep topo",
                        associateHwvtepToElanJob);

            } else {
                LOG.info("L2GwConn create is not handled for device with id {} as it's not connected", l2DeviceName);
            }
        }
    }

    public static L2GatewayDevice addL2DeviceToElanL2GwCache(String elanName, L2GatewayDevice l2GatewayDevice,
            Uuid l2GwConnId, Devices l2Device) {
        String l2gwDeviceNodeId = l2GatewayDevice.getHwvtepNodeId();
        L2GatewayDevice elanL2GwDevice = ElanL2GwCacheUtils.getL2GatewayDeviceFromCache(elanName, l2gwDeviceNodeId);
        if (elanL2GwDevice == null) {
            elanL2GwDevice = new L2GatewayDevice();
            elanL2GwDevice.setHwvtepNodeId(l2gwDeviceNodeId);
            elanL2GwDevice.setDeviceName(l2GatewayDevice.getDeviceName());
            elanL2GwDevice.setTunnelIps(l2GatewayDevice.getTunnelIps());
            ElanL2GwCacheUtils.addL2GatewayDeviceToCache(elanName, elanL2GwDevice);
            LOG.debug("Elan L2GwConn cache created for hwvtep id {}", l2gwDeviceNodeId);
        } else {
            LOG.debug("Elan L2GwConn cache already exists for hwvtep id {}; updating L2GwConn id {} to it",
                    l2gwDeviceNodeId, l2GwConnId);
        }
        elanL2GwDevice.addL2GatewayId(l2GwConnId);
        if (elanL2GwDevice.getL2gwConnectionIdToDevices().get(l2GwConnId) == null) {
            elanL2GwDevice.getL2gwConnectionIdToDevices().put(l2GwConnId, new ArrayList<Devices>());
        }
        elanL2GwDevice.getL2gwConnectionIdToDevices().get(l2GwConnId).add(l2Device);

        LOG.trace("Elan L2GwConn cache updated with below details: {}", elanL2GwDevice);
        return elanL2GwDevice;
    }

    private static boolean isL2GwDeviceConnected(L2GatewayDevice l2GwDevice) {
        return l2GwDevice != null && l2GwDevice.getHwvtepNodeId() != null && l2GwDevice.isConnected();
    }

    protected static boolean isLastL2GwConnBeingDeleted(L2GatewayDevice l2GwDevice) {
        return l2GwDevice.getL2GatewayIds().size() == 1;
    }
}

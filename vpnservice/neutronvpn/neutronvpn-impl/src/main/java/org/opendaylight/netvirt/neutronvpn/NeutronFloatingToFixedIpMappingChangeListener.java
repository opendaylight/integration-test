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
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.FloatingIpInfo;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.info.RouterPorts;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.info.RouterPortsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.info.RouterPortsKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.info.router.ports.Ports;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.info.router.ports.PortsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.info.router.ports.PortsKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.info.router.ports.ports.InternalToExternalPortMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.info.router.ports.ports.InternalToExternalPortMapBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.info.router.ports.ports.InternalToExternalPortMapKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.port.info.FloatingIpIdToPortMappingBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l3.rev150712.floatingips.attributes.Floatingips;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l3.rev150712.floatingips.attributes.floatingips.Floatingip;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static org.opendaylight.netvirt.neutronvpn.NeutronvpnUtils.buildfloatingIpIdToPortMappingIdentifier;

public class NeutronFloatingToFixedIpMappingChangeListener extends AsyncDataTreeChangeListenerBase<Floatingip,
        NeutronFloatingToFixedIpMappingChangeListener> implements AutoCloseable {
    private static final Logger LOG = LoggerFactory.getLogger(NeutronFloatingToFixedIpMappingChangeListener.class);
    private final DataBroker dataBroker;

    public NeutronFloatingToFixedIpMappingChangeListener(final DataBroker dataBroker) {
        super(Floatingip.class, NeutronFloatingToFixedIpMappingChangeListener.class);
        this.dataBroker = dataBroker;
    }

    public void start() {
        LOG.info("{} start", getClass().getSimpleName());
        registerListener(LogicalDatastoreType.CONFIGURATION, dataBroker);
    }

    @Override
    protected InstanceIdentifier<Floatingip> getWildCardPath() {
        return InstanceIdentifier.create(Neutron.class).child(Floatingips.class).child(Floatingip.class);
    }

    @Override
    protected NeutronFloatingToFixedIpMappingChangeListener getDataTreeChangeListener() {
        return NeutronFloatingToFixedIpMappingChangeListener.this;
    }

    @Override
    protected void add(InstanceIdentifier<Floatingip> identifier, Floatingip input) {
        LOG.trace("Neutron Floating IP created: key: {}, value={}", identifier, input);
        IpAddress fixedIp = input.getFixedIpAddress();
        String floatingIp = input.getFloatingIpAddress().getIpv4Address().getValue();
        if (fixedIp != null) {
            addToFloatingIpInfo(input.getRouterId().getValue(), input.getFloatingNetworkId(), input.getPortId()
                    .getValue(), fixedIp.getIpv4Address().getValue(), floatingIp, input.getUuid());
        }
    }

    @Override
    protected void remove(InstanceIdentifier<Floatingip> identifier, Floatingip input) {
        LOG.trace("Neutron Floating IP deleted : key: {}, value={}", identifier, input);
        IpAddress fixedIp = input.getFixedIpAddress();
        if (fixedIp != null) {
            // update FloatingIpPortInfo to set isFloatingIpDeleted as true to enable deletion of FloatingIpPortInfo
            // map once it is used for processing in the NAT removal path
            updateFloatingIpPortInfo(input.getUuid(), input.getPortId());
            clearFromFloatingIpInfo(input.getRouterId().getValue(), input.getPortId().getValue(), fixedIp
                    .getIpv4Address().getValue());
        } else {
            // delete FloatingIpPortInfo mapping since floating IP is deleted and no fixed IP is associated to it
            removeFromFloatingIpPortInfo(input.getUuid());
        }
    }

    // populate the floating to fixed ip map upon association/dissociation from fixed ip
    @Override
    protected void update(InstanceIdentifier<Floatingip> identifier, Floatingip original, Floatingip update) {
        LOG.trace("Handling FloatingIptoFixedIp mapping : key: {}, original value={}, update value={}", identifier,
                original, update);
        IpAddress oldFixedIp = original.getFixedIpAddress();
        IpAddress newFixedIp = update.getFixedIpAddress();
        String floatingIp = update.getFloatingIpAddress().getIpv4Address().getValue();

        if (oldFixedIp != null && !oldFixedIp.equals(newFixedIp)) {
            clearFromFloatingIpInfo(original.getRouterId().getValue(), original.getPortId().getValue(), oldFixedIp
                    .getIpv4Address().getValue());
        }
        if (newFixedIp != null && !newFixedIp.equals(oldFixedIp)) {
            addToFloatingIpInfo(update.getRouterId().getValue(), update.getFloatingNetworkId(), update.getPortId()
                    .getValue(), newFixedIp.getIpv4Address().getValue(), floatingIp, update.getUuid());
        }
    }

    private void addToFloatingIpInfo(String routerName, Uuid extNetworkId, String fixedNeutronPortName, String
            fixedIpAddress, String floatingIpAddress, Uuid floatingIpId) {
        RouterPortsBuilder routerPortsBuilder;
        boolean isLockAcquired = false;
        InstanceIdentifier<RouterPorts> routerPortsIdentifier = InstanceIdentifier.builder(FloatingIpInfo.class)
                .child(RouterPorts.class, new RouterPortsKey(routerName)).build();
        try {
            Optional<RouterPorts> optionalRouterPorts = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType
                    .CONFIGURATION, routerPortsIdentifier);
            if (optionalRouterPorts.isPresent()) {
                LOG.debug("Updating routerPorts node {} in floatingIpInfo DS for floating IP () on fixed " +
                        "neutron port {} : ", routerName, floatingIpAddress, fixedNeutronPortName);
                routerPortsBuilder = new RouterPortsBuilder(optionalRouterPorts.get());
            } else {
                LOG.debug("Creating new routerPorts node {} in floatingIpInfo DS for floating IP () on fixed " +
                        "neutron port {} : ", routerName, floatingIpAddress, fixedNeutronPortName);
                routerPortsBuilder = new RouterPortsBuilder().setKey(new RouterPortsKey(routerName)).setRouterId
                        (routerName);
            }
            if (extNetworkId != null) {
                routerPortsBuilder.setExternalNetworkId(extNetworkId);
            }
            if (fixedNeutronPortName != null) {
                List<Ports> portsList = routerPortsBuilder.getPorts();
                if (portsList == null) {
                    portsList = new ArrayList<>();
                }
                PortsBuilder fixedNeutronPortBuilder = null;
                for (Ports neutronPort : portsList) {
                    if (neutronPort.getPortName().equals(fixedNeutronPortName)) {
                        fixedNeutronPortBuilder = new PortsBuilder(neutronPort);
                        break;
                    }
                }
                if (fixedNeutronPortBuilder == null) {
                    fixedNeutronPortBuilder = new PortsBuilder().setKey(new PortsKey(fixedNeutronPortName))
                            .setPortName(fixedNeutronPortName);
                }
                if (fixedIpAddress != null) {
                    List<InternalToExternalPortMap> intExtPortMapList = fixedNeutronPortBuilder
                            .getInternalToExternalPortMap();
                    if (intExtPortMapList == null) {
                        intExtPortMapList = new ArrayList<>();
                    }
                    InternalToExternalPortMap intExtPortMap = new InternalToExternalPortMapBuilder().setKey(new
                            InternalToExternalPortMapKey(fixedIpAddress)).setInternalIp(fixedIpAddress)
                            .setExternalIp(floatingIpAddress).setExternalId(floatingIpId).setLabel(null).build();
                    intExtPortMapList.add(intExtPortMap);
                    fixedNeutronPortBuilder.setInternalToExternalPortMap(intExtPortMapList);
                }
                portsList.add(fixedNeutronPortBuilder.build());
                routerPortsBuilder.setPorts(portsList);
            }
            isLockAcquired = NeutronvpnUtils.lock(routerName);
            LOG.debug("Creating/Updating routerPorts node {} in floatingIpInfo DS for floating IP () on fixed " +
                    "neutron port {} : ", routerName, floatingIpAddress, fixedNeutronPortName);
            MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, routerPortsIdentifier, routerPortsBuilder
                    .build());
            LOG.debug("FloatingIpInfo DS updated for floating IP {} ", floatingIpAddress);
        } catch (Exception e) {
            LOG.error("addToFloatingIpInfo failed for floating IP: {} ", floatingIpAddress);
        } finally {
            if (isLockAcquired) {
                NeutronvpnUtils.unlock(routerName);
            }
        }
    }

    private void clearFromFloatingIpInfo(String routerName, String fixedNeutronPortName, String fixedIpAddress) {
        boolean isLockAcquired = false;
        InstanceIdentifier.InstanceIdentifierBuilder<RouterPorts> routerPortsIdentifierBuilder = InstanceIdentifier
                .builder(FloatingIpInfo.class).child(RouterPorts.class, new RouterPortsKey(routerName));
        try {
            Optional<RouterPorts> optionalRouterPorts = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType
                    .CONFIGURATION, routerPortsIdentifierBuilder.build());
            if (optionalRouterPorts.isPresent()) {
                RouterPorts routerPorts = optionalRouterPorts.get();
                List<Ports> portsList = routerPorts.getPorts();
                List<InternalToExternalPortMap> intExtPortMap = new ArrayList<>();
                for (Ports ports : portsList) {
                    if (ports.getPortName().equals(fixedNeutronPortName)) {
                        intExtPortMap = ports.getInternalToExternalPortMap();
                        break;
                    }
                }
                if (intExtPortMap.size() == 1) {
                    removeRouterPortsOrPortsNode(routerName, routerPortsIdentifierBuilder, portsList,
                            fixedNeutronPortName, isLockAcquired);
                } else {
                    InstanceIdentifier<InternalToExternalPortMap> intExtPortMapIdentifier =
                            routerPortsIdentifierBuilder.child(Ports
                            .class, new PortsKey(fixedNeutronPortName)).child(InternalToExternalPortMap.class, new
                            InternalToExternalPortMapKey(fixedIpAddress)).build();
                    try {
                        // remove particular internal-to-external-port-map
                        isLockAcquired = NeutronvpnUtils.lock(fixedIpAddress);
                        LOG.debug("removing particular internal-to-external-port-map {}", intExtPortMap);
                        MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION, intExtPortMapIdentifier);
                    } catch (Exception e) {
                        LOG.error("Failure in deletion of internal-to-external-port-map {}", intExtPortMap);
                    } finally {
                        if (isLockAcquired) {
                            NeutronvpnUtils.unlock(fixedIpAddress);
                        }
                    }
                }
                LOG.debug("Deletion from FloatingIpInfo DS successful for fixedIp {} ", fixedIpAddress);
            } else {
                LOG.error("routerPorts for router {} not found", routerName);
            }
        } catch (Exception e) {
            LOG.error("Failed to delete internal-to-external-port-map from FloatingIpInfo DS for fixed Ip {}",
                    fixedIpAddress);
        }
    }

    protected void dissociatefixedIPFromFloatingIP(String fixedNeutronPortName) {
        boolean isLockAcquired = false;
        InstanceIdentifier.InstanceIdentifierBuilder<FloatingIpInfo> floatingIpInfoIdentifierBuilder =
                InstanceIdentifier.builder(FloatingIpInfo.class);
        try {
            Optional<FloatingIpInfo> optionalFloatingIPInfo = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType
                    .CONFIGURATION, floatingIpInfoIdentifierBuilder.build());
            if (optionalFloatingIPInfo.isPresent() && optionalFloatingIPInfo.get() != null) {
                List<RouterPorts> routerPortsList = optionalFloatingIPInfo.get().getRouterPorts();
                if (routerPortsList != null && !routerPortsList.isEmpty()) {
                    for (RouterPorts routerPorts : routerPortsList) {
                        List<Ports> portsList = routerPorts.getPorts();
                        if (portsList != null && !portsList.isEmpty()) {
                            for (Ports ports : portsList) {
                                if (ports.getPortName().equals(fixedNeutronPortName)) {
                                    String routerName = routerPorts.getRouterId();
                                    InstanceIdentifier.InstanceIdentifierBuilder<RouterPorts>
                                            routerPortsIdentifierBuilder = floatingIpInfoIdentifierBuilder.child
                                            (RouterPorts.class, new RouterPortsKey(routerName));
                                    removeRouterPortsOrPortsNode(routerName, routerPortsIdentifierBuilder, portsList,
                                            fixedNeutronPortName, isLockAcquired);
                                    LOG.debug("Deletion from FloatingIpInfo DS successful for fixedIP neutron port {} ",
                                            fixedNeutronPortName);
                                    break;
                                }
                            }
                        }
                    }
                } else {
                    LOG.debug("No router present containing fixed to floating IP association(s)");
                }
            } else {
                LOG.debug("FloatingIPInfo DS empty. Hence, no router present containing fixed to floating IP " +
                        "association(s)");
            }
        } catch (Exception e) {
            LOG.error("Failed to dissociate fixedIP from FloatingIpInfo DS for neutron port {}", fixedNeutronPortName);
        }
    }

    private void removeRouterPortsOrPortsNode(String routerName, InstanceIdentifier
            .InstanceIdentifierBuilder<RouterPorts> routerPortsIdentifierBuilder, List<Ports> portsList,
                                              String fixedNeutronPortName, boolean isLockAcquired) {
        String lockName = null;
        try {
            if (portsList.size() == 1) {
                // remove entire routerPorts node
                lockName = routerName;
                isLockAcquired = NeutronvpnUtils.lock(lockName);
                LOG.debug("removing routerPorts node: {} ", routerName);
                MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION, routerPortsIdentifierBuilder
                        .build());
            } else {
                InstanceIdentifier.InstanceIdentifierBuilder<Ports> portsIdentifierBuilder =
                        routerPortsIdentifierBuilder.child(Ports.class, new PortsKey(fixedNeutronPortName));
                // remove entire ports node under this routerPorts node
                lockName = fixedNeutronPortName;
                isLockAcquired = NeutronvpnUtils.lock(lockName);
                LOG.debug("removing ports node {} under routerPorts node {}", fixedNeutronPortName, routerName);
                MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION, portsIdentifierBuilder.build());
            }
        } catch (Exception e) {
            LOG.error("Failure in deletion of routerPorts node {}", routerName);
        } finally {
            if (isLockAcquired) {
                NeutronvpnUtils.unlock(lockName);
            }
        }
    }

    // updates FloatingIPPortInfo to have isFloatingIPDeleted set to true on a floating IP delete
    private void updateFloatingIpPortInfo(Uuid floatingIpId, Uuid floatingIpPortId) {
        InstanceIdentifier id = buildfloatingIpIdToPortMappingIdentifier(floatingIpId);
        try {
            FloatingIpIdToPortMappingBuilder floatingIpIdToPortMappingBuilder = new
                    FloatingIpIdToPortMappingBuilder().setFloatingIpDeleted(true);
            LOG.debug("Updating floating IP UUID {} to Floating IP neutron port {} mapping in Floating IP" +
                            " Port Info Config DS to set isFloatingIpDeleted flag as true", floatingIpId.getValue(),
                    floatingIpPortId.getValue());
            MDSALUtil.syncUpdate(dataBroker, LogicalDatastoreType.CONFIGURATION, id,
                    floatingIpIdToPortMappingBuilder.build());
        } catch (Exception e) {
            LOG.error("Updating floating IP UUID {} to Floating IP neutron port {} mapping in Floating IP" +
                    " Port Info Config DS to set isFloatingIpDeleted flag as true failed with exception {}",
                    floatingIpId.getValue(), floatingIpPortId.getValue(), e);
        }
    }

    private void removeFromFloatingIpPortInfo(Uuid floatingIpId) {
        InstanceIdentifier id = buildfloatingIpIdToPortMappingIdentifier(floatingIpId);
        try {
            LOG.debug("Deleting floating IP UUID {} to Floating IP neutron port mapping from Floating " +
                    "IP Port Info Config DS", floatingIpId.getValue());
            MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
        } catch (Exception e) {
            LOG.error("Deleting floating IP UUID {} to Floating IP neutron port mapping from Floating " +
                    "IP Port Info Config DS failed with exception {}", floatingIpId.getValue(), e);
        }
    }
}

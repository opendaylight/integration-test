/*
 * Copyright (c) 2015 - 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.neutronvpn;

import static org.opendaylight.netvirt.neutronvpn.NeutronvpnUtils.buildfloatingIpIdToPortMappingIdentifier;

import com.google.common.base.Optional;
import com.google.common.collect.Lists;
import com.google.common.util.concurrent.ListenableFuture;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.concurrent.Callable;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.NotificationPublishService;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.genius.datastoreutils.DataStoreJobCoordinator;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.netvirt.elanmanager.api.IElanService;
import org.opendaylight.netvirt.neutronvpn.api.utils.NeutronConstants;
import org.opendaylight.netvirt.neutronvpn.api.utils.NeutronUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.iana._if.type.rev140508.L2vlan;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.InterfaceBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.PhysAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.IfL2vlan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.IfL2vlanBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.ParentRefs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.ParentRefsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.InterfaceAcl;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.InterfaceAclBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.interfaces._interface.AllowedAddressPairs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.ElanInstances;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.ElanInterfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstanceKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.interfaces.ElanInterface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.interfaces.ElanInterfaceBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.interfaces.ElanInterfaceKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.port.info.FloatingIpIdToPortMappingBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.port.info.FloatingIpIdToPortMappingKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.PortAddedToSubnetBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.PortRemovedFromSubnetBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.subnetmaps.Subnetmap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l3.rev150712.routers.attributes.routers.Router;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.networks.attributes.networks.Network;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.FixedIps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.Ports;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.qos.ext.rev160613.QosPortExtension;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class NeutronPortChangeListener extends AsyncDataTreeChangeListenerBase<Port, NeutronPortChangeListener>
        implements AutoCloseable {
    private static final Logger LOG = LoggerFactory.getLogger(NeutronPortChangeListener.class);
    private final DataBroker dataBroker;
    private final NeutronvpnManager nvpnManager;
    private final NeutronvpnNatManager nvpnNatManager;
    private final NotificationPublishService notificationPublishService;
    private final NeutronSubnetGwMacResolver gwMacResolver;
    private OdlInterfaceRpcService odlInterfaceRpcService;
    private final IElanService elanService;

    public NeutronPortChangeListener(final DataBroker dataBroker,
                                     final NeutronvpnManager nVpnMgr, final NeutronvpnNatManager nVpnNatMgr,
                                     final NotificationPublishService notiPublishService,
                                     final NeutronSubnetGwMacResolver gwMacResolver,
                                     final OdlInterfaceRpcService odlInterfaceRpcService,
                                     final IElanService elanService) {
        super(Port.class, NeutronPortChangeListener.class);
        this.dataBroker = dataBroker;
        nvpnManager = nVpnMgr;
        nvpnNatManager = nVpnNatMgr;
        notificationPublishService = notiPublishService;
        this.gwMacResolver = gwMacResolver;
        this.odlInterfaceRpcService = odlInterfaceRpcService;
        this.elanService = elanService;
    }


    public void start() {
        LOG.info("{} start", getClass().getSimpleName());
        registerListener(LogicalDatastoreType.CONFIGURATION, dataBroker);
    }

    @Override
    protected InstanceIdentifier<Port> getWildCardPath() {
        return InstanceIdentifier.create(Neutron.class).child(Ports.class).child(Port.class);
    }

    @Override
    protected NeutronPortChangeListener getDataTreeChangeListener() {
        return NeutronPortChangeListener.this;
    }


    @Override
    protected void add(InstanceIdentifier<Port> identifier, Port input) {
        String portName = input.getUuid().getValue();
        LOG.trace("Adding Port : key: {}, value={}", identifier, input);
        Network network = NeutronvpnUtils.getNeutronNetwork(dataBroker, input.getNetworkId());
        if (network == null || !NeutronvpnUtils.isNetworkTypeSupported(network)) {
            //FIXME: This should be removed when support for VLAN and GRE network types is added
            LOG.error("neutron vpn doesn't support vlan/gre network provider type for the port {} which is part of " +
                    "network {}.", portName, network);
            return;
        }
        NeutronvpnUtils.addToPortCache(input);

        /* check if router interface has been created */
        if ((input.getDeviceOwner() != null) && (input.getDeviceId() != null)) {
            if (input.getDeviceOwner().equals(NeutronConstants.DEVICE_OWNER_ROUTER_INF)) {
                handleRouterInterfaceAdded(input);
                /* nothing else to do here */
                return;
            }
            if (NeutronConstants.DEVICE_OWNER_GATEWAY_INF.equals(input.getDeviceOwner())) {
                handleRouterGatewayUpdated(input);
            } else if (NeutronConstants.DEVICE_OWNER_FLOATING_IP.equals(input.getDeviceOwner())) {

                // populate floating-ip uuid and floating-ip port attributes (uuid, mac and subnet id for the ONLY
                // fixed IP) to be used by NAT, depopulated in NATService once mac is retrieved in the removal path
                addToFloatingIpPortInfo(new Uuid(input.getDeviceId()), input.getUuid(), input.getFixedIps().get(0)
                                .getSubnetId(), input.getMacAddress().getValue());

                elanService.handleKnownL3DmacAddress(input.getMacAddress().getValue(), input.getNetworkId().getValue(),
                        NwConstants.ADD_FLOW);
            }
        }
        if (input.getFixedIps() != null && !input.getFixedIps().isEmpty()) {
            handleNeutronPortCreated(input);
        }
    }

    @Override
    protected void remove(InstanceIdentifier<Port> identifier, Port input) {
        LOG.trace("Removing Port : key: {}, value={}", identifier, input);
        Network network = NeutronvpnUtils.getNeutronNetwork(dataBroker, input.getNetworkId());
        if (network == null || !NeutronvpnUtils.isNetworkTypeSupported(network)) {
            //FIXME: This should be removed when support for VLAN and GRE network types is added
            LOG.error("neutron vpn doesn't support vlan/gre network provider type for the port {} which is part of " +
                    "network {}.", input.getUuid().getValue(), network);
            return;
        }
        NeutronvpnUtils.removeFromPortCache(input);

        if ((input.getDeviceOwner() != null) && (input.getDeviceId() != null)) {
            if (input.getDeviceOwner().equals(NeutronConstants.DEVICE_OWNER_ROUTER_INF)) {
                handleRouterInterfaceRemoved(input);
                /* nothing else to do here */
                return;
            } else if (NeutronConstants.DEVICE_OWNER_GATEWAY_INF.equals(input.getDeviceOwner())
                    || NeutronConstants.DEVICE_OWNER_FLOATING_IP.equals(input.getDeviceOwner())) {
                elanService.handleKnownL3DmacAddress(input.getMacAddress().getValue(), input.getNetworkId().getValue(),
                        NwConstants.DEL_FLOW);
            }
        }
        if (input.getFixedIps() != null && !input.getFixedIps().isEmpty()) {
            handleNeutronPortDeleted(input);
        }
    }

    @Override
    protected void update(InstanceIdentifier<Port> identifier, Port original, Port update) {
        final String portName = update.getUuid().getValue();
        LOG.trace("Updating Port : key: {}, original value={}, update value={}", identifier, original, update);
        Network network = NeutronvpnUtils.getNeutronNetwork(dataBroker, update.getNetworkId());
        if (network == null || !NeutronvpnUtils.isNetworkTypeSupported(network)) {
            LOG.error("neutron vpn doesn't support vlan/gre network provider type for the port {} which is part of " +
                    "network {}. Skipping the processing of Port update DCN", portName, network);
            return;
        }
        NeutronvpnUtils.addToPortCache(update);

        /* check if router interface has been updated */
        if ((update.getDeviceOwner() != null) && (update.getDeviceId() != null)) {
            if (update.getDeviceOwner().equals(NeutronConstants.DEVICE_OWNER_ROUTER_INF)) {
                handleRouterInterfaceAdded(update);
                /* nothing else to do here */
                return;
            }
        }

        // check if VIF type updated as part of port binding
        // check if port security enabled/disabled as part of port update
        boolean isPortVifTypeUpdated = NeutronvpnUtils.isPortVifTypeUpdated(original, update);
        boolean origSecurityEnabled = NeutronvpnUtils.getPortSecurityEnabled(original);
        boolean updatedSecurityEnabled = NeutronvpnUtils.getPortSecurityEnabled(update);

        if (isPortVifTypeUpdated || origSecurityEnabled || updatedSecurityEnabled) {
            InstanceIdentifier interfaceIdentifier = NeutronvpnUtils.buildVlanInterfaceIdentifier(portName);
            final DataStoreJobCoordinator portDataStoreCoordinator = DataStoreJobCoordinator.getInstance();
            portDataStoreCoordinator.enqueueJob("PORT- " + portName, new Callable<List<ListenableFuture<Void>>>() {
                @Override
                public List<ListenableFuture<Void>> call() throws Exception {
                    WriteTransaction wrtConfigTxn = dataBroker.newWriteOnlyTransaction();
                    try {
                        Optional<Interface> optionalInf = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType
                                .CONFIGURATION, interfaceIdentifier);
                        if (optionalInf.isPresent()) {
                            InterfaceBuilder interfaceBuilder = new InterfaceBuilder(optionalInf.get());
                            if (isPortVifTypeUpdated && getParentRefsBuilder(update) != null) {
                                interfaceBuilder.addAugmentation(ParentRefs.class, getParentRefsBuilder(update).build
                                        ());
                            }
                            if (origSecurityEnabled || updatedSecurityEnabled) {
                                InterfaceAcl infAcl = handlePortSecurityUpdated(original, update,
                                        origSecurityEnabled, updatedSecurityEnabled, interfaceBuilder).build();
                                interfaceBuilder.addAugmentation(InterfaceAcl.class, infAcl);
                            }
                            LOG.info("Of-port-interface updation for port {}", portName);
                            // Update OFPort interface for this neutron port
                            wrtConfigTxn.put(LogicalDatastoreType.CONFIGURATION, interfaceIdentifier,
                                    interfaceBuilder.build());
                        } else {
                            LOG.error("Interface {} is not present", portName);
                        }
                    } catch (Exception e) {
                        LOG.error("Failed to update interface {} due to the exception {}", portName, e);
                    }
                    List<ListenableFuture<Void>> futures = new ArrayList<>();
                    futures.add(wrtConfigTxn.submit());
                    return futures;
                }
            });
        }
        List<FixedIps> oldIPs = (original.getFixedIps() != null) ? original.getFixedIps() : new ArrayList<FixedIps>();
        List<FixedIps> newIPs = (update.getFixedIps() != null) ? update.getFixedIps() : new ArrayList<FixedIps>();
        if (!oldIPs.equals(newIPs)) {
            Iterator<FixedIps> iterator = newIPs.iterator();
            while (iterator.hasNext()) {
                FixedIps ip = iterator.next();
                if (oldIPs.remove(ip)) {
                    iterator.remove();
                }
            }
            handleNeutronPortUpdated(original, update);
        }
        if (NeutronConstants.DEVICE_OWNER_GATEWAY_INF.equals(update.getDeviceOwner())) {
            handleRouterGatewayUpdated(update);
        } else if (NeutronConstants.DEVICE_OWNER_FLOATING_IP.equals(update.getDeviceOwner())) {
            elanService.handleKnownL3DmacAddress(update.getMacAddress().getValue(), update.getNetworkId().getValue(),
                    NwConstants.ADD_FLOW);
        }
        // check for QoS updates
        QosPortExtension updateQos = update.getAugmentation(QosPortExtension.class);
        QosPortExtension originalQos = original.getAugmentation(QosPortExtension.class);
        if (originalQos == null && updateQos != null) {
            // qos policy add
            NeutronvpnUtils.addToQosPortsCache(updateQos.getQosPolicyId(), update);
            NeutronQosUtils.handleNeutronPortQosUpdate(dataBroker, odlInterfaceRpcService,
                    update, updateQos.getQosPolicyId());
        } else if (originalQos != null && updateQos != null
                && !originalQos.getQosPolicyId().equals(updateQos.getQosPolicyId())) {
            // qos policy update
            NeutronvpnUtils.removeFromQosPortsCache(originalQos.getQosPolicyId(), original);
            NeutronvpnUtils.addToQosPortsCache(updateQos.getQosPolicyId(), update);
            NeutronQosUtils.handleNeutronPortQosUpdate(dataBroker, odlInterfaceRpcService,
                    update, updateQos.getQosPolicyId());
        } else if (originalQos != null && updateQos == null) {
            // qos policy delete
            NeutronQosUtils.handleNeutronPortQosRemove(dataBroker, odlInterfaceRpcService,
                    original, originalQos.getQosPolicyId());
            NeutronvpnUtils.removeFromQosPortsCache(originalQos.getQosPolicyId(), original);
        }
    }

    private void handleRouterInterfaceAdded(Port routerPort) {
        if (routerPort.getDeviceId() != null) {
            Uuid routerId = new Uuid(routerPort.getDeviceId());
            Uuid infNetworkId = routerPort.getNetworkId();
            Uuid existingVpnId = NeutronvpnUtils.getVpnForNetwork(dataBroker, infNetworkId);

            elanService.handleKnownL3DmacAddress(routerPort.getMacAddress().getValue(), infNetworkId.getValue(),
                    NwConstants.ADD_FLOW);
            if (existingVpnId == null) {
                for (FixedIps portIP : routerPort.getFixedIps()) {
                    Uuid vpnId = NeutronvpnUtils.getVpnForRouter(dataBroker, routerId, true);
                    if (vpnId == null) {
                        vpnId = routerId;
                    }
                    // NOTE:  Please donot change the order of calls to updateSubnetNodeWithFixedIPs
                    // and addSubnetToVpn here
                    String ipValue = String.valueOf(portIP.getIpAddress().getValue());
                    nvpnManager.updateSubnetNodeWithFixedIps(portIP.getSubnetId(), routerId,
                            routerPort.getUuid(), ipValue, routerPort.getMacAddress().getValue());
                    nvpnManager.addSubnetToVpn(vpnId, portIP.getSubnetId());
                    nvpnNatManager.handleSubnetsForExternalRouter(routerId, dataBroker);
                    PhysAddress mac = new PhysAddress(routerPort.getMacAddress().getValue());
                    LOG.trace("NeutronPortChangeListener Add Subnet Gateway IP {} MAC {} Interface {} VPN {}",
                            ipValue, routerPort.getMacAddress(),
                            routerPort.getUuid().getValue(), vpnId.getValue());
                    // ping responder for router interfaces
                    nvpnManager.createVpnInterface(vpnId, routerId, routerPort, null);
                }
            } else {
                LOG.error("Neutron network {} corresponding to router interface port {} for neutron router {} already" +
                        " associated to VPN {}", infNetworkId.getValue(), routerPort.getUuid().getValue(), routerId
                        .getValue(), existingVpnId.getValue());
            }
        }
    }

    private void handleRouterInterfaceRemoved(Port routerPort) {
        if (routerPort.getDeviceId() != null) {
            Uuid routerId = new Uuid(routerPort.getDeviceId());
            Uuid infNetworkId = routerPort.getNetworkId();

            elanService.handleKnownL3DmacAddress(routerPort.getMacAddress().getValue(), infNetworkId.getValue(),
                    NwConstants.DEL_FLOW);
            for (FixedIps portIP : routerPort.getFixedIps()) {
                Uuid vpnId = NeutronvpnUtils.getVpnForRouter(dataBroker, routerId, true);
                if(vpnId == null) {
                    vpnId = routerId;
                }
                // NOTE:  Please donot change the order of calls to removeSubnetFromVpn and
                // and updateSubnetNodeWithFixedIPs
                nvpnManager.removeSubnetFromVpn(vpnId, portIP.getSubnetId());
                nvpnManager.updateSubnetNodeWithFixedIps(portIP.getSubnetId(), null,
                        null, null, null);
                nvpnNatManager.handleSubnetsForExternalRouter(routerId, dataBroker);
                String ipValue = String.valueOf(portIP.getIpAddress().getValue());
                NeutronvpnUtils.removeVpnPortFixedIpToPort(dataBroker, vpnId.getValue(), ipValue);
                // ping responder for router interfaces
                nvpnManager.deleteVpnInterface(vpnId, routerId, routerPort, null);
            }
        }
    }

    private void handleRouterGatewayUpdated(Port routerGwPort) {
        Uuid routerId = new Uuid(routerGwPort.getDeviceId());
        Uuid networkId = routerGwPort.getNetworkId();
        elanService.handleKnownL3DmacAddress(routerGwPort.getMacAddress().getValue(), networkId.getValue(),
                NwConstants.ADD_FLOW);

        Router router = NeutronvpnUtils.getNeutronRouter(dataBroker, routerId);
        if (router == null) {
            LOG.warn("No router found for router GW port {} router id {}", routerGwPort.getUuid(), routerId.getValue());
            return;
        }

        gwMacResolver.sendArpRequestsToExtGateways(router);
    }

    private void handleNeutronPortCreated(final Port port) {
        final String portName = port.getUuid().getValue();
        final Uuid portId = port.getUuid();
        final Uuid subnetId = port.getFixedIps().get(0).getSubnetId();
        final DataStoreJobCoordinator portDataStoreCoordinator = DataStoreJobCoordinator.getInstance();
        portDataStoreCoordinator.enqueueJob("PORT- " + portName, new Callable<List<ListenableFuture<Void>>>() {
            @Override
            public List<ListenableFuture<Void>> call() throws Exception {
                WriteTransaction wrtConfigTxn = dataBroker.newWriteOnlyTransaction();
                List<ListenableFuture<Void>> futures = new ArrayList<>();

                // add direct port to subnetMaps config DS
                if (!NeutronUtils.isPortVnicTypeNormal(port)) {
                    nvpnManager.updateSubnetmapNodeWithPorts(subnetId, null, portId);
                    LOG.info("Port {} is not a NORMAL VNIC Type port; OF Port interfaces are not created", portName);
                    futures.add(wrtConfigTxn.submit());
                    return futures;
                }
                LOG.info("Of-port-interface creation for port {}", portName);
                // Create of-port interface for this neutron port
                String portInterfaceName = createOfPortInterface(port, wrtConfigTxn);
                LOG.debug("Creating ELAN Interface for port {}", portName);
                createElanInterface(port, portInterfaceName, wrtConfigTxn);

                Subnetmap subnetMap = nvpnManager.updateSubnetmapNodeWithPorts(subnetId, portId, null);
                Uuid vpnId = (subnetMap != null) ? subnetMap.getVpnId() : null;
                Uuid routerId = (subnetMap != null) ? subnetMap.getRouterId() : null;
                if (vpnId != null) {
                    // create vpn-interface on this neutron port
                    LOG.debug("Adding VPN Interface for port {}", portName);
                    nvpnManager.createVpnInterface(vpnId, routerId, port, wrtConfigTxn);
                    // send port added to subnet notification
                    // only sent when the port is part of a VPN
                    String elanInstanceName = port.getNetworkId().getValue();
                    InstanceIdentifier<ElanInstance> elanIdentifierId = InstanceIdentifier.builder(ElanInstances.class)
                            .child(ElanInstance.class, new ElanInstanceKey(elanInstanceName)).build();
                    try {
                        Optional<ElanInstance> elanInstance = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType
                                .CONFIGURATION, elanIdentifierId);
                        if (elanInstance.isPresent()) {
                            long elanTag = elanInstance.get().getElanTag();
                            checkAndPublishPortAddNotification(subnetMap.getSubnetIp(), subnetId, port.getUuid(), elanTag);

                            LOG.debug("Port added to subnet notification sent for port {}", portName);
                        } else {
                            LOG.error("Port added to subnet notification failed for port {} because of failure in " +
                                    "reading ELANInstance {}", portName, elanInstanceName);
                        }
                    } catch (Exception e) {
                        LOG.error("Port added to subnet notification failed for port {}", portName, e);
                    }
                }
                futures.add(wrtConfigTxn.submit());
                return futures;
            }
        });
    }

    private void handleNeutronPortDeleted(final Port port) {
        final String portName = port.getUuid().getValue();
        final Uuid portId = port.getUuid();
        final Uuid subnetId = port.getFixedIps().get(0).getSubnetId();
        final DataStoreJobCoordinator portDataStoreCoordinator = DataStoreJobCoordinator.getInstance();
        portDataStoreCoordinator.enqueueJob("PORT- " + portName, new Callable<List<ListenableFuture<Void>>>() {
            @Override
            public List<ListenableFuture<Void>> call() throws Exception {
                WriteTransaction wrtConfigTxn = dataBroker.newWriteOnlyTransaction();
                List<ListenableFuture<Void>> futures = new ArrayList<>();

                // remove direct port from subnetMaps config DS
                if (!NeutronUtils.isPortVnicTypeNormal(port)) {
                    nvpnManager.removePortsFromSubnetmapNode(subnetId, null, portId);
                    LOG.info("Port {} is not a NORMAL VNIC Type port; OF Port interfaces are not created", portName);
                    futures.add(wrtConfigTxn.submit());
                    return futures;
                }
                Subnetmap subnetMap = nvpnManager.removePortsFromSubnetmapNode(subnetId, portId, null);
                Uuid vpnId = (subnetMap != null) ? subnetMap.getVpnId() : null;
                Uuid routerId = (subnetMap != null) ? subnetMap.getRouterId() : null;
                if (vpnId != null) {
                    // remove vpn-interface for this neutron port
                    LOG.debug("removing VPN Interface for port {}", portName);
                    nvpnManager.deleteVpnInterface(vpnId, routerId, port, wrtConfigTxn);
                    // send port removed from subnet notification
                    // only sent when the port was part of a VPN
                    String elanInstanceName = port.getNetworkId().getValue();
                    InstanceIdentifier<ElanInstance> elanIdentifierId = InstanceIdentifier.builder(ElanInstances.class)
                            .child(ElanInstance.class, new ElanInstanceKey(elanInstanceName)).build();
                    try {
                        Optional<ElanInstance> elanInstance = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType
                                .CONFIGURATION, elanIdentifierId);
                        if (elanInstance.isPresent()) {
                            long elanTag = elanInstance.get().getElanTag();
                            checkAndPublishPortRemoveNotification(subnetMap.getSubnetIp(), subnetId, port.getUuid(),
                                    elanTag);

                            LOG.debug("Port removed from subnet notification sent for port {}", portName);
                        } else {
                            LOG.error("Port removed from subnet notification failed for port {} because of failure in" +
                                    "reading ELANInstance {}", portName, elanInstanceName);
                        }
                    } catch (Exception e) {
                        LOG.error("Port removed from subnet notification failed for port {}", portName, e);
                    }
                }
                // Remove of-port interface for this neutron port
                // ELAN interface is also implicitly deleted as part of this operation
                LOG.debug("Of-port-interface removal for port {}", portName);
                deleteOfPortInterface(port, wrtConfigTxn);
                //dissociate fixedIP from floatingIP if associated
                nvpnManager.dissociatefixedIPFromFloatingIP(port.getUuid().getValue());
                futures.add(wrtConfigTxn.submit());
                return futures;
            }
        });
    }

    private void handleNeutronPortUpdated(final Port portoriginal, final Port portupdate) {
        if (portoriginal.getFixedIps() == null || portoriginal.getFixedIps().isEmpty()) {
            handleNeutronPortCreated(portupdate);
            return;
        }

        if (portupdate.getFixedIps() == null || portupdate.getFixedIps().isEmpty()) {
            LOG.debug("Ignoring portUpdate (fixed_ip removal) for port {} as this case is handled "
                      + "during subnet deletion event.", portupdate.getUuid().getValue());
            return;
        }

        final DataStoreJobCoordinator portDataStoreCoordinator = DataStoreJobCoordinator.getInstance();
        portDataStoreCoordinator.enqueueJob("PORT- " + portupdate.getUuid().getValue(), new
                Callable<List<ListenableFuture<Void>>>() {
                    @Override
                    public List<ListenableFuture<Void>> call() throws Exception {
                        WriteTransaction wrtConfigTxn = dataBroker.newWriteOnlyTransaction();
                        List<ListenableFuture<Void>> futures = new ArrayList<>();

                        Uuid vpnIdNew = null;
                        final Uuid subnetIdOr = portupdate.getFixedIps().get(0).getSubnetId();
                        final Uuid subnetIdUp = portupdate.getFixedIps().get(0).getSubnetId();
                        // check if subnet UUID has changed upon change in fixedIP
                        final Boolean subnetUpdated = subnetIdUp.equals(subnetIdOr) ? false : true;

                        if (subnetUpdated) {
                            Subnetmap subnetMapOld = nvpnManager.removePortsFromSubnetmapNode(subnetIdOr, portoriginal
                                    .getUuid(), null);
                            Uuid vpnIdOld = (subnetMapOld != null) ? subnetMapOld.getVpnId() : null;
                            if (vpnIdOld != null) {
                                // send port removed from subnet notification
                                // only sent when the port was part of a VPN
                                String portOriginalName = portoriginal.getUuid().getValue();
                                String elanInstanceName = portoriginal.getNetworkId().getValue();
                                InstanceIdentifier<ElanInstance> elanIdentifierId = InstanceIdentifier.builder
                                        (ElanInstances.class).child(ElanInstance.class, new ElanInstanceKey
                                        (elanInstanceName)).build();
                                try {
                                    Optional<ElanInstance> elanInstance = NeutronvpnUtils.read(dataBroker,
                                            LogicalDatastoreType.CONFIGURATION, elanIdentifierId);
                                    if (elanInstance.isPresent()) {
                                        long elanTag = elanInstance.get().getElanTag();
                                        checkAndPublishPortRemoveNotification(subnetMapOld.getSubnetIp(), subnetIdOr,
                                                portoriginal.getUuid(), elanTag);

                                        LOG.debug("Port removed from subnet notification sent for port {}",
                                                portOriginalName);
                                    } else {
                                        LOG.error("Port removed from subnet notification failed for port {} because "
                                                + "of failure in" + "reading ELANInstance {}", portOriginalName,
                                                elanInstanceName);
                                    }
                                } catch (Exception e) {
                                    LOG.error("Port removed from subnet notification failed for port {}",
                                            portOriginalName, e);
                                }
                            }
                            Subnetmap subnetMapNew = nvpnManager.updateSubnetmapNodeWithPorts(subnetIdUp, portupdate
                                            .getUuid(), null);
                            vpnIdNew = (subnetMapNew != null) ? subnetMapNew.getVpnId() : null;
                            if (vpnIdNew != null) {
                                // send port added to subnet notification
                                // only sent when the port is part of a VPN
                                String portUpdatedName = portoriginal.getUuid().getValue();
                                String elanInstanceName = portupdate.getNetworkId().getValue();
                                InstanceIdentifier<ElanInstance> elanIdentifierId = InstanceIdentifier.builder
                                        (ElanInstances.class).child(ElanInstance.class, new ElanInstanceKey
                                        (elanInstanceName)).build();
                                try {
                                    Optional<ElanInstance> elanInstance = NeutronvpnUtils.read(dataBroker,
                                            LogicalDatastoreType.CONFIGURATION, elanIdentifierId);
                                    if (elanInstance.isPresent()) {
                                        long elanTag = elanInstance.get().getElanTag();
                                        checkAndPublishPortAddNotification(subnetMapNew.getSubnetIp(), subnetIdUp,
                                                portupdate.getUuid(), elanTag);

                                        LOG.debug("Port added to subnet notification sent for port {}",
                                                portUpdatedName);
                                    } else {
                                        LOG.error("Port added to subnet notification failed for port {} because of " +
                                                "failure in " + "reading ELANInstance {}", portUpdatedName,
                                                elanInstanceName);
                                    }
                                } catch (Exception e) {
                                    LOG.error("Port added to subnet notification failed for port {}",
                                            portUpdatedName, e);
                                }
                            }
                        }
                        if (!subnetUpdated) {
                            Subnetmap subnetmap = NeutronvpnUtils.getSubnetmap(dataBroker, subnetIdUp);
                            vpnIdNew = subnetmap.getVpnId();
                        }
                        if (vpnIdNew != null) {
                            // remove vpn-interface for this neutron port
                            LOG.debug("removing VPN Interface for port {}", portupdate.getUuid().getValue());
                            nvpnManager.deleteVpnInterface(vpnIdNew, null, portupdate, wrtConfigTxn);
                            // create vpn-interface on this neutron port
                            LOG.debug("Adding VPN Interface for port {}", portupdate.getUuid().getValue());
                            nvpnManager.createVpnInterface(vpnIdNew, null, portupdate, wrtConfigTxn);
                        }
                        futures.add(wrtConfigTxn.submit());
                        return futures;
                    }
                });
    }

    private static InterfaceAclBuilder handlePortSecurityUpdated(Port portOriginal, Port portUpdated, boolean
            origSecurityEnabled, boolean updatedSecurityEnabled, InterfaceBuilder interfaceBuilder) {
        String interfaceName = portUpdated.getUuid().getValue();
        InterfaceAclBuilder interfaceAclBuilder = null;
        if (origSecurityEnabled != updatedSecurityEnabled) {
            interfaceAclBuilder = new InterfaceAclBuilder();
            interfaceAclBuilder.setPortSecurityEnabled(updatedSecurityEnabled);
            if (updatedSecurityEnabled) {
                // Handle security group enabled
                NeutronvpnUtils.populateInterfaceAclBuilder(interfaceAclBuilder, portUpdated);
            } else {
                // Handle security group disabled
                interfaceAclBuilder.setSecurityGroups(Lists.newArrayList());
                interfaceAclBuilder.setAllowedAddressPairs(Lists.newArrayList());
            }
        } else {
            if (updatedSecurityEnabled) {
                // handle SG add/delete delta
                InterfaceAcl interfaceAcl = interfaceBuilder.getAugmentation(InterfaceAcl.class);
                interfaceAclBuilder = new InterfaceAclBuilder(interfaceAcl);
                interfaceAclBuilder.setSecurityGroups(
                        NeutronvpnUtils.getUpdatedSecurityGroups(interfaceAcl.getSecurityGroups(),
                                portOriginal.getSecurityGroups(), portUpdated.getSecurityGroups()));
                List<AllowedAddressPairs> updatedAddressPairs = NeutronvpnUtils.getUpdatedAllowedAddressPairs(
                        interfaceAcl.getAllowedAddressPairs(), portOriginal.getAllowedAddressPairs(),
                        portUpdated.getAllowedAddressPairs());
                interfaceAclBuilder.setAllowedAddressPairs(NeutronvpnUtils.getAllowedAddressPairsForFixedIps(
                        updatedAddressPairs, portOriginal.getMacAddress(), portOriginal.getFixedIps(),
                        portUpdated.getFixedIps()));
            }
        }
        return interfaceAclBuilder;
    }

    private String createOfPortInterface(Port port, WriteTransaction wrtConfigTxn) {
        Interface inf = createInterface(port);
        String infName = inf.getName();

        LOG.debug("Creating OFPort Interface {}", infName);
        InstanceIdentifier interfaceIdentifier = NeutronvpnUtils.buildVlanInterfaceIdentifier(infName);
        try {
            Optional<Interface> optionalInf = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType.CONFIGURATION,
                    interfaceIdentifier);
            if (!optionalInf.isPresent()) {
                wrtConfigTxn.put(LogicalDatastoreType.CONFIGURATION, interfaceIdentifier, inf);
            } else {
                LOG.error("Interface {} is already present", infName);
            }
        } catch (Exception e) {
            LOG.error("failed to create interface {} due to the exception {} ", infName, e.getMessage());
        }
        return infName;
    }

    private Interface createInterface(Port port) {
        String parentRefName = NeutronvpnUtils.getVifPortName(port);
        String interfaceName = port.getUuid().getValue();
        IfL2vlan.L2vlanMode l2VlanMode = IfL2vlan.L2vlanMode.Trunk;
        InterfaceBuilder interfaceBuilder = new InterfaceBuilder();
        IfL2vlanBuilder ifL2vlanBuilder = new IfL2vlanBuilder();

        Network network = NeutronvpnUtils.getNeutronNetwork(dataBroker, port.getNetworkId());
        ifL2vlanBuilder.setL2vlanMode(l2VlanMode);

        if(parentRefName != null) {
            ParentRefsBuilder parentRefsBuilder = new ParentRefsBuilder().setParentInterface(parentRefName);
            interfaceBuilder.addAugmentation(ParentRefs.class, parentRefsBuilder.build());
        }

        interfaceBuilder.setEnabled(true).setName(interfaceName).setType(L2vlan.class)
                .addAugmentation(IfL2vlan.class, ifL2vlanBuilder.build());

        if (NeutronvpnUtils.getPortSecurityEnabled(port)) {
            InterfaceAclBuilder interfaceAclBuilder = new InterfaceAclBuilder();
            interfaceAclBuilder.setPortSecurityEnabled(true);
            NeutronvpnUtils.populateInterfaceAclBuilder(interfaceAclBuilder, port);
            interfaceBuilder.addAugmentation(InterfaceAcl.class, interfaceAclBuilder.build());
        }
        return interfaceBuilder.build();
    }

    private void deleteOfPortInterface(Port port, WriteTransaction wrtConfigTxn) {
        String name = port.getUuid().getValue();
        LOG.debug("Removing OFPort Interface {}", name);
        InstanceIdentifier interfaceIdentifier = NeutronvpnUtils.buildVlanInterfaceIdentifier(name);
        try {
            Optional<Interface> optionalInf = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType.CONFIGURATION,
                    interfaceIdentifier);
            if (optionalInf.isPresent()) {
                wrtConfigTxn.delete(LogicalDatastoreType.CONFIGURATION, interfaceIdentifier);
            } else {
                LOG.error("Interface {} is not present", name);
            }
        } catch (Exception e) {
            LOG.error("Failed to delete interface {} due to the exception {}", name, e.getMessage());
        }
    }

    private ParentRefsBuilder getParentRefsBuilder(Port update) {
        String parentRefName = NeutronvpnUtils.getVifPortName(update);
        if (parentRefName != null) {
            return new ParentRefsBuilder().setParentInterface(parentRefName);
        }
        return null;
    }

    private void createElanInterface(Port port, String name, WriteTransaction wrtConfigTxn) {
        String elanInstanceName = port.getNetworkId().getValue();
        List<PhysAddress> physAddresses = new ArrayList<>();
        physAddresses.add(new PhysAddress(port.getMacAddress().getValue()));

        InstanceIdentifier<ElanInterface> id = InstanceIdentifier.builder(ElanInterfaces.class).child(ElanInterface
                .class, new ElanInterfaceKey(name)).build();
        ElanInterface elanInterface = new ElanInterfaceBuilder().setElanInstanceName(elanInstanceName)
                .setName(name).setStaticMacEntries(physAddresses).setKey(new ElanInterfaceKey(name)).build();
        wrtConfigTxn.put(LogicalDatastoreType.CONFIGURATION, id, elanInterface);
        LOG.debug("Creating new ELan Interface {}", elanInterface);
    }

    private void addToFloatingIpPortInfo(Uuid floatingIpId, Uuid floatingIpPortId, Uuid floatingIpPortSubnetId, String
                                         floatingIpPortMacAddress) {
        InstanceIdentifier id = buildfloatingIpIdToPortMappingIdentifier(floatingIpId);
        try {
            FloatingIpIdToPortMappingBuilder floatingipIdToPortMacMappingBuilder = new
                    FloatingIpIdToPortMappingBuilder().setKey(new FloatingIpIdToPortMappingKey(floatingIpId))
                    .setFloatingIpId(floatingIpId).setFloatingIpPortId(floatingIpPortId).setFloatingIpPortSubnetId
                            (floatingIpPortSubnetId).setFloatingIpPortMacAddress(floatingIpPortMacAddress);
            LOG.debug("Creating floating IP UUID {} to Floating IP neutron port {} mapping in Floating IP" +
                            " Port Info Config DS", floatingIpId.getValue(), floatingIpPortId.getValue());
            MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, id,
                    floatingipIdToPortMacMappingBuilder.build());
        } catch (Exception e) {
            LOG.error("Creating floating IP UUID {} to Floating IP neutron port {} mapping in Floating IP" +
                    " Port Info Config DS failed with exception {}", floatingIpId.getValue(), floatingIpPortId
                    .getValue(), e);
        }
    }

    private void checkAndPublishPortAddNotification(String subnetIp, Uuid subnetId, Uuid portId, Long elanTag) throws
            InterruptedException {
        PortAddedToSubnetBuilder builder = new PortAddedToSubnetBuilder();
        LOG.info("publish notification called");
        builder.setSubnetIp(subnetIp);
        builder.setSubnetId(subnetId);
        builder.setPortId(portId);
        builder.setElanTag(elanTag);

        notificationPublishService.putNotification(builder.build());
    }

    private void checkAndPublishPortRemoveNotification(String subnetIp, Uuid subnetId, Uuid portId, Long elanTag)
            throws InterruptedException {
        PortRemovedFromSubnetBuilder builder = new PortRemovedFromSubnetBuilder();
        LOG.info("publish notification called");
        builder.setPortId(portId);
        builder.setSubnetIp(subnetIp);
        builder.setSubnetId(subnetId);
        builder.setElanTag(elanTag);

        notificationPublishService.putNotification(builder.build());
    }
}

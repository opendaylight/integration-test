/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager;

import java.math.BigInteger;
import java.net.InetAddress;
import java.util.ArrayList;
import java.util.List;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.genius.datastoreutils.DataStoreJobCoordinator;
import org.opendaylight.genius.interfacemanager.interfaces.IInterfaceManager;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.netvirt.neutronvpn.interfaces.INeutronVpnManager;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.MacAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.AlivenessMonitorService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.EtherTypes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.VpnToDpnList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpn.to.dpn.list.VpnInterfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.NeutronVpnPortipPortData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.neutron.vpn.portip.port.data.VpnPortipToPort;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.neutron.vpn.portip.port.data.VpnPortipToPortKey;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.base.Optional;

public class ArpMonitoringHandler extends AsyncDataTreeChangeListenerBase<VpnPortipToPort, ArpMonitoringHandler> {
    private static final Logger LOG = LoggerFactory.getLogger(ArpMonitoringHandler.class);
    private final DataBroker dataBroker;
    private final OdlInterfaceRpcService interfaceRpc;
    private final IMdsalApiManager mdsalManager;
    private final AlivenessMonitorService alivenessManager;
    private final INeutronVpnManager neutronVpnService;
    private final IInterfaceManager interfaceManager;
    private Long arpMonitorProfileId = 0L;

    public ArpMonitoringHandler(final DataBroker dataBroker, final OdlInterfaceRpcService interfaceRpc,
            IMdsalApiManager mdsalManager, AlivenessMonitorService alivenessManager, INeutronVpnManager neutronVpnService,
            IInterfaceManager interfaceManager) {
        super(VpnPortipToPort.class, ArpMonitoringHandler.class);
        this.dataBroker = dataBroker;
        this.interfaceRpc = interfaceRpc;
        this.mdsalManager = mdsalManager;
        this.alivenessManager = alivenessManager;
        this.neutronVpnService = neutronVpnService;
        this.interfaceManager = interfaceManager;
    }

    public void start() {
        Optional <Long> profileIdOptional = AlivenessMonitorUtils.allocateProfile(alivenessManager,
                ArpConstants.FAILURE_THRESHOLD, ArpConstants.ARP_CACHE_TIMEOUT_MILLIS, ArpConstants.MONITORING_WINDOW,
                EtherTypes.Arp);
        if(profileIdOptional.isPresent()) {
            arpMonitorProfileId = profileIdOptional.get();
        } else {
            LOG.error("Error while allocating Profile Id", profileIdOptional);
        }
        registerListener(LogicalDatastoreType.OPERATIONAL, dataBroker);
    }

    @Override
    protected InstanceIdentifier<VpnPortipToPort> getWildCardPath() {
        return InstanceIdentifier.create(NeutronVpnPortipPortData.class).child(VpnPortipToPort.class);
    }

    public static InstanceIdentifier<VpnPortipToPort> getVpnPortipToPortInstanceOpDataIdentifier(String ip, String vpnName) {
        return InstanceIdentifier.builder(NeutronVpnPortipPortData.class)
                .child(VpnPortipToPort.class, new VpnPortipToPortKey(ip, vpnName)).build();
    }

    @Override
    protected ArpMonitoringHandler getDataTreeChangeListener() {
        return this;
    }

    @Override
    protected void update(InstanceIdentifier<VpnPortipToPort> id, VpnPortipToPort value,
            VpnPortipToPort dataObjectModificationAfter) {
        try {
            Boolean islearnt = value.isLearnt();
            if(value.getMacAddress() == null || dataObjectModificationAfter.getMacAddress() == null) {
                LOG.warn("The Macaddress received is null for VpnPortipToPort {}, ignoring the DTCN", dataObjectModificationAfter);
                return;
            }
            if(islearnt) {
                remove(id, value);
                add(id, dataObjectModificationAfter);
            }
        } catch (Exception e) {
            LOG.error("Error in handling update to vpnPortIpToPort for vpnName {} and IP Address {}", value.getVpnName() , value.getPortFixedip(), e);
        }
    }

    @Override
    protected void add(InstanceIdentifier<VpnPortipToPort> identifier, VpnPortipToPort value) {
        try {
            InetAddress srcInetAddr = InetAddress.getByName(value.getPortFixedip());
            String macAddress = value.getMacAddress();
            if(value.getMacAddress() == null) {
                LOG.warn("The Macaddress received is null for VpnPortipToPort {}, ignoring the DTCN", value);
                return;
            }
            MacAddress srcMacAddress = MacAddress.getDefaultInstance(value.getMacAddress());
            String vpnName =  value.getVpnName();
            String interfaceName =  value.getPortName();
            Boolean islearnt = value.isLearnt();
            if (islearnt) {
                MacEntry macEntry = new MacEntry(vpnName, srcMacAddress, srcInetAddr, interfaceName);
                DataStoreJobCoordinator coordinator = DataStoreJobCoordinator.getInstance();
                coordinator.enqueueJob(buildJobKey(srcInetAddr.toString(), vpnName),
                        new ArpMonitorStartTask(macEntry, arpMonitorProfileId, dataBroker, alivenessManager,
                                interfaceRpc, neutronVpnService, interfaceManager));
            }
            if (value.isSubnetIp()) {
                WriteTransaction writeTx = dataBroker.newWriteOnlyTransaction();
                VpnUtil.setupSubnetMacIntoVpnInstance(dataBroker, mdsalManager, vpnName,
                        macAddress, BigInteger.ZERO /* On all DPNs */, writeTx, NwConstants.ADD_FLOW);
                writeTx.submit();
            }
        } catch (Exception e) {
            LOG.error("Error in handling add DCN for VpnPortipToPort {}", value, e);
        }
    }

    @Override
    protected void remove(InstanceIdentifier<VpnPortipToPort> key, VpnPortipToPort value) {
        try {
            InetAddress srcInetAddr = InetAddress.getByName(value.getPortFixedip());
            String macAddress = value.getMacAddress();
            if(value.getMacAddress() == null) {
                LOG.warn("The Macaddress received is null for VpnPortipToPort {}, ignoring the DTCN", value);
                return;
            }
            MacAddress srcMacAddress = MacAddress.getDefaultInstance(value.getMacAddress());
            String vpnName =  value.getVpnName();
            String interfaceName =  value.getPortName();
            Boolean islearnt = value.isLearnt();
            if (islearnt) {
                MacEntry macEntry = new MacEntry(vpnName, srcMacAddress, srcInetAddr, interfaceName);
                DataStoreJobCoordinator coordinator = DataStoreJobCoordinator.getInstance();
                coordinator.enqueueJob(buildJobKey(srcInetAddr.toString(), vpnName),
                        new ArpMonitorStopTask(macEntry, dataBroker, alivenessManager));
            }
            if (value.isSubnetIp()) {
                WriteTransaction writeTx = dataBroker.newWriteOnlyTransaction();
                VpnUtil.setupSubnetMacIntoVpnInstance(dataBroker, mdsalManager, vpnName,
                        macAddress, BigInteger.ZERO /* On all DPNs */, writeTx, NwConstants.DEL_FLOW);
                writeTx.submit();
            }
        } catch (Exception e) {
            LOG.error("Error in handling remove DCN for VpnPortipToPort {}", value, e);
        }
    }

    static String buildJobKey(String ip, String vpnName) {
        return new StringBuilder(ArpConstants.ARPJOB).append(ip).append(vpnName).toString();
    }
}

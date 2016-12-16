/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.genius.interfacemanager.interfaces.IInterfaceManager;
import org.opendaylight.netvirt.neutronvpn.interfaces.INeutronVpnManager;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv4Address;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.PhysAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.AlivenessMonitorService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.EtherTypes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.MonitorProfileCreateInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.MonitorProfileCreateInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.MonitorProfileCreateOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.MonitorProfileGetInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.MonitorProfileGetInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.MonitorProfileGetOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.MonitorStartInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.MonitorStartInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.MonitorStartOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.MonitorStopInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.MonitorStopInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.MonitoringMode;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.endpoint.endpoint.type.Interface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.endpoint.endpoint.type.InterfaceBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.monitor.params.DestinationBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.monitor.params.SourceBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.monitor.profile.create.input.Profile;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.monitor.profile.create.input.ProfileBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.monitor.start.input.ConfigBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.base.Optional;

public class AlivenessMonitorUtils {

    private static final Logger LOG = LoggerFactory.getLogger(AlivenessMonitorUtils.class);
    private static Map<Long, MacEntry> alivenessCache = new ConcurrentHashMap<>();

    public static void startArpMonitoring(MacEntry macEntry, Long arpMonitorProfileId,
        AlivenessMonitorService alivenessMonitorService, DataBroker dataBroker,
        OdlInterfaceRpcService interfaceRpc, INeutronVpnManager neutronVpnService,
        IInterfaceManager interfaceManager) {
        if (interfaceManager.isExternalInterface(macEntry.getInterfaceName())) {
            LOG.debug("ARP monitoring is currently not supported through external interfaces,"
                    + "skipping ARP monitoring from interface {} for IP {} (last known MAC {})",
                    macEntry.getInterfaceName(), macEntry.getIpAddress().getHostAddress(), macEntry.getMacAddress());
            return;
        }
        Optional<IpAddress> gatewayIpOptional =
                VpnUtil.getGatewayIpAddressFromInterface(macEntry.getInterfaceName(), neutronVpnService, dataBroker);
        IpAddress gatewayIp;
        PhysAddress gatewayMac;
        if(!gatewayIpOptional.isPresent()) {
            LOG.error("Error while retrieving GatewayIp for interface{}", macEntry.getInterfaceName());
            return;
        }
        gatewayIp = gatewayIpOptional.get();
        Optional<String> gatewayMacOptional = VpnUtil.getGWMacAddressFromInterface(macEntry,
                gatewayIp, dataBroker, interfaceRpc);
        if(!gatewayMacOptional.isPresent()) {
            LOG.error("Error while retrieving GatewayMac for interface{}", macEntry.getInterfaceName());
            return;
        }
        gatewayMac = new PhysAddress(gatewayMacOptional.get());
        if(arpMonitorProfileId == null || arpMonitorProfileId.equals(0L)) {
            Optional<Long> profileIdOptional = allocateProfile(alivenessMonitorService,
                    ArpConstants.FAILURE_THRESHOLD, ArpConstants.ARP_CACHE_TIMEOUT_MILLIS,
                    ArpConstants.MONITORING_WINDOW, EtherTypes.Arp);
            if(!profileIdOptional.isPresent()) {
                LOG.error("Error while allocating Profile Id for alivenessMonitorService");
                return;
            }
            arpMonitorProfileId = profileIdOptional.get();
        }

        IpAddress targetIp =  new IpAddress(new Ipv4Address(macEntry.getIpAddress().getHostAddress()));
        MonitorStartInput arpMonitorInput = new MonitorStartInputBuilder().setConfig(new ConfigBuilder()
                .setSource(new SourceBuilder().setEndpointType(getSourceEndPointType(macEntry.getInterfaceName(),
                        gatewayIp, gatewayMac)).build())
                .setDestination(new DestinationBuilder().setEndpointType(getEndPointIpAddress(targetIp)).build())
                .setMode(MonitoringMode.OneOne)
                .setProfileId(arpMonitorProfileId).build()).build();
        try {
            Future<RpcResult<MonitorStartOutput>> result = alivenessMonitorService.monitorStart(arpMonitorInput);
            RpcResult<MonitorStartOutput> rpcResult = result.get();
            long monitorId;
            if (rpcResult.isSuccessful()) {
                monitorId = rpcResult.getResult().getMonitorId();
                createOrUpdateInterfaceMonitorIdMap(monitorId, macEntry);
                LOG.trace("Started ARP monitoring with id {}", monitorId);
            } else {
                LOG.warn("RPC Call to start monitoring returned with Errors {}", rpcResult.getErrors());
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.warn("Exception when starting monitoring", e);
        }
    }

    public static void stopArpMonitoring(AlivenessMonitorService alivenessMonitorService,
            Long monitorId) {
        MonitorStopInput input = new MonitorStopInputBuilder().setMonitorId(monitorId).build();
        alivenessMonitorService.monitorStop(input);
        alivenessCache.remove(monitorId);
        return;
    }

    private static void createOrUpdateInterfaceMonitorIdMap(long monitorId, MacEntry macEntry) {
        alivenessCache.put(monitorId, macEntry);
    }

    private static Interface getSourceEndPointType(String interfaceName, IpAddress ipAddress,
            PhysAddress gwMac) {
        return new InterfaceBuilder()
                .setInterfaceIp(ipAddress)
                .setInterfaceName(interfaceName)
                .setMacAddress(gwMac)
                .build();
    }

    public static Optional<Long> allocateProfile(AlivenessMonitorService alivenessMonitor,
            long FAILURE_THRESHOLD, long MONITORING_INTERVAL,
            long MONITORING_WINDOW, EtherTypes etherTypes) {
        MonitorProfileCreateInput input = new MonitorProfileCreateInputBuilder()
                .setProfile(new ProfileBuilder().setFailureThreshold(FAILURE_THRESHOLD)
                        .setMonitorInterval(MONITORING_INTERVAL).setMonitorWindow(MONITORING_WINDOW)
                        .setProtocolType(etherTypes).build()).build();
        return createMonitorProfile(alivenessMonitor, input);
    }

    public static Optional<Long> createMonitorProfile(AlivenessMonitorService alivenessMonitor,
            MonitorProfileCreateInput monitorProfileCreateInput) {
        Optional <Long> monitorProfileOptional = Optional.absent();
        try {
            Future<RpcResult<MonitorProfileCreateOutput>> result = alivenessMonitor.monitorProfileCreate(monitorProfileCreateInput);
            RpcResult<MonitorProfileCreateOutput> rpcResult = result.get();
            if(rpcResult.isSuccessful()) {
                return Optional.of(rpcResult.getResult().getProfileId());
            } else {
                LOG.warn("RPC Call to Get Profile Id Id returned with Errors {}.. Trying to fetch existing profile ID",
                        rpcResult.getErrors());
                try{
                    Profile createProfile = monitorProfileCreateInput.getProfile();
                    Future<RpcResult<MonitorProfileGetOutput>> existingProfile =
                            alivenessMonitor.monitorProfileGet(buildMonitorGetProfile(createProfile.getMonitorInterval(),
                                    createProfile.getMonitorWindow(), createProfile.getFailureThreshold(), createProfile.getProtocolType()));
                    RpcResult<MonitorProfileGetOutput> rpcGetResult = existingProfile.get();
                    if(rpcGetResult.isSuccessful()) {
                        return Optional.of(rpcGetResult.getResult().getProfileId());
                    } else {
                        LOG.warn("RPC Call to Get Existing Profile Id returned with Errors {}", rpcGetResult.getErrors());
                    }
                } catch(Exception e) {
                    LOG.warn("Exception when getting existing profile", e);
                }
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.warn("Exception when allocating profile Id", e);
        }
        return monitorProfileOptional;
    }

    private static MonitorProfileGetInput buildMonitorGetProfile(long monitorInterval,
            long monitorWindow, long failureThreshold, EtherTypes protocolType) {
        MonitorProfileGetInputBuilder buildGetProfile = new MonitorProfileGetInputBuilder();
        org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.monitor.profile.get.input.ProfileBuilder profileBuilder =
                new org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.monitor.profile.get.input.ProfileBuilder();
        profileBuilder.setFailureThreshold(failureThreshold)
        .setMonitorInterval(monitorInterval)
        .setMonitorWindow(monitorWindow)
        .setProtocolType(protocolType);
        buildGetProfile.setProfile(profileBuilder.build());
        return (buildGetProfile.build());
    }

    public static MacEntry getMacEntryFromMonitorId(Long monitorId) {
        return alivenessCache.get(monitorId);
    }

    private static org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411
    .endpoint.endpoint.type.IpAddress getEndPointIpAddress(IpAddress ip) {
        return new org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411
                .endpoint.endpoint.type.IpAddressBuilder().setIpAddress(ip).build();
    }

    public static java.util.Optional<Long> getMonitorIdFromInterface(MacEntry macEntry) {
        java.util.Optional<Long> monitorId = alivenessCache.entrySet().parallelStream()
                .filter(map -> macEntry.equals(map.getValue()))
                .map(map->map.getKey())
                .findFirst();
        return monitorId;
    }

}

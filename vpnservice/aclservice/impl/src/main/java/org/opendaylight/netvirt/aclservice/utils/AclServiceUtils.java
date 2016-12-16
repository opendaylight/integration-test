/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.aclservice.utils;

import com.google.common.base.Optional;
import com.googlecode.ipv6.IPv6Address;
import com.googlecode.ipv6.IPv6NetworkMask;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;

import javax.inject.Inject;
import javax.inject.Singleton;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.ReadOnlyTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.ReadFailedException;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.MatchFieldType;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.MatchInfoBase;
import org.opendaylight.genius.mdsalutil.MetaDataUtil;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.NxMatchFieldType;
import org.opendaylight.genius.mdsalutil.NxMatchInfo;
import org.opendaylight.genius.mdsalutil.packet.IPProtocols;
import org.opendaylight.netvirt.aclservice.api.AclServiceManager.MatchCriteria;
import org.opendaylight.netvirt.aclservice.api.utils.AclInterface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.AccessLists;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.Ipv4Acl;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.Acl;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.AclKey;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.Ace;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpPrefix;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.Interfaces;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.InterfacesState;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.InterfaceKey;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.Instruction;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.ReleaseIdInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.ReleaseIdInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetDpidFromInterfaceInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetDpidFromInterfaceInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetDpidFromInterfaceOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.ServiceBindings;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.ServiceModeBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.ServiceTypeFlowBased;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.StypeOpenflow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.StypeOpenflowBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.ServicesInfo;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.ServicesInfoKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.services.info.BoundServices;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.services.info.BoundServicesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.services.info.BoundServicesKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeConnectorId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.config.rev160806.AclserviceConfig;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.InterfaceAcl;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.IpPrefixOrAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.SecurityRuleAttr;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.interfaces._interface.AllowedAddressPairs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.ElanInstances;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.ElanInterfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstanceKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.interfaces.ElanInterface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.interfaces.ElanInterfaceKey;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier.InstanceIdentifierBuilder;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Singleton
@SuppressWarnings("deprecation")
public final class AclServiceUtils {

    private static final Logger LOG = LoggerFactory.getLogger(AclServiceUtils.class);

    private final AclDataUtil aclDataUtil;
    private final AclserviceConfig config;

    @Inject
    public AclServiceUtils(AclDataUtil aclDataUtil, AclserviceConfig config) {
        super();
        this.aclDataUtil = aclDataUtil;
        this.config = config;
    }

    /**
     * Retrieves the Interface from the datastore.
     * @param broker the data broker
     * @param interfaceName the interface name
     * @return the interface.
     */
    public static Optional<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces
        .Interface> getInterface(DataBroker broker, String interfaceName) {
        return read(broker, LogicalDatastoreType.CONFIGURATION, getInterfaceIdentifier(interfaceName));
    }

    /**
     * Builds the interface identifier.
     * @param interfaceName the interface name.
     * @return the interface identifier.
     */
    public static InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508
        .interfaces.Interface> getInterfaceIdentifier(String interfaceName) {
        return InstanceIdentifier.builder(Interfaces.class)
                .child(
                    org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces
                    .Interface.class, new InterfaceKey(interfaceName)).build();
    }

    /**
     * Retrieves the object from the datastore.
     * @param broker the data broker.
     * @param datastoreType the data store type.
     * @param path the wild card path.
     * @param <T> type of DataObject
     * @return the required object.
     */
    public static <T extends DataObject> Optional<T> read(
            DataBroker broker, LogicalDatastoreType datastoreType, InstanceIdentifier<T> path) {

        Optional<T> result = Optional.absent();
        ReadOnlyTransaction tx = broker.newReadOnlyTransaction();
        try {
            result = tx.read(datastoreType, path).checkedGet();
        } catch (ReadFailedException e) {
            LOG.warn("Failed to read InstanceIdentifier {} from {}", path, datastoreType, e);
        } finally {
            tx.close();
        }
        return result;
    }

    /**
     * Retrieves the acl matching the key from the data store.
     *
     * @param broker the data broker
     * @param aclKey the acl key
     * @return the acl
     */
    public static Acl getAcl(DataBroker broker, String aclKey) {
        Optional<Acl> optAcl = read(broker,
            LogicalDatastoreType.CONFIGURATION, getAclInstanceIdentifier(aclKey));
        if (optAcl.isPresent()) {
            return optAcl.get();
        }
        return null;
    }

    /** Creates the Acl instance identifier.
     *
     * @param aclKey the acl key
     * @return the instance identifier
     */
    public static InstanceIdentifier<Acl> getAclInstanceIdentifier(String aclKey) {
        return InstanceIdentifier
                .builder(AccessLists.class)
                .child(Acl.class,
                        new AclKey(aclKey,Ipv4Acl.class))
                .build();
    }

    /**
     * Get the data path number for the interface.
     * @param interfaceManagerRpcService interfaceManagerRpcService instance.
     * @param ifName the interface name.
     * @return the dpn.
     */
    public static BigInteger getDpnForInterface(OdlInterfaceRpcService interfaceManagerRpcService, String ifName) {
        BigInteger nodeId = BigInteger.ZERO;
        try {
            GetDpidFromInterfaceInput dpIdInput =
                    new GetDpidFromInterfaceInputBuilder().setIntfName(ifName).build();
            Future<RpcResult<GetDpidFromInterfaceOutput>> dpIdOutput =
                    interfaceManagerRpcService.getDpidFromInterface(dpIdInput);
            RpcResult<GetDpidFromInterfaceOutput> dpIdResult = dpIdOutput.get();
            if (dpIdResult.isSuccessful()) {
                nodeId = dpIdResult.getResult().getDpid();
            } else {
                LOG.error("Could not retrieve DPN Id for interface {}", ifName);
            }
        } catch (NullPointerException | InterruptedException | ExecutionException e) {
            LOG.error("Exception when getting dpn for interface {}", ifName,  e);
        }
        return nodeId;
    }

    /**
     * Retrieves the interface state.
     * @param dataBroker the data broker.
     * @param interfaceName the interface name.
     * @return the interface state.
     */
    public static org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state
        .Interface getInterfaceStateFromOperDS(DataBroker dataBroker, String interfaceName) {
        InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508
            .interfaces.state.Interface> ifStateId = buildStateInterfaceId(interfaceName);
        Optional<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508
            .interfaces.state.Interface> ifStateOptional = MDSALUtil.read(LogicalDatastoreType
                .OPERATIONAL, ifStateId, dataBroker);
        if (!ifStateOptional.isPresent()) {
            return null;
        }

        return ifStateOptional.get();
    }

    /**
     * Build the interface state.
     * @param interfaceName the interface name.
     * @return the interface state.
     */
    public static InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508
        .interfaces.state.Interface> buildStateInterfaceId(String interfaceName) {
        InstanceIdentifierBuilder<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508
            .interfaces.state.Interface> idBuilder = InstanceIdentifier.builder(InterfacesState.class)
            .child(org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces
            .state.Interface.class, new org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces
            .rev140508.interfaces.state.InterfaceKey(interfaceName));
        return idBuilder.build();
    }

    /**
     * Checks whether port security is enabled for the port.
     * @param port the port.
     * @return the port security is enabled/not.
     */
    public static boolean isPortSecurityEnabled(AclInterface port) {
        return port.isPortSecurityEnabled();
    }

    /**
     * Checks whether port security is enabled for the port.
     * @param port the port.
     * @return the list of security groups.
     */
    public static List<Uuid> getInterfaceAcls(Interface port) {
        if (port == null) {
            LOG.error("Port is Null");
            return null;
        }
        InterfaceAcl aclInPort = port.getAugmentation(InterfaceAcl.class);
        if (aclInPort == null) {
            LOG.error("getSecurityGroupInPortList: no security group associated}",
                port.getName());
            return null;
        }
        return aclInPort.getSecurityGroups();
    }

    /**
     * Retrieves the security rule attribute augmentation from the access list.
     * @param ace the access list entry
     * @return the security rule attributes
     */
    public static SecurityRuleAttr  getAccesssListAttributes(Ace ace) {
        if (ace == null) {
            LOG.error("Ace is Null");
            return null;
        }
        SecurityRuleAttr aceAttributes = ace.getAugmentation(SecurityRuleAttr.class);
        if (aceAttributes == null) {
            LOG.error("Ace is null");
            return null;
        }
        return aceAttributes;
    }

    /**
     * Returns the DHCP match.
     *
     * @param srcPort the source port.
     * @param dstPort the destination port.
     * @param lportTag the lport tag
     * @return list of matches.
     */
    public static List<MatchInfoBase> buildDhcpMatches(int srcPort, int dstPort, int lportTag) {
        List<MatchInfoBase> matches = new ArrayList<>(6);
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { NwConstants.ETHTYPE_IPV4 }));
        matches.add(new MatchInfo(MatchFieldType.ip_proto,
                new long[] { IPProtocols.UDP.intValue() }));
        matches.add(new MatchInfo(MatchFieldType.udp_dst,
                new long[] { dstPort }));
        matches.add(new MatchInfo(MatchFieldType.udp_src,
                new long[] { srcPort}));
        matches.add(AclServiceUtils.buildLPortTagMatch(lportTag));
        return matches;
    }

    /**
     * Returns the DHCPv6 match.
     *
     * @param srcPort the source port.
     * @param dstPort the destination port.
     * @param lportTag the lport tag
     * @return list of matches.
     */
    public static List<MatchInfoBase> buildDhcpV6Matches(int srcPort, int dstPort, int lportTag) {
        List<MatchInfoBase> matches = new ArrayList<>(6);
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { NwConstants.ETHTYPE_IPV6 }));
        matches.add(new MatchInfo(MatchFieldType.ip_proto,
                new long[] { IPProtocols.UDP.intValue() }));
        matches.add(new MatchInfo(MatchFieldType.udp_dst,
                new long[] { dstPort }));
        matches.add(new MatchInfo(MatchFieldType.udp_src,
                new long[] { srcPort}));
        matches.add(AclServiceUtils.buildLPortTagMatch(lportTag));
        return matches;
    }

    /**
     * Returns the ICMPv6 match.
     *
     * @param icmpType the icmpv6-type.
     * @param icmpCode the icmpv6-code.
     * @param lportTag the lport tag
     * @return list of matches.
     */
    public static List<MatchInfoBase> buildIcmpV6Matches(int icmpType, int icmpCode, int lportTag) {
        List<MatchInfoBase> matches = new ArrayList<>(6);
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { NwConstants.ETHTYPE_IPV6 }));
        matches.add(new MatchInfo(MatchFieldType.ip_proto,
                new long[] { IPProtocols.IPV6ICMP.intValue() }));
        if (icmpType != 0) {
            matches.add(new MatchInfo(MatchFieldType.icmp_v6,
                    new long[] { icmpType, icmpCode}));
        }
        matches.add(AclServiceUtils.buildLPortTagMatch(lportTag));
        return matches;
    }

    /**
     * Builds the service id.
     *
     * @param interfaceName the interface name
     * @param serviceIndex the service index
     * @param serviceMode the service mode
     * @return the instance identifier
     */
    public static InstanceIdentifier<BoundServices> buildServiceId(String interfaceName, short serviceIndex,
            Class<? extends ServiceModeBase> serviceMode) {
        return InstanceIdentifier.builder(ServiceBindings.class)
                .child(ServicesInfo.class, new ServicesInfoKey(interfaceName, serviceMode))
                .child(BoundServices.class, new BoundServicesKey(serviceIndex)).build();
    }

    /**
     * Gets the bound services.
     *
     * @param serviceName the service name
     * @param servicePriority the service priority
     * @param flowPriority the flow priority
     * @param cookie the cookie
     * @param instructions the instructions
     * @return the bound services
     */
    public static BoundServices getBoundServices(String serviceName, short servicePriority, int flowPriority,
            BigInteger cookie, List<Instruction> instructions) {
        StypeOpenflowBuilder augBuilder = new StypeOpenflowBuilder().setFlowCookie(cookie).setFlowPriority(flowPriority)
                .setInstruction(instructions);
        return new BoundServicesBuilder().setKey(new BoundServicesKey(servicePriority)).setServiceName(serviceName)
                .setServicePriority(servicePriority).setServiceType(ServiceTypeFlowBased.class)
                .addAugmentation(StypeOpenflow.class, augBuilder.build()).build();
    }

    public static List<Uuid> getUpdatedAclList(List<Uuid> updatedAclList, List<Uuid> currentAclList) {
        if (updatedAclList == null) {
            return null;
        }
        List<Uuid> newAclList = new ArrayList<>(updatedAclList);
        if (currentAclList == null) {
            return newAclList;
        }
        List<Uuid> origAclList = new ArrayList<>(currentAclList);
        for (Iterator<Uuid> iterator = newAclList.iterator(); iterator.hasNext();) {
            Uuid updatedAclUuid = iterator.next();
            for (Uuid currentAclUuid :origAclList) {
                if (updatedAclUuid.getValue().equals(currentAclUuid.getValue())) {
                    iterator.remove();
                }
            }
        }
        return newAclList;
    }

    public static List<AllowedAddressPairs> getUpdatedAllowedAddressPairs(
            List<AllowedAddressPairs> updatedAllowedAddressPairs,
            List<AllowedAddressPairs> currentAllowedAddressPairs) {
        if (updatedAllowedAddressPairs == null) {
            return null;
        }
        List<AllowedAddressPairs> newAllowedAddressPairs = new ArrayList<>(updatedAllowedAddressPairs);
        if (currentAllowedAddressPairs == null) {
            return newAllowedAddressPairs;
        }
        List<AllowedAddressPairs> origAllowedAddressPairs = new ArrayList<>(currentAllowedAddressPairs);
        for (Iterator<AllowedAddressPairs> iterator = newAllowedAddressPairs.iterator(); iterator.hasNext();) {
            AllowedAddressPairs updatedAllowedAddressPair = iterator.next();
            for (AllowedAddressPairs currentAllowedAddressPair : origAllowedAddressPairs) {
                if (updatedAllowedAddressPair.getKey().equals(currentAllowedAddressPair.getKey())) {
                    iterator.remove();
                    break;
                }
            }
        }
        return newAllowedAddressPairs;
    }

    public static List<AllowedAddressPairs> getPortAllowedAddresses(Interface port) {
        if (port == null) {
            LOG.error("Port is Null");
            return null;
        }
        InterfaceAcl aclInPort = port.getAugmentation(InterfaceAcl.class);
        if (aclInPort == null) {
            LOG.error("getSecurityGroupInPortList: no security group associated to Interface port: {}", port.getName());
            return null;
        }
        return aclInPort.getAllowedAddressPairs();
    }

    public static BigInteger getDpIdFromIterfaceState(org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf
            .interfaces.rev140508.interfaces.state.Interface interfaceState) {
        BigInteger dpId = null;
        List<String> ofportIds = interfaceState.getLowerLayerIf();
        if (ofportIds != null && !ofportIds.isEmpty()) {
            NodeConnectorId nodeConnectorId = new NodeConnectorId(ofportIds.get(0));
            dpId = BigInteger.valueOf(MDSALUtil.getDpnIdFromPortName(nodeConnectorId));
        }
        return dpId;
    }

    /**
     * Builds the ip matches.
     *
     * @param ipPrefixOrAddress the ip prefix or address
     * @param matchCriteria the source_ip or destination_ip used for the match
     * @return the list
     */
    public static List<MatchInfoBase> buildIpMatches(IpPrefixOrAddress ipPrefixOrAddress,
                                                     MatchCriteria matchCriteria) {
        List<MatchInfoBase> flowMatches = new ArrayList<>();
        IpPrefix ipPrefix = ipPrefixOrAddress.getIpPrefix();
        MatchFieldType matchFieldType;
        if (ipPrefix != null) {
            if (ipPrefix.getIpv4Prefix() != null) {
                flowMatches.add(new MatchInfo(MatchFieldType.eth_type, new long[] {NwConstants.ETHTYPE_IPV4}));
                String[] ipaddressValues = ipPrefix.getIpv4Prefix().getValue().split("/");
                matchFieldType = matchCriteria == MatchCriteria.MATCH_SOURCE
                        ? MatchFieldType.ipv4_source : MatchFieldType.ipv4_destination;
                flowMatches.add(new MatchInfo(matchFieldType, new String[] {ipaddressValues[0], ipaddressValues[1]}));
            } else {
                matchFieldType = matchCriteria == MatchCriteria.MATCH_SOURCE
                        ? MatchFieldType.ipv6_source : MatchFieldType.ipv6_destination;
                String[] ipv6addressValues = ipPrefix.getIpv6Prefix().getValue().split("/");
                IPv6Address ipv6Address = IPv6Address.fromString(ipv6addressValues[0]);
                IPv6Address maskedV6Address = ipv6Address.maskWithNetworkMask(
                        IPv6NetworkMask.fromPrefixLength(Integer.parseInt(ipv6addressValues[1])));
                flowMatches.add(new MatchInfo(MatchFieldType.eth_type, new long[] {NwConstants.ETHTYPE_IPV6}));
                flowMatches.add(new MatchInfo(matchFieldType,
                        new String[] {maskedV6Address.toString() + "/" + ipv6addressValues[1]}));
            }
        } else {
            IpAddress ipAddress = ipPrefixOrAddress.getIpAddress();
            if (ipAddress.getIpv4Address() != null) {
                matchFieldType = matchCriteria == MatchCriteria.MATCH_SOURCE
                        ? MatchFieldType.ipv4_source : MatchFieldType.ipv4_destination;
                flowMatches.add(new MatchInfo(MatchFieldType.eth_type, new long[] {NwConstants.ETHTYPE_IPV4}));
                flowMatches.add(new MatchInfo(matchFieldType,
                        new String[] {ipAddress.getIpv4Address().getValue(), "32"}));
            } else {
                matchFieldType = matchCriteria == MatchCriteria.MATCH_SOURCE
                        ? MatchFieldType.ipv6_source : MatchFieldType.ipv6_destination;
                flowMatches.add(new MatchInfo(MatchFieldType.eth_type, new long[] {NwConstants.ETHTYPE_IPV6}));
                flowMatches.add(new MatchInfo(matchFieldType,
                        new String[] {ipAddress.getIpv6Address().getValue() + "/128" }));
            }
        }
        return flowMatches;
    }

    /**
     * Gets the lport tag match.
     *
     * @param lportTag the lport tag
     * @return the lport tag match
     */
    public static MatchInfo buildLPortTagMatch(int lportTag) {
        return new MatchInfo(MatchFieldType.metadata,
                new BigInteger[] {MetaDataUtil.getLportTagMetaData(lportTag), MetaDataUtil.METADATA_MASK_LPORT_TAG});
    }

    public static List<Ace> getAceWithRemoteAclId(DataBroker dataBroker, AclInterface port, Uuid remoteAcl) {
        List<Ace> remoteAclRuleList = new ArrayList<>();
        List<Uuid> aclList = port.getSecurityGroups();
        for (Uuid aclId : aclList) {
            Acl acl = getAcl(dataBroker, aclId.getValue());
            List<Ace> aceList = acl.getAccessListEntries().getAce();
            for (Ace ace : aceList) {
                Uuid tempRemoteAcl = getAccesssListAttributes(ace).getRemoteGroupId();
                if (tempRemoteAcl != null && tempRemoteAcl.equals(remoteAcl)) {
                    remoteAclRuleList.add(ace);
                }
            }
        }
        return remoteAclRuleList;
    }

    public Map<String, List<MatchInfoBase>> getFlowForRemoteAcl(Uuid remoteAclId, String ignoreInterfaceId,
                                                                       Map<String, List<MatchInfoBase>>
                                                                               flowMatchesMap, boolean
                                                                               isSourceIpMacMatch) {
        List<AclInterface> interfaceList = aclDataUtil.getInterfaceList(remoteAclId);
        if (flowMatchesMap == null || interfaceList == null || interfaceList.isEmpty()) {
            return null;
        }
        Map<String, List<MatchInfoBase>> updatedFlowMatchesMap = new HashMap<>();
        MatchInfoBase ipv4Match = new MatchInfo(MatchFieldType.eth_type, new long[] {NwConstants.ETHTYPE_IPV4});
        MatchInfoBase ipv6Match = new MatchInfo(MatchFieldType.eth_type, new long[] {NwConstants.ETHTYPE_IPV6});
        for (String flowName : flowMatchesMap.keySet()) {
            List<MatchInfoBase> flows = flowMatchesMap.get(flowName);
            for (AclInterface port : interfaceList) {
                if (port.getInterfaceId().equals(ignoreInterfaceId)) {
                    continue;
                }
                //get allow address pair
                List<AllowedAddressPairs> allowedAddressPair = port.getAllowedAddressPairs();
                // iterate over allow address pair and update match type
                for (AllowedAddressPairs aap : allowedAddressPair) {
                    List<MatchInfoBase> matchInfoBaseList;
                    String flowId;
                    if (flows.contains(ipv4Match) && isIPv4Address(aap)) {
                        matchInfoBaseList = updateAAPMatches(isSourceIpMacMatch, flows, aap);
                        flowId = flowName + "_ipv4_remoteACL_interface_aap_" + aap.getKey();
                        updatedFlowMatchesMap.put(flowId, matchInfoBaseList);
                    } else if (flows.contains(ipv6Match) && !isIPv4Address(aap)) {
                        matchInfoBaseList = updateAAPMatches(isSourceIpMacMatch, flows, aap);
                        flowId = flowName + "_ipv6_remoteACL_interface_aap_" +  aap.getKey();
                        updatedFlowMatchesMap.put(flowId, matchInfoBaseList);
                    }
                }

            }

        }
        return updatedFlowMatchesMap;
    }

    public AclserviceConfig getConfig() {
        return config;
    }

    private static boolean isIPv4Address(AllowedAddressPairs aap) {
        IpPrefixOrAddress ipPrefixOrAddress = aap.getIpAddress();
        IpPrefix ipPrefix = ipPrefixOrAddress.getIpPrefix();
        if (ipPrefix != null) {
            if (ipPrefix.getIpv4Prefix() != null) {
                return true;
            }
        } else {
            IpAddress ipAddress = ipPrefixOrAddress.getIpAddress();
            if (ipAddress.getIpv4Address() != null) {
                return true;
            }
        }
        return false;
    }

    public static Map<String, List<MatchInfoBase>> getFlowForAllowedAddresses(List<AllowedAddressPairs>
                                                                                      syncAllowedAddresses,
                                                                              Map<String, List<MatchInfoBase>>
                                                                                      flowMatchesMap, boolean
                                                                                      isSourceIpMacMatch) {
        if (flowMatchesMap == null) {
            return null;
        }
        Map<String, List<MatchInfoBase>> updatedFlowMatchesMap = new HashMap<>();
        MatchInfoBase ipv4Match = new MatchInfo(MatchFieldType.eth_type, new long[] {NwConstants.ETHTYPE_IPV4});
        MatchInfoBase ipv6Match = new MatchInfo(MatchFieldType.eth_type, new long[] {NwConstants.ETHTYPE_IPV6});
        for (String flowName : flowMatchesMap.keySet()) {
            List<MatchInfoBase> flows = flowMatchesMap.get(flowName);
            // iterate over allow address pair and update match type
            for (AllowedAddressPairs aap : syncAllowedAddresses) {
                List<MatchInfoBase> matchInfoBaseList;
                String flowId;
                if (flows.contains(ipv4Match) && isIPv4Address(aap)) {
                    matchInfoBaseList = updateAAPMatches(isSourceIpMacMatch, flows, aap);
                    flowId = flowName + "_ipv4_remoteACL_interface_aap_" + aap.getKey();
                    updatedFlowMatchesMap.put(flowId, matchInfoBaseList);
                } else if (flows.contains(ipv6Match) && !isIPv4Address(aap)) {
                    matchInfoBaseList = updateAAPMatches(isSourceIpMacMatch, flows, aap);
                    flowId = flowName + "_ipv6_remoteACL_interface_aap_" + aap.getKey();
                    updatedFlowMatchesMap.put(flowId, matchInfoBaseList);
                }
            }

        }
        return updatedFlowMatchesMap;
    }

    public static Long getElanIdFromInterface(String elanInterfaceName,DataBroker broker) {
        ElanInterface elanInterface = getElanInterfaceByElanInterfaceName(elanInterfaceName, broker);
        if (null != elanInterface) {
            ElanInstance elanInfo = getElanInstanceByName(elanInterface.getElanInstanceName(), broker);
            return elanInfo.getElanTag();
        }
        return null;
    }

    public static ElanInterface getElanInterfaceByElanInterfaceName(String elanInterfaceName,DataBroker broker) {
        InstanceIdentifier<ElanInterface> elanInterfaceId = getElanInterfaceConfigurationDataPathId(elanInterfaceName);
        Optional<ElanInterface> existingElanInterface = read(broker,
                LogicalDatastoreType.CONFIGURATION, elanInterfaceId);
        if (existingElanInterface.isPresent()) {
            return existingElanInterface.get();
        }
        return null;
    }

    public static InstanceIdentifier<ElanInterface> getElanInterfaceConfigurationDataPathId(String interfaceName) {
        return InstanceIdentifier.builder(ElanInterfaces.class)
                .child(ElanInterface.class, new ElanInterfaceKey(interfaceName)).build();
    }

    // elan-instances config container
    public static ElanInstance getElanInstanceByName(String elanInstanceName, DataBroker broker) {
        InstanceIdentifier<ElanInstance> elanIdentifierId = getElanInstanceConfigurationDataPath(elanInstanceName);
        Optional<ElanInstance> elanInstance = read(broker, LogicalDatastoreType.CONFIGURATION,
                elanIdentifierId);
        if (elanInstance.isPresent()) {
            return elanInstance.get();
        }
        return null;
    }

    public static InstanceIdentifier<ElanInstance> getElanInstanceConfigurationDataPath(String elanInstanceName) {
        return InstanceIdentifier.builder(ElanInstances.class)
                .child(ElanInstance.class, new ElanInstanceKey(elanInstanceName)).build();
    }

    private static List<MatchInfoBase> updateAAPMatches(boolean isSourceIpMacMatch, List<MatchInfoBase> flows,
                                                        AllowedAddressPairs aap) {
        List<MatchInfoBase> matchInfoBaseList;
        if (isSourceIpMacMatch) {
            matchInfoBaseList = AclServiceUtils.buildIpMatches(aap.getIpAddress(), MatchCriteria.MATCH_SOURCE);
        } else {
            matchInfoBaseList = AclServiceUtils.buildIpMatches(aap.getIpAddress(), MatchCriteria.MATCH_DESTINATION);
        }
        matchInfoBaseList.addAll(flows);
        return matchInfoBaseList;
    }

    public static MatchInfoBase popMatchInfoByType(List<MatchInfoBase> flows, MatchFieldType type) {
        MatchInfoBase mib = getMatchInfoByType(flows, type);
        if (mib != null) {
            flows.remove(mib);
        }
        return mib;
    }

    public static MatchInfo getMatchInfoByType(List<MatchInfoBase> flows, MatchFieldType type) {
        for (MatchInfoBase mib : flows) {
            if (mib instanceof MatchInfo) {
                if (((MatchInfo)mib).getMatchField() == type) {
                    return (MatchInfo) mib;
                }
            }
        }
        return null;
    }

    public static MatchInfoBase getMatchInfoByType(List<MatchInfoBase> flows, NxMatchFieldType type) {
        for (MatchInfoBase mib : flows) {
            if (mib instanceof NxMatchInfo) {
                if (((NxMatchInfo)mib).getMatchField() == type) {
                    return mib;
                }
            }
        }
        return null;
    }

    public static boolean containsMatchFieldType(List<MatchInfoBase> flows, MatchFieldType type) {
        MatchInfoBase mib = getMatchInfoByType(flows, type);
        if (mib != null) {
            return true;
        }
        return false;
    }

    public static boolean containsMatchFieldType(List<MatchInfoBase> flows, NxMatchFieldType type) {
        MatchInfoBase mib = getMatchInfoByType(flows, type);
        if (mib != null) {
            return true;
        }
        return false;
    }

    public static boolean containsMatchFieldTypeAndValue(List<MatchInfoBase> flows, MatchFieldType type,
            long[] values) {
        MatchInfo mib = getMatchInfoByType(flows, type);
        if (mib != null && Arrays.equals(mib.getMatchValues(), values)) {
            return true;
        }

        return false;
    }

    public static boolean containsTcpMatchField(List<MatchInfoBase> flows) {
        return containsMatchFieldTypeAndValue(flows, MatchFieldType.ip_proto, new long[] {IPProtocols.TCP.intValue()});
    }

    public static boolean containsUdpMatchField(List<MatchInfoBase> flows) {
        return containsMatchFieldTypeAndValue(flows, MatchFieldType.ip_proto, new long[] {IPProtocols.UDP.intValue()});
    }

    public static Integer allocateId(IdManagerService idManager, String poolName, String idKey) {
        AllocateIdInput getIdInput = new AllocateIdInputBuilder().setPoolName(poolName).setIdKey(idKey).build();
        try {
            Future<RpcResult<AllocateIdOutput>> result = idManager.allocateId(getIdInput);
            RpcResult<AllocateIdOutput> rpcResult = result.get();
            if (rpcResult.isSuccessful()) {
                return rpcResult.getResult().getIdValue().intValue();
            } else {
                LOG.warn("RPC Call to Get Unique Id returned with Errors {}", rpcResult.getErrors());
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.warn("Exception when getting Unique Id", e);
        }
        return AclConstants.PROTO_MATCH_PRIORITY;
    }

    public static void releaseId(IdManagerService idManager, String poolName, String idKey) {
        ReleaseIdInput idInput = new ReleaseIdInputBuilder().setPoolName(poolName).setIdKey(idKey).build();
        try {
            Future<RpcResult<Void>> result = idManager.releaseId(idInput);
            RpcResult<Void> rpcResult = result.get();
            if (!rpcResult.isSuccessful()) {
                LOG.warn("RPC Call to release Id {} with Key {} returned with Errors {}", idKey, rpcResult.getErrors());
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.warn("Exception when releasing Id for key {}", idKey, e);
        }
    }

    /**
     * Indicates whether the interface has port security enabled.
     * @param aclInterface the interface.
     * @return true if port is security enabled.
     */
    public static boolean isOfInterest(AclInterface aclInterface) {
        return aclInterface != null && aclInterface.getPortSecurityEnabled() != null
                && aclInterface.isPortSecurityEnabled();
    }
}
